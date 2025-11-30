defmodule ExWappTest do
  use ExUnit.Case, async: false

  alias ExWapp.Session
  alias ExWapp.Session.Supervisor, as: SessionSupervisor

  describe "Session lifecycle" do
    test "starts in idle state" do
      {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)
      assert ExWapp.state(session) == :idle
      GenServer.stop(session)
    end

    test "returns stats" do
      {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)
      stats = ExWapp.stats(session)

      assert stats.status == :idle
      assert stats.messages_sent == 0
      assert stats.reconnect_attempts == 0
      GenServer.stop(session)
    end

    test "disconnect resets to idle" do
      {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)
      ExWapp.disconnect(session)
      Process.sleep(10)
      assert ExWapp.state(session) == :idle
      GenServer.stop(session)
    end
  end

  describe "QR stream" do
    test "subscribes and receives events" do
      {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)
      {:ok, ref} = Session.subscribe_qr(session)

      send(session, {:connection_event, {:error, :test_error}})
      assert_receive {:ex_wapp_qr, ^ref, {:error, :test_error}}, 1_000

      GenServer.stop(session)
    end

    test "unsubscribe stops receiving events" do
      {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)
      {:ok, ref} = Session.subscribe_qr(session)

      Session.unsubscribe_qr(session, ref)
      assert_receive {:ex_wapp_qr_closed, ^ref}, 1_000

      GenServer.stop(session)
    end
  end

  describe "DynamicSupervisor" do
    test "start_session creates a new session" do
      session_id = "test_#{System.unique_integer([:positive])}"
      {:ok, session} = SessionSupervisor.start_session(session_id, store: ExWapp.Store.Memory)

      assert is_pid(session)
      assert Process.alive?(session)
      assert ExWapp.state(session) == :idle

      :ok = SessionSupervisor.stop_session(session_id)
    end

    test "get_session returns existing session" do
      session_id = "test_#{System.unique_integer([:positive])}"
      {:ok, session} = SessionSupervisor.start_session(session_id, store: ExWapp.Store.Memory)

      assert {:ok, ^session} = SessionSupervisor.get_session(session_id)

      :ok = SessionSupervisor.stop_session(session_id)
    end

    test "get_session returns error for non-existent session" do
      assert :error = SessionSupervisor.get_session("non_existent_#{System.unique_integer()}")
    end

    test "start_session fails if session already exists" do
      session_id = "test_#{System.unique_integer([:positive])}"
      {:ok, session} = SessionSupervisor.start_session(session_id, store: ExWapp.Store.Memory)

      assert {:error, {:already_started, ^session}} =
               SessionSupervisor.start_session(session_id, store: ExWapp.Store.Memory)

      :ok = SessionSupervisor.stop_session(session_id)
    end

    test "stop_session terminates the session" do
      session_id = "test_#{System.unique_integer([:positive])}"
      {:ok, session} = SessionSupervisor.start_session(session_id, store: ExWapp.Store.Memory)

      :ok = SessionSupervisor.stop_session(session_id)
      Process.sleep(10)

      refute Process.alive?(session)
      assert :error = SessionSupervisor.get_session(session_id)
    end

    test "list_sessions returns all active sessions" do
      id1 = "test_#{System.unique_integer([:positive])}"
      id2 = "test_#{System.unique_integer([:positive])}"

      {:ok, _} = SessionSupervisor.start_session(id1, store: ExWapp.Store.Memory)
      {:ok, _} = SessionSupervisor.start_session(id2, store: ExWapp.Store.Memory)

      sessions = SessionSupervisor.list_sessions()
      session_ids = Enum.map(sessions, fn {id, _pid} -> id end)

      assert id1 in session_ids
      assert id2 in session_ids

      :ok = SessionSupervisor.stop_session(id1)
      :ok = SessionSupervisor.stop_session(id2)
    end

    test "session_exists? returns correct boolean" do
      session_id = "test_#{System.unique_integer([:positive])}"

      refute SessionSupervisor.session_exists?(session_id)

      {:ok, _} = SessionSupervisor.start_session(session_id, store: ExWapp.Store.Memory)
      assert SessionSupervisor.session_exists?(session_id)

      :ok = SessionSupervisor.stop_session(session_id)
      Process.sleep(10)
      refute SessionSupervisor.session_exists?(session_id)
    end
  end
end
