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
end
