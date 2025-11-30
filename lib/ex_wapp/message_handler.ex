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

  alias ExWapp.{Binary, Chat}
  alias ExWapp.Binary.Node

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

  def handle_node(%Node{tag: "ack"} = node, _session, state) do
    handle_ack(node, state)
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
    from = Map.get(attrs, "from", "")
    id = Map.get(attrs, "id", "")
    type = Map.get(attrs, "type", "text")
    timestamp = parse_timestamp(Map.get(attrs, "t"))
    participant = Map.get(attrs, "participant")

    Logger.info("Received message from=#{from} id=#{id} type=#{type}")

    # Extract message content
    message_data = extract_message_content(content, type)

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

    # Store message in chat
    if is_pid(session) do
      Chat.add_message(session, from, message)

      # Notify subscribers of new message
      send(session, {:new_message, from, message})
    end

    # Send delivery receipt
    actions = [
      {:send_receipt, from, id, participant, "delivery"}
    ]

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

  defp update_stats(state, _key), do: state

  defp extract_message_content(nil, _type), do: %{text: nil, media: nil}

  defp extract_message_content(content, _type) when is_binary(content) do
    %{text: content, media: nil}
  end

  defp extract_message_content(content, _type) when is_list(content) do
    # Look for enc (encrypted) or plaintext nodes
    enc_node = find_child_node(content, "enc")

    case enc_node do
      %Node{attrs: enc_attrs, content: enc_content} ->
        # Encrypted message - content is the ciphertext
        enc_type = Map.get(enc_attrs, "type", "msg")

        %{
          text: "(encrypted: #{enc_type})",
          media: nil,
          encrypted: true,
          enc_type: enc_type,
          ciphertext: normalize_content(enc_content)
        }

      nil ->
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

    Logger.debug("Notification type=#{type} from=#{from}")

    case type do
      "encrypt" ->
        # Encryption notification - identity key change
        handle_encrypt_notification(content, session, state)

      "w:gp2" ->
        # Group notification
        handle_group_notification(attrs, content, session, state)

      "account_sync" ->
        # Account sync - could be history
        handle_account_sync(content, session, state)

      "server_sync" ->
        # Server sync notification
        handle_server_sync(content, session, state)

      "picture" ->
        # Profile picture update
        {:ok, state}

      "mediaretry" ->
        # Media retry request
        {:ok, state}

      _ ->
        Logger.debug("Unhandled notification type: #{type}")
        {:ok, state}
    end
  end

  defp handle_encrypt_notification(_content, _session, state) do
    # Handle identity key change - just log for now
    Logger.info("Received encryption notification (identity key change)")
    {:ok, state}
  end

  defp handle_group_notification(attrs, content, session, state) do
    group_jid = Map.get(attrs, "from", "")

    # Extract group info changes
    case find_child_node(content, "add") || find_child_node(content, "remove") ||
           find_child_node(content, "subject") do
      %Node{tag: "subject", attrs: subj_attrs} ->
        subject = Map.get(subj_attrs, "subject", "")

        if is_pid(session) do
          Chat.update_name(session, group_jid, subject)
        end

      _ ->
        :ok
    end

    {:ok, state}
  end

  defp handle_account_sync(content, session, state) do
    # Look for history sync blob
    case find_child_node(content, "collection") do
      %Node{attrs: %{"name" => "regular_high"}, content: items} when is_list(items) ->
        # Process history sync items
        process_history_items(items, session)

      _ ->
        :ok
    end

    {:ok, state}
  end

  defp handle_server_sync(content, session, state) do
    # Server sync can contain chat/message data
    case find_child_node(content, "collection") do
      %Node{content: items} when is_list(items) ->
        process_history_items(items, session)

      _ ->
        :ok
    end

    {:ok, state}
  end

  defp process_history_items(items, session) when is_list(items) do
    Enum.each(items, fn
      %Node{tag: "item", content: item_content} ->
        process_history_item(item_content, session)

      _ ->
        :ok
    end)
  end

  defp process_history_items(_, _), do: :ok

  defp process_history_item(content, session) when is_list(content) do
    # Look for conversation data
    case find_child_node(content, "chat") do
      %Node{attrs: chat_attrs} ->
        jid = Map.get(chat_attrs, "jid", "")
        name = Map.get(chat_attrs, "name")

        if jid != "" and is_pid(session) do
          # Create or update chat
          Chat.get_or_create(session, jid, name: name)
        end

      _ ->
        :ok
    end
  end

  defp process_history_item(_, _), do: :ok

  # ============================================================================
  # Receipt Handling
  # ============================================================================

  defp handle_receipt(%Node{attrs: attrs}, session, state) do
    from = Map.get(attrs, "from", "")
    id = Map.get(attrs, "id", "")
    type = Map.get(attrs, "type", "delivery")

    Logger.debug("Receipt from=#{from} id=#{id} type=#{type}")

    # Update message status
    status =
      case type do
        "read" -> :read
        "played" -> :read
        _ -> :delivered
      end

    if is_pid(session) do
      Chat.update_message_status(session, from, id, status)
    end

    {:ok, state}
  end

  # ============================================================================
  # ACK Handling
  # ============================================================================

  defp handle_ack(%Node{attrs: attrs}, state) do
    id = Map.get(attrs, "id", "")
    class = Map.get(attrs, "class", "")

    Logger.debug("ACK id=#{id} class=#{class}")

    # Message was accepted by server
    {:ok, state}
  end

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

  defp normalize_content(%Binary.Raw{data: data}), do: data
  defp normalize_content(content) when is_binary(content), do: content
  defp normalize_content(_), do: nil
end
