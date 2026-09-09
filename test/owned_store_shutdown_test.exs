defmodule ExWapp.OwnedStoreShutdownTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  alias ExWapp.{Session, Store}
  alias ExWapp.Test.FaultStore

  for failure <- [:raise, :throw, :exit, {:return, {:error, :disk_full}}] do
    @failure failure
    test "an owned store close failure #{@failure |> inspect()} preserves normal session shutdown" do
      session =
        start_supervised!(%{
          id: make_ref(),
          restart: :temporary,
          start:
            {Session, :start_link,
             [[store: {FaultStore, initial_data: %{marker: "retained"}}, reconnect: false]]}
        })

      store = GenServer.call(session, :get_store)
      # These diagnostic adapter agents outlive a normal owner exit; explicitly
      # release them even when the close callback is deliberately interrupted.
      on_exit(fn ->
        for pid <- [store.faults, store.inner.agent], Process.alive?(pid), do: Agent.stop(pid)
      end)

      state = :sys.get_state(session)
      assert state.store_owned?
      assert Store.get(store, :marker) == "retained"
      FaultStore.arm(store, :close, @failure)
      monitor = Process.monitor(session)
      log = capture_log(fn -> assert :ok = GenServer.stop(session, :normal) end)
      assert log =~ "Failed closing store"
      assert_receive {:DOWN, ^monitor, :process, ^session, :normal}, 1000

      for pid <- [state.outbound_queue, state.inbound_router, state.send_worker_sup],
          do: refute(Process.alive?(pid))
    end
  end
end
