defmodule ExWapp.Store.Ets do
  @moduledoc """
  ETS-backed store with file persistence.

  This is the default store adapter. It keeps data in an ETS table for fast
  access and persists to a file on disk using the versioned ExWapp store codec.
  Legacy ETF-backed files are migrated on first load.

  ## Options

    * `:path` - File path for persistence. Defaults to `~/.cache/ex_wapp/session.etf`

  ## Examples

      # Use with default path
      store = ExWapp.Store.Ets.new()

      # Use with custom path
      store = ExWapp.Store.Ets.new(path: "/var/lib/myapp/wa_session.etf")

      # Store and retrieve data
      :ok = ExWapp.Store.persist(store, %{user: "Alice"})
      {:ok, %{user: "Alice"}} = ExWapp.Store.load(store)

  ## Implementation Notes

  - A linked writer process owns the ETS tables and serializes mutations
  - Top-level domains, Signal sessions, device cache, and messages are stored
    separately so an update does not copy or replace unrelated state
  - Caller-owned batches coalesce sync mutations into one durable snapshot
  - Message streams traverse the ordered message table lazily by JID and cursor
  - Snapshot encoding runs in a short-lived process to release its large heap
    immediately after compression and I/O
  - File is loaded on `new/1` if it exists
  """

  @behaviour ExWapp.Store
  require Logger
  alias ExWapp.Log
  alias ExWapp.Signal.SessionStore
  alias ExWapp.Store.Codec
  alias ExWapp.Store.Ets.Writer
  alias ExWapp.Store.MessageTable
  alias ExWapp.Telemetry

  defstruct [:path, :table, :signal_table, :device_cache_table, :message_table, :writer]

  @type t :: %__MODULE__{
          path: Path.t(),
          table: :ets.tid(),
          signal_table: :ets.tid(),
          device_cache_table: :ets.tid(),
          message_table: MessageTable.t(),
          writer: pid() | nil
        }

  @default_path_segments [".cache", "ex_wapp", "session.etf"]
  @impl true
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    path =
      opts
      |> Keyword.get(:path, default_path())
      |> Path.expand()

    :ok = path |> String.to_charlist() |> :filelib.ensure_dir()

    table =
      :ets.new(:ex_wapp_store, [
        :set,
        :public,
        :compressed,
        read_concurrency: true
      ])

    signal_store = SessionStore.new_ets()
    signal_table = signal_store.table

    device_cache_table =
      :ets.new(:ex_wapp_device_cache, [
        :set,
        :public,
        :compressed,
        read_concurrency: true
      ])

    {base_data, signal_sessions, device_cache, initial_messages} =
      case load_file(path) do
        {:ok, data} ->
          split_specialized_data(data)

        {:error, :enoent} ->
          {%{}, SessionStore.new(), %{}, %{}}

        {:error, reason} ->
          raise "ExWapp.Store.Ets failed to load #{path}: #{inspect(reason)}"
      end

    put_base_data(table, base_data)
    SessionStore.replace(signal_store, signal_sessions)
    :ets.insert(device_cache_table, {:snapshot, normalize_device_cache(device_cache)})

    store_without_writer = %__MODULE__{
      path: path,
      table: table,
      signal_table: signal_table,
      device_cache_table: device_cache_table,
      message_table:
        MessageTable.new(initial_messages,
          max_per_chat: Keyword.get(opts, :max_messages_per_chat, :default)
        ),
      writer: nil
    }

    {:ok, writer} = Writer.start_link(store_without_writer)
    transfer_tables(store_without_writer, writer)
    %{store_without_writer | writer: writer}
  end

  @doc """
  Loads store data directly from a persisted file path.

  This is useful for one-off reads, such as pairing handoff flows, where
  creating a full ETS-backed store instance would hide missing-file errors by
  defaulting to an empty map.
  """
  @spec load_path(Path.t()) :: {:ok, ExWapp.Store.data()} | {:error, term()}
  def load_path(path) when is_binary(path) do
    path
    |> Path.expand()
    |> load_file()
  end

  @impl true
  @spec load(t()) :: {:ok, ExWapp.Store.data()} | {:error, term()}
  def load(%__MODULE__{
        table: table,
        signal_table: signal_table,
        device_cache_table: device_cache_table
      }) do
    {:ok,
     table
     |> base_snapshot()
     |> Map.put(:signal_sessions, SessionStore.snapshot(SessionStore.attach(signal_table)))
     |> Map.put(:device_cache, load_device_cache_snapshot(device_cache_table))}
  rescue
    ArgumentError -> {:error, :store_closed}
  end

  @impl true
  @spec persist(t(), ExWapp.Store.data()) :: :ok | {:error, term()}
  def persist(%__MODULE__{} = store, data) when is_map(data) do
    Writer.mutate(store.writer, fn -> apply_full_persist(store, data) end)
  end

  @impl true
  @spec clear(t()) :: :ok | {:error, term()}
  def clear(%__MODULE__{} = store) do
    Writer.clear(store.writer, fn ->
      :ets.delete_all_objects(store.table)
      :ets.delete_all_objects(store.signal_table)
      :ets.insert(store.device_cache_table, {:snapshot, %{}})
      MessageTable.clear(store.message_table)

      case File.rm(store.path) do
        :ok -> :ok
        {:error, :enoent} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  @spec get(t(), atom(), term()) :: term()
  def get(%__MODULE__{} = store, key, default \\ nil)
      when is_atom(key) do
    case key do
      :signal_sessions ->
        load_signal_sessions(store)

      :device_cache ->
        load_device_cache(store)

      _ ->
        case :ets.lookup(store.table, key) do
          [{^key, value}] -> value
          [] -> default
        end
    end
  rescue
    ArgumentError -> default
  end

  @impl true
  @spec stream_messages(t(), String.t(), keyword()) :: Enumerable.t()
  def stream_messages(%__MODULE__{message_table: message_table}, jid, opts) do
    MessageTable.stream(message_table, jid, opts)
  end

  @impl true
  @spec upsert_messages(t(), String.t(), [map()]) :: :ok | {:error, term()}
  def upsert_messages(%__MODULE__{} = store, jid, messages) do
    Writer.mutate(store.writer, fn ->
      changed = MessageTable.upsert_count(store.message_table, jid, messages)
      {:ok, changed_status(changed)}
    end)
  end

  @impl true
  @spec find_message(t(), String.t(), String.t()) :: map() | nil
  def find_message(%__MODULE__{message_table: message_table}, jid, message_id) do
    MessageTable.find(message_table, jid, message_id)
  end

  @impl true
  @spec find_message_by_id(t(), String.t()) :: {String.t(), map()} | nil
  def find_message_by_id(%__MODULE__{message_table: message_table}, message_id) do
    MessageTable.find_by_id(message_table, message_id)
  end

  @impl true
  @spec update_message_status(t(), String.t(), String.t(), atom()) ::
          :ok | {:error, term()}
  def update_message_status(%__MODULE__{} = store, jid, message_id, status) do
    Writer.mutate(store.writer, fn ->
      changed = MessageTable.update_status_count(store.message_table, jid, message_id, status)
      {:ok, changed_status(changed)}
    end)
  end

  @impl true
  @spec update_message_status_by_id(t(), String.t(), atom()) ::
          :ok | {:error, term()}
  def update_message_status_by_id(%__MODULE__{} = store, message_id, status) do
    Writer.mutate(store.writer, fn ->
      changed = MessageTable.update_status_by_id_count(store.message_table, message_id, status)
      {:ok, changed_status(changed)}
    end)
  end

  @impl true
  @spec delete_messages(t(), String.t(), [String.t()]) :: :ok | {:error, term()}
  def delete_messages(%__MODULE__{} = store, jid, message_ids) do
    Writer.mutate(store.writer, fn ->
      deleted = MessageTable.delete_count(store.message_table, jid, message_ids)
      {:ok, changed_status(deleted)}
    end)
  end

  @impl true
  @spec delete_chat_messages(t(), String.t()) :: :ok | {:error, term()}
  def delete_chat_messages(%__MODULE__{} = store, jid) do
    Writer.mutate(store.writer, fn ->
      deleted = MessageTable.delete_chat_count(store.message_table, jid)
      {:ok, changed_status(deleted)}
    end)
  end

  @impl true
  @spec snapshot_messages(t()) :: %{optional(String.t()) => [map()]}
  def snapshot_messages(%__MODULE__{message_table: message_table}) do
    MessageTable.snapshot(message_table)
  end

  @spec load_signal_sessions(t()) :: SessionStore.t()
  def load_signal_sessions(%__MODULE__{signal_table: signal_table}) do
    SessionStore.attach(signal_table)
  end

  @spec persist_signal_sessions(t(), term()) :: :ok | {:error, term()}
  def persist_signal_sessions(%__MODULE__{} = store, sessions) do
    Writer.mutate(store.writer, fn ->
      :ok = maybe_replace_signal_sessions(store.signal_table, sessions)
      {:ok, :changed}
    end)
  end

  @spec load_device_cache(t()) :: map()
  def load_device_cache(%__MODULE__{device_cache_table: device_cache_table}) do
    load_device_cache_snapshot(device_cache_table)
  end

  @spec persist_device_cache(t(), map()) :: :ok | {:error, term()}
  def persist_device_cache(%__MODULE__{} = store, cache) when is_map(cache) do
    Writer.mutate(store.writer, fn ->
      :ok = put_device_cache(store.device_cache_table, cache)
      {:ok, :changed}
    end)
  end

  @doc false
  @impl true
  @spec read(t(), (map() -> term())) :: term()
  def read(%__MODULE__{} = store, reader) when is_function(reader, 1) do
    Writer.read(store.writer, fn -> reader.(base_snapshot(store.table)) end)
  end

  @doc false
  @impl true
  @spec update(t(), atom(), term(), (term() -> term())) :: :ok | {:error, term()}
  def update(%__MODULE__{} = store, key, default, updater)
      when is_atom(key) and is_function(updater, 1) do
    Writer.mutate(store.writer, fn ->
      current = base_get(store.table, key, default)
      updated = updater.(current)

      if updated === current do
        {:ok, :unchanged}
      else
        :ets.insert(store.table, {key, updated})
        {:ok, :changed}
      end
    end)
  end

  @doc false
  @impl true
  @spec get_and_update(t(), atom(), term(), (term() -> {term(), term()})) ::
          term() | {:error, term()}
  def get_and_update(%__MODULE__{} = store, key, default, updater)
      when is_atom(key) and is_function(updater, 1) do
    Writer.mutate(store.writer, fn ->
      current = base_get(store.table, key, default)
      apply_get_and_update(store.table, key, current, updater.(current))
    end)
  end

  @doc false
  @impl true
  @spec transaction(t(), (map() -> map())) :: :ok | {:error, term()}
  def transaction(%__MODULE__{} = store, updater) when is_function(updater, 1) do
    Writer.mutate(store.writer, fn ->
      current = base_snapshot(store.table)
      apply_transaction(store.table, current, updater.(current))
    end)
  end

  @doc false
  @impl true
  @spec begin_batch(t(), term()) :: :ok
  def begin_batch(%__MODULE__{writer: writer}, reason), do: Writer.begin_batch(writer, reason)

  @doc false
  @impl true
  @spec finish_batch(t(), term()) :: :ok | {:error, term()}
  def finish_batch(%__MODULE__{writer: writer}, reason), do: Writer.finish_batch(writer, reason)

  @impl true
  @spec flush(t()) :: :ok | {:error, term()}
  def flush(%__MODULE__{writer: writer}), do: Writer.flush(writer)

  @impl true
  @spec close(t()) :: :ok | {:error, term()}
  def close(%__MODULE__{writer: writer}), do: Writer.stop(writer)

  defp default_path do
    Path.join([System.user_home!() | @default_path_segments])
  end

  defp split_specialized_data(data) when is_map(data) do
    {base_data, messages} = MessageTable.extract(data)

    {
      Map.drop(base_data, [:signal_sessions, :device_cache]),
      SessionStore.snapshot(Map.get(data, :signal_sessions, SessionStore.new())),
      normalize_device_cache(Map.get(data, :device_cache, %{})),
      messages
    }
  end

  defp apply_full_persist(%__MODULE__{} = store, data) do
    {base_data, signal_sessions, device_cache, messages} = split_specialized_data(data)
    current_base = base_snapshot(store.table)

    replace_base_data(store.table, current_base, base_data)

    if Map.has_key?(data, :signal_sessions) and :ets.info(store.signal_table, :size) == 0 do
      put_signal_sessions(store.signal_table, signal_sessions)
    end

    if Map.has_key?(data, :device_cache) and
         map_size(load_device_cache_snapshot(store.device_cache_table)) == 0 do
      put_device_cache(store.device_cache_table, device_cache)
    end

    put_initial_messages(store.message_table, messages)
    {:ok, :changed}
  end

  defp merged_snapshot(%__MODULE__{
         table: table,
         signal_table: signal_table,
         device_cache_table: device_cache_table,
         message_table: message_table
       }) do
    table
    |> base_snapshot()
    |> Map.put(:signal_sessions, SessionStore.snapshot(SessionStore.attach(signal_table)))
    |> Map.put(:device_cache, load_device_cache_snapshot(device_cache_table))
    |> put_message_snapshot(MessageTable.snapshot(message_table))
  end

  @doc false
  @spec flush_snapshot(t()) :: :ok | {:error, term()}
  def flush_snapshot(%__MODULE__{} = store) do
    started_at = System.monotonic_time()
    encode_started_at = System.monotonic_time()
    encoded = Codec.encode(merged_snapshot(store))
    encode_duration = System.monotonic_time() - encode_started_at

    {result, bytes, write_duration} =
      case encoded do
        {:ok, blob} ->
          write_started_at = System.monotonic_time()
          result = atomic_write(store.path, blob)
          {result, byte_size(blob), System.monotonic_time() - write_started_at}

        {:error, _reason} = error ->
          {error, 0, 0}
      end

    duration = System.monotonic_time() - started_at

    Telemetry.execute(
      [:ex_wapp, :store, :flush],
      %{
        duration: duration,
        encode_duration: encode_duration,
        write_duration: write_duration,
        bytes: bytes
      },
      %{adapter: __MODULE__, result: telemetry_result(result)}
    )

    Logger.debug(
      "[STORE] snapshot flush result=#{telemetry_result(result)} bytes=#{bytes} encode_ms=#{native_ms(encode_duration)} write_ms=#{native_ms(write_duration)} duration_ms=#{native_ms(duration)}"
    )

    result
  rescue
    exception -> {:error, {:snapshot_flush_failed, exception}}
  catch
    kind, reason -> {:error, {:snapshot_flush_failed, {kind, reason}}}
  end

  defp put_initial_messages(message_table, messages) when is_map(messages) do
    Enum.each(messages, fn {jid, chat_messages} ->
      MessageTable.upsert(message_table, jid, chat_messages)
    end)

    :ok
  end

  defp put_message_snapshot(data, messages) when map_size(messages) == 0,
    do: Map.delete(data, :chat_messages)

  defp put_message_snapshot(data, messages), do: Map.put(data, :chat_messages, messages)

  defp put_base_data(table, data) when is_map(data) do
    :ets.delete_all_objects(table)

    if map_size(data) > 0 do
      :ets.insert(table, Map.to_list(data))
    end

    :ok
  end

  defp replace_base_data(table, current, updated) do
    Enum.each(updated, fn {key, value} ->
      if Map.fetch(current, key) != {:ok, value} do
        :ets.insert(table, {key, value})
      end
    end)

    current
    |> Map.keys()
    |> Enum.reject(&Map.has_key?(updated, &1))
    |> Enum.each(&:ets.delete(table, &1))

    :ok
  end

  defp base_snapshot(table), do: table |> :ets.tab2list() |> Map.new()

  defp base_get(table, key, default) do
    case :ets.lookup(table, key) do
      [{^key, value}] -> value
      [] -> default
    end
  end

  defp apply_get_and_update(_table, _key, current, {reply, current}),
    do: {:ok, reply, :unchanged}

  defp apply_get_and_update(table, key, _current, {reply, updated}) do
    :ets.insert(table, {key, updated})
    {:ok, reply, :changed}
  end

  defp apply_get_and_update(_table, _key, _current, other),
    do: {:error, {:invalid_store_get_and_update_result, other}}

  defp apply_transaction(_table, current, current), do: {:ok, :unchanged}

  defp apply_transaction(table, current, updated) when is_map(updated) do
    replace_base_data(table, current, updated)
    {:ok, :changed}
  end

  defp apply_transaction(_table, _current, other),
    do: {:error, {:invalid_store_transaction_result, other}}

  defp put_signal_sessions(signal_table, sessions) do
    signal_table
    |> SessionStore.attach()
    |> SessionStore.replace(sessions || SessionStore.new())

    :ok
  end

  defp maybe_replace_signal_sessions(signal_table, %SessionStore.Ref{table: signal_table}),
    do: :ok

  defp maybe_replace_signal_sessions(signal_table, sessions),
    do: put_signal_sessions(signal_table, sessions)

  defp put_device_cache(device_cache_table, cache) when is_map(cache) do
    :ets.insert(device_cache_table, {:snapshot, normalize_device_cache(cache)})
    :ok
  end

  defp load_device_cache_snapshot(device_cache_table) do
    case :ets.lookup(device_cache_table, :snapshot) do
      [{:snapshot, cache}] when is_map(cache) -> cache
      _ -> %{}
    end
  end

  defp normalize_device_cache(cache) when is_map(cache), do: cache
  defp normalize_device_cache(_), do: %{}

  defp changed_status(0), do: :unchanged
  defp changed_status(changed) when is_integer(changed) and changed > 0, do: :changed

  defp transfer_tables(store, writer) do
    [
      store.table,
      store.signal_table,
      store.device_cache_table,
      store.message_table.table,
      store.message_table.index_table,
      store.message_table.count_table
    ]
    |> Enum.each(&:ets.give_away(&1, writer, :ex_wapp_store))
  end

  defp atomic_write(path, blob) do
    temporary_path =
      path <> ".tmp." <> Integer.to_string(System.unique_integer([:positive, :monotonic]))

    case File.write(temporary_path, blob) do
      :ok ->
        case File.rename(temporary_path, path) do
          :ok ->
            :ok

          {:error, reason} ->
            _ = File.rm(temporary_path)
            {:error, reason}
        end

      {:error, reason} ->
        _ = File.rm(temporary_path)
        {:error, reason}
    end
  end

  defp telemetry_result(:ok), do: :ok
  defp telemetry_result({:error, _reason}), do: :error

  defp native_ms(duration),
    do: System.convert_time_unit(duration, :native, :microsecond) / 1_000

  defp load_file(path) do
    case File.read(path) do
      {:ok, blob} ->
        case Codec.decode(blob) do
          {:ok, data} when is_map(data) ->
            {:ok, data}

          {:error, :unknown_codec} ->
            load_legacy_ets_file(path)

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp load_legacy_ets_file(path) do
    char_path = String.to_charlist(path)

    case :ets.file2tab(char_path) do
      {:ok, temp_tab} ->
        data =
          case :ets.lookup(temp_tab, :data) do
            [{:data, value}] when is_map(value) -> value
            [{:data, _other}] -> %{}
            [] -> %{}
          end

        :ets.delete(temp_tab)
        maybe_migrate_legacy_file(path, data)
        {:ok, data}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_migrate_legacy_file(path, data) when is_map(data) do
    case Codec.encode(data) do
      {:ok, blob} ->
        case File.write(path, blob) do
          :ok ->
            Logger.info("[STORE] migrated legacy ETS store to codec path=#{path}")

          {:error, reason} ->
            Logger.warning(
              "[STORE] failed to migrate legacy ETS store path=#{path} reason=#{Log.reason(reason)}"
            )
        end

      {:error, reason} ->
        Logger.warning(
          "[STORE] failed to encode legacy ETS store path=#{path} reason=#{Log.reason(reason)}"
        )
    end
  end
end
