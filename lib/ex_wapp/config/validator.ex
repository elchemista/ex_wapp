defmodule ExWapp.Config.Validator do
  @moduledoc false

  @spec validate(map()) :: :ok | {:error, term()}
  def validate(cfg) when is_map(cfg) do
    with :ok <- validate_reconnect(cfg),
         :ok <- validate_health(cfg),
         :ok <- validate_iq(cfg),
         :ok <- validate_send(cfg),
         :ok <- validate_queue(cfg),
         :ok <- validate_throttle(cfg),
         :ok <- validate_quota(cfg),
         :ok <- validate_safety(cfg),
         :ok <- validate_prekeys(cfg) do
      :ok
    end
  end

  def validate(_), do: {:error, {:invalid_runtime_config, :not_a_map}}

  defp validate_reconnect(cfg) do
    with :ok <- ensure_boolean(cfg, [:reconnect, :enabled]),
         :ok <- ensure_non_neg_integer(cfg, [:reconnect, :max_attempts]),
         :ok <- ensure_non_neg_integer(cfg, [:reconnect, :initial_backoff_ms]),
         :ok <- ensure_positive_number(cfg, [:reconnect, :backoff_multiplier]),
         :ok <- ensure_non_neg_integer(cfg, [:reconnect, :max_backoff_ms]),
         :ok <- ensure_non_neg_integer(cfg, [:reconnect, :jitter_ms]),
         :ok <- ensure_boolean(cfg, [:reconnect, :stop_on_session_invalid]) do
      :ok
    end
  end

  defp validate_health(cfg), do: ensure_positive_integer(cfg, [:health, :check_interval_ms])

  defp validate_iq(cfg) do
    with :ok <- ensure_positive_integer(cfg, [:iq, :default_timeout_ms]),
         :ok <- ensure_positive_integer(cfg, [:iq, :prekey_timeout_ms]),
         :ok <- ensure_positive_integer(cfg, [:iq, :usync_timeout_ms]),
         :ok <- ensure_positive_integer(cfg, [:iq, :group_info_timeout_ms]),
         :ok <- ensure_positive_integer(cfg, [:iq, :max_pending_requests]) do
      :ok
    end
  end

  defp validate_send(cfg) do
    with :ok <- ensure_non_neg_integer(cfg, [:send, :max_outgoing_retry_attempts]),
         :ok <- ensure_positive_integer(cfg, [:send, :confirm_timeout_ms]),
         :ok <- ensure_non_neg_integer(cfg, [:send, :max_silent_drop_fallback_attempts]),
         :ok <- ensure_list_of_positive_integers(cfg, [:send, :retry_backoff_ms]) do
      :ok
    end
  end

  defp validate_queue(cfg) do
    with :ok <- ensure_positive_integer(cfg, [:queue, :max_size]),
         :ok <- ensure_one_of(cfg, [:queue, :drop_policy], [:reject_new, :drop_oldest]),
         :ok <- ensure_positive_integer(cfg, [:queue, :flush_batch_size]),
         :ok <- ensure_positive_integer(cfg, [:queue, :flush_tick_ms]) do
      :ok
    end
  end

  defp validate_throttle(cfg) do
    with :ok <- ensure_boolean(cfg, [:throttle, :enabled]),
         :ok <- ensure_positive_number(cfg, [:throttle, :global, :messages_per_second]),
         :ok <- ensure_positive_integer(cfg, [:throttle, :global, :burst]),
         :ok <- ensure_positive_integer(cfg, [:throttle, :per_jid, :messages_per_minute]),
         :ok <- ensure_positive_integer(cfg, [:throttle, :per_group, :messages_per_minute]),
         :ok <- ensure_non_neg_integer(cfg, [:throttle, :min_delay_ms]),
         :ok <- ensure_non_neg_integer(cfg, [:throttle, :jitter_ms]),
         :ok <- ensure_one_of(cfg, [:throttle, :on_limit], [:delay, :reject]),
         :ok <- ensure_positive_integer(cfg, [:throttle, :max_delay_ms]) do
      :ok
    end
  end

  defp validate_quota(cfg) do
    with :ok <- ensure_boolean(cfg, [:quota, :enabled]),
         :ok <- ensure_positive_integer(cfg, [:quota, :per_session, :daily_messages]),
         :ok <- ensure_positive_integer(cfg, [:quota, :per_jid, :daily_messages]),
         :ok <- ensure_positive_integer(cfg, [:quota, :per_group, :daily_messages]),
         :ok <- ensure_binary(cfg, [:quota, :reset_timezone]),
         :ok <- ensure_one_of(cfg, [:quota, :on_exceeded], [:block, :warn_only]) do
      :ok
    end
  end

  defp validate_safety(cfg) do
    with :ok <- ensure_boolean(cfg, [:safety, :enabled]),
         :ok <- ensure_positive_integer(cfg, [:safety, :max_401_events_per_hour]),
         :ok <- ensure_positive_integer(cfg, [:safety, :max_403_events_per_hour]),
         :ok <- ensure_positive_integer(cfg, [:safety, :max_stream_replaced_per_hour]),
         :ok <- ensure_non_neg_integer(cfg, [:safety, :cooloff_on_rate_signal_ms]),
         :ok <- ensure_boolean(cfg, [:safety, :disable_send_on_forbidden]) do
      :ok
    end
  end

  defp validate_prekeys(cfg) do
    with :ok <- ensure_positive_integer(cfg, [:prekeys, :initial_prekey_count]),
         :ok <- ensure_positive_integer(cfg, [:prekeys, :refill_prekey_count]),
         :ok <- ensure_positive_integer(cfg, [:prekeys, :min_threshold]),
         :ok <- ensure_non_neg_integer(cfg, [:prekeys, :upload_cooldown_ms]) do
      :ok
    end
  end

  defp ensure_binary(cfg, path) do
    case fetch(cfg, path) do
      value when is_binary(value) -> :ok
      value -> {:error, {:invalid_runtime_config, path, value, :expected_binary}}
    end
  end

  defp ensure_boolean(cfg, path) do
    case fetch(cfg, path) do
      value when is_boolean(value) -> :ok
      value -> {:error, {:invalid_runtime_config, path, value, :expected_boolean}}
    end
  end

  defp ensure_positive_integer(cfg, path) do
    case fetch(cfg, path) do
      value when is_integer(value) and value > 0 -> :ok
      value -> {:error, {:invalid_runtime_config, path, value, :expected_positive_integer}}
    end
  end

  defp ensure_non_neg_integer(cfg, path) do
    case fetch(cfg, path) do
      value when is_integer(value) and value >= 0 -> :ok
      value -> {:error, {:invalid_runtime_config, path, value, :expected_non_neg_integer}}
    end
  end

  defp ensure_positive_number(cfg, path) do
    case fetch(cfg, path) do
      value when is_integer(value) and value > 0 -> :ok
      value when is_float(value) and value > 0.0 -> :ok
      value -> {:error, {:invalid_runtime_config, path, value, :expected_positive_number}}
    end
  end

  defp ensure_one_of(cfg, path, allowed) when is_list(allowed) do
    value = fetch(cfg, path)

    if value in allowed do
      :ok
    else
      {:error, {:invalid_runtime_config, path, value, {:expected_one_of, allowed}}}
    end
  end

  defp ensure_list_of_positive_integers(cfg, path) do
    value = fetch(cfg, path)

    cond do
      not is_list(value) ->
        {:error, {:invalid_runtime_config, path, value, :expected_list}}

      Enum.all?(value, fn v -> is_integer(v) and v > 0 end) ->
        :ok

      true ->
        {:error, {:invalid_runtime_config, path, value, :expected_list_of_positive_integers}}
    end
  end

  defp fetch(cfg, [head | tail]) do
    case cfg do
      %{^head => nested} when tail != [] -> fetch(nested, tail)
      %{^head => value} -> value
      _ -> nil
    end
  end
end
