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
          required(:id) => String.t(),
          required(:from_me) => boolean(),
          required(:timestamp) => integer(),
          required(:text) => String.t() | nil,
          required(:status) => message_status(),
          required(:participant) => String.t() | JID.t() | nil,
          required(:raw) => map() | nil,
          optional(:content) => term(),
          optional(:media) => term(),
          optional(:location) => term(),
          optional(:contact) => term(),
          optional(:event) => term()
        }

  @type chat :: %__MODULE__{
          jid: String.t(),
          name: String.t() | nil,
          unread_count: non_neg_integer(),
          last_message_timestamp: integer() | nil,
          pinned: boolean(),
          muted_until: integer() | nil,
          archived: boolean(),
          is_group: boolean()
        }

  defstruct [
    :jid,
    :name,
    unread_count: 0,
    last_message_timestamp: nil,
    pinned: false,
    muted_until: nil,
    archived: false,
    is_group: false
  ]

  @doc """
  Lists all chats for a session.

  Returns a list of chat structs sorted by last message timestamp (most recent first).
  """
  @spec list(target()) :: [chat()]
  def list(target) do
    store = resolve_store(target)

    if store do
      store
      |> Store.get(:chats, %{})
      |> Map.values()
      |> Enum.map(&normalize_stored_chat(store, &1))
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
      case Store.get(store, :chats, %{}) |> Map.get(jid_str) do
        nil -> {:error, :not_found}
        chat -> {:ok, normalize_stored_chat(store, chat)}
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
      unread_count: 0
    }
  end

  @doc """
  Gets a materialized page of locally retained messages, newest first.

  Message payloads live in the configured message store rather than in the
  chat struct. Use stream_messages/3 for an unbounded, lazy traversal.
  """
  @spec messages(target(), String.t() | JID.t(), keyword()) :: [message()]
  def messages(target, jid, opts \\ []) do
    case resolve_store(target) do
      nil ->
        []

      store ->
        opts = opts |> Keyword.put_new(:order, :newest_first) |> Keyword.put_new(:limit, 50)
        Store.list_messages(store, normalize_jid(jid), opts)
    end
  end

  @doc """
  Builds a lazy stream over locally retained messages.

  The default order is oldest first so a wrapper can persist history in
  chronological order. The stream reads one indexed record at a time and does
  not first load the complete chat history.

  This is local history only; it does not request older messages from WhatsApp.
  """
  @spec stream_messages(target(), String.t() | JID.t(), keyword()) :: Enumerable.t()
  def stream_messages(target, jid, opts \\ []) do
    case resolve_store(target) do
      nil ->
        Stream.iterate(nil, fn _ -> nil end) |> Stream.take(0)

      store ->
        opts = opts |> Keyword.put_new(:order, :oldest_first) |> Keyword.put_new(:limit, :all)
        Store.stream_messages(store, normalize_jid(jid), opts)
    end
  end

  @doc """
  Returns a lazy stream over every locally retained message, oldest first.
  """
  @spec all_messages(target(), String.t() | JID.t(), keyword()) :: Enumerable.t()
  def all_messages(target, jid, opts \\ []), do: stream_messages(target, jid, opts)

  @doc """
  Merges a batch of messages into a chat, deduplicating by message ID.
  """
  @spec merge_messages(target(), String.t() | JID.t(), [message()]) ::
          :ok | {:error, term()}
  def merge_messages(target, jid, messages) when is_list(messages) do
    jid_str = normalize_jid(jid)
    store = resolve_store(target)
    normalized_messages = normalize_merged_messages(messages)

    case store do
      nil ->
        :ok

      store ->
        save_chat_with_messages(
          store,
          jid_str,
          normalized_messages,
          &update_last_message_timestamp(&1, normalized_messages)
        )
    end
  end

  def merge_messages(_target, _jid, _messages), do: :ok

  @doc """
  Adds a message to a chat.
  """
  @spec add_message(target(), String.t() | JID.t(), message()) ::
          :ok | {:error, term()}
  def add_message(target, jid, message) do
    jid_str = normalize_jid(jid)
    store = resolve_store(target)

    case store do
      nil ->
        :ok

      store ->
        save_chat_with_messages(store, jid_str, [message], fn chat ->
          %{
            chat
            | last_message_timestamp: message.timestamp,
              unread_count:
                if(message.from_me, do: chat.unread_count, else: chat.unread_count + 1)
          }
        end)
    end
  end

  @doc """
  Marks all messages in a chat as read.
  """
  @spec mark_read(target(), String.t() | JID.t()) :: :ok
  def mark_read(target, jid) do
    update_chat(target, jid, &%{&1 | unread_count: 0})
  end

  @doc """
  Updates a message status.
  """
  @spec update_message_status(target(), String.t() | JID.t(), String.t(), message_status()) ::
          :ok | {:error, term()}
  def update_message_status(target, jid, message_id, status) do
    case resolve_store(target) do
      nil -> :ok
      store -> Store.update_message_status(store, normalize_jid(jid), message_id, status)
    end
  end

  @doc """
  Updates a message status by message ID across all chats.

  Useful for ACK nodes that do not provide a chat JID we can trust.
  """
  @spec update_message_status_by_id(target(), String.t(), message_status()) ::
          :ok | {:error, term()}
  def update_message_status_by_id(target, message_id, status) when is_binary(message_id) do
    case resolve_store(target) do
      nil -> :ok
      store -> Store.update_message_status_by_id(store, message_id, status)
    end
  end

  @doc "Finds one locally stored message in a chat."
  @spec find_message(target(), String.t() | JID.t(), String.t()) :: message() | nil
  def find_message(target, jid, message_id) do
    case resolve_store(target) do
      nil -> nil
      store -> Store.find_message(store, normalize_jid(jid), message_id)
    end
  end

  @doc "Finds one locally stored message by ID across all chats."
  @spec find_message_by_id(target(), String.t()) :: {String.t(), message()} | nil
  def find_message_by_id(target, message_id) do
    case resolve_store(target) do
      nil -> nil
      store -> Store.find_message_by_id(store, message_id)
    end
  end

  @doc """
  Deletes selected local messages after they have been persisted elsewhere.
  """
  @spec delete_messages(target(), String.t() | JID.t(), [String.t()]) ::
          :ok | {:error, term()}
  def delete_messages(target, jid, message_ids) when is_list(message_ids) do
    case resolve_store(target) do
      nil -> :ok
      store -> Store.delete_messages(store, normalize_jid(jid), message_ids)
    end
  end

  @doc """
  Deletes a chat.
  """
  @spec delete(target(), String.t()) :: :ok | {:error, term()}
  def delete(target, jid) do
    store = resolve_store(target)
    jid_str = normalize_jid(jid)

    if store, do: delete_from_store(store, jid_str), else: :ok
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
    upsert_chat(target, jid, &%{&1 | archived: archived})
  end

  @doc "Update pinned state from app state sync dispatch."
  @spec update_pinned(target(), String.t(), boolean()) :: :ok
  def update_pinned(target, jid, pinned) when is_boolean(pinned) do
    upsert_chat(target, jid, &%{&1 | pinned: pinned})
  end

  @doc "Update muted state from app state sync dispatch."
  @spec update_muted(target(), String.t(), map()) :: :ok
  def update_muted(target, jid, mute_action) when is_map(mute_action) do
    muted = Map.get(mute_action, :muted, false)
    mute_end = Map.get(mute_action, :mute_end_timestamp)

    muted_until =
      cond do
        not muted -> nil
        is_integer(mute_end) and mute_end > 0 -> mute_end
        true -> -1
      end

    upsert_chat(target, jid, &%{&1 | muted_until: muted_until})
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

    upsert_chat(target, jid_str, fn chat ->
      chat
      |> maybe_update_name(metadata)
      |> maybe_update_non_neg_integer(:unread_count, metadata)
      |> maybe_update_non_neg_integer(:last_message_timestamp, metadata)
      |> maybe_update_boolean_field(:pinned, metadata)
      |> maybe_update_muted_until(metadata)
      |> maybe_update_boolean_field(:archived, metadata)
      |> maybe_update_boolean_field(:is_group, metadata)
    end)
  end

  # Message parsing

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

  # Store and lookup helpers

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
      normalized = %{
        id: id,
        from_me: Map.get(message, :from_me, false) == true,
        timestamp: normalized_timestamp(Map.get(message, :timestamp)),
        text: normalize_optional_text(Map.get(message, :text)),
        status:
          normalize_message_status(Map.get(message, :status), Map.get(message, :from_me, false)),
        participant: Map.get(message, :participant),
        raw: normalize_raw_payload(Map.get(message, :raw))
      }

      message
      |> Map.take([:content, :media, :location, :contact, :event])
      |> Map.merge(normalized)
    else
      nil
    end
  end

  defp normalize_merged_message(_), do: nil

  defp normalize_merged_messages(messages) do
    messages
    |> Enum.reduce([], fn message, acc ->
      case normalize_merged_message(message) do
        nil -> acc
        normalized -> [normalized | acc]
      end
    end)
    |> Enum.reverse()
  end

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

  defp latest_message_timestamp(messages) when is_list(messages) do
    Enum.reduce(messages, nil, fn
      %{timestamp: timestamp}, nil when is_integer(timestamp) and timestamp >= 0 ->
        timestamp

      %{timestamp: timestamp}, current when is_integer(timestamp) and timestamp >= 0 ->
        max(current, timestamp)

      _message, current ->
        current
    end)
  end

  defp update_last_message_timestamp(chat, messages) do
    case latest_message_timestamp(messages) do
      nil ->
        chat

      latest ->
        current =
          if(is_integer(chat.last_message_timestamp), do: chat.last_message_timestamp, else: 0)

        %{chat | last_message_timestamp: max(current, latest)}
    end
  end

  defp save_chat(target, chat) do
    case resolve_store(target) do
      nil -> :ok
      store -> save_chat_to_store(store, strip_legacy_messages(chat))
    end
  end

  defp delete_from_store(store, jid) do
    Store.batch(store, {:delete_chat, jid}, fn ->
      with :ok <- Store.delete_chat_messages(store, jid) do
        Store.update(store, :chats, %{}, &Map.delete(&1, jid))
      end
    end)
  end

  defp save_chat_with_messages(store, jid, messages, updater)
       when is_function(updater, 1) do
    Store.batch(store, {:chat_with_messages, jid}, fn ->
      with :ok <- Store.upsert_messages(store, jid, messages) do
        update_stored_chat(store, jid, updater, true)
      end
    end)
  end

  defp save_chat_to_store(store, chat) do
    Store.update(store, :chats, %{}, fn chats ->
      Map.put(chats, chat.jid, strip_legacy_messages(chat))
    end)
  end

  defp normalize_stored_chat(store, chat) when is_map(chat) do
    legacy_messages = Map.get(chat, :messages, [])
    clean_chat = strip_legacy_messages(chat)

    if is_list(legacy_messages) and legacy_messages != [] do
      normalized_messages = normalize_merged_messages(legacy_messages)

      :ok = Store.upsert_messages(store, clean_chat.jid, normalized_messages)
      :ok = save_chat_to_store(store, clean_chat)
    end

    clean_chat
  end

  defp strip_legacy_messages(%{__struct__: __MODULE__} = chat) do
    attrs =
      chat
      |> Map.delete(:__struct__)
      |> Map.delete(:messages)

    struct(__MODULE__, attrs)
  end

  defp strip_legacy_messages(chat) when is_map(chat), do: Map.delete(chat, :messages)

  defp update_chat(target, jid, update_fn) do
    case resolve_store(target) do
      nil -> :ok
      store -> update_stored_chat(store, normalize_jid(jid), update_fn, false)
    end
  end

  defp upsert_chat(target, jid, update_fn) do
    case resolve_store(target) do
      nil -> :ok
      store -> update_stored_chat(store, normalize_jid(jid), update_fn, true)
    end
  end

  defp update_stored_chat(store, jid, update_fn, create?) do
    Store.update(store, :chats, %{}, fn chats ->
      case Map.get(chats, jid) do
        nil when create? ->
          Map.put(chats, jid, update_fn.(new_chat(jid)))

        nil ->
          chats

        chat ->
          chat = coerce_chat(chat, jid)
          Map.put(chats, jid, update_fn.(chat))
      end
    end)
  end

  defp coerce_chat(%__MODULE__{} = chat, _jid), do: strip_legacy_messages(chat)

  defp coerce_chat(chat, jid) when is_map(chat) do
    fields = Map.take(chat, Map.keys(Map.from_struct(%__MODULE__{})))
    struct(__MODULE__, Map.put_new(fields, :jid, jid))
  end

  defp coerce_chat(_chat, jid), do: new_chat(jid)
end
