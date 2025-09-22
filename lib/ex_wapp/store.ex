defmodule ExWapp.Store do
  @moduledoc """
  Persistence abstraction used by the WhatsApp session.

  Adapters implement this behaviour to back the durable state (Noise keys,
  identity, Signal ratchets, etc). The default adapter is ETS+file
  (`ExWapp.Store.ETS`), but you can provide your own (e.g. SQL, Mongo).

  ## Passing a store to the Session

    * `nil`                      -> uses `ExWapp.Store.ETS.new/1` with defaults
    * `MyStoreModule`            -> calls `MyStoreModule.new([])`
    * `{MyStoreModule, opts}`    -> calls `MyStoreModule.new(opts)`
    * `%MyStoreStruct{}`         -> used as-is (must implement this behaviour)
  """

  @type data :: map()
  @type t :: struct()

  @callback new(keyword()) :: t()
  @callback load(t()) :: {:ok, data()} | {:error, term()}
  @callback persist(t(), data()) :: :ok | {:error, term()}

  @doc """
  Create a store instance from various inputs. See moduledoc for accepted forms.
  """
  @spec new(nil | module() | {module(), keyword()} | t()) :: t()
  def new(nil), do: ExWapp.Store.ETS.new([])
  def new(%_{} = struct), do: struct
  def new({mod, opts}) when is_atom(mod) and is_list(opts), do: mod.new(opts)
  def new(mod) when is_atom(mod), do: mod.new([])

  @doc "Load data from a store adapter."
  @spec load(t()) :: {:ok, data()} | {:error, term()}
  def load(store), do: store.__struct__.load(store)

  @doc "Load data or return an empty map if missing."
  @spec load!(t()) :: data()
  def load!(store) do
    case load(store) do
      {:ok, data} -> data
      {:error, _} -> %{}
    end
  end

  @doc "Persist data via the store adapter."
  @spec persist(t(), data()) :: :ok | {:error, term()}
  def persist(store, data), do: store.__struct__.persist(store, data)
end
