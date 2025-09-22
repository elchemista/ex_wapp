defmodule ExWapp.Store.ETS do
  @moduledoc """
  Minimal ETS-backed store persisted to a single ETF file.

  File path defaults to `~/.cache/ex_wapp/session.etf`.
  """

  @behaviour ExWapp.Store

  defstruct [:path, :table]
  @type t :: %__MODULE__{path: Path.t(), table: :ets.tid()}

  @impl true
  def new(opts \\ []) do
    path =
      opts
      |> Keyword.get(:path, default_path())
      |> Path.expand()

    char_path = String.to_charlist(path)
    :ok = :filelib.ensure_dir(char_path)

    table =
      case :ets.file2tab(char_path) do
        {:ok, tab} -> tab
        {:error, _} -> :ets.new(:ex_wapp_store, [:set, :private])
      end

    if :ets.lookup(table, :data) == [] do
      :ets.insert(table, {:data, %{}})
    end

    %__MODULE__{path: path, table: table}
  end

  @impl true
  def load(%__MODULE__{table: table}) do
    case :ets.lookup(table, :data) do
      [{:data, data}] -> {:ok, data}
      [] -> {:ok, %{}}
    end
  end

  @impl true
  def persist(%__MODULE__{path: path, table: table}, data) when is_map(data) do
    :ets.insert(table, {:data, data})
    char_path = String.to_charlist(path)

    case :ets.tab2file(table, char_path, sync: true) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp default_path do
    Path.join([System.user_home!(), ".cache", "ex_wapp", "session.etf"])
  end
end
