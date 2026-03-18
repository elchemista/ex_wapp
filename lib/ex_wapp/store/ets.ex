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

  defstruct [:path, :table]

  @type t :: %__MODULE__{
          path: Path.t(),
          table: :ets.tid()
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

    # Always create a new public table (accessible from any process)
    table = :ets.new(:ex_wapp_store, [:set, :public, :compressed])

    # Load existing data from file if available
    case load_file(path) do
      {:ok, data} ->
        :ets.insert(table, {:data, data})

      {:error, :enoent} ->
        :ets.insert(table, {:data, %{}})

      {:error, reason} ->
        raise "ExWapp.Store.Ets failed to load #{path}: #{inspect(reason)}"
    end

    %__MODULE__{path: path, table: table}
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
  def load(%__MODULE__{table: table}) do
    case :ets.lookup(table, :data) do
      [{:data, data}] -> {:ok, data}
      [] -> {:ok, %{}}
    end
  end

  @impl true
  @spec persist(t(), ExWapp.Store.data()) :: :ok | {:error, term()}
  def persist(%__MODULE__{path: path, table: table}, data) when is_map(data) do
    with {:ok, blob} <- ExWapp.Store.Codec.encode(data),
         :ok <- File.write(path, blob) do
      :ets.insert(table, {:data, data})
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  @spec clear(t()) :: :ok
  def clear(%__MODULE__{path: path, table: table}) do
    :ets.insert(table, {:data, %{}})

    # Delete file if it exists
    case File.rm(path) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      {:error, _reason} -> :ok
    end
  end

  defp default_path do
    Path.join([System.user_home!() | @default_path_segments])
  end

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
