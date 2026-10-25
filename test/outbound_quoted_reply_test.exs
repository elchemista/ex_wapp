defmodule ExWapp.OutboundQuotedReplyTest do
  use ExUnit.Case, async: true

  alias ExWapp.Message
  alias WAWebProtobufsE2E.{ContextInfo, ExtendedTextMessage}
  alias WAWebProtobufsE2E.Message, as: ProtoMessage
  alias ExWapp.Session
  alias ExWapp.Session.Worker.Outbound

  defmodule SessionStub do
    use GenServer

    def start_link(owner), do: GenServer.start_link(__MODULE__, owner)

    @impl true
    def init(owner), do: {:ok, owner}

    @impl true
    def handle_call({:send_message, message}, _from, owner) do
      send(owner, {:canonical_message, message})
      {:reply, {:ok, message.id || "generated-id"}, owner}
    end
  end

  test "text sends keep the quoted context instead of dropping the send options" do
    proto =
      Outbound.outbound_proto("reply body",
        quoted_id: "3EB0QUOTED",
        quoted_participant: "15550002222@s.whatsapp.net"
      )

    assert %ProtoMessage{
             conversation: nil,
             extendedTextMessage: %ExtendedTextMessage{
               text: "reply body",
               contextInfo: %ContextInfo{
                 stanzaID: "3EB0QUOTED",
                 participant: "15550002222@s.whatsapp.net"
               }
             }
           } = proto

    assert {:ok, encoded, _size} = ProtoMessage.encode(proto)
    assert :binary.match(IO.iodata_to_binary(encoded), "3EB0QUOTED") != :nomatch
  end

  test "text sends without a quote or mentions stay plain conversations" do
    assert %ProtoMessage{conversation: "hello", extendedTextMessage: nil} =
             Outbound.outbound_proto("hello", [])

    assert %ProtoMessage{conversation: "hello", extendedTextMessage: nil} =
             Outbound.outbound_proto("hello", message_node_type: "text")
  end

  test "a prebuilt protobuf still wins over the text options" do
    prebuilt = %ProtoMessage{conversation: "prebuilt"}

    assert ^prebuilt =
             Outbound.outbound_proto("ignored", proto_message: prebuilt, quoted_id: "3EB0QUOTED")
  end

  test "session text sends carry the quote options into the canonical message" do
    session = start_supervised!({SessionStub, self()})
    jid = "15550001111@s.whatsapp.net"

    assert {:ok, "reply-id"} =
             Session.send_text(session, jid, "reply body",
               id: "reply-id",
               quoted_id: "3EB0QUOTED",
               quoted_participant: "15550002222@s.whatsapp.net"
             )

    assert_receive {:canonical_message, %Message{id: "reply-id", type: :text, opts: opts}}
    assert opts[:quoted_id] == "3EB0QUOTED"
    assert opts[:quoted_participant] == "15550002222@s.whatsapp.net"
  end
end
