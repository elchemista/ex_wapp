defmodule ExWapp.Messages do
  @moduledoc """
  Helpers for constructing WhatsApp message protocol payloads and nodes.

  This module handles:
  - Message ID generation
  - Message node construction
  - Protobuf payload encoding
  """

  alias ExWapp.{Binary, JID, Media}

  alias ExWapp.Proto.{
    ContextInfo,
    ExtendedTextMessage,
    Message,
    MessageKey,
    PeerDataOperationRequestMessage,
    PlaceholderMessageResendRequest,
    ProtocolMessage
  }

  @typedoc """
  Shared outbound send options used when building protobuf payloads.
  """
  @type send_opts :: [
          quoted_id: String.t(),
          quoted_participant: String.t(),
          mentions: [String.t()]
        ]

  @web_message_id_prefix "3EB0"

  @doc """
  Generates a unique message ID matching whatsmeow/Baileys/whatsapp-rust format.

  Format: "3EB0" + uppercase hex of SHA256(timestamp + ownJID@c.us + 16 random bytes)[:9]
  Total length: 22 characters (4 prefix + 18 hex).
  """
  @spec generate_id(String.t() | nil) :: String.t()
  def generate_id(own_jid \\ nil) do
    timestamp = System.system_time(:second)
    <<ts::big-unsigned-64>> = <<timestamp::big-unsigned-64>>
    random = :crypto.strong_rand_bytes(16)

    jid_bytes =
      case own_jid do
        jid when is_binary(jid) and jid != "" ->
          # Extract user part and append @c.us (whatsmeow format)
          user_part =
            jid
            |> String.replace(~r/:(\d+)@/, "@")
            |> String.split("@", parts: 2)
            |> hd()

          user_part <> "@c.us"

        _ ->
          ""
      end

    data = <<ts::big-unsigned-64>> <> jid_bytes <> random
    <<first_9::binary-size(9), _rest::binary>> = :crypto.hash(:sha256, data)

    @web_message_id_prefix <> Base.encode16(first_9, case: :upper)
  end

  @doc """
  Builds a text message protobuf.

  WhatsApp uses a simpler `conversation` field for plain text, but switches to
  `extendedTextMessage` as soon as reply metadata or mentions are present.
  """
  @spec build_text_proto(String.t(), send_opts()) :: Message.t()
  def build_text_proto(text, opts \\ []) do
    mentions = Keyword.get(opts, :mentions, [])
    quoted_id = Keyword.get(opts, :quoted_id)

    if quoted_id || mentions != [] do
      # Use ExtendedTextMessage for quotes/mentions
      context_info = build_context_info(opts)

      %Message{
        extendedTextMessage: %ExtendedTextMessage{
          text: text,
          contextInfo: context_info
        }
      }
    else
      # Simple conversation message
      %Message{conversation: text}
    end
  end

  @doc """
  Builds an image message protobuf from uploaded media metadata.

  The upload struct already contains the cryptographic hashes, CDN URL, media
  key, and direct path returned by WhatsApp. This function only maps that data
  into the protobuf fields expected by the E2E message payload.
  """
  @spec build_image_proto(Media.Upload.t(), keyword()) :: Message.t()
  def build_image_proto(%Media.Upload{} = upload, opts \\ []) do
    %Message{
      imageMessage: %ExWapp.Proto.ImageMessage{
        # These fields are the server-issued media reference the recipient will use
        # to download and verify the encrypted payload.
        URL: upload.url,
        mimetype: Keyword.get(opts, :mimetype, "image/jpeg"),
        caption: Keyword.get(opts, :caption),
        fileSHA256: upload.file_sha256,
        fileLength: upload.file_length,
        height: Keyword.get(opts, :height),
        width: Keyword.get(opts, :width),
        mediaKey: upload.media_key,
        fileEncSHA256: upload.file_enc_sha256,
        directPath: upload.direct_path,
        mediaKeyTimestamp: Keyword.get(opts, :media_key_timestamp, System.system_time(:second)),
        JPEGThumbnail: Keyword.get(opts, :thumbnail),
        contextInfo: build_context_info(opts)
      }
    }
  end

  @doc """
  Builds an audio message protobuf from uploaded media metadata.

  Audio messages use a different protobuf field number than images and may
  carry voice-note specific metadata such as `PTT`, duration, and waveform.
  """
  @spec build_audio_proto(Media.Upload.t(), keyword()) :: Message.t()
  def build_audio_proto(%Media.Upload{} = upload, opts \\ []) do
    %Message{
      audioMessage: %ExWapp.Proto.AudioMessage{
        # Voice-note playback relies on the same CDN/hashes/media-key tuple used
        # for images, with extra audio-specific metadata layered on top.
        URL: upload.url,
        mimetype: Keyword.get(opts, :mimetype, "audio/ogg; codecs=opus"),
        fileSHA256: upload.file_sha256,
        fileLength: upload.file_length,
        seconds: Keyword.get(opts, :duration) || Keyword.get(opts, :seconds),
        PTT: Keyword.get(opts, :ptt),
        mediaKey: upload.media_key,
        fileEncSHA256: upload.file_enc_sha256,
        directPath: upload.direct_path,
        mediaKeyTimestamp: Keyword.get(opts, :media_key_timestamp, System.system_time(:second)),
        contextInfo: build_context_info(opts),
        waveform: Keyword.get(opts, :waveform)
      }
    }
  end

  @doc """
  Builds a peer-data placeholder resend request for an undecryptable message.
  """
  @spec build_placeholder_resend_proto(String.t(), String.t() | nil, String.t()) :: Message.t()
  def build_placeholder_resend_proto(chat_jid, sender_jid, message_id) do
    %Message{
      protocolMessage: %ProtocolMessage{
        type: :PEER_DATA_OPERATION_REQUEST_MESSAGE,
        peerDataOperationRequestMessage: %PeerDataOperationRequestMessage{
          peerDataOperationRequestType: :PLACEHOLDER_MESSAGE_RESEND,
          placeholderMessageResendRequest: [
            %PlaceholderMessageResendRequest{
              messageKey: build_message_key(chat_jid, sender_jid, message_id)
            }
          ]
        }
      }
    }
  end

  @doc """
  Builds a message key for referring to an existing WhatsApp message.
  """
  @spec build_message_key(String.t(), String.t() | nil, String.t()) :: MessageKey.t()
  def build_message_key(chat_jid, sender_jid, message_id) do
    sender_jid = normalize_optional_jid(sender_jid)
    chat_jid = normalize_optional_jid(chat_jid)

    %MessageKey{
      remoteJID: chat_jid,
      fromMe: false,
      id: message_id,
      participant: message_key_participant(chat_jid, sender_jid)
    }
  end

  @doc """
  Builds context info for replies and mentions.

  Returning `nil` keeps the protobuf lean for plain messages that do not need
  threading or mention metadata.
  """
  @spec build_context_info(send_opts()) :: ContextInfo.t() | nil
  def build_context_info(opts) do
    quoted_id = Keyword.get(opts, :quoted_id)
    quoted_participant = Keyword.get(opts, :quoted_participant)
    mentions = Keyword.get(opts, :mentions, [])

    if quoted_id || mentions != [] do
      %ContextInfo{
        stanzaID: quoted_id,
        participant: quoted_participant,
        mentionedJID: mentions
      }
    else
      nil
    end
  end

  defp message_key_participant(chat_jid, sender_jid) do
    cond do
      sender_jid == "" ->
        nil

      JID.group?(chat_jid) ->
        strip_device(sender_jid)

      true ->
        nil
    end
  end

  defp normalize_optional_jid(%JID{} = jid), do: JID.to_string(jid) |> normalize_optional_jid()

  defp normalize_optional_jid(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
  end

  defp normalize_optional_jid(_), do: ""

  defp strip_device(jid) when is_binary(jid), do: String.replace(jid, ~r/:(\d+)@/, "@")

  @doc """
  Builds the binary XML node wrapper for an outbound message payload.

  The payload passed into this function is already protobuf-encoded. WhatsApp
  still expects it to live inside an `<enc>` node, which is later encrypted by
  the Signal send pipeline.
  """
  @spec build_message_node(String.t(), String.t(), binary(), integer(), keyword()) ::
          Binary.Node.t()
  def build_message_node(jid, message_id, payload, timestamp, _opts \\ []) do
    # Message nodes keep transport routing metadata in XML attrs while the real
    # message body travels inside the nested encrypted payload node.
    type = if JID.group?(jid), do: "text", else: "text"

    attrs = %{
      "id" => message_id,
      "to" => jid,
      "type" => type,
      "t" => Integer.to_string(timestamp)
    }

    # Signal encryption wraps the protobuf payload later; this layer only shapes
    # the stanza that the session worker will send on the wire.
    enc_node = %Binary.Node{
      tag: "enc",
      attrs: %{
        "v" => "2",
        "type" => "msg"
      },
      content: Binary.raw(payload)
    }

    %Binary.Node{
      tag: "message",
      attrs: attrs,
      content: [enc_node]
    }
  end

  @doc """
  Builds a receipt node for read or played acknowledgments.
  """
  @spec build_receipt_node(String.t(), [String.t()], String.t()) :: Binary.Node.t()
  def build_receipt_node(jid, message_ids, type) do
    list_nodes =
      Enum.map(message_ids, fn id ->
        %Binary.Node{
          tag: "item",
          attrs: %{"id" => id},
          content: nil
        }
      end)

    %Binary.Node{
      tag: "receipt",
      attrs: %{
        "to" => jid,
        "type" => type,
        "id" => List.first(message_ids)
      },
      content: [
        %Binary.Node{
          tag: "list",
          attrs: %{},
          content: list_nodes
        }
      ]
    }
  end

  @doc """
  Builds a presence subscription request.
  """
  @spec build_presence_subscribe(String.t()) :: Binary.Node.t()
  def build_presence_subscribe(jid) do
    %Binary.Node{
      tag: "presence",
      attrs: %{
        "to" => jid,
        "type" => "subscribe"
      },
      content: nil
    }
  end

  @doc """
  Builds a typing indicator node.

  WhatsApp represents typing state as a nested `chatstate` stanza with either a
  `composing` or `paused` child tag.
  """
  @spec build_typing(String.t(), boolean()) :: Binary.Node.t()
  def build_typing(jid, composing \\ true) do
    state = if composing, do: "composing", else: "paused"

    %Binary.Node{
      tag: "chatstate",
      attrs: %{"to" => jid},
      content: [
        %Binary.Node{
          tag: state,
          attrs: %{},
          content: nil
        }
      ]
    }
  end
end
