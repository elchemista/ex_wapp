defmodule ExWapp.RetryReceiptHandlingTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.Receipt
  alias ExWapp.MessageHandler
  alias ExWapp.Session.OutboundQueue
  alias ExWapp.Session.Worker.NodeHandler
  alias ExWapp.Store

  defmodule AckTransport do
    def send_node(pid, node) when is_pid(pid) do
      send(pid, {:sent_node, node})
      :ok
    end

    def restart_stream(_pid), do: :ok
  end

  setup do
    ensure_runtime_started()
    :ok
  end

  test "retry receipt requests a resend and withholds its ack until dispatch" do
    store = Store.Memory.new(initial_data: %{})

    node = %Node{
      tag: "receipt",
      attrs: %{
        "from" => "15550001111:3@s.whatsapp.net",
        "id" => "3EB0AAAA000000000001",
        "type" => "retry",
        "recipient" => "15550009999@s.whatsapp.net"
      },
      content: [
        %Node{
          tag: "retry",
          attrs: %{
            "count" => "1",
            "id" => "3EB0AAAA000000000001",
            "t" => "1700000000",
            "v" => "1"
          }
        },
        %Node{tag: "keys", content: [%Node{tag: "identity", content: <<1, 2, 3>>}]}
      ]
    }

    assert {:ok, _state, [{:retry_outgoing_message, from, "3EB0AAAA000000000001", meta}]} =
             Receipt.handle_receipt(node, self(), %{store: store})

    assert String.starts_with?(from, "15550001111")
    assert meta.retry_count == 1
    assert meta.recipient == "15550009999@s.whatsapp.net"

    # The stanza ack is carried inside the request rather than emitted now.
    assert %Node{
             tag: "ack",
             attrs: %{
               "class" => "receipt",
               "id" => "3EB0AAAA000000000001",
               "to" => "15550001111:3@s.whatsapp.net",
               "type" => "retry",
               "recipient" => "15550009999@s.whatsapp.net"
             }
           } = meta.ack_node
  end

  test "retry child id wins over the receipt id and group retries keep the participant" do
    store = Store.Memory.new(initial_data: %{})

    node = %Node{
      tag: "receipt",
      attrs: %{
        "from" => "120363000000000001@g.us",
        "id" => "3EB0BBBB000000000002",
        "participant" => "15550002222:7@lid",
        "type" => "retry"
      },
      content: [
        %Node{
          tag: "retry",
          attrs: %{"count" => "2", "id" => "3EB0CCCC000000000003", "t" => "1700000000"}
        }
      ]
    }

    assert {:ok, _state, [{:retry_outgoing_message, from, "3EB0CCCC000000000003", meta}]} =
             Receipt.handle_receipt(node, self(), %{store: store})

    assert String.starts_with?(from, "120363000000000001")
    assert meta.retry_count == 2
    assert meta.participant == "15550002222:7@lid"
    refute Map.has_key?(meta, :recipient)
    assert %Node{tag: "ack", attrs: %{"participant" => "15550002222:7@lid"}} = meta.ack_node
  end

  test "non-retry receipts still ack immediately" do
    node = %Node{
      tag: "receipt",
      attrs: %{"from" => "15550001111@s.whatsapp.net", "id" => "3EB0DDDD000000000004"}
    }

    assert {:ok, _state, [{:send_node, %Node{tag: "ack", attrs: %{"class" => "receipt"}}}]} =
             Receipt.handle_receipt(node, self(), %{})
  end

  test "status stanzas get the immediate transport ack and are routed" do
    status = %Node{
      tag: "status",
      attrs: %{
        "from" => "120363000000000002@newsletter",
        "id" => "3EB0EEEE000000000005",
        "type" => "text"
      },
      content: [%Node{tag: "plaintext", content: <<1, 2, 3>>}]
    }

    assert [
             {:send_node,
              %Node{
                tag: "ack",
                attrs: %{
                  "class" => "status",
                  "id" => "3EB0EEEE000000000005",
                  "to" => "120363000000000002@newsletter",
                  "type" => "text"
                }
              }}
           ] = NodeHandler.immediate_actions(status)

    assert {:ok, %{}} = MessageHandler.handle_node(status, self(), %{})
  end

  test "the session acks a retry receipt once the resend has been dispatched or ruled out" do
    session_id = "retry_receipt_ack_#{System.unique_integer([:positive])}"

    {:ok, pid} =
      ExWapp.Session.Supervisor.start_session(session_id,
        store: ExWapp.Store.Memory,
        transport: AckTransport,
        reconnect: false
      )

    on_exit(fn -> ExWapp.Session.Supervisor.stop_all_sessions(session_id) end)

    test_pid = self()
    :sys.replace_state(pid, fn state -> %{state | status: :connected, conn: test_pid} end)
    OutboundQueue.set_conn(:sys.get_state(pid).outbound_queue, test_pid)

    ack = %Node{
      tag: "ack",
      attrs: %{
        "class" => "receipt",
        "id" => "3EB0FFFF000000000006",
        "to" => "15550001111@s.whatsapp.net",
        "type" => "retry"
      },
      content: nil
    }

    # Nothing is retained under that ID, so no retry worker starts — the
    # receipt is still acknowledged, just after the decision rather than before.
    send(
      pid,
      {:retry_outgoing_message, "15550001111@s.whatsapp.net", "3EB0FFFF000000000006",
       %{retry_count: 1, ack_node: ack}}
    )

    assert_receive {:sent_node, ^ack}, 2_000

    # Internal repairs carry no ack and must not emit one.
    send(
      pid,
      {:retry_outgoing_message, "15550001111@s.whatsapp.net", "3EB0FFFF000000000007", %{}}
    )

    refute_receive {:sent_node, %Node{tag: "ack"}}, 300
  end

  defp ensure_runtime_started do
    if is_nil(Process.whereis(ExWapp.PubSub)) do
      start_supervised!({Phoenix.PubSub, name: ExWapp.PubSub})
    end

    if is_nil(Process.whereis(ExWapp.Session.Registry)) do
      start_supervised!({Registry, keys: :unique, name: ExWapp.Session.Registry})
    end

    if is_nil(Process.whereis(ExWapp.Session.Supervisor)) do
      start_supervised!(ExWapp.Session.Supervisor)
    end
  end
end
