defmodule ExWapp.Session.Worker.Safety do
  @moduledoc """
  Implements the session's outbound safety circuit breaker.

  It records server-side risk signals, applies configurable cool-off windows, and
  can lock sending after forbidden responses until the session is reset.
  """

  alias ExWapp.Config
  alias ExWapp.Session.JIDUtils
  alias ExWapp.Session.Worker
  alias ExWapp.Session.Worker.PolicyState

  @window_ms 3_600_000

  @type state_data :: %{
          counters: %{optional(atom()) => [integer()]},
          recipients: %{optional(String.t()) => integer()},
          blocked_until_ms: integer() | nil,
          forbidden: boolean(),
          last_trip_reason: atom() | nil
        }

  @spec new() :: state_data()
  def new do
    %{
      counters: %{},
      recipients: %{},
      blocked_until_ms: nil,
      forbidden: false,
      last_trip_reason: nil
    }
  end

  @spec check_send_allowed(Worker.t()) :: {:ok, Worker.t()} | {:error, term(), Worker.t()}
  def check_send_allowed(state) when is_map(state) do
    safety_cfg = Config.get(state.runtime_cfg, [:safety], %{})

    if Config.get(state.runtime_cfg, [:release_gates, :remote_kill_switch], false) do
      {:error, :remote_kill_switch, state}
    else
      check_circuit(state, safety_cfg)
    end
  end

  def check_send_allowed(state), do: {:ok, state}

  defp check_circuit(state, safety_cfg) do
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

  @doc false
  @spec check_recipient(Worker.t(), String.t()) ::
          {:ok, Worker.t()} | {:error, term(), Worker.t()}
  def check_recipient(state, jid) do
    if Config.get(state.runtime_cfg, [:safety, :enabled], true),
      do: check_recipient_enabled(state, jid),
      else: {:ok, state}
  end

  defp check_recipient_enabled(state, jid) do
    now = now_ms()
    safety = Map.get(state, :safety) || new()

    recipients =
      Map.reject(Map.get(safety, :recipients, %{}), fn {_jid, until} -> until <= now end)

    state = %{state | safety: Map.put(safety, :recipients, recipients)}
    key = JIDUtils.strip_device(jid)

    case Map.get(recipients, key) do
      nil -> {:ok, state}
      until -> {:error, {:recipient_cooloff, until - now}, state}
    end
  end

  @doc false
  @spec record_ack(Worker.t(), String.t(), String.t()) :: Worker.t()
  def record_ack(state, jid, code) when code in ["401", "403"] do
    if Config.get(state.runtime_cfg, [:safety, :enabled], true),
      do: suppress_recipient(state, jid),
      else: state
  end

  def record_ack(state, _jid, "429"), do: record_signal(state, :rate_limited)
  def record_ack(state, _jid, _code), do: state

  defp suppress_recipient(state, jid) do
    safety = Map.get(state, :safety) || new()
    recipients = Map.get(safety, :recipients, %{})
    ttl = Config.get(state.runtime_cfg, [:safety, :cooloff_on_rate_signal_ms], 900_000)
    key = JIDUtils.strip_device(jid)
    recipients = Map.put(recipients, key, now_ms() + ttl)

    %{state | safety: Map.put(safety, :recipients, recipients)}
    |> PolicyState.persist()
  end

  @spec record_signal(Worker.t(), atom()) :: Worker.t()
  def record_signal(state, signal) when is_map(state) and is_atom(signal) do
    safety_cfg = Config.get(state.runtime_cfg, [:safety], %{})

    if Config.get(safety_cfg, [:enabled], true) do
      now_ms = now_ms()
      safety = Map.get(state, :safety) || new()
      current = Map.get(safety.counters, signal, [])
      recent = Enum.filter(current, fn ts -> now_ms - ts <= @window_ms end)
      threshold = threshold_for(signal, safety_cfg)
      updated = Enum.take([now_ms | recent], max(threshold, 1))
      counters = Map.put(safety.counters, signal, updated)
      reached = length(updated) >= threshold

      safety =
        if reached do
          trip(%{safety | counters: counters}, signal, now_ms, safety_cfg)
        else
          %{safety | counters: counters}
        end

      %{state | safety: safety}
      |> PolicyState.persist()
    else
      state
    end
  end

  def record_signal(state, _signal), do: state

  @spec status(Worker.t()) :: map()
  def status(state) when is_map(state) do
    safety = Map.get(state, :safety) || new()

    %{
      forbidden: safety.forbidden,
      blocked_until_ms: safety.blocked_until_ms,
      last_trip_reason: safety.last_trip_reason,
      counters: safety.counters,
      recipient_cooloffs: Map.get(safety, :recipients, %{})
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
