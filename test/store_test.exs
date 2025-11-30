defmodule ExWapp.StoreTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Store

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
      assert {:ok, ^payload} = Store.load(store)
    end

    test "clears data" do
      path = Path.join(@tmp_dir, "clear_test.etf")
      store = Store.Ets.new(path: path)

      Store.persist(store, %{foo: "bar"})
      assert {:ok, %{foo: "bar"}} = Store.load(store)

      assert :ok = Store.clear(store)
      assert {:ok, %{}} = Store.load(store)
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

    test "stop/1 terminates the agent" do
      store = Store.Memory.new()
      assert :ok = Store.Memory.stop(store)
      assert catch_exit(Store.load(store))
    end
  end

  describe "Store.load!/1" do
    test "returns data on success" do
      store = Store.Memory.new(initial_data: %{key: "value"})
      assert %{key: "value"} = Store.load!(store)
    end

    test "returns empty map on error" do
      store = Store.Memory.new()
      Store.Memory.stop(store)
      # Agent is stopped, load will fail
      assert %{} = Store.load!(store)
    end
  end
end
