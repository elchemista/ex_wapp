defmodule ExWapp.CallSyncRecoveryTest do
  use ExUnit.Case, async: true
  alias ExWapp.{Call, Chat, Store}
  alias ExWapp.AppState.Engine
  alias ExWapp.Test.FaultStore
  @peer "123@s.whatsapp.net"

  test "old call maps are normalized and malformed entries do not hide valid history" do
    store =
      Store.Memory.new(
        initial_data: %{
          call_log: %{
            "old" => %{id: "old", chat_jid: @peer, status: :missed, start_time: 10},
            "bad" => :invalid
          }
        }
      )

    assert [%Call{id: "old"}] = Call.list(store, jid: "", limit: :invalid, offset: :invalid)
    assert {:ok, %Call{id: "old"}} = Call.get(store, "old")
    assert :ok = Call.delete_by_peer(store, nil)
    {:ok, peer} = ExWapp.JID.parse(@peer)
    assert :ok = Call.delete_by_peer(store, peer)
    assert Call.list(store) == []
    Store.put(store, :call_log, :invalid_old_snapshot)
    assert Call.list(store) == []
    assert Call.default_max_records() > 0
  end

  test "a missing or stopped session supports offline call projection without crashing" do
    pid = spawn(fn -> :ok end)
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, :process, ^pid, _}

    for target <- [nil, :invalid, pid] do
      assert Call.list(target) == []
      assert Call.count(target) == 0
      assert Call.clear(target) == :ok
      assert Call.delete_by_peer(target, @peer) == :ok
      assert {:ok, %Call{id: "offline"}} = Call.upsert(target, %Call{id: "offline"})
    end
  end

  test "store outages preserve existing call records and synchronized deletes are retryable" do
    store = FaultStore.new()
    {:ok, _} = Call.upsert(store, %Call{id: "saved", chat_jid: @peer, is_incoming: true})
    FaultStore.arm(store, :get_and_update, {:return, {:error, :unavailable}})
    assert {:error, :unavailable} = Call.upsert(store, %Call{id: "new"})
    assert {:ok, %Call{id: "saved"}} = Call.get(store, "saved")
    FaultStore.arm(store, :update, {:return, {:error, :unavailable}})

    assert :ignored =
             Engine.dispatch_mutation(store, ["delete_individual_call_log", @peer], nil)

    assert {:ok, %Call{id: "saved"}} = Call.get(store, "saved")
    assert :ok = Engine.dispatch_mutation(store, ["delete_individual_call_log", @peer], nil)
    assert Call.list(store) == []
  end

  test "absent action payloads and REMOVE mutations cannot reset stored chat preferences" do
    store = Store.Memory.new()
    Chat.get_or_create(store, @peer)
    Chat.update_pinned(store, @peer, true)
    Chat.update_archived(store, @peer, true)
    before = Store.load!(store)

    for index <- [
          ["contact", @peer],
          ["archive", @peer],
          ["pin_v1", @peer],
          ["mute", @peer],
          ["markChatAsRead", @peer],
          ["call_log"],
          ["delete_individual_call_log"]
        ] do
      assert :ignored = Engine.dispatch_mutation(store, 0, index, nil)

      if hd(index) != "contact",
        do: assert(:ignored == Engine.dispatch_mutation(store, 1, index, nil))
    end

    assert Store.load!(store) == before
    assert :ignored = Engine.dispatch_mutation(store, 0, ["pin_v1", @peer], :invalid)

    assert :ok =
             Engine.apply_outgoing_patch(store, Engine.build_pin(@peer, false))

    assert {:ok, %{pinned: false, archived: true}} = Chat.get(store, @peer)
  end

  test "a failing mutation is isolated so later acknowledged mutations can still apply" do
    store = FaultStore.new()
    Chat.get_or_create(store, @peer)
    FaultStore.arm(store, :update, :raise)
    patch = Engine.build_pin(@peer, true)
    assert :ok = Engine.apply_outgoing_patch(store, patch)
    assert {:ok, %{pinned: false}} = Chat.get(store, @peer)
    assert :ok = Engine.apply_outgoing_patch(store, patch)
    assert {:ok, %{pinned: true}} = Chat.get(store, @peer)
  end
end
