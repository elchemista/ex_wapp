defmodule ExWapp.CallStanzaTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary.Node
  alias ExWapp.Call
  alias ExWapp.MessageHandler
  alias ExWapp.Session.Worker
  alias ExWapp.Store

  @caller "15550002222@s.whatsapp.net"
  @own "15550001111@s.whatsapp.net"
  @group "120363999999999999@g.us"

  defp new_state do
    %{store: Store.new(Store.Memory), session_id: "call-stanza-test", runtime_cfg: %{}}
  end

  defp call_node(child_tag, opts \\ []) do
    child_attrs =
      %{"call-id" => Keyword.get(opts, :call_id, "CALL1")}
      |> maybe_put("call-creator", Keyword.get(opts, :creator, @caller))
      |> maybe_put("group-jid", Keyword.get(opts, :group_jid))
      |> maybe_put("reason", Keyword.get(opts, :reason))
      |> maybe_put("media", Keyword.get(opts, :media))
      |> maybe_put("type", Keyword.get(opts, :type))
      |> maybe_put("duration", Keyword.get(opts, :duration))

    %Node{
      tag: "call",
      attrs: %{
        "from" => Keyword.get(opts, :from, @caller),
        "id" => "stanza-#{System.unique_integer([:positive])}",
        "t" => Keyword.get(opts, :t, "1754000000")
      },
      content: [
        %Node{tag: child_tag, attrs: child_attrs, content: Keyword.get(opts, :children, [])}
      ]
    }
  end

  defp maybe_put(attrs, _key, nil), do: attrs
  defp maybe_put(attrs, key, value), do: Map.put(attrs, key, value)

  defp handle(node, state), do: MessageHandler.handle_node(node, self(), state)

  test "an offer creates a ringing log entry and emits a call event" do
    state = new_state()

    assert {:ok, ^state} = handle(call_node("offer", t: "1754000100"), state)

    assert_receive {:call_event, %Call{} = call}
    assert call.id == "CALL1"
    assert call.status == :ringing
    assert call.chat_jid == @caller
    assert call.creator_jid == @caller
    assert call.start_time == 1_754_000_100
    assert call.is_video == false
    assert call.source == :live

    assert [%Call{id: "CALL1", status: :ringing}] = Call.list(state.store)
  end

  test "a video child on the offer marks the call as video" do
    state = new_state()
    video_child = [%Node{tag: "video", attrs: %{}, content: nil}]

    assert {:ok, _state} = handle(call_node("offer", children: video_child), state)

    assert_receive {:call_event, %Call{is_video: true}}
  end

  test "an unanswered timeout terminate becomes a missed call" do
    state = new_state()
    assert {:ok, _state} = handle(call_node("offer", t: "1754000100"), state)
    assert_receive {:call_event, %Call{status: :ringing}}

    assert {:ok, _state} =
             handle(call_node("terminate", t: "1754000160", reason: "timeout"), state)

    assert_receive {:call_event, %Call{} = call}
    assert call.status == :missed
    assert call.start_time == 1_754_000_100
    assert call.ended_at == 1_754_000_160
    assert call.end_reason == "timeout"
    assert call.duration == nil
  end

  test "offer, accept, and terminate resolve to a connected call with duration" do
    state = new_state()
    assert {:ok, _state} = handle(call_node("offer", t: "1754000100"), state)
    assert {:ok, _state} = handle(call_node("accept", t: "1754000110"), state)
    assert_receive {:call_event, %Call{status: :ringing}}
    assert_receive {:call_event, %Call{status: :ongoing, accepted_at: 1_754_000_110}}

    assert {:ok, _state} = handle(call_node("terminate", t: "1754000173"), state)

    assert_receive {:call_event, %Call{} = call}
    assert call.status == :connected
    assert call.duration == 63
  end

  test "a duration attribute on terminate marks the call connected" do
    state = new_state()

    assert {:ok, _state} = handle(call_node("terminate", t: "1754000200", duration: "42"), state)

    assert_receive {:call_event, %Call{status: :connected, duration: 42}}
  end

  test "an unanswered terminate for an outgoing call becomes cancelled" do
    state = new_state()
    :ok = Store.persist(state.store, %{client_info: %{jid: @own}})

    assert {:ok, _state} = handle(call_node("offer", creator: @own, from: @caller), state)
    assert_receive {:call_event, %Call{is_incoming: false}}

    assert {:ok, _state} = handle(call_node("terminate", creator: @own, from: @caller), state)

    assert_receive {:call_event, %Call{status: :cancelled}}
  end

  test "a reject settles the call as rejected" do
    state = new_state()
    assert {:ok, _state} = handle(call_node("offer"), state)
    assert {:ok, _state} = handle(call_node("reject", t: "1754000130"), state)

    assert_receive {:call_event, %Call{status: :ringing}}
    assert_receive {:call_event, %Call{status: :rejected, ended_at: 1_754_000_130}}
  end

  test "a group offer notice records a group call with media type" do
    state = new_state()

    node =
      call_node("offer_notice",
        from: @group,
        group_jid: @group,
        media: "video",
        type: "group"
      )

    assert {:ok, _state} = handle(node, state)

    assert_receive {:call_event, %Call{} = call}
    assert call.status == :ringing
    assert call.is_group == true
    assert call.group_jid == @group
    assert call.chat_jid == @group
    assert call.is_video == true
  end

  test "transport and relaylatency children change nothing" do
    state = new_state()

    assert {:ok, ^state} = handle(call_node("transport"), state)
    assert {:ok, ^state} = handle(call_node("relaylatency"), state)

    refute_receive {:call_event, _call}, 20
    assert Call.list(state.store) == []
  end

  test "unknown children and childless call stanzas are ignored" do
    state = new_state()
    childless = %Node{tag: "call", attrs: %{"from" => @caller, "id" => "x"}, content: []}

    assert {:ok, ^state} = handle(call_node("enc_rekey"), state)
    assert {:ok, ^state} = handle(childless, state)

    refute_receive {:call_event, _call}, 20
  end

  test "a live record is enriched, not duplicated, by a later synced record" do
    state = new_state()
    assert {:ok, _state} = handle(call_node("offer", t: "1754000100"), state)

    assert {:ok, _state} =
             handle(call_node("terminate", t: "1754000160", reason: "timeout"), state)

    :ok =
      Call.merge_from_sync(state.store, %WAWebProtobufSyncAction.CallLogRecord{
        callID: "CALL1",
        callResult: :MISSED,
        isIncoming: true,
        isVideo: false,
        startTime: 1_754_000_100,
        duration: 0
      })

    assert Call.count(state.store) == 1
    assert {:ok, %Call{status: :missed, is_incoming: true}} = Call.get(state.store, "CALL1")
  end

  test "a handler call event is published by the worker on both topics" do
    :ok = Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:calls:call-stanza-test")
    :ok = Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:calls")

    state = Map.merge(new_state(), %{status: :connected, reconnect_attempts: 0})
    assert {:ok, ^state} = handle(call_node("offer", call_id: "CALL9"), state)
    assert_receive {:call_event, %Call{id: "CALL9"} = call}

    assert {:noreply, ^state} = Worker.handle_info({:call_event, call}, state)

    assert_receive {:ex_wapp_call, %Call{id: "CALL9"}}
    assert_receive {"call-stanza-test", {:ex_wapp_call, %Call{id: "CALL9"}}}
  end
end
