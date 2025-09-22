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

  test "ETS store persists arbitrary maps (via facade)" do
    path = Path.join(@tmp_dir, "session.etf")

    store = Store.new({ExWapp.Store.ETS, path: path})

    assert {:ok, %{}} = Store.load(store)

    payload = %{"noise" => %{client_static: <<1, 2, 3>>}}
    assert :ok = Store.persist(store, payload)
    assert {:ok, ^payload} = Store.load(store)
  end
end
