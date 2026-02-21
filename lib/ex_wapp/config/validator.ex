defmodule ExWapp.Config.Validator do
  @moduledoc false

  @spec validate(map()) :: :ok | {:error, term()}
  def validate(cfg) when is_map(cfg) do
    with :ok <- validate_reconnect(cfg),
         :ok <- validate_health(cfg),
         :ok <- validate_iq(cfg),
         :ok <- validate_send(cfg),
         :ok <- validate_send_error_guard(cfg),
         :ok <- validate_queue(cfg),
         :ok <- validate_throttle(cfg),
         :ok <- validate_quota(cfg),
         :ok <- validate_protocol(cfg),
         :ok <- validate_safety(cfg),
         :ok <- validate_prekeys(cfg),
         :ok <- validate_compliance(cfg),
         :ok <- validate_adaptive_governor(cfg),
         :ok <- validate_risk(cfg),
         :ok <- validate_canary(cfg),
         :ok <- validate_release_gates(cfg),
         :ok <- validate_auth_guard(cfg),
         :ok <- validate_protocol_health(cfg),
         :ok <- validate_hygiene(cfg),
         :ok <- validate_enforcement(cfg) do
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

  defp validate_send_error_guard(cfg) do
    with :ok <- ensure_boolean(cfg, [:send_error_guard, :enabled]),
         :ok <- ensure_positive_integer(cfg, [:send_error_guard, :max_consecutive_errors]),
         :ok <- ensure_positive_integer(cfg, [:send_error_guard, :max_errors_per_minute]),
         :ok <- ensure_positive_integer(cfg, [:send_error_guard, :max_drops_per_minute]),
         :ok <-
           ensure_one_of(cfg, [:send_error_guard, :action], [
             :none,
             :pause,
             :disconnect,
             :stop_session
           ]),
         :ok <- ensure_boolean(cfg, [:send_error_guard, :notify_only]) do
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

  defp validate_protocol(cfg) do
    with :ok <- ensure_boolean(cfg, [:protocol, :strict_mode]),
         :ok <- ensure_positive_integer(cfg, [:protocol, :client_version, :primary]),
         :ok <- ensure_positive_integer(cfg, [:protocol, :client_version, :secondary]),
         :ok <- ensure_positive_integer(cfg, [:protocol, :client_version, :tertiary]),
         :ok <- ensure_binary(cfg, [:protocol, :user_agent, :os_version]),
         :ok <- ensure_binary(cfg, [:protocol, :user_agent, :manufacturer]),
         :ok <- ensure_binary(cfg, [:protocol, :user_agent, :device_name]),
         :ok <- ensure_binary(cfg, [:protocol, :user_agent, :os_build]),
         :ok <- ensure_binary(cfg, [:protocol, :user_agent, :locale_language]),
         :ok <- ensure_binary(cfg, [:protocol, :user_agent, :locale_country]),
         :ok <- ensure_boolean(cfg, [:protocol, :allow_relaxed_adv_decode]),
         :ok <- ensure_boolean(cfg, [:protocol, :fail_on_unknown_critical_node]),
         :ok <- ensure_boolean(cfg, [:protocol, :capture_unknown_nodes]) do
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

  defp validate_compliance(cfg) do
    with :ok <- ensure_boolean(cfg, [:compliance, :strict_mode]),
         :ok <- ensure_boolean(cfg, [:compliance, :require_explicit_opt_in]),
         :ok <- ensure_boolean(cfg, [:compliance, :enforce_opt_out]),
         :ok <-
           ensure_positive_integer(cfg, [:compliance, :high_risk_fanout, :max_new_jids_per_hour]),
         :ok <-
           ensure_positive_integer(cfg, [:compliance, :high_risk_fanout, :max_groups_per_hour]),
         :ok <-
           ensure_positive_integer(cfg, [:compliance, :high_risk_fanout, :max_mentions_per_hour]),
         :ok <- ensure_one_of(cfg, [:compliance, :on_violation], [:block, :warn_only]) do
      :ok
    end
  end

  defp validate_adaptive_governor(cfg) do
    with :ok <- ensure_boolean(cfg, [:adaptive_governor, :enabled]),
         :ok <- ensure_positive_number(cfg, [:adaptive_governor, :baseline_mps]),
         :ok <- ensure_positive_number(cfg, [:adaptive_governor, :min_mps]),
         :ok <- ensure_positive_number(cfg, [:adaptive_governor, :degrade_step]),
         :ok <- ensure_positive_number(cfg, [:adaptive_governor, :recovery_step]),
         :ok <- ensure_positive_number(cfg, [:adaptive_governor, :signal_weights, :unauthorized]),
         :ok <- ensure_positive_number(cfg, [:adaptive_governor, :signal_weights, :forbidden]),
         :ok <-
           ensure_positive_number(cfg, [:adaptive_governor, :signal_weights, :stream_replaced]),
         :ok <-
           ensure_positive_number(cfg, [:adaptive_governor, :signal_weights, :delivery_anomaly]),
         :ok <- ensure_positive_number(cfg, [:adaptive_governor, :signal_weights, :retry_spike]) do
      :ok
    end
  end

  defp validate_risk(cfg) do
    with :ok <- ensure_boolean(cfg, [:risk, :enabled]),
         :ok <- ensure_positive_integer(cfg, [:risk, :block_threshold]),
         :ok <- ensure_non_neg_integer(cfg, [:risk, :decay_per_minute]),
         :ok <- ensure_boolean(cfg, [:risk, :manual_unblock_required]),
         :ok <- ensure_non_neg_integer(cfg, [:risk, :cooloff_ms]),
         :ok <- ensure_positive_integer(cfg, [:risk, :weights, :unauthorized]),
         :ok <- ensure_positive_integer(cfg, [:risk, :weights, :forbidden]),
         :ok <- ensure_positive_integer(cfg, [:risk, :weights, :stream_replaced]),
         :ok <- ensure_positive_integer(cfg, [:risk, :weights, :rate_limited]),
         :ok <- ensure_positive_integer(cfg, [:risk, :weights, :retry_spike]),
         :ok <- ensure_positive_integer(cfg, [:risk, :weights, :delivery_anomaly]) do
      :ok
    end
  end

  defp validate_canary(cfg) do
    with :ok <- ensure_boolean(cfg, [:canary, :enabled]),
         :ok <- ensure_positive_integer(cfg, [:canary, :interval_ms]),
         :ok <- ensure_list_of_binaries(cfg, [:canary, :recipients]),
         :ok <- ensure_boolean(cfg, [:canary, :checks, :login]),
         :ok <- ensure_boolean(cfg, [:canary, :checks, :send_text]),
         :ok <- ensure_boolean(cfg, [:canary, :checks, :send_media]),
         :ok <- ensure_boolean(cfg, [:canary, :checks, :group_send]),
         :ok <- ensure_positive_integer(cfg, [:canary, :fail_fast_consecutive_failures]) do
      :ok
    end
  end

  defp validate_release_gates(cfg) do
    with :ok <- ensure_boolean(cfg, [:release_gates, :enabled]),
         :ok <- ensure_boolean(cfg, [:release_gates, :remote_kill_switch]),
         :ok <-
           ensure_one_of(cfg, [:release_gates, :rollback_profile], [
             :last_known_good,
             :safe_mode,
             :none
           ]),
         :ok <- ensure_map(cfg, [:release_gates, :feature_flags]),
         :ok <- ensure_list_of_atoms_or_binaries(cfg, [:release_gates, :blocked_features]) do
      :ok
    end
  end

  defp validate_auth_guard(cfg) do
    with :ok <- ensure_positive_integer(cfg, [:auth_guard, :max_repair_attempts_per_hour]),
         :ok <- ensure_positive_integer(cfg, [:auth_guard, :max_reauth_attempts_per_day]),
         :ok <- ensure_non_neg_integer(cfg, [:auth_guard, :reauth_cooldown_ms]),
         :ok <- ensure_non_neg_integer(cfg, [:auth_guard, :re_pair_cooldown_ms]) do
      :ok
    end
  end

  defp validate_protocol_health(cfg) do
    with :ok <- ensure_boolean(cfg, [:protocol_health, :enabled]),
         :ok <-
           ensure_non_neg_integer(cfg, [:protocol_health, :alert_thresholds, :bad_mac_per_minute]),
         :ok <-
           ensure_non_neg_integer(cfg, [
             :protocol_health,
             :alert_thresholds,
             :prekey_miss_per_minute
           ]),
         :ok <-
           ensure_non_neg_integer(cfg, [
             :protocol_health,
             :alert_thresholds,
             :session_mismatch_per_minute
           ]) do
      :ok
    end
  end

  defp validate_hygiene(cfg) do
    with :ok <- ensure_boolean(cfg, [:hygiene, :enabled]),
         :ok <- ensure_boolean(cfg, [:hygiene, :prevent_concurrent_store_use]),
         :ok <- ensure_boolean(cfg, [:hygiene, :enforce_stable_resource]),
         :ok <- ensure_non_neg_integer(cfg, [:hygiene, :max_fingerprint_changes_per_day]) do
      :ok
    end
  end

  defp validate_enforcement(cfg) do
    with :ok <- ensure_boolean(cfg, [:enforcement, :enabled]),
         :ok <- ensure_list_of_atoms(cfg, [:enforcement, :snapshot_on_signals]),
         :ok <- ensure_boolean(cfg, [:enforcement, :include_runtime_config]),
         :ok <- ensure_non_neg_integer(cfg, [:enforcement, :capture_last_events]),
         :ok <- ensure_positive_integer(cfg, [:enforcement, :max_snapshot_bytes]) do
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

  defp ensure_map(cfg, path) do
    case fetch(cfg, path) do
      value when is_map(value) -> :ok
      value -> {:error, {:invalid_runtime_config, path, value, :expected_map}}
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

  defp ensure_list_of_binaries(cfg, path) do
    value = fetch(cfg, path)

    cond do
      not is_list(value) ->
        {:error, {:invalid_runtime_config, path, value, :expected_list}}

      Enum.all?(value, &is_binary/1) ->
        :ok

      true ->
        {:error, {:invalid_runtime_config, path, value, :expected_list_of_binaries}}
    end
  end

  defp ensure_list_of_atoms(cfg, path) do
    value = fetch(cfg, path)

    cond do
      not is_list(value) ->
        {:error, {:invalid_runtime_config, path, value, :expected_list}}

      Enum.all?(value, &is_atom/1) ->
        :ok

      true ->
        {:error, {:invalid_runtime_config, path, value, :expected_list_of_atoms}}
    end
  end

  defp ensure_list_of_atoms_or_binaries(cfg, path) do
    value = fetch(cfg, path)

    cond do
      not is_list(value) ->
        {:error, {:invalid_runtime_config, path, value, :expected_list}}

      Enum.all?(value, &(is_atom(&1) or is_binary(&1))) ->
        :ok

      true ->
        {:error, {:invalid_runtime_config, path, value, :expected_list_of_atoms_or_binaries}}
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
