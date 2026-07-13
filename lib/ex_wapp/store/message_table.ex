defmodule ExWapp.Store.MessageTable do
  @moduledoc """
  Indexed message storage used by the built-in store adapters.

  Chat metadata and message payloads deliberately live in different tables.
  A chat can therefore be listed or updated without copying its whole history
  onto the caller process heap. Message streams walk the ordered ETS table one
  record at a time and only materialize a list when a caller explicitly asks
  for a paginated list or a complete snapshot.

  Custom ExWapp.Store adapters do not need to use this module. They can
  implement the message callbacks directly with a database cursor.
  """

  @max_timestamp 18_446_744_073_709_551_615

  defstruct [:table, :index_table]

  @type order :: :newest_first | :oldest_first
  @type t :: %__MODULE__{table: :ets.tid(), index_table: :ets.tid()}

  @doc """
  Creates an empty message table and imports optional initial messages.

  Initial data is a map keyed by chat JID. Duplicate message IDs are replaced
  by the last value imported.
  """
  @spec new(map()) :: t()
  def new(initial_messages \\ %{}) do
    message_store = %__MODULE__{
      table: :ets.new(:ex_wapp_messages, [:ordered_set, :public, :compressed]),
      index_table: :ets.new(:ex_wapp_message_index, [:set, :public, :compressed])
    }

    Enum.each(normalize_initial_messages(initial_messages), fn {jid, messages} ->
      upsert(message_store, jid, messages)
    end)

    message_store
  end

  @doc """
  Separates message payloads from persisted chat metadata.

  It understands both the current top-level :chat_messages snapshot and the
  legacy %ExWapp.Chat{messages: [...]} representation. The returned data no
  longer contains either representation.
  """
  @spec extract(map()) :: {map(), map()}
  def extract(data) when is_map(data) do
    persisted_messages = normalize_initial_messages(Map.get(data, :chat_messages, %{}))
    chats = Map.get(data, :chats, %{})

    {clean_chats, legacy_messages} =
      Enum.reduce(chats, {%{}, %{}}, fn {jid, chat}, {chat_acc, message_acc} ->
        messages = if is_map(chat), do: Map.get(chat, :messages, []), else: []
        clean_chat = strip_legacy_messages(chat)

        {
          Map.put(chat_acc, jid, clean_chat),
          maybe_put_initial_messages(message_acc, jid, messages)
        }
      end)

    clean_data = Map.delete(data, :chat_messages)

    clean_data =
      if Map.has_key?(data, :chats) do
        Map.put(clean_data, :chats, clean_chats)
      else
        clean_data
      end

    {clean_data, Map.merge(persisted_messages, legacy_messages, &merge_message_lists/3)}
  end

  @doc """
  Inserts or replaces messages for a chat by message ID.
  """
  @spec upsert(t(), String.t(), [map()]) :: :ok
  def upsert(%__MODULE__{} = message_store, jid, messages)
      when is_binary(jid) and is_list(messages) do
    Enum.each(messages, &upsert_one(message_store, jid, &1))
    :ok
  end

  def upsert(%__MODULE__{}, _jid, _messages), do: :ok

  @doc """
  Returns a lazy stream over messages for one chat.

  The table is not read until the stream is enumerated. Supported options are
  :order, :offset, and :limit. The default stream is newest first and
  unbounded.
  """
  @spec stream(t(), String.t(), keyword()) :: Enumerable.t()
  def stream(%__MODULE__{} = message_store, jid, opts \\ []) when is_binary(jid) do
    order = normalize_order(Keyword.get(opts, :order, :newest_first))
    offset = normalize_offset(Keyword.get(opts, :offset, 0))
    limit = normalize_limit(Keyword.get(opts, :limit, :all))

    message_store
    |> resource_stream(jid, order, offset, limit)
    |> Stream.map(& &1)
  end

  defp resource_stream(message_store, jid, order, offset, limit) do
    Stream.resource(
      fn -> %{cursor: nil, skip: offset, remaining: limit} end,
      &next_stream_item(message_store, jid, order, &1),
      fn _state -> :ok end
    )
  end

  @doc """
  Materializes a requested message page.
  """
  @spec list(t(), String.t(), keyword()) :: [map()]
  def list(%__MODULE__{} = message_store, jid, opts \\ []) do
    opts = Keyword.put_new(opts, :limit, 50)
    message_store |> stream(jid, opts) |> Enum.to_list()
  end

  @doc """
  Finds a message by chat JID and message ID.
  """
  @spec find(t(), String.t(), String.t()) :: map() | nil
  def find(%__MODULE__{} = message_store, jid, message_id)
      when is_binary(jid) and is_binary(message_id) do
    with [{{^jid, ^message_id}, key}] <-
           :ets.lookup(message_store.index_table, {jid, message_id}),
         [{^key, message}] <- :ets.lookup(message_store.table, key) do
      message
    else
      _ -> nil
    end
  end

  def find(%__MODULE__{}, _jid, _message_id), do: nil

  @doc """
  Finds the first message with an ID across all chats.
  """
  @spec find_by_id(t(), String.t()) :: {String.t(), map()} | nil
  def find_by_id(%__MODULE__{} = message_store, message_id) when is_binary(message_id) do
    message_store.index_table
    |> :ets.select([{{{:"$1", message_id}, :"$2"}, [], [:"$_"]}])
    |> Enum.find_value(fn {{jid, ^message_id}, key} ->
      case :ets.lookup(message_store.table, key) do
        [{^key, message}] -> {jid, message}
        _ -> nil
      end
    end)
  end

  def find_by_id(%__MODULE__{}, _message_id), do: nil

  @doc """
  Updates the status of one stored message.
  """
  @spec update_status(t(), String.t(), String.t(), atom()) :: :ok
  def update_status(%__MODULE__{} = message_store, jid, message_id, status) do
    case find(message_store, jid, message_id) do
      nil -> :ok
      message -> upsert(message_store, jid, [Map.put(message, :status, status)])
    end
  end

  @doc """
  Updates every stored message matching an ID.
  """
  @spec update_status_by_id(t(), String.t(), atom()) :: :ok
  def update_status_by_id(%__MODULE__{} = message_store, message_id, status)
      when is_binary(message_id) do
    message_store.index_table
    |> :ets.select([{{{:"$1", message_id}, :"$2"}, [], [:"$_"]}])
    |> Enum.each(fn {{jid, ^message_id}, key} ->
      case :ets.lookup(message_store.table, key) do
        [{^key, message}] -> upsert(message_store, jid, [Map.put(message, :status, status)])
        _ -> :ok
      end
    end)

    :ok
  end

  def update_status_by_id(%__MODULE__{}, _message_id, _status), do: :ok

  @doc """
  Deletes selected messages after an application has durably persisted them.
  """
  @spec delete(t(), String.t(), [String.t()]) :: :ok
  def delete(%__MODULE__{} = message_store, jid, message_ids)
      when is_binary(jid) and is_list(message_ids) do
    Enum.each(message_ids, fn message_id ->
      case :ets.take(message_store.index_table, {jid, message_id}) do
        [{{^jid, ^message_id}, key}] -> :ets.delete(message_store.table, key)
        _ -> :ok
      end
    end)

    :ok
  end

  def delete(%__MODULE__{}, _jid, _message_ids), do: :ok

  @doc """
  Deletes all messages for one chat.
  """
  @spec delete_chat(t(), String.t()) :: :ok
  def delete_chat(%__MODULE__{} = message_store, jid) when is_binary(jid) do
    message_store.index_table
    |> :ets.select([{{{jid, :"$1"}, :"$2"}, [], [:"$_"]}])
    |> Enum.each(fn {{^jid, message_id}, key} ->
      :ets.delete(message_store.index_table, {jid, message_id})
      :ets.delete(message_store.table, key)
    end)

    :ok
  end

  def delete_chat(%__MODULE__{}, _jid), do: :ok

  @doc """
  Returns a complete, newest-first snapshot grouped by chat JID.

  This intentionally materializes all messages and is reserved for explicit
  backup/export operations.
  """
  @spec snapshot(t()) :: %{optional(String.t()) => [map()]}
  def snapshot(%__MODULE__{} = message_store) do
    :ets.foldl(
      fn {{jid, _timestamp, _id}, message}, acc ->
        Map.update(acc, jid, [message], &[message | &1])
      end,
      %{},
      message_store.table
    )
  end

  @doc """
  Removes all indexed messages.
  """
  @spec clear(t()) :: :ok
  def clear(%__MODULE__{} = message_store) do
    :ets.delete_all_objects(message_store.table)
    :ets.delete_all_objects(message_store.index_table)
    :ok
  end

  defp upsert_one(message_store, jid, message) when is_map(message) do
    case Map.get(message, :id) do
      message_id when is_binary(message_id) and message_id != "" ->
        delete_previous_key(message_store, jid, message_id)

        timestamp = normalize_timestamp(Map.get(message, :timestamp))
        key = {jid, timestamp, message_id}
        normalized_message = Map.put(message, :timestamp, timestamp)

        :ets.insert(message_store.table, {key, normalized_message})
        :ets.insert(message_store.index_table, {{jid, message_id}, key})

      _ ->
        :ok
    end
  end

  defp upsert_one(_message_store, _jid, _message), do: :ok

  defp delete_previous_key(message_store, jid, message_id) do
    case :ets.lookup(message_store.index_table, {jid, message_id}) do
      [{{^jid, ^message_id}, old_key}] -> :ets.delete(message_store.table, old_key)
      _ -> :ok
    end
  end

  defp next_stream_item(_message_store, _jid, _order, %{remaining: 0} = state),
    do: {:halt, state}

  defp next_stream_item(message_store, jid, order, state) do
    key = next_key(message_store.table, jid, order, state.cursor)

    case key do
      {^jid, _timestamp, _id} ->
        case :ets.lookup(message_store.table, key) do
          [{^key, _message}] when state.skip > 0 ->
            next_stream_item(message_store, jid, order, %{
              state
              | cursor: key,
                skip: state.skip - 1
            })

          [{^key, message}] ->
            {[message], %{state | cursor: key, remaining: decrement_remaining(state.remaining)}}

          _ ->
            next_stream_item(message_store, jid, order, %{state | cursor: key})
        end

      _ ->
        {:halt, state}
    end
  rescue
    ArgumentError -> {:halt, state}
  end

  defp next_key(table, jid, :oldest_first, nil), do: :ets.next(table, {jid, -1, ""})

  defp next_key(table, jid, :newest_first, nil),
    do: :ets.prev(table, {jid, @max_timestamp + 1, ""})

  defp next_key(table, _jid, :oldest_first, cursor), do: :ets.next(table, cursor)
  defp next_key(table, _jid, :newest_first, cursor), do: :ets.prev(table, cursor)

  defp decrement_remaining(:all), do: :all
  defp decrement_remaining(remaining), do: remaining - 1

  defp normalize_order(:oldest_first), do: :oldest_first
  defp normalize_order(_), do: :newest_first

  defp normalize_offset(offset) when is_integer(offset) and offset >= 0, do: offset
  defp normalize_offset(_), do: 0

  defp normalize_limit(:all), do: :all
  defp normalize_limit(limit) when is_integer(limit) and limit >= 0, do: limit
  defp normalize_limit(_), do: :all

  defp normalize_timestamp(timestamp)
       when is_integer(timestamp) and timestamp >= 0 and timestamp <= @max_timestamp,
       do: timestamp

  defp normalize_timestamp(timestamp) when is_integer(timestamp) and timestamp > @max_timestamp,
    do: @max_timestamp

  defp normalize_timestamp(_), do: 0

  defp normalize_initial_messages(messages) when is_map(messages) do
    Enum.reduce(messages, %{}, fn
      {jid, values}, acc when is_binary(jid) and is_list(values) -> Map.put(acc, jid, values)
      _, acc -> acc
    end)
  end

  defp normalize_initial_messages(_), do: %{}

  defp maybe_put_initial_messages(acc, jid, messages)
       when is_binary(jid) and is_list(messages) and messages != [],
       do: Map.put(acc, jid, messages)

  defp maybe_put_initial_messages(acc, _jid, _messages), do: acc

  defp merge_message_lists(_jid, left, right), do: left ++ right

  defp strip_legacy_messages(%{__struct__: ExWapp.Chat} = chat) do
    attrs =
      chat
      |> Map.delete(:__struct__)
      |> Map.delete(:messages)

    struct(ExWapp.Chat, attrs)
  end

  defp strip_legacy_messages(chat) when is_map(chat), do: Map.delete(chat, :messages)
  defp strip_legacy_messages(chat), do: chat
end
