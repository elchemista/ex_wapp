defmodule ExWapp.Config.Validator do
  @moduledoc false

  @spec validate(map()) :: :ok | {:error, term()}
  def validate(cfg) when is_map(cfg) do
    run_validations([
      fn -> validate_reconnect(cfg) end,
      fn -> validate_health(cfg) end,
      fn -> validate_iq(cfg) end,
      fn -> validate_send(cfg) end,
      fn -> validate_signal(cfg) end,
      fn -> validate_app_state(cfg) end,
      fn -> validate_send_error_guard(cfg) end,
      fn -> validate_queue(cfg) end,
      fn -> validate_throttle(cfg) end,
      fn -> validate_quota(cfg) end,
      fn -> validate_protocol(cfg) end,
      fn -> validate_safety(cfg) end,
      fn -> validate_prekeys(cfg) end,
      fn -> validate_compliance(cfg) end,
      fn -> validate_adaptive_governor(cfg) end,
      fn -> validate_risk(cfg) end,
      fn -> validate_canary(cfg) end,
      fn -> validate_release_gates(cfg) end,
      fn -> validate_auth_guard(cfg) end,
      fn -> validate_protocol_health(cfg) end,
      fn -> validate_hygiene(cfg) end,
      fn -> validate_enforcement(cfg) end
    ])
  end

  def validate(_), do: {:error, {:invalid_runtime_config, :not_a_map}}

  defp validate_reconnect(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:reconnect, :enabled]) end,
      fn -> ensure_non_neg_integer(cfg, [:reconnect, :max_attempts]) end,
      fn -> ensure_non_neg_integer(cfg, [:reconnect, :initial_backoff_ms]) end,
      fn -> ensure_positive_number(cfg, [:reconnect, :backoff_multiplier]) end,
      fn -> ensure_non_neg_integer(cfg, [:reconnect, :max_backoff_ms]) end,
      fn -> ensure_non_neg_integer(cfg, [:reconnect, :jitter_ms]) end,
      fn -> ensure_boolean(cfg, [:reconnect, :stop_on_session_invalid]) end
    ])
  end

  defp validate_health(cfg), do: ensure_positive_integer(cfg, [:health, :check_interval_ms])

  defp validate_iq(cfg) do
    run_validations([
      fn -> ensure_positive_integer(cfg, [:iq, :default_timeout_ms]) end,
      fn -> ensure_positive_integer(cfg, [:iq, :prekey_timeout_ms]) end,
      fn -> ensure_positive_integer(cfg, [:iq, :usync_timeout_ms]) end,
      fn -> ensure_positive_integer(cfg, [:iq, :group_info_timeout_ms]) end,
      fn -> ensure_positive_integer(cfg, [:iq, :max_pending_requests]) end
    ])
  end

  defp validate_send(cfg) do
    run_validations([
      fn -> ensure_non_neg_integer(cfg, [:send, :max_outgoing_retry_attempts]) end,
      fn -> ensure_positive_integer(cfg, [:send, :confirm_timeout_ms]) end,
      fn -> ensure_non_neg_integer(cfg, [:send, :max_silent_drop_fallback_attempts]) end,
      fn -> ensure_list_of_positive_integers(cfg, [:send, :retry_backoff_ms]) end,
      fn -> ensure_non_neg_integer(cfg, [:send, :max_session_repair_attempts]) end,
      fn -> ensure_list_of_non_neg_integers(cfg, [:send, :session_repair_backoff_ms]) end
    ])
  end

  defp validate_signal(cfg) do
    run_validations([
      fn -> ensure_positive_integer(cfg, [:signal, :session_max_age_ms]) end,
      fn -> ensure_positive_integer(cfg, [:signal, :device_cache_max_age_ms]) end,
      fn -> ensure_non_neg_integer(cfg, [:signal, :evict_one_way_sessions_after_ms]) end,
      fn -> ensure_boolean(cfg, [:signal, :reset_sessions_on_connect]) end
    ])
  end

  defp validate_app_state(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:app_state, :initial_sync_enabled]) end
    ])
  end

  defp validate_send_error_guard(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:send_error_guard, :enabled]) end,
      fn -> ensure_positive_integer(cfg, [:send_error_guard, :max_consecutive_errors]) end,
      fn -> ensure_positive_integer(cfg, [:send_error_guard, :max_errors_per_minute]) end,
      fn -> ensure_positive_integer(cfg, [:send_error_guard, :max_drops_per_minute]) end,
      fn ->
        ensure_one_of(cfg, [:send_error_guard, :action], [
          :none,
          :pause,
          :disconnect,
          :stop_session
        ])
      end,
      fn -> ensure_boolean(cfg, [:send_error_guard, :notify_only]) end
    ])
  end

  defp validate_queue(cfg) do
    run_validations([
      fn -> ensure_positive_integer(cfg, [:queue, :max_size]) end,
      fn -> ensure_one_of(cfg, [:queue, :drop_policy], [:reject_new, :drop_oldest]) end,
      fn -> ensure_positive_integer(cfg, [:queue, :flush_batch_size]) end,
      fn -> ensure_positive_integer(cfg, [:queue, :flush_tick_ms]) end
    ])
  end

  defp validate_throttle(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:throttle, :enabled]) end,
      fn -> ensure_positive_number(cfg, [:throttle, :global, :messages_per_second]) end,
      fn -> ensure_positive_integer(cfg, [:throttle, :global, :burst]) end,
      fn -> ensure_positive_integer(cfg, [:throttle, :per_jid, :messages_per_minute]) end,
      fn -> ensure_positive_integer(cfg, [:throttle, :per_group, :messages_per_minute]) end,
      fn -> ensure_non_neg_integer(cfg, [:throttle, :min_delay_ms]) end,
      fn -> ensure_non_neg_integer(cfg, [:throttle, :jitter_ms]) end,
      fn -> ensure_one_of(cfg, [:throttle, :on_limit], [:delay, :reject]) end,
      fn -> ensure_positive_integer(cfg, [:throttle, :max_delay_ms]) end
    ])
  end

  defp validate_quota(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:quota, :enabled]) end,
      fn -> ensure_positive_integer(cfg, [:quota, :per_session, :daily_messages]) end,
      fn -> ensure_positive_integer(cfg, [:quota, :per_jid, :daily_messages]) end,
      fn -> ensure_positive_integer(cfg, [:quota, :per_group, :daily_messages]) end,
      fn -> ensure_binary(cfg, [:quota, :reset_timezone]) end,
      fn -> ensure_one_of(cfg, [:quota, :on_exceeded], [:block, :warn_only]) end
    ])
  end

  defp validate_protocol(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:protocol, :strict_mode]) end,
      fn -> ensure_one_of(cfg, [:protocol, :client_mode], [:web, :android]) end,
      fn -> ensure_boolean(cfg, [:protocol, :post_auth_digest_enabled]) end,
      fn -> ensure_positive_integer(cfg, [:protocol, :client_version, :primary]) end,
      fn -> ensure_positive_integer(cfg, [:protocol, :client_version, :secondary]) end,
      fn -> ensure_positive_integer(cfg, [:protocol, :client_version, :tertiary]) end,
      fn -> ensure_binary(cfg, [:protocol, :pairing_device_props, :os]) end,
      fn -> ensure_non_neg_integer(cfg, [:protocol, :pairing_device_props, :platform_type]) end,
      fn -> ensure_boolean(cfg, [:protocol, :pairing_device_props, :require_full_sync]) end,
      fn ->
        ensure_optional_non_neg_integer(cfg, [
          :protocol,
          :pairing_device_props,
          :version,
          :primary
        ])
      end,
      fn ->
        ensure_optional_non_neg_integer(cfg, [
          :protocol,
          :pairing_device_props,
          :version,
          :secondary
        ])
      end,
      fn ->
        ensure_optional_non_neg_integer(cfg, [
          :protocol,
          :pairing_device_props,
          :version,
          :tertiary
        ])
      end,
      fn ->
        ensure_optional_non_neg_integer(
          cfg,
          [:protocol, :pairing_device_props, :history_sync_config, :storage_quota_mb]
        )
      end,
      fn ->
        ensure_optional_boolean(
          cfg,
          [
            :protocol,
            :pairing_device_props,
            :history_sync_config,
            :inline_initial_payload_in_e2ee_msg
          ]
        )
      end,
      fn ->
        ensure_optional_boolean(
          cfg,
          [:protocol, :pairing_device_props, :history_sync_config, :support_call_log_history]
        )
      end,
      fn ->
        ensure_optional_boolean(
          cfg,
          [
            :protocol,
            :pairing_device_props,
            :history_sync_config,
            :support_bot_user_agent_chat_history
          ]
        )
      end,
      fn ->
        ensure_optional_boolean(
          cfg,
          [
            :protocol,
            :pairing_device_props,
            :history_sync_config,
            :support_cag_reactions_and_polls
          ]
        )
      end,
      fn ->
        ensure_optional_boolean(
          cfg,
          [:protocol, :pairing_device_props, :history_sync_config, :support_biz_hosted_msg]
        )
      end,
      fn ->
        ensure_optional_boolean(
          cfg,
          [
            :protocol,
            :pairing_device_props,
            :history_sync_config,
            :support_recent_sync_chunk_message_count_tuning
          ]
        )
      end,
      fn ->
        ensure_optional_boolean(
          cfg,
          [:protocol, :pairing_device_props, :history_sync_config, :support_hosted_group_msg]
        )
      end,
      fn ->
        ensure_optional_boolean(
          cfg,
          [
            :protocol,
            :pairing_device_props,
            :history_sync_config,
            :support_fbid_bot_chat_history
          ]
        )
      end,
      fn ->
        ensure_optional_boolean(
          cfg,
          [
            :protocol,
            :pairing_device_props,
            :history_sync_config,
            :support_message_association
          ]
        )
      end,
      fn ->
        ensure_optional_boolean(
          cfg,
          [:protocol, :pairing_device_props, :history_sync_config, :support_group_history]
        )
      end,
      fn -> ensure_binary(cfg, [:protocol, :user_agent, :os_version]) end,
      fn -> ensure_binary(cfg, [:protocol, :user_agent, :manufacturer]) end,
      fn -> ensure_binary(cfg, [:protocol, :user_agent, :device_name]) end,
      fn -> ensure_binary(cfg, [:protocol, :user_agent, :os_build]) end,
      fn -> ensure_binary(cfg, [:protocol, :user_agent, :locale_language]) end,
      fn -> ensure_binary(cfg, [:protocol, :user_agent, :locale_country]) end,
      fn -> ensure_boolean(cfg, [:protocol, :allow_relaxed_adv_decode]) end,
      fn -> ensure_boolean(cfg, [:protocol, :fail_on_unknown_critical_node]) end,
      fn -> ensure_boolean(cfg, [:protocol, :capture_unknown_nodes]) end
    ])
  end

  defp validate_safety(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:safety, :enabled]) end,
      fn -> ensure_positive_integer(cfg, [:safety, :max_401_events_per_hour]) end,
      fn -> ensure_positive_integer(cfg, [:safety, :max_403_events_per_hour]) end,
      fn -> ensure_positive_integer(cfg, [:safety, :max_stream_replaced_per_hour]) end,
      fn -> ensure_non_neg_integer(cfg, [:safety, :cooloff_on_rate_signal_ms]) end,
      fn -> ensure_boolean(cfg, [:safety, :disable_send_on_forbidden]) end
    ])
  end

  defp validate_compliance(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:compliance, :strict_mode]) end,
      fn -> ensure_boolean(cfg, [:compliance, :require_explicit_opt_in]) end,
      fn -> ensure_boolean(cfg, [:compliance, :enforce_opt_out]) end,
      fn ->
        ensure_positive_integer(cfg, [:compliance, :high_risk_fanout, :max_new_jids_per_hour])
      end,
      fn ->
        ensure_positive_integer(cfg, [:compliance, :high_risk_fanout, :max_groups_per_hour])
      end,
      fn ->
        ensure_positive_integer(cfg, [:compliance, :high_risk_fanout, :max_mentions_per_hour])
      end,
      fn -> ensure_one_of(cfg, [:compliance, :on_violation], [:block, :warn_only]) end
    ])
  end

  defp validate_adaptive_governor(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:adaptive_governor, :enabled]) end,
      fn -> ensure_positive_number(cfg, [:adaptive_governor, :baseline_mps]) end,
      fn -> ensure_positive_number(cfg, [:adaptive_governor, :min_mps]) end,
      fn -> ensure_positive_number(cfg, [:adaptive_governor, :degrade_step]) end,
      fn -> ensure_positive_number(cfg, [:adaptive_governor, :recovery_step]) end,
      fn -> ensure_positive_number(cfg, [:adaptive_governor, :signal_weights, :unauthorized]) end,
      fn -> ensure_positive_number(cfg, [:adaptive_governor, :signal_weights, :forbidden]) end,
      fn ->
        ensure_positive_number(cfg, [:adaptive_governor, :signal_weights, :stream_replaced])
      end,
      fn ->
        ensure_positive_number(cfg, [:adaptive_governor, :signal_weights, :delivery_anomaly])
      end,
      fn -> ensure_positive_number(cfg, [:adaptive_governor, :signal_weights, :retry_spike]) end
    ])
  end

  defp validate_risk(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:risk, :enabled]) end,
      fn -> ensure_positive_integer(cfg, [:risk, :block_threshold]) end,
      fn -> ensure_non_neg_integer(cfg, [:risk, :decay_per_minute]) end,
      fn -> ensure_boolean(cfg, [:risk, :manual_unblock_required]) end,
      fn -> ensure_non_neg_integer(cfg, [:risk, :cooloff_ms]) end,
      fn -> ensure_positive_integer(cfg, [:risk, :weights, :unauthorized]) end,
      fn -> ensure_positive_integer(cfg, [:risk, :weights, :forbidden]) end,
      fn -> ensure_positive_integer(cfg, [:risk, :weights, :stream_replaced]) end,
      fn -> ensure_positive_integer(cfg, [:risk, :weights, :rate_limited]) end,
      fn -> ensure_positive_integer(cfg, [:risk, :weights, :retry_spike]) end,
      fn -> ensure_positive_integer(cfg, [:risk, :weights, :delivery_anomaly]) end
    ])
  end

  defp validate_canary(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:canary, :enabled]) end,
      fn -> ensure_positive_integer(cfg, [:canary, :interval_ms]) end,
      fn -> ensure_list_of_binaries(cfg, [:canary, :recipients]) end,
      fn -> ensure_boolean(cfg, [:canary, :checks, :login]) end,
      fn -> ensure_boolean(cfg, [:canary, :checks, :send_text]) end,
      fn -> ensure_boolean(cfg, [:canary, :checks, :send_media]) end,
      fn -> ensure_boolean(cfg, [:canary, :checks, :group_send]) end,
      fn -> ensure_positive_integer(cfg, [:canary, :fail_fast_consecutive_failures]) end
    ])
  end

  defp validate_release_gates(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:release_gates, :enabled]) end,
      fn -> ensure_boolean(cfg, [:release_gates, :remote_kill_switch]) end,
      fn ->
        ensure_one_of(cfg, [:release_gates, :rollback_profile], [
          :last_known_good,
          :safe_mode,
          :none
        ])
      end,
      fn -> ensure_map(cfg, [:release_gates, :feature_flags]) end,
      fn -> ensure_list_of_atoms_or_binaries(cfg, [:release_gates, :blocked_features]) end
    ])
  end

  defp validate_auth_guard(cfg) do
    run_validations([
      fn -> ensure_positive_integer(cfg, [:auth_guard, :max_repair_attempts_per_hour]) end,
      fn -> ensure_positive_integer(cfg, [:auth_guard, :max_reauth_attempts_per_day]) end,
      fn -> ensure_non_neg_integer(cfg, [:auth_guard, :reauth_cooldown_ms]) end,
      fn -> ensure_non_neg_integer(cfg, [:auth_guard, :re_pair_cooldown_ms]) end
    ])
  end

  defp validate_protocol_health(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:protocol_health, :enabled]) end,
      fn ->
        ensure_non_neg_integer(cfg, [:protocol_health, :alert_thresholds, :bad_mac_per_minute])
      end,
      fn ->
        ensure_non_neg_integer(cfg, [:protocol_health, :alert_thresholds, :prekey_miss_per_minute])
      end,
      fn ->
        ensure_non_neg_integer(cfg, [
          :protocol_health,
          :alert_thresholds,
          :session_mismatch_per_minute
        ])
      end
    ])
  end

  defp validate_hygiene(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:hygiene, :enabled]) end,
      fn -> ensure_boolean(cfg, [:hygiene, :prevent_concurrent_store_use]) end,
      fn -> ensure_boolean(cfg, [:hygiene, :enforce_stable_resource]) end,
      fn -> ensure_non_neg_integer(cfg, [:hygiene, :max_fingerprint_changes_per_day]) end
    ])
  end

  defp validate_enforcement(cfg) do
    run_validations([
      fn -> ensure_boolean(cfg, [:enforcement, :enabled]) end,
      fn -> ensure_list_of_atoms(cfg, [:enforcement, :snapshot_on_signals]) end,
      fn -> ensure_boolean(cfg, [:enforcement, :include_runtime_config]) end,
      fn -> ensure_non_neg_integer(cfg, [:enforcement, :capture_last_events]) end,
      fn -> ensure_positive_integer(cfg, [:enforcement, :max_snapshot_bytes]) end
    ])
  end

  defp validate_prekeys(cfg) do
    run_validations([
      fn -> ensure_positive_integer(cfg, [:prekeys, :initial_prekey_count]) end,
      fn -> ensure_positive_integer(cfg, [:prekeys, :refill_prekey_count]) end,
      fn -> ensure_positive_integer(cfg, [:prekeys, :min_threshold]) end,
      fn -> ensure_non_neg_integer(cfg, [:prekeys, :upload_cooldown_ms]) end,
      fn -> ensure_nil_or_function(cfg, [:prekeys, :id_allocator], 2) end
    ])
  end

  # Caught here rather than at the first prekey mint: a misconfigured allocator
  # surfaces at session start, not hours later when the pool needs refilling.
  defp ensure_nil_or_function(cfg, path, arity) do
    case fetch(cfg, path) do
      nil -> :ok
      value when is_function(value, arity) -> :ok
      value -> {:error, {:invalid_runtime_config, path, value, {:expected_function, arity}}}
    end
  end

  defp run_validations(validations) when is_list(validations) do
    Enum.reduce_while(validations, :ok, fn validation, :ok ->
      case validation.() do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
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

  defp ensure_optional_boolean(cfg, path) do
    case fetch(cfg, path) do
      nil -> :ok
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

  defp ensure_optional_non_neg_integer(cfg, path) do
    case fetch(cfg, path) do
      nil -> :ok
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

  # Backoff schedules start at zero when the first attempt is meant to be
  # immediate, so this list admits it where a timeout never could.
  defp ensure_list_of_non_neg_integers(cfg, path) do
    value = fetch(cfg, path)

    cond do
      not is_list(value) ->
        {:error, {:invalid_runtime_config, path, value, :expected_list}}

      Enum.all?(value, fn v -> is_integer(v) and v >= 0 end) ->
        :ok

      true ->
        {:error, {:invalid_runtime_config, path, value, :expected_list_of_non_neg_integers}}
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
