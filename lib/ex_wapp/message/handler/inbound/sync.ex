defmodule ExWapp.Message.Handler.Inbound.Sync do
  @moduledoc """
  Ingests protocol messages that update local synchronized state.

  This module owns history-sync projection, app-state key shares, and recovered
  placeholder messages. It does not decrypt Signal envelopes or build receipts.
  """

  require Logger

  alias ExWapp.AppState.Engine
  alias ExWapp.{Chat, Log, PrivacyToken, Store}
  alias ExWapp.Message.Content, as: MessageContent
  alias ExWapp.Message.Handler.Common
  alias ExWapp.Message.Handler.Inbound.{Content, Projection}
  alias ExWapp.Message.Handler.Wire.Fields
  alias ExWapp.Proto.HistorySync
  alias ExWapp.Session.JIDUtils

  alias WAWebProtobufsE2E.{
    AppStateSyncKey,
    AppStateSyncKeyData,
    AppStateSyncKeyId,
    Message
  }

  @doc """
  Applies every supported inbound protocol-sync payload to session state.

  `own_sender?` must come from trusted envelope metadata. History sync and
  app-state key shares are self-only protocol messages and are ignored unless
  the server-attested sender is one of the local account identities.
  """
  @spec ingest(map(), term(), map(), term(), term()) :: map()
  def ingest(message_data, session, state, from, id) do
    ingest(message_data, session, state, from, id, false)
  end

  @spec ingest(map(), term(), map(), term(), term(), boolean()) :: map()
  def ingest(message_data, session, state, from, id, own_sender?) do
    state =
      maybe_ingest_history_sync(
        message_data,
        session,
        state,
        from,
        id,
        own_sender? == true
      )

    state = maybe_ingest_app_state_keys(message_data, session, state, own_sender? == true)
    maybe_ingest_placeholder_resend_response(message_data, session, state)
  end

  @spec maybe_ingest_history_sync(map(), term(), map(), term(), term(), boolean()) :: map()
  defp maybe_ingest_history_sync(
         %{message_content_type: :protocol, protocol_payload: payload},
         session,
         state,
         from,
         id,
         true
       )
       when is_binary(payload) do
    case HistorySync.extract_from_message(payload) do
      {:ok, %{sync_type: sync_type, conversations: conversations, lid_mappings: lid_mappings}} ->
        target = Common.chat_target(session, state)

        history_message_count =
          Enum.reduce(conversations, 0, fn conversation, count ->
            count + length(Map.get(conversation, :messages, []))
          end)

        if target do
          Enum.each(conversations, &upsert_chat_from_history_sync(target, &1))
        end

        persist_history_sync_lid_mappings(state, lid_mappings)
        privacy_token_count = persist_history_sync_privacy_tokens(state, conversations)

        Logger.debug(
          "[HISTORY_SYNC] Applied protocol history sync from=#{Log.reference(from)} id=#{Log.reference(id)} sync_type=#{inspect(sync_type)} conversations=#{length(conversations)} messages=#{history_message_count} lid_mappings=#{length(lid_mappings)} privacy_tokens=#{privacy_token_count}"
        )

        state

      :not_history_sync ->
        state

      {:error, :history_sync_download_required} ->
        Logger.debug(
          "[HISTORY_SYNC] History sync notification requires blob download (inline payload missing) from=#{Log.reference(from)} id=#{Log.reference(id)}"
        )

        state

      {:error, reason} ->
        Logger.warning(
          "[HISTORY_SYNC] Failed to parse protocol history sync from=#{Log.reference(from)} id=#{Log.reference(id)}: #{Log.reason(reason)}"
        )

        state
    end
  end

  defp maybe_ingest_history_sync(
         %{message_content_type: :protocol},
         _session,
         state,
         _from,
         _id,
         false
       ),
       do: state

  defp maybe_ingest_history_sync(
         _message_data,
         _session,
         state,
         _from,
         _id,
         _own_sender?
       ),
       do: state

  @spec maybe_ingest_app_state_keys(map(), term(), map(), boolean()) :: map()
  defp maybe_ingest_app_state_keys(
         %{message_content_type: :protocol, protocol_payload: payload},
         session,
         state,
         true
       )
       when is_binary(payload) do
    case extract_app_state_keys(payload) do
      {:ok, keys} ->
        case store_app_state_keys(state, keys) do
          {:ok, action} when action in [:updated, :unchanged] ->
            maybe_trigger_initial_app_state_sync(session)

          _ ->
            :ok
        end

        state

      _ ->
        state
    end
  rescue
    error ->
      Logger.warning("[APP_STATE] Failed to ingest app state keys: #{Log.reason(error)}")
      state
  end

  defp maybe_ingest_app_state_keys(
         %{message_content_type: :protocol},
         _session,
         state,
         false
       ),
       do: state

  defp maybe_ingest_app_state_keys(_message_data, _session, state, _own_sender?), do: state

  @spec extract_app_state_keys(binary()) ::
          {:ok, [AppStateSyncKey.t()]} | :not_app_state_key_share
  defp extract_app_state_keys(payload) when is_binary(payload) do
    case Message.decode(payload) do
      {:ok, %Message{protocolMessage: %{appStateSyncKeyShare: %{keys: keys}}}}
      when is_list(keys) and keys != [] ->
        {:ok, keys}

      _ ->
        :not_app_state_key_share
    end
  end

  @spec maybe_ingest_placeholder_resend_response(map(), term(), map()) :: map()
  defp maybe_ingest_placeholder_resend_response(
         %{message_content_type: :protocol, protocol_payload: payload},
         session,
         state
       )
       when is_binary(payload) do
    case extract_placeholder_resend_response(payload) do
      {:ok, %{request_id: request_id, messages: recovered_messages}} ->
        target = Common.chat_target(session, state)

        count =
          recovered_messages
          |> Enum.map(&ingest_recovered_placeholder_message(&1, target, session))
          |> Enum.count(&(&1 == :ok))

        if count > 0 do
          Logger.debug(
            "[PLACEHOLDER] Applied #{count} recovered message(s) from request=#{request_id}"
          )
        end

        state

      :not_placeholder_resend_response ->
        state

      {:error, reason} ->
        Logger.warning("[PLACEHOLDER] Failed to parse resend response: #{Log.reason(reason)}")
        state
    end
  rescue
    error ->
      Logger.warning("[PLACEHOLDER] Failed to ingest resend response: #{Log.reason(error)}")
      state
  end

  defp maybe_ingest_placeholder_resend_response(_message_data, _session, state), do: state

  @spec extract_placeholder_resend_response(binary()) ::
          {:ok, %{request_id: binary(), messages: [map()]}}
          | :not_placeholder_resend_response
          | {:error, term()}
  defp extract_placeholder_resend_response(message_payload) do
    with {:ok, message_fields} <- Fields.decode_safe(message_payload),
         protocol_message when is_binary(protocol_message) <-
           Fields.first_length_delimited(message_fields, 12),
         {:ok, protocol_fields} <- Fields.decode_safe(protocol_message),
         17 <- Fields.first_varint(protocol_fields, 2),
         peer_response when is_binary(peer_response) <-
           Fields.first_length_delimited(protocol_fields, 17),
         {:ok, response_fields} <- Fields.decode_safe(peer_response),
         4 <- Fields.first_varint(response_fields, 1) do
      request_id = Fields.first_length_delimited(response_fields, 2) || ""

      messages =
        response_fields
        |> Fields.all_length_delimited(3)
        |> Enum.flat_map(&extract_placeholder_result_messages/1)

      {:ok, %{request_id: request_id, messages: messages}}
    else
      nil -> :not_placeholder_resend_response
      value when is_integer(value) -> :not_placeholder_resend_response
      {:error, reason} -> {:error, reason}
    end
  end

  @spec extract_placeholder_result_messages(binary()) :: [map()]
  defp extract_placeholder_result_messages(result_payload) do
    with {:ok, result_fields} <- Fields.decode_safe(result_payload),
         placeholder_response when is_binary(placeholder_response) <-
           Fields.first_length_delimited(result_fields, 4),
         {:ok, placeholder_fields} <- Fields.decode_safe(placeholder_response),
         web_message_info when is_binary(web_message_info) <-
           Fields.first_length_delimited(placeholder_fields, 1),
         {:ok, recovered} <- decode_recovered_web_message_info(web_message_info) do
      [recovered]
    else
      _ -> []
    end
  end

  @spec decode_recovered_web_message_info(binary()) :: {:ok, map()} | {:error, atom()}
  defp decode_recovered_web_message_info(web_message_info) do
    with {:ok, fields} <- Fields.decode_safe(web_message_info),
         key_payload when is_binary(key_payload) <- Fields.first_length_delimited(fields, 1),
         message_payload when is_binary(message_payload) <-
           Fields.first_length_delimited(fields, 2),
         {:ok, key} <- decode_message_key_payload(key_payload) do
      timestamp = Fields.first_varint(fields, 3)
      participant = Fields.first_length_delimited(fields, 5) || Map.get(key, :participant)
      push_name = Fields.first_length_delimited(fields, 19)

      {:ok,
       %{
         key: key,
         message_payload: message_payload,
         timestamp: timestamp,
         participant: participant,
         push_name: push_name
       }}
    else
      _ -> {:error, :invalid_web_message_info}
    end
  end

  @spec decode_message_key_payload(binary()) :: {:ok, map()} | {:error, term()}
  defp decode_message_key_payload(key_payload) do
    with {:ok, fields} <- Fields.decode_safe(key_payload) do
      {:ok,
       %{
         remote_jid: Fields.first_length_delimited(fields, 1) || "",
         from_me: Fields.first_varint(fields, 2) == 1,
         id: Fields.first_length_delimited(fields, 3) || "",
         participant: Fields.first_length_delimited(fields, 4)
       }}
    end
  end

  @spec ingest_recovered_placeholder_message(map(), term(), term()) :: :ok | :skip
  defp ingest_recovered_placeholder_message(
         %{key: %{remote_jid: chat_jid, id: id} = key, message_payload: payload} = recovered,
         target,
         session
       )
       when is_binary(chat_jid) and chat_jid != "" and is_binary(id) and id != "" do
    canonical =
      Content.decode_plaintext(payload,
        enc_type: "placeholder_resend",
        sender_jid: Map.get(recovered, :participant, "")
      )

    if canonical.kind == :protocol do
      :skip
    else
      legacy = MessageContent.to_legacy(canonical)
      from_me = Map.get(key, :from_me) == true
      participant = Common.normalize_optional_text(Map.get(recovered, :participant))

      message = %{
        id: id,
        content: canonical,
        from_me: from_me,
        timestamp: Common.parse_timestamp(Map.get(recovered, :timestamp)),
        text: Common.normalize_optional_text(Map.get(legacy, :text)),
        status: if(from_me, do: :sent, else: :received),
        participant: participant,
        media: Map.get(legacy, :media),
        location: Map.get(legacy, :location),
        contact: Map.get(legacy, :contact),
        event: Map.get(legacy, :event),
        raw: %{
          type: :placeholder_resend,
          content: canonical,
          from_me: from_me,
          media: Map.get(legacy, :media),
          media_type: Map.get(legacy, :media_type),
          content_type: Map.get(legacy, :content_type),
          push_name: Map.get(recovered, :push_name)
        }
      }

      if target do
        Projection.update_chat_name(target, chat_jid, %{
          "notify" => Map.get(recovered, :push_name)
        })

        Chat.add_message(target, chat_jid, message)
      end

      if is_pid(session) do
        send(session, {:new_message, chat_jid, message})
      end

      :ok
    end
  end

  defp ingest_recovered_placeholder_message(_recovered, _target, _session), do: :skip

  @spec store_app_state_keys(map(), [map()]) ::
          {:ok, :updated | :unchanged} | {:error, term()}
  defp store_app_state_keys(state, keys) when is_list(keys) do
    store = Map.get(state, :store)

    if is_nil(store) do
      Logger.warning("[APP_STATE] No store available, cannot persist app state keys")
      {:error, :missing_store}
    else
      persist_app_state_keys(store, keys)
    end
  rescue
    error ->
      Logger.warning("[APP_STATE] Failed to store app state keys: #{Log.reason(error)}")
      {:error, {:store_failed, error}}
  end

  defp persist_app_state_keys(store, keys) do
    case Store.get_and_update(
           store,
           :app_state_keys,
           %{},
           &merge_app_state_keys(&1, keys)
         ) do
      status when status in [:updated, :unchanged] -> {:ok, status}
      {:error, _reason} = error -> error
    end
  end

  defp merge_app_state_keys(existing_keys, keys) do
    updated_keys = Enum.reduce(keys, existing_keys, &maybe_put_app_state_key/2)
    status = if updated_keys == existing_keys, do: :unchanged, else: :updated
    {status, updated_keys}
  end

  @spec maybe_put_app_state_key(map(), map()) :: map()
  defp maybe_put_app_state_key(key, acc) do
    case extract_app_state_key_data(key) do
      {:ok, key_id, key_data_bin, timestamp, fingerprint} ->
        key_id_hex = Base.encode16(key_id, case: :lower)

        Map.put(acc, key_id_hex, %{
          data: key_data_bin,
          timestamp: timestamp,
          fingerprint: fingerprint
        })

      :error ->
        Logger.warning("[APP_STATE] Skipping malformed key: #{Log.term_summary(key)}")
        acc
    end
  end

  @spec extract_app_state_key_data(map()) ::
          {:ok, binary(), binary(), term(), term()} | :error
  defp extract_app_state_key_data(%AppStateSyncKey{
         keyID: %AppStateSyncKeyId{keyID: key_id},
         keyData: %AppStateSyncKeyData{keyData: key_data_bin} = key_data
       })
       when is_binary(key_id) and is_binary(key_data_bin) do
    {:ok, key_id, key_data_bin, key_data.timestamp, encode_key_fingerprint(key_data.fingerprint)}
  end

  defp extract_app_state_key_data(_key), do: :error

  # The fingerprint is stored but never read back as a struct; keep the
  # persisted shape as the raw protobuf bytes it always was.
  @spec encode_key_fingerprint(struct() | nil) :: binary() | nil
  defp encode_key_fingerprint(%_{} = fingerprint),
    do: fingerprint.__struct__.encode!(fingerprint) |> IO.iodata_to_binary()

  defp encode_key_fingerprint(_fingerprint), do: nil

  @spec maybe_trigger_initial_app_state_sync(term()) :: :ok
  defp maybe_trigger_initial_app_state_sync(session) do
    if is_pid(session) and Process.alive?(session) do
      send(session, {:app_state_initial_sync, Engine.all_collections()})
    end

    :ok
  end

  @spec upsert_chat_from_history_sync(term(), map()) :: :ok
  defp upsert_chat_from_history_sync(target, %{jid: jid} = conversation)
       when not is_nil(target) do
    metadata =
      %{}
      |> maybe_put_sync_metadata(:name, Map.get(conversation, :name))
      |> maybe_put_sync_metadata(:unread_count, Map.get(conversation, :unread_count))
      |> maybe_put_sync_metadata(
        :last_message_timestamp,
        Map.get(conversation, :last_message_timestamp)
      )
      |> maybe_put_sync_metadata(:pinned, Map.get(conversation, :pinned))
      |> maybe_put_sync_metadata(:archived, Map.get(conversation, :archived))
      |> maybe_put_sync_metadata(:muted_until, Map.get(conversation, :muted_until))
      |> maybe_put_sync_metadata(:is_group, Map.get(conversation, :is_group))

    Chat.merge_metadata(target, jid, metadata)

    conversation
    |> Map.get(:messages, [])
    |> history_sync_chat_messages(jid)
    |> maybe_merge_history_sync_chat_messages(target, jid)

    maybe_update_history_sync_contact_name(target, jid, conversation)
  end

  defp upsert_chat_from_history_sync(_target, _conversation), do: :ok

  @spec history_sync_chat_messages([map()], binary()) :: [map()]
  defp history_sync_chat_messages(history_messages, jid)
       when is_list(history_messages) and history_messages != [] do
    history_messages
    |> Enum.with_index()
    |> Enum.map(fn {history_message, index} ->
      history_sync_message_to_chat_message(history_message, jid, index)
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp history_sync_chat_messages(_history_messages, _jid), do: []

  @spec maybe_merge_history_sync_chat_messages([map()], term(), term()) :: :ok
  defp maybe_merge_history_sync_chat_messages([], _target, _jid), do: :ok

  defp maybe_merge_history_sync_chat_messages(chat_messages, target, jid)
       when is_list(chat_messages) do
    Chat.merge_messages(target, jid, chat_messages)
  end

  @spec maybe_update_history_sync_contact_name(term(), term(), map()) :: :ok
  defp maybe_update_history_sync_contact_name(target, jid, conversation) do
    if Map.get(conversation, :is_group, false) do
      :ok
    else
      maybe_update_push_name_from_history_sync(target, jid, Map.get(conversation, :name))
    end
  end

  @spec maybe_update_push_name_from_history_sync(term(), term(), term()) :: :ok
  defp maybe_update_push_name_from_history_sync(target, jid, name)
       when is_binary(name) and name != "" do
    case Common.resolve_store_from_target(target) do
      nil -> :ok
      store -> ExWapp.Contact.update_push_name(store, jid, name)
    end
  end

  defp maybe_update_push_name_from_history_sync(_target, _jid, _name), do: :ok

  @spec history_sync_message_to_chat_message(map(), binary(), non_neg_integer()) :: map() | nil
  defp history_sync_message_to_chat_message(message, conversation_jid, index)
       when is_map(message) and is_binary(conversation_jid) and is_integer(index) do
    from_me = Map.get(message, :from_me, false) == true
    timestamp = normalize_history_sync_timestamp(Map.get(message, :timestamp))
    participant = normalize_optional_history_jid(Map.get(message, :participant))
    remote_jid = normalize_optional_history_jid(Map.get(message, :remote_jid))

    message_id =
      Common.first_non_empty([
        Common.normalize_optional_text(Map.get(message, :id)),
        history_sync_message_fallback_id(message, conversation_jid, index)
      ])

    if is_binary(message_id) and message_id != "" do
      %{
        id: message_id,
        from_me: from_me,
        timestamp: timestamp,
        text: Common.normalize_optional_text(Map.get(message, :text)),
        status: if(from_me, do: :sent, else: :received),
        participant: participant,
        raw: %{
          type: "history_sync",
          source: :history_sync,
          remote_jid: remote_jid,
          order_id: Map.get(message, :order_id)
        }
      }
    else
      nil
    end
  end

  defp history_sync_message_to_chat_message(_message, _conversation_jid, _index), do: nil

  @spec normalize_history_sync_timestamp(term()) :: non_neg_integer()
  defp normalize_history_sync_timestamp(value) when is_integer(value) and value >= 0, do: value
  defp normalize_history_sync_timestamp(_), do: 0

  @spec normalize_optional_history_jid(term()) :: binary() | nil
  defp normalize_optional_history_jid(value) do
    case Common.normalize_jid(value) do
      "" -> nil
      jid -> jid
    end
  end

  @spec history_sync_message_fallback_id(map(), binary(), non_neg_integer()) :: binary()
  defp history_sync_message_fallback_id(message, conversation_jid, index)
       when is_map(message) and is_binary(conversation_jid) and is_integer(index) do
    seed = %{
      conversation_jid: conversation_jid,
      order_id: Map.get(message, :order_id),
      timestamp: Map.get(message, :timestamp),
      text: Map.get(message, :text),
      participant: Map.get(message, :participant),
      remote_jid: Map.get(message, :remote_jid),
      from_me: Map.get(message, :from_me, false),
      index: index
    }

    "history-sync-" <>
      (:crypto.hash(:sha256, :erlang.term_to_binary(seed))
       |> Base.encode16(case: :lower)
       |> binary_part(0, 20))
  rescue
    _ -> "history-sync-#{index}"
  end

  @spec persist_history_sync_lid_mappings(map(), list()) :: :ok
  defp persist_history_sync_lid_mappings(state, lid_mappings)
       when is_map(state) and is_list(lid_mappings) do
    case {Map.get(state, :store), normalize_lid_mappings(lid_mappings)} do
      {nil, _} ->
        :ok

      {_store, []} ->
        :ok

      {store, normalized_mappings} ->
        Store.update(
          store,
          :lid_mapping,
          %{},
          &merge_lid_mappings(&1, normalized_mappings)
        )

        :ok
    end
  rescue
    error ->
      Logger.warning("[HISTORY_SYNC] Failed storing LID mappings: #{Log.reason(error)}")
      :ok
  end

  defp persist_history_sync_lid_mappings(_state, _lid_mappings), do: :ok

  @spec persist_history_sync_privacy_tokens(map(), list()) :: non_neg_integer()
  defp persist_history_sync_privacy_tokens(state, conversations)
       when is_map(state) and is_list(conversations) do
    case Map.get(state, :store) do
      nil ->
        0

      store ->
        lid_mapping = store |> Store.load!() |> Map.get(:lid_mapping, %{})
        token_entries = history_sync_privacy_token_entries(conversations, lid_mapping)

        if token_entries != [] do
          Store.update(store, :tctokens, %{}, fn existing_tokens ->
            merge_history_sync_privacy_tokens(existing_tokens, token_entries)
          end)
        end

        length(token_entries)
    end
  rescue
    error ->
      Logger.warning("[HISTORY_SYNC] Failed storing privacy tokens: #{Log.reason(error)}")
      0
  end

  defp persist_history_sync_privacy_tokens(_state, _conversations), do: 0

  defp history_sync_privacy_token_entries(conversations, lid_mapping) do
    Enum.reduce(conversations, [], fn conversation, entries ->
      record = %{
        token: Map.get(conversation, :tc_token),
        timestamp: Map.get(conversation, :tc_token_timestamp),
        sender_timestamp: Map.get(conversation, :tc_token_sender_timestamp)
      }

      storage_jids = history_sync_privacy_token_jids(conversation, lid_mapping)

      if PrivacyToken.valid?(record) and storage_jids != [] do
        [{storage_jids, record} | entries]
      else
        entries
      end
    end)
  end

  defp history_sync_privacy_token_jids(conversation, lid_mapping) do
    conversation
    |> Map.take([:jid, :pn_jid, :lid_jid])
    |> Map.values()
    |> Enum.flat_map(&JIDUtils.related_bases(&1, lid_mapping))
    |> Enum.filter(&direct_user_jid?/1)
    |> Enum.uniq()
  end

  defp direct_user_jid?(jid) when is_binary(jid) do
    String.ends_with?(jid, "@s.whatsapp.net") or JIDUtils.lid_jid?(jid)
  end

  defp direct_user_jid?(_jid), do: false

  defp merge_history_sync_privacy_tokens(existing_tokens, token_entries) do
    Enum.reduce(token_entries, existing_tokens, fn {storage_jids, record}, tokens ->
      Enum.reduce(storage_jids, tokens, fn jid, aliases ->
        Map.update(aliases, jid, record, fn existing ->
          if PrivacyToken.newer_or_equal?(record, existing), do: record, else: existing
        end)
      end)
    end)
  end

  defp merge_lid_mappings(existing_mappings, normalized_mappings) do
    Enum.reduce(normalized_mappings, existing_mappings, fn {lid, pn}, acc ->
      acc
      |> Map.put({:pn_to_lid, pn}, lid)
      |> Map.put({:lid_to_pn, lid}, pn)
    end)
  end

  @spec normalize_lid_mappings(list()) :: [{binary(), binary()}]
  defp normalize_lid_mappings(lid_mappings) when is_list(lid_mappings) do
    lid_mappings
    |> Enum.reduce([], fn
      {lid, pn}, acc ->
        normalized_lid = Common.normalize_jid(lid)
        normalized_pn = Common.normalize_jid(pn)

        if normalized_lid != "" and normalized_pn != "",
          do: [{normalized_lid, normalized_pn} | acc],
          else: acc

      _other, acc ->
        acc
    end)
    |> Enum.uniq()
  end

  @spec maybe_put_sync_metadata(map(), atom(), term()) :: map()
  defp maybe_put_sync_metadata(metadata, _key, nil), do: metadata
  defp maybe_put_sync_metadata(metadata, key, value), do: Map.put(metadata, key, value)
end
