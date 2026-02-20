defmodule ExWappTest do
  use ExUnit.Case, async: false

  alias ExWapp.Session
  alias ExWapp.Session.Supervisor, as: SessionSupervisor

  defmodule FakeTransport do
    def start_link(_opts) do
      {:ok, spawn_link(fn -> Process.sleep(:infinity) end)}
    end

    def send_node(_conn, _node), do: :ok
  end

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

  describe "App state sync stability" do
    test "app-state mutation request on connected session does not crash" do
      key_id_hex = Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
      key_data = :crypto.strong_rand_bytes(32)

      {:ok, session} =
        ExWapp.start_link(
          reconnect: false,
          store:
            {ExWapp.Store.Memory,
             initial_data: %{
               app_state_keys: %{
                 key_id_hex => %{data: key_data, timestamp: 1}
               }
             }}
        )

      send(session, {:connection_event, {:noise, :handshake_completed}})
      assert eventually(fn -> ExWapp.state(session) == :connected end)

      assert {:error, _reason} = ExWapp.unarchive_chat(session, "120363424063038804@g.us")
      assert Process.alive?(session)

      GenServer.stop(session)
    end

    test "sync_contacts returns not_connected when session is idle" do
      {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)

      assert {:error, {:not_connected, :idle}} = ExWapp.sync_contacts(session)

      GenServer.stop(session)
    end

    test "initial app-state sync from persisted keys is requested once per connection cycle" do
      key_id_hex = Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
      key_data = :crypto.strong_rand_bytes(32)

      {:ok, session} =
        ExWapp.start_link(
          reconnect: false,
          transport: FakeTransport,
          store:
            {ExWapp.Store.Memory,
             initial_data: %{
               app_state_keys: %{
                 key_id_hex => %{data: key_data, timestamp: 1}
               }
             }}
        )

      conn = spawn_link(fn -> Process.sleep(:infinity) end)

      :sys.replace_state(session, fn state ->
        %{state | conn: conn, status: :handshaking, app_state_initial_sync_requested: false}
      end)

      send(session, {:connection_event, {:noise, :handshake_completed}})

      assert eventually(fn ->
               state = :sys.get_state(session)

               state.app_state_initial_sync_requested and map_size(state.pending_iqs) > 0
             end)

      first_pending_count = map_size(:sys.get_state(session).pending_iqs)

      send(session, {:connection_event, {:noise, :handshake_completed}})
      Process.sleep(50)

      state_after_duplicate = :sys.get_state(session)
      assert state_after_duplicate.app_state_initial_sync_requested
      assert map_size(state_after_duplicate.pending_iqs) == first_pending_count

      send(session, {:connection_event, {:transport, {:closed, :test}}})

      assert eventually(fn ->
               state = :sys.get_state(session)

               state.app_state_initial_sync_requested == false and
                 map_size(state.pending_iqs) == 0
             end)

      :sys.replace_state(session, fn state ->
        %{state | conn: conn, status: :handshaking}
      end)

      send(session, {:connection_event, {:noise, :handshake_completed}})

      assert eventually(fn ->
               state = :sys.get_state(session)

               state.app_state_initial_sync_requested and
                 map_size(state.pending_iqs) > 0
             end)

      GenServer.stop(session)
      Process.exit(conn, :kill)
    end
  end

  describe "Chat listing" do
    test "add_message initializes chats map when store has no :chats key" do
      {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)

      :ok =
        ExWapp.Chat.add_message(session, "999000111@s.whatsapp.net", %{
          id: "m1",
          from_me: false,
          timestamp: 123,
          text: "hello",
          status: :received,
          participant: nil,
          raw: nil
        })

      chats = ExWapp.list_chats(session)
      assert length(chats) == 1
      assert hd(chats).jid == "999000111@s.whatsapp.net"

      GenServer.stop(session)
    end

    test "list_groups returns only group chats" do
      {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)

      :ok =
        ExWapp.Chat.add_message(session, "12345@g.us", %{
          id: "g1",
          from_me: false,
          timestamp: 1,
          text: "group",
          status: :sent,
          participant: nil,
          raw: nil
        })

      :ok =
        ExWapp.Chat.add_message(session, "555000111@s.whatsapp.net", %{
          id: "d1",
          from_me: false,
          timestamp: 2,
          text: "direct",
          status: :sent,
          participant: nil,
          raw: nil
        })

      groups = ExWapp.list_groups(session)

      assert length(groups) == 1
      assert hd(groups).jid == "12345@g.us"

      GenServer.stop(session)
    end
  end

  describe "PubSub subscription" do
    test "subscribe/1 receives broadcasted messages" do
      session_id = "pubsub_test_#{System.unique_integer([:positive])}"

      {:ok, session} =
        ExWapp.start_link(store: ExWapp.Store.Memory, session_id: session_id)

      :ok = ExWapp.subscribe(session_id)

      # Simulate an incoming message arriving at the session
      send(session, {:new_message, "1234@s.whatsapp.net", %{text: "hello", id: "test1"}})

      assert_receive {:ex_wapp_message, "1234@s.whatsapp.net", %{text: "hello"}}, 1_000

      ExWapp.unsubscribe(session_id)
      GenServer.stop(session)
    end
  end

  describe "Message handling persistence" do
    test "incoming message node is persisted to chats on empty store" do
      {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)

      node = %ExWapp.Binary.Node{
        tag: "message",
        attrs: %{
          "from" => "15550001111@s.whatsapp.net",
          "id" => "MSG_1",
          "type" => "text",
          "t" => "1730000000"
        },
        content: [%ExWapp.Binary.Node{tag: "body", attrs: %{}, content: "hello"}]
      }

      state = %{stats: %{messages_received: 0}}
      assert {:ok, _new_state, _actions} = ExWapp.MessageHandler.handle_node(node, session, state)

      chats = ExWapp.list_chats(session)
      assert length(chats) == 1
      assert hd(chats).jid == "15550001111@s.whatsapp.net"

      GenServer.stop(session)
    end

    test "connection_event message persists when handled inside Session process" do
      {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)

      node = %ExWapp.Binary.Node{
        tag: "message",
        attrs: %{
          "from" => "15550001111@s.whatsapp.net",
          "id" => "MSG_2",
          "type" => "text",
          "t" => "1730000001"
        },
        content: [%ExWapp.Binary.Node{tag: "body", attrs: %{}, content: "inside-session"}]
      }

      send(session, {:connection_event, {:connection_message, node}})
      Process.sleep(50)

      chats = ExWapp.list_chats(session)
      assert length(chats) == 1
      assert hd(chats).jid == "15550001111@s.whatsapp.net"
      assert hd(chats).messages |> hd() |> Map.get(:id) == "MSG_2"

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

  defp eventually(fun, attempts \\ 80)
  defp eventually(_fun, 0), do: false

  defp eventually(fun, attempts) when is_function(fun, 0) and attempts > 0 do
    result =
      try do
        fun.()
      rescue
        _ -> false
      catch
        :exit, _ -> false
      end

    if result do
      true
    else
      Process.sleep(10)
      eventually(fun, attempts - 1)
    end
  end
end
