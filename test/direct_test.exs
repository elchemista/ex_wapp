defmodule ExWapp.Session.Outbound.DirectTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Binary, Messages}
  alias ExWapp.Session.Outbound.Direct
  alias ExWapp.Store.Memory

  test "preserves an explicit retry message ID" do
    assert Direct.message_id(
             [retry_message_id: "existing-message-id"],
             "15550009999@s.whatsapp.net"
           ) == "existing-message-id"
  end

  test "builds recipient and own-device payloads from one proto message" do
    proto = Messages.build_text_proto("hello", [])

    assert {:ok, payloads} =
             Direct.build_payloads(
               proto,
               "15550001111@s.whatsapp.net",
               []
             )

    assert is_binary(payloads.recipient)
    assert is_binary(payloads.own)
    assert payloads.raw_size > 0
    assert payloads.recipient != payloads.own
  end

  test "builds the final direct multi-device message node" do
    store = Memory.new()

    participant = %Binary.Node{
      tag: "to",
      attrs: %{"jid" => "15550001111:5@s.whatsapp.net"},
      content: []
    }

    node =
      Direct.build_encrypted_message_node(
        "15550001111:7@s.whatsapp.net",
        "message-id",
        [participant],
        store,
        false
      )

    assert %Binary.Node{
             tag: "message",
             attrs: %{
               "id" => "message-id",
               "to" => "15550001111@s.whatsapp.net",
               "type" => "text"
             },
             content: [
               %Binary.Node{
                 tag: "participants",
                 attrs: %{},
                 content: [^participant]
               }
             ]
           } = node
  end
end
