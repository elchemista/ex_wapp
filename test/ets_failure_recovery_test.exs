defmodule ExWapp.EtsFailureRecoveryTest do
  use ExUnit.Case, async: true
  alias ExWapp.Store
  alias ExWapp.Store.Ets
  @moduletag :tmp_dir
  @moduletag capture_log: true

  test "nested batches become durable at the outer boundary and preserve message updates", %{
    tmp_dir: dir
  } do
    path = Path.join(dir, "state.etf")
    store = Ets.new(path: path)

    try do
      :ok = Store.put(store, :marker, :before)
      before = File.read!(path)
      assert :ok = Store.begin_batch(store, :outer)
      assert :ok = Store.begin_batch(store, :inner)
      assert :ok = Store.put(store, :marker, :after)

      assert :ok =
               Store.upsert_messages(store, "chat", [
                 %{id: "a", timestamp: 1},
                 %{id: "b", timestamp: 2}
               ])

      assert :ok = Store.update_message_status(store, "chat", "a", :read)
      assert :ok = Store.finish_batch(store, :inner)
      assert File.read!(path) == before
      assert :ok = Store.finish_batch(store, :outer)
      refute File.read!(path) == before
      reopened = Ets.new(path: path)

      try do
        assert Store.get(reopened, :marker) == :after
        assert {"chat", %{id: "a", status: :read}} = Store.find_message_by_id(reopened, "a")
        assert :ok = Store.delete_messages(reopened, "chat", ["a"])
        assert nil == Store.find_message_by_id(reopened, "a")
        assert {:ok, %{chat_messages: %{"chat" => [%{id: "b"}]}}} = Store.snapshot(reopened)
      after
        Store.close(reopened)
      end

      assert {:error, :batch_not_started} = Store.finish_batch(store, :outer)
    after
      Store.close(store)
    end
  end

  test "failed atomic rename leaves the last snapshot readable and a later flush recovers", %{
    tmp_dir: dir
  } do
    path = Path.join(dir, "state.etf")
    backup = Path.join(dir, "last-good.etf")
    store = Ets.new(path: path)

    try do
      assert :ok = Store.put(store, :value, "old")
      File.rename!(path, backup)
      File.mkdir!(path)
      assert {:error, _} = Store.put(store, :value, "new")
      assert Store.get(store, :value) == "new"
      previous = Ets.new(path: backup)
      assert Store.get(previous, :value) == "old"
      Store.close(previous)
      File.rmdir!(path)
      assert :ok = Store.flush(store)
      recovered = Ets.new(path: path)
      assert Store.get(recovered, :value) == "new"
      Store.close(recovered)
      assert Path.wildcard(path <> ".tmp*") == []
    after
      Store.close(store)
    end
  end

  test "invalid transactions and callback exceptions leave data intact and writer alive", %{
    tmp_dir: dir
  } do
    store = Ets.new(path: Path.join(dir, "state.etf"))

    try do
      :ok = Store.put(store, :value, 1)
      assert :ok = Store.transaction(store, & &1)
      assert 1 = Store.get_and_update(store, :value, 0, &{&1, &1})
      assert {:error, _} = Store.transaction(store, fn _ -> :invalid end)
      assert {:error, _} = Store.get_and_update(store, :value, 0, fn _ -> :invalid end)
      assert {:error, _} = Store.update(store, :value, 0, fn _ -> raise "updater failed" end)
      assert {:error, _} = Store.update(store, :value, 0, fn _ -> throw(:aborted) end)
      assert {:error, _} = Store.read(store, fn _ -> exit(:read_aborted) end)
      assert Store.get(store, :value) == 1
      assert Process.alive?(store.writer)
      assert :ok = Store.update_message_status(store, "missing", "id", :read)
      assert :ok = Store.delete_messages(store, "missing", ["id"])
    after
      Store.close(store)
    end

    assert {:error, :store_closed} = Store.load(store)
    assert Ets.get(store, :value, :closed) == :closed
    assert :ok = Store.close(store)
  end

  test "device cache and Signal references survive serialization independently of chat payloads",
       %{tmp_dir: dir} do
    path = Path.join(dir, "state.etf")
    store = Ets.new(path: path)
    cache = %{"1555@s.whatsapp.net" => %{devices: %{"1555:1@s.whatsapp.net" => 123}}}

    try do
      assert :ok = Store.persist_device_cache(store, cache)
      assert Ets.get(store, :device_cache) == cache
      assert ExWapp.Signal.SessionStore.store?(Ets.get(store, :signal_sessions))
      assert :ok = Store.upsert_messages(store, "chat", [%{id: "one", timestamp: 1}])
      assert :ok = Store.persist_signal_sessions(store, ExWapp.Signal.SessionStore.new())
    after
      Store.close(store)
    end

    reopened = Ets.new(path: path)

    try do
      assert Store.load_device_cache(reopened) == cache
      assert [%{id: "one"}] = Store.list_messages(reopened, "chat")
      assert :ok = Store.clear(reopened)
      assert :ok = Store.clear(reopened)
      assert Store.load_device_cache(reopened) == %{}
      assert [] == Store.list_messages(reopened, "chat")
    after
      Store.close(reopened)
    end
  end

  test "corrupted on-disk snapshots fail explicitly instead of resetting identity", %{
    tmp_dir: dir
  } do
    path = Path.join(dir, "corrupt.etf")
    File.write!(path, <<0, 1, 2, 3>>)
    assert_raise RuntimeError, ~r/failed to load/, fn -> Ets.new(path: path) end
    assert File.read!(path) == <<0, 1, 2, 3>>
  end
end
