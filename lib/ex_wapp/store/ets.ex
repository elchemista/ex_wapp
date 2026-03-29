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

  - ETS table is created with `:public` access to allow cross-process reads
  - Data is persisted synchronously on each `persist/2` call
  - File is loaded on `new/1` if it exists
  """

  @behaviour ExWapp.Store
  require Logger
  alias ExWapp.Signal.SessionStore

  defstruct [:path, :table, :signal_table, :device_cache_table]

  @type t :: %__MODULE__{
          path: Path.t(),
          table: :ets.tid(),
          signal_table: :ets.tid(),
          device_cache_table: :ets.tid()
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

    # Always create new public tables (accessible from any process)
    table = :ets.new(:ex_wapp_store, [:set, :public, :compressed])
    signal_store = SessionStore.new_ets()
    signal_table = signal_store.table
    device_cache_table = :ets.new(:ex_wapp_device_cache, [:set, :public, :compressed])

    # Load existing data from file if available
    case load_file(path) do
      {:ok, data} ->
        {base_data, signal_sessions, device_cache} = split_specialized_data(data)
        :ets.insert(table, {:data, base_data})
        SessionStore.replace(signal_store, signal_sessions)
        :ets.insert(device_cache_table, {:snapshot, normalize_device_cache(device_cache)})

      {:error, :enoent} ->
        :ets.insert(table, {:data, %{}})
        :ets.insert(device_cache_table, {:snapshot, %{}})

      {:error, reason} ->
        raise "ExWapp.Store.Ets failed to load #{path}: #{inspect(reason)}"
    end

    %__MODULE__{
      path: path,
      table: table,
      signal_table: signal_table,
      device_cache_table: device_cache_table
    }
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
  def load(%__MODULE__{table: table, signal_table: signal_table, device_cache_table: device_cache_table}) do
    case :ets.lookup(table, :data) do
      [{:data, data}] ->
        {:ok,
         data
         |> Map.put(:signal_sessions, SessionStore.snapshot(SessionStore.attach(signal_table)))
         |> Map.put(:device_cache, load_device_cache_snapshot(device_cache_table))}

      [] ->
        {:ok,
         %{
           signal_sessions: SessionStore.snapshot(SessionStore.attach(signal_table)),
           device_cache: load_device_cache_snapshot(device_cache_table)
         }}
    end
  end

  @impl true
  @spec persist(t(), ExWapp.Store.data()) :: :ok | {:error, term()}
  def persist(%__MODULE__{} = store, data) when is_map(data) do
    {base_data, signal_sessions, device_cache} = split_specialized_data(data)

    with :ok <- put_base_data(store.table, base_data),
         :ok <- put_signal_sessions(store.signal_table, signal_sessions),
         :ok <- put_device_cache(store.device_cache_table, device_cache),
         {:ok, blob} <- ExWapp.Store.Codec.encode(merged_snapshot(store)),
         :ok <- File.write(store.path, blob) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  @spec clear(t()) :: :ok
  def clear(%__MODULE__{path: path, table: table, signal_table: signal_table, device_cache_table: device_cache_table}) do
    :ets.insert(table, {:data, %{}})
    :ets.delete_all_objects(signal_table)
    :ets.insert(device_cache_table, {:snapshot, %{}})

    # Delete file if it exists
    case File.rm(path) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      {:error, _reason} -> :ok
    end
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
        case :ets.lookup(store.table, :data) do
          [{:data, data}] -> Map.get(data, key, default)
          [] -> default
        end
    end
  end

  @spec load_signal_sessions(t()) :: SessionStore.t()
  def load_signal_sessions(%__MODULE__{signal_table: signal_table}) do
    SessionStore.attach(signal_table)
  end

  @spec persist_signal_sessions(t(), term()) :: :ok | {:error, term()}
  def persist_signal_sessions(%__MODULE__{} = store, sessions) do
    with :ok <- put_signal_sessions(store.signal_table, sessions),
         {:ok, blob} <- ExWapp.Store.Codec.encode(merged_snapshot(store)),
         :ok <- File.write(store.path, blob) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec load_device_cache(t()) :: map()
  def load_device_cache(%__MODULE__{device_cache_table: device_cache_table}) do
    load_device_cache_snapshot(device_cache_table)
  end

  @spec persist_device_cache(t(), map()) :: :ok | {:error, term()}
  def persist_device_cache(%__MODULE__{} = store, cache) when is_map(cache) do
    with :ok <- put_device_cache(store.device_cache_table, cache),
         {:ok, blob} <- ExWapp.Store.Codec.encode(merged_snapshot(store)),
         :ok <- File.write(store.path, blob) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp default_path do
    Path.join([System.user_home!() | @default_path_segments])
  end

  defp split_specialized_data(data) when is_map(data) do
    {
      Map.drop(data, [:signal_sessions, :device_cache]),
      SessionStore.snapshot(Map.get(data, :signal_sessions, SessionStore.new())),
      normalize_device_cache(Map.get(data, :device_cache, %{}))
    }
  end

  defp merged_snapshot(%__MODULE__{table: table, signal_table: signal_table, device_cache_table: device_cache_table}) do
    base_data =
      case :ets.lookup(table, :data) do
        [{:data, data}] -> data
        [] -> %{}
      end

    base_data
    |> Map.put(:signal_sessions, SessionStore.snapshot(SessionStore.attach(signal_table)))
    |> Map.put(:device_cache, load_device_cache_snapshot(device_cache_table))
  end

  defp put_base_data(table, data) when is_map(data) do
    :ets.insert(table, {:data, data})
    :ok
  end

  defp put_signal_sessions(signal_table, sessions) do
    signal_table
    |> SessionStore.attach()
    |> SessionStore.replace(sessions || SessionStore.new())

    :ok
  end

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

  defp load_file(path) do
    case File.read(path) do
      {:ok, blob} ->
        case ExWapp.Store.Codec.decode(blob) do
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
    case ExWapp.Store.Codec.encode(data) do
      {:ok, blob} ->
        case File.write(path, blob) do
          :ok ->
            Logger.info("[STORE] migrated legacy ETS store to codec path=#{path}")

          {:error, reason} ->
            Logger.warning(
              "[STORE] failed to migrate legacy ETS store path=#{path} reason=#{inspect(reason)}"
            )
        end

      {:error, reason} ->
        Logger.warning(
          "[STORE] failed to encode legacy ETS store path=#{path} reason=#{inspect(reason)}"
        )
    end
  end
end
