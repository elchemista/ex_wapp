defmodule ExWapp.Session.Outbound.IQRequestsTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Session.Outbound.IQRequests
  alias ExWapp.Signal.SessionStore
  alias ExWapp.Store.Memory

  setup do
    store = Memory.new()

    on_exit(fn ->
      if Process.alive?(store.agent), do: Memory.stop(store)
    end)

    {:ok, state: %{store: store, runtime_cfg: %{}}}
  end

  test "normalizes a USync transport send failure", %{state: state} do
    send_node = failing_send_node(self())

    assert {:error, {:usync_send_failed, {:error, :closed}}} =
             IQRequests.query_devices(
               state,
               ["15550001111@s.whatsapp.net"],
               send_node
             )

    assert_receive {:outbound_iq, %Binary.Node{tag: "iq"}}
  end

  test "normalizes a group-info transport send failure", %{state: state} do
    send_node = failing_send_node(self())

    assert {:error, {:group_info_send_failed, {:error, :closed}}} =
             IQRequests.query_group_info(
               state,
               "120363000000000000@g.us",
               send_node
             )

    assert_receive {:outbound_iq, %Binary.Node{tag: "iq"}}
  end

  test "normalizes a batch prekey transport send failure", %{state: state} do
    send_node = failing_send_node(self())

    assert {:error, {:send_failed, {:error, :closed}}} =
             IQRequests.fetch_prekeys_batch(
               state,
               ["15550001111@s.whatsapp.net"],
               SessionStore.new(),
               send_node
             )

    assert_receive {:outbound_iq, %Binary.Node{tag: "iq"}}
  end

  defp failing_send_node(test_pid) do
    fn node ->
      send(test_pid, {:outbound_iq, node})
      {:error, :closed}
    end
  end
end
