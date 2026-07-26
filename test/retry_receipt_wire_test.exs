defmodule ExWapp.RetryReceiptWireTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Binary.Node
  alias ExWapp.Session.Worker.{Inbound, ReceiptBuilder}
  alias ExWapp.Signal.{Keys, SessionStore}
  alias ExWapp.Store
  alias ExWapp.Test.FlushProbeStore

  test "second retry durably reserves a fresh collision-free key bundle" do
    identity = Keys.generate_key_pair()
    signed_prekey = Keys.generate_signed_prekey(identity, 17)
    existing_prekey = Keys.generate_prekey(101)
    highest_prekey = Keys.generate_prekey(150)

    store =
      FlushProbeStore.new(
        owner: self(),
        initial_data: %{
          pairing: %{device_identity: <<1, 2, 3, 4>>},
          signal: %{
            identity_key: identity,
            registration_id: 44_321,
            signed_prekeys: %{signed_prekey.id => signed_prekey},
            prekeys: %{
              existing_prekey.id => existing_prekey,
              highest_prekey.id => highest_prekey
            },
            next_prekey_id: 101
          }
        }
      )

    on_exit(fn -> FlushProbeStore.stop(store) end)

    node = %Node{
      tag: "message",
      attrs: %{
        "from" => "15550001111@s.whatsapp.net",
        "id" => "WIRE_RETRY_1",
        "type" => "text",
        "t" => "1730000300"
      },
      content: [
        %Node{tag: "enc", attrs: %{"type" => "pkmsg", "v" => "2"}, content: <<0x33, 0>>}
      ]
    }

    state = %{
      store: store,
      signal_sessions: SessionStore.new(),
      stats: %{messages_received: 0},
      retry_counters: %{}
    }

    {state, first_actions} = handle(node, state, store)
    first_retry = retry_node!(first_actions)

    assert first_retry.attrs == %{
             "id" => "WIRE_RETRY_1",
             "to" => "15550001111@s.whatsapp.net",
             "type" => "retry"
           }

    assert Enum.map(first_retry.content, & &1.tag) == ["retry", "registration"]
    assert [%Node{attrs: %{"count" => "1", "id" => "WIRE_RETRY_1"}} | _] = first_retry.content

    {state, second_actions} = handle(node, state, store)
    second_retry = retry_node!(second_actions)

    assert Enum.map(second_retry.content, & &1.tag) == ["retry", "registration", "keys"]
    assert [%Node{attrs: %{"count" => "2"}} | _] = second_retry.content

    assert %Node{tag: "keys", content: key_children} = List.last(second_retry.content)

    assert Enum.map(key_children, & &1.tag) == [
             "type",
             "identity",
             "key",
             "skey",
             "device-identity"
           ]

    assert state.retry_counters == %{
             "15550001111@s.whatsapp.net|WIRE_RETRY_1|" => 2
           }

    assert_receive :retry_store_flushed

    persisted_signal = Store.load!(store).signal
    assert persisted_signal.prekeys[101] == existing_prekey
    assert persisted_signal.prekeys[150] == highest_prekey
    assert persisted_signal.prekeys[151].id == 151
    assert persisted_signal.next_prekey_id == 152
  end

  test "retry keys are not advertised when their durable flush fails" do
    identity = Keys.generate_key_pair()
    signed_prekey = Keys.generate_signed_prekey(identity, 17)

    store =
      FlushProbeStore.new(
        owner: self(),
        flush_result: {:error, :disk_full},
        initial_data: %{
          pairing: %{device_identity: <<1, 2, 3, 4>>},
          signal: %{
            identity_key: identity,
            registration_id: 44_321,
            signed_prekeys: %{signed_prekey.id => signed_prekey},
            prekeys: %{},
            next_prekey_id: 101
          }
        }
      )

    on_exit(fn -> FlushProbeStore.stop(store) end)

    receipt =
      ReceiptBuilder.build_retry_receipt_ack(
        store,
        "15550001111@s.whatsapp.net",
        "WIRE_RETRY_FLUSH_FAILURE",
        nil,
        "1730000300",
        2,
        0,
        %{}
      )

    assert_receive :retry_store_flushed
    assert Enum.map(receipt.content, & &1.tag) == ["retry", "registration"]
  end

  test "a first retry for a prekey this device lost already carries the key bundle" do
    # From the capture this test exists for: the peer kept re-sending a `pkmsg`
    # built on prekey 815, which the store no longer had, and every retry receipt
    # asked for the same bytes back. A resend cannot fix a key that is gone — the
    # peer has to be moved onto a bundle this device holds, and the only thing
    # that does that is `<keys>`. Waiting for the second receipt to send it wastes
    # the round trip that was supposed to heal the conversation.
    identity = Keys.generate_key_pair()
    signed_prekey = Keys.generate_signed_prekey(identity, 1)
    lost_prekey = Keys.generate_prekey(815)

    {:ok, ciphertext, :prekey, _peer_sessions} =
      SessionStore.encrypt_message(
        SessionStore.new(),
        "own@s.whatsapp.net",
        "ciao",
        Keys.generate_key_pair(),
        416_037_980,
        %{
          registration_id: 416_037_980,
          identity_key: identity.public,
          signed_prekey: %{
            id: 1,
            public: signed_prekey.public,
            signature: signed_prekey.signature
          },
          prekey: %{id: 815, public: lost_prekey.public}
        }
      )

    store =
      FlushProbeStore.new(
        owner: self(),
        initial_data: %{
          pairing: %{device_identity: <<1, 2, 3, 4>>},
          signal: %{
            identity_key: identity,
            registration_id: 26_581,
            signed_prekeys: %{1 => signed_prekey},
            # The private half of 815 is exactly what went missing.
            prekeys: %{},
            next_prekey_id: 812
          }
        }
      )

    on_exit(fn -> FlushProbeStore.stop(store) end)

    node = %Node{
      tag: "message",
      attrs: %{
        "from" => "15550007777@s.whatsapp.net",
        "id" => "WIRE_LOST_PREKEY",
        "type" => "text",
        "t" => "1730000300"
      },
      content: [
        %Node{tag: "enc", attrs: %{"type" => "pkmsg", "v" => "2"}, content: ciphertext}
      ]
    }

    state = %{
      store: store,
      signal_sessions: SessionStore.new(),
      stats: %{messages_received: 0},
      retry_counters: %{}
    }

    {_state, actions} = handle(node, state, store)
    retry = retry_node!(actions)

    assert [%Node{attrs: %{"count" => "1"}} | _] = retry.content
    assert Enum.map(retry.content, & &1.tag) == ["retry", "registration", "keys"]

    # The advertised key is durable and clear of the id the peer still holds.
    assert_receive :retry_store_flushed
    signal = Store.load!(store).signal
    assert %{private: <<_::binary-size(32)>>} = signal.prekeys[816]
    assert signal.max_advertised_prekey_id == 816
  end

  test "retry counters remain scoped to the message ID" do
    base = %{stats: %{messages_received: 0}, retry_counters: %{}}

    first = invalid_message("MESSAGE_A")
    second = invalid_message("MESSAGE_B")

    {base, _actions} =
      Inbound.handle_message_node(first, base, &receipt_stub/5, &retry_stub/7)

    {base, _actions} =
      Inbound.handle_message_node(second, base, &receipt_stub/5, &retry_stub/7)

    assert base.retry_counters["15550001111@s.whatsapp.net|MESSAGE_A|"] == 1
    assert base.retry_counters["15550001111@s.whatsapp.net|MESSAGE_B|"] == 1
  end

  defp handle(node, state, store) do
    Inbound.handle_message_node(
      node,
      state,
      &ReceiptBuilder.build_receipt_ack/5,
      fn to, id, participant, timestamp, count, error, metadata ->
        ReceiptBuilder.build_retry_receipt_ack(
          store,
          to,
          id,
          participant,
          timestamp,
          count,
          error,
          metadata
        )
      end
    )
  end

  defp retry_node!(actions) do
    Enum.find_value(actions, fn
      {:send_node, %Node{tag: "receipt", attrs: %{"type" => "retry"}} = node} -> node
      _ -> nil
    end) || flunk("retry receipt was not emitted: #{inspect(actions)}")
  end

  defp invalid_message(id) do
    %Node{
      tag: "message",
      attrs: %{
        "from" => "15550001111@s.whatsapp.net",
        "id" => id,
        "type" => "text",
        "t" => "1730000301"
      },
      content: [%Node{tag: "enc", attrs: %{"type" => "msg"}, content: <<0x33, 0>>}]
    }
  end

  defp receipt_stub(to, id, participant, type, metadata),
    do: {:receipt, to, id, participant, type, metadata}

  defp retry_stub(to, id, participant, timestamp, count, error, metadata),
    do: {:retry, to, id, participant, timestamp, count, error, metadata}
end
