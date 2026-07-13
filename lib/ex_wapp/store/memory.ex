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

  alias ExWapp.Store.MessageTable

  defstruct [:agent, :message_table]

  @type t :: %__MODULE__{agent: pid(), message_table: MessageTable.t()}

  @impl true
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    initial_data = Keyword.get(opts, :initial_data, %{})
    {base_data, messages} = MessageTable.extract(initial_data)
    {:ok, agent} = Agent.start_link(fn -> base_data end)

    %__MODULE__{agent: agent, message_table: MessageTable.new(messages)}
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
  def persist(%__MODULE__{agent: agent, message_table: message_table}, data)
      when is_map(data) do
    {base_data, messages} = MessageTable.extract(data)
    :ok = put_initial_messages(message_table, messages)
    Agent.update(agent, fn _ -> base_data end)
    :ok
  end

  @impl true
  @spec stream_messages(t(), String.t(), keyword()) :: Enumerable.t()
  def stream_messages(%__MODULE__{message_table: message_table}, jid, opts) do
    MessageTable.stream(message_table, jid, opts)
  end

  @impl true
  @spec upsert_messages(t(), String.t(), [map()]) :: :ok
  def upsert_messages(%__MODULE__{message_table: message_table}, jid, messages) do
    MessageTable.upsert(message_table, jid, messages)
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
  @spec update_message_status(t(), String.t(), String.t(), atom()) :: :ok
  def update_message_status(%__MODULE__{message_table: message_table}, jid, message_id, status) do
    MessageTable.update_status(message_table, jid, message_id, status)
  end

  @impl true
  @spec update_message_status_by_id(t(), String.t(), atom()) :: :ok
  def update_message_status_by_id(%__MODULE__{message_table: message_table}, message_id, status) do
    MessageTable.update_status_by_id(message_table, message_id, status)
  end

  @impl true
  @spec delete_messages(t(), String.t(), [String.t()]) :: :ok
  def delete_messages(%__MODULE__{message_table: message_table}, jid, message_ids) do
    MessageTable.delete(message_table, jid, message_ids)
  end

  @impl true
  @spec delete_chat_messages(t(), String.t()) :: :ok
  def delete_chat_messages(%__MODULE__{message_table: message_table}, jid) do
    MessageTable.delete_chat(message_table, jid)
  end

  @impl true
  @spec snapshot_messages(t()) :: %{optional(String.t()) => [map()]}
  def snapshot_messages(%__MODULE__{message_table: message_table}) do
    MessageTable.snapshot(message_table)
  end

  @spec load_signal_sessions(t()) :: term()
  def load_signal_sessions(%__MODULE__{} = store), do: get(store, :signal_sessions)

  @spec persist_signal_sessions(t(), term()) :: :ok
  def persist_signal_sessions(%__MODULE__{agent: agent}, sessions) do
    Agent.update(
      agent,
      &Map.put(&1, :signal_sessions, ExWapp.Signal.SessionStore.snapshot(sessions))
    )

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
  def clear(%__MODULE__{agent: agent, message_table: message_table}) do
    Agent.update(agent, fn _ -> %{} end)
    MessageTable.clear(message_table)
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

  defp put_initial_messages(message_table, messages) do
    Enum.each(messages, fn {jid, chat_messages} ->
      MessageTable.upsert(message_table, jid, chat_messages)
    end)

    :ok
  end

  @doc """
  Stops the underlying Agent process.

  Call this in test teardown if you want to clean up the process.
  """
  @spec stop(t()) :: :ok
  def stop(%__MODULE__{agent: agent}) do
    if Process.alive?(agent), do: Agent.stop(agent), else: :ok
    :ok
  catch
    :exit, {:noproc, _} -> :ok
    :exit, :noproc -> :ok
  end
end
