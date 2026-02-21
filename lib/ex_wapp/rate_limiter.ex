defmodule ExWapp.RateLimiter do
  @moduledoc false

  alias ExWapp.Config

  @type bucket :: %{tokens: float(), last_ms: integer()}
  @type state_data :: %{
          global: bucket() | nil,
          per_jid: %{optional(String.t()) => bucket()},
          per_group: %{optional(String.t()) => bucket()},
          last_send_at_ms: integer() | nil
        }

  @spec new() :: state_data()
  def new do
    %{
      global: nil,
      per_jid: %{},
      per_group: %{},
      last_send_at_ms: nil
    }
  end

  @spec check_and_update(map(), String.t()) :: {:ok, map()} | {:error, term(), map()}
  def check_and_update(state, jid) when is_map(state) and is_binary(jid) do
    throttle_enabled = Config.get(state.runtime_cfg, [:throttle, :enabled], true)

    if throttle_enabled do
      limiter = Map.get(state, :rate_limiter) || new()
      now_ms = now_ms()

      with {:ok, limiter} <- enforce_global(limiter, state.runtime_cfg, now_ms),
           {:ok, limiter} <- enforce_entity(limiter, state.runtime_cfg, jid, now_ms),
           {:ok, limiter} <- enforce_min_delay(limiter, state.runtime_cfg, now_ms) do
        {:ok, %{state | rate_limiter: %{limiter | last_send_at_ms: now_ms}}}
      else
        {:error, _} = error ->
          {reason, _retry_after_ms} = normalize_limit_error(error, state.runtime_cfg)
          {:error, reason, %{state | rate_limiter: limiter}}
      end
    else
      {:ok, state}
    end
  end

  def check_and_update(state, _jid), do: {:ok, state}

  defp enforce_global(limiter, runtime_cfg, now_ms) do
    mps = Config.get(runtime_cfg, [:throttle, :global, :messages_per_second], 8.0)
    burst = Config.get(runtime_cfg, [:throttle, :global, :burst], 16)

    bucket = limiter.global || %{tokens: burst * 1.0, last_ms: now_ms}

    case consume_bucket(bucket, mps / 1_000.0, burst * 1.0, now_ms) do
      {:ok, updated_bucket} ->
        {:ok, %{limiter | global: updated_bucket}}

      {:error, retry_after_ms} ->
        {:error, {:global, retry_after_ms}}
    end
  end

  defp enforce_entity(limiter, runtime_cfg, jid, now_ms) do
    per_jid_limit = Config.get(runtime_cfg, [:throttle, :per_jid, :messages_per_minute], 20)
    per_group_limit = Config.get(runtime_cfg, [:throttle, :per_group, :messages_per_minute], 30)
    normalized = normalize_jid(jid)

    if group_jid?(normalized) do
      key = normalize_group_jid(normalized)
      bucket = Map.get(limiter.per_group, key, %{tokens: per_group_limit * 1.0, last_ms: now_ms})

      case consume_bucket(bucket, per_group_limit / 60_000.0, per_group_limit * 1.0, now_ms) do
        {:ok, updated_bucket} ->
          {:ok, %{limiter | per_group: Map.put(limiter.per_group, key, updated_bucket)}}

        {:error, retry_after_ms} ->
          {:error, {:per_group, retry_after_ms}}
      end
    else
      key = normalize_entity_jid(normalized)
      bucket = Map.get(limiter.per_jid, key, %{tokens: per_jid_limit * 1.0, last_ms: now_ms})

      case consume_bucket(bucket, per_jid_limit / 60_000.0, per_jid_limit * 1.0, now_ms) do
        {:ok, updated_bucket} ->
          {:ok, %{limiter | per_jid: Map.put(limiter.per_jid, key, updated_bucket)}}

        {:error, retry_after_ms} ->
          {:error, {:per_jid, retry_after_ms}}
      end
    end
  end

  defp enforce_min_delay(limiter, runtime_cfg, now_ms) do
    min_delay = Config.get(runtime_cfg, [:throttle, :min_delay_ms], 150)
    jitter = Config.get(runtime_cfg, [:throttle, :jitter_ms], 120)
    required = min_delay + random_jitter(jitter)

    case limiter.last_send_at_ms do
      nil ->
        {:ok, limiter}

      last_ms ->
        elapsed = now_ms - last_ms

        if elapsed >= required do
          {:ok, limiter}
        else
          {:error, {:min_delay, max(required - elapsed, 1)}}
        end
    end
  end

  defp consume_bucket(%{tokens: tokens, last_ms: last_ms}, refill_per_ms, burst, now_ms)
       when is_float(tokens) do
    elapsed = max(now_ms - last_ms, 0)
    replenished = min(burst, tokens + elapsed * refill_per_ms)

    if replenished >= 1.0 do
      {:ok, %{tokens: replenished - 1.0, last_ms: now_ms}}
    else
      missing = 1.0 - replenished
      retry_after_ms = max(Float.ceil(missing / max(refill_per_ms, 1.0e-9)) |> trunc(), 1)
      {:error, retry_after_ms}
    end
  end

  defp normalize_limit_error({:error, {scope, retry_after_ms}}, runtime_cfg) do
    max_delay = Config.get(runtime_cfg, [:throttle, :max_delay_ms], 30_000)
    retry_after_ms = min(max(retry_after_ms, 1), max_delay)
    {{:rate_limited, scope, retry_after_ms}, retry_after_ms}
  end

  defp random_jitter(jitter_ms) when is_integer(jitter_ms) and jitter_ms > 0 do
    :rand.uniform(jitter_ms) - 1
  end

  defp random_jitter(_), do: 0

  defp normalize_entity_jid(jid) do
    jid
    |> String.replace(~r/:\d+@/, "@")
    |> normalize_jid()
  end

  defp normalize_group_jid(jid) do
    jid
    |> String.replace(~r/:\d+@/, "@")
    |> normalize_jid()
  end

  defp normalize_jid(jid) when is_binary(jid), do: String.trim(jid)
  defp normalize_jid(_), do: ""

  defp group_jid?(jid), do: String.ends_with?(jid, "@g.us")

  defp now_ms, do: System.monotonic_time(:millisecond)
end
