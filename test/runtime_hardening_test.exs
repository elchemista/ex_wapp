defmodule ExWapp.RuntimeHardeningTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Config, Quota, RateLimiter}
  alias ExWapp.Session.Worker.{Resilience, Safety}

  test "config resolve applies legacy reconnect override" do
    {:ok, cfg} = Config.resolve(reconnect: false)
    assert get_in(cfg, [:reconnect, :enabled]) == false
  end

  test "resilience gives up once max attempts is reached" do
    state = %{
      reconnect_attempts: 1,
      session_invalid: false,
      opts: [],
      runtime_cfg: %{
        reconnect: %{
          enabled: true,
          max_attempts: 1,
          initial_backoff_ms: 1_000,
          backoff_multiplier: 2.0,
          max_backoff_ms: 60_000,
          jitter_ms: 0,
          stop_on_session_invalid: true
        }
      }
    }

    assert :give_up = Resilience.reconnect_decision(state)
  end

  test "rate limiter and quota can update worker-like state" do
    state = %{
      runtime_cfg:
        Config.defaults()
        |> put_in([:throttle, :global, :messages_per_second], 100.0)
        |> put_in([:throttle, :global, :burst], 100)
        |> put_in([:throttle, :per_jid, :messages_per_minute], 1000)
        |> put_in([:throttle, :per_group, :messages_per_minute], 1000)
        |> put_in([:throttle, :min_delay_ms], 0)
        |> put_in([:throttle, :jitter_ms], 0)
        |> put_in([:quota, :per_session, :daily_messages], 2),
      quota: Quota.new(Config.defaults()),
      rate_limiter: RateLimiter.new(),
      safety: Safety.new()
    }

    assert {:ok, state} = Quota.check_and_increment(state, "15550001111@s.whatsapp.net")
    assert {:ok, _state} = RateLimiter.check_and_update(state, "15550001111@s.whatsapp.net")
  end

  test "safety breaker can lock sends on forbidden" do
    state = %{
      runtime_cfg: Config.defaults(),
      safety: Safety.new()
    }

    state = Safety.record_signal(state, :forbidden)
    assert {:error, :forbidden_locked, _} = Safety.check_send_allowed(state)
  end

  test "session exposes runtime config and policy status" do
    {:ok, session} =
      ExWapp.start_link(
        store: ExWapp.Store.Memory,
        runtime: [reconnect: [max_attempts: 3]]
      )

    cfg = ExWapp.runtime_config(session)
    assert get_in(cfg, [:reconnect, :max_attempts]) == 3

    status = ExWapp.policy_status(session)
    assert is_map(status.safety)

    GenServer.stop(session)
  end
end
