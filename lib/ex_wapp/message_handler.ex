defmodule ExWapp.MessageHandler do
  @moduledoc """
  Handles incoming WhatsApp messages and notifications.

  This module processes various types of incoming nodes:
  - `message` - Incoming chat messages
  - `notification` - System notifications, history sync, receipts
  - `receipt` - Message delivery/read receipts
  - `ack` - Server acknowledgments for sent messages

  ## Message Flow

      Conn receives encrypted frame
      -> Noise decrypts to plaintext
      -> Binary decodes to node
      -> Session receives :connection_message
      -> MessageHandler.handle_node/3 processes it
      -> Chat module stores the message
      -> Session notifies subscribers
  """

  require Logger

  alias ExWapp.AppState.Engine
  alias ExWapp.{Binary, Chat, JID, MapPath, Store}
  alias ExWapp.Proto.{HistorySync, SyncAction}
  alias ExWapp.Signal.{Encryption, SenderKey}
  alias ExWapp.Binary.Node

  @type chat_target :: pid() | struct()
  @type handler_result :: {:ok, map()} | {:ok, map(), [term()]} | {:error, term()}

  @doc """
  Handles an incoming node and updates state accordingly.

  Returns `{:ok, updated_state}` or `{:ok, updated_state, actions}`.
  """
  @spec handle_node(Node.t(), pid(), map()) :: handler_result()
  def handle_node(%Node{tag: "message"} = node, session, state) do
    handle_message(node, session, state)
  end

  def handle_node(%Node{tag: "notification"} = node, session, state) do
    handle_notification(node, session, state)
  end

  def handle_node(%Node{tag: "receipt"} = node, session, state) do
    handle_receipt(node, session, state)
  end

  def handle_node(%Node{tag: "ack"} = node, session, state) do
    handle_ack(node, session, state)
  end

  def handle_node(%Node{tag: "call"} = node, _session, state) do
    # Ignore call notifications for now
    Logger.debug("Ignoring call node: #{inspect(node.attrs)}")
    {:ok, state}
  end

  def handle_node(%Node{tag: "presence"} = node, _session, state) do
    handle_presence(node, state)
  end

  def handle_node(%Node{tag: "chatstate"} = node, _session, state) do
    handle_chatstate(node, state)
  end

  def handle_node(_node, _session, state) do
    {:ok, state}
  end

  # ============================================================================
  # Message Handling
  # ============================================================================

  defp handle_message(%Node{attrs: attrs, content: content} = _node, session, state) do
    from =
      case Map.get(attrs, "from", "") do
        %JID{} = jid -> jid
        jid when is_binary(jid) -> jid
        _ -> ""
      end

    id = Map.get(attrs, "id", "")
    type = Map.get(attrs, "type", "text")
    timestamp = parse_timestamp(Map.get(attrs, "t"))
    participant = Map.get(attrs, "participant")

    Logger.debug("Received message from=#{from} id=#{id} type=#{type}")

    # Extract message content
    message_data = extract_message_content(content, type)
    {message_data, state} = maybe_decrypt_message(message_data, state, from, participant, attrs)
    state = maybe_ingest_history_sync(message_data, session, state, from, id)
    state = maybe_ingest_app_state_keys(message_data, session, state)

    # Build message struct
    message = %{
      id: id,
      from_me: false,
      timestamp: timestamp,
      text: message_data[:text],
      status: :received,
      participant: participant,
      raw: %{
        type: type,
        attrs: attrs,
        media: message_data[:media]
      }
    }

    # Only store user-visible messages in chat (skip protocol messages like history sync)
    is_protocol = message_data[:message_content_type] == :protocol

    if not is_protocol do
      if target = chat_target(session, state) do
        maybe_update_chat_name(target, from, attrs)
        Chat.add_message(target, from, message)
      end

      # Notify subscribers of new message
      if is_pid(session) do
        send(session, {:new_message, from, message})
      end
    end

    {actions, state} = build_receipt_actions(from, id, participant, attrs, message_data, state)

    # Update stats if state is a map (avoid Access behaviour issues with structs)
    updated_state = update_stats(state, :messages_received)
    {:ok, updated_state, actions}
  end

  defp update_stats(state, key) when is_map(state) do
    stats = Map.get(state, :stats, %{})
    new_count = Map.get(stats, key, 0) + 1
    new_stats = Map.put(stats, key, new_count)
    Map.put(state, :stats, new_stats)
  end

  defp extract_message_content(nil, _type), do: %{text: nil, media: nil}

  defp extract_message_content(content, _type) when is_binary(content) do
    %{text: content, media: nil}
  end

  defp extract_message_content(content, _type) when is_list(content) do
    enc_candidates = extract_enc_candidates(content)

    case enc_candidates do
      [%{enc_type: enc_type, enc_version: enc_version, ciphertext: ciphertext} | _] ->
        %{
          text: "(encrypted: #{enc_type})",
          media: nil,
          encrypted: true,
          enc_type: enc_type,
          enc_version: enc_version,
          ciphertext: ciphertext,
          enc_candidates: enc_candidates
        }

      [] ->
        # Try to find plaintext body
        body_node = find_child_node(content, "body")

        case body_node do
          %Node{content: body} when is_binary(body) ->
            %{text: body, media: nil}

          _ ->
            %{text: nil, media: nil}
        end
    end
  end

  defp extract_message_content(_, _), do: %{text: nil, media: nil}

  # ============================================================================
  # Notification Handling (History Sync, etc.)
  # ============================================================================

  defp handle_notification(%Node{attrs: attrs, content: content}, session, state) do
    type = Map.get(attrs, "type", "")
    from = Map.get(attrs, "from", "")
    id = Map.get(attrs, "id", "")
    participant = Map.get(attrs, "participant")

    Logger.debug("Notification type=#{type} from=#{from} id=#{id}")

    # Always acknowledge notifications so the server keeps sending them
    # Notifications use <ack class="notification"> not <receipt>
    ack_actions = notification_ack_actions(id, from, participant, type)

    handle_notification_type(type, attrs, content, session, state)
    |> append_actions(ack_actions)
  end

  defp notification_ack_actions(id, from, participant, type) do
    if id != "" and from != "" do
      ack_node = build_notification_ack(from, id, participant, type)
      [{:send_node, ack_node}]
    else
      []
    end
  end

  defp receipt_ack_actions(id, from, participant, recipient, type) do
    if id != "" and from != "" do
      ack_node = build_receipt_node_ack(from, id, participant, recipient, type)
      [{:send_node, ack_node}]
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

  defp handle_notification_type("privacy_token", attrs, content, _session, state),
    do: handle_privacy_token_notification(attrs, content, state)

  defp handle_notification_type(type, _attrs, _content, _session, state)
       when type in ["picture", "mediaretry"] do
    {:ok, state}
  end

  defp handle_notification_type(type, attrs, _content, _session, state) do
    from = Map.get(attrs, "from", "")
    Logger.debug("[NOTIFICATION] Unhandled type=#{type} from=#{from}")
    {:ok, state}
  end

  defp append_actions({:ok, state}, extra_actions) do
    {:ok, state, extra_actions}
  end

  defp handle_encrypt_notification(_content, _session, state) do
    Logger.debug("Received encryption notification (identity key change)")
    {:ok, state}
  end

  # Reference: Baileys messages-recv.ts handlePrivacyTokenNotification
  defp handle_privacy_token_notification(attrs, content, state) do
    from = normalize_jid(Map.get(attrs, "from", ""))

    content
    |> find_child_node("tokens")
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
      token_data = normalize_content(token_content)

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
    # Log device list updates — these tell us about user's devices
    if is_list(content) do
      Enum.each(content, fn
        %Node{tag: tag, attrs: node_attrs} ->
          Logger.debug("[DEVICES] #{tag}: #{inspect(node_attrs)}")

        _ ->
          :ok
      end)
    end

    {:ok, state}
  end

  defp handle_group_notification(attrs, content, session, state) do
    group_jid = normalize_jid(Map.get(attrs, "from", ""))

    if target = chat_target(session, state) do
      if group_jid != "" do
        metadata =
          %{is_group: true}
          |> maybe_put_sync_metadata(:name, extract_group_subject(content))
          |> maybe_put_sync_metadata(
            :last_message_timestamp,
            extract_group_event_timestamp(content)
          )

        Chat.merge_metadata(target, group_jid, metadata)
      end
    end

    {:ok, state}
  end

  defp handle_account_sync(content, session, state) do
    process_sync_collections(content, chat_target(session, state))

    {:ok, state}
  end

  # Handle w:sync:app:state notification — server pushes when another device
  # modifies app state (contacts, chat settings, etc.)
  # Reference: whatsmeow appstate.go FetchAppState / handleAppStateSyncNotification
  defp handle_app_state_sync_notification(content, session, state) do
    collection_names = extract_app_state_collection_names(content)

    if collection_names != [] do
      Logger.debug(
        "[APP_STATE] Received sync notification for collections: #{inspect(collection_names)}"
      )

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

  defp collection_names_from_node(%Node{tag: "sync", content: children}) when is_list(children) do
    Enum.flat_map(children, &collection_names_from_node/1)
  end

  defp collection_names_from_node(%Node{tag: "collection", attrs: attrs}) do
    case Map.get(attrs, "name") do
      name when is_binary(name) and name != "" -> [name]
      _ -> []
    end
  end

  defp collection_names_from_node(_node), do: []

  defp handle_server_sync(content, session, state) do
    process_sync_collections(content, chat_target(session, state))

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
      %Node{tag: "item", content: item_content} ->
        process_history_item(item_content, target)

      _ ->
        :ok
    end)
  end

  defp process_history_items(_, _), do: :ok

  defp process_history_item(content, target) when is_list(content) and not is_nil(target) do
    case find_child_node(content, "chat") do
      %Node{attrs: chat_attrs} ->
        upsert_chat_from_sync_attrs(target, chat_attrs)

      _ ->
        :ok
    end

    case find_child_node(content, "group") do
      %Node{attrs: group_attrs} ->
        upsert_chat_from_sync_attrs(target, group_attrs, %{is_group: true})

      _ ->
        :ok
    end
  end

  defp process_history_item(_, _), do: :ok

  # ============================================================================
  # Receipt Handling
  # ============================================================================

  defp handle_receipt(%Node{attrs: attrs, content: content}, session, state) do
    from_raw = Map.get(attrs, "from", "")
    from = normalize_jid(from_raw)
    id = Map.get(attrs, "id", "")
    type = Map.get(attrs, "type", "delivery")
    participant = Map.get(attrs, "participant")
    recipient = Map.get(attrs, "recipient")

    retry_info = extract_retry_info(content)
    target = chat_target(session, state)
    status = receipt_status(type)

    log_receipt(type, retry_info, from, id)
    maybe_update_receipt_status(target, from, id, status)

    actions = receipt_actions(type, from, id)
    ack_actions = receipt_ack_actions(id, from_raw, participant, recipient, type)

    {:ok, state, actions ++ ack_actions}
  end

  # ============================================================================
  # ACK Handling
  # ============================================================================

  defp handle_ack(%Node{attrs: attrs}, session, state) do
    id = Map.get(attrs, "id", "")
    class = Map.get(attrs, "class", "")
    type = Map.get(attrs, "type", "")
    from = normalize_jid(Map.get(attrs, "from", ""))
    to = normalize_jid(Map.get(attrs, "to", ""))

    target = chat_target(session, state)

    log_ack(class, type, id, from, to)
    maybe_update_ack_status(target, ack_target_jid(to, from), id, ack_status(type))

    {:ok, state}
  end

  defp extract_retry_info(content) when is_list(content) do
    case find_child_node(content, "retry") do
      %Node{attrs: retry_attrs} ->
        %{
          count: Map.get(retry_attrs, "count"),
          error: Map.get(retry_attrs, "error"),
          id: Map.get(retry_attrs, "id"),
          timestamp: Map.get(retry_attrs, "t")
        }

      _ ->
        nil
    end
  end

  defp extract_retry_info(_), do: nil

  defp log_receipt("retry", %{count: count, error: error}, from, id) do
    Logger.warning(
      "[RECEIPT] Retry requested from=#{from} id=#{id} retry_count=#{count || "?"} error=#{error || "?"}"
    )
  end

  defp log_receipt("retry", _retry_info, from, id) do
    Logger.warning("[RECEIPT] Retry requested from=#{from} id=#{id}")
  end

  defp log_receipt(type, _retry_info, from, id) do
    Logger.debug("[RECEIPT] from=#{from} id=#{id} type=#{type}")
  end

  defp maybe_update_receipt_status(nil, _from, _id, _status), do: :ok

  defp maybe_update_receipt_status(target, from, id, status) do
    if from != "", do: Chat.update_message_status(target, from, id, status)
    Chat.update_message_status_by_id(target, id, status)
  end

  defp receipt_actions("retry", from, id) when from != "" and id != "" do
    [{:retry_outgoing_message, from, id}]
  end

  defp receipt_actions(_type, _from, _id), do: []

  defp log_ack(class, type, id, from, to) do
    if class in ["message", "chat", "receipt"] or type == "error" do
      log_fn = if type == "error", do: :warning, else: :info
      Logger.log(log_fn, "[ACK] id=#{id} class=#{class} type=#{type} from=#{from} to=#{to}")
    else
      Logger.debug("ACK id=#{id} class=#{class} type=#{type}")
    end
  end

  defp ack_status("error"), do: :failed
  defp ack_status(_type), do: :sent

  defp ack_target_jid(to, _from) when to != "", do: to
  defp ack_target_jid(_to, from) when from != "", do: from
  defp ack_target_jid(_to, _from), do: ""

  defp maybe_update_ack_status(nil, _jid, _id, _status), do: :ok

  defp maybe_update_ack_status(target, jid, id, status) do
    if jid != "", do: Chat.update_message_status(target, jid, id, status)
    Chat.update_message_status_by_id(target, id, status)
  end

  defp receipt_status("read"), do: :read
  defp receipt_status("played"), do: :read
  defp receipt_status("retry"), do: :failed
  defp receipt_status(_), do: :delivered

  # ============================================================================
  # Presence Handling
  # ============================================================================

  defp handle_presence(%Node{attrs: attrs}, state) do
    from = Map.get(attrs, "from", "")
    type = Map.get(attrs, "type", "available")

    Logger.debug("Presence from=#{from} type=#{type}")

    # Could store presence info if needed
    {:ok, state}
  end

  # ============================================================================
  # Chatstate Handling (Typing indicators)
  # ============================================================================

  defp handle_chatstate(%Node{attrs: attrs, content: content}, state) do
    from = Map.get(attrs, "from", "")

    chatstate =
      case content do
        [%Node{tag: "composing"}] -> :typing
        [%Node{tag: "paused"}] -> :stopped
        _ -> :unknown
      end

    Logger.debug("Chatstate from=#{from} state=#{chatstate}")

    # Could notify subscribers of typing status
    {:ok, state}
  end

  # ============================================================================
  # Helpers
  # ============================================================================

  defp build_notification_ack(from, id, participant, type) do
    build_stanza_ack("notification", from, id, participant, nil, type)
  end

  defp build_receipt_node_ack(from, id, participant, recipient, type) do
    build_stanza_ack("receipt", from, id, participant, recipient, type)
  end

  defp build_stanza_ack(stanza_class, from, id, participant, recipient, type) do
    attrs = %{
      "id" => id,
      "to" => from,
      "class" => stanza_class
    }

    attrs = if type != "", do: Map.put(attrs, "type", type), else: attrs

    attrs =
      case participant do
        p when is_binary(p) and p != "" -> Map.put(attrs, "participant", p)
        _ -> attrs
      end

    attrs =
      case recipient do
        r when is_binary(r) and r != "" -> Map.put(attrs, "recipient", r)
        _ -> attrs
      end

    %Node{tag: "ack", attrs: attrs, content: nil}
  end

  defp find_child_node(content, tag) when is_list(content) do
    Enum.find(content, fn
      %Node{tag: ^tag} -> true
      _ -> false
    end)
  end

  defp find_child_node(_, _), do: nil

  defp parse_timestamp(nil), do: System.system_time(:second)

  defp parse_timestamp(ts) when is_binary(ts) do
    case Integer.parse(ts) do
      {int, _} -> int
      :error -> System.system_time(:second)
    end
  end

  defp parse_timestamp(ts) when is_integer(ts), do: ts

  defp upsert_chat_from_sync_attrs(target, attrs, extra_metadata \\ %{})

  defp upsert_chat_from_sync_attrs(target, attrs, extra_metadata)
       when is_map(attrs) and is_map(extra_metadata) do
    jid =
      attrs
      |> find_first_attr(["jid", "id", "chat_jid"])
      |> normalize_jid()

    if jid != "" do
      metadata =
        %{}
        |> maybe_put_sync_metadata(:name, extract_sync_name(attrs))
        |> maybe_put_sync_metadata(
          :unread_count,
          extract_sync_non_neg_integer(attrs, ["count", "unread", "unread_count"])
        )
        |> maybe_put_sync_metadata(
          :last_message_timestamp,
          extract_sync_non_neg_integer(attrs, ["t", "last", "last_message_timestamp", "timestamp"])
        )
        |> maybe_put_sync_metadata(:pinned, extract_sync_boolean(attrs, ["pin", "pinned"]))
        |> maybe_put_sync_metadata(
          :archived,
          extract_sync_boolean(attrs, ["archive", "archived"])
        )
        |> maybe_put_sync_metadata(:is_group, JID.group?(jid))
        |> maybe_put_sync_mute(attrs)
        |> Map.merge(extra_metadata)

      Chat.merge_metadata(target, jid, metadata)
    end
  end

  defp upsert_chat_from_sync_attrs(_target, _attrs, _extra_metadata), do: :ok

  defp maybe_put_sync_mute(metadata, attrs) do
    case extract_sync_integer(attrs, ["mute", "mute_t", "mute_until", "muted_until"]) do
      {:ok, value} when value > 0 -> Map.put(metadata, :muted_until, value)
      {:ok, _value} -> Map.put(metadata, :muted_until, nil)
      :error -> metadata
    end
  end

  defp extract_group_subject(content) when is_list(content) do
    create_node = find_child_node(content, "create")
    subject_node = find_child_node(content, "subject")

    create_group_node =
      case create_node do
        %Node{content: create_content} when is_list(create_content) ->
          find_child_node(create_content, "group")

        _ ->
          nil
      end

    first_non_empty([
      node_attr(subject_node, "subject"),
      node_attr(create_group_node, "subject"),
      node_attr(create_group_node, "name"),
      node_attr(create_node, "subject")
    ])
  end

  defp extract_group_subject(_), do: nil

  defp extract_group_event_timestamp(content) when is_list(content) do
    create_node = find_child_node(content, "create")
    subject_node = find_child_node(content, "subject")

    create_group_node =
      case create_node do
        %Node{content: create_content} when is_list(create_content) ->
          find_child_node(create_content, "group")

        _ ->
          nil
      end

    first_integer_value([
      node_attr(subject_node, "t"),
      node_attr(create_group_node, "creation"),
      node_attr(create_group_node, "t"),
      node_attr(create_node, "t")
    ])
  end

  defp extract_group_event_timestamp(_), do: nil

  defp maybe_put_sync_metadata(metadata, _key, nil), do: metadata
  defp maybe_put_sync_metadata(metadata, key, value), do: Map.put(metadata, key, value)

  defp extract_sync_name(attrs) when is_map(attrs) do
    attrs
    |> find_first_attr(["name", "display_name", "subject", "title"])
    |> normalize_optional_text()
  end

  defp find_first_attr(attrs, keys) when is_map(attrs) and is_list(keys) do
    Enum.find_value(keys, fn key ->
      case Map.get(attrs, key) do
        nil -> nil
        value -> value
      end
    end)
  end

  defp find_first_attr(_, _), do: nil

  defp extract_sync_non_neg_integer(attrs, keys) do
    case extract_sync_integer(attrs, keys) do
      {:ok, value} when value >= 0 -> value
      _ -> nil
    end
  end

  defp extract_sync_integer(attrs, keys) when is_map(attrs) and is_list(keys) do
    Enum.reduce_while(keys, :error, fn key, _acc ->
      case parse_sync_integer(Map.get(attrs, key)) do
        {:ok, value} -> {:halt, {:ok, value}}
        :error -> {:cont, :error}
      end
    end)
  end

  defp extract_sync_integer(_, _), do: :error

  defp extract_sync_boolean(attrs, keys) when is_map(attrs) and is_list(keys) do
    Enum.reduce_while(keys, nil, fn key, _acc ->
      case parse_sync_boolean(Map.get(attrs, key)) do
        {:ok, value} -> {:halt, value}
        :error -> {:cont, nil}
      end
    end)
  end

  defp extract_sync_boolean(_, _), do: nil

  defp first_integer_value(values) when is_list(values) do
    Enum.reduce_while(values, nil, fn value, _acc ->
      case parse_sync_integer(value) do
        {:ok, parsed} -> {:halt, parsed}
        :error -> {:cont, nil}
      end
    end)
  end

  defp parse_sync_integer(value) when is_integer(value), do: {:ok, value}

  defp parse_sync_integer(value) when is_binary(value) do
    value
    |> String.trim()
    |> Integer.parse()
    |> case do
      {parsed, _rest} -> {:ok, parsed}
      :error -> :error
    end
  end

  defp parse_sync_integer(_), do: :error

  defp parse_sync_boolean(value) when is_boolean(value), do: {:ok, value}
  defp parse_sync_boolean(1), do: {:ok, true}
  defp parse_sync_boolean(0), do: {:ok, false}

  defp parse_sync_boolean(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> parse_sync_boolean_string()
  end

  defp parse_sync_boolean(_), do: :error

  defp parse_sync_boolean_string(value) when value in ["1", "true", "yes", "on"],
    do: {:ok, true}

  defp parse_sync_boolean_string(value) when value in ["0", "false", "no", "off"],
    do: {:ok, false}

  defp parse_sync_boolean_string(_value), do: :error

  defp normalize_optional_text(%JID{} = jid), do: normalize_optional_text(JID.to_string(jid))

  defp normalize_optional_text(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end

  defp normalize_optional_text(_), do: nil

  defp node_attr(%Node{attrs: attrs}, key), do: Map.get(attrs, key)
  defp node_attr(_, _), do: nil

  defp parse_enc_version(version) when is_integer(version), do: version

  defp parse_enc_version(version) when is_binary(version) do
    case Integer.parse(version) do
      {value, ""} -> value
      _ -> nil
    end
  end

  defp parse_enc_version(_), do: nil

  defp normalize_content(%Binary.Raw{data: data}), do: data
  defp normalize_content({:raw, data}) when is_binary(data), do: data
  defp normalize_content(content) when is_binary(content), do: content

  defp normalize_content([single]), do: normalize_content(single)

  defp normalize_content(list) when is_list(list) do
    if Enum.all?(list, &is_integer/1) do
      :erlang.list_to_binary(list)
    else
      nil
    end
  end

  defp normalize_content(_), do: nil

  defp maybe_decrypt_message(
         %{encrypted: true, enc_type: enc_type} = message_data,
         state,
         from,
         participant,
         attrs
       ) do
    decrypt_ctx = build_decrypt_context(message_data, state, from, participant, attrs)
    log_decrypt_attempt(enc_type, decrypt_ctx, from)

    case validate_decrypt_context(state, decrypt_ctx) do
      {:ok, store} ->
        decrypt_and_decode_message(
          store,
          state,
          from,
          message_data,
          enc_type,
          decrypt_ctx
        )

      {:error, reason} ->
        decrypt_error_result(message_data, state, reason)
    end
  end

  defp maybe_decrypt_message(message_data, state, _from, _participant, _attrs),
    do: {message_data, state}

  defp build_decrypt_context(message_data, state, from, participant, attrs) do
    sender_candidates = signal_sender_jids(from, participant, attrs, state)
    payload_candidates = encrypted_payload_candidates(message_data)

    decryptable_payloads =
      payload_candidates
      |> prioritize_payload_candidates(state, attrs)
      |> Enum.filter(&is_binary(&1.ciphertext))

    %{
      sender_candidates: sender_candidates,
      payload_candidates: payload_candidates,
      decryptable_payloads: decryptable_payloads
    }
  end

  defp log_decrypt_attempt(enc_type, decrypt_ctx, from) do
    Logger.debug(
      "[DECRYPT] Attempting decrypt: enc_type=#{inspect(enc_type)} payload_candidates=#{length(decrypt_ctx.payload_candidates)} decryptable_payloads=#{length(decrypt_ctx.decryptable_payloads)} from=#{inspect(from)} sender_candidates=#{inspect(decrypt_ctx.sender_candidates)}"
    )
  end

  defp validate_decrypt_context(state, decrypt_ctx) do
    cond do
      is_nil(Map.get(state, :store)) ->
        Logger.warning("[DECRYPT] Missing store in state, cannot decrypt")
        {:error, :missing_store}

      decrypt_ctx.sender_candidates == [] ->
        Logger.warning(
          "[DECRYPT] No sender candidates found from from/participant/sender_lid attrs"
        )

        {:error, :no_sender_candidates}

      decrypt_ctx.decryptable_payloads == [] ->
        Logger.warning(
          "[DECRYPT] Skipping decrypt: no binary ciphertext candidates. first_candidate=#{inspect(List.first(decrypt_ctx.payload_candidates))}"
        )

        {:error, :no_ciphertext_candidates}

      true ->
        {:ok, Map.get(state, :store)}
    end
  end

  defp decrypt_and_decode_message(store, state, from, message_data, enc_type, decrypt_ctx) do
    case decrypt_with_payload_candidates(
           store,
           Map.get(state, :signal_sessions),
           decrypt_ctx.sender_candidates,
           decrypt_ctx.decryptable_payloads,
           from
         ) do
      {:ok, padded_plaintext, updated_sessions, sender_jid, payload} ->
        decode_decrypted_message(
          message_data,
          state,
          from,
          enc_type,
          padded_plaintext,
          updated_sessions,
          sender_jid,
          payload
        )

      {:error, reason} ->
        Logger.warning("[DECRYPT] Failed to decrypt message: #{inspect(reason)}")
        decrypt_error_result(message_data, state, reason)
    end
  end

  defp decode_decrypted_message(
         message_data,
         state,
         from,
         enc_type,
         padded_plaintext,
         updated_sessions,
         sender_jid,
         payload
       ) do
    plaintext =
      Encryption.unpad_message(
        padded_plaintext,
        Map.get(payload, :enc_version) || Map.get(message_data, :enc_version)
      )

    {sender_key_dist_count, state} =
      maybe_process_sender_key_distributions(state, from, sender_jid, plaintext)

    {content_type, decoded_text} =
      classify_decrypted_content(plaintext, sender_key_dist_count)

    text = decoded_text || "(encrypted: #{Map.get(payload, :enc_type, enc_type)})"

    log_decrypted_message(content_type, decoded_text, sender_jid, payload, plaintext, text)

    updated_state = Map.put(state, :signal_sessions, updated_sessions)
    decoded_message_data = build_decoded_message_data(message_data, text, content_type, plaintext)

    {decoded_message_data, updated_state}
  end

  defp log_decrypted_message(
         :protocol,
         _decoded_text,
         _sender_jid,
         payload,
         plaintext,
         _text
       ) do
    Logger.debug(
      "[DECRYPT] Protocol message (#{Map.get(payload, :enc_type)}), plaintext_size=#{byte_size(plaintext)} — skipping chat display"
    )
  end

  defp log_decrypted_message(
         _content_type,
         decoded_text,
         sender_jid,
         payload,
         plaintext,
         text
       ) do
    if is_nil(decoded_text) do
      preview_size = min(byte_size(plaintext), 24)
      preview = Base.encode16(binary_part(plaintext, 0, preview_size), case: :lower)

      Logger.warning(
        "[DECRYPT] Decrypted payload but could not extract text. sender_jid=#{sender_jid} enc_type=#{Map.get(payload, :enc_type)} plaintext_size=#{byte_size(plaintext)} preview=#{preview}"
      )
    end

    Logger.debug(
      "[DECRYPT] Success! sender_jid=#{sender_jid} enc_type=#{Map.get(payload, :enc_type)} plaintext_size=#{byte_size(plaintext)} text=#{inspect(String.slice(text || "", 0, 50))}"
    )
  end

  defp build_decoded_message_data(message_data, text, :protocol, plaintext) do
    message_data
    |> Map.put(:text, text)
    |> Map.put(:decrypt_status, :ok)
    |> Map.put(:message_content_type, :protocol)
    |> Map.put(:protocol_payload, plaintext)
  end

  defp build_decoded_message_data(message_data, text, content_type, _plaintext) do
    message_data
    |> Map.put(:text, text)
    |> Map.put(:decrypt_status, :ok)
    |> Map.put(:message_content_type, content_type)
  end

  defp decrypt_error_result(message_data, state, reason) do
    {Map.put(message_data, :decrypt_status, {:error, reason}), state}
  end

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
        target = chat_target(session, state)

        history_message_count =
          Enum.reduce(conversations, 0, fn conversation, count ->
            count + length(Map.get(conversation, :messages, []))
          end)

        if target do
          Enum.each(conversations, &upsert_chat_from_history_sync(target, &1))
        end

        persist_history_sync_lid_mappings(state, lid_mappings)

        Logger.debug(
          "[HISTORY_SYNC] Applied protocol history sync from=#{normalize_jid(from)} id=#{id} sync_type=#{inspect(sync_type)} conversations=#{length(conversations)} messages=#{history_message_count} lid_mappings=#{length(lid_mappings)}"
        )

        state

      :not_history_sync ->
        state

      {:error, :history_sync_download_required} ->
        Logger.debug(
          "[HISTORY_SYNC] History sync notification requires blob download (inline payload missing) from=#{normalize_jid(from)} id=#{id}"
        )

        state

      {:error, reason} ->
        Logger.warning(
          "[HISTORY_SYNC] Failed to parse protocol history sync from=#{normalize_jid(from)} id=#{id}: #{inspect(reason)}"
        )

        state
    end
  end

  defp maybe_ingest_history_sync(_message_data, _session, state, _from, _id), do: state

  # ============================================================================
  # App State Key Ingestion
  # ============================================================================

  # Detect AppStateSyncKeyShare in protocol messages (ProtocolMessage field 7)
  # Reference: whatsmeow message.go:812 handleAppStateSyncKeyShare
  defp maybe_ingest_app_state_keys(
         %{message_content_type: :protocol, protocol_payload: payload},
         session,
         state
       )
       when is_binary(payload) do
    with {:ok, message_fields} <- decode_wire_fields_safe(payload),
         protocol_message when is_binary(protocol_message) <-
           find_first_ld_field(message_fields, 12),
         {:ok, protocol_fields} <- decode_wire_fields_safe(protocol_message),
         key_share_bytes when is_binary(key_share_bytes) <-
           find_first_ld_field(protocol_fields, 7),
         {:ok, key_share} <- SyncAction.decode_app_state_sync_key_share(key_share_bytes),
         true <- key_share.keys != [] do
      Logger.debug(
        "[APP_STATE] Received AppStateSyncKeyShare with #{length(key_share.keys)} keys"
      )

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

  defp store_app_state_keys(state, keys) when is_list(keys) do
    store = Map.get(state, :store)

    if is_nil(store) do
      Logger.warning("[APP_STATE] No store available, cannot persist app state keys")
      {:error, :missing_store}
    else
      data = Store.load!(store)
      existing_keys = Map.get(data, :app_state_keys, %{})

      updated_keys =
        Enum.reduce(keys, existing_keys, &maybe_put_app_state_key/2)

      if updated_keys != existing_keys do
        Store.persist(store, Map.put(data, :app_state_keys, updated_keys))
        Logger.debug("[APP_STATE] Persisted #{map_size(updated_keys)} total app state keys")
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

        Logger.debug(
          "[APP_STATE] Storing app state key #{key_id_hex} (ts: #{inspect(timestamp)})"
        )

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

  defp resolve_session_pid(session, _state) when is_pid(session), do: session

  defp resolve_session_pid(_session, state) when is_map(state) do
    Map.get(state, :session_pid)
  end

  defp resolve_session_pid(_session, _state), do: nil

  # Lightweight protobuf helpers for key extraction (reuse decode_wire_fields pattern from HistorySync)
  defp decode_wire_fields_safe(binary) when is_binary(binary) do
    decode_wire_fields_acc(binary, [])
  end

  defp decode_wire_fields_acc(<<>>, acc), do: {:ok, Enum.reverse(acc)}

  defp decode_wire_fields_acc(binary, acc) when is_binary(binary) do
    with {:ok, tag, rest} <- decode_varint_safe(binary),
         wire_type <- Bitwise.band(tag, 0x07),
         field_num <- Bitwise.bsr(tag, 3) do
      decode_wire_field_acc(wire_type, rest, field_num, acc)
    end
  end

  defp decode_wire_field_acc(0, rest, field_num, acc) do
    with {:ok, value, tail} <- decode_varint_safe(rest) do
      decode_wire_fields_acc(tail, [{field_num, 0, value} | acc])
    end
  end

  defp decode_wire_field_acc(1, rest, field_num, acc) do
    if byte_size(rest) >= 8 do
      <<_skip::binary-size(8), tail::binary>> = rest
      decode_wire_fields_acc(tail, [{field_num, 1, :fixed64} | acc])
    else
      {:error, :invalid_fixed64}
    end
  end

  defp decode_wire_field_acc(2, rest, field_num, acc) do
    with {:ok, len, tail} <- decode_varint_safe(rest),
         true <- byte_size(tail) >= len do
      <<value::binary-size(len), next::binary>> = tail
      decode_wire_fields_acc(next, [{field_num, 2, value} | acc])
    else
      false -> {:error, :invalid_length}
    end
  end

  defp decode_wire_field_acc(5, rest, field_num, acc) do
    if byte_size(rest) >= 4 do
      <<_skip::binary-size(4), tail::binary>> = rest
      decode_wire_fields_acc(tail, [{field_num, 5, :fixed32} | acc])
    else
      {:error, :invalid_fixed32}
    end
  end

  defp decode_wire_field_acc(wire_type, _rest, _field_num, _acc),
    do: {:error, {:unsupported_wire_type, wire_type}}

  defp decode_varint_safe(binary), do: decode_varint_safe(binary, 0, 0)
  defp decode_varint_safe(_, _, shift) when shift > 63, do: {:error, :invalid_varint}
  defp decode_varint_safe(<<>>, _, _), do: {:error, :invalid_varint}

  defp decode_varint_safe(<<byte, rest::binary>>, acc, shift) do
    value = Bitwise.bor(acc, Bitwise.bsl(Bitwise.band(byte, 0x7F), shift))

    if Bitwise.band(byte, 0x80) == 0 do
      {:ok, value, rest}
    else
      decode_varint_safe(rest, value, shift + 7)
    end
  end

  defp find_first_ld_field(fields, field_num) when is_list(fields) do
    Enum.find_value(fields, fn
      {^field_num, 2, value} when is_binary(value) -> value
      _ -> nil
    end)
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
       when is_list(chat_messages) do
    Chat.merge_messages(target, jid, chat_messages)
  end

  defp maybe_update_history_sync_contact_name(target, jid, conversation) do
    if Map.get(conversation, :is_group, false) do
      :ok
    else
      maybe_update_push_name_from_history_sync(target, jid, Map.get(conversation, :name))
    end
  end

  defp maybe_update_push_name_from_history_sync(target, jid, name)
       when is_binary(name) and name != "" do
    case resolve_store_from_target(target) do
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
      first_non_empty([
        normalize_optional_text(Map.get(message, :id)),
        history_sync_message_fallback_id(message, conversation_jid, index)
      ])

    if is_binary(message_id) and message_id != "" do
      %{
        id: message_id,
        from_me: from_me,
        timestamp: timestamp,
        text: normalize_optional_text(Map.get(message, :text)),
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
    case normalize_jid(value) do
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
    _ ->
      "history-sync-#{index}"
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
        normalized_lid = normalize_jid(lid)
        normalized_pn = normalize_jid(pn)

        if normalized_lid != "" and normalized_pn != "" do
          [{normalized_lid, normalized_pn} | acc]
        else
          acc
        end

      _other, acc ->
        acc
    end)
    |> Enum.uniq()
  end

  defp encrypted_payload_candidates(message_data) when is_map(message_data) do
    candidates = Map.get(message_data, :enc_candidates, [])

    if is_list(candidates) and candidates != [] do
      candidates
    else
      [
        %{
          enc_type: Map.get(message_data, :enc_type, "msg"),
          enc_version: Map.get(message_data, :enc_version),
          ciphertext: Map.get(message_data, :ciphertext),
          to_jid: nil
        }
      ]
    end
  end

  defp maybe_update_chat_name(target, jid, attrs) do
    name_hint =
      first_non_empty([
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
    jid_str = normalize_jid(jid)

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

  defp signal_sender_jids(from, participant, attrs, state) do
    raw_candidates = [
      participant,
      from,
      Map.get(attrs, "sender_lid"),
      Map.get(attrs, "sender_pn"),
      Map.get(attrs, "participant_lid"),
      Map.get(attrs, "participant_pn")
    ]

    with_device =
      raw_candidates
      |> Enum.map(&normalize_jid_with_device/1)
      |> Enum.reject(&(&1 == ""))

    without_device =
      with_device
      |> Enum.map(&strip_device_from_jid/1)
      |> Enum.reject(&(&1 == ""))

    base_candidates =
      (with_device ++ without_device)
      |> Enum.uniq()

    # Expand candidates via PN<->LID mapping (Baileys: getDecryptionJid)
    mapped_candidates = resolve_lid_mapping_candidates(base_candidates, state)

    (base_candidates ++ mapped_candidates)
    |> Enum.uniq()
  end

  defp resolve_lid_mapping_candidates(candidates, state) do
    store = Map.get(state, :store)
    if is_nil(store), do: [], else: do_resolve_lid_mappings(candidates, store)
  rescue
    _ -> []
  end

  defp do_resolve_lid_mappings(candidates, store) do
    data = Store.load!(store)
    lid_mapping = Map.get(data, :lid_mapping, %{})

    if map_size(lid_mapping) == 0 do
      # Also store envelope mappings from attrs for future use
      []
    else
      Enum.flat_map(candidates, fn jid ->
        normalized = strip_device_from_jid(jid)

        mapped =
          [
            Map.get(lid_mapping, {:pn_to_lid, normalized}),
            Map.get(lid_mapping, {:lid_to_pn, normalized})
          ]
          |> Enum.reject(&is_nil/1)

        mapped ++ Enum.map(mapped, &strip_device_from_jid/1)
      end)
      |> Enum.reject(&(&1 == ""))
    end
  end

  defp extract_enc_candidates(content) when is_list(content) do
    do_extract_enc_candidates(content, nil, [])
    |> Enum.reverse()
  end

  defp extract_enc_candidates(_), do: []

  defp do_extract_enc_candidates([], _current_to_jid, acc), do: acc

  defp do_extract_enc_candidates([node | rest], current_to_jid, acc) do
    acc =
      case node do
        %Node{tag: "enc", attrs: enc_attrs, content: enc_content} ->
          [
            %{
              enc_type: Map.get(enc_attrs, "type", "msg"),
              enc_version: parse_enc_version(Map.get(enc_attrs, "v")),
              ciphertext: normalize_content(enc_content),
              to_jid: normalize_jid_with_device(current_to_jid)
            }
            | acc
          ]

        %Node{tag: "to", attrs: to_attrs, content: nested} when is_list(nested) ->
          to_jid = Map.get(to_attrs, "jid")
          do_extract_enc_candidates(nested, to_jid, acc)

        %Node{content: nested} when is_list(nested) ->
          do_extract_enc_candidates(nested, current_to_jid, acc)

        _ ->
          acc
      end

    do_extract_enc_candidates(rest, current_to_jid, acc)
  end

  defp decrypt_with_payload_candidates(_store, _signal_sessions, _candidates, [], _chat_jid) do
    {:error, :no_payload_candidates}
  end

  defp decrypt_with_payload_candidates(
         store,
         signal_sessions,
         candidates,
         [payload | rest],
         chat_jid
       ) do
    ciphertext = Map.get(payload, :ciphertext)
    enc_type = Map.get(payload, :enc_type, "msg")

    case decrypt_with_candidates(
           store,
           signal_sessions,
           candidates,
           ciphertext,
           enc_type,
           chat_jid
         ) do
      {:ok, plaintext, updated_sessions, sender_jid} ->
        {:ok, plaintext, updated_sessions, sender_jid, payload}

      {:error, reason} ->
        case decrypt_with_payload_candidates(store, signal_sessions, candidates, rest, chat_jid) do
          {:ok, _plaintext, _updated_sessions, _sender_jid, _payload} = success ->
            success

          {:error, _other} ->
            {:error, {:decrypt_failed_for_payload, enc_type, reason}}
        end
    end
  end

  defp decrypt_with_candidates(_store, _signal_sessions, [], _ciphertext, _enc_type, _chat_jid) do
    {:error, :no_sender_candidates}
  end

  defp decrypt_with_candidates(
         store,
         signal_sessions,
         [candidate | rest],
         ciphertext,
         enc_type,
         chat_jid
       ) do
    decrypt_result =
      if sender_key_message?(enc_type, chat_jid) do
        case SenderKey.decrypt_group_message(store, chat_jid, candidate, ciphertext) do
          {:ok, plaintext} -> {:ok, plaintext, signal_sessions}
          {:error, reason} -> {:error, reason}
        end
      else
        Encryption.decrypt_from_sender_sync(
          store,
          signal_sessions,
          candidate,
          ciphertext,
          enc_type
        )
      end

    case decrypt_result do
      {:ok, plaintext, updated_sessions} ->
        {:ok, plaintext, updated_sessions, candidate}

      {:error, reason} ->
        case decrypt_with_candidates(store, signal_sessions, rest, ciphertext, enc_type, chat_jid) do
          {:ok, _plaintext, _updated_sessions, _candidate} = success ->
            success

          {:error, _} ->
            {:error, {:decrypt_failed_for_candidate, candidate, reason}}
        end
    end
  end

  defp sender_key_message?(enc_type, chat_jid) do
    enc_type in [:skmsg, "skmsg"] and group_jid?(chat_jid)
  end

  defp group_jid?(jid) do
    jid
    |> normalize_jid()
    |> JID.group?()
  end

  defp maybe_process_sender_key_distributions(state, from, sender_jid, plaintext)
       when is_binary(plaintext) do
    store = Map.get(state, :store)

    cond do
      is_nil(store) ->
        {0, state}

      not group_jid?(from) ->
        {0, state}

      true ->
        case SenderKey.process_distributions_from_plaintext(store, from, sender_jid, plaintext) do
          {:ok, count} ->
            {count, state}

          {:error, reason} ->
            Logger.warning(
              "[SENDER_KEY] Failed processing sender key distribution: #{inspect(reason)}"
            )

            {0, state}
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
        build_delivery_receipt_actions(from, id, participant, attrs, state)
    end
  end

  defp invalid_receipt_target?(from, id), do: from == "" or id in [nil, ""]

  defp build_retry_receipt_actions(from, id, participant, attrs, message_data, state) do
    retry_reason_code = retry_reason_code(Map.get(message_data, :decrypt_status))
    {retry_count, updated_state} = next_retry_count(state, from, id, participant)

    retry_meta = %{
      category: Map.get(attrs, "category"),
      recipient: Map.get(attrs, "recipient")
    }

    {[
       {:send_retry_receipt, from, id, participant, Map.get(attrs, "t"), retry_count,
        retry_reason_code, retry_meta}
     ], updated_state}
  end

  defp build_delivery_receipt_actions(from, id, participant, attrs, state) do
    receipt_type = delivery_receipt_type(from, attrs, state)
    receipt_meta = %{recipient: Map.get(attrs, "recipient")}
    {[{:send_receipt, from, id, participant, receipt_type, receipt_meta}], state}
  end

  defp delivery_receipt_type(from, attrs, state) do
    if normalize_jid(from) in local_recipient_jids(state, attrs) do
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

  defp next_retry_count(state, from, id, participant) when is_map(state) do
    key = retry_counter_key(from, id, participant)
    counters = Map.get(state, :retry_counters, %{})
    next = Map.get(counters, key, 0) + 1
    {next, Map.put(state, :retry_counters, Map.put(counters, key, next))}
  end

  defp next_retry_count(state, _from, _id, _participant), do: {1, state}

  defp retry_counter_key(from, id, participant) do
    [
      normalize_jid_with_device(from),
      to_string(id || ""),
      normalize_jid_with_device(participant)
    ]
    |> Enum.join("|")
  end

  defp prioritize_payload_candidates(payload_candidates, state, attrs)
       when is_list(payload_candidates) do
    local_jids = local_recipient_jids(state, attrs)

    if local_jids == [] do
      payload_candidates
    else
      {matching, non_matching} =
        Enum.split_with(payload_candidates, fn payload ->
          payload_to = Map.get(payload, :to_jid)

          payload_to in local_jids ||
            strip_device_from_jid(payload_to) in local_jids
        end)

      if matching == [] do
        payload_candidates
      else
        matching ++ non_matching
      end
    end
  end

  defp prioritize_payload_candidates(payload_candidates, _state, _attrs), do: payload_candidates

  defp local_recipient_jids(state, attrs) do
    from_store =
      case Map.get(state, :store) do
        nil ->
          []

        store ->
          data = Store.load!(store)

          [
            MapPath.first(data, [
              ["pairing", "device", "jid"],
              ["client_info", "jid"]
            ]),
            MapPath.get(data, ["client_info", "wid"]),
            MapPath.get(data, ["client_info", "lid"])
          ]
      end

    from_attrs = [
      Map.get(attrs, "to"),
      Map.get(attrs, "recipient"),
      Map.get(attrs, "recipient_lid"),
      Map.get(attrs, "recipient_pn")
    ]

    normalized_with_device =
      (from_store ++ from_attrs)
      |> Enum.map(&normalize_jid_with_device/1)
      |> Enum.reject(&(&1 == ""))

    normalized_without_device =
      normalized_with_device
      |> Enum.map(&strip_device_from_jid/1)
      |> Enum.reject(&(&1 == ""))

    Enum.uniq(normalized_with_device ++ normalized_without_device)
  end

  defp normalize_jid_with_device(%JID{} = jid), do: normalize_jid_with_device(JID.to_string(jid))
  defp normalize_jid_with_device(nil), do: ""

  defp normalize_jid_with_device(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
  end

  defp normalize_jid_with_device(_), do: ""

  defp strip_device_from_jid(jid) when is_binary(jid) do
    String.replace(jid, ~r/:(\d+)@/, "@")
  end

  defp strip_device_from_jid(_), do: ""

  defp normalize_jid(%JID{} = jid), do: normalize_jid(JID.to_string(jid))
  defp normalize_jid(nil), do: ""

  defp normalize_jid(jid) when is_binary(jid) do
    jid
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
    |> then(fn value ->
      case String.split(value, "@", parts: 2) do
        [user, domain] -> Regex.replace(~r/:(\d+)$/, user, "") <> "@" <> domain
        _ -> value
      end
    end)
  end

  defp normalize_jid(_), do: ""

  @max_message_decode_depth 6

  defp classify_decrypted_content(_payload, sender_key_distribution_count)
       when sender_key_distribution_count > 0 do
    {:protocol, nil}
  end

  defp classify_decrypted_content(payload, _sender_key_distribution_count)
       when is_binary(payload) do
    # Check if this is a protocolMessage (field 12) - history sync, app state, etc.
    case find_length_delimited_field(payload, 12) do
      {:ok, _protocol_msg} ->
        {:protocol, nil}

      _ ->
        # Try to extract user-visible text
        case decode_message_text_recursive(payload, 0) do
          {:ok, text} -> {:user_message, text}
          :error -> {:user_message, nil}
        end
    end
  end

  defp decode_message_text_recursive(_payload, depth) when depth > @max_message_decode_depth,
    do: :error

  defp decode_message_text_recursive(payload, depth) do
    case decode_message_text_shallow(payload) do
      {:ok, text} ->
        {:ok, text}

      :error ->
        decode_nested_message_text(payload, depth)
    end
  end

  defp decode_nested_message_text(payload, depth) do
    case collect_length_delimited_fields(payload) do
      {:ok, nested_values} ->
        Enum.reduce_while(nested_values, :error, fn nested, _acc ->
          reduce_nested_message_text(nested, depth)
        end)

      {:error, _reason} ->
        :error
    end
  end

  defp reduce_nested_message_text(nested, depth) do
    case decode_message_text_recursive(nested, depth + 1) do
      {:ok, text} -> {:halt, {:ok, text}}
      :error -> {:cont, :error}
    end
  end

  defp decode_message_text_shallow(payload) do
    with {:ok, conversation} <- find_length_delimited_field(payload, 1),
         true <- valid_text_payload?(conversation) do
      {:ok, conversation}
    else
      _ ->
        with {:ok, extended} <- find_length_delimited_field(payload, 6),
             {:ok, text} <- find_length_delimited_field(extended, 1),
             true <- valid_text_payload?(text) do
          {:ok, text}
        else
          _ -> :error
        end
    end
  end

  defp valid_text_payload?(value) when is_binary(value) do
    value != "" and String.valid?(value)
  end

  defp first_non_empty(values) when is_list(values) do
    Enum.find(values, fn
      value when is_binary(value) and value != "" -> true
      _ -> false
    end)
  end

  defp find_length_delimited_field(binary, field_num) when is_binary(binary) do
    do_find_length_delimited_field(binary, field_num)
  end

  defp do_find_length_delimited_field(<<>>, _field_num), do: {:error, :not_found}

  defp do_find_length_delimited_field(binary, field_num) do
    with {:ok, tag, rest} <- decode_varint(binary),
         wire_type <- Bitwise.band(tag, 0x07),
         field <- Bitwise.bsr(tag, 3) do
      find_length_delimited_by_wire_type(wire_type, rest, field, field_num)
    end
  end

  defp find_length_delimited_by_wire_type(0, rest, _field, field_num) do
    with {:ok, _value, tail} <- decode_varint(rest) do
      do_find_length_delimited_field(tail, field_num)
    end
  end

  defp find_length_delimited_by_wire_type(1, rest, _field, field_num) do
    if byte_size(rest) >= 8 do
      <<_skip::binary-size(8), tail::binary>> = rest
      do_find_length_delimited_field(tail, field_num)
    else
      {:error, :invalid_fixed64}
    end
  end

  defp find_length_delimited_by_wire_type(2, rest, field, field_num) do
    with {:ok, len, tail} <- decode_varint(rest),
         true <- byte_size(tail) >= len do
      <<value::binary-size(len), next::binary>> = tail

      if field == field_num do
        {:ok, value}
      else
        do_find_length_delimited_field(next, field_num)
      end
    else
      false -> {:error, :invalid_length}
    end
  end

  defp find_length_delimited_by_wire_type(5, rest, _field, field_num) do
    if byte_size(rest) >= 4 do
      <<_skip::binary-size(4), tail::binary>> = rest
      do_find_length_delimited_field(tail, field_num)
    else
      {:error, :invalid_fixed32}
    end
  end

  defp find_length_delimited_by_wire_type(wire_type, _rest, _field, _field_num),
    do: {:error, {:unsupported_wire_type, wire_type}}

  defp decode_varint(binary), do: decode_varint(binary, 0, 0)
  defp decode_varint(_, _, shift) when shift > 63, do: {:error, :invalid_varint}
  defp decode_varint(<<>>, _, _), do: {:error, :invalid_varint}

  defp decode_varint(<<byte, rest::binary>>, acc, shift) do
    value = Bitwise.bor(acc, Bitwise.bsl(Bitwise.band(byte, 0x7F), shift))

    if Bitwise.band(byte, 0x80) == 0 do
      {:ok, value, rest}
    else
      decode_varint(rest, value, shift + 7)
    end
  end

  defp collect_length_delimited_fields(binary), do: collect_length_delimited_fields(binary, [])

  defp collect_length_delimited_fields(<<>>, acc), do: {:ok, Enum.reverse(acc)}

  defp collect_length_delimited_fields(binary, acc) do
    with {:ok, tag, rest} <- decode_varint(binary),
         wire_type <- Bitwise.band(tag, 0x07) do
      collect_length_delimited_by_wire_type(wire_type, rest, acc)
    end
  end

  defp collect_length_delimited_by_wire_type(0, rest, acc) do
    with {:ok, _value, tail} <- decode_varint(rest) do
      collect_length_delimited_fields(tail, acc)
    end
  end

  defp collect_length_delimited_by_wire_type(1, rest, acc) do
    if byte_size(rest) >= 8 do
      <<_skip::binary-size(8), tail::binary>> = rest
      collect_length_delimited_fields(tail, acc)
    else
      {:error, :invalid_fixed64}
    end
  end

  defp collect_length_delimited_by_wire_type(2, rest, acc) do
    with {:ok, len, tail} <- decode_varint(rest),
         true <- byte_size(tail) >= len do
      <<value::binary-size(len), next::binary>> = tail
      collect_length_delimited_fields(next, [value | acc])
    else
      false -> {:error, :invalid_length}
    end
  end

  defp collect_length_delimited_by_wire_type(5, rest, acc) do
    if byte_size(rest) >= 4 do
      <<_skip::binary-size(4), tail::binary>> = rest
      collect_length_delimited_fields(tail, acc)
    else
      {:error, :invalid_fixed32}
    end
  end

  defp collect_length_delimited_by_wire_type(wire_type, _rest, _acc),
    do: {:error, {:unsupported_wire_type, wire_type}}

  @spec chat_target(pid() | term(), map()) :: chat_target() | nil
  defp chat_target(session, state) do
    case Map.get(state, :store) do
      nil -> if(is_pid(session), do: session, else: nil)
      %{__struct__: _} = store -> store
      _ -> if(is_pid(session), do: session, else: nil)
    end
  end

  # Resolve a store struct from a chat target (pid or store struct).
  defp resolve_store_from_target(%{__struct__: _} = store), do: store

  defp resolve_store_from_target(pid) when is_pid(pid) do
    GenServer.call(pid, :get_store)
  catch
    :exit, _ -> nil
  end
end
