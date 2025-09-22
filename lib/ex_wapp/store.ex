defmodule ExWapp.Store do
  @moduledoc """
  Persistence abstraction used by the WhatsApp session.

  The protocol demands a fair amount of durable state (Noise keys, device
  identity, Signal ratchets, ...). For the initial prototype we only store
  a generic map so we can gradually expand the schema without rewriting the
  surrounding code.
  """

  @type data :: map()
  @type t :: struct()

  @callback new(keyword()) :: t()
  @callback load(t()) :: {:ok, data()} | {:error, term()}
  @callback persist(t(), data()) :: :ok | {:error, term()}

  defmodule File do
    @moduledoc """
    Minimal file-backed store using Erlang external term format.

    The implementation is intentionally simple: it persists a map to a
    single file under `~/.cache/ex_wapp/session.etf`. The format is stable
    enough for prototyping yet human readable via `:erlang.binary_to_term/1`.
    """

    @behaviour ExWapp.Store

    defstruct [:path]

    @type t :: %__MODULE__{path: Path.t()}

    @impl true
    def new(opts \\ []) do
      path =
        opts
        |> Keyword.get(:path, default_path())
        |> Path.expand()

      :ok = Elixir.File.mkdir_p(Path.dirname(path))
      %__MODULE__{path: path}
    end

    @impl true
    def load(%__MODULE__{path: path}) do
      case Elixir.File.read(path) do
        {:ok, bin} -> {:ok, :erlang.binary_to_term(bin)}
        {:error, :enoent} -> {:ok, %{}}
        {:error, reason} -> {:error, reason}
      end
    end

    @impl true
    def persist(%__MODULE__{path: path}, data) when is_map(data) do
      tmp_path = path <> ".tmp"
      payload = :erlang.term_to_binary(data)

      with :ok <- Elixir.File.mkdir_p(Path.dirname(path)),
           :ok <- Elixir.File.write(tmp_path, payload),
           :ok <- Elixir.File.rename(tmp_path, path) do
        :ok
      else
        {:error, reason} -> {:error, reason}
      end
    end

    defp default_path do
      Path.join([System.user_home!(), ".cache", "ex_wapp", "session.etf"])
    end
  end
end
