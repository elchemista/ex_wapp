defmodule ExWapp.Chat do
  @moduledoc """
  Chat and conversation management.

  This module handles:
  - Storing and retrieving conversations
  - Managing chat history
  - Tracking message state (read, delivered, etc.)

  ## Storage

  Chats are persisted via the session's store adapter. The chat data is stored
  under the `:chats` key in the store.

  ## Usage

      # Get all chats from session
      chats = ExWapp.Chat.list(session)

      # Get a specific chat
      {:ok, chat} = ExWapp.Chat.get(session, "1234567890@s.whatsapp.net")

      # Get messages for a chat
      messages = ExWapp.Chat.messages(session, "1234567890@s.whatsapp.net")
  """

  alias ExWapp.{Binary, JID, Store}

  @type target :: pid() | struct()
  @type message_status :: :pending | :sent | :received | :delivered | :read | :failed

  @type message :: %{
          id: String.t(),
          from_me: boolean(),
          timestamp: integer(),
          text: String.t() | nil,
          status: message_status(),
          participant: String.t() | JID.t() | nil,
          raw: map() | nil
        }

  @type chat :: %__MODULE__{
          jid: String.t(),
          name: String.t() | nil,
          unread_count: non_neg_integer(),
          last_message_timestamp: integer() | nil,
          pinned: boolean(),
          muted_until: integer() | nil,
          archived: boolean(),
          is_group: boolean(),
          messages: [message()]
        }

  defstruct [
    :jid,
    :name,
    unread_count: 0,
    last_message_timestamp: nil,
    pinned: false,
    muted_until: nil,
    archived: false,
    is_group: false,
    messages: []
  ]

  @doc """
  Lists all chats for a session.

  Returns a list of chat structs sorted by last message timestamp (most recent first).
  """
  @spec list(target()) :: [chat()]
  def list(target) do
    store = resolve_store(target)

    if store do
      data = Store.load!(store)

      data
      |> Map.get(:chats, %{})
      |> Map.values()
      |> Enum.sort_by(&(&1.last_message_timestamp || 0), :desc)
    else
      []
    end
  end

  @doc """
  Lists only group chats for a session.
  """
  @spec list_groups(target()) :: [chat()]
  def list_groups(target) do
    target
    |> list()
    |> Enum.filter(& &1.is_group)
  end

  @doc """
  Gets a specific chat by JID.
  """
  @spec get(target(), String.t() | JID.t()) :: {:ok, chat()} | {:error, :not_found}
  def get(target, jid) do
    jid_str = normalize_jid(jid)
    store = resolve_store(target)

    if store do
      data = Store.load!(store)

      case get_in(data, [:chats, jid_str]) do
        nil -> {:error, :not_found}
        chat -> {:ok, chat}
      end
    else
      {:error, :not_found}
    end
  end

  @doc """
  Gets or creates a chat for a JID.
  """
  @spec get_or_create(target(), String.t() | JID.t(), keyword()) :: chat()
  def get_or_create(target, jid, opts \\ []) do
    # Normalize JID to string
    jid_str = normalize_jid(jid)

    case get(target, jid_str) do
      {:ok, chat} ->
        chat

      {:error, :not_found} ->
        chat = new_chat(jid_str, opts)
        save_chat(target, chat)
        chat
    end
  end

  @doc """
  Creates a new chat struct.
  """
  @spec new_chat(String.t(), keyword()) :: chat()
  def new_chat(jid, opts \\ []) do
    %__MODULE__{
      jid: jid,
      name: Keyword.get(opts, :name),
      is_group: JID.group?(jid),
      unread_count: 0,
      messages: []
    }
  end

  @doc """
  Gets messages for a chat, optionally with pagination.
  """
  @spec messages(target(), String.t() | JID.t(), keyword()) :: [message()]
  def messages(target, jid, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    case get(target, jid) do
      {:ok, chat} ->
        chat.messages
        |> Enum.drop(offset)
        |> Enum.take(limit)

      {:error, _} ->
        []
    end
  end

  @doc """
  Merges a batch of messages into a chat, deduplicating by message ID.
  """
  @spec merge_messages(target(), String.t() | JID.t(), [message()]) :: :ok
  def merge_messages(target, jid, messages) when is_list(messages) do
    chat = get_or_create(target, jid)

    normalized_new_messages =
      messages
      |> Enum.map(&normalize_merged_message/1)
      |> Enum.reject(&is_nil/1)

    merged_messages =
      (chat.messages ++ normalized_new_messages)
      |> Enum.uniq_by(&message_identity/1)
      |> Enum.sort_by(&message_sort_key/1, :desc)
      |> Enum.take(1000)

    updated_chat =
      case latest_message_timestamp(merged_messages) do
        nil ->
          %{chat | messages: merged_messages}

        latest when is_integer(latest) ->
          current =
            if(is_integer(chat.last_message_timestamp), do: chat.last_message_timestamp, else: 0)

          %{chat | messages: merged_messages, last_message_timestamp: max(current, latest)}
      end

    save_chat(target, updated_chat)
  end

  def merge_messages(_target, _jid, _messages), do: :ok

  @doc """
  Adds a message to a chat.
  """
  @spec add_message(target(), String.t() | JID.t(), message()) :: :ok
  def add_message(target, jid, message) do
    chat = get_or_create(target, jid)

    updated_chat = %{
      chat
      | messages: [message | chat.messages] |> Enum.take(1000),
        last_message_timestamp: message.timestamp,
        unread_count: if(message.from_me, do: chat.unread_count, else: chat.unread_count + 1)
    }

    save_chat(target, updated_chat)
  end

  @doc """
  Marks all messages in a chat as read.
  """
  @spec mark_read(target(), String.t() | JID.t()) :: :ok
  def mark_read(target, jid) do
    case get(target, jid) do
      {:ok, chat} ->
        updated_chat = %{chat | unread_count: 0}
        save_chat(target, updated_chat)

      {:error, _} ->
        :ok
    end
  end

  @doc """
  Updates a message status.
  """
  @spec update_message_status(target(), String.t() | JID.t(), String.t(), message_status()) :: :ok
  def update_message_status(target, jid, message_id, status) do
    case get(target, jid) do
      {:ok, chat} ->
        updated_messages =
          Enum.map(chat.messages, fn msg ->
            if msg.id == message_id do
              %{msg | status: status}
            else
              msg
            end
          end)

        save_chat(target, %{chat | messages: updated_messages})

      {:error, _} ->
        :ok
    end
  end

  @doc """
  Updates a message status by message ID across all chats.

  Useful for ACK nodes that do not provide a chat JID we can trust.
  """
  @spec update_message_status_by_id(target(), String.t(), message_status()) :: :ok
  def update_message_status_by_id(target, message_id, status) when is_binary(message_id) do
    store = resolve_store(target)

    if store do
      data = Store.load!(store)
      chats = Map.get(data, :chats, %{})

      updated_chats =
        Enum.reduce(chats, %{}, fn {jid, chat}, acc ->
          updated_messages =
            Enum.map(chat.messages, fn msg ->
              if msg.id == message_id do
                %{msg | status: status}
              else
                msg
              end
            end)

          Map.put(acc, jid, %{chat | messages: updated_messages})
        end)

      Store.persist(store, Map.put(data, :chats, updated_chats))
    end

    :ok
  end

  @doc """
  Deletes a chat.
  """
  @spec delete(target(), String.t()) :: :ok
  def delete(target, jid) do
    store = resolve_store(target)

    if store do
      data = Store.load!(store)
      chats = Map.get(data, :chats, %{})
      updated_data = Map.put(data, :chats, Map.delete(chats, jid))
      Store.persist(store, updated_data)
    end
  end

  @doc """
  Archives a chat.
  """
  @spec archive(target(), String.t()) :: :ok
  def archive(target, jid) do
    update_chat(target, jid, fn chat -> %{chat | archived: true} end)
  end

  @doc """
  Unarchives a chat.
  """
  @spec unarchive(target(), String.t()) :: :ok
  def unarchive(target, jid) do
    update_chat(target, jid, fn chat -> %{chat | archived: false} end)
  end

  @doc """
  Pins a chat.
  """
  @spec pin(target(), String.t()) :: :ok
  def pin(target, jid) do
    update_chat(target, jid, fn chat -> %{chat | pinned: true} end)
  end

  @doc """
  Unpins a chat.
  """
  @spec unpin(target(), String.t()) :: :ok
  def unpin(target, jid) do
    update_chat(target, jid, fn chat -> %{chat | pinned: false} end)
  end

  @doc "Update archived state from app state sync dispatch."
  @spec update_archived(target(), String.t(), boolean()) :: :ok
  def update_archived(target, jid, archived) when is_boolean(archived) do
    chat = get_or_create(target, jid)
    save_chat(target, %{chat | archived: archived})
  end

  @doc "Update pinned state from app state sync dispatch."
  @spec update_pinned(target(), String.t(), boolean()) :: :ok
  def update_pinned(target, jid, pinned) when is_boolean(pinned) do
    chat = get_or_create(target, jid)
    save_chat(target, %{chat | pinned: pinned})
  end

  @doc "Update muted state from app state sync dispatch."
  @spec update_muted(target(), String.t(), map()) :: :ok
  def update_muted(target, jid, mute_action) when is_map(mute_action) do
    chat = get_or_create(target, jid)
    muted = Map.get(mute_action, :muted, false)
    mute_end = Map.get(mute_action, :mute_end_timestamp)

    muted_until =
      cond do
        not muted -> nil
        is_integer(mute_end) and mute_end > 0 -> mute_end
        true -> -1
      end

    save_chat(target, %{chat | muted_until: muted_until})
  end

  @doc "Mark chat as read/unread from app state sync dispatch."
  @spec mark_read_from_sync(target(), String.t(), map()) :: :ok
  def mark_read_from_sync(target, jid, action_value) when is_map(action_value) do
    mark_read_action = Map.get(action_value, :mark_chat_as_read_action)
    read = is_map(mark_read_action) and Map.get(mark_read_action, :read, false)

    if read do
      mark_read(target, jid)
    else
      :ok
    end
  end

  @doc """
  Updates the chat name (for contacts that send push names).
  """
  @spec update_name(target(), String.t(), String.t()) :: :ok
  def update_name(target, jid, name) do
    update_chat(target, jid, fn chat -> %{chat | name: name} end)
  end

  @doc """
  Upserts metadata fields for a chat from sync/notification payloads.

  Supported keys:
  - `:name`
  - `:unread_count`
  - `:last_message_timestamp`
  - `:pinned`
  - `:muted_until`
  - `:archived`
  - `:is_group`
  """
  @spec merge_metadata(target(), String.t() | JID.t(), map() | keyword()) :: :ok
  def merge_metadata(target, jid, metadata) when is_list(metadata) do
    merge_metadata(target, jid, Map.new(metadata))
  end

  def merge_metadata(target, jid, metadata) when is_map(metadata) do
    jid_str = normalize_jid(jid)

    chat =
      case get(target, jid_str) do
        {:ok, existing_chat} ->
          existing_chat

        {:error, :not_found} ->
          name =
            case fetch_metadata(metadata, :name) do
              {:ok, value} when is_binary(value) and value != "" -> value
              _ -> nil
            end

          new_chat(jid_str, name: name)
      end

    updated_chat =
      chat
      |> maybe_update_name(metadata)
      |> maybe_update_non_neg_integer(:unread_count, metadata)
      |> maybe_update_non_neg_integer(:last_message_timestamp, metadata)
      |> maybe_update_boolean_field(:pinned, metadata)
      |> maybe_update_muted_until(metadata)
      |> maybe_update_boolean_field(:archived, metadata)
      |> maybe_update_boolean_field(:is_group, metadata)

    save_chat(target, updated_chat)
  end

  # ============================================================================
  # Message Parsing
  # ============================================================================

  @doc """
  Parses a received message node into a message struct.
  """
  @spec parse_message_node(Binary.Node.t()) :: {:ok, String.t(), message()} | {:error, term()}
  def parse_message_node(%Binary.Node{tag: "message", attrs: attrs, content: content}) do
    with {:ok, from} <- Map.fetch(attrs, "from"),
         {:ok, id} <- Map.fetch(attrs, "id"),
         {:ok, type} <- Map.fetch(attrs, "type") do
      # Normalize JID to string (may come as struct or string)
      jid = normalize_jid(from)
      timestamp = parse_timestamp(Map.get(attrs, "t", "0"))
      participant = Map.get(attrs, "participant")
      from_me = Map.get(attrs, "from_me") == "1"

      text = extract_text(content, type)

      message = %{
        id: id,
        from_me: from_me,
        timestamp: timestamp,
        text: text,
        status: :delivered,
        participant: participant,
        raw: %{type: type, attrs: attrs}
      }

      {:ok, jid, message}
    else
      :error -> {:error, :invalid_message_node}
    end
  end

  def parse_message_node(_), do: {:error, :not_a_message}

  defp extract_text(content, "text") when is_binary(content), do: content

  defp extract_text([%Binary.Node{tag: "enc", content: _enc_content}], _) do
    # Encrypted content - would need Signal decryption
    "(encrypted)"
  end

  defp extract_text(_, _), do: nil

  # ============================================================================
  # Internal Helpers
  # ============================================================================

  defp resolve_store(target) when is_pid(target), do: get_store(target)

  defp resolve_store(%{__struct__: mod} = store) when is_atom(mod) do
    if function_exported?(mod, :load, 1) and function_exported?(mod, :persist, 2) do
      store
    else
      nil
    end
  end

  defp resolve_store(_), do: nil

  defp get_store(session) do
    GenServer.call(session, :get_store)
  catch
    :exit, _ -> nil
  end

  # Normalize JID to string format
  defp normalize_jid(%JID{} = jid), do: normalize_jid(JID.to_string(jid))

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

  # Parse timestamp (may be string or integer)
  defp parse_timestamp(ts) when is_integer(ts), do: ts
  defp parse_timestamp(ts) when is_binary(ts), do: String.to_integer(ts)
  defp parse_timestamp(_), do: 0

  defp maybe_update_name(chat, metadata) do
    case fetch_metadata(metadata, :name) do
      {:ok, value} when is_binary(value) and value != "" ->
        %{chat | name: value}

      _ ->
        chat
    end
  end

  defp maybe_update_non_neg_integer(chat, field, metadata) do
    case fetch_metadata(metadata, field) do
      {:ok, value} when is_integer(value) and value >= 0 ->
        Map.put(chat, field, value)

      _ ->
        chat
    end
  end

  defp maybe_update_boolean_field(chat, field, metadata) do
    case fetch_metadata(metadata, field) do
      {:ok, value} when is_boolean(value) ->
        Map.put(chat, field, value)

      _ ->
        chat
    end
  end

  defp maybe_update_muted_until(chat, metadata) do
    case fetch_metadata(metadata, :muted_until) do
      {:ok, nil} ->
        %{chat | muted_until: nil}

      {:ok, value} when is_integer(value) and value > 0 ->
        %{chat | muted_until: value}

      {:ok, 0} ->
        %{chat | muted_until: nil}

      _ ->
        chat
    end
  end

  defp fetch_metadata(metadata, key) do
    key_str = Atom.to_string(key)

    cond do
      Map.has_key?(metadata, key) -> {:ok, Map.get(metadata, key)}
      Map.has_key?(metadata, key_str) -> {:ok, Map.get(metadata, key_str)}
      true -> :error
    end
  end

  defp normalize_merged_message(message) when is_map(message) do
    id =
      case Map.get(message, :id) do
        value when is_binary(value) ->
          value = String.trim(value)
          if value == "", do: nil, else: value

        _ ->
          nil
      end

    if is_binary(id) do
      %{
        id: id,
        from_me: Map.get(message, :from_me, false) == true,
        timestamp: normalized_timestamp(Map.get(message, :timestamp)),
        text: normalize_optional_text(Map.get(message, :text)),
        status:
          normalize_message_status(Map.get(message, :status), Map.get(message, :from_me, false)),
        participant: Map.get(message, :participant),
        raw: normalize_raw_payload(Map.get(message, :raw))
      }
    else
      nil
    end
  end

  defp normalize_merged_message(_), do: nil

  defp normalize_optional_text(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end

  defp normalize_optional_text(_), do: nil

  defp normalized_timestamp(value) when is_integer(value) and value >= 0, do: value
  defp normalized_timestamp(_), do: 0

  defp normalize_message_status(status, _from_me)
       when status in [:pending, :sent, :received, :delivered, :read, :failed] do
    status
  end

  defp normalize_message_status(_status, from_me) do
    if from_me == true, do: :sent, else: :received
  end

  defp normalize_raw_payload(value) when is_map(value), do: value
  defp normalize_raw_payload(_), do: nil

  defp message_identity(%{id: id}) when is_binary(id), do: {:id, id}

  defp message_identity(message),
    do: {:fallback, message_sort_key(message), Map.get(message, :text)}

  defp message_sort_key(%{timestamp: timestamp, id: id}) do
    {normalized_timestamp(timestamp), normalize_sort_id(id)}
  end

  defp message_sort_key(_), do: {0, ""}

  defp normalize_sort_id(value) when is_binary(value), do: value
  defp normalize_sort_id(_), do: ""

  defp latest_message_timestamp(messages) when is_list(messages) do
    Enum.find_value(messages, fn
      %{timestamp: timestamp} when is_integer(timestamp) and timestamp >= 0 -> timestamp
      _ -> nil
    end)
  end

  defp save_chat(target, chat) do
    store = resolve_store(target)

    if store do
      data = Store.load!(store)
      chats = Map.get(data, :chats, %{})
      updated_data = Map.put(data, :chats, Map.put(chats, chat.jid, chat))
      Store.persist(store, updated_data)
    end

    :ok
  end

  defp update_chat(target, jid, update_fn) do
    case get(target, jid) do
      {:ok, chat} ->
        save_chat(target, update_fn.(chat))

      {:error, _} ->
        :ok
    end
  end
end
