defmodule ExWapp.Signal.MutationLock do
  @moduledoc false

  use GenServer

  defstruct locks: %{}, monitors: %{}

  @type key :: term()
  @type lock :: %{
          owner: pid(),
          monitor: reference(),
          waiting: :queue.queue(GenServer.from())
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Runs `fun` while holding every requested mutation key."
  @spec with_locks([key()], (-> result)) :: result when result: term()
  def with_locks(keys, fun) when is_list(keys) and is_function(fun, 0) do
    keys
    |> Enum.uniq()
    |> Enum.sort()
    |> lock_all(fun)
  end

  @doc "Runs `fun` while holding one mutation key."
  @spec with_lock(key(), (-> result)) :: result when result: term()
  def with_lock(key, fun) when is_function(fun, 0) do
    process_key = {__MODULE__, key}

    if Process.get(process_key) do
      fun.()
    else
      with_coordinator(key, process_key, fun)
    end
  end

  @impl true
  def init(:ok), do: {:ok, %__MODULE__{}}

  @impl true
  def handle_call({:acquire, key}, {owner, _tag} = from, state) do
    case Map.get(state.locks, key) do
      nil ->
        monitor = Process.monitor(owner)
        lock = %{owner: owner, monitor: monitor, waiting: :queue.new()}

        {:reply, :ok,
         %{
           state
           | locks: Map.put(state.locks, key, lock),
             monitors: Map.put(state.monitors, monitor, key)
         }}

      %{owner: ^owner} ->
        # `with_lock/2` handles normal re-entrancy in the caller. Treat a direct
        # duplicate acquisition as already held as an additional safety net.
        {:reply, :ok, state}

      lock ->
        updated_lock = %{lock | waiting: :queue.in(from, lock.waiting)}
        {:noreply, %{state | locks: Map.put(state.locks, key, updated_lock)}}
    end
  end

  def handle_call({:release, key}, {owner, _tag}, state) do
    case Map.get(state.locks, key) do
      %{owner: ^owner} = lock ->
        {:reply, :ok, release_lock(state, key, lock)}

      _other ->
        {:reply, {:error, :not_lock_owner}, state}
    end
  end

  @impl true
  def handle_info({:DOWN, monitor, :process, owner, _reason}, state) do
    case Map.pop(state.monitors, monitor) do
      {nil, _monitors} ->
        {:noreply, state}

      {key, monitors} ->
        state = %{state | monitors: monitors}

        case Map.get(state.locks, key) do
          %{owner: ^owner, monitor: ^monitor} = lock ->
            {:noreply, grant_next(state, key, lock.waiting)}

          _other ->
            {:noreply, state}
        end
    end
  end

  defp lock_all([], fun), do: fun.()

  defp lock_all([key | rest], fun) do
    with_lock(key, fn -> lock_all(rest, fun) end)
  end

  defp with_coordinator(key, process_key, fun) do
    case Process.whereis(__MODULE__) do
      coordinator when is_pid(coordinator) ->
        run_coordinated(coordinator, key, process_key, fun)

      nil ->
        # Signal primitives are useful in isolated scripts too. Preserve the
        # same local-node exclusion guarantee when the OTP application is not
        # running and therefore has not started the coordinator.
        :global.trans({{__MODULE__, key}, self()}, fun, [node()])
    end
  end

  defp run_coordinated(coordinator, key, process_key, fun) do
    :ok = GenServer.call(coordinator, {:acquire, key}, :infinity)
    Process.put(process_key, true)

    try do
      fun.()
    after
      Process.delete(process_key)
      release(coordinator, key)
    end
  end

  defp release(coordinator, key) do
    GenServer.call(coordinator, {:release, key}, :infinity)
  catch
    :exit, _reason -> :ok
  end

  defp release_lock(state, key, lock) do
    Process.demonitor(lock.monitor, [:flush])

    state
    |> Map.update!(:monitors, &Map.delete(&1, lock.monitor))
    |> grant_next(key, lock.waiting)
  end

  defp grant_next(state, key, waiting) do
    case :queue.out(waiting) do
      {:empty, _queue} ->
        %{state | locks: Map.delete(state.locks, key)}

      {{:value, {owner, _tag} = from}, remaining} ->
        if Process.alive?(owner) do
          monitor = Process.monitor(owner)
          GenServer.reply(from, :ok)
          lock = %{owner: owner, monitor: monitor, waiting: remaining}

          %{
            state
            | locks: Map.put(state.locks, key, lock),
              monitors: Map.put(state.monitors, monitor, key)
          }
        else
          grant_next(state, key, remaining)
        end
    end
  end
end
