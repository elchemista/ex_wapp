defmodule ExWapp.Session.RetryCounters do
  @moduledoc """
  Bounded bookkeeping for the per-message retry counters in the session state.

  A counter is added for every inbound message that fails to decrypt and for
  every outbound retry or session repair, and nothing ever resolves them —
  deliberately, since `clear_pending_requests` must not forget attempt counts
  across a reconnect. Without a cap, a peer with a desynced session grows the
  session's heap by one permanent map entry per undecryptable message and the
  repair path scans all of them on every rejected ack.

  Keys are evicted oldest-first once the cap is reached. Losing an old counter
  merely re-opens a handful of extra retries for a message that has long been
  resolved, whereas an unbounded map grows for the life of the process.
  """

  @max_entries 2048

  @doc """
  Sets `key` to `count` in the state's `:retry_counters`, evicting the oldest
  counters beyond the cap.
  """
  @spec put(map(), String.t(), pos_integer()) :: map()
  def put(state, key, count) when is_map(state) and is_binary(key) do
    counters = Map.get(state, :retry_counters, %{})
    order = Map.get(state, :retry_counter_order, [])

    order = if Map.has_key?(counters, key), do: order, else: [key | order]
    counters = Map.put(counters, key, count)

    {counters, order} =
      if map_size(counters) > @max_entries do
        {keep, evict} = Enum.split(order, @max_entries)
        {Map.drop(counters, evict), keep}
      else
        {counters, order}
      end

    state
    |> Map.put(:retry_counters, counters)
    |> Map.put(:retry_counter_order, order)
  end

  @doc false
  @spec max_entries() :: pos_integer()
  def max_entries, do: @max_entries
end
