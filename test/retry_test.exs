defmodule ExWapp.Session.Worker.RetryTest do
  use ExUnit.Case, async: true

  alias ExWapp.Session.JIDUtils
  alias ExWapp.Session.Worker.Retry

  test "retries using cached outgoing payload when store lookup is unavailable" do
    parent = self()

    state = %{
      store: nil,
      retry_counters: %{},
      send_workers: %{},
      send_worker_mons: %{}
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
        send_fun: send_fun,
        outgoing_payloads: %{
          "MID_1" => %{jid: "270578829287645@lid", text: "retry me"}
        }
      )

    assert_receive {:retry_worker_started, "270578829287645@lid"}
    assert_receive {:retry_send, "270578829287645@lid", "retry me"}

    assert next_state.retry_counters == %{"outbound_retry|270578829287645@lid|MID_1" => 1}
    assert map_size(next_state.send_workers) == 1
    assert map_size(next_state.send_worker_mons) == 1
  end

  test "normalizes linked-device retry receipts to the cached base lid jid" do
    parent = self()

    state = %{
      store: nil,
      retry_counters: %{},
      send_workers: %{},
      send_worker_mons: %{}
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
      send_workers: %{},
      send_worker_mons: %{}
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
      Retry.maybe_retry_outgoing_message(state, "33625382846503@lid", "MID_3",
        max_attempts: 2,
        normalize_jid: &JIDUtils.normalize_for_signal/1,
        start_worker: start_worker,
        send_fun: send_fun,
        outgoing_payloads: %{
          "MID_3" => %{jid: "393277726137@s.whatsapp.net", text: "retry original contact"}
        }
      )

    assert_receive {:retry_worker_started, "393277726137@s.whatsapp.net"}
    assert_receive {:retry_send, "393277726137@s.whatsapp.net", "retry original contact"}

    assert next_state.retry_counters == %{
             "outbound_retry|393277726137@s.whatsapp.net|MID_3" => 1
           }
  end
end

