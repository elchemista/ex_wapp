defmodule ExWapp.Session.Worker.Safety do
  @moduledoc false

  alias ExWapp.Config

  @window_ms 3_600_000

  @type state_data :: %{
          counters: %{optional(atom()) => [integer()]},
          blocked_until_ms: integer() | nil,
          forbidden: boolean(),
          last_trip_reason: atom() | nil
        }

  @spec new() :: state_data()
  def new do
    %{
      counters: %{},
      blocked_until_ms: nil,
      forbidden: false,
      last_trip_reason: nil
    }
  end

  @spec check_send_allowed(map()) :: {:ok, map()} | {:error, term(), map()}
  def check_send_allowed(state) when is_map(state) do
    safety_cfg = Config.get(state.runtime_cfg, [:safety], %{})

    if Config.get(safety_cfg, [:enabled], true) do
      safety = Map.get(state, :safety) || new()
      now_ms = now_ms()
      disable_on_forbidden = Config.get(safety_cfg, [:disable_send_on_forbidden], true)

      cond do
        disable_on_forbidden and safety.forbidden ->
          {:error, :forbidden_locked, %{state | safety: safety}}

        is_integer(safety.blocked_until_ms) and safety.blocked_until_ms > now_ms ->
          retry_after_ms = max(safety.blocked_until_ms - now_ms, 1)
          {:error, {:safety_cooloff, retry_after_ms}, %{state | safety: safety}}

        true ->
          cleared = %{safety | blocked_until_ms: nil}
          {:ok, %{state | safety: cleared}}
      end
    else
      {:ok, state}
    end
  end

  def check_send_allowed(state), do: {:ok, state}

  @spec record_signal(map(), atom()) :: map()
  def record_signal(state, signal) when is_map(state) and is_atom(signal) do
    safety_cfg = Config.get(state.runtime_cfg, [:safety], %{})

    if Config.get(safety_cfg, [:enabled], true) do
      now_ms = now_ms()
      safety = Map.get(state, :safety) || new()
      current = Map.get(safety.counters, signal, [])
      recent = Enum.filter(current, fn ts -> now_ms - ts <= @window_ms end)
      updated = [now_ms | recent]
      counters = Map.put(safety.counters, signal, updated)
      threshold = threshold_for(signal, safety_cfg)
      reached = length(updated) >= threshold

      safety =
        if reached do
          trip(safety, signal, now_ms, safety_cfg)
        else
          %{safety | counters: counters}
        end

      %{state | safety: safety}
    else
      state
    end
  end

  def record_signal(state, _signal), do: state

  @spec status(map()) :: map()
  def status(state) when is_map(state) do
    safety = Map.get(state, :safety) || new()

    %{
      forbidden: safety.forbidden,
      blocked_until_ms: safety.blocked_until_ms,
      last_trip_reason: safety.last_trip_reason,
      counters: safety.counters
    }
  end

  defp trip(safety, signal, now_ms, safety_cfg) do
    cooloff_ms = Config.get(safety_cfg, [:cooloff_on_rate_signal_ms], 900_000)
    disable_on_forbidden = Config.get(safety_cfg, [:disable_send_on_forbidden], true)

    base = %{safety | last_trip_reason: signal}

    case signal do
      :forbidden when disable_on_forbidden ->
        %{base | forbidden: true}

      _ ->
        %{base | blocked_until_ms: now_ms + cooloff_ms}
    end
  end

  defp threshold_for(:unauthorized, safety_cfg),
    do: Config.get(safety_cfg, [:max_401_events_per_hour], 1)

  defp threshold_for(:device_removed, safety_cfg),
    do: Config.get(safety_cfg, [:max_401_events_per_hour], 1)

  defp threshold_for(:forbidden, safety_cfg),
    do: Config.get(safety_cfg, [:max_403_events_per_hour], 1)

  defp threshold_for(:stream_replaced, safety_cfg),
    do: Config.get(safety_cfg, [:max_stream_replaced_per_hour], 3)

  defp threshold_for(_signal, _safety_cfg), do: 1

  defp now_ms, do: System.monotonic_time(:millisecond)
end
