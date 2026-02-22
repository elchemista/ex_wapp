defmodule ExWapp.Quota do
  @moduledoc false

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

      session_limit =
        Config.get(state.runtime_cfg, [:quota, :per_session, :daily_messages], 5_000)

      jid_limit = Config.get(state.runtime_cfg, [:quota, :per_jid, :daily_messages], 500)
      group_limit = Config.get(state.runtime_cfg, [:quota, :per_group, :daily_messages], 1_000)
      on_exceeded = Config.get(state.runtime_cfg, [:quota, :on_exceeded], :block)

      normalized = normalize_jid(jid)
      session_next = quota_state.session_count + 1
      jid_next = Map.get(quota_state.per_jid, normalized, 0) + 1
      group_next = Map.get(quota_state.per_group, normalized, 0) + 1

      exceeded =
        cond do
          session_next > session_limit -> {:session, session_limit}
          group_jid?(normalized) and group_next > group_limit -> {:group, group_limit}
          not group_jid?(normalized) and jid_next > jid_limit -> {:jid, jid_limit}
          true -> nil
        end

      cond do
        exceeded == nil ->
          {:ok, %{state | quota: increment(quota_state, normalized)}}

        on_exceeded == :warn_only ->
          {:ok, %{state | quota: increment(quota_state, normalized)}}

        true ->
          {:error, {:quota_exceeded, exceeded}, %{state | quota: quota_state}}
      end
    else
      {:ok, state}
    end
  end

  def check_and_increment(state, _jid), do: {:ok, state}

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
