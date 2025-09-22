defmodule ExWapp.StoreTest do
  use ExUnit.Case, async: true

  alias ExWapp.Store

  @tmp_dir Path.join(System.tmp_dir!(), "ex_wapp_store_tests")

  setup do
    File.rm_rf(@tmp_dir)
    :ok = File.mkdir_p(@tmp_dir)
    on_exit(fn -> File.rm_rf(@tmp_dir) end)
    :ok
  end

  test "file store persists arbitrary maps" do
    path = Path.join(@tmp_dir, "session.etf")
    store = Store.File.new(path: path)

    assert {:ok, %{}} = Store.File.load(store)

    payload = %{"noise" => %{client_static: <<1, 2, 3>>}}
    assert :ok = Store.File.persist(store, payload)
    assert {:ok, ^payload} = Store.File.load(store)
  end
end
