defmodule ExWapp.Session.Outbound.DirectTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Binary, Messages}
  alias ExWapp.Session.Account
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

  test "appends a PN-stored privacy token to a LID-addressed message" do
    pn = "15550002222@s.whatsapp.net"
    lid = "88888822222@lid"
    token = <<5, 6, 7, 8>>

    store =
      Memory.new(
        initial_data: %{
          lid_mapping: %{
            {:pn_to_lid, pn} => lid,
            {:lid_to_pn, lid} => pn
          },
          tctokens: %{pn => %{token: token, timestamp: "123"}}
        }
      )

    node =
      Direct.build_encrypted_message_node(
        lid,
        "message-with-token",
        [],
        store,
        false
      )

    assert node.attrs["peer_recipient_pn"] == pn

    assert %Binary.Node{tag: "tctoken", content: %Binary.Raw{data: ^token}} =
             List.last(node.content)
  end

  test "selects the local sender identity in the destination addressing family" do
    pn = "15550002222@s.whatsapp.net"
    lid = "70000002222@lid"

    store =
      Memory.new(
        initial_data: %{
          client_info: %{jid: pn, lid: lid}
        }
      )

    assert Account.local_account_sender_identity_for_destination(
             store,
             "70000001111:5@lid"
           ) == lid

    assert Account.local_account_sender_identity_for_destination(
             store,
             "15550001111:5@s.whatsapp.net"
           ) == pn
  end

  test "refuses mixed PN participants in a LID-addressed direct message" do
    lid_participant = %Binary.Node{
      tag: "to",
      attrs: %{"jid" => "70000001111:5@lid"},
      content: []
    }

    pn_participant = %Binary.Node{
      tag: "to",
      attrs: %{"jid" => "15550001111:7@s.whatsapp.net"},
      content: []
    }

    assert {:error, {:mixed_addressing_family, 1}} =
             Direct.validate_participant_family(
               "70000001111@lid",
               [lid_participant, pn_participant]
             )

    node =
      Direct.build_encrypted_message_node(
        "70000001111@lid",
        "mixed-family-message",
        [lid_participant, pn_participant],
        Memory.new(),
        false
      )

    assert [
             %Binary.Node{
               tag: "participants",
               content: [^lid_participant]
             }
           ] = node.content
  end
end
