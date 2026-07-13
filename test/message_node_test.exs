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
end
