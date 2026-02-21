defmodule ExWapp.Config do
  @moduledoc false

  alias ExWapp.Config.Validator

  @type runtime_cfg :: map()

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
      protocol: %{
        strict_mode: false,
        client_version: %{
          primary: 2,
          secondary: 3000,
          tertiary: 1_029_948_479
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
      |> deep_merge(app_runtime)
      |> deep_merge(session_runtime)
      |> apply_legacy_overrides(opts)

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
