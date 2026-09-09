defmodule ExWapp.Test.FaultStore do
  @moduledoc false
  @behaviour ExWapp.Store
  alias ExWapp.Store
  defstruct [:inner, :faults]

  def new(opts \\ []) do
    {:ok, faults} = Agent.start_link(fn -> %{} end)
    %__MODULE__{inner: Store.Memory.new(opts), faults: faults}
  end

  def arm(store, callback, action), do: Agent.update(store.faults, &Map.put(&1, callback, action))
  def load(store), do: run(store, :load, fn -> Store.snapshot(store.inner) end)
  def persist(store, data), do: run(store, :persist, fn -> Store.persist(store.inner, data) end)
  def flush(store), do: run(store, :flush, fn -> :ok end)
  def close(store), do: run(store, :close, fn -> :ok end)
  def begin_batch(store, _), do: run(store, :begin_batch, fn -> :ok end)
  def finish_batch(store, _), do: run(store, :finish_batch, fn -> :ok end)

  def update(store, key, default, fun),
    do: run(store, :update, fn -> Store.update(store.inner, key, default, fun) end)

  def get_and_update(store, key, default, fun),
    do:
      run(store, :get_and_update, fn -> Store.get_and_update(store.inner, key, default, fun) end)

  def transaction(store, fun),
    do: run(store, :transaction, fn -> Store.transaction(store.inner, fun) end)

  defp run(store, callback, fun) do
    action = Agent.get_and_update(store.faults, fn faults -> Map.pop(faults, callback) end)

    case action do
      nil -> fun.()
      {:return, result} -> result
      :raise -> raise "adapter temporarily unavailable"
      :throw -> throw(:adapter_aborted)
      :exit -> exit(:adapter_disconnected)
    end
  end
end
