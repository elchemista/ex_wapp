defmodule ExWapp.StoreIncrementalHistoryTest do
  use ExUnit.Case, async: true
  alias ExWapp.Store.{Ets, Memory}

  test "a failed history rollback cannot be reset through application snapshots", %{path: path} do
    store = Ets.new(path: path, history_storage: :incremental)
    reason = {:history_rollback_failed, :eio}
    :ets.insert(store.runtime_table, {:history_write_error, reason})
    assert {:error, ^reason} = Ets.persist(store, %{user: "updated"})
    assert {:error, ^reason} = Ets.transaction(store, fn _ -> %{user: "replaced"} end)
    assert {:ok, data} = Ets.load(store)
    refute Map.has_key?(data, :history_write_error)
    assert {:error, ^reason} = Ets.close(store)
  end

  test "migration refuses a conflicting or incomplete pre-history backup", %{path: path} do
    File.write!(path, "complete snapshot")
    File.write!(path <> ".pre-history", "partial")
    assert {:error, :snapshot_backup_conflict} = ExWapp.Store.FileSync.preserve_snapshot(path)
    assert File.read!(path) == "complete snapshot"
    assert File.read!(path <> ".pre-history") == "partial"
  end

  test "a globally named session can claim a store only once" do
    store = Memory.new()
    name = {__MODULE__, make_ref()}
    {:ok, session} = Agent.start_link(fn -> nil end, name: {:global, name})
    assert :ok = Agent.get(session, fn _ -> ExWapp.Store.SessionClaim.claim(store.agent) end)
    assert_raise ArgumentError, fn -> ExWapp.Store.SessionClaim.claim(store.agent) end
    Agent.stop(session)
    Memory.stop(store)
  end

  setup do
    dir = Path.join(System.tmp_dir!(), "ex_wapp_history_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    %{path: Path.join(dir, "session.etf"), dir: dir}
  end

  test "incremental history survives reopen, status updates, deletes and a torn final append", %{
    path: path
  } do
    jid = "15550001111@s.whatsapp.net"
    store = Ets.new(path: path, history_storage: :incremental)

    assert :ok =
             Ets.upsert_messages(store, jid, [
               %{id: "one", timestamp: 1, text: "hello"},
               %{id: "two", timestamp: 2}
             ])

    assert :ok = Ets.update_message_status_by_id(store, "one", :delivered)
    assert :ok = Ets.delete_messages(store, jid, ["two"])
    assert :ok = Ets.close(store)
    File.write!(path <> ".history", <<0, 0, 0>>, [:append])

    reopened = Ets.new(path: path)
    assert %{text: "hello", status: :delivered} = Ets.find_message(reopened, jid, "one")
    assert Ets.find_message(reopened, jid, "two") == nil
    assert :ok = Ets.upsert_messages(reopened, jid, [%{id: "three", timestamp: 3}])
    assert :ok = Ets.close(reopened)

    final = Ets.new(path: path)
    assert %{id: "three"} = Ets.find_message(final, jid, "three")
    Ets.close(final)
  end

  test "explicit migration keeps the original snapshot and exports back to snapshot mode", %{
    path: path,
    dir: dir
  } do
    jid = "15550001111@s.whatsapp.net"
    store = Ets.new(path: path)
    Ets.upsert_messages(store, jid, [%{id: "original", timestamp: 1, text: "retained"}])
    Ets.close(store)
    original = File.read!(path)

    migrated = Ets.new(path: path, history_storage: :incremental)
    assert File.read!(path <> ".pre-history") == original
    Ets.close(migrated)
    assert {:ok, data} = Ets.load_path(path)

    clone_path = Path.join(dir, "clone.etf")
    clone = Ets.new(path: clone_path)
    assert :ok = Ets.persist(clone, data)
    Ets.close(clone)
    clone = Ets.new(path: clone_path)
    assert %{text: "retained"} = Ets.find_message(clone, jid, "original")
    refute File.exists?(clone_path <> ".history")
    Ets.close(clone)
  end

  test "startup retention does not resurrect pruned history when the limit is removed", %{
    path: path
  } do
    jid = "15550001111@s.whatsapp.net"
    store = Ets.new(path: path, history_storage: :incremental)
    Ets.upsert_messages(store, jid, for(i <- 1..3, do: %{id: "m#{i}", timestamp: i}))
    Ets.close(store)

    bounded = Ets.new(path: path, max_messages_per_chat: 1)
    Ets.close(bounded)
    reopened = Ets.new(path: path)
    assert Enum.map(Ets.stream_messages(reopened, jid, []), & &1.id) == ["m3"]
    Ets.close(reopened)
  end

  test "the path lock rejects aliases and is released on close", %{path: path, dir: dir} do
    store = Ets.new(path: path)
    Ets.persist(store, %{paired: true})
    alias_path = Path.join(dir, "alias.etf")
    File.ln_s!(path, alias_path)
    assert_raise RuntimeError, fn -> Ets.new(path: alias_path) end
    Ets.close(store)
    reopened = Ets.new(path: alias_path)
    Ets.close(reopened)
  end

  test "ID index follows replacement, multiple chats, deletions and memory-store shutdown" do
    store = Memory.new()
    a = "1@s.whatsapp.net"
    b = "2@s.whatsapp.net"
    Memory.upsert_messages(store, a, [%{id: "same", timestamp: 1}])
    Memory.upsert_messages(store, a, [%{id: "same", timestamp: 2, text: "replacement"}])
    Memory.upsert_messages(store, b, [%{id: "same", timestamp: 3}])
    Memory.update_message_status_by_id(store, "same", :read)
    assert %{timestamp: 2, status: :read} = Memory.find_message(store, a, "same")
    assert %{status: :read} = Memory.find_message(store, b, "same")
    Memory.update_message_status_by_id(store, "same", :failed)
    assert %{status: :read} = Memory.find_message(store, b, "same")
    Memory.delete_chat_messages(store, a)
    assert {^b, %{id: "same"}} = Memory.find_message_by_id(store, "same")
    table = store.message_table.id_index_table
    Memory.stop(store)
    assert :ets.info(table) == :undefined
  end
end
