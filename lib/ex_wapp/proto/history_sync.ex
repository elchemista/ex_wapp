defmodule ExWapp.Proto.HistorySync do
  @moduledoc """
  Extracts WhatsApp history sync payloads embedded in protocol messages.

  Mirrors the flow used in reference clients:
  - `Message.protocolMessage.historySyncNotification`
  - `initialHistBootstrapInlinePayload` (zlib-compressed)
  - `HistorySync.conversations`

  Decoding uses the generated `WAWebProtobufsHistorySync` modules; this module
  only flattens the structs into the internal map contract.

  ## Inline chunks versus blob chunks

  WhatsApp delivers the bootstrap chunk inline (`initialHistBootstrapInlinePayload`),
  and the larger RECENT/FULL chunks as encrypted media the client is expected to
  download. Only the inline path is implemented: the bootstrap gives roughly the
  latest message per chat, which is enough for a chat list but not for reading
  conversation history.

  Blob chunks are **not** silently discarded — `extract_from_message/1` returns
  `{:pending_blob, blob_ref()}` with everything a download needs, so the gap is a
  missing consumer rather than lost data. To close it:

  1. teach `ExWapp.Media.Crypto` the `:history` type — HKDF context string
     `"WhatsApp History Keys"` (whatsmeow `download.go`), and allow it in
     `validate_ref/1`;
  2. hand the `blob_ref()` to the existing `ExWapp.Media.HTTP.download/3`, which
     already resolves `media_conn` from `direct_path` and verifies the HMAC;
  3. zlib-inflate the plaintext and feed it to `parse_history_payload/2` below —
     the parsing and flattening already work, they are what the inline path uses.

  Run the download off the inbound message path (a chunk can be megabytes);
  whatsmeow uses a dedicated worker with an idle timeout for exactly this reason.
  """

  alias ExWapp.{Call, JID}
  alias WAWebProtobufsE2E.Message
  alias WAWebProtobufsHistorySync.{Conversation, HistorySync, PhoneNumberToLIDMapping}
  alias WAWebProtobufsWeb.WebMessageInfo

  @type conversation_message :: %{
          id: String.t() | nil,
          from_me: boolean(),
          timestamp: non_neg_integer() | nil,
          text: String.t() | nil,
          participant: String.t() | nil,
          remote_jid: String.t() | nil,
          order_id: non_neg_integer() | nil
        }

  @type conversation :: %{
          jid: String.t(),
          name: String.t() | nil,
          unread_count: non_neg_integer() | nil,
          last_message_timestamp: non_neg_integer() | nil,
          pinned: boolean() | nil,
          archived: boolean() | nil,
          muted_until: non_neg_integer() | nil,
          is_group: boolean(),
          pn_jid: String.t() | nil,
          lid_jid: String.t() | nil,
          tc_token: binary() | nil,
          tc_token_timestamp: non_neg_integer() | nil,
          tc_token_sender_timestamp: non_neg_integer() | nil,
          messages: [conversation_message()]
        }

  @type t :: %{
          sync_type: atom() | non_neg_integer() | nil,
          conversations: [conversation()],
          lid_mappings: [{String.t(), String.t()}],
          call_log_records: [Call.t()]
        }

  @typedoc """
  Everything needed to download and decrypt a history-sync chunk delivered as
  media instead of inline. Kept verbatim from the notification so a future
  downloader needs no re-parse.
  """
  @type blob_ref :: %{
          sync_type: atom() | non_neg_integer() | nil,
          chunk_order: non_neg_integer() | nil,
          progress: non_neg_integer() | nil,
          oldest_msg_timestamp: non_neg_integer() | nil,
          media_key: binary() | nil,
          direct_path: String.t() | nil,
          enc_handle: String.t() | nil,
          file_sha256: binary() | nil,
          file_enc_sha256: binary() | nil,
          file_length: non_neg_integer() | nil
        }

  @max_message_unwrap_depth 6
  @jid_like_payload_pattern ~r/^[0-9+:-]+@(?:s\.whatsapp\.net|g\.us|lid|hosted\.lid)$/

  @spec extract_from_message(binary()) ::
          {:ok, t()}
          | {:pending_blob, blob_ref()}
          | :not_history_sync
          | {:error, term()}
  def extract_from_message(message_payload) when is_binary(message_payload) do
    case Message.decode(message_payload) do
      {:ok, %Message{protocolMessage: %{historySyncNotification: %{} = notification}}} ->
        extract_from_notification(notification)

      {:ok, _message} ->
        :not_history_sync

      {:error, reason} ->
        {:error, reason}
    end
  end

  def extract_from_message(_), do: :not_history_sync

  defp extract_from_notification(notification) do
    case notification.initialHistBootstrapInlinePayload do
      payload when is_binary(payload) and payload != "" ->
        payload
        |> inflate_history_payload()
        |> parse_history_payload(notification.syncType)

      _ ->
        {:pending_blob, blob_ref(notification)}
    end
  end

  @spec blob_ref(struct()) :: blob_ref()
  defp blob_ref(notification) do
    %{
      sync_type: notification.syncType,
      chunk_order: notification.chunkOrder,
      progress: notification.progress,
      oldest_msg_timestamp: notification.oldestMsgInChunkTimestampSec,
      media_key: notification.mediaKey,
      direct_path: notification.directPath,
      enc_handle: notification.encHandle,
      file_sha256: notification.fileSHA256,
      file_enc_sha256: notification.fileEncSHA256,
      file_length: notification.fileLength
    }
  end

  @doc """
  Flattens an already-inflated `HistorySync` payload into the internal contract.

  The inline path calls this after inflating the bootstrap payload; a future blob
  downloader can call it with the decrypted-and-inflated chunk instead.
  """
  @spec parse_history_payload({:ok, binary()} | binary(), term()) ::
          {:ok, t()} | {:error, term()}
  def parse_history_payload(payload, sync_type_from_notification) when is_binary(payload) do
    parse_history_payload({:ok, payload}, sync_type_from_notification)
  end

  def parse_history_payload({:ok, history_payload}, sync_type_from_notification) do
    with {:ok, %HistorySync{} = history} <- HistorySync.decode(history_payload) do
      conversations =
        history.conversations
        |> Enum.map(&parse_conversation/1)
        |> Enum.reject(&is_nil/1)

      explicit_mappings =
        history.phoneNumberToLidMappings
        |> Enum.map(&parse_phone_number_lid_mapping/1)
        |> Enum.reject(&is_nil/1)

      conversation_mappings =
        conversations
        |> Enum.map(&conversation_mapping/1)
        |> Enum.reject(&is_nil/1)

      call_log_records =
        history.callLogRecords
        |> Enum.map(&Call.from_call_log_record(&1, source: :history_sync))
        |> Enum.reject(&is_nil/1)

      {:ok,
       %{
         sync_type: history.syncType || sync_type_from_notification,
         conversations: conversations,
         lid_mappings: Enum.uniq(explicit_mappings ++ conversation_mappings),
         call_log_records: call_log_records
       }}
    end
  end

  defp parse_conversation(%Conversation{} = conversation) do
    case normalize_non_empty_jid(conversation."ID") do
      jid when is_binary(jid) ->
        %{
          jid: jid,
          name:
            first_non_empty([
              normalize_optional_text(conversation.displayName),
              normalize_optional_text(conversation.name),
              normalize_optional_text(conversation.username)
            ]),
          unread_count: non_neg_or_nil(conversation.unreadCount),
          last_message_timestamp:
            non_neg_or_nil(conversation.lastMsgTimestamp) ||
              non_neg_or_nil(conversation.conversationTimestamp),
          pinned: parse_optional_boolean(conversation.pinned),
          archived: conversation.archived,
          muted_until: non_neg_or_nil(conversation.muteEndTime),
          is_group: JID.group?(jid),
          pn_jid: normalize_optional_jid(conversation.pnJID),
          lid_jid: normalize_optional_jid(conversation.lidJID),
          tc_token: conversation.tcToken,
          tc_token_timestamp: conversation.tcTokenTimestamp,
          tc_token_sender_timestamp: conversation.tcTokenSenderTimestamp,
          messages:
            conversation.messages
            |> Enum.map(&parse_history_sync_message/1)
            |> Enum.reject(&is_nil/1)
        }

      _ ->
        nil
    end
  end

  defp parse_conversation(_), do: nil

  defp parse_history_sync_message(%{message: %WebMessageInfo{} = web_message} = history_msg) do
    case parse_web_message_info(web_message) do
      parsed when is_map(parsed) -> Map.put(parsed, :order_id, history_msg.msgOrderID)
      _ -> nil
    end
  end

  defp parse_history_sync_message(_), do: nil

  defp parse_web_message_info(%WebMessageInfo{} = web_message) do
    key = parse_message_key(web_message.key)
    timestamp = non_neg_or_nil(web_message.messageTimestamp)
    text = extract_message_text(web_message.message, 0)

    participant =
      first_non_empty([
        normalize_optional_jid(web_message.participant),
        key.participant
      ])

    if is_binary(key.id) or is_integer(timestamp) or is_binary(text) do
      %{
        id: key.id,
        from_me: key.from_me,
        timestamp: timestamp,
        text: text,
        participant: participant,
        remote_jid: key.remote_jid
      }
    else
      nil
    end
  end

  defp parse_message_key(%{} = key) do
    %{
      remote_jid: normalize_optional_jid(key.remoteJID),
      from_me: key.fromMe == true,
      id: normalize_optional_text(key."ID"),
      participant: normalize_optional_jid(key.participant)
    }
  end

  defp parse_message_key(_), do: %{remote_jid: nil, from_me: false, id: nil, participant: nil}

  @spec extract_message_text(Message.t() | nil, non_neg_integer()) :: String.t() | nil
  defp extract_message_text(_message, depth) when depth > @max_message_unwrap_depth, do: nil

  defp extract_message_text(%Message{} = message, depth) do
    extract_message_text_shallow(message) ||
      Enum.find_value(wrapped_messages(message), fn wrapped ->
        extract_message_text(wrapped, depth + 1)
      end)
  end

  defp extract_message_text(_message, _depth), do: nil

  defp extract_message_text_shallow(message) do
    cond do
      valid_text_payload?(message.conversation) ->
        message.conversation

      is_map(message.extendedTextMessage) and
          valid_text_payload?(message.extendedTextMessage.text) ->
        message.extendedTextMessage.text

      true ->
        nil
    end
  end

  defp wrapped_messages(message) do
    wrappers = [
      message.deviceSentMessage,
      message.viewOnceMessage,
      message.ephemeralMessage,
      message.documentWithCaptionMessage,
      message.viewOnceMessageV2,
      message.viewOnceMessageV2Extension,
      message.lottieStickerMessage
    ]

    for %{message: %Message{} = wrapped} <- wrappers, do: wrapped
  end

  defp valid_text_payload?(value) when is_binary(value) do
    trimmed = String.trim(value)

    trimmed != "" and String.valid?(trimmed) and
      not Regex.match?(@jid_like_payload_pattern, trimmed)
  end

  defp valid_text_payload?(_value), do: false

  defp parse_phone_number_lid_mapping(%PhoneNumberToLIDMapping{} = mapping) do
    with pn when is_binary(pn) <- normalize_non_empty_jid(mapping.pnJID),
         lid when is_binary(lid) <- normalize_non_empty_jid(mapping.lidJID) do
      {lid, pn}
    else
      _ -> nil
    end
  end

  defp parse_phone_number_lid_mapping(_), do: nil

  defp conversation_mapping(%{
         jid: jid,
         is_group: false,
         pn_jid: pn_jid,
         lid_jid: lid_jid
       }) do
    cond do
      lid_jid?(jid) and is_binary(pn_jid) and pn_jid != "" ->
        {jid, pn_jid}

      pn_jid?(jid) and is_binary(lid_jid) and lid_jid != "" ->
        {lid_jid, jid}

      true ->
        nil
    end
  end

  defp conversation_mapping(_), do: nil

  defp lid_jid?(jid) when is_binary(jid) do
    String.ends_with?(jid, "@lid") or String.ends_with?(jid, "@hosted.lid")
  end

  defp lid_jid?(_), do: false

  defp pn_jid?(jid) when is_binary(jid) do
    not lid_jid?(jid) and not JID.group?(jid) and String.contains?(jid, "@")
  end

  defp pn_jid?(_), do: false

  defp non_neg_or_nil(value) when is_integer(value) and value >= 0, do: value
  defp non_neg_or_nil(_), do: nil

  defp parse_optional_boolean(nil), do: nil
  defp parse_optional_boolean(false), do: false
  defp parse_optional_boolean(true), do: true
  defp parse_optional_boolean(0), do: false
  defp parse_optional_boolean(value) when is_integer(value) and value > 0, do: true
  defp parse_optional_boolean(_), do: nil

  defp first_non_empty(values) when is_list(values) do
    Enum.find(values, fn
      value when is_binary(value) and value != "" -> true
      _ -> false
    end)
  end

  defp normalize_optional_text(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end

  defp normalize_optional_text(_), do: nil

  defp normalize_optional_jid(value), do: normalize_non_empty_jid(value)

  defp normalize_non_empty_jid(value) do
    case normalize_jid(value) do
      "" -> nil
      jid -> jid
    end
  end

  defp normalize_jid(%JID{} = jid), do: normalize_jid(JID.to_string(jid))
  defp normalize_jid(nil), do: ""

  defp normalize_jid(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
    |> then(fn value ->
      case String.split(value, "@", parts: 2) do
        [user, domain] when user != "" and domain != "" ->
          Regex.replace(~r/:(\d+)$/, user, "") <> "@" <> domain

        _ ->
          value
      end
    end)
  end

  defp normalize_jid(_), do: ""

  defp inflate_history_payload(payload) when is_binary(payload) do
    {:ok, :zlib.uncompress(payload)}
  rescue
    _ ->
      # In some edge cases this payload may already be plain protobuf bytes.
      {:ok, payload}
  catch
    _, _ -> {:ok, payload}
  end
end
