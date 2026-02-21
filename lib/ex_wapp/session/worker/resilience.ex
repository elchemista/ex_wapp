defmodule ExWapp.Session.Worker.Resilience do
  @moduledoc """
  Reconnect/backoff policy for session workers.
  """

  alias ExWapp.Config

  @type reconnect_decision ::
          :session_invalid
          | :give_up
          | {:reconnect, attempt :: pos_integer(), delay_ms :: non_neg_integer()}

  @spec reconnect_decision(map()) :: reconnect_decision()
  def reconnect_decision(state) when is_map(state) do
    reconnect_cfg = Config.get(state, [:runtime_cfg, :reconnect], %{})
    enabled? = reconnect_enabled?(state, reconnect_cfg)
    stop_on_invalid? = Config.get(reconnect_cfg, [:stop_on_session_invalid], true)

    cond do
      Map.get(state, :session_invalid, false) and stop_on_invalid? ->
        :session_invalid

      enabled? and under_max_attempts?(state, reconnect_cfg) ->
        attempt = Map.get(state, :reconnect_attempts, 0) + 1
        {:reconnect, attempt, calculate_backoff(attempt, reconnect_cfg)}

      true ->
        :give_up
    end
  end

  @spec reconnect_enabled?(map(), map()) :: boolean()
  def reconnect_enabled?(state, reconnect_cfg) when is_map(state) and is_map(reconnect_cfg) do
    cfg_enabled = Config.get(reconnect_cfg, [:enabled], true)
    legacy_enabled = state |> Map.get(:opts, []) |> Keyword.get(:reconnect, true)
    cfg_enabled and legacy_enabled
  end

  defp under_max_attempts?(state, reconnect_cfg) do
    max_attempts = Config.get(reconnect_cfg, [:max_attempts], 12)

    case max_attempts do
      :infinity -> true
      value when is_integer(value) and value > 0 -> Map.get(state, :reconnect_attempts, 0) < value
      _ -> false
    end
  end

  defp calculate_backoff(attempt, reconnect_cfg) when is_integer(attempt) and attempt >= 1 do
    initial_backoff_ms = Config.get(reconnect_cfg, [:initial_backoff_ms], 1_000)
    backoff_multiplier = Config.get(reconnect_cfg, [:backoff_multiplier], 2.0)
    max_backoff_ms = Config.get(reconnect_cfg, [:max_backoff_ms], 300_000)
    jitter_ms = Config.get(reconnect_cfg, [:jitter_ms], 1_000)

    delay = initial_backoff_ms * :math.pow(backoff_multiplier, attempt - 1)
    jitter = if jitter_ms > 0, do: :rand.uniform(jitter_ms), else: 0
    min(trunc(delay) + jitter, max_backoff_ms)
  end
end
