defmodule ExWapp.Session.Worker.SendHealthTest do
  use ExUnit.Case, async: true

  alias ExWapp.Session.Worker
  alias ExWapp.Session.Worker.SendHealth

  defp state(send_health \\ %{}) do
    %Worker{
      session_id: "send-health-test",
      send_health: Map.merge(SendHealth.default(), send_health)
    }
  end

  describe "guard_trigger_reason/2" do
    @metrics %{consecutive: 0, errors_min: 0, drops_min: 0}

    test "stays silent while every metric is below its threshold" do
      assert SendHealth.guard_trigger_reason(%{@metrics | consecutive: 2}, %{}) == nil
    end

    test "uses 3 / 20 / 10 when the guard is not configured" do
      assert {:max_consecutive_errors, 3} =
               SendHealth.guard_trigger_reason(%{@metrics | consecutive: 3}, %{})

      assert {:max_errors_per_minute, 20} =
               SendHealth.guard_trigger_reason(%{@metrics | errors_min: 20}, %{})

      assert {:max_drops_per_minute, 10} =
               SendHealth.guard_trigger_reason(%{@metrics | drops_min: 10}, %{})
    end

    test "honours configured thresholds" do
      cfg = %{max_consecutive_errors: 10, max_errors_per_minute: 100, max_drops_per_minute: 50}

      assert SendHealth.guard_trigger_reason(%{@metrics | consecutive: 9}, cfg) == nil

      assert {:max_consecutive_errors, 10} =
               SendHealth.guard_trigger_reason(%{@metrics | consecutive: 10}, cfg)
    end

    # The cond order is the policy: a consecutive-error streak is reported even
    # when the per-minute counters are also over the line.
    test "reports the consecutive streak first when several thresholds are crossed" do
      metrics = %{consecutive: 5, errors_min: 99, drops_min: 99}

      assert {:max_consecutive_errors, 5} = SendHealth.guard_trigger_reason(metrics, %{})
    end
  end

  describe "ensure_send_enabled/2" do
    test "lets a send through on a healthy session" do
      assert {:ok, _state} = SendHealth.ensure_send_enabled(state(), "15550001111@s.whatsapp.net")
    end

    test "refuses while paused and counts the refusal as a send error" do
      assert {:error, :send_paused, blocked} =
               SendHealth.ensure_send_enabled(
                 state(%{paused: true}),
                 "15550001111@s.whatsapp.net"
               )

      assert SendHealth.get(blocked, :consecutive_send_errors, 0) == 1
      assert SendHealth.get(blocked, :last_error_reason, nil) == :send_paused
    end

    test "hard_stopped takes precedence over paused" do
      assert {:error, :send_guard_hard_stopped, _} =
               SendHealth.ensure_send_enabled(
                 state(%{paused: true, hard_stopped: true}),
                 "15550001111@s.whatsapp.net"
               )
    end
  end

  describe "counters" do
    test "register_send_error/3 advances totals, streak and the error window" do
      after_one = SendHealth.register_send_error(state(), :boom, %{jid: "x@s.whatsapp.net"})

      assert SendHealth.get(after_one, :send_errors_total, 0) == 1
      assert SendHealth.get(after_one, :consecutive_send_errors, 0) == 1
      assert length(SendHealth.get(after_one, :errors_window_ms, [])) == 1

      after_two = SendHealth.register_send_error(after_one, :boom, %{})
      assert SendHealth.get(after_two, :consecutive_send_errors, 0) == 2
      assert length(SendHealth.get(after_two, :errors_window_ms, [])) == 2
    end

    test "a successful send clears only the streak, not the totals" do
      recovered =
        state()
        |> SendHealth.register_send_error(:boom, %{})
        |> SendHealth.clear_consecutive_send_errors()

      assert SendHealth.get(recovered, :consecutive_send_errors, 0) == 0
      assert SendHealth.get(recovered, :send_errors_total, 0) == 1
    end

    test "outbound-queue errors are counted apart from send errors" do
      queued = SendHealth.increment_outbound_queue_errors(state(), :closed)

      assert SendHealth.get(queued, :outbound_queue_errors_total, 0) == 1
      assert SendHealth.get(queued, :send_errors_total, 0) == 0
      assert SendHealth.get(queued, :last_error_reason, nil) == {:outbound_queue_error, :closed}
    end

    test "register_drop_timeout/3 feeds the drop window the guard reads" do
      dropped = SendHealth.register_drop_timeout(state(), "3EB0ABC", %{jid: "x@s.whatsapp.net"})

      assert SendHealth.get(dropped, :drops_total, 0) == 1
      assert SendHealth.guard_metrics(dropped).drops_min == 1
    end

    # Entries older than the one-minute window must not keep the guard tripped.
    test "the rolling windows forget entries older than a minute" do
      stale = System.monotonic_time(:millisecond) - 61_000

      pruned =
        state(%{errors_window_ms: [stale, stale]})
        |> SendHealth.register_send_error(:boom, %{})

      assert length(SendHealth.get(pruned, :errors_window_ms, [])) == 1
      assert SendHealth.guard_metrics(pruned).errors_min == 1
    end
  end

  test "guard_metrics/1 reads the three numbers the thresholds compare against" do
    metrics =
      state(%{consecutive_send_errors: 4, errors_window_ms: [1, 2, 3], drops_window_ms: [1]})
      |> SendHealth.guard_metrics()

    assert metrics == %{consecutive: 4, errors_min: 3, drops_min: 1}
  end
end
