defmodule ExWapp.SendWorkerRecoveryTest do
  use ExUnit.Case, async: true
  alias ExWapp.Session.{Worker, SendCoordinator}
  alias ExWapp.Session.Worker.SendRecovery

  test "worker exceptions and exits are reported to the owner and free supervisor capacity" do
    supervisor = start_supervised!({Task.Supervisor, max_children: 1})
    state = %Worker{send_worker_sup: supervisor}

    for {fun, expected} <- [
          {fn -> raise "failed operation" end,
           {:send_worker_exception, RuntimeError, "failed operation"}},
          {fn -> throw(:operation_aborted) end,
           {:send_worker_caught, :throw, :operation_aborted}},
          {fn -> exit(:dependency_closed) end, {:send_worker_caught, :exit, :dependency_closed}}
        ] do
      assert {:ok, pid, ref} =
               SendRecovery.start_send_worker(state, "operation", fn ->
                 receive do
                   :execute -> fun.()
                 end
               end)

      send(pid, :execute)
      assert_receive {:send_worker_finished, ^pid, {:error, ^expected}}, 1000
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 1000
    end

    assert {:ok, pid, ref} =
             SendRecovery.start_send_worker(state, "operation", fn ->
               receive do
                 :execute -> {:ok, "recovered"}
               end
             end)

    send(pid, :execute)
    assert_receive {:send_worker_finished, ^pid, {:ok, "recovered"}}, 1000
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 1000
  end

  test "placeholder recovery requires valid references and available worker capacity" do
    supervisor = start_supervised!({Task.Supervisor, max_children: 0})

    state = %Worker{
      status: :connected,
      conn: self(),
      send_worker_sup: supervisor,
      send_coordinator: SendCoordinator.new()
    }

    for {candidate, chat, sender, id} <- [
          {nil, "123@s.whatsapp.net", "456@s.whatsapp.net", "id"},
          {%{state | status: :idle}, "123@s.whatsapp.net", "456@s.whatsapp.net", "id"},
          {%{state | conn: nil}, "123@s.whatsapp.net", "456@s.whatsapp.net", "id"},
          {state, nil, "456@s.whatsapp.net", "id"},
          {state, "", "456@s.whatsapp.net", "id"},
          {state, %ExWapp.JID{user: "123", server: "s.whatsapp.net"}, "456@s.whatsapp.net", "id"},
          {state, 1, "456@s.whatsapp.net", "id"},
          {state, "123@s.whatsapp.net", "", "id"},
          {state, "123@s.whatsapp.net", "456@s.whatsapp.net", ""}
        ] do
      assert SendRecovery.maybe_start_placeholder_resend_request(candidate, chat, sender, id, %{}) ==
               candidate
    end

    assert SendRecovery.maybe_start_placeholder_resend_request(
             state,
             "123@s.whatsapp.net",
             "456@s.whatsapp.net",
             "id",
             %{}
           ) == state

    assert Task.Supervisor.children(supervisor) == []
  end

  test "retry payload retention evicts the oldest entries and accepts real iodata" do
    now = System.monotonic_time(:millisecond)

    payloads =
      Map.new(1..512, fn index ->
        {"old-#{index}",
         %{
           jid: "123@s.whatsapp.net",
           text: "message #{index}",
           inserted_at_ms: now - 1000 + index
         }}
      end)

    state = %{outgoing_retry_payloads: payloads}

    updated =
      SendRecovery.remember_outgoing_retry_payload(
        state,
        "123@s.whatsapp.net",
        ["new", [32, "message"]],
        "new-id"
      )

    assert map_size(updated.outgoing_retry_payloads) == 512
    refute Map.has_key?(updated.outgoing_retry_payloads, "old-1")
    assert updated.outgoing_retry_payloads["new-id"].text == "new message"

    assert SendRecovery.remember_outgoing_retry_payload(
             updated,
             "123@s.whatsapp.net",
             [],
             "empty"
           ) == updated

    assert SendRecovery.remember_outgoing_retry_payload(updated, nil, "message", "invalid") ==
             updated
  end
end
