defmodule ExWapp.SessionFreshnessTest do
  @moduledoc """
  Coverage for dropping Signal sessions that have stopped being usable.

  A session that this device keeps encrypting on while the peer answers nothing
  is what a desync looks like from the inside: the peer discarded its half and
  re-initiated, this device never adopted the replacement, and the server refuses
  every send with `<ack error="463">`. The send path cannot tell that apart from
  a healthy conversation — it has a session, it uses it — so the judgement is
  made at connect, where a stale local view is expected anyway.
  """

  use ExUnit.Case, async: true

  alias ExWapp.Session.Worker
  alias ExWapp.Signal.SessionStore
  alias ExWapp.Store
  alias ExWapp.Store.Memory

  @peer "15550007777@s.whatsapp.net"
  @other "15550008888@s.whatsapp.net"

  @an_hour :timer.hours(1)

  describe "one-way session eviction" do
    test "drops a session with sends and no replies once it is old enough" do
      store = SessionStore.new() |> SessionStore.put_session(@peer, one_way_session())

      assert {pruned, [@peer]} =
               SessionStore.evict_one_way_sessions(store, @an_hour, hours_from_now(2))

      assert SessionStore.list_sessions(pruned) == []
    end

    test "keeps a session the peer has answered on" do
      # Traffic in both directions proves the ratchet is shared. Dropping those
      # would force a needless prekey fetch on every reconnect for every live
      # conversation, and burn a one-time key of the peer's each time.
      store = SessionStore.new() |> SessionStore.put_session(@peer, two_way_session())

      assert {pruned, []} =
               SessionStore.evict_one_way_sessions(store, @an_hour, hours_from_now(2))

      assert SessionStore.list_sessions(pruned) == [@peer]
    end

    test "keeps a one-way session that is still young" do
      # A message sent a minute ago that has not been answered yet is the normal
      # state of every new conversation, not a broken one.
      store = SessionStore.new() |> SessionStore.put_session(@peer, one_way_session())

      assert {_pruned, []} =
               SessionStore.evict_one_way_sessions(store, @an_hour)
    end

    test "keeps a session that has never been used at all" do
      store = SessionStore.new() |> SessionStore.put_session(@peer, unused_session())

      assert {_pruned, []} =
               SessionStore.evict_one_way_sessions(store, @an_hour, hours_from_now(2))
    end

    test "treats a session with no timestamp as old" do
      # Timestamps are written on every store, so a session without one outlived
      # the process that made it — which is exactly the restored-snapshot case
      # this is meant to catch.
      store = Map.put(SessionStore.new(), :sessions, %{@peer => one_way_session()})

      assert {_pruned, [@peer]} = SessionStore.evict_one_way_sessions(store, @an_hour)
    end

    test "evicts nothing when the grace period is zero" do
      # Zero is the off switch, not an instant expiry.
      store = SessionStore.new() |> SessionStore.put_session(@peer, one_way_session())

      assert {_pruned, []} = SessionStore.evict_one_way_sessions(store, 0, hours_from_now(48))
    end

    test "leaves healthy peers alone while dropping the stuck one" do
      store =
        SessionStore.new()
        |> SessionStore.put_session(@peer, one_way_session())
        |> SessionStore.put_session(@other, two_way_session())

      assert {pruned, [@peer]} =
               SessionStore.evict_one_way_sessions(store, @an_hour, hours_from_now(2))

      assert SessionStore.list_sessions(pruned) == [@other]
    end
  end

  describe "worker connect" do
    test "prunes stuck sessions and persists the result" do
      # The eviction has to reach disk. Keeping it in memory only means the next
      # restart resurrects the very session that could not send.
      store = Memory.new([])
      on_exit(fn -> Memory.stop(store) end)

      sessions =
        Map.put(SessionStore.new(), :sessions, %{
          @peer => one_way_session(),
          @other => two_way_session()
        })

      state = connected_state(store, sessions)

      assert {:noreply, new_state} =
               Worker.handle_info({:connection_event, {:auth, :ready}}, state)

      assert SessionStore.list_sessions(new_state.signal_sessions) == [@other]
      assert SessionStore.list_sessions(Store.load_signal_sessions(store)) == [@other]
    end

    test "leaves the session store untouched when nothing is stuck" do
      store = Memory.new([])
      on_exit(fn -> Memory.stop(store) end)

      sessions = SessionStore.put_session(SessionStore.new(), @peer, two_way_session())
      state = connected_state(store, sessions)

      assert {:noreply, new_state} =
               Worker.handle_info({:connection_event, {:auth, :ready}}, state)

      assert SessionStore.list_sessions(new_state.signal_sessions) == [@peer]
    end

    test "drops every session when the deployment asks for a full reset" do
      # For a store that is restored from an external snapshot, no local session
      # is trustworthy on the way back up — including the ones that look healthy,
      # because the snapshot may predate traffic the peer already ratcheted past.
      store = Memory.new([])
      on_exit(fn -> Memory.stop(store) end)

      sessions =
        SessionStore.new()
        |> SessionStore.put_session(@peer, one_way_session())
        |> SessionStore.put_session(@other, two_way_session())

      state =
        store
        |> connected_state(sessions)
        |> Map.put(:runtime_cfg, %{signal: %{reset_sessions_on_connect: true}})

      assert {:noreply, new_state} =
               Worker.handle_info({:connection_event, {:auth, :ready}}, state)

      assert SessionStore.list_sessions(new_state.signal_sessions) == []
    end
  end

  defp connected_state(store, sessions) do
    %Worker{
      session_id: "freshness-test-#{System.unique_integer([:positive])}",
      store: store,
      signal_sessions: sessions,
      runtime_cfg: %{signal: %{evict_one_way_sessions_after_ms: @an_hour}}
    }
  end

  defp one_way_session do
    %{
      root_key: :crypto.strong_rand_bytes(32),
      sending_chain: %{counter: 1, key: :crypto.strong_rand_bytes(32)},
      receiving_chain: %{counter: 0, key: :crypto.strong_rand_bytes(32)}
    }
  end

  defp two_way_session do
    %{
      root_key: :crypto.strong_rand_bytes(32),
      sending_chain: %{counter: 1, key: :crypto.strong_rand_bytes(32)},
      receiving_chain: %{counter: 3, key: :crypto.strong_rand_bytes(32)}
    }
  end

  defp unused_session do
    %{
      root_key: :crypto.strong_rand_bytes(32),
      sending_chain: %{counter: 0, key: :crypto.strong_rand_bytes(32)},
      receiving_chain: nil
    }
  end

  defp hours_from_now(hours), do: System.system_time(:millisecond) + :timer.hours(hours)
end
