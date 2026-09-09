defmodule ExWapp.AppStateLifecycleFailureTest do
  use ExUnit.Case, async: true
  alias ExWapp.Session.AppStateSync
  alias ExWapp.Test.FaultStore
  alias ExWapp.Store

  setup do
    store =
      FaultStore.new(
        initial_data: %{app_state_keys: %{"01" => %{data: <<1::256>>, timestamp: 1}}}
      )

    supervisor = start_supervised!(Task.Supervisor)
    id = "sync-failure-#{System.unique_integer([:positive])}"
    :ok = ExWapp.subscribe(id)
    %{store: store, supervisor: supervisor, id: id}
  end

  test "unexpected adapter errors finish initial sync with a visible failure", ctx do
    for action <- [:raise, :throw, :exit, {:return, {:error, :storage_down}}] do
      FaultStore.arm(ctx.store, :begin_batch, action)

      assert {:ok, task} =
               AppStateSync.refresh(ctx.supervisor, self(), ctx.store, [], :initial, ctx.id)

      assert_receive {:initial_sync_finished, ^task, :failed}, 1000
      assert_receive {:ex_wapp_session, :initial_sync, :failed, reason, %{session_id: id}}, 1000
      assert id == ctx.id
      assert is_tuple(reason)
      assert map_size(Store.get(ctx.store, :app_state_keys)) == 1
    end
  end

  test "a failed final flush reports failure even if every requested collection completed", ctx do
    FaultStore.arm(ctx.store, :finish_batch, {:return, {:error, :disk_full}})

    assert {:ok, task} =
             AppStateSync.refresh(ctx.supervisor, self(), ctx.store, [], :initial, ctx.id)

    assert_receive {:initial_sync_finished, ^task, :failed}, 1000

    assert_receive {:ex_wapp_session, :initial_sync, :failed,
                    {:final_store_flush_failed, :disk_full},
                    %{flush_reason: :disk_full, failures: []}},
                   1000

    assert {:ok, recovered} =
             AppStateSync.refresh(ctx.supervisor, self(), ctx.store, [], :initial, ctx.id)

    assert_receive {:initial_sync_finished, ^recovered, :completed}, 1000
    assert_receive {:ex_wapp_session, :initial_sync, :completed, %{success_count: 0}}, 1000
  end

  test "unavailable task supervisors return an error instead of leaving a synchronization gate",
       ctx do
    assert {:error, :task_supervisor_unavailable} =
             AppStateSync.refresh(nil, self(), ctx.store, [], :initial)

    supervisor = start_supervised!(%{id: :doomed, start: {Task.Supervisor, :start_link, [[]]}})
    stop_supervised(:doomed)

    assert {:error, {:task_supervisor_exit, _}} =
             AppStateSync.refresh(supervisor, self(), ctx.store, [], :initial)

    refute_receive {:initial_sync_finished, _, _}
  end

  test "collection read and session failures are isolated and reported with their collection",
       ctx do
    for action <- [:raise, :throw, :exit] do
      FaultStore.arm(ctx.store, :load, action)

      assert {:ok, task} =
               AppStateSync.refresh(
                 ctx.supervisor,
                 self(),
                 ctx.store,
                 ["regular_low"],
                 :initial,
                 ctx.id
               )

      assert_receive {:initial_sync_finished, ^task, :failed}, 1000

      assert_receive {:ex_wapp_session, :initial_sync, :failed,
                      {:collection_fetch_failed, [%{collection: "regular_low"}]}, _},
                     1000
    end

    for action <- [:raise, :throw, :exit] do
      FaultStore.arm(ctx.store, :load, action)
      refute AppStateSync.keys_available?(ctx.store)
    end

    assert AppStateSync.keys_available?(ctx.store)
  end
end
