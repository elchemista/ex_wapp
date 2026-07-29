defmodule ExWapp.StoreTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Store
  alias ExWapp.Store.MessageTable

  @tmp_dir Path.join(System.tmp_dir!(), "ex_wapp_store_tests")

  setup do
    File.rm_rf(@tmp_dir)
    :ok = File.mkdir_p(@tmp_dir)
    on_exit(fn -> File.rm_rf(@tmp_dir) end)
    :ok
  end

  describe "Store.new/1" do
    test "creates default Ets store when given nil" do
      store = Store.new(nil)
      assert %Store.Ets{} = store
    end

    test "creates store from module name" do
      store = Store.new(Store.Memory)
      assert %Store.Memory{} = store
    end

    test "creates store from {module, opts} tuple" do
      path = Path.join(@tmp_dir, "custom.etf")
      store = Store.new({Store.Ets, path: path})
      assert %Store.Ets{path: ^path} = store
    end

    test "returns existing struct unchanged" do
      original = Store.Memory.new([])
      assert Store.new(original) == original
    end
  end

  describe "Store.Ets adapter" do
    test "persists and loads data" do
      path = Path.join(@tmp_dir, "session.etf")
      store = Store.new({Store.Ets, path: path})

      assert {:ok, %{}} = Store.load(store)

      payload = %{noise: %{client_static: <<1, 2, 3>>}}
      assert :ok = Store.persist(store, payload)
      assert {:ok, loaded} = Store.load(store)
      assert loaded.noise == payload.noise
      assert is_map(loaded.signal_sessions)
      assert loaded.device_cache == %{}
    end

    test "migrates legacy ETS files on load" do
      path = Path.join(@tmp_dir, "legacy.etf")
      table = :ets.new(:legacy_ex_wapp_store, [:set, :public])
      :ets.insert(table, {:data, %{legacy: true, bytes: <<0, 255, 1>>}})
      assert :ok = :ets.tab2file(table, String.to_charlist(path), sync: true)
      :ets.delete(table)

      store = Store.new({Store.Ets, path: path})

      assert {:ok, %{legacy: true, bytes: <<0, 255, 1>>}} = Store.load(store)

      assert {:ok, %{legacy: true, bytes: <<0, 255, 1>>}} =
               path |> File.read!() |> ExWapp.Store.Codec.decode()
    end

    test "load_path/1 reads codec-backed files" do
      path = Path.join(@tmp_dir, "codec_load_path.etf")

      payload = %{
        pairing: %{jid: "12025550123@s.whatsapp.net"},
        signal: %{prekeys: %{1 => <<1, 2, 3>>}}
      }

      assert {:ok, blob} = ExWapp.Store.Codec.encode(payload)
      assert :ok = File.write(path, blob)

      assert {:ok, ^payload} = Store.Ets.load_path(path)
    end

    test "load_path/1 reads legacy ETS files" do
      path = Path.join(@tmp_dir, "legacy_load_path.etf")
      table = :ets.new(:legacy_ex_wapp_load_path_store, [:set, :public])
      :ets.insert(table, {:data, %{legacy: true, bytes: <<0, 255, 1>>}})
      assert :ok = :ets.tab2file(table, String.to_charlist(path), sync: true)
      :ets.delete(table)

      assert {:ok, %{legacy: true, bytes: <<0, 255, 1>>}} = Store.Ets.load_path(path)
    end

    test "clears data" do
      path = Path.join(@tmp_dir, "clear_test.etf")
      store = Store.Ets.new(path: path)

      Store.persist(store, %{foo: "bar"})
      assert {:ok, %{foo: "bar"}} = Store.load(store)

      assert :ok = Store.clear(store)
      assert {:ok, %{}} = Store.load(store)
    end

    test "message streams survive reload outside chat metadata" do
      path = Path.join(@tmp_dir, "message_stream_test.etf")
      jid = "15550001111@s.whatsapp.net"
      store1 = Store.Ets.new(path: path)

      message = %{
        id: "persisted-message-1",
        from_me: false,
        timestamp: 10,
        text: "stored",
        status: :received,
        participant: nil,
        raw: nil
      }

      assert :ok = Store.upsert_messages(store1, jid, [message])
      assert {:ok, loaded} = Store.load(store1)
      refute Map.has_key?(loaded, :chat_messages)

      store2 = Store.Ets.new(path: path)

      assert [%{id: "persisted-message-1"}] =
               store2
               |> Store.stream_messages(jid, order: :oldest_first)
               |> Enum.to_list()
    end

    test "message persistence survives the store-creating process exiting" do
      # The writer process takes ownership of every ETS table precisely so the
      # store outlives whoever built it. A table left off the give-away list
      # stays owned by the creator and dies with it — and because the per-chat
      # counter is touched on every insert, one missing table turns every later
      # message write into {:error, {:store_mutation_failed, %ArgumentError{}}}
      # while the rest of the store keeps working.
      path = Path.join(@tmp_dir, "creator_handoff_test.etf")
      jid = "15550001111@s.whatsapp.net"
      parent = self()

      {creator, ref} =
        spawn_monitor(fn ->
          send(parent, {:store, Store.Ets.new(path: path)})
        end)

      assert_receive {:store, store}
      assert_receive {:DOWN, ^ref, :process, ^creator, :normal}

      assert :ok =
               Store.upsert_messages(store, jid, [
                 %{id: "after-handoff", timestamp: 1, status: :received}
               ])

      assert :ok = Store.delete_chat_messages(store, jid)
    end

    test "status updates by ID apply across chats" do
      path = Path.join(@tmp_dir, "status_by_id_test.etf")
      store = Store.Ets.new(path: path)
      message_id = "shared-message-id"
      jid1 = "15550001111@s.whatsapp.net"
      jid2 = "15550002222@s.whatsapp.net"

      assert :ok =
               Store.upsert_messages(store, jid1, [
                 %{id: message_id, timestamp: 1, status: :pending}
               ])

      assert :ok =
               Store.upsert_messages(store, jid2, [
                 %{id: message_id, timestamp: 2, status: :pending}
               ])

      assert :ok = Store.update_message_status_by_id(store, message_id, :delivered)

      assert %{status: :delivered} = Store.find_message(store, jid1, message_id)
      assert %{status: :delivered} = Store.find_message(store, jid2, message_id)
    end

    test "delete_chat_messages removes only the requested chat history" do
      path = Path.join(@tmp_dir, "delete_chat_messages_test.etf")
      store = Store.Ets.new(path: path)
      jid = "15550001111@s.whatsapp.net"
      other_jid = "15550002222@s.whatsapp.net"

      assert :ok =
               Store.upsert_messages(store, jid, [
                 %{id: "m1", timestamp: 1, status: :received},
                 %{id: "m2", timestamp: 2, status: :received}
               ])

      assert :ok =
               Store.upsert_messages(store, other_jid, [
                 %{id: "m3", timestamp: 3, status: :received}
               ])

      assert :ok = Store.delete_chat_messages(store, jid)

      assert [] = Store.list_messages(store, jid, limit: :all)
      assert [%{id: "m3"}] = Store.list_messages(store, other_jid, limit: :all)

      reloaded = Store.Ets.new(path: path)
      assert [] = Store.list_messages(reloaded, jid, limit: :all)
      assert [%{id: "m3"}] = Store.list_messages(reloaded, other_jid, limit: :all)
    end

    test "persists to file and survives reload" do
      path = Path.join(@tmp_dir, "persist_test.etf")

      # First store instance
      store1 = Store.Ets.new(path: path)
      Store.persist(store1, %{key: "value"})

      # Second store instance loading same file
      store2 = Store.Ets.new(path: path)
      assert {:ok, %{key: "value"}} = Store.load(store2)
    end

    test "a stale general snapshot cannot roll back a newer Signal ratchet" do
      path = Path.join(@tmp_dir, "signal_stale_snapshot.etf")
      store = Store.Ets.new(path: path)
      sessions = Store.load_signal_sessions(store)
      jid = "15550001111@s.whatsapp.net"

      ExWapp.Signal.SessionStore.put_session(sessions, jid, %{ratchet_counter: 1})
      assert :ok = Store.persist_signal_sessions(store, sessions)
      stale_snapshot = Store.load!(store)

      ExWapp.Signal.SessionStore.put_session(sessions, jid, %{ratchet_counter: 2})
      assert :ok = Store.persist_signal_sessions(store, sessions)

      assert :ok =
               Store.persist(
                 store,
                 Map.put(stale_snapshot, :contacts, %{"stale@s.whatsapp.net" => %{}})
               )

      assert {:ok, %{ratchet_counter: 2}} =
               store
               |> Store.load_signal_sessions()
               |> ExWapp.Signal.SessionStore.get_session(jid)

      reloaded = Store.Ets.new(path: path)

      assert {:ok, %{ratchet_counter: 2}} =
               reloaded
               |> Store.load_signal_sessions()
               |> ExWapp.Signal.SessionStore.get_session(jid)
    end

    test "concurrent contact-domain updates do not lose entries" do
      path = Path.join(@tmp_dir, "concurrent_contacts.etf")
      store = Store.Ets.new(path: path)

      1..32
      |> Enum.map(fn index ->
        Task.async(fn ->
          jid = "#{index}@s.whatsapp.net"

          ExWapp.Contact.merge_from_sync(store, jid, %{
            full_name: "Contact #{index}",
            first_name: "Contact"
          })
        end)
      end)
      |> Task.await_many(10_000)

      assert store |> Store.get(:contacts, %{}) |> map_size() == 32
      assert Store.Ets.new(path: path) |> Store.get(:contacts, %{}) |> map_size() == 32
    end

    test "a caller-owned batch defers disk persistence until its final mutation" do
      path = Path.join(@tmp_dir, "batched_contacts.etf")
      store = Store.Ets.new(path: path)

      assert :ok = Store.begin_batch(store, :contact_sync)

      for index <- 1..16 do
        assert :ok =
                 ExWapp.Contact.merge_from_sync(store, "#{index}@s.whatsapp.net", %{
                   full_name: "Contact #{index}"
                 })
      end

      refute File.exists?(path)
      assert :ok = Store.finish_batch(store, :contact_sync)
      assert File.exists?(path)

      assert Store.Ets.new(path: path) |> Store.get(:contacts, %{}) |> map_size() == 16
    end

    test "an explicit flush persists a still-open batch" do
      path = Path.join(@tmp_dir, "explicit_flush.etf")
      store = Store.Ets.new(path: path)

      assert :ok = Store.begin_batch(store, :long_sync)
      assert :ok = Store.put(store, :sync_progress, 42)
      refute File.exists?(path)

      assert :ok = Store.flush(store)
      assert {:ok, %{sync_progress: 42}} = Store.Ets.load_path(path)
      assert Process.alive?(store.writer)

      assert :ok = Store.finish_batch(store, :long_sync)
    end

    test "close durably flushes a pending batch before stopping its writer" do
      path = Path.join(@tmp_dir, "close_flush.etf")
      store = Store.Ets.new(path: path)

      assert :ok = Store.begin_batch(store, :long_sync)
      assert :ok = Store.put(store, :last_update, :pending)
      refute File.exists?(path)

      assert :ok = Store.close(store)
      refute Process.alive?(store.writer)
      assert {:ok, %{last_update: :pending}} = Store.Ets.load_path(path)
    end

    test "an abandoned caller batch is flushed when its owner exits" do
      path = Path.join(@tmp_dir, "abandoned_batch.etf")
      store = Store.Ets.new(path: path)
      parent = self()

      {owner, monitor} =
        spawn_monitor(fn ->
          assert :ok = Store.begin_batch(store, :owner_exit)
          assert :ok = Store.put(store, :owner_state, :finished)
          send(parent, :batch_mutated)
        end)

      assert_receive :batch_mutated
      assert_receive {:DOWN, ^monitor, :process, ^owner, :normal}

      assert_eventually(fn ->
        match?({:ok, %{owner_state: :finished}}, Store.Ets.load_path(path))
      end)
    end

    test "a failing read callback cannot crash the ETS owner" do
      path = Path.join(@tmp_dir, "reader_isolation.etf")
      store = Store.Ets.new(path: path)

      assert {:error, {:store_read_failed, %RuntimeError{message: "reader failed"}}} =
               Store.read(store, fn _data -> raise "reader failed" end)

      assert Process.alive?(store.writer)
      assert :ok = Store.put(store, :still_available, true)
      assert Store.get(store, :still_available) == true
    end
  end

  describe "MessageTable" do
    test "streams a chat in timestamp order with offset and limit" do
      table =
        MessageTable.new(%{
          "15550001111@s.whatsapp.net" => [
            %{id: "m1", timestamp: 1},
            %{id: "m3", timestamp: 3},
            %{id: "m2", timestamp: 2}
          ],
          "15550002222@s.whatsapp.net" => [
            %{id: "other", timestamp: 4}
          ]
        })

      assert ["m3", "m2"] =
               table
               |> MessageTable.stream("15550001111@s.whatsapp.net", limit: 2)
               |> Enum.map(& &1.id)

      assert ["m2"] =
               table
               |> MessageTable.stream("15550001111@s.whatsapp.net",
                 order: :oldest_first,
                 offset: 1,
                 limit: 1
               )
               |> Enum.map(& &1.id)
    end
  end

  describe "Store.Memory adapter" do
    test "stores and retrieves data" do
      store = Store.Memory.new()

      assert {:ok, %{}} = Store.load(store)

      Store.persist(store, %{user: "Alice"})
      assert {:ok, %{user: "Alice"}} = Store.load(store)
    end

    test "accepts initial data" do
      store = Store.Memory.new(initial_data: %{preset: true})
      assert {:ok, %{preset: true}} = Store.load(store)
    end

    test "clears data" do
      store = Store.Memory.new(initial_data: %{foo: "bar"})
      assert :ok = Store.clear(store)
      assert {:ok, %{}} = Store.load(store)
    end

    test "update/3 modifies specific key" do
      store = Store.Memory.new(initial_data: %{a: 1, b: 2})
      Store.Memory.update(store, :a, 100)
      assert {:ok, %{a: 100, b: 2}} = Store.load(store)
    end

    test "failing callbacks cannot crash the memory adapter" do
      store = Store.Memory.new(initial_data: %{counter: 1})

      assert {:error, {:store_read_failed, %RuntimeError{message: "read failed"}}} =
               Store.read(store, fn _data -> raise "read failed" end)

      assert {:error, {:store_mutation_failed, %RuntimeError{message: "update failed"}}} =
               Store.update(store, :counter, 0, fn _current -> raise "update failed" end)

      assert {:error, {:invalid_store_get_and_update_result, :invalid}} =
               Store.get_and_update(store, :counter, 0, fn _current -> :invalid end)

      assert {:error, {:invalid_store_transaction_result, :invalid}} =
               Store.transaction(store, fn _data -> :invalid end)

      assert Process.alive?(store.agent)
      assert :ok = Store.put(store, :counter, 2)
      assert Store.get(store, :counter) == 2
    end

    test "stop/1 terminates the agent" do
      store = Store.Memory.new()
      assert :ok = Store.Memory.stop(store)
      assert catch_exit(Store.load(store))
    end

    test "stop/1 is idempotent" do
      store = Store.Memory.new()

      assert :ok = Store.Memory.stop(store)
      assert :ok = Store.Memory.stop(store)
    end

    test "stop/1 tolerates an agent that shuts down while being stopped" do
      # The agent is linked to whoever built the store, so teardown that runs
      # after that owner has gone races the shutdown it caused: the process is
      # alive when stop/1 looks, and dead with reason :shutdown by the time the
      # stop lands. That is what an ExUnit `on_exit` cleanup does after its test
      # process exits, and a teardown helper that raises there fails a test that
      # had already passed.
      #
      # Standing in for the agent is a process that exits :shutdown when the
      # stop reaches it, which pins the timing rather than racing for it.
      agent =
        spawn(fn ->
          Process.flag(:trap_exit, true)

          receive do
            {:system, _from, _message} -> exit(:shutdown)
          end
        end)

      store = %Store.Memory{agent: agent, message_table: nil}

      assert :ok = Store.Memory.stop(store)
    end

    test "stop/1 tolerates an agent killed out from under it" do
      store = Store.Memory.new()
      Process.unlink(store.agent)
      Process.exit(store.agent, :kill)

      assert :ok = Store.Memory.stop(store)
    end
  end

  describe "Store.load!/1" do
    test "returns data on success" do
      store = Store.Memory.new(initial_data: %{key: "value"})
      assert %{key: "value"} = Store.load!(store)
    end

    test "raises on error" do
      store = Store.Memory.new()
      Store.Memory.stop(store)

      assert_raise RuntimeError, ~r/ExWapp\.Store\.load! exited:/, fn ->
        Store.load!(store)
      end
    end
  end

  defp assert_eventually(assertion, attempts \\ 50)

  defp assert_eventually(assertion, attempts) when attempts > 0 do
    if assertion.() do
      :ok
    else
      Process.sleep(10)
      assert_eventually(assertion, attempts - 1)
    end
  end

  defp assert_eventually(_assertion, 0), do: flunk("condition did not become true")
end
