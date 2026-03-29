defmodule ExWapp.Store.Memory do
  @moduledoc """
  In-memory store adapter for testing.

  Data is stored in an Agent process and is not persisted to disk.
  Useful for unit tests and development scenarios where persistence
  is not required.

  ## Examples

      # Create a memory store
      store = ExWapp.Store.Memory.new()

      # Use in tests
      ExWapp.connect(store: ExWapp.Store.Memory)

      # Pre-populate with data
      store = ExWapp.Store.Memory.new(initial_data: %{foo: "bar"})

  ## Testing Usage

  ```elixir
  defmodule MyTest do
    use ExUnit.Case

    setup do
      store = ExWapp.Store.Memory.new()
      {:ok, store: store}
    end

    test "stores data", %{store: store} do
      assert :ok = ExWapp.Store.persist(store, %{key: "value"})
      assert {:ok, %{key: "value"}} = ExWapp.Store.load(store)
    end
  end
  ```
  """

  @behaviour ExWapp.Store

  defstruct [:agent]

  @type t :: %__MODULE__{agent: pid()}

  @impl true
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    initial_data = Keyword.get(opts, :initial_data, %{})
    {:ok, agent} = Agent.start_link(fn -> initial_data end)
    %__MODULE__{agent: agent}
  end

  @impl true
  @spec load(t()) :: {:ok, ExWapp.Store.data()}
  def load(%__MODULE__{agent: agent}) do
    data = Agent.get(agent, & &1)
    {:ok, data}
  end

  @spec get(t(), atom(), term()) :: term()
  def get(%__MODULE__{agent: agent}, key, default \\ nil) when is_atom(key) do
    Agent.get(agent, &Map.get(&1, key, default))
  end

  @impl true
  @spec persist(t(), ExWapp.Store.data()) :: :ok
  def persist(%__MODULE__{agent: agent}, data) when is_map(data) do
    Agent.update(agent, fn _ -> data end)
    :ok
  end

  @spec load_signal_sessions(t()) :: term()
  def load_signal_sessions(%__MODULE__{} = store), do: get(store, :signal_sessions)

  @spec persist_signal_sessions(t(), term()) :: :ok
  def persist_signal_sessions(%__MODULE__{agent: agent}, sessions) do
    Agent.update(agent, &Map.put(&1, :signal_sessions, ExWapp.Signal.SessionStore.snapshot(sessions)))
    :ok
  end

  @spec load_device_cache(t()) :: map()
  def load_device_cache(%__MODULE__{} = store), do: get(store, :device_cache, %{})

  @spec persist_device_cache(t(), map()) :: :ok
  def persist_device_cache(%__MODULE__{agent: agent}, cache) when is_map(cache) do
    Agent.update(agent, &Map.put(&1, :device_cache, cache))
    :ok
  end

  @impl true
  @spec clear(t()) :: :ok
  def clear(%__MODULE__{agent: agent}) do
    Agent.update(agent, fn _ -> %{} end)
    :ok
  end

  @doc """
  Updates specific keys in the store without replacing all data.

  This is a convenience function for tests that need to modify
  specific fields.

  ## Examples

      store = ExWapp.Store.Memory.new()
      ExWapp.Store.Memory.update(store, :noise, %{static_private: <<...>>})
  """
  @spec update(t(), atom(), term()) :: :ok
  def update(%__MODULE__{agent: agent}, key, value) do
    Agent.update(agent, fn data -> Map.put(data, key, value) end)
    :ok
  end

  @doc """
  Stops the underlying Agent process.

  Call this in test teardown if you want to clean up the process.
  """
  @spec stop(t()) :: :ok
  def stop(%__MODULE__{agent: agent}) do
    Agent.stop(agent)
    :ok
  end
end
