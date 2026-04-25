defmodule ExWapp.Session.Worker.PostAuthTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Binary, Signal, Store}
  alias ExWapp.Session.Worker.PostAuth

  test "passive ack before prekey count waits until prekey count completes" do
    state = base_state(%{prekey_count_query_id: "count-1", passive_iq_id: "passive-1"})

    {after_passive, passive_actions} =
      PostAuth.handle_passive_response(
        iq_result("passive-1"),
        "result",
        state,
        &build_digest_query/0,
        &build_unified_session/0
      )

    assert passive_actions == []
    assert after_passive.passive_ack_received? == true
    assert after_passive.post_auth_phase == :awaiting_prekey_count

    {after_count, count_actions} =
      PostAuth.handle_prekey_count_response(
        count_result("count-1", "10"),
        after_passive,
        &build_passive_iq/0,
        &build_digest_query/0,
        &build_unified_session/0
      )

    assert after_count.post_auth_phase == :complete
    assert final_actions?(count_actions)
  end

  test "passive ack before prekey upload ack waits until upload completes" do
    store = signal_store!()

    state =
      base_state(%{
        store: store,
        prekey_count_query_id: "count-1",
        passive_iq_id: "passive-1"
      })

    initial_prekey_count = prekey_count(store)

    {after_passive, passive_actions} =
      PostAuth.handle_passive_response(
        iq_result("passive-1"),
        "result",
        state,
        &build_digest_query/0,
        &build_unified_session/0
      )

    assert passive_actions == []

    {after_count, count_actions} =
      PostAuth.handle_prekey_count_response(
        count_result("count-1", "0"),
        after_passive,
        &build_passive_iq/0,
        &build_digest_query/0,
        &build_unified_session/0
      )

    assert [{:send_node, %Binary.Node{tag: "iq", attrs: %{"xmlns" => "encrypt"}}}] = count_actions
    assert is_binary(after_count.prekey_upload_iq_id)
    assert after_count.post_auth_phase == :awaiting_prekey_upload
    assert prekey_count(store) == initial_prekey_count

    {after_upload, upload_actions} =
      PostAuth.handle_prekey_upload_response(
        iq_result(after_count.prekey_upload_iq_id),
        "result",
        after_count,
        &build_passive_iq/0,
        &build_digest_query/0,
        &build_unified_session/0
      )

    assert after_upload.post_auth_phase == :complete
    assert final_actions?(upload_actions)
    assert prekey_count(store) > initial_prekey_count
  end

  test "high prekey count path does not send duplicate passive iq" do
    state = base_state(%{prekey_count_query_id: "count-1", passive_iq_id: "passive-1"})

    {after_count, count_actions} =
      PostAuth.handle_prekey_count_response(
        count_result("count-1", "10"),
        state,
        &build_passive_iq/0,
        &build_digest_query/0,
        &build_unified_session/0
      )

    assert count_actions == []
    assert after_count.passive_iq_id == "passive-1"
    assert after_count.post_auth_phase == :awaiting_passive_ack

    {after_passive, passive_actions} =
      PostAuth.handle_passive_response(
        iq_result("passive-1"),
        "result",
        after_count,
        &build_digest_query/0,
        &build_unified_session/0
      )

    assert after_passive.post_auth_phase == :complete
    assert final_actions?(passive_actions)
  end

  test "post-auth finalization is emitted only once" do
    state =
      base_state(%{
        prekey_count_completed?: true,
        prekey_upload_required?: false,
        prekey_upload_completed?: true,
        passive_iq_id: "passive-1"
      })

    {after_passive, passive_actions} =
      PostAuth.handle_passive_response(
        iq_result("passive-1"),
        "result",
        state,
        &build_digest_query/0,
        &build_unified_session/0
      )

    assert final_actions?(passive_actions)

    {after_duplicate, duplicate_actions} =
      PostAuth.handle_passive_response(
        iq_result("passive-1"),
        "result",
        after_passive,
        &build_digest_query/0,
        &build_unified_session/0
      )

    assert after_duplicate.post_auth_phase == :complete
    assert duplicate_actions == []
  end

  defp base_state(attrs) do
    Map.merge(
      %{
        store: ExWapp.Store.Memory.new(initial_data: %{}),
        runtime_cfg: %{},
        prekey_count_query_id: nil,
        prekey_upload_iq_id: nil,
        pending_prekey_upload: [],
        passive_iq_id: nil,
        digest_iq_id: nil,
        post_auth_phase: :awaiting_prekey_count,
        prekey_count_completed?: false,
        prekey_upload_required?: false,
        prekey_upload_completed?: false,
        passive_ack_received?: false,
        digest_completed?: false,
        post_auth_completed?: false
      },
      attrs
    )
  end

  defp signal_store! do
    store = ExWapp.Store.Memory.new(initial_data: %{})
    {:ok, _signal_info, signal_state} = Signal.bootstrap(%{})
    :ok = Store.persist(store, %{signal: signal_state})
    store
  end

  defp prekey_count(store) do
    store
    |> Store.load!()
    |> get_in([:signal, :prekeys])
    |> map_size()
  end

  defp count_result(id, value) do
    %Binary.Node{
      tag: "iq",
      attrs: %{"type" => "result", "id" => id},
      content: [%Binary.Node{tag: "count", attrs: %{"value" => value}, content: nil}]
    }
  end

  defp iq_result(id), do: %Binary.Node{tag: "iq", attrs: %{"type" => "result", "id" => id}}

  defp build_passive_iq do
    %Binary.Node{
      tag: "iq",
      attrs: %{"id" => "passive-1", "xmlns" => "passive", "type" => "set"},
      content: [%Binary.Node{tag: "active", attrs: %{}, content: nil}]
    }
  end

  defp build_digest_query do
    %Binary.Node{
      tag: "iq",
      attrs: %{"id" => "digest-1", "xmlns" => "encrypt", "type" => "get"},
      content: [%Binary.Node{tag: "digest", attrs: %{}, content: nil}]
    }
  end

  defp build_unified_session do
    %Binary.Node{
      tag: "ib",
      attrs: %{},
      content: [%Binary.Node{tag: "unified_session", attrs: %{"id" => "unified-1"}}]
    }
  end

  defp final_actions?([
         {:send_node, %Binary.Node{tag: "ib", content: [%Binary.Node{tag: "unified_session"}]}},
         :mark_authenticated
       ]),
       do: true

  defp final_actions?(_actions), do: false
end
