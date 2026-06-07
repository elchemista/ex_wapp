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

  require Logger

  alias ExWapp.{Binary, Chat, Conn, JID}
  alias ExWapp.Proto.{Message, ExtendedTextMessage, ContextInfo}

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
      {:ok, payload} ->
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
    payload =
      []
      |> encode_ld_field(1, upload.url || "")
      |> encode_string_field(2, Keyword.get(opts, :mimetype, "image/jpeg"))
      |> encode_binary_field(3, upload.file_sha256)
      |> encode_binary_field(4, upload.file_enc_sha256)
      |> encode_binary_field(5, upload.media_key)
      |> encode_ld_field(6, upload.direct_path || "")
      |> encode_varint_field(7, upload.file_length || 0)
      |> encode_optional_string_field(8, Keyword.get(opts, :caption))
      |> IO.iodata_to_binary()

    %Message{__uf__: [{3, 2, payload}]}
  end

  @doc """
  Builds an audio message protobuf from uploaded media metadata.
  """
  @spec build_audio_proto(ExWapp.Media.Upload.t(), keyword()) :: Message.t()
  def build_audio_proto(%ExWapp.Media.Upload{} = upload, opts \\ []) do
    payload =
      []
      |> encode_ld_field(1, upload.url || "")
      |> encode_string_field(2, Keyword.get(opts, :mimetype, "audio/ogg; codecs=opus"))
      |> encode_binary_field(3, upload.file_sha256)
      |> encode_binary_field(4, upload.file_enc_sha256)
      |> encode_binary_field(5, upload.media_key)
      |> encode_ld_field(6, upload.direct_path || "")
      |> encode_varint_field(7, upload.file_length || 0)
      |> encode_bool_field(8, Keyword.get(opts, :ptt, false))
      |> encode_varint_field(9, Keyword.get(opts, :duration, 0))
      |> IO.iodata_to_binary()

    %Message{__uf__: [{8, 2, payload}]}
  end

  @doc """
  Builds a protocol message requesting resend of an unavailable placeholder.
  """
  @spec build_placeholder_resend_proto(String.t(), String.t(), String.t()) :: Message.t()
  def build_placeholder_resend_proto(chat_jid, sender_jid, message_id) do
    message_key =
      %ExWapp.Proto.MessageKey{
        remoteJID: chat_jid,
        fromMe: false,
        id: message_id,
        participant: strip_device(sender_jid)
      }
      |> ExWapp.Proto.MessageKey.encode!()

    resend_request = encode_ld_field([], 1, message_key) |> IO.iodata_to_binary()

    request_message =
      []
      |> encode_varint_field(1, 4)
      |> encode_ld_field(5, resend_request)
      |> IO.iodata_to_binary()

    %Message{
      protocolMessage: %ExWapp.Proto.ProtocolMessage{
        type: :PEER_DATA_OPERATION_REQUEST,
        __uf__: [{16, 2, request_message}]
      }
    }
  end

  @doc """
  Builds context info for replies and mentions.
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

  # ============================================================================
  # Internal Helpers
  # ============================================================================

  defp send_node(session, node) do
    try do
      conn = GenServer.call(session, :get_conn)

      if conn && Process.alive?(conn) do
        Conn.send_node(conn, node)
      else
        {:error, :not_connected}
      end
    catch
      :exit, _ -> {:error, :session_unavailable}
    end
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

  defp encode_optional_string_field(acc, _field_num, nil), do: acc

  defp encode_optional_string_field(acc, field_num, value),
    do: encode_string_field(acc, field_num, value)

  defp encode_string_field(acc, field_num, value) when is_binary(value),
    do: encode_ld_field(acc, field_num, value)

  defp encode_binary_field(acc, _field_num, nil), do: acc

  defp encode_binary_field(acc, field_num, value) when is_binary(value),
    do: encode_ld_field(acc, field_num, value)

  defp encode_ld_field(acc, field_num, value) when is_binary(value) do
    [acc, encode_varint(Bitwise.bsl(field_num, 3) + 2), encode_varint(byte_size(value)), value]
  end

  defp encode_varint_field(acc, field_num, value) when is_integer(value),
    do: [acc, encode_varint(Bitwise.bsl(field_num, 3)), encode_varint(value)]

  defp encode_bool_field(acc, field_num, value) when is_boolean(value),
    do: encode_varint_field(acc, field_num, if(value, do: 1, else: 0))

  defp encode_varint(n) when n < 128, do: <<n::8>>

  defp encode_varint(n) do
    <<Bitwise.bor(Bitwise.band(n, 0x7F), 0x80), encode_varint(Bitwise.bsr(n, 7))::binary>>
  end

  defp strip_device(jid) when is_binary(jid) do
    String.replace(jid, ~r/:\d+@/, "@")
  end
end
