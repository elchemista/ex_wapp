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

  defmodule FailingTransport do
    def start_link(_opts), do: {:error, :boom}
    def send_node(_conn, _node), do: :ok
  end

  defmodule TrackingTransport do
    def start_link(_opts) do
      {:ok, spawn_link(fn -> Process.sleep(:infinity) end)}
    end

    def send_node(conn, node) do
      send(conn, {:transport_send, node})
      :ok
    end

    def restart_stream(conn) do
      send(conn, :transport_restart_stream)
      :ok
    end
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
    test "send_text returns not_connected when session is disconnected" do
      {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)

      :sys.replace_state(session, fn state ->
        %{state | status: :disconnected, conn: nil}
      end)

      assert {:error, {:not_connected, :disconnected}} =
               ExWapp.send_text(session, "15550001111@s.whatsapp.net", "hello")

      GenServer.stop(session)
    end

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

      send(session, {:connection_event, {:auth, :ready}})
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
      if Process.whereis(ExWapp.PubSub) == nil do
        start_supervised!({Phoenix.PubSub, name: ExWapp.PubSub})
      end

      key_id_hex = Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
      key_data = :crypto.strong_rand_bytes(32)
      session_id = "session-syncing-#{System.unique_integer([:positive])}"

      Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:session:#{session_id}")

      {:ok, session} =
        ExWapp.start_link(
          reconnect: false,
          transport: FakeTransport,
          session_id: session_id,
          store:
            {ExWapp.Store.Memory,
             initial_data: %{
               app_state_keys: %{
                 key_id_hex => %{data: key_data, timestamp: 1}
               }
             }}
        )

      conn = spawn(fn -> Process.sleep(:infinity) end)

      :sys.replace_state(session, fn state ->
        %{state | conn: conn, status: :handshaking, app_state_initial_sync_requested: false}
      end)

      send(session, {:connection_event, {:auth, :ready}})

      assert_receive {:ex_wapp_session, :post_auth_ready,
                      %{status: :syncing, initial_sync_pending?: true}},
                     1_000

      assert eventually(fn ->
               state = :sys.get_state(session)

               state.app_state_initial_sync_requested and map_size(state.pending_iqs) > 0
             end)

      first_pending_count = map_size(:sys.get_state(session).pending_iqs)

      send(session, {:connection_event, {:auth, :ready}})
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

      send(session, {:connection_event, {:auth, :ready}})

      assert eventually(fn ->
               state = :sys.get_state(session)

               state.app_state_initial_sync_requested and
                 map_size(state.pending_iqs) > 0
             end)

      GenServer.stop(session)
      Process.exit(conn, :kill)
    end

    test "auth ready without app-state keys does not broadcast initial sync completed" do
      if Process.whereis(ExWapp.PubSub) == nil do
        start_supervised!({Phoenix.PubSub, name: ExWapp.PubSub})
      end

      session_id = "session-no-keys"

      Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:session:#{session_id}")

      {:ok, session} =
        ExWapp.start_link(
          reconnect: false,
          transport: FakeTransport,
          store: ExWapp.Store.Memory,
          session_id: session_id
        )

      conn = spawn(fn -> Process.sleep(:infinity) end)

      :sys.replace_state(session, fn state ->
        %{state | conn: conn, status: :handshaking, app_state_initial_sync_requested: false}
      end)

      send(session, {:connection_event, {:auth, :ready}})

      assert_receive {:ex_wapp_session, :post_auth_ready,
                      %{status: :connected, initial_sync_pending?: false}},
                     1_000

      refute_receive {:ex_wapp_session, :initial_sync, :completed, _payload}, 200

      state = :sys.get_state(session)
      assert state.status == :connected
      assert state.app_state_initial_sync_requested == false

      GenServer.stop(session)
      Process.exit(conn, :kill)
    end

    test "auth ready can skip initial app-state sync even when keys are present" do
      if Process.whereis(ExWapp.PubSub) == nil do
        start_supervised!({Phoenix.PubSub, name: ExWapp.PubSub})
      end

      key_id_hex = Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
      key_data = :crypto.strong_rand_bytes(32)
      session_id = "session-skip-initial-sync"

      Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:session:#{session_id}")

      {:ok, session} =
        ExWapp.start_link(
          reconnect: false,
          transport: FakeTransport,
          runtime: [app_state: [initial_sync_enabled: false]],
          store:
            {ExWapp.Store.Memory,
             initial_data: %{
               app_state_keys: %{
                 key_id_hex => %{data: key_data, timestamp: 1}
               }
             }},
          session_id: session_id
        )

      conn = spawn(fn -> Process.sleep(:infinity) end)

      :sys.replace_state(session, fn state ->
        %{state | conn: conn, status: :handshaking, app_state_initial_sync_requested: false}
      end)

      send(session, {:connection_event, {:auth, :ready}})

      assert_receive {:ex_wapp_session, :post_auth_ready,
                      %{status: :connected, initial_sync_pending?: false}},
                     1_000

      refute_receive {:ex_wapp_session, :initial_sync, :started, _payload}, 200

      state = :sys.get_state(session)
      assert state.status == :connected
      assert state.app_state_initial_sync_requested == false
      assert map_size(state.pending_iqs) == 0

      GenServer.stop(session)
      Process.exit(conn, :kill)
    end

    test "initial app-state sync failure is broadcast and still releases the sync gate" do
      if Process.whereis(ExWapp.PubSub) == nil do
        start_supervised!({Phoenix.PubSub, name: ExWapp.PubSub})
      end

      key_id_hex = Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
      key_data = :crypto.strong_rand_bytes(32)
      session_id = "session-sync-failed-#{System.unique_integer([:positive])}"

      Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:session:#{session_id}")

      {:ok, session} =
        ExWapp.start_link(
          reconnect: false,
          transport: FakeTransport,
          session_id: session_id,
          store:
            {ExWapp.Store.Memory,
             initial_data: %{
               app_state_keys: %{
                 key_id_hex => %{data: key_data, timestamp: 1}
               }
             }}
        )

      :sys.replace_state(session, fn state ->
        %{state | conn: nil, status: :handshaking, app_state_initial_sync_requested: false}
      end)

      send(session, {:connection_event, {:auth, :ready}})

      assert_receive {:ex_wapp_session, :post_auth_ready, %{status: :syncing}}, 1_000
      assert_receive {:ex_wapp_session, :initial_sync, :started, _payload}, 1_000

      assert_receive {:ex_wapp_session, :initial_sync, :failed,
                      {:collection_fetch_failed, failures}, payload},
                     1_000

      assert failures != []
      assert payload.success_count == 0
      assert eventually(fn -> ExWapp.state(session) == :connected end)

      GenServer.stop(session)
    end

    test "outbound queue stays detached until Noise handshake completes" do
      {:ok, session} =
        GenServer.start(ExWapp.Session.Worker,
          store: ExWapp.Store.Memory,
          transport: TrackingTransport,
          runtime: [health: [check_interval_ms: 60_000]]
        )

      conn = self()

      :sys.replace_state(session, fn state ->
        %{state | conn: conn, status: :connecting, transport_ready?: false}
      end)

      queue = :sys.get_state(session).outbound_queue

      node = %ExWapp.Binary.Node{
        tag: "presence",
        attrs: %{"type" => "available"},
        content: nil
      }

      ExWapp.Session.OutboundQueue.enqueue_node(queue, node)

      refute_receive {:transport_send, ^node}, 100
      assert :sys.get_state(queue).conn == nil

      send(session, {:connection_event, {:noise, :handshake_started}})
      Process.sleep(50)

      refute_receive {:transport_send, ^node}, 100
      assert :sys.get_state(queue).conn == nil

      send(session, {:connection_event, {:noise, :handshake_completed}})

      assert_receive {:transport_send, ^node}, 1_000
      assert :sys.get_state(queue).conn == conn

      GenServer.stop(session)
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

    test "get_messages supports pagination and all locally retained messages" do
      {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)
      jid = "999000111@s.whatsapp.net"

      for {id, timestamp} <- [{"m1", 1}, {"m2", 2}, {"m3", 3}] do
        :ok =
          ExWapp.Chat.add_message(session, jid, %{
            id: id,
            from_me: false,
            timestamp: timestamp,
            text: id,
            status: :received,
            participant: nil,
            raw: nil
          })
      end

      assert [%{id: "m2"}, %{id: "m1"}] =
               ExWapp.get_messages(session, jid, limit: 2, offset: 1)

      assert Enum.map(ExWapp.all_messages(session, jid), & &1.id) == ["m1", "m2", "m3"]

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

    test "subscribe/1 receives session error events from connection errors" do
      session_id = "pubsub_err_conn_#{System.unique_integer([:positive])}"

      {:ok, session} =
        ExWapp.start_link(store: ExWapp.Store.Memory, session_id: session_id)

      :ok = ExWapp.subscribe(session_id)

      send(session, {:connection_event, {:error, :test_error}})

      assert_receive {:ex_wapp_session, :error, :test_error}, 1_000

      ExWapp.unsubscribe(session_id)
      GenServer.stop(session)
    end

    test "subscribe/1 receives session error events from server failure nodes" do
      session_id = "pubsub_err_failure_#{System.unique_integer([:positive])}"

      {:ok, session} =
        ExWapp.start_link(store: ExWapp.Store.Memory, session_id: session_id)

      :ok = ExWapp.subscribe(session_id)

      send(
        session,
        {:inbound_node,
         %ExWapp.Binary.Node{
           tag: "failure",
           attrs: %{"reason" => "403", "location" => "test_location"},
           content: nil
         }}
      )

      assert_receive {:ex_wapp_session, :error,
                      {:connection_failure, :forbidden, "test_location"}},
                     1_000

      ExWapp.unsubscribe(session_id)
      GenServer.stop(session)
    end

    test "subscribe/1 receives disconnected event on stream:error" do
      session_id = "pubsub_stream_disc_#{System.unique_integer([:positive])}"

      {:ok, session} =
        ExWapp.start_link(
          store: ExWapp.Store.Memory,
          session_id: session_id,
          reconnect: false
        )

      :ok = ExWapp.subscribe(session_id)

      conn = spawn(fn -> Process.sleep(:infinity) end)
      conn_ref = Process.monitor(conn)

      :sys.replace_state(session, fn state ->
        %{state | conn: conn, conn_ref: conn_ref, status: :connected}
      end)

      send(
        session,
        {:inbound_node,
         %ExWapp.Binary.Node{tag: "stream:error", attrs: %{"code" => "515"}, content: nil}}
      )

      assert_receive {:ex_wapp_session, :disconnected,
                      {:transport_closed, {:stream_error, "515", nil}}, payload},
                     1_000

      assert payload.status == :disconnected
      assert payload.transport_ready? == false

      assert eventually(fn -> ExWapp.state(session) == :idle end)

      ExWapp.unsubscribe(session_id)
      if Process.alive?(conn), do: Process.exit(conn, :normal)
      GenServer.stop(session)
    end

    test "vext-managed sessions surface connect failures and do not auto-reconnect" do
      session_id = "pubsub_vext_managed_connect_#{System.unique_integer([:positive])}"

      {:ok, session} =
        ExWapp.start_link(
          store: ExWapp.Store.Memory,
          session_id: session_id,
          transport: FailingTransport,
          runtime: [
            ownership: [vext_managed: true],
            reconnect: [enabled: true, max_attempts: 3, initial_backoff_ms: 10, jitter_ms: 0]
          ]
        )

      :ok = ExWapp.subscribe(session_id)

      ExWapp.connect(session)

      assert_receive {:ex_wapp_session, :disconnected, {:connect_failed, :boom}, payload}, 1_000
      assert payload.status == :idle

      Process.sleep(50)
      state = :sys.get_state(session)
      assert state.status == :disconnected
      assert state.reconnect_attempts == 0

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

    test "incoming message receipt preserves recipient and omits forced delivery type" do
      node = %ExWapp.Binary.Node{
        tag: "message",
        attrs: %{
          "from" => "15550001111@s.whatsapp.net",
          "recipient" => "15550002222@s.whatsapp.net",
          "id" => "MSG_RECEIPT_1",
          "type" => "text",
          "t" => "1730000000"
        },
        content: [%ExWapp.Binary.Node{tag: "body", attrs: %{}, content: "hello"}]
      }

      {_new_state, actions} =
        ExWapp.Session.Worker.Inbound.handle_message_node(
          node,
          %{stats: %{messages_received: 0}},
          &ExWapp.Session.Worker.ReceiptBuilder.build_receipt_ack/5,
          fn _, _, _, _, _, _, _ ->
            flunk("unexpected retry receipt")
          end
        )

      assert [
               {:send_node, %ExWapp.Binary.Node{tag: "receipt", attrs: attrs, content: nil}}
             ] = actions

      assert attrs["id"] == "MSG_RECEIPT_1"
      assert attrs["to"] == "15550001111@s.whatsapp.net"
      assert attrs["recipient"] == "15550002222@s.whatsapp.net"
      refute Map.has_key?(attrs, "type")
    end

    test "incoming receipt stanza is acknowledged" do
      node = %ExWapp.Binary.Node{
        tag: "receipt",
        attrs: %{
          "from" => "15550001111@s.whatsapp.net",
          "participant" => "15550003333@s.whatsapp.net",
          "recipient" => "15550002222@s.whatsapp.net",
          "id" => "RCPT_1",
          "type" => "read"
        },
        content: nil
      }

      assert {:ok, _state, actions} = ExWapp.MessageHandler.handle_node(node, :session, %{})

      assert [
               {:send_node, %ExWapp.Binary.Node{tag: "ack", attrs: attrs, content: nil}}
             ] = actions

      assert attrs["class"] == "receipt"
      assert attrs["id"] == "RCPT_1"
      assert attrs["to"] == "15550001111@s.whatsapp.net"
      assert attrs["type"] == "read"
      assert attrs["participant"] == "15550003333@s.whatsapp.net"
      assert attrs["recipient"] == "15550002222@s.whatsapp.net"
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
      refute Map.has_key?(hd(chats), :messages)

      assert [%{id: "MSG_2"}] =
               ExWapp.get_messages(session, "15550001111@s.whatsapp.net", limit: 1)

      GenServer.stop(session)
    end

    test "message history is streamed outside the chat struct without a retention cap" do
      store = ExWapp.Store.Memory.new()
      jid = "15550001111@s.whatsapp.net"

      messages =
        Enum.map(1..1_001, fn number ->
          %{
            id: "history-#{number}",
            from_me: false,
            timestamp: number,
            text: "message #{number}",
            status: :received,
            participant: nil,
            raw: nil
          }
        end)

      assert :ok = ExWapp.Chat.merge_messages(store, jid, messages)
      assert {:ok, chat} = ExWapp.Chat.get(store, jid)
      refute Map.has_key?(chat, :messages)

      stream = ExWapp.all_messages(store, jid)
      assert %Stream{} = stream
      assert Enum.count(stream) == 1_001
      assert [%{id: "history-1"}] = Enum.take(stream, 1)

      assert :ok = ExWapp.delete_messages(store, jid, ["history-1"])
      assert Enum.count(ExWapp.all_messages(store, jid)) == 1_000
    end

    test "history streams preserve decoded typed content" do
      store = ExWapp.Store.Memory.new()
      jid = "15550001111@s.whatsapp.net"

      typed_content = %{
        content: %{kind: :image, value: %{caption: "photo"}},
        media: %{direct_path: "/media/image"},
        location: %{latitude: 45.4642, longitude: 9.19},
        contact: %{display_name: "Alice"},
        event: %{name: "Meeting"}
      }

      message =
        Map.merge(
          %{
            id: "typed-history-1",
            from_me: false,
            timestamp: 10,
            text: nil,
            status: :received,
            participant: nil,
            raw: nil
          },
          typed_content
        )

      assert :ok = ExWapp.Chat.merge_messages(store, jid, [message])
      assert [stored] = Enum.to_list(ExWapp.all_messages(store, jid))
      assert Map.take(stored, Map.keys(typed_content)) == typed_content
    end
  end

  describe "Signal session persistence" do
    test "signal sessions survive worker restart via persisted store" do
      path =
        Path.join(
          System.tmp_dir!(),
          "ex_wapp_signal_sessions_#{System.unique_integer([:positive])}.etf"
        )

      on_exit(fn -> File.rm_rf(path) end)

      persisted_sessions =
        ExWapp.Signal.SessionStore.new()
        |> ExWapp.Signal.SessionStore.put_session("15550001111:2@s.whatsapp.net", %{
          remote_identity_key: <<1, 2, 3, 4>>,
          local_identity_key: %{public: <<5, 6, 7, 8>>, private: <<9, 10, 11, 12>>},
          root_key: <<13, 14, 15, 16>>,
          sending_chain: %{key: <<17, 18, 19, 20>>, counter: 2, message_keys: %{}},
          receiving_chain: %{key: <<21, 22, 23, 24>>, counter: 1, message_keys: %{}},
          previous_counter: 1,
          ratchet_key: %{public: <<25, 26, 27, 28>>, private: <<29, 30, 31, 32>>},
          remote_ratchet_key: <<33, 34, 35, 36>>
        })

      {:ok, session1} =
        ExWapp.start_link(
          store: {ExWapp.Store.Ets, path: path},
          reconnect: false
        )

      assert :ok = GenServer.call(session1, {:update_signal_sessions, persisted_sessions})

      assert ExWapp.Signal.SessionStore.snapshot(persisted_sessions) ==
               ExWapp.Signal.SessionStore.snapshot(GenServer.call(session1, :get_signal_sessions))

      GenServer.stop(session1)

      {:ok, session2} =
        ExWapp.start_link(
          store: {ExWapp.Store.Ets, path: path},
          reconnect: false
        )

      assert ExWapp.Signal.SessionStore.snapshot(persisted_sessions) ==
               ExWapp.Signal.SessionStore.snapshot(GenServer.call(session2, :get_signal_sessions))

      GenServer.stop(session2)
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
