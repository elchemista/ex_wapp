defmodule ExWapp.ReceiptProtocolTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.Ack
  alias ExWapp.Message.Handler.Receipt
  alias ExWapp.Session.OutboundQueue
  alias ExWapp.Session.Worker.NodeHandler
  alias ExWapp.Store
  alias ExWapp.Store.Memory

  defmodule QueueTransport do
    def send_node(conn, node) do
      send(conn, {:transport_send, node})
      :ok
    end

    def restart_stream(_conn), do: :ok
  end

  test "builds immediate message and call stanza acknowledgements" do
    message = %Node{
      tag: "message",
      attrs: %{
        "from" => "15550001111:7@s.whatsapp.net",
        "id" => "MSG_ACK_1",
        "type" => "text",
        "participant" => "15550003333:2@s.whatsapp.net",
        "recipient" => "15550004444@s.whatsapp.net"
      }
    }

    assert [
             {:send_node,
              %Node{
                tag: "ack",
                attrs: %{
                  "class" => "message",
                  "id" => "MSG_ACK_1",
                  "to" => "15550001111:7@s.whatsapp.net",
                  "participant" => "15550003333:2@s.whatsapp.net",
                  "recipient" => "15550004444@s.whatsapp.net"
                }
              }}
           ] = NodeHandler.immediate_actions(message)

    call = %Node{
      tag: "call",
      attrs: %{
        "from" => "15550001111@s.whatsapp.net",
        "id" => "CALL_ACK_1"
      },
      content: [%Node{tag: "offer", attrs: %{"call-id" => "CALL_MEDIA_1"}}]
    }

    assert {:ok,
            %Node{
              tag: "ack",
              attrs: %{
                "class" => "call",
                "id" => "CALL_ACK_1",
                "to" => "15550001111@s.whatsapp.net",
                "type" => "offer"
              }
            }} = Ack.build_immediate_ack(call)
  end

  test "uses call child correlation fields when the outer stanza omits them" do
    call = %Node{
      tag: "call",
      attrs: %{"from" => "15550001111@s.whatsapp.net"},
      content: [
        %Node{
          tag: "offer",
          attrs: %{
            "call-id" => "CALL_CHILD_ID",
            "participant" => "15550002222:3@s.whatsapp.net"
          }
        }
      ]
    }

    assert {:ok,
            %Node{
              tag: "ack",
              attrs: %{
                "class" => "call",
                "id" => "CALL_CHILD_ID",
                "to" => "15550001111@s.whatsapp.net",
                "type" => "offer",
                "participant" => "15550002222:3@s.whatsapp.net"
              }
            }} = Ack.build_immediate_ack(call)
  end

  test "does not emit uncorrelatable or duplicate immediate acknowledgements" do
    assert NodeHandler.immediate_actions(%Node{
             tag: "message",
             attrs: %{"from" => "15550001111@s.whatsapp.net"}
           }) == []

    assert NodeHandler.immediate_actions(%Node{
             tag: "notification",
             attrs: %{"from" => "15550001111@s.whatsapp.net", "id" => "NOTIFICATION_1"}
           }) == []
  end

  test "classifies a stream error ack child as a missing stanza acknowledgement" do
    stream_error = %Node{
      tag: "stream:error",
      attrs: %{},
      content: [
        %Node{
          tag: "ack",
          attrs: %{"class" => "call", "id" => "CALL_ACK_2", "type" => "offer"}
        }
      ]
    }

    assert {%{stats: %{}}, []} =
             NodeHandler.safe_handle_node(stream_error, %{session_id: "ack-test", stats: %{}})

    assert_receive {:connection_event,
                    {:transport,
                     {:closed, {:stream_error, "unknown", {:missing_stanza_ack, "call", "offer"}}}}}
  end

  test "stanza acknowledgements preempt queued application traffic" do
    {:ok, queue} =
      OutboundQueue.start_link(
        session: self(),
        transport: QueueTransport,
        flush_batch_size: 10
      )

    application_node = %Node{tag: "message", attrs: %{"id" => "APPLICATION_1"}}

    ack_node = %Node{
      tag: "ack",
      attrs: %{"class" => "call", "id" => "CALL_PRIORITY_1", "type" => "offer"}
    }

    OutboundQueue.enqueue_node(queue, application_node)
    OutboundQueue.enqueue_priority_node(queue, ack_node)
    OutboundQueue.set_conn(queue, self())

    assert_receive {:transport_send, ^ack_node}
    assert_receive {:transport_send, ^application_node}

    GenServer.stop(queue)
  end

  test "session queues a call acknowledgement at the connection boundary" do
    {:ok, session} =
      GenServer.start(ExWapp.Session.Worker,
        store: Memory,
        transport: QueueTransport,
        runtime: [health: [check_interval_ms: 60_000]]
      )

    queue = :sys.get_state(session).outbound_queue
    OutboundQueue.set_conn(queue, self())

    call = %Node{
      tag: "call",
      attrs: %{"from" => "15550001111@s.whatsapp.net", "id" => "CALL_BOUNDARY_1"},
      content: [%Node{tag: "offer", attrs: %{}}]
    }

    send(session, {:connection_event, {:connection_message, call}})

    assert_receive {:transport_send,
                    %Node{
                      tag: "ack",
                      attrs: %{
                        "class" => "call",
                        "id" => "CALL_BOUNDARY_1",
                        "to" => "15550001111@s.whatsapp.net",
                        "type" => "offer"
                      }
                    }},
                   1_000

    GenServer.stop(session)
  end

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
