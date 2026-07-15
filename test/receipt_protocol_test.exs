defmodule ExWapp.ReceiptProtocolTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.Receipt
  alias ExWapp.Store
  alias ExWapp.Store.Memory

  test "parses a normal receipt, malformed timestamps and a batched list" do
    node = %Node{
      tag: "receipt",
      attrs: %{
        "from" => "15550001111@s.whatsapp.net",
        "id" => "ID1",
        "type" => "read-self",
        "t" => "not-a-timestamp"
      },
      content: [
        %Node{
          tag: "list",
          attrs: %{},
          content: [
            %Node{tag: "item", attrs: %{"id" => "ID2"}},
            %Node{tag: "item", attrs: %{"id" => "ID3"}},
            %Node{tag: "item", attrs: %{}}
          ]
        }
      ]
    }

    assert [receipt] = Receipt.parse_receipts(node)
    assert receipt.message_ids == ["ID1", "ID2", "ID3"]
    assert receipt.status == :read
    assert receipt.timestamp == nil
  end

  test "fans grouped receipts out per message and participant" do
    group = "120363000000001@g.us"

    node = %Node{
      tag: "receipt",
      attrs: %{"from" => group, "type" => "read"},
      content: [
        participants("MSGA", [
          user("111@s.whatsapp.net", "1700"),
          user("222@s.whatsapp.net", "1701"),
          user("malformed", "1702")
        ]),
        participants("MSGB", [user("333@s.whatsapp.net", "bad")]),
        participants("", [user("444@s.whatsapp.net", "1704")])
      ]
    }

    assert [first, second, third] = Receipt.parse_receipts(node)

    assert %{message_ids: ["MSGA"], participant: "111@s.whatsapp.net", timestamp: 1700} =
             first

    assert %{message_ids: ["MSGA"], participant: "222@s.whatsapp.net", timestamp: 1701} =
             second

    assert %{message_ids: ["MSGB"], participant: "333@s.whatsapp.net", timestamp: nil} =
             third

    assert Enum.all?([first, second, third], &(&1.from == group and &1.status == :read))
  end

  test "updates every grouped message status without emitting an empty-id ack" do
    store = Memory.new([])
    group = "120363000000002@g.us"

    assert :ok =
             Store.upsert_messages(store, group, [
               %{id: "MSGA", timestamp: 1, status: :pending},
               %{id: "MSGB", timestamp: 2, status: :pending}
             ])

    node = %Node{
      tag: "receipt",
      attrs: %{"from" => group, "type" => "read"},
      content: [
        participants("MSGA", [user("111@s.whatsapp.net", "10")]),
        participants("MSGB", [user("222@s.whatsapp.net", "20")])
      ]
    }

    assert {:ok, %{store: ^store}, []} = Receipt.handle_receipt(node, self(), %{store: store})
    assert %{status: :read} = Store.find_message(store, group, "MSGA")
    assert %{status: :read} = Store.find_message(store, group, "MSGB")
  end

  test "normal receipt still emits the stanza ack and maps sender receipts to sent" do
    node = %Node{
      tag: "receipt",
      attrs: %{
        "from" => "15550001111@s.whatsapp.net",
        "id" => "RCPT1",
        "type" => "sender"
      }
    }

    assert [%{status: :sent}] = Receipt.parse_receipts(node)

    assert {:ok, _state, [{:send_node, %Node{tag: "ack", attrs: attrs}}]} =
             Receipt.handle_receipt(node, self(), %{})

    assert attrs == %{
             "class" => "receipt",
             "id" => "RCPT1",
             "to" => "15550001111@s.whatsapp.net",
             "type" => "sender"
           }
  end

  test "ack error fails a message while phash-only and duplicate acks stay successful" do
    store = Memory.new([])
    jid = "15550002222@s.whatsapp.net"

    assert :ok =
             Store.upsert_messages(store, jid, [
               %{id: "ACK_OK", timestamp: 1, status: :pending},
               %{id: "ACK_ERROR", timestamp: 2, status: :pending}
             ])

    phash_ack = %Node{
      tag: "ack",
      attrs: %{"id" => "ACK_OK", "to" => jid, "class" => "message", "phash" => "1:abc"}
    }

    assert {:ok, %{store: ^store}} = Receipt.handle_ack(phash_ack, self(), %{store: store})
    assert %{status: :sent} = Store.find_message(store, jid, "ACK_OK")

    # A duplicate successful ack is idempotent.
    assert {:ok, _state} = Receipt.handle_ack(phash_ack, self(), %{store: store})
    assert %{status: :sent} = Store.find_message(store, jid, "ACK_OK")

    error_ack = %Node{
      tag: "ack",
      attrs: %{"id" => "ACK_ERROR", "to" => jid, "class" => "message", "error" => "479"}
    }

    assert {:ok, _state} = Receipt.handle_ack(error_ack, self(), %{store: store})
    assert %{status: :failed} = Store.find_message(store, jid, "ACK_ERROR")

    unknown_ack = %Node{
      tag: "ack",
      attrs: %{"id" => "UNKNOWN", "to" => jid, "class" => "message"}
    }

    assert {:ok, _state} = Receipt.handle_ack(unknown_ack, self(), %{store: store})
  end

  defp participants(key, users),
    do: %Node{tag: "participants", attrs: %{"key" => key}, content: users}

  defp user(jid, timestamp),
    do: %Node{tag: "user", attrs: %{"jid" => jid, "t" => timestamp}}
end
