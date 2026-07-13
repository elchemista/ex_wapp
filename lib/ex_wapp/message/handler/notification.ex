defmodule ExWapp.Message.Handler.Notification do
  @moduledoc """
  Handles server notifications and translates them into session actions.

  Notifications are acknowledged here. Notifications that invalidate local
  state also emit a focused action so the session can refresh that state and
  notify wrappers without making them parse protocol nodes.
  """

  require Logger

  alias ExWapp.{Chat, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.{Ack, Common}

  @spec handle_notification(Node.t(), pid(), map()) :: {:ok, map()} | {:ok, map(), [term()]}
  def handle_notification(%Node{attrs: attrs, content: content}, session, state) do
    type = Map.get(attrs, "type", "")
    from = Map.get(attrs, "from", "")
    id = Map.get(attrs, "id", "")
    participant = Map.get(attrs, "participant")

    Logger.debug("Notification type=#{type} from=#{from} id=#{id}")

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

  defp handle_notification_type("encrypt", _attrs, content, session, state),
    do: handle_encrypt_notification(content, session, state)

  defp handle_notification_type("w:gp2", attrs, content, session, state),
    do: handle_group_notification(attrs, content, session, state)

  defp handle_notification_type("account_sync", _attrs, content, session, state),
    do: handle_account_sync(content, session, state)

  defp handle_notification_type("server_sync", _attrs, content, session, state),
    do: handle_server_sync(content, session, state)

  defp handle_notification_type("w:sync:app:state", _attrs, content, session, state),
    do: handle_app_state_sync_notification(content, session, state)

  defp handle_notification_type("devices", _attrs, content, session, state),
    do: handle_devices_notification(content, session, state)

  defp handle_notification_type("contacts", attrs, content, _session, state),
    do: handle_contacts_notification(attrs, content, state)

  defp handle_notification_type("privacy_token", attrs, content, _session, state),
    do: handle_privacy_token_notification(attrs, content, state)

  defp handle_notification_type(type, _attrs, _content, _session, state)
       when type in ["picture", "mediaretry"] do
    {:ok, state}
  end

  defp handle_notification_type(type, attrs, _content, _session, state) do
    Logger.debug("[NOTIFICATION] Unhandled type=#{type} from=#{Map.get(attrs, "from", "")}")
    {:ok, state}
  end

  defp append_actions({:ok, state}, extra_actions), do: {:ok, state, extra_actions}

  defp append_actions({:ok, state, actions}, extra_actions),
    do: {:ok, state, extra_actions ++ actions}

  defp handle_encrypt_notification(_content, _session, state) do
    Logger.debug("Received encryption notification (identity key change)")
    {:ok, state}
  end

  defp handle_privacy_token_notification(attrs, content, state) do
    from = Common.normalize_jid(Map.get(attrs, "from", ""))

    content
    |> Common.find_child_node("tokens")
    |> extract_privacy_token_nodes()
    |> Enum.each(&maybe_store_privacy_token(state, from, &1))

    {:ok, state}
  end

  defp extract_privacy_token_nodes(%Node{content: children}) when is_list(children) do
    Enum.filter(children, &match?(%Node{tag: "token"}, &1))
  end

  defp extract_privacy_token_nodes(_tokens_node), do: []

  defp maybe_store_privacy_token(state, from, %Node{attrs: token_attrs, content: token_content}) do
    if Map.get(token_attrs, "type") == "trusted_contact" do
      timestamp = Map.get(token_attrs, "t")
      token_data = Common.normalize_content(token_content)

      if is_binary(token_data) and from != "" do
        Logger.debug(
          "[PRIVACY_TOKEN] Storing trusted_contact token for #{from} (#{byte_size(token_data)} bytes)"
        )

        store_tctoken(state, from, token_data, timestamp)
      end
    end
  end

  defp store_tctoken(state, jid, token, timestamp) do
    store = Map.get(state, :store)
    if is_nil(store), do: :ok, else: do_store_tctoken(store, jid, token, timestamp)
  rescue
    error ->
      Logger.warning("[PRIVACY_TOKEN] Failed to store tctoken: #{inspect(error)}")
      :ok
  end

  defp do_store_tctoken(store, jid, token, timestamp) do
    data = Store.load!(store)
    tctokens = Map.get(data, :tctokens, %{})
    tctokens = Map.put(tctokens, jid, %{token: token, timestamp: timestamp})
    Store.persist(store, Map.put(data, :tctokens, tctokens))
  end

  defp handle_devices_notification(content, _session, state) do
    if is_list(content) do
      Enum.each(content, fn
        %Node{tag: tag, attrs: node_attrs} ->
          Logger.debug("[DEVICES] #{tag}: #{inspect(node_attrs)}")

        _ ->
          :ok
      end)
    end

    ExWapp.Message.Handler.Inbound.persist_notification_devices(state, content)
    {:ok, state}
  end

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
    {:ok, state}
  end

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
