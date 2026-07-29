defmodule ExWapp.Session.RetryCountersTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Session.RetryCounters

  test "keeps the newest counters when the cap is exceeded" do
    # A peer with a desynced session adds one counter per undecryptable
    # message and nothing ever removes them, so the map must be bounded or the
    # session leaks for the life of the process.
    max = RetryCounters.max_entries()

    state =
      Enum.reduce(1..(max + 10), %{retry_counters: %{}}, fn n, state ->
        RetryCounters.put(state, "key|#{n}", 1)
      end)

    assert map_size(state.retry_counters) == max
    assert length(state.retry_counter_order) == max
    refute Map.has_key?(state.retry_counters, "key|1")
    assert Map.has_key?(state.retry_counters, "key|#{max + 10}")
  end

  test "updating an existing counter does not duplicate its order entry" do
    state =
      %{retry_counters: %{}}
      |> RetryCounters.put("key|a", 1)
      |> RetryCounters.put("key|a", 2)

    assert state.retry_counters == %{"key|a" => 2}
    assert state.retry_counter_order == ["key|a"]
  end
end
