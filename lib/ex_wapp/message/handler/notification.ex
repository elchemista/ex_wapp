defmodule ExWapp.Message.Handler.Notification do
  @moduledoc """
  Handles server notifications and translates them into session actions.

  Notifications are acknowledged here. Notifications that invalidate local
  state also emit a focused action so the session can refresh that state and
  notify wrappers without making them parse protocol nodes.
  """

  require Logger

  alias ExWapp.Binary.Node
  alias ExWapp.{Chat, Config, Log, Pairing, PrivacyToken, Store}
  alias ExWapp.Media.Retry, as: MediaRetry
  alias ExWapp.Message.Handler.{Ack, Common}
  alias ExWapp.Pairing.LinkCode
  alias ExWapp.Session.{Account, DeviceCache, JIDUtils}
  alias ExWapp.Signal.SessionStore

  @spec handle_notification(Node.t(), pid(), map()) :: {:ok, map()} | {:ok, map(), [term()]}
  def handle_notification(%Node{attrs: attrs, content: content}, session, state) do
    type = Map.get(attrs, "type", "")
    from = Map.get(attrs, "from", "")
    id = Map.get(attrs, "id", "")
    participant = Map.get(attrs, "participant")

    Logger.debug("Notification type=#{type} from=#{Log.reference(from)} id=#{Log.reference(id)}")

    ack_actions = notification_ack_actions(id, from, participant, type)

    handle_notification_type(type, attrs, content, session, state)
    |> append_actions(ack_actions)
  end

  defp notification_ack_actions(id, from, participant, type) do
    if id != "" and from != "" do
      [{:send_node, Ack.build_notification_ack(from, id, participant, type)}]
    else
      []
    end
  end

  defp handle_notification_type("encrypt", attrs, content, session, state),
    do: handle_encrypt_notification(attrs, content, session, state)

  defp handle_notification_type("w:gp2", attrs, content, session, state),
    do: handle_group_notification(attrs, content, session, state)

  defp handle_notification_type("account_sync", _attrs, content, session, state),
    do: handle_account_sync(content, session, state)

  defp handle_notification_type("server_sync", _attrs, content, session, state),
    do: handle_server_sync(content, session, state)

  defp handle_notification_type("w:sync:app:state", _attrs, content, session, state),
    do: handle_app_state_sync_notification(content, session, state)

  defp handle_notification_type("devices", attrs, content, session, state),
    do: handle_devices_notification(attrs, content, session, state)

  defp handle_notification_type("contacts", attrs, content, _session, state),
    do: handle_contacts_notification(attrs, content, state)

  defp handle_notification_type("privacy_token", attrs, content, _session, state),
    do: handle_privacy_token_notification(attrs, content, state)

  defp handle_notification_type("mediaretry", attrs, content, _session, state),
    do: handle_media_retry_notification(attrs, content, state)

  defp handle_notification_type("link_code_companion_reg", attrs, content, _session, state),
    do: handle_link_code_notification(attrs, content, state)

  defp handle_notification_type("picture", _attrs, _content, _session, state) do
    {:ok, state}
  end

  defp handle_notification_type(type, attrs, _content, _session, state) do
    Logger.debug(
      "[NOTIFICATION] Unhandled type=#{type} from=#{Log.reference(Map.get(attrs, "from", ""))}"
    )

    {:ok, state}
  end

  defp handle_link_code_notification(attrs, content, state) do
    notification = %Node{
      tag: "notification",
      attrs: attrs,
      content: content
    }

    case LinkCode.finish(Map.get(state, :store), notification) do
      {:ok, %{node: finish_node, jid: jid}} ->
        state =
          case Map.get(state, :pairing) do
            %{store: _store} = pairing ->
              Map.put(state, :pairing, Pairing.mark_link_code_paired(pairing))

            _other ->
              state
          end

        {:ok, state,
         [
           {:send_node, finish_node},
           {:status, :success},
           {:pairing_success, :link_code, jid}
         ]}

      {:error, reason}
      when reason in [:missing_link_code_registration, :link_code_not_pending] ->
        Logger.debug(
          "[PAIRING] Ignoring incomplete link-code notification: #{Log.reason(reason)}"
        )

        {:ok, state}

      {:error, {:missing_link_code_field, _field} = reason} ->
        Logger.debug(
          "[PAIRING] Ignoring incomplete link-code notification: #{Log.reason(reason)}"
        )

        {:ok, state}

      {:error, reason} ->
        Logger.warning("[PAIRING] Link-code finish failed: #{Log.reason(reason)}")
        {:ok, state, [{:error, {:link_code_pairing, reason}}]}
    end
  end

  defp append_actions({:ok, state}, extra_actions), do: {:ok, state, extra_actions}

  defp append_actions({:ok, state, actions}, extra_actions),
    do: {:ok, state, extra_actions ++ actions}

  defp handle_encrypt_notification(attrs, content, _session, state) do
    from = Common.normalize_jid_with_device(Map.get(attrs, "from"))

    cond do
      server_encrypt_origin?(from) ->
        handle_prekey_inventory_notification(content, state)

      Map.get(attrs, "offline") not in [nil, ""] ->
        Logger.debug(
          "[IDENTITY] Ignoring offline identity notification from #{Log.reference(from)}"
        )

        {:ok, state}

      true ->
        invalidate_identity_sessions(from, state)
    end
  end

  defp server_encrypt_origin?(from), do: from in ["", "s.whatsapp.net", "@s.whatsapp.net"]

  defp handle_prekey_inventory_notification(content, state) do
    count =
      case Common.find_child_node(content, "count") do
        %Node{attrs: attrs} -> parse_non_negative_integer(Map.get(attrs, "value"))
        _ -> nil
      end

    threshold = Config.get(Map.get(state, :runtime_cfg, %{}), [:prekeys, :min_threshold], 5)

    if is_integer(count) and count <= threshold do
      Logger.debug("[PREKEYS] Server inventory low (#{count}); scheduling refill")
      {:ok, state, [{:refill_prekeys, count}]}
    else
      {:ok, state}
    end
  end

  defp invalidate_identity_sessions("", state), do: {:ok, state}

  defp invalidate_identity_sessions(from, state) do
    sessions = Map.get(state, :signal_sessions)

    if SessionStore.store?(sessions) do
      before_count = sessions |> SessionStore.list_sessions() |> length()
      lid_mapping = Account.load_lid_mapping(Map.get(state, :store))
      updated_sessions = SessionStore.delete_sessions_for_user(sessions, from, lid_mapping)
      after_count = updated_sessions |> SessionStore.list_sessions() |> length()

      if after_count < before_count do
        Logger.debug(
          "[IDENTITY] Removed #{before_count - after_count} stale session(s) for #{Log.reference(from)}"
        )

        updated_state = Map.put(state, :signal_sessions, updated_sessions)

        {:ok, updated_state,
         [
           {:signal_sessions_updated, updated_sessions},
           {:refresh_identity_session, from}
         ]}
      else
        {:ok, state}
      end
    else
      {:ok, state}
    end
  end

  defp handle_privacy_token_notification(attrs, content, state) do
    storage_jids = privacy_token_storage_jids(attrs, state)

    content
    |> Common.find_child_node("tokens")
    |> extract_privacy_token_nodes()
    |> Enum.each(&maybe_store_privacy_token(state, storage_jids, &1))

    {:ok, state}
  end

  defp privacy_token_storage_jids(attrs, state) do
    lid_mapping = Account.load_lid_mapping(Map.get(state, :store))

    [
      Map.get(attrs, "sender_lid"),
      Map.get(attrs, "from"),
      Map.get(attrs, "sender_pn")
    ]
    |> Enum.flat_map(&JIDUtils.related_bases(&1, lid_mapping))
    |> JIDUtils.normalize_target_list()
    |> Enum.map(&JIDUtils.strip_device/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp extract_privacy_token_nodes(%Node{content: children}) when is_list(children) do
    Enum.filter(children, &match?(%Node{tag: "token"}, &1))
  end

  defp extract_privacy_token_nodes(_tokens_node), do: []

  defp maybe_store_privacy_token(
         state,
         storage_jids,
         %Node{attrs: token_attrs, content: token_content}
       ) do
    if Map.get(token_attrs, "type") == "trusted_contact" do
      timestamp = Map.get(token_attrs, "t")
      token_data = Common.normalize_content(token_content)

      if is_binary(token_data) and storage_jids != [] do
        Logger.debug(
          "[PRIVACY_TOKEN] Storing trusted_contact token for #{length(storage_jids)} PN/LID alias(es) (#{byte_size(token_data)} bytes)"
        )

        store_tctoken(state, storage_jids, token_data, timestamp)
      end
    end
  end

  defp store_tctoken(state, jids, token, timestamp) do
    store = Map.get(state, :store)
    if is_nil(store), do: :ok, else: do_store_tctoken(store, jids, token, timestamp)
  rescue
    error ->
      Logger.warning("[PRIVACY_TOKEN] Failed to store tctoken: #{Log.reason(error)}")
      :ok
  end

  defp do_store_tctoken(store, jids, token, timestamp) do
    record = %{token: token, timestamp: timestamp}

    Store.update(store, :tctokens, %{}, &PrivacyToken.put_newer(&1, jids, record))
  end

  defp handle_devices_notification(attrs, content, _session, state) do
    if is_list(content) do
      Enum.each(content, fn
        %Node{tag: tag, attrs: node_attrs} ->
          Logger.debug("[DEVICES] #{tag}: #{inspect(Log.attrs(node_attrs))}")

        _ ->
          :ok
      end)
    end

    affected_bases =
      notification_jids([%Node{tag: "notification", attrs: attrs, content: content}])

    DeviceCache.invalidate_bases(Map.get(state, :store), affected_bases)
    {:ok, state}
  end

  defp notification_jids(content) when is_list(content) do
    content
    |> Enum.flat_map(&notification_jids/1)
    |> Enum.map(&JIDUtils.strip_device/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp notification_jids(%Node{attrs: attrs, content: content}) do
    current =
      [Map.get(attrs || %{}, "jid"), Map.get(attrs || %{}, "user")]
      |> Enum.map(&Common.normalize_jid_with_device/1)
      |> Enum.filter(&String.contains?(&1, "@"))

    nested = if is_list(content), do: Enum.flat_map(content, &notification_jids/1), else: []
    current ++ nested
  end

  defp notification_jids(_content), do: []

  defp handle_contacts_notification(attrs, content, state) do
    from = Common.normalize_jid(Map.get(attrs, "from"))

    jids =
      [from | contact_jids(content)]
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    payload = %{
      from: from,
      jids: jids,
      notification_id: Map.get(attrs, "id", ""),
      timestamp: Map.get(attrs, "t")
    }

    {:ok, state, [{:contacts_changed, payload}]}
  end

  defp contact_jids(content) when is_list(content) do
    Enum.flat_map(content, &contact_jids/1)
  end

  defp contact_jids(%Node{attrs: attrs, content: content}) do
    current =
      case Common.normalize_jid(Map.get(attrs, "jid")) do
        "" -> []
        jid -> [jid]
      end

    current ++ contact_jids(content)
  end

  defp contact_jids(_content), do: []

  defp handle_group_notification(attrs, content, session, state) do
    group_jid = Common.normalize_jid(Map.get(attrs, "from", ""))

    case {Common.chat_target(session, state), group_jid} do
      {target, jid} when not is_nil(target) and jid != "" ->
        metadata =
          %{is_group: true}
          |> Map.put_new_lazy(:name, fn -> Common.extract_group_subject(content) end)
          |> maybe_put_metadata(
            :last_message_timestamp,
            Common.extract_group_event_timestamp(content)
          )

        Chat.merge_metadata(target, jid, metadata)

      _ ->
        :ok
    end

    {:ok, state}
  end

  defp handle_account_sync(content, session, state) do
    process_sync_collections(content, Common.chat_target(session, state))
    invalidate_own_device_cache_if_needed(content, state)
    {:ok, state}
  end

  defp invalidate_own_device_cache_if_needed(content, state) do
    if contains_node_tag?(content, "devices") do
      store = Map.get(state, :store)

      own_bases =
        [Account.local_account_base_jid(store), Account.local_account_lid_jid(store)]
        |> Enum.reject(&(&1 == ""))

      DeviceCache.invalidate_bases(store, own_bases)
    end

    :ok
  end

  defp contains_node_tag?(content, tag) when is_list(content),
    do: Enum.any?(content, &contains_node_tag?(&1, tag))

  defp contains_node_tag?(%Node{tag: tag}, tag), do: true

  defp contains_node_tag?(%Node{content: content}, tag),
    do: contains_node_tag?(content, tag)

  defp contains_node_tag?(_content, _tag), do: false

  defp handle_media_retry_notification(attrs, content, state) do
    msg_id = Map.get(attrs, "id", "")
    pending_retries = Map.get(state, :pending_media_retries, %{})

    case Map.pop(pending_retries, msg_id) do
      {nil, _pending} ->
        Logger.debug("[MEDIA_RETRY] No pending request for #{Log.reference(msg_id)}")
        {:ok, state}

      {pending, remaining} ->
        cancel_pending_timer(pending)

        result =
          %Node{tag: "notification", attrs: attrs, content: content}
          |> MediaRetry.decode_notification(Map.fetch!(pending, :media_key))
          |> finalize_media_retry(pending, state)

        next_state = Map.put(state, :pending_media_retries, remaining)
        {:ok, next_state, [{:resolve_media_retry, Map.fetch!(pending, :from), result}]}
    end
  end

  defp finalize_media_retry({:ok, direct_path}, pending, state) do
    refreshed_ref = %{Map.fetch!(pending, :ref) | direct_path: direct_path, url: nil}
    persist_refreshed_media(state, pending, refreshed_ref)
    {:ok, refreshed_ref}
  end

  defp finalize_media_retry({:error, _reason} = error, _pending, _state), do: error

  defp persist_refreshed_media(state, pending, refreshed_ref) do
    message = Map.fetch!(pending, :message)
    chat_jid = Map.fetch!(pending, :chat_jid)

    updated_message =
      message
      |> Map.put(:media, refreshed_ref)
      |> update_canonical_media(refreshed_ref)
      |> update_raw_media(refreshed_ref)

    case Map.get(state, :store) do
      nil -> :ok
      store -> Store.upsert_messages(store, chat_jid, [updated_message])
    end
  end

  defp update_canonical_media(%{content: %ExWapp.Message.Content{} = content} = message, ref),
    do: %{message | content: %{content | media: ref}}

  defp update_canonical_media(message, _ref), do: message

  defp update_raw_media(%{raw: raw} = message, ref) when is_map(raw),
    do: %{message | raw: Map.put(raw, :media, ref)}

  defp update_raw_media(message, _ref), do: message

  defp cancel_pending_timer(%{timer: timer}) when is_reference(timer) do
    Process.cancel_timer(timer)
    :ok
  end

  defp cancel_pending_timer(_pending), do: :ok

  defp parse_non_negative_integer(value) when is_integer(value) and value >= 0, do: value

  defp parse_non_negative_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer >= 0 -> integer
      _ -> nil
    end
  end

  defp parse_non_negative_integer(_value), do: nil

  defp handle_app_state_sync_notification(content, session, state) do
    collection_names = extract_app_state_collection_names(content)

    if collection_names != [] do
      session_pid = resolve_session_pid(session, state)

      if is_pid(session_pid) and Process.alive?(session_pid) do
        send(session_pid, {:app_state_sync_collections, collection_names})
      end
    end

    {:ok, state}
  end

  defp extract_app_state_collection_names(content) when is_list(content) do
    content
    |> Enum.flat_map(&collection_names_from_node/1)
    |> Enum.uniq()
  end

  defp extract_app_state_collection_names(_), do: []

  defp collection_names_from_node(%Node{tag: "sync", content: children}) when is_list(children),
    do: Enum.flat_map(children, &collection_names_from_node/1)

  defp collection_names_from_node(%Node{tag: "collection", attrs: attrs}) do
    case Map.get(attrs, "name") do
      name when is_binary(name) and name != "" -> [name]
      _ -> []
    end
  end

  defp collection_names_from_node(_node), do: []

  defp handle_server_sync(content, session, state) do
    process_sync_collections(content, Common.chat_target(session, state))
    {:ok, state}
  end

  defp process_sync_collections(content, target) when is_list(content) and not is_nil(target) do
    Enum.each(content, fn
      %Node{tag: "collection", content: items} when is_list(items) ->
        process_history_items(items, target)

      _ ->
        :ok
    end)
  end

  defp process_sync_collections(_, _), do: :ok

  defp process_history_items(items, target) when is_list(items) and not is_nil(target) do
    Enum.each(items, fn
      %Node{tag: "item", content: item_content} -> process_history_item(item_content, target)
      _ -> :ok
    end)
  end

  defp process_history_items(_, _), do: :ok

  defp process_history_item(content, target) when is_list(content) and not is_nil(target) do
    case Common.find_child_node(content, "chat") do
      %Node{attrs: chat_attrs} -> Common.upsert_chat_from_sync_attrs(target, chat_attrs)
      _ -> :ok
    end

    case Common.find_child_node(content, "group") do
      %Node{attrs: group_attrs} ->
        Common.upsert_chat_from_sync_attrs(target, group_attrs, %{is_group: true})

      _ ->
        :ok
    end
  end

  defp process_history_item(_, _), do: :ok

  defp resolve_session_pid(session, _state) when is_pid(session), do: session
  defp resolve_session_pid(_session, state) when is_map(state), do: Map.get(state, :session_pid)
  defp resolve_session_pid(_session, _state), do: nil

  defp maybe_put_metadata(metadata, _key, nil), do: metadata
  defp maybe_put_metadata(metadata, key, value), do: Map.put(metadata, key, value)
end
