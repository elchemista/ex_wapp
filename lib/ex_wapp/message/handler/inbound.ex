defmodule ExWapp.Message.Handler.Inbound do
  @moduledoc false

  require Logger

  alias ExWapp.AppState.Engine
  alias ExWapp.{Chat, JID, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.{Common, Wire}
  alias ExWapp.Message.Handler.Inbound.{Content, Decryptor, Envelope}
  alias ExWapp.Proto.{HistorySync, SyncAction}
  alias ExWapp.Session.DeviceCache
  alias ExWapp.Signal.SessionStore

  @max_retry_receipt_count 2

  @spec handle_message(Node.t(), pid(), map()) :: {:ok, map(), [term()]}
  def handle_message(%Node{attrs: attrs, content: content}, session, state) do
    from =
      case Map.get(attrs, "from", "") do
        %JID{} = jid -> jid
        jid when is_binary(jid) -> jid
        _ -> ""
      end

    id = Map.get(attrs, "id", "")
    type = Map.get(attrs, "type", "text")
    timestamp = Common.parse_timestamp(Map.get(attrs, "t"))
    participant = Map.get(attrs, "participant")

    Logger.debug("Received message from=#{from} id=#{id} type=#{type}")
    state = Envelope.persist_lid_mappings(state, attrs, from, participant)
    Envelope.persist_observed_devices(state, attrs, from, participant)

    message_data = Wire.extract_message_content(content, type)
    {message_data, state} = maybe_decrypt_message(message_data, state, from, participant, attrs)
    state = maybe_ingest_history_sync(message_data, session, state, from, id)
    state = maybe_ingest_app_state_keys(message_data, session, state)
    state = maybe_ingest_placeholder_resend_response(message_data, session, state)
    from_me = Envelope.from_me?(attrs, from, state, message_data)

    message = %{
      id: id,
      from_me: from_me,
      timestamp: timestamp,
      text: message_data[:text],
      status: if(from_me, do: :sent, else: :received),
      participant: participant,
      media: message_data[:media],
      location: message_data[:location],
      contact: message_data[:contact],
      event: message_data[:event],
      raw: %{
        type: type,
        attrs: attrs,
        media: message_data[:media],
        media_type: message_data[:media_type],
        content_type: message_data[:content_type],
        location: message_data[:location],
        contact: message_data[:contact],
        event: message_data[:event],
        from_me: from_me
      }
    }

    is_protocol = message_data[:message_content_type] == :protocol
    suppress_message? = transient_encrypted_placeholder?(message_data)

    if not is_protocol and not suppress_message? do
      if target = Common.chat_target(session, state) do
        maybe_update_chat_name(target, from, attrs)
        Chat.add_message(target, from, message)
      end

      if is_pid(session) do
        send(session, {:new_message, from, message})
      end
    else
      maybe_log_suppressed_message(is_protocol, suppress_message?, from, id, message_data)
    end

    {actions, state} = build_receipt_actions(from, id, participant, attrs, message_data, state)
    updated_state = Common.update_stats(state, :messages_received)
    {:ok, updated_state, actions}
  end

  @doc false
  @spec persist_notification_devices(map(), term()) :: :ok
  def persist_notification_devices(state, content) when is_map(state) and is_list(content) do
    store = Map.get(state, :store)

    content
    |> Enum.flat_map(fn
      %Node{attrs: attrs} when is_map(attrs) ->
        attrs
        |> Map.values()
        |> Enum.map(&Common.normalize_jid_with_device/1)
        |> Enum.filter(&String.contains?(&1, "@"))

      _ ->
        []
    end)
    |> Enum.uniq()
    |> Enum.each(&DeviceCache.persist_observed_device(store, &1))

    :ok
  end

  def persist_notification_devices(_state, _content), do: :ok

  @spec maybe_decrypt_message(map(), map(), term(), term(), map()) :: {map(), map()}
  defp maybe_decrypt_message(
         %{encrypted: true} = message_data,
         state,
         from,
         participant,
         attrs
       ) do
    case Decryptor.decrypt(message_data, state, from, participant, attrs) do
      {:ok, decrypt_result, updated_state} ->
        {Content.decode_decrypted(decrypt_result), updated_state}

      {:error, updated_message_data, updated_state} ->
        {updated_message_data, updated_state}
    end
  end

  defp maybe_decrypt_message(message_data, state, _from, _participant, _attrs),
    do: {message_data, state}

  defp transient_encrypted_placeholder?(%{encrypted: true, decrypt_status: {:error, _}}), do: true
  defp transient_encrypted_placeholder?(%{placeholder_unavailable: true}), do: true
  defp transient_encrypted_placeholder?(_message_data), do: false

  defp maybe_log_suppressed_message(true, _suppress_message?, _from, _id, _message_data), do: :ok

  defp maybe_log_suppressed_message(_is_protocol, true, from, id, message_data) do
    Logger.debug(
      "[DECRYPT] Suppressing undecryptable encrypted placeholder from=#{Common.normalize_jid_with_device(from)} id=#{id} reason=#{inspect(Map.get(message_data, :decrypt_status))}"
    )
  end

  defp maybe_log_suppressed_message(_is_protocol, _suppress_message?, _from, _id, _message_data),
    do: :ok

  defp maybe_ingest_history_sync(
         %{message_content_type: :protocol, protocol_payload: payload},
         session,
         state,
         from,
         id
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

        Logger.debug(
          "[HISTORY_SYNC] Applied protocol history sync from=#{Common.normalize_jid(from)} id=#{id} sync_type=#{inspect(sync_type)} conversations=#{length(conversations)} messages=#{history_message_count} lid_mappings=#{length(lid_mappings)}"
        )

        state

      :not_history_sync ->
        state

      {:error, :history_sync_download_required} ->
        Logger.debug(
          "[HISTORY_SYNC] History sync notification requires blob download (inline payload missing) from=#{Common.normalize_jid(from)} id=#{id}"
        )

        state

      {:error, reason} ->
        Logger.warning(
          "[HISTORY_SYNC] Failed to parse protocol history sync from=#{Common.normalize_jid(from)} id=#{id}: #{inspect(reason)}"
        )

        state
    end
  end

  defp maybe_ingest_history_sync(_message_data, _session, state, _from, _id), do: state

  defp maybe_ingest_app_state_keys(
         %{message_content_type: :protocol, protocol_payload: payload},
         session,
         state
       )
       when is_binary(payload) do
    with {:ok, message_fields} <- Wire.decode_wire_fields_safe(payload),
         protocol_message when is_binary(protocol_message) <-
           Wire.find_first_ld_field(message_fields, 12),
         {:ok, protocol_fields} <- Wire.decode_wire_fields_safe(protocol_message),
         key_share_bytes when is_binary(key_share_bytes) <-
           Wire.find_first_ld_field(protocol_fields, 7),
         {:ok, key_share} <- SyncAction.decode_app_state_sync_key_share(key_share_bytes),
         true <- key_share.keys != [] do
      case store_app_state_keys(state, key_share.keys) do
        {:ok, action} when action in [:updated, :unchanged] ->
          maybe_trigger_initial_app_state_sync(session)

        _ ->
          :ok
      end

      state
    else
      _ -> state
    end
  rescue
    error ->
      Logger.warning("[APP_STATE] Failed to ingest app state keys: #{inspect(error)}")
      state
  end

  defp maybe_ingest_app_state_keys(_message_data, _session, state), do: state

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
        Logger.warning("[PLACEHOLDER] Failed to parse resend response: #{inspect(reason)}")
        state
    end
  rescue
    error ->
      Logger.warning("[PLACEHOLDER] Failed to ingest resend response: #{inspect(error)}")
      state
  end

  defp maybe_ingest_placeholder_resend_response(_message_data, _session, state), do: state

  defp extract_placeholder_resend_response(message_payload) do
    with {:ok, message_fields} <- Wire.decode_wire_fields_safe(message_payload),
         protocol_message when is_binary(protocol_message) <-
           Wire.find_first_ld_field(message_fields, 12),
         {:ok, protocol_fields} <- Wire.decode_wire_fields_safe(protocol_message),
         17 <- Wire.find_first_varint_field(protocol_fields, 2),
         peer_response when is_binary(peer_response) <-
           Wire.find_first_ld_field(protocol_fields, 17),
         {:ok, response_fields} <- Wire.decode_wire_fields_safe(peer_response),
         4 <- Wire.find_first_varint_field(response_fields, 1) do
      request_id = Wire.find_first_ld_field(response_fields, 2) || ""

      messages =
        response_fields
        |> Wire.find_all_ld_fields(3)
        |> Enum.flat_map(&extract_placeholder_result_messages/1)

      {:ok, %{request_id: request_id, messages: messages}}
    else
      nil -> :not_placeholder_resend_response
      value when is_integer(value) -> :not_placeholder_resend_response
      {:error, reason} -> {:error, reason}
    end
  end

  defp extract_placeholder_result_messages(result_payload) do
    with {:ok, result_fields} <- Wire.decode_wire_fields_safe(result_payload),
         placeholder_response when is_binary(placeholder_response) <-
           Wire.find_first_ld_field(result_fields, 4),
         {:ok, placeholder_fields} <- Wire.decode_wire_fields_safe(placeholder_response),
         web_message_info when is_binary(web_message_info) <-
           Wire.find_first_ld_field(placeholder_fields, 1),
         {:ok, recovered} <- decode_recovered_web_message_info(web_message_info) do
      [recovered]
    else
      _ -> []
    end
  end

  defp decode_recovered_web_message_info(web_message_info) do
    with {:ok, fields} <- Wire.decode_wire_fields_safe(web_message_info),
         key_payload when is_binary(key_payload) <- Wire.find_first_ld_field(fields, 1),
         message_payload when is_binary(message_payload) <- Wire.find_first_ld_field(fields, 2),
         {:ok, key} <- decode_message_key_payload(key_payload) do
      timestamp = Wire.find_first_varint_field(fields, 3)
      participant = Wire.find_first_ld_field(fields, 5) || Map.get(key, :participant)
      push_name = Wire.find_first_ld_field(fields, 19)

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

  defp decode_message_key_payload(key_payload) do
    with {:ok, fields} <- Wire.decode_wire_fields_safe(key_payload) do
      {:ok,
       %{
         remote_jid: Wire.find_first_ld_field(fields, 1) || "",
         from_me: Wire.find_first_varint_field(fields, 2) == 1,
         id: Wire.find_first_ld_field(fields, 3) || "",
         participant: Wire.find_first_ld_field(fields, 4)
       }}
    end
  end

  defp ingest_recovered_placeholder_message(
         %{key: %{remote_jid: chat_jid, id: id} = key, message_payload: payload} = recovered,
         target,
         session
       )
       when is_binary(chat_jid) and chat_jid != "" and is_binary(id) and id != "" do
    {content_type, decoded_text} = Wire.classify_decrypted_content(payload, 0)

    if content_type == :protocol do
      :skip
    else
      message = %{
        id: id,
        from_me: Map.get(key, :from_me, false),
        timestamp: Map.get(recovered, :timestamp) || System.system_time(:second),
        text: decoded_text,
        status: if(Map.get(key, :from_me, false), do: :sent, else: :received),
        participant: Map.get(recovered, :participant),
        raw: %{
          type: :placeholder_resend,
          from_me: Map.get(key, :from_me, false),
          media: nil,
          push_name: Map.get(recovered, :push_name)
        }
      }

      if target do
        maybe_update_chat_name(target, chat_jid, %{"notify" => Map.get(recovered, :push_name)})
        Chat.add_message(target, chat_jid, message)
      end

      if is_pid(session) do
        send(session, {:new_message, chat_jid, message})
      end

      :ok
    end
  end

  defp ingest_recovered_placeholder_message(_recovered, _target, _session), do: :skip

  defp store_app_state_keys(state, keys) when is_list(keys) do
    store = Map.get(state, :store)

    if is_nil(store) do
      Logger.warning("[APP_STATE] No store available, cannot persist app state keys")
      {:error, :missing_store}
    else
      data = Store.load!(store)
      existing_keys = Map.get(data, :app_state_keys, %{})
      updated_keys = Enum.reduce(keys, existing_keys, &maybe_put_app_state_key/2)

      if updated_keys != existing_keys do
        Store.persist(store, Map.put(data, :app_state_keys, updated_keys))
        {:ok, :updated}
      else
        {:ok, :unchanged}
      end
    end
  rescue
    error ->
      Logger.warning("[APP_STATE] Failed to store app state keys: #{inspect(error)}")
      {:error, {:store_failed, error}}
  end

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
        Logger.warning("[APP_STATE] Skipping malformed key: #{inspect(key)}")
        acc
    end
  end

  defp extract_app_state_key_data(key) when is_map(key) do
    key_id = Map.get(key, :key_id)
    key_data = Map.get(key, :key_data)

    case {key_id, key_data} do
      {key_id, %{key_data: key_data_bin} = key_data_map}
      when is_binary(key_id) and is_binary(key_data_bin) ->
        {:ok, key_id, key_data_bin, Map.get(key_data_map, :timestamp),
         Map.get(key_data_map, :fingerprint)}

      _ ->
        :error
    end
  end

  defp extract_app_state_key_data(_key), do: :error

  defp maybe_trigger_initial_app_state_sync(session) do
    if is_pid(session) and Process.alive?(session) do
      send(session, {:app_state_initial_sync, Engine.all_collections()})
    end
  end

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

  defp maybe_merge_history_sync_chat_messages([], _target, _jid), do: :ok

  defp maybe_merge_history_sync_chat_messages(chat_messages, target, jid)
       when is_list(chat_messages), do: Chat.merge_messages(target, jid, chat_messages)

  defp maybe_update_history_sync_contact_name(target, jid, conversation) do
    if Map.get(conversation, :is_group, false) do
      :ok
    else
      maybe_update_push_name_from_history_sync(target, jid, Map.get(conversation, :name))
    end
  end

  defp maybe_update_push_name_from_history_sync(target, jid, name)
       when is_binary(name) and name != "" do
    case Common.resolve_store_from_target(target) do
      nil -> :ok
      store -> ExWapp.Contact.update_push_name(store, jid, name)
    end
  end

  defp maybe_update_push_name_from_history_sync(_target, _jid, _name), do: :ok

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
  defp normalize_history_sync_timestamp(value) when is_integer(value) and value >= 0, do: value
  defp normalize_history_sync_timestamp(_), do: 0

  defp normalize_optional_history_jid(value) do
    case Common.normalize_jid(value) do
      "" -> nil
      jid -> jid
    end
  end

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

  defp persist_history_sync_lid_mappings(state, lid_mappings)
       when is_map(state) and is_list(lid_mappings) do
    case {Map.get(state, :store), normalize_lid_mappings(lid_mappings)} do
      {nil, _} ->
        :ok

      {_store, []} ->
        :ok

      {store, normalized_mappings} ->
        data = Store.load!(store)
        existing_mappings = Map.get(data, :lid_mapping, %{})

        updated_mappings =
          Enum.reduce(normalized_mappings, existing_mappings, fn {lid, pn}, acc ->
            acc
            |> Map.put({:pn_to_lid, pn}, lid)
            |> Map.put({:lid_to_pn, lid}, pn)
          end)

        if updated_mappings != existing_mappings do
          Store.persist(store, Map.put(data, :lid_mapping, updated_mappings))
        end
    end
  rescue
    error ->
      Logger.warning("[HISTORY_SYNC] Failed storing LID mappings: #{inspect(error)}")
      :ok
  end

  defp persist_history_sync_lid_mappings(_state, _lid_mappings), do: :ok

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

  defp maybe_update_chat_name(target, jid, attrs) do
    name_hint =
      Common.first_non_empty([
        Map.get(attrs, "notify"),
        Map.get(attrs, "pushname")
      ])

    if is_binary(name_hint) and name_hint != "" do
      Chat.update_name(target, jid, name_hint)
    else
      maybe_set_number_fallback_name(target, jid)
    end
  end

  defp maybe_set_number_fallback_name(target, jid) do
    jid_str = Common.normalize_jid(jid)

    if JID.user?(jid_str) do
      fallback =
        case String.split(jid_str, "@", parts: 2) do
          [user, _] when user != "" -> user
          _ -> nil
        end

      case {fallback, Chat.get_or_create(target, jid).name} do
        {name, existing}
        when is_binary(name) and name != "" and (is_nil(existing) or existing == "") ->
          Chat.update_name(target, jid, name)

        _ ->
          :ok
      end
    end
  end

  defp build_receipt_actions(from, id, participant, attrs, message_data, state) do
    cond do
      invalid_receipt_target?(from, id) ->
        {[], state}

      needs_retry_receipt?(message_data) ->
        build_retry_receipt_actions(from, id, participant, attrs, message_data, state)

      true ->
        build_delivery_receipt_actions(from, id, participant, attrs, message_data, state)
    end
  end

  defp invalid_receipt_target?(from, id), do: from == "" or id in [nil, ""]

  defp build_retry_receipt_actions(from, id, participant, attrs, message_data, state) do
    retry_reason_code = retry_reason_code(Map.get(message_data, :decrypt_status))
    {retry_count, updated_state} = next_retry_count(state, from, id, participant, message_data)

    actions =
      if retry_count > @max_retry_receipt_count do
        Logger.warning(
          "[DECRYPT] Not sending more retry receipts for #{id}: count=#{retry_count}"
        )

        signal_sessions_update_actions(message_data)
      else
        retry_meta = %{
          category: Map.get(attrs, "category"),
          recipient: Map.get(attrs, "recipient")
        }

        [
          {:send_retry_receipt, from, id, participant, Map.get(attrs, "t"), retry_count,
           retry_reason_code, retry_meta}
        ] ++
          placeholder_resend_actions(from, id, participant, retry_count, message_data) ++
          signal_sessions_update_actions(message_data)
      end

    {actions, updated_state}
  end

  defp build_delivery_receipt_actions(from, id, participant, attrs, message_data, state) do
    receipt_type = delivery_receipt_type(from, attrs, state)
    receipt_meta = %{recipient: Map.get(attrs, "recipient")}

    actions =
      [{:send_receipt, from, id, participant, receipt_type, receipt_meta}] ++
        placeholder_resend_actions(from, id, participant, 1, message_data) ++
        signal_sessions_update_actions(message_data)

    {actions, state}
  end

  defp placeholder_resend_actions(from, id, participant, retry_count, message_data) do
    if needs_placeholder_resend_request?(message_data) and retry_count == 1 do
      sender = if is_binary(participant) and participant != "", do: participant, else: from
      [{:request_placeholder_resend, Common.strip_device_from_jid(from), sender, id}]
    else
      []
    end
  end

  defp delivery_receipt_type(from, attrs, state) do
    if Common.normalize_jid(from) in local_recipient_jids(state, attrs) do
      if Map.get(attrs, "type") == "peer_msg", do: "peer_msg", else: "sender"
    else
      nil
    end
  end

  defp retry_reason_code(
         {:error,
          {:decrypt_failed_for_payload, _, {:decrypt_failed_for_candidate, _, :invalid_mac}}}
       ),
       do: 7

  defp retry_reason_code(
         {:error,
          {:decrypt_failed_for_payload, _,
           {:decrypt_failed_for_candidate, _, :unknown_signed_prekey}}}
       ),
       do: 3

  defp retry_reason_code(
         {:error,
          {:decrypt_failed_for_payload, _, {:decrypt_failed_for_candidate, _, :no_session}}}
       ),
       do: 1

  defp retry_reason_code(_), do: 0

  defp needs_retry_receipt?(%{decrypt_status: {:error, _}}), do: true
  defp needs_retry_receipt?(_), do: false
  defp needs_placeholder_resend_request?(%{placeholder_unavailable: true}), do: true

  defp needs_placeholder_resend_request?(%{decrypt_status: {:error, reason}, encrypted: true}) do
    reason in [:no_ciphertext_candidates, :no_payload_candidates] or
      match?({:decrypt_failed_for_payload, _, _}, reason)
  end

  defp needs_placeholder_resend_request?(_), do: false

  defp signal_sessions_update_actions(%{signal_sessions_update: sessions}) do
    if SessionStore.store?(sessions), do: [{:signal_sessions_updated, sessions}], else: []
  end

  defp signal_sessions_update_actions(_message_data), do: []

  defp next_retry_count(state, from, id, participant, message_data) when is_map(state) do
    key = retry_counter_key(from, id, participant)
    counters = Map.get(state, :retry_counters, %{})
    local_next = Map.get(counters, key, 0) + 1
    incoming_next = incoming_retry_count(message_data) + 1
    next = if local_next == 1 and incoming_next > 1, do: incoming_next, else: local_next
    {next, Map.put(state, :retry_counters, Map.put(counters, key, next))}
  end

  defp next_retry_count(state, _from, _id, _participant, _message_data), do: {1, state}

  defp incoming_retry_count(%{enc_candidates: candidates})
       when is_list(candidates) and candidates != [] do
    candidates
    |> Enum.map(&Map.get(&1, :enc_count))
    |> Enum.filter(&is_integer/1)
    |> case do
      [] -> 0
      counts -> Enum.max(counts)
    end
  end

  defp incoming_retry_count(%{enc_count: count}) when is_integer(count), do: count
  defp incoming_retry_count(_), do: 0

  defp retry_counter_key(from, id, participant) do
    [
      Common.normalize_jid_with_device(from),
      to_string(id || ""),
      Common.normalize_jid_with_device(participant)
    ]
    |> Enum.join("|")
  end

  defp maybe_put_sync_metadata(metadata, _key, nil), do: metadata
  defp maybe_put_sync_metadata(metadata, key, value), do: Map.put(metadata, key, value)
end
