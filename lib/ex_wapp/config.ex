defmodule ExWapp.Config do
  @moduledoc false

  alias ExWapp.Config.Validator

  @default_client_version %{primary: 2, secondary: 3000, tertiary: 1_041_540_217}

  @type runtime_cfg :: map()
  @type client_version :: %{
          required(:primary) => pos_integer(),
          required(:secondary) => pos_integer(),
          required(:tertiary) => pos_integer()
        }

  @spec default_client_version() :: client_version()
  def default_client_version, do: @default_client_version

  @spec defaults() :: runtime_cfg()
  def defaults do
    %{
      reconnect: %{
        enabled: true,
        max_attempts: 12,
        initial_backoff_ms: 1_000,
        backoff_multiplier: 2.0,
        max_backoff_ms: 300_000,
        jitter_ms: 1_000,
        stop_on_session_invalid: true
      },
      health: %{
        check_interval_ms: 30_000
      },
      iq: %{
        default_timeout_ms: 30_000,
        prekey_timeout_ms: 30_000,
        usync_timeout_ms: 15_000,
        group_info_timeout_ms: 15_000,
        max_pending_requests: 1_000
      },
      send: %{
        max_outgoing_retry_attempts: 2,
        confirm_timeout_ms: 6_000,
        max_silent_drop_fallback_attempts: 1,
        retry_backoff_ms: [1_000, 3_000, 7_000]
      },
      send_error_guard: %{
        enabled: false,
        max_consecutive_errors: 3,
        max_errors_per_minute: 20,
        max_drops_per_minute: 10,
        action: :stop_session,
        notify_only: false
      },
      queue: %{
        max_size: 10_000,
        drop_policy: :reject_new,
        flush_batch_size: 100,
        flush_tick_ms: 10
      },
      throttle: %{
        enabled: true,
        global: %{
          messages_per_second: 8.0,
          burst: 16
        },
        per_jid: %{
          messages_per_minute: 20
        },
        per_group: %{
          messages_per_minute: 30
        },
        min_delay_ms: 150,
        jitter_ms: 120,
        on_limit: :delay,
        max_delay_ms: 30_000
      },
      quota: %{
        enabled: true,
        per_session: %{
          daily_messages: 5_000
        },
        per_jid: %{
          daily_messages: 500
        },
        per_group: %{
          daily_messages: 1_000
        },
        reset_timezone: "UTC",
        on_exceeded: :block
      },
      prekeys: %{
        initial_prekey_count: 812,
        refill_prekey_count: 50,
        min_threshold: 5,
        upload_cooldown_ms: 120_000
      },
      signal: %{
        session_max_age_ms: :timer.hours(12),
        device_cache_max_age_ms: :timer.hours(24 * 14)
      },
      app_state: %{
        initial_sync_enabled: true,
        initial_sync_gate_ms: 180_000
      },
      protocol: %{
        strict_mode: false,
        client_version: @default_client_version,
        post_auth_digest_enabled: false,
        pairing_device_props: %{
          os: "whatsmeow",
          platform_type: 0,
          require_full_sync: false,
          version: %{
            primary: 0,
            secondary: 1,
            tertiary: 0
          },
          history_sync_config: %{
            storage_quota_mb: 10_240,
            inline_initial_payload_in_e2ee_msg: true,
            support_call_log_history: false,
            support_bot_user_agent_chat_history: true,
            support_cag_reactions_and_polls: true,
            support_biz_hosted_msg: true,
            support_recent_sync_chunk_message_count_tuning: true,
            support_hosted_group_msg: true,
            support_fbid_bot_chat_history: true,
            support_message_association: true,
            support_group_history: false
          }
        },
        user_agent: %{
          os_version: "Linux x86_64",
          manufacturer: "Mozilla",
          device_name: "Firefox",
          os_build: "Linux",
          locale_language: "en",
          locale_country: "US"
        },
        allow_relaxed_adv_decode: true,
        fail_on_unknown_critical_node: false,
        capture_unknown_nodes: true
      },
      safety: %{
        enabled: true,
        max_401_events_per_hour: 1,
        max_403_events_per_hour: 1,
        max_stream_replaced_per_hour: 3,
        cooloff_on_rate_signal_ms: 900_000,
        disable_send_on_forbidden: true
      },
      compliance: %{
        strict_mode: true,
        require_explicit_opt_in: true,
        enforce_opt_out: true,
        high_risk_fanout: %{
          max_new_jids_per_hour: 20,
          max_groups_per_hour: 10,
          max_mentions_per_hour: 200
        },
        on_violation: :block
      },
      adaptive_governor: %{
        enabled: true,
        baseline_mps: 8.0,
        min_mps: 1.0,
        degrade_step: 0.2,
        recovery_step: 0.05,
        signal_weights: %{
          unauthorized: 1.0,
          forbidden: 1.0,
          stream_replaced: 0.5,
          delivery_anomaly: 0.4,
          retry_spike: 0.3
        }
      },
      risk: %{
        enabled: true,
        block_threshold: 80,
        decay_per_minute: 2,
        manual_unblock_required: true,
        cooloff_ms: 3_600_000,
        weights: %{
          unauthorized: 40,
          forbidden: 60,
          stream_replaced: 25,
          rate_limited: 10,
          retry_spike: 10,
          delivery_anomaly: 15
        }
      },
      canary: %{
        enabled: false,
        interval_ms: 900_000,
        recipients: [],
        checks: %{
          login: true,
          send_text: true,
          send_media: false,
          group_send: false
        },
        fail_fast_consecutive_failures: 2
      },
      release_gates: %{
        enabled: true,
        remote_kill_switch: false,
        rollback_profile: :last_known_good,
        feature_flags: %{},
        blocked_features: []
      },
      auth_guard: %{
        max_repair_attempts_per_hour: 3,
        max_reauth_attempts_per_day: 10,
        reauth_cooldown_ms: 300_000,
        re_pair_cooldown_ms: 1_800_000
      },
      protocol_health: %{
        enabled: true,
        alert_thresholds: %{
          bad_mac_per_minute: 20,
          prekey_miss_per_minute: 20,
          session_mismatch_per_minute: 20
        }
      },
      hygiene: %{
        enabled: true,
        prevent_concurrent_store_use: true,
        enforce_stable_resource: true,
        max_fingerprint_changes_per_day: 1
      },
      enforcement: %{
        enabled: true,
        snapshot_on_signals: [:unauthorized, :forbidden, :stream_replaced, :device_removed],
        include_runtime_config: true,
        capture_last_events: 200,
        max_snapshot_bytes: 262_144
      }
    }
  end

  @spec resolve(keyword()) :: {:ok, runtime_cfg()} | {:error, term()}
  def resolve(opts) when is_list(opts) do
    app_runtime =
      :ex_wapp
      |> Application.get_env(:runtime, %{})
      |> normalize_container()

    session_runtime =
      opts
      |> Keyword.get(:runtime, %{})
      |> normalize_container()

    cfg =
      defaults()
      |> put_in([:signal, :session_max_age_ms], :timer.hours(3))
      |> deep_merge(app_runtime)
      |> deep_merge_runtime(session_runtime)
      |> apply_legacy_overrides(opts)
      |> normalize_protocol_client_version()

    case Validator.validate(cfg) do
      :ok -> {:ok, cfg}
      {:error, _} = error -> error
    end
  end

  def resolve(_), do: {:error, {:invalid_runtime_config, :opts_must_be_keyword}}

  @spec get(map(), [term()], term()) :: term()
  def get(cfg, path, default \\ nil)

  def get(cfg, [head | tail], default) when is_map(cfg) do
    case cfg do
      %{^head => nested} when tail != [] -> get(nested, tail, default)
      %{^head => value} -> value
      _ -> default
    end
  end

  def get(_cfg, _path, default), do: default

  defp apply_legacy_overrides(cfg, opts) do
    cfg
    |> maybe_put_in([:reconnect, :enabled], Keyword.get(opts, :reconnect))
    |> maybe_put_in([:reconnect, :max_attempts], Keyword.get(opts, :max_reconnect_attempts))
    |> maybe_put_in([:health, :check_interval_ms], Keyword.get(opts, :health_check_interval_ms))
    |> maybe_put_in(
      [:send, :max_outgoing_retry_attempts],
      Keyword.get(opts, :max_outgoing_retry_attempts)
    )
    |> maybe_put_in(
      [:send, :confirm_timeout_ms],
      Keyword.get(opts, :silent_drop_confirm_timeout_ms)
    )
    |> maybe_put_in([:iq, :default_timeout_ms], Keyword.get(opts, :iq_timeout_ms))
    |> maybe_put_in([:iq, :max_pending_requests], Keyword.get(opts, :max_pending_iqs))
    |> maybe_put_in([:queue, :max_size], Keyword.get(opts, :queue_max_size))
    |> maybe_put_in([:queue, :drop_policy], Keyword.get(opts, :queue_drop_policy))
    |> maybe_put_normalized_client_version(Keyword.get(opts, :client_version))
    |> maybe_put_normalized_client_version(Keyword.get(opts, :wa_version))
  end

  defp maybe_put_in(cfg, _path, nil), do: cfg

  defp maybe_put_in(cfg, [head], value), do: Map.put(cfg, head, value)

  defp maybe_put_in(cfg, [head | tail], value) do
    nested = cfg |> Map.get(head, %{}) |> maybe_put_in(tail, value)
    Map.put(cfg, head, nested)
  end

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _k, l, r ->
      deep_merge(l, r)
    end)
  end

  defp deep_merge(_left, right), do: right

  defp deep_merge_runtime(cfg, %{protocol: %{pairing_device_props: _props}} = runtime) do
    cfg
    |> put_in(
      [:protocol, :pairing_device_props],
      get_in(runtime, [:protocol, :pairing_device_props])
    )
    |> deep_merge(Map.update!(runtime, :protocol, &Map.delete(&1, :pairing_device_props)))
  end

  defp deep_merge_runtime(cfg, runtime), do: deep_merge(cfg, runtime)

  defp maybe_put_normalized_client_version(cfg, nil), do: cfg

  defp maybe_put_normalized_client_version(cfg, version) do
    version = normalize_container(version)

    case normalize_client_version(version) do
      {:ok, normalized} -> maybe_put_in(cfg, [:protocol, :client_version], normalized)
      :error -> maybe_put_in(cfg, [:protocol, :client_version], version)
    end
  end

  defp normalize_protocol_client_version(cfg) when is_map(cfg) do
    case get(cfg, [:protocol, :client_version]) do
      nil ->
        cfg

      version ->
        case normalize_client_version(version) do
          {:ok, normalized} -> maybe_put_in(cfg, [:protocol, :client_version], normalized)
          :error -> cfg
        end
    end
  end

  defp normalize_protocol_client_version(cfg), do: cfg

  defp normalize_client_version(%{primary: p, secondary: s, tertiary: t})
       when is_integer(p) and is_integer(s) and is_integer(t) do
    {:ok, %{primary: p, secondary: s, tertiary: t}}
  end

  defp normalize_client_version(%{"primary" => p, "secondary" => s, "tertiary" => t})
       when is_integer(p) and is_integer(s) and is_integer(t) do
    {:ok, %{primary: p, secondary: s, tertiary: t}}
  end

  defp normalize_client_version({p, s, t})
       when is_integer(p) and is_integer(s) and is_integer(t) do
    {:ok, %{primary: p, secondary: s, tertiary: t}}
  end

  defp normalize_client_version(version) when is_binary(version) do
    case String.split(version, ".", parts: 3) do
      [p, s, t] ->
        with {primary, ""} <- Integer.parse(p),
             {secondary, ""} <- Integer.parse(s),
             {tertiary, ""} <- Integer.parse(t) do
          {:ok, %{primary: primary, secondary: secondary, tertiary: tertiary}}
        else
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp normalize_client_version(_), do: :error

  defp normalize_container(container) when is_list(container) do
    if Keyword.keyword?(container) do
      container
      |> Enum.into(%{}, fn {k, v} -> {k, normalize_container(v)} end)
    else
      container
    end
  end

  defp normalize_container(container) when is_map(container) do
    Enum.into(container, %{}, fn {k, v} -> {k, normalize_container(v)} end)
  end

  defp normalize_container(value), do: value
end
