defmodule ExWapp.SignalMutationLockTest do
  use ExUnit.Case, async: true

  alias ExWapp.Signal.MutationLock

  test "releases a mutation key when its owner crashes" do
    test_pid = self()
    key = {:crash_recovery, make_ref()}

    holder =
      spawn(fn ->
        MutationLock.with_lock(key, fn ->
          send(test_pid, {:mutation_lock_held, self()})

          receive do
            :finish -> :ok
          end
        end)
      end)

    on_exit(fn ->
      if Process.alive?(holder), do: Process.exit(holder, :kill)
    end)

    assert_receive {:mutation_lock_held, ^holder}

    waiter = Task.async(fn -> MutationLock.with_lock(key, fn -> :acquired_after_crash end) end)
    assert lock_has_waiter?(key)

    Process.exit(holder, :kill)
    assert Task.await(waiter) == :acquired_after_crash
  end

  defp lock_has_waiter?(key, attempts \\ 100)

  defp lock_has_waiter?(_key, 0), do: false

  defp lock_has_waiter?(key, attempts) do
    state = :sys.get_state(MutationLock)

    case Map.get(state.locks, key) do
      %{waiting: waiting} ->
        if :queue.is_empty(waiting) do
          Process.sleep(1)
          lock_has_waiter?(key, attempts - 1)
        else
          true
        end

      _other ->
        false
    end
  end
end
