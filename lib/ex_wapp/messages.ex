defmodule ExWapp.Messages do
  @moduledoc """
  High-level helpers for constructing and sending WhatsApp messages.

  This module handles:
  - Message ID generation
  - Message node construction
  - Protobuf payload encoding
  - Message routing (direct, group, broadcast)

  ## Message Flow

      1. User calls send_text/3
      2. Message proto is built and encoded
      3. Binary node is constructed with proper attributes
      4. Signal encryption is applied (when implemented)
      5. Node is sent via the connection

  ## Example

      # Simple text message
      ExWapp.Messages.send_text(session, "1234567890@s.whatsapp.net", "Hello!")

      # Reply to a message
      ExWapp.Messages.send_text(session, jid, "Reply text",
        quoted_id: "ABC123",
        quoted_participant: "sender@s.whatsapp.net"
      )
  """
  alias ExWapp.{Binary, Chat, Conn, JID}
  alias WACommon.MessageKey

  alias WAWebProtobufsE2E.{
    AudioMessage,
    ContactMessage,
    ContextInfo,
    DocumentMessage,
    EventMessage,
    ExtendedTextMessage,
    ImageMessage,
    LocationMessage,
    Message,
    MessageContextInfo,
    PeerDataOperationRequestMessage,
    ProtocolMessage
  }

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
  Sends a text message to a JID.

  ## Options

    * `:quoted_id` - ID of message to reply to
    * `:quoted_participant` - JID of quoted message sender (for groups)
    * `:mentions` - List of JIDs to mention

  ## Returns

    * `{:ok, message_id}` - Message was queued for sending
    * `{:error, reason}` - Failed to send
  """
  @spec send_text(pid(), String.t(), String.t(), send_opts()) ::
          {:ok, String.t()} | {:error, term()}
  def send_text(session, jid, text, opts \\ [])
      when is_pid(session) and is_binary(jid) and is_binary(text) do
    message_id = generate_id()
    timestamp = System.system_time(:second)

    # Build the message proto
    proto = build_text_proto(text, opts)

    # Encode to protobuf binary
    case Message.encode(proto) do
      {:ok, iodata} ->
        payload = IO.iodata_to_binary(iodata)

        # Build the binary node
        node = build_message_node(jid, message_id, payload, timestamp, opts)

        # Record the outgoing message
        record_outgoing(session, jid, message_id, text, timestamp)

        # Send via connection
        case send_node(session, node) do
          :ok -> {:ok, message_id}
          error -> error
        end

      {:error, reason} ->
        {:error, {:proto_encode, reason}}
    end
  end

  @doc """
  Builds a text message protobuf.
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
  """
  @spec build_image_proto(ExWapp.Media.Upload.t(), keyword()) :: Message.t()
  def build_image_proto(%ExWapp.Media.Upload{} = upload, opts \\ []) do
    %Message{
      imageMessage: %ImageMessage{
        URL: upload.url,
        mimetype: Keyword.get(opts, :mimetype, "image/jpeg"),
        caption: Keyword.get(opts, :caption),
        fileSHA256: upload.file_sha256,
        fileLength: upload.file_length || 0,
        height: Keyword.get(opts, :height),
        width: Keyword.get(opts, :width),
        mediaKey: upload.media_key,
        fileEncSHA256: upload.file_enc_sha256,
        directPath: upload.direct_path,
        mediaKeyTimestamp: upload.media_key_timestamp,
        JPEGThumbnail: Keyword.get(opts, :jpeg_thumbnail),
        contextInfo: build_context_info(opts),
        viewOnce: Keyword.get(opts, :view_once)
      }
    }
  end

  @doc """
  Builds an audio message protobuf from uploaded media metadata.
  """
  @spec build_audio_proto(ExWapp.Media.Upload.t(), keyword()) :: Message.t()
  def build_audio_proto(%ExWapp.Media.Upload{} = upload, opts \\ []) do
    %Message{
      audioMessage: %AudioMessage{
        URL: upload.url,
        mimetype: Keyword.get(opts, :mimetype, "audio/ogg; codecs=opus"),
        fileSHA256: upload.file_sha256,
        fileLength: upload.file_length || 0,
        seconds: Keyword.get(opts, :seconds, Keyword.get(opts, :duration, 0)),
        PTT: Keyword.get(opts, :ptt, false),
        mediaKey: upload.media_key,
        fileEncSHA256: upload.file_enc_sha256,
        directPath: upload.direct_path,
        mediaKeyTimestamp: upload.media_key_timestamp,
        contextInfo: build_context_info(opts),
        waveform: Keyword.get(opts, :waveform),
        viewOnce: Keyword.get(opts, :view_once)
      }
    }
  end

  @doc """
  Builds a document message protobuf from uploaded media metadata.
  """
  @spec build_document_proto(ExWapp.Media.Upload.t(), keyword()) :: Message.t()
  def build_document_proto(%ExWapp.Media.Upload{} = upload, opts \\ []) do
    %Message{
      documentMessage: %DocumentMessage{
        URL: upload.url,
        mimetype: Keyword.get(opts, :mimetype, "application/octet-stream"),
        title: Keyword.get(opts, :title),
        fileSHA256: upload.file_sha256,
        fileLength: upload.file_length || 0,
        pageCount: Keyword.get(opts, :page_count),
        mediaKey: upload.media_key,
        fileName: Keyword.get(opts, :file_name) || "document",
        fileEncSHA256: upload.file_enc_sha256,
        directPath: upload.direct_path,
        mediaKeyTimestamp: upload.media_key_timestamp,
        contactVcard: Keyword.get(opts, :contact_vcard),
        JPEGThumbnail: Keyword.get(opts, :jpeg_thumbnail),
        contextInfo: build_context_info(opts),
        caption: Keyword.get(opts, :caption)
      }
    }
  end

  @doc """
  Builds a static or live GPS location protobuf.
  """
  @spec build_location_proto(number(), number(), keyword()) :: Message.t()
  def build_location_proto(latitude, longitude, opts \\ [])
      when is_number(latitude) and is_number(longitude) do
    %Message{locationMessage: build_location_message(latitude, longitude, opts)}
  end

  @doc """
  Builds a single WhatsApp contact-card protobuf.
  """
  @spec build_contact_proto(String.t(), String.t(), keyword()) :: Message.t()
  def build_contact_proto(display_name, vcard, opts \\ [])
      when is_binary(display_name) and is_binary(vcard) do
    %Message{
      contactMessage: %ContactMessage{
        displayName: display_name,
        vcard: vcard,
        contextInfo: build_context_info(opts),
        isSelfContact: Keyword.get(opts, :is_self_contact)
      }
    }
  end

  @doc """
  Builds WhatsApp's calendar event message (E2E Message field 75).

  WhatsApp Web also attaches a 32-byte message secret to event messages; it is
  generated automatically unless `:message_secret` is supplied.
  """
  @spec build_event_proto(String.t(), integer() | DateTime.t(), keyword()) :: Message.t()
  def build_event_proto(name, start_time, opts \\ []) when is_binary(name) do
    %Message{
      messageContextInfo: %MessageContextInfo{messageSecret: event_message_secret(opts)},
      eventMessage: %EventMessage{
        contextInfo: build_context_info(opts),
        isCanceled: Keyword.get(opts, :canceled),
        name: name,
        description: Keyword.get(opts, :description),
        location: event_location(Keyword.get(opts, :location)),
        joinLink: Keyword.get(opts, :join_link),
        startTime: unix_seconds(start_time),
        endTime: optional_unix_seconds(Keyword.get(opts, :end_time)),
        extraGuestsAllowed: Keyword.get(opts, :extra_guests_allowed),
        isScheduleCall: Keyword.get(opts, :scheduled_call),
        hasReminder: Keyword.get(opts, :has_reminder),
        reminderOffsetSec: Keyword.get(opts, :reminder_offset_seconds)
      }
    }
  end

  @doc """
  Builds a protocol message requesting resend of an unavailable placeholder.
  """
  @spec build_placeholder_resend_proto(String.t(), String.t(), String.t(), keyword()) ::
          Message.t()
  def build_placeholder_resend_proto(chat_jid, sender_jid, message_id, opts \\ []) do
    from_me = Keyword.get(opts, :from_me, false) == true

    participant =
      if not from_me and (JID.group?(chat_jid) or JID.broadcast?(chat_jid)) do
        strip_device(sender_jid)
      end

    %Message{
      protocolMessage: %ProtocolMessage{
        type: :PEER_DATA_OPERATION_REQUEST_MESSAGE,
        peerDataOperationRequestMessage: %PeerDataOperationRequestMessage{
          peerDataOperationRequestType: :PLACEHOLDER_MESSAGE_RESEND,
          placeholderMessageResendRequest: [
            %PeerDataOperationRequestMessage.PlaceholderMessageResendRequest{
              messageKey: %MessageKey{
                remoteJID: chat_jid,
                fromMe: from_me,
                ID: message_id,
                participant: participant
              }
            }
          ]
        }
      }
    }
  end

  @doc """
  Builds context info for replies and mentions.
  """
  @spec build_context_info(keyword()) :: ContextInfo.t() | nil
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

  @doc """
  Builds the binary XML node for a message.
  """
  @spec build_message_node(String.t(), String.t(), binary(), integer(), keyword()) ::
          Binary.Node.t()
  def build_message_node(jid, message_id, payload, timestamp, _opts \\ []) do
    # Determine message type and device info
    type = if JID.group?(jid), do: "text", else: "text"

    attrs = %{
      "id" => message_id,
      "to" => jid,
      "type" => type,
      "t" => Integer.to_string(timestamp)
    }

    # The payload needs to be encrypted with Signal
    # For now, create the structure without encryption
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
  Sends a read receipt for messages.
  """
  @spec send_read_receipt(pid(), String.t(), [String.t()]) :: :ok | {:error, term()}
  def send_read_receipt(session, jid, message_ids) when is_list(message_ids) do
    node = build_receipt_node(jid, message_ids, "read")
    send_node(session, node)
  end

  @doc """
  Sends a delivery receipt for a message.
  """
  @spec send_delivery_receipt(pid(), String.t(), String.t(), String.t() | nil) ::
          :ok | {:error, term()}
  def send_delivery_receipt(session, jid, message_id, participant \\ nil) do
    attrs = %{
      "id" => message_id,
      "to" => jid,
      "type" => "delivery"
    }

    attrs = if participant, do: Map.put(attrs, "participant", participant), else: attrs

    node = %Binary.Node{
      tag: "receipt",
      attrs: attrs,
      content: nil
    }

    send_node(session, node)
  end

  @doc """
  Builds a receipt node for read/played acknowledgments.
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
  """
  @spec build_typing(String.t(), boolean()) :: Binary.Node.t()
  def build_typing(jid, composing \\ true) do
    build_typing_node(jid, composing)
  end

  @doc """
  Builds a typing indicator node while preserving the legacy three-argument
  API. WhatsApp no longer accepts the local sender identity in chat-state
  attributes, so `from_jid` is intentionally ignored.
  """
  @spec build_typing(String.t(), String.t(), boolean()) :: Binary.Node.t()
  def build_typing(jid, from_jid, composing)
      when is_binary(from_jid) and from_jid != "" and is_boolean(composing) do
    build_typing_node(jid, composing)
  end

  defp build_typing_node(jid, composing) do
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

  defp send_node(session, node) do
    conn = GenServer.call(session, :get_conn)

    if conn && Process.alive?(conn) do
      Conn.send_node(conn, node)
    else
      {:error, :not_connected}
    end
  catch
    :exit, _ -> {:error, :session_unavailable}
  end

  defp record_outgoing(session, jid, message_id, text, timestamp) do
    message = %{
      id: message_id,
      from_me: true,
      timestamp: timestamp,
      text: text,
      status: :pending,
      participant: nil,
      raw: nil
    }

    Chat.add_message(session, jid, message)
  rescue
    _ -> :ok
  end

  @spec build_location_message(number(), number(), keyword()) :: LocationMessage.t()
  defp build_location_message(latitude, longitude, opts) do
    %LocationMessage{
      degreesLatitude: latitude * 1.0,
      degreesLongitude: longitude * 1.0,
      name: Keyword.get(opts, :name),
      address: Keyword.get(opts, :address),
      URL: Keyword.get(opts, :url),
      isLive: Keyword.get(opts, :is_live),
      accuracyInMeters: Keyword.get(opts, :accuracy),
      speedInMps: optional_float(Keyword.get(opts, :speed)),
      degreesClockwiseFromMagneticNorth: Keyword.get(opts, :bearing),
      comment: Keyword.get(opts, :comment),
      JPEGThumbnail: Keyword.get(opts, :jpeg_thumbnail),
      contextInfo: build_context_info(opts)
    }
  end

  @spec event_location(term()) :: LocationMessage.t() | nil
  defp event_location(location) when is_map(location) do
    case location_coordinates(location) do
      {:ok, latitude, longitude} ->
        build_location_message(latitude, longitude, event_location_opts(location))

      :error ->
        nil
    end
  end

  defp event_location(_location), do: nil

  @spec location_coordinates(map()) :: {:ok, number(), number()} | :error
  defp location_coordinates(location) do
    latitude = location_value(location, :latitude, "latitude")
    longitude = location_value(location, :longitude, "longitude")
    validate_location_coordinates(latitude, longitude)
  end

  @spec validate_location_coordinates(term(), term()) :: {:ok, number(), number()} | :error
  defp validate_location_coordinates(latitude, longitude)
       when is_number(latitude) and is_number(longitude),
       do: {:ok, latitude, longitude}

  defp validate_location_coordinates(_latitude, _longitude), do: :error

  @spec event_location_opts(map()) :: keyword()
  defp event_location_opts(location) do
    [
      name: location_value(location, :name, "name"),
      address: location_value(location, :address, "address"),
      url: location_value(location, :url, "url"),
      comment: location_value(location, :comment, "comment"),
      accuracy: location_value(location, :accuracy, "accuracy")
    ]
  end

  @spec location_value(map(), atom(), String.t()) :: term()
  defp location_value(location, atom_key, string_key),
    do: Map.get(location, atom_key) || Map.get(location, string_key)

  defp optional_float(nil), do: nil
  defp optional_float(value) when is_number(value), do: value * 1.0

  defp unix_seconds(%DateTime{} = value), do: DateTime.to_unix(value, :second)
  defp unix_seconds(value) when is_integer(value) and value >= 0, do: value

  defp optional_unix_seconds(nil), do: nil
  defp optional_unix_seconds(value), do: unix_seconds(value)

  defp event_message_secret(opts) do
    case Keyword.get(opts, :message_secret) do
      secret when is_binary(secret) and byte_size(secret) == 32 -> secret
      _ -> :crypto.strong_rand_bytes(32)
    end
  end

  defp strip_device(jid) when is_binary(jid) do
    String.replace(jid, ~r/:\d+@/, "@")
  end
end
