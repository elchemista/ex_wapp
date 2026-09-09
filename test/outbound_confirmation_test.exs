defmodule ExWapp.OutboundConfirmationTest do
  use ExUnit.Case, async: true

  alias ExWapp.Store
  alias ExWapp.Session.Worker.OutboundConfirmation, as: Confirmation

  @pn "15550001111@s.whatsapp.net"
  @lid "70000001111@lid"

  setup do
    store = Store.Memory.new(initial_data: %{client_info: %{jid: @pn, lid: @lid}})
    {:ok, state: %{store: store, outbound_confirmations: %{}}}
  end

  test "self-chat confirmation timers recognize both own identities and device suffixes", %{
    state: state
  } do
    for jid <- [@pn, @lid, "70000001111:7@lid"] do
      id = "timer-#{jid}"
      updated = Confirmation.schedule(state, jid, ["hel", "lo"], id, :normal, 0, timeout_ms: 1)
      assert %{text: "hello", attempt: 0, timer: timer} = updated.outbound_confirmations[id]
      assert is_reference(timer)
      assert_receive {:outbound_confirm_timeout, ^id}, 500
    end
  end

  test "other recipients and exhausted attempts do not schedule retries", %{state: state} do
    assert Confirmation.schedule(state, "15550002222@s.whatsapp.net", "text", "peer", :normal, 0) ==
             state

    assert Confirmation.schedule(state, @pn, "text", "spent", :fallback, 2) == state

    assert Confirmation.schedule(%{state | store: nil}, @pn, "text", "unknown", :normal, 0) == %{
             state
             | store: nil
           }
  end

  test "delivered and failed messages never start a fallback, including PN/LID aliases", %{
    state: state
  } do
    for status <- [:delivered, :read, :received, :failed] do
      id = "confirmed-#{status}"

      :ok =
        Store.upsert_messages(state.store, @lid, [
          %{id: id, timestamp: 1, from_me: true, status: status}
        ])

      assert Confirmation.handle_timeout(
               state,
               id,
               confirmation(@pn, 0),
               unexpected(3),
               unexpected(5),
               unexpected(4)
             ) == state

      assert Store.find_message(state.store, @lid, id).status == status
    end
  end

  for result <- [{:ok, "replacement"}, {:error, :offline}] do
    test "fallback reports #{inspect(result)} and registers its worker", %{state: state} do
      result = unquote(Macro.escape(result))

      :ok =
        Store.upsert_messages(state.store, @lid, [
          %{id: "pending", timestamp: 1, from_me: true, status: :pending}
        ])

      owner = self()
      supervisor = start_supervised!(Task.Supervisor)

      start_worker = fn ^state, @lid, work ->
        {:ok, pid} = Task.Supervisor.start_child(supervisor, work)
        {:ok, pid, Process.monitor(pid)}
      end

      send_message = fn ^owner, ^state, @lid, "hello", opts ->
        send(owner, {:fallback_options, opts})
        result
      end

      register = fn state, pid, monitor, @lid -> Map.put(state, :worker, {pid, monitor}) end

      updated =
        Confirmation.handle_timeout(
          state,
          "pending",
          confirmation(@lid, 0),
          start_worker,
          send_message,
          register
        )

      assert {pid, monitor} = updated.worker
      assert Store.find_message(state.store, @lid, "pending").status == :failed
      assert_receive {:fallback_options, [self_chat_mode: :recipient_primary]}
      assert_receive {:send_result, @lid, "hello", ^result, :fallback, 1}
      assert_receive {:DOWN, ^monitor, :process, ^pid, _reason}
    end
  end

  test "a fallback worker that cannot start still leaves the original message failed", %{
    state: state
  } do
    :ok =
      Store.upsert_messages(state.store, @pn, [
        %{id: "stuck", timestamp: 1, from_me: true, status: :pending}
      ])

    assert Confirmation.handle_timeout(
             state,
             "stuck",
             confirmation(@pn, 0),
             fn _, _, _ -> {:error, :unavailable} end,
             unexpected(5),
             unexpected(4)
           ) == state

    assert Store.find_message(state.store, @pn, "stuck").status == :failed
  end

  test "spent retry budget marks failure and reports a drop exactly once", %{state: state} do
    :ok =
      Store.upsert_messages(state.store, @pn, [
        %{id: "spent", timestamp: 1, from_me: true, status: :sent}
      ])

    owner = self()
    opts = [on_drop: fn jid, id, attempt -> send(owner, {:dropped, jid, id, attempt}) end]

    for _ <- 1..2 do
      assert Confirmation.handle_timeout(
               state,
               "spent",
               confirmation(@pn, 1),
               unexpected(3),
               unexpected(5),
               unexpected(4),
               opts
             ) == state
    end

    assert Store.find_message(state.store, @pn, "spent").status == :failed
    assert_receive {:dropped, @pn, "spent", 1}
    refute_receive {:dropped, _, _, _}
  end

  defp confirmation(jid, attempt), do: %{jid: jid, text: "hello", attempt: attempt}

  defp unexpected(3), do: fn _, _, _ -> flunk("unexpected retry worker") end
  defp unexpected(4), do: fn _, _, _, _ -> flunk("unexpected worker registration") end
  defp unexpected(5), do: fn _, _, _, _, _ -> flunk("unexpected resend") end
end
