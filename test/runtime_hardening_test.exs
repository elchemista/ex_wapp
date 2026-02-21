defmodule ExWapp.RuntimeHardeningTest do
  use ExUnit.Case, async: false

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
        runtime: [
          reconnect: [max_attempts: 3],
          compliance: [strict_mode: false],
          risk: [block_threshold: 70]
        ]
      )

    cfg = ExWapp.runtime_config(session)
    assert get_in(cfg, [:reconnect, :max_attempts]) == 3
    assert get_in(cfg, [:compliance, :strict_mode]) == false
    assert get_in(cfg, [:risk, :block_threshold]) == 70

    status = ExWapp.policy_status(session)
    assert is_map(status.safety)

    GenServer.stop(session)
  end

  test "send health counters track errors and reset on success" do
    {:ok, session} =
      ExWapp.start_link(
        store: ExWapp.Store.Memory,
        runtime: [send_error_guard: [enabled: false]]
      )

    send(session, {:send_result, "15550001111@s.whatsapp.net", "x", {:error, :boom}, :primary, 0})
    :timer.sleep(25)

    health_1 = ExWapp.health_status(session)
    assert health_1.send_errors_total == 1
    assert health_1.consecutive_send_errors == 1

    send(
      session,
      {:send_result, "15550001111@s.whatsapp.net", "x", {:ok, "msg_ok_1"}, :primary, 0}
    )

    :timer.sleep(25)
    health_2 = ExWapp.health_status(session)
    assert health_2.consecutive_send_errors == 0

    GenServer.stop(session)
  end

  test "guard can hard-stop worker after max consecutive send errors" do
    {:ok, session} =
      GenServer.start(ExWapp.Session.Worker,
        store: ExWapp.Store.Memory,
        runtime: [
          send_error_guard: [
            enabled: true,
            max_consecutive_errors: 3,
            max_errors_per_minute: 100,
            max_drops_per_minute: 100,
            action: :stop_session,
            notify_only: false
          ]
        ]
      )

    mon = Process.monitor(session)

    for _ <- 1..3 do
      send(
        session,
        {:send_result, "15550001111@s.whatsapp.net", "x", {:error, :boom}, :primary, 0}
      )
    end

    assert_receive {:DOWN, ^mon, :process, ^session,
                    {:send_error_guard_trip, {:max_consecutive_errors, 3}}},
                   1_000
  end

  test "pubsub control can pause/resume sends and emits health events" do
    session_id = "health_ctrl_#{System.unique_integer([:positive])}"

    {:ok, session} =
      ExWapp.start_link(
        session_id: session_id,
        store: ExWapp.Store.Memory,
        runtime: [send_error_guard: [enabled: false]]
      )

    :ok = Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:health:#{session_id}")

    :ok = ExWapp.control_session(session_id, :pause_sends)

    assert_receive {:ex_wapp_health, :control, %{action: :pause_sends}}, 1_000
    eventually(fn -> assert ExWapp.health_status(session).paused == true end)

    assert {:error, :send_paused} =
             ExWapp.send_message(session, "15550001111@s.whatsapp.net", "hi")

    :ok = ExWapp.control_session(session_id, :resume_sends)
    assert_receive {:ex_wapp_health, :control, %{action: :resume_sends}}, 1_000
    eventually(fn -> assert ExWapp.health_status(session).paused == false end)

    GenServer.stop(session)
  end

  defp eventually(fun, attempts \\ 25)

  defp eventually(fun, attempts) when attempts > 0 do
    fun.()
  rescue
    e in ExUnit.AssertionError ->
      if attempts == 1 do
        reraise e, __STACKTRACE__
      else
        :timer.sleep(20)
        eventually(fun, attempts - 1)
      end
  end
end
