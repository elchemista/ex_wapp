defmodule ExWapp.RateLimiterTest do
  @moduledoc """
  Coverage for the outbound token buckets.

  This is the last thing between a caller's send loop and WhatsApp's own
  flood protection, so its failure modes are asymmetric: letting one message
  through early costs nothing, while charging for sends that never happened
  tightens the throttle on a client that is already being told to wait.
  """

  use ExUnit.Case, async: true

  alias ExWapp.RateLimiter

  @jid "15550001111@s.whatsapp.net"
  @other_jid "15550002222@s.whatsapp.net"
  @group "120363000000000000@g.us"

  defp config(overrides) do
    throttle =
      Map.merge(
        %{
          enabled: true,
          min_delay_ms: 0,
          jitter_ms: 0,
          max_delay_ms: 30_000,
          global: %{messages_per_second: 1000.0, burst: 1000},
          per_jid: %{messages_per_minute: 1000},
          per_group: %{messages_per_minute: 1000}
        },
        Map.new(overrides)
      )

    %{throttle: throttle}
  end

  defp state(overrides \\ []) do
    %{runtime_cfg: config(overrides), rate_limiter: RateLimiter.new()}
  end

  defp send_n(state, jid, count) do
    Enum.reduce(1..count, {state, []}, fn _attempt, {current, results} ->
      case RateLimiter.check_and_update(current, jid) do
        {:ok, updated} -> {updated, [:ok | results]}
        {:error, reason, updated} -> {updated, [reason | results]}
      end
    end)
    |> then(fn {final, results} -> {final, Enum.reverse(results)} end)
  end

  describe "throttling can be turned off" do
    test "a disabled throttle passes every send through untouched" do
      state = state(enabled: false)

      {final, results} = send_n(state, @jid, 50)

      assert Enum.all?(results, &(&1 == :ok))
      assert final.rate_limiter == RateLimiter.new()
    end
  end

  describe "burst and refill" do
    test "the global burst bounds how many sends go out back to back" do
      state = state(global: %{messages_per_second: 1.0, burst: 3})

      {_final, results} = send_n(state, @jid, 5)

      assert Enum.take(results, 3) == [:ok, :ok, :ok]
      assert [{:rate_limited, :global, _}, {:rate_limited, :global, _}] = Enum.drop(results, 3)
    end

    test "an exhausted bucket recovers as time passes" do
      state = state(global: %{messages_per_second: 1.0, burst: 1})

      {spent, [:ok, {:rate_limited, :global, _}]} = send_n(state, @jid, 2)

      # Two seconds of refill at one message per second, applied by moving the
      # bucket's clock back rather than by sleeping.
      recovered = rewind_global(spent, 2_000)

      assert {:ok, _state} = RateLimiter.check_and_update(recovered, @jid)
    end

    test "refill never exceeds the configured burst" do
      state = state(global: %{messages_per_second: 100.0, burst: 2})

      {spent, _results} = send_n(state, @jid, 2)

      # An hour of idle time must not bank more than the burst allows.
      {_final, results} = spent |> rewind_global(3_600_000) |> send_n(@jid, 3)

      assert Enum.take(results, 2) == [:ok, :ok]
      assert [{:rate_limited, :global, _}] = Enum.drop(results, 2)
    end
  end

  describe "a rejected send is not charged for" do
    test "a send blocked by the minimum delay leaves the buckets untouched" do
      # The stages run in order and the state only advances when all of them
      # agree. If a rejection at the last stage still spent a global and a
      # per-recipient token, a caller retrying a blocked send would drive
      # itself into a deeper throttle than the limits describe.
      state = state(min_delay_ms: 100_000, global: %{messages_per_second: 1.0, burst: 5})

      {after_first, [:ok]} = send_n(state, @jid, 1)
      buckets = {after_first.rate_limiter.global, after_first.rate_limiter.per_jid}

      {after_blocked, results} = send_n(after_first, @jid, 5)

      assert Enum.all?(results, &match?({:rate_limited, :min_delay, _}, &1))
      assert {after_blocked.rate_limiter.global, after_blocked.rate_limiter.per_jid} == buckets
    end

    test "a send blocked by the recipient limit does not spend a global token" do
      state =
        state(global: %{messages_per_second: 1.0, burst: 50}, per_jid: %{messages_per_minute: 1})

      {after_first, [:ok]} = send_n(state, @jid, 1)
      global_before = after_first.rate_limiter.global

      {after_blocked, [{:rate_limited, :per_jid, _}]} = send_n(after_first, @jid, 1)

      assert after_blocked.rate_limiter.global == global_before
    end
  end

  describe "bucket identity" do
    test "each recipient gets its own allowance" do
      state = state(per_jid: %{messages_per_minute: 1})

      {after_first, [:ok]} = send_n(state, @jid, 1)

      assert {:ok, _state} = RateLimiter.check_and_update(after_first, @other_jid)
    end

    test "devices of one recipient share a single allowance" do
      # Fanout sends to every device of a contact. Counting each device
      # separately would multiply the effective per-recipient rate by the number
      # of devices that contact happens to have linked.
      state = state(per_jid: %{messages_per_minute: 1})

      {after_first, [:ok]} = send_n(state, @jid, 1)

      assert {:error, {:rate_limited, :per_jid, _}, _state} =
               RateLimiter.check_and_update(after_first, "15550001111:2@s.whatsapp.net")

      assert map_size(after_first.rate_limiter.per_jid) == 1
    end

    test "groups draw on the group limit rather than the recipient limit" do
      state = state(per_jid: %{messages_per_minute: 1}, per_group: %{messages_per_minute: 3})

      {final, results} = send_n(state, @group, 4)

      assert Enum.take(results, 3) == [:ok, :ok, :ok]
      assert [{:rate_limited, :per_group, _}] = Enum.drop(results, 3)
      assert final.rate_limiter.per_jid == %{}
    end
  end

  describe "retry hints" do
    test "the reported wait is positive and within the configured ceiling" do
      state =
        state(
          max_delay_ms: 500,
          min_delay_ms: 100_000,
          global: %{messages_per_second: 0.001, burst: 1}
        )

      {after_first, [:ok]} = send_n(state, @jid, 1)

      assert {:error, {:rate_limited, _scope, retry_after_ms}, _state} =
               RateLimiter.check_and_update(after_first, @jid)

      assert retry_after_ms > 0
      assert retry_after_ms <= 500
    end

    test "a non-binary target is let through rather than crashing the send" do
      assert {:ok, state} = RateLimiter.check_and_update(state(), nil)
      assert state.rate_limiter == RateLimiter.new()
    end
  end

  # The limiter reads a monotonic clock it does not expose, so age a bucket by
  # moving its own timestamp backwards instead of waiting in real time.
  defp rewind_global(state, by_ms) do
    update_in(state.rate_limiter.global, fn bucket ->
      %{bucket | last_ms: bucket.last_ms - by_ms}
    end)
  end
end
