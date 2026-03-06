defmodule ExWapp.Store.Ets do
  @moduledoc """
  ETS-backed store with file persistence.

  This is the default store adapter. It keeps data in an ETS table for fast
  access and persists to a file on disk using Erlang's term format (ETF).

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

    char_path = String.to_charlist(path)
    :ok = :filelib.ensure_dir(char_path)

    # Always create a new public table (accessible from any process)
    table = :ets.new(:ex_wapp_store, [:set, :public, :compressed])

    # Load existing data from file if available
    case :ets.file2tab(char_path) do
      {:ok, temp_tab} ->
        case :ets.lookup(temp_tab, :data) do
          [{:data, data}] -> :ets.insert(table, {:data, data})
          [] -> :ets.insert(table, {:data, %{}})
        end

        :ets.delete(temp_tab)

      {:error, _} ->
        :ets.insert(table, {:data, %{}})
    end

    %__MODULE__{path: path, table: table}
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
    :ets.insert(table, {:data, data})
    char_path = String.to_charlist(path)

    case :ets.tab2file(table, char_path, sync: true) do
      :ok -> :ok
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
end
