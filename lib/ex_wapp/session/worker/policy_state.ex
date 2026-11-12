defmodule ExWapp.Session.Worker.PolicyState do
  @moduledoc false
  require Logger
  alias ExWapp.Store

  # Monotonic timestamps are VM-local. Store absolute expiry times, then convert
  # back on restore so a worker/VM restart cannot reset an active cool-off.
  @spec restore(state) :: state when state: map()
  def restore(state) do
    case Store.get(state.store, :outbound_policy) do
      %{version: 1, safety: safety, quota: quota} when is_map(safety) and is_map(quota) ->
        offset = System.monotonic_time(:millisecond) - System.system_time(:millisecond)
        %{state | safety: shift(safety, offset), quota: quota}

      _ ->
        state
    end
  end

  @spec persist(state) :: state when state: map()
  def persist(state) when not is_map_key(state, :store), do: state
  def persist(%{store: nil} = state), do: state

  def persist(state) do
    offset = System.system_time(:millisecond) - System.monotonic_time(:millisecond)

    case Store.put(state.store, :outbound_policy, %{
           version: 1,
           safety: shift(state.safety, offset),
           quota: state.quota
         }) do
      :ok ->
        state

      {:error, reason} ->
        Logger.error("Cannot persist outbound policy: #{inspect(reason)}")
        # Fail closed if counters/locks cannot be saved durably.
        put_in(state.send_health.paused, true)
    end
  end

  defp shift(safety, offset) do
    safety
    |> Map.update(:blocked_until_ms, nil, &shift_time(&1, offset))
    |> Map.update(:counters, %{}, fn counters ->
      Map.new(counters, fn {key, times} -> {key, Enum.map(times, &(&1 + offset))} end)
    end)
    |> Map.update(:recipients, %{}, fn recipients ->
      Map.new(recipients, fn {jid, time} -> {jid, time + offset} end)
    end)
  end

  defp shift_time(nil, _offset), do: nil
  defp shift_time(time, offset), do: time + offset
end
