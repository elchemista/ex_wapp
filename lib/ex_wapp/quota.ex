defmodule ExWapp.Quota do
  @moduledoc """
  Tracks configurable daily outbound-message quotas.

  The counter state lives in the session worker and is split across the whole
  session, individual JIDs, and groups. `check_and_increment/2` returns the
  updated worker state and an explicit error when a blocking limit is hit.
  """

  alias ExWapp.Config

  @type state_data :: %{
          period_key: String.t(),
          session_count: non_neg_integer(),
          per_jid: %{optional(String.t()) => non_neg_integer()},
          per_group: %{optional(String.t()) => non_neg_integer()}
        }

  @spec new(map()) :: state_data()
  def new(runtime_cfg \\ %{}) do
    %{
      period_key: period_key(Config.get(runtime_cfg, [:quota, :reset_timezone], "UTC")),
      session_count: 0,
      per_jid: %{},
      per_group: %{}
    }
  end

  @spec check_and_increment(map(), String.t()) :: {:ok, map()} | {:error, term(), map()}
  def check_and_increment(state, jid) when is_map(state) and is_binary(jid) do
    enabled? = Config.get(state.runtime_cfg, [:quota, :enabled], true)

    if enabled? do
      quota_state = refresh_period(state.quota || new(state.runtime_cfg), state.runtime_cfg)
      limits = quota_limits(state.runtime_cfg)
      normalized = normalize_jid(jid)
      exceeded = quota_exceeded(quota_state, normalized, limits)

      apply_quota_decision(state, quota_state, normalized, exceeded, limits.on_exceeded)
    else
      {:ok, state}
    end
  end

  def check_and_increment(state, _jid), do: {:ok, state}

  defp quota_limits(runtime_cfg) do
    %{
      session_limit: Config.get(runtime_cfg, [:quota, :per_session, :daily_messages], 5_000),
      jid_limit: Config.get(runtime_cfg, [:quota, :per_jid, :daily_messages], 500),
      group_limit: Config.get(runtime_cfg, [:quota, :per_group, :daily_messages], 1_000),
      on_exceeded: Config.get(runtime_cfg, [:quota, :on_exceeded], :block)
    }
  end

  defp quota_exceeded(quota_state, normalized_jid, limits) do
    session_next = quota_state.session_count + 1
    jid_next = Map.get(quota_state.per_jid, normalized_jid, 0) + 1
    group_next = Map.get(quota_state.per_group, normalized_jid, 0) + 1

    cond do
      session_next > limits.session_limit ->
        {:session, limits.session_limit}

      group_jid?(normalized_jid) and group_next > limits.group_limit ->
        {:group, limits.group_limit}

      not group_jid?(normalized_jid) and jid_next > limits.jid_limit ->
        {:jid, limits.jid_limit}

      true ->
        nil
    end
  end

  defp apply_quota_decision(state, quota_state, normalized_jid, nil, _on_exceeded) do
    {:ok, %{state | quota: increment(quota_state, normalized_jid)}}
  end

  defp apply_quota_decision(state, quota_state, normalized_jid, _exceeded, :warn_only) do
    {:ok, %{state | quota: increment(quota_state, normalized_jid)}}
  end

  defp apply_quota_decision(state, quota_state, _normalized_jid, exceeded, _on_exceeded) do
    {:error, {:quota_exceeded, exceeded}, %{state | quota: quota_state}}
  end

  defp increment(quota_state, jid) do
    if group_jid?(jid) do
      %{
        quota_state
        | session_count: quota_state.session_count + 1,
          per_group: Map.update(quota_state.per_group, jid, 1, &(&1 + 1))
      }
    else
      %{
        quota_state
        | session_count: quota_state.session_count + 1,
          per_jid: Map.update(quota_state.per_jid, jid, 1, &(&1 + 1))
      }
    end
  end

  defp refresh_period(quota_state, runtime_cfg) do
    timezone = Config.get(runtime_cfg, [:quota, :reset_timezone], "UTC")
    current_key = period_key(timezone)

    if quota_state.period_key == current_key do
      quota_state
    else
      %{quota_state | period_key: current_key, session_count: 0, per_jid: %{}, per_group: %{}}
    end
  end

  defp period_key(timezone) do
    date =
      case timezone do
        "UTC" ->
          Date.utc_today()

        tz when is_binary(tz) ->
          try do
            DateTime.now!(tz) |> DateTime.to_date()
          rescue
            _ -> Date.utc_today()
          end

        _ ->
          Date.utc_today()
      end

    Date.to_iso8601(date)
  end

  defp normalize_jid(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace(~r/:\d+@/, "@")
  end

  defp group_jid?(jid), do: String.ends_with?(jid, "@g.us")
end
