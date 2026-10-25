defmodule ExWapp.MessagesTransportContractTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Chat, Messages, Store}
  alias ExWapp.Binary.Node
  alias WAWebProtobufsE2E.Message

  defmodule Session do
    use GenServer
    def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
    def init(opts), do: {:ok, Map.new(opts)}
    def handle_call(:get_conn, _from, state), do: {:reply, state.conn, state}
    def handle_call(:get_store, _from, state), do: {:reply, state.store, state}
  end

  setup do
    store = Store.Memory.new()
    on_exit(fn -> Store.Memory.stop(store) end)
    %{store: store}
  end

  test "legacy text sends record the same ID and text that reach the connection", ctx do
    session = start_supervised!({Session, store: ctx.store, conn: self()})
    jid = "15550001111@s.whatsapp.net"
    assert {:ok, id} = Messages.send_text(session, jid, "hello")

    assert_receive {:"$websockex_cast",
                    {:send_node, %Node{tag: "message", attrs: attrs, content: [enc]}}}

    assert attrs["id"] == id
    assert attrs["to"] == jid
    assert %Message{conversation: "hello"} = Message.decode!(enc.content.data)

    assert [%{id: ^id, text: "hello", from_me: true, status: :pending}] =
             Chat.messages(ctx.store, jid)
  end

  test "quoted text retains its context through the legacy send API", ctx do
    session = start_supervised!({Session, store: ctx.store, conn: self()})
    jid = "15550001111@s.whatsapp.net"

    assert {:ok, _} =
             Messages.send_text(session, jid, "reply",
               quoted_id: "original",
               quoted_participant: jid
             )

    assert_receive {:"$websockex_cast", {:send_node, %Node{content: [enc]}}}
    message = Message.decode!(enc.content.data)
    assert message.extendedTextMessage.text == "reply"
    assert message.extendedTextMessage.contextInfo.stanzaID == "original"
  end

  test "delivery receipts preserve the optional group participant", ctx do
    session = start_supervised!({Session, store: ctx.store, conn: self()})
    assert :ok = Messages.send_delivery_receipt(session, "15550001111@s.whatsapp.net", "direct")
    assert_receive {:"$websockex_cast", {:send_node, %Node{attrs: direct}}}

    assert direct == %{
             "to" => "15550001111@s.whatsapp.net",
             "id" => "direct",
             "type" => "delivery"
           }

    assert :ok = Messages.send_delivery_receipt(session, "123@g.us", "group", "70000001111@lid")
    assert_receive {:"$websockex_cast", {:send_node, %Node{attrs: group}}}
    assert group["participant"] == "70000001111@lid"
    assert group["to"] == "123@g.us"
  end

  test "offline and terminated sessions return errors instead of losing the caller", ctx do
    offline = start_supervised!({Session, store: ctx.store, conn: nil})
    assert {:error, :not_connected} = Messages.send_text(offline, "123@s.whatsapp.net", "pending")

    assert {:error, :not_connected} =
             Messages.send_delivery_receipt(offline, "123@s.whatsapp.net", "receipt")

    GenServer.stop(offline)

    assert {:error, :session_unavailable} =
             Messages.send_delivery_receipt(offline, "123@s.whatsapp.net", "receipt")
  end
end
