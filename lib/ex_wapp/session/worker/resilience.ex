defmodule ExWapp.Session.Worker.Resilience do
  @moduledoc """
  Reconnect/backoff policy for session workers.
  """

  @initial_backoff_ms 1_000
  @max_backoff_ms 300_000
  @backoff_multiplier 2

  @type reconnect_decision ::
          :session_invalid
          | :give_up
          | {:reconnect, attempt :: pos_integer(), delay_ms :: non_neg_integer()}

  @spec reconnect_decision(map()) :: reconnect_decision()
  def reconnect_decision(state) when is_map(state) do
    cond do
      Map.get(state, :session_invalid, false) ->
        :session_invalid

      reconnect_enabled?(Map.get(state, :opts, [])) and under_max_attempts?(state) ->
        attempt = Map.get(state, :reconnect_attempts, 0) + 1
        {:reconnect, attempt, calculate_backoff(attempt)}

      true ->
        :give_up
    end
  end

  @spec reconnect_enabled?(keyword()) :: boolean()
  def reconnect_enabled?(opts) when is_list(opts) do
    Keyword.get(opts, :reconnect, true)
  end

  defp under_max_attempts?(_state), do: true

  defp calculate_backoff(attempt) when is_integer(attempt) and attempt >= 1 do
    delay = @initial_backoff_ms * :math.pow(@backoff_multiplier, attempt - 1)
    jitter = :rand.uniform(1000)
    min(trunc(delay) + jitter, @max_backoff_ms)
  end
end
