defmodule ExWapp.Release016FeaturesTest do
  use ExUnit.Case, async: true
  alias ExWapp.{Media, Message}
  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.Inbound.Content, as: Inbound
  alias ExWapp.Session.Outbound.{Command, Content}
  alias ExWapp.Session.MessageNode
  alias WAWebProtobufsE2E.Message, as: Proto

  # Fixtures generated independently with protoc from the pinned upstream schema.
  test "history request uses seconds, explicit direction and the upstream field numbers" do
    bytes =
      Base.decode16!(
        "6224101082011F0803221B0A07313233406C69641206616E63686F72180020322880A4A7DA06"
      )

    anchor = %{id: "anchor", from_me: false, timestamp: 1_800_000_000}

    assert {:ok, proto, _} =
             Content.prepare(self(), %{}, Message.history_request("123@lid", anchor))

    assert proto == Proto.decode!(bytes)
    assert IO.iodata_to_binary(elem(Proto.encode!(proto), 0)) == bytes
  end

  test "reactions preserve the target key and removal through the canonical content contract" do
    proto =
      Proto.decode!(
        Base.decode16!(
          "F202280A1D0A0831323340672E757310001A067461726765742207343536406C696412002080A0F1C2B134"
        )
      )

    wrapped = %Proto{deviceSentMessage: %WAWebProtobufsE2E.DeviceSentMessage{message: proto}}
    content = Inbound.decode_message(wrapped, <<>>)
    assert content.kind == :reaction
    assert content.text == nil

    assert content.reaction == %{
             message_id: "target",
             chat_jid: "123@g.us",
             from_me: false,
             participant: "456@lid",
             text: "",
             sender_timestamp_ms: 1_800_000_000_000
           }

    legacy = ExWapp.Message.Content.to_legacy(content)
    assert ExWapp.Message.Content.from_legacy(legacy).reaction == content.reaction
    store = ExWapp.Store.Memory.new()

    :ok =
      ExWapp.Chat.merge_messages(store, "123@g.us", [
        Map.merge(legacy, %{id: "reaction", timestamp: 1, content: content})
      ])

    assert [%{reaction: reaction, content: %{kind: :reaction}}] =
             ExWapp.Chat.messages(store, "123@g.us")

    assert reaction.text == ""
  end

  test "reaction send normalizes group participants and emits removal attributes on every encrypted branch" do
    for text <- ["👍", ""] do
      message = Message.reaction("123@g.us", "target", text, participant: "456:7@lid")
      assert {:ok, proto, opts} = Content.prepare(self(), %{}, message)
      assert proto.reactionMessage.key.participant == "456@lid"
      assert proto.reactionMessage.key.fromMe == false
      assert proto.reactionMessage.text == text
      assert is_integer(proto.reactionMessage.senderTimestampMS)

      node = %Node{
        tag: "message",
        attrs: %{},
        content: [
          %Node{tag: "enc", attrs: %{"type" => "skmsg"}, content: <<1>>},
          %Node{
            tag: "participants",
            content: [MessageNode.build_participant_encrypted_node("456@lid", <<2>>, :prekey)]
          }
        ]
      }

      updated = MessageNode.apply_outbound_options(node, opts)
      assert updated.attrs["type"] == "reaction"
      assert updated.attrs["edit"] == if(text == "", do: "7", else: nil)
      [enc, %{content: [%{content: [participant_enc]}]}] = updated.content
      assert enc.attrs["decrypt-fail"] == "hide"
      assert participant_enc.attrs["decrypt-fail"] == "hide"
      assert enc.content == <<1>>
    end

    for jid <- ["123@lid", "123@s.whatsapp.net", "123@g.us"] do
      assert {:ok, proto, _} =
               Content.prepare(self(), %{}, Message.reaction(jid, "own", "👍", from_me: true))

      assert proto.reactionMessage.key.fromMe
      assert proto.reactionMessage.key.participant == nil
    end
  end

  test "malformed requests are rejected before any connection or upload" do
    anchor = %{id: "anchor", from_me: true, timestamp: 1_800_000_000}

    for bad <- [
          %{},
          %{anchor | id: ""},
          %{anchor | from_me: nil},
          %{anchor | timestamp: 0},
          %{anchor | timestamp: "yesterday"}
        ] do
      assert {:error, :invalid_history_anchor} =
               Command.prepare(Message.history_request("123@lid", bad))
    end

    for count <- [0, -1, 1001, "50"] do
      assert {:error, :invalid_history_count} =
               Command.prepare(Message.history_request("123@lid", anchor, count: count))
    end

    assert {:error, :unsupported_history_chat} =
             Command.prepare(Message.history_request("123@newsletter", anchor))

    assert {:error, :unsupported_reaction_chat} =
             Command.prepare(Message.reaction("123@newsletter", "id", "👍"))

    assert {:error, :missing_reaction_participant} =
             Command.prepare(Message.reaction("123@g.us", "id", "👍"))

    assert {:error, :invalid_reaction_target} =
             Command.prepare(Message.reaction("123@lid", "", "👍"))

    assert {:error, :invalid_reaction_text} =
             Command.prepare(Message.reaction("123@lid", "id", <<255>>))

    assert {:error, :invalid_reaction_from_me} =
             Command.prepare(Message.reaction("123@lid", "id", "👍", from_me: "true"))

    for type <- [:video, :sticker] do
      assert {:error, {:unsupported_media_source, :bad}} =
               Command.prepare(%Message{to: "123@lid", type: type, body: :bad})

      assert {:error, {:media_type_mismatch, ^type, :audio}} =
               Command.prepare(%Message{
                 to: "123@lid",
                 type: type,
                 body: %Media.Upload{type: :audio}
               })
    end
  end

  test "video and sticker use the correct independent HKDF domains and reject tampering" do
    key = :binary.list_to_bin(Enum.to_list(0..31))
    keys = Media.Crypto.derive_keys(key, :video)

    assert keys.iv <> keys.cipher_key <> keys.mac_key <> keys.ref_key ==
             Base.decode16!(
               "F1DEE5782CC4E2E7B07233B1E25DE59B8564567EE06FA7006EDAB56A13C2B0A1431BEB8EFE698EFAD0F258E65FEB5395259AD46118ADCF3CD134AE881831C6865DB31A8FA0BBCE7BC3BCB9FCF369FCDA9A63D5EB49EB03827D842400A27DBFB62EFC9EBEB6F62B45DF4575DE4A871856"
             )

    assert Media.Crypto.derive_keys(key, :sticker) == Media.Crypto.derive_keys(key, :image)
    refute keys == Media.Crypto.derive_keys(key, :image)

    for type <- [:video, :sticker] do
      assert {:ok, upload, body} = Media.Crypto.encrypt_upload("encoded-media", type)
      ref = Media.ref_from_upload(upload)
      assert {:ok, "encoded-media"} = Media.Crypto.decrypt_download(body, ref)
      <<first, rest::binary>> = body

      assert {:error, :invalid_media_hmac} =
               Media.Crypto.decrypt_download(<<Bitwise.bxor(first, 1), rest::binary>>, ref)
    end
  end

  test "video and animated WebP metadata survive the send and wrapped receive paths" do
    for {type, builder, mime} <- [
          {:video, &Message.video/3, "video/mp4"},
          {:sticker, &Message.sticker/3, "image/webp"}
        ] do
      {:ok, upload, _} = Media.Crypto.encrypt_upload("encoded-media", type)

      message =
        builder.("123@lid", %{upload | url: "https://example.test/media", direct_path: "/media"},
          caption: "clip",
          seconds: 3,
          width: 512,
          height: 512,
          animated: true,
          gif_playback: true,
          quoted_id: "quoted",
          quoted_participant: "456@lid",
          mentions: ["456@lid"]
        )

      assert {:ok, proto, opts} = Content.prepare(self(), %{}, message)
      assert opts[:mediatype] == if(type == :video, do: "gif", else: "sticker")
      encoded = IO.iodata_to_binary(elem(Proto.encode!(proto), 0))

      wrapped = %Proto{
        ephemeralMessage: %WAWebProtobufsE2E.FutureProofMessage{message: Proto.decode!(encoded)}
      }

      content = Inbound.decode_message(wrapped, encoded)
      assert content.kind == :media
      assert content.media.type == type
      assert content.media.mimetype == mime
      assert content.media.metadata.width == 512
      assert content.media.media_key == upload.media_key

      if type == :video do
        assert content.text == "clip"
        assert content.media.metadata.seconds == 3
        assert content.media.metadata.gif_playback
        assert proto.videoMessage.contextInfo.stanzaID == "quoted"
      else
        assert content.text == nil
        assert content.media.metadata.animated
        assert proto.stickerMessage.contextInfo.stanzaID == "quoted"
      end
    end
  end

  defmodule Adapter do
    @behaviour ExWapp.Client.Transport
    def connect(client), do: {:ok, client}

    def send_message(client, message) do
      send(client.metadata.owner, {:sent, message})
      {:ok, message.id}
    end
  end

  test "all four facade operations preserve typed messages across custom adapters" do
    client = ExWapp.new(transport: Adapter, metadata: %{owner: self()})
    anchor = %{id: "old", from_me: false, timestamp: 1_800_000_000}

    calls = [
      {:video, fn -> ExWapp.send_video(client, "123@lid", {:bytes, "mp4"}, caption: "clip") end},
      {:sticker,
       fn -> ExWapp.send_sticker(client, "123@lid", {:bytes, "webp"}, animated: true) end},
      {:reaction, fn -> ExWapp.send_reaction(client, "123@lid", "target", "👍") end},
      {:history_request, fn -> ExWapp.request_history(client, "123@lid", anchor, count: 20) end}
    ]

    for {type, call} <- calls do
      assert {:ok, _, id} = call.()
      assert_receive {:sent, %Message{type: ^type, id: ^id, to: "123@lid"}}
    end
  end
end
