defmodule ExWapp.RetryReceiptWireTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Binary.Node
  alias ExWapp.Session.Worker.{Inbound, ReceiptBuilder}
  alias ExWapp.Signal.{Keys, SessionStore}
  alias ExWapp.Store
  alias ExWapp.Store.Memory

  test "first retry carries registration and second retry adds a fresh key bundle" do
    identity = Keys.generate_key_pair()
    signed_prekey = Keys.generate_signed_prekey(identity, 17)

    store =
      Memory.new(
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

    assert get_in(Store.load!(store), [:signal, :prekeys, 101]).id == 101
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
