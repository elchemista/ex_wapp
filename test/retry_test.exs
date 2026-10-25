defmodule ExWapp.Session.Worker.RetryTest do
  use ExUnit.Case, async: true

  alias ExWapp.Session.JIDUtils
  alias ExWapp.Session.Worker.Retry

  test "retries using cached outgoing payload when store lookup is unavailable" do
    parent = self()

    state = %{
      store: nil,
      retry_counters: %{},
      registered_workers: %{},
      registered_monitors: %{}
    }

    start_worker = fn _state, jid, fun ->
      pid =
        spawn(fn ->
          send(parent, {:retry_worker_started, jid})
          fun.()
        end)

      {:ok, pid, Process.monitor(pid)}
    end

    send_fun = fn jid, text ->
      send(parent, {:retry_send, jid, text})
      {:ok, "NEW_ID"}
    end

    next_state =
      Retry.maybe_retry_outgoing_message(state, "270578829287645@lid", "MID_1",
        max_attempts: 2,
        normalize_jid: &JIDUtils.normalize_for_signal/1,
        start_worker: start_worker,
        register_worker: &register_worker/4,
        send_fun: send_fun,
        outgoing_payloads: %{
          "MID_1" => %{jid: "270578829287645@lid", text: "retry me"}
        }
      )

    assert_receive {:retry_worker_started, "270578829287645@lid"}
    assert_receive {:retry_send, "270578829287645@lid", "retry me"}

    assert next_state.retry_counters == %{"outbound_retry|270578829287645@lid|MID_1" => 1}
    assert map_size(next_state.registered_workers) == 1
    assert map_size(next_state.registered_monitors) == 1
  end

  test "normalizes linked-device retry receipts to the cached base lid jid" do
    parent = self()

    state = %{
      store: nil,
      retry_counters: %{},
      registered_workers: %{},
      registered_monitors: %{}
    }

    start_worker = fn _state, jid, fun ->
      pid =
        spawn(fn ->
          send(parent, {:retry_worker_started, jid})
          fun.()
        end)

      {:ok, pid, Process.monitor(pid)}
    end

    send_fun = fn jid, text ->
      send(parent, {:retry_send, jid, text})
      {:ok, "NEW_ID"}
    end

    next_state =
      Retry.maybe_retry_outgoing_message(state, "270578829287645:91@lid", "MID_2",
        max_attempts: 2,
        normalize_jid: &JIDUtils.normalize_for_signal/1,
        start_worker: start_worker,
        register_worker: &register_worker/4,
        send_fun: send_fun,
        outgoing_payloads: %{
          "MID_2" => %{jid: "270578829287645@lid", text: "retry linked device"}
        }
      )

    assert_receive {:retry_worker_started, "270578829287645@lid"}
    assert_receive {:retry_send, "270578829287645@lid", "retry linked device"}

    assert next_state.retry_counters == %{"outbound_retry|270578829287645@lid|MID_2" => 1}
  end

  test "uses cached original recipient when own device requests an outbound retry" do
    parent = self()

    state = %{
      store: nil,
      retry_counters: %{},
      registered_workers: %{},
      registered_monitors: %{}
    }

    start_worker = fn _state, jid, fun ->
      pid =
        spawn(fn ->
          send(parent, {:retry_worker_started, jid})
          fun.()
        end)

      {:ok, pid, Process.monitor(pid)}
    end

    send_fun = fn jid, text ->
      send(parent, {:retry_send, jid, text})
      {:ok, "NEW_ID"}
    end

    next_state =
      Retry.maybe_retry_outgoing_message(state, "19995550202@lid", "MID_3",
        max_attempts: 2,
        normalize_jid: &JIDUtils.normalize_for_signal/1,
        start_worker: start_worker,
        register_worker: &register_worker/4,
        send_fun: send_fun,
        outgoing_payloads: %{
          "MID_3" => %{jid: "19995550404@s.whatsapp.net", text: "retry original contact"}
        }
      )

    assert_receive {:retry_worker_started, "19995550404@s.whatsapp.net"}
    assert_receive {:retry_send, "19995550404@s.whatsapp.net", "retry original contact"}

    assert next_state.retry_counters == %{
             "outbound_retry|19995550404@s.whatsapp.net|MID_3" => 1
           }
  end

  defp register_worker(state, worker, monitor, jid) do
    %{
      state
      | registered_workers: Map.put(state.registered_workers, worker, jid),
        registered_monitors: Map.put(state.registered_monitors, monitor, worker)
    }
  end

  test "a retry after cache loss finds the original chat even when the requester differs" do
    store = ExWapp.Store.Memory.new()
    on_exit(fn -> ExWapp.Store.Memory.stop(store) end)
    recipient = "15550001111@s.whatsapp.net"

    ExWapp.Chat.add_message(store, recipient, %{
      id: "stored",
      from_me: true,
      text: "persisted text"
    })

    state = retry_state(store)

    opts = retry_options(outgoing_payloads: nil)
    updated = Retry.maybe_retry_outgoing_message(state, "70000009999:7@lid", "stored", opts)
    assert_receive {:retry_send, ^recipient, "persisted text"}
    assert updated.retry_counters == %{"outbound_retry|#{recipient}|stored" => 1}

    # Looking up the same chat directly also works without a payload cache.
    opts = Keyword.delete(opts, :outgoing_payloads)
    updated = Retry.maybe_retry_outgoing_message(updated, recipient, "stored", opts)
    assert_receive {:retry_send, ^recipient, "persisted text"}
    assert updated.retry_counters == %{"outbound_retry|#{recipient}|stored" => 2}
    assert Retry.maybe_retry_outgoing_message(updated, recipient, "stored", opts) == updated
    refute_received {:retry_send, _, _}
  end

  test "inbound messages cannot be replayed as outgoing retries" do
    store = ExWapp.Store.Memory.new()
    on_exit(fn -> ExWapp.Store.Memory.stop(store) end)
    recipient = "15550001111@s.whatsapp.net"
    ExWapp.Chat.add_message(store, recipient, %{id: "received", from_me: false, text: "not ours"})
    state = retry_state(store)
    opts = retry_options([])
    assert Retry.maybe_retry_outgoing_message(state, recipient, "received", opts) == state
    refute_received {:retry_send, _, _}
  end

  test "cached text without a recipient uses the normalized requesting address" do
    state = retry_state(nil)
    opts = retry_options(outgoing_payloads: %{"cached" => %{text: "cached text"}})
    updated = Retry.maybe_retry_outgoing_message(state, "70000001111:8@lid", "cached", opts)
    assert_receive {:retry_send, "70000001111@lid", "cached text"}
    assert updated.retry_counters == %{"outbound_retry|70000001111@lid|cached" => 1}
  end

  defp retry_state(store),
    do: %{store: store, retry_counters: %{}, registered_workers: %{}, registered_monitors: %{}}

  defp retry_options(overrides) do
    supervisor = start_supervised!(Task.Supervisor)
    owner = self()

    Keyword.merge(
      [
        max_attempts: 2,
        normalize_jid: &JIDUtils.normalize_for_signal/1,
        register_worker: &register_worker/4,
        start_worker: fn _state, _jid, fun ->
          {:ok, pid} = Task.Supervisor.start_child(supervisor, fun)
          {:ok, pid, Process.monitor(pid)}
        end,
        send_fun: fn jid, text ->
          send(owner, {:retry_send, jid, text})
          {:ok, "retried"}
        end
      ],
      overrides
    )
  end
end
