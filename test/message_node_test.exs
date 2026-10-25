defmodule ExWapp.Session.MessageNodeTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Session.MessageNode

  test "applies direct message options and appends additional nodes" do
    encrypted = %Binary.Node{
      tag: "enc",
      attrs: %{"type" => "msg", "v" => "2"},
      content: nil
    }

    metadata = %Binary.Node{
      tag: "meta",
      attrs: %{"event_type" => "creation"},
      content: nil
    }

    node = %Binary.Node{
      tag: "message",
      attrs: %{"type" => "text", "mediatype" => "legacy"},
      content: [encrypted]
    }

    updated =
      MessageNode.apply_outbound_options(node,
        message_node_type: "event",
        mediatype: "image",
        additional_message_nodes: [metadata]
      )

    assert updated.attrs == %{"type" => "event"}
    assert [%Binary.Node{attrs: encrypted_attrs}, ^metadata] = updated.content
    assert encrypted_attrs["mediatype"] == "image"
  end

  test "applies mediatype to every participant encrypted payload" do
    participants = [
      MessageNode.build_participant_encrypted_node(
        "19995550101@s.whatsapp.net",
        <<1>>,
        :whisper
      ),
      MessageNode.build_participant_encrypted_node(
        "19995550101:9@s.whatsapp.net",
        <<2>>,
        :prekey
      )
    ]

    identity = %Binary.Node{
      tag: "device-identity",
      attrs: %{},
      content: nil
    }

    node = %Binary.Node{
      tag: "message",
      attrs: %{"type" => "text"},
      content: [
        %Binary.Node{
          tag: "participants",
          attrs: %{},
          content: participants
        },
        identity
      ]
    }

    updated =
      MessageNode.apply_outbound_options(node,
        message_node_type: "media",
        mediatype: "ptt"
      )

    assert updated.attrs == %{"type" => "media"}

    assert [
             %Binary.Node{tag: "participants", content: updated_participants},
             ^identity
           ] = updated.content

    assert Enum.all?(updated_participants, fn %Binary.Node{content: [encrypted]} ->
             encrypted.attrs["mediatype"] == "ptt"
           end)
  end

  test "leaves encrypted payloads unchanged when mediatype is absent" do
    encrypted = %Binary.Node{
      tag: "enc",
      attrs: %{"type" => "msg", "v" => "2"},
      content: nil
    }

    node = %Binary.Node{
      tag: "message",
      attrs: %{"type" => "text"},
      content: [encrypted]
    }

    updated = MessageNode.apply_outbound_options(node, message_node_type: "text")

    assert updated == node
  end

  test "string encryption types survive participant encoding with the original ciphertext" do
    for {input, wire_type} <- [
          {"prekey", "pkmsg"},
          {"pkmsg", "pkmsg"},
          {"msg", "msg"},
          {:unknown, "msg"}
        ] do
      node =
        MessageNode.build_participant_encrypted_node(
          "15550001111:7@s.whatsapp.net",
          <<0, 255, 128>>,
          input
        )

      assert %Binary.Node{content: [encrypted]} = node |> Binary.encode!() |> Binary.decode!()
      assert encrypted.attrs["type"] == wire_type
      assert encrypted.content == Binary.raw(<<0, 255, 128>>)
    end
  end

  test "media options preserve existing metadata beside direct and participant payloads" do
    metadata = %Binary.Node{tag: "meta", attrs: %{"name" => "preserve"}}

    participant =
      MessageNode.build_participant_encrypted_node("15550001111@s.whatsapp.net", <<1>>, :prekey)

    [encrypted] = participant.content
    node = %Binary.Node{tag: "message", attrs: %{}, content: [encrypted, metadata]}

    updated =
      MessageNode.apply_outbound_options(node, mediatype: "image", additional_message_nodes: nil)

    assert [enc, ^metadata] = updated.content
    assert enc.attrs["mediatype"] == "image"

    node = %{
      node
      | content: [%Binary.Node{tag: "participants", content: [participant, metadata]}]
    }

    updated = MessageNode.apply_outbound_options(node, mediatype: "image")
    assert [%Binary.Node{content: [%Binary.Node{content: [enc]}, ^metadata]}] = updated.content
    assert enc.attrs["mediatype"] == "image"

    assert MessageNode.extract_participant_jids([participant, metadata, nil]) == [
             "15550001111@s.whatsapp.net"
           ]

    assert MessageNode.extract_participant_jids(nil) == []

    assert MessageNode.maybe_put_message_attr(%{"type" => "media"}, "id", nil) == %{
             "type" => "media"
           }
  end
end
