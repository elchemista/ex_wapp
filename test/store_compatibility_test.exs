defmodule ExWapp.StoreCompatibilityTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Contact, Store}
  alias ExWapp.Domains.Contacts.Repository

  # Deliberately implements only the three required callbacks, exercising the
  # documented custom-adapter contract against an actual persistent file.
  defmodule FileStore do
    @behaviour ExWapp.Store
    defstruct [:path]
    @impl true
    def new(opts), do: %__MODULE__{path: Keyword.fetch!(opts, :path)}
    @impl true
    def load(store) do
      case File.read(store.path) do
        {:ok, binary} -> {:ok, :erlang.binary_to_term(binary, [:safe])}
        {:error, :enoent} -> {:error, :empty_store}
        error -> error
      end
    end

    @impl true
    def persist(store, data), do: File.write(store.path, :erlang.term_to_binary(data))
  end

  setup %{tmp_dir: dir} do
    store = Store.new({FileStore, path: Path.join(dir, "session.etf")})
    %{store: store}
  end

  @moduletag :tmp_dir

  test "required callbacks support durable transactions, batches and Signal snapshots", %{
    store: store
  } do
    assert Store.load!(store) == %{}
    assert Store.get(store, :missing, :default) == :default
    assert Store.new(store) == store
    assert :ok = Store.put(store, :counter, 1)
    assert :ok = Store.update(store, :counter, 0, &(&1 + 1))
    assert 2 = Store.get_and_update(store, :counter, 0, &{&1, &1 + 1})
    assert :ok = Store.transaction(store, &Map.put(&1, :identity, "keep"))

    assert :done =
             Store.batch(store, :import, fn ->
               :ok = Store.persist_device_cache(store, %{"1555" => [1, 2]})
               :ok = Store.persist_signal_sessions(store, ExWapp.Signal.SessionStore.new())
               :done
             end)

    assert :ok = Store.flush(store)
    assert :ok = Store.close(store)
    reopened = FileStore.new(path: store.path)

    assert Store.read(reopened, &Map.take(&1, [:counter, :identity])) == %{
             counter: 3,
             identity: "keep"
           }

    assert Store.load_device_cache(reopened) == %{"1555" => [1, 2]}

    assert Store.load_signal_sessions(reopened) == %{
             sessions: %{},
             pending_prekeys: %{},
             session_touched_at_ms: %{}
           }

    assert {:update, 4} in Store.missing_optional_callbacks(reopened)
    assert Store.clear(reopened) == {:error, :not_implemented}
  end

  test "message upserts replace IDs and pagination survives reopening", %{store: store} do
    jid = "1555@s.whatsapp.net"

    assert :ok =
             Store.upsert_messages(store, jid, [
               %{id: "a", timestamp: 1, text: "old"},
               %{id: "b", timestamp: 2}
             ])

    assert :ok =
             Store.upsert_messages(store, jid, [
               %{id: "a", timestamp: 3, text: "edited"},
               :invalid
             ])

    reopened = FileStore.new(path: store.path)
    assert Store.find_message(reopened, jid, "a").text == "edited"
    assert Enum.map(Store.list_messages(reopened, jid), & &1.id) == ["a", "b"]

    assert [%{id: "a"}] =
             Store.list_messages(reopened, jid, order: :oldest_first, offset: 1, limit: 1)

    assert [] = Store.list_messages(reopened, jid, limit: 0)
    assert length(Store.list_messages(reopened, jid, offset: -1, limit: :invalid)) == 2
    assert {^jid, %{id: "a"}} = Store.find_message_by_id(reopened, "a")
    assert nil == Store.find_message_by_id(reopened, "absent")
    assert :ok = Store.update_message_status(reopened, jid, "a", :delivered)
    assert Store.find_message(reopened, jid, "a").status == :delivered
    assert :ok = Store.upsert_messages(reopened, "other", [%{id: "a", timestamp: 4}])
    assert :ok = Store.update_message_status_by_id(reopened, "a", :read)

    for chat <- [jid, "other"],
        do: assert(Store.find_message(reopened, chat, "a").status == :read)

    assert :ok = Store.delete_messages(reopened, jid, ["a"])
    assert nil == Store.find_message(reopened, jid, "a")
    assert :ok = Store.delete_chat_messages(reopened, "other")
    assert [] == Store.list_messages(reopened, "other")
    assert {:ok, %{chat_messages: %{^jid => [%{id: "b"}]}}} = Store.snapshot(reopened)
  end

  test "legacy messages migrate on write without resurrecting edits or deletions", %{store: store} do
    jid = "legacy"

    assert :ok =
             Store.persist(store, %{
               chats: %{
                 jid => %{name: "Archive", messages: [%{id: "old", timestamp: 1}]},
                 "bad" => nil,
                 "empty" => %{}
               },
               chat_messages: %{jid => [%{id: "new", timestamp: 2}]}
             })

    assert Enum.map(Store.list_messages(store, jid), & &1.id) == ["new", "old"]
    assert :ok = Store.update_message_status(store, jid, "old", :read)
    assert [%{id: "new"}, %{id: "old", status: :read}] = Store.list_messages(store, jid)
    assert :ok = Store.delete_chat_messages(store, jid)
    assert [] == Store.list_messages(FileStore.new(path: store.path), jid)
    assert Store.load!(store).chats[jid].name == "Archive"
    assert {:ok, snapshot} = Store.snapshot(store)
    refute Map.has_key?(snapshot, :chat_messages)
  end

  test "write failures propagate and corrupt files never become empty successful loads", %{
    store: store
  } do
    assert :ok = Store.put(store, :counter, 1)
    File.rm!(store.path)
    File.mkdir!(store.path)
    assert {:error, :eisdir} = Store.load(store)
    assert_raise RuntimeError, ~r/load! failed/, fn -> Store.load!(store) end
    assert {:error, :eisdir} = Store.persist(store, %{})
    File.rmdir!(store.path)
    File.write!(store.path, "corrupt")
    assert_raise ArgumentError, fn -> Store.load!(store) end
    missing_parent = FileStore.new(path: Path.join(store.path <> "-missing", "data"))
    assert {:error, :enoent} = Store.get_and_update(missing_parent, :count, 0, &{&1, &1 + 1})
  end

  test "contact synchronization consolidates aliases and preserves unspecified fields", %{
    store: store
  } do
    legacy = %Contact{jid: "+1555@whatsapp.net", full_name: "Alice"}

    assert :ok =
             Store.put(store, :contacts, %{
               legacy.jid => legacy,
               "999@s.whatsapp.net" => %Contact{jid: "999@s.whatsapp.net"}
             })

    assert Repository.get(store, "1555@s.whatsapp.net") == legacy
    assert :ok = Repository.update_push_name(store, "+1555@whatsapp.net", "Alice mobile")
    assert :ok = Repository.update_push_name(store, "1555", "")

    assert :ok =
             Repository.merge_from_sync(store, "1555@s.whatsapp.net", %{
               first_name: "Ali",
               lid_jid: "77@lid",
               username: "alice"
             })

    assert %Contact{
             full_name: "Alice",
             first_name: "Ali",
             push_name: "Alice mobile",
             lid: "77@lid",
             username: "alice",
             phone_number: "1555"
           } = Repository.get(store, "1555@s.whatsapp.net")

    assert length(Repository.list(store)) == 2
    assert :ok = Repository.merge_from_sync(store, "1555", nil)

    assert :ok =
             Repository.put(store, "123@s.whatsapp.net", %Contact{jid: "old", full_name: "Bob"})

    assert Repository.get(FileStore.new(path: store.path), "123@s.whatsapp.net").jid ==
             "123@s.whatsapp.net"

    assert :ok = Repository.delete(store, "+1555@whatsapp.net")
    assert nil == Repository.get(store, "1555@s.whatsapp.net")
    assert length(Repository.list(store)) == 2
  end
end
