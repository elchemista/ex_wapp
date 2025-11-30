defmodule ExWapp.Store do
  @moduledoc """
  Persistence adapter behaviour for WhatsApp session state.

  Adapters implement this behaviour to persist session data including:
  - Noise protocol keys (static keypair, handshake hash/salt)
  - Signal protocol state (identity, signed prekeys, sessions)
  - Client configuration and pairing data

  ## Built-in Adapters

    * `ExWapp.Store.Ets` - ETS table with file persistence (default)
    * `ExWapp.Store.Memory` - In-memory only, useful for testing

  ## Passing a Store to Session

  ```elixir
  # Use default ETS adapter
  ExWapp.connect(store: nil)

  # Use ETS with custom path
  ExWapp.connect(store: {ExWapp.Store.Ets, path: "/custom/path.etf"})

  # Use memory adapter for testing
  ExWapp.connect(store: ExWapp.Store.Memory)

  # Use pre-created store instance
  store = ExWapp.Store.Ets.new(path: "my_session.etf")
  ExWapp.connect(store: store)
  ```

  ## Creating a Custom Adapter

  Implement the `ExWapp.Store` behaviour:

  ```elixir
  defmodule MyApp.PostgresStore do
    @behaviour ExWapp.Store

    defstruct [:conn, :user_id]

    @impl true
    def new(opts) do
      conn = Keyword.fetch!(opts, :conn)
      user_id = Keyword.fetch!(opts, :user_id)
      %__MODULE__{conn: conn, user_id: user_id}
    end

    @impl true
    def load(%__MODULE__{conn: conn, user_id: user_id}) do
      case MyApp.Repo.get_by(WaSession, user_id: user_id) do
        nil -> {:ok, %{}}
        session -> {:ok, session.data}
      end
    end

    @impl true
    def persist(%__MODULE__{conn: conn, user_id: user_id}, data) do
      MyApp.Repo.insert_or_update!(%WaSession{user_id: user_id, data: data})
      :ok
    end
  end
  ```
  """

  @type data :: map()
  @type t :: struct()

  @doc """
  Creates a new store instance.

  Options are adapter-specific. See the adapter module documentation.
  """
  @callback new(opts :: keyword()) :: t()

  @doc """
  Loads persisted session data.

  Returns `{:ok, data}` with the stored map, or `{:ok, %{}}` if no data exists.
  Returns `{:error, reason}` if the load operation fails.
  """
  @callback load(store :: t()) :: {:ok, data()} | {:error, term()}

  @doc """
  Persists session data.

  The `data` map contains all session state that needs to survive restarts.
  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  @callback persist(store :: t(), data :: data()) :: :ok | {:error, term()}

  @doc """
  Optional callback to clear all stored data.

  Useful for testing or when unlinking a device.
  """
  @callback clear(store :: t()) :: :ok | {:error, term()}

  @optional_callbacks [clear: 1]

  # Default adapter
  @default_adapter ExWapp.Store.Ets

  @doc """
  Creates a store instance from various input formats.

  ## Examples

      # Use default adapter
      iex> ExWapp.Store.new(nil)
      %ExWapp.Store.Ets{...}

      # Use module name
      iex> ExWapp.Store.new(ExWapp.Store.Memory)
      %ExWapp.Store.Memory{...}

      # Use module with options
      iex> ExWapp.Store.new({ExWapp.Store.Ets, path: "/tmp/test.etf"})
      %ExWapp.Store.Ets{path: "/tmp/test.etf", ...}

      # Pass existing struct
      iex> store = ExWapp.Store.Memory.new([])
      iex> ExWapp.Store.new(store) == store
      true
  """
  @spec new(nil | module() | {module(), keyword()} | t()) :: t()
  def new(nil), do: @default_adapter.new([])
  def new(%_{} = struct), do: struct
  def new({mod, opts}) when is_atom(mod) and is_list(opts), do: mod.new(opts)
  def new(mod) when is_atom(mod), do: mod.new([])

  @doc """
  Loads data from a store adapter.

  ## Examples

      iex> store = ExWapp.Store.Memory.new([])
      iex> ExWapp.Store.load(store)
      {:ok, %{}}
  """
  @spec load(t()) :: {:ok, data()} | {:error, term()}
  def load(store), do: store.__struct__.load(store)

  @doc """
  Loads data from store, returning empty map on error.

  This is a convenience function that never fails. Use `load/1` if you
  need to handle errors explicitly.
  """
  @spec load!(t()) :: data()
  def load!(store) do
    case load(store) do
      {:ok, data} -> data
      {:error, _} -> %{}
    end
  rescue
    _ -> %{}
  catch
    :exit, _ -> %{}
  end

  @doc """
  Persists data via the store adapter.

  ## Examples

      iex> store = ExWapp.Store.Memory.new([])
      iex> ExWapp.Store.persist(store, %{foo: "bar"})
      :ok
      iex> ExWapp.Store.load(store)
      {:ok, %{foo: "bar"}}
  """
  @spec persist(t(), data()) :: :ok | {:error, term()}
  def persist(store, data), do: store.__struct__.persist(store, data)

  @doc """
  Clears all data from the store.

  Only available if the adapter implements the optional `clear/1` callback.
  """
  @spec clear(t()) :: :ok | {:error, term()}
  def clear(store) do
    if function_exported?(store.__struct__, :clear, 1) do
      store.__struct__.clear(store)
    else
      {:error, :not_implemented}
    end
  end
end
