defmodule ExWapp.ClientApiTest do
  use ExUnit.Case, async: false

  defmodule FakeTransport do
    @behaviour ExWapp.Client.Transport

    @impl true
    def connect(client), do: {:ok, client}

    @impl true
    def pair(client), do: {:ok, client, "qr-payload"}

    @impl true
    def disconnect(client), do: {:ok, client}

    @impl true
    def send_message(client, message) do
      send(client.metadata.test_pid, {:adapter_send_message, message})
      {:ok, client, message.id}
    end

    @impl true
    def receive_message(client, payload, _opts) do
      event =
        ExWapp.Event.new(:message_received, payload,
          session_id: client.session_id,
          metadata: %{source: :fake_transport}
        )

      {:ok, client, [event]}
    end

    @impl true
    def list_contacts(_client), do: {:ok, [%ExWapp.Contact{jid: "15550001111@s.whatsapp.net"}]}

    @impl true
    def get_contact(_client, jid), do: {:ok, %ExWapp.Contact{jid: jid, full_name: "Alice"}}

    @impl true
    def sync_contacts(client), do: {:ok, client}

    @impl true
    def create_contact(client, _jid, _name), do: {:ok, client}

    @impl true
    def update_contact(client, _jid, _attrs), do: {:ok, client}

    @impl true
    def delete_contact(client, _jid), do: {:ok, client}

    @impl true
    def list_chats(_client), do: {:ok, [%ExWapp.Chat{jid: "15550001111@s.whatsapp.net"}]}

    @impl true
    def list_groups(_client), do: {:ok, [%ExWapp.Chat{jid: "123@g.us", is_group: true}]}

    @impl true
    def get_chat(_client, jid), do: {:ok, %ExWapp.Chat{jid: jid}}

    @impl true
    def get_messages(client, jid, opts) do
      send(client.metadata.test_pid, {:adapter_get_messages, jid, opts})
      {:ok, [stored_message()]}
    end

    @impl true
    def stream_messages(client, jid, opts) do
      test_pid = client.metadata.test_pid
      send(test_pid, {:adapter_stream_messages, jid, opts})

      stream =
        Stream.map([stored_message()], fn message ->
          send(test_pid, {:adapter_stream_item, message.id})
          message
        end)

      {:ok, stream}
    end

    @impl true
    def delete_messages(client, jid, message_ids) do
      send(client.metadata.test_pid, {:adapter_delete_messages, jid, message_ids})
      {:ok, client}
    end

    defp stored_message do
      %{
        id: "m1",
        from_me: false,
        timestamp: 1,
        text: "stored",
        status: :received,
        participant: nil,
        raw: nil
      }
    end
  end

  defmodule TestEvents do
    @behaviour ExWapp.Events

    @impl true
    def emit(client, event) do
      send(client.metadata.test_pid, {:ex_wapp_event, event})
      :ok
    end
  end

  test "new/1 builds a runtime-neutral high-level client" do
    client =
      ExWapp.new(
        session_id: "acc_1",
        store: ExWapp.Store.Memory,
        transport: FakeTransport,
        events: TestEvents,
        metadata: %{test_pid: self()}
      )

    assert %ExWapp.Client{} = client
    assert client.session_id == "acc_1"
    assert client.status == :new
    assert client.transport == FakeTransport
  end

  test "client module stays data-only and does not generate wrapper modules" do
    refute function_exported?(ExWapp.Client, :__using__, 1)
  end

  test "connect and pair use adapters and emit high-level events" do
    client = new_client()

    assert {:ok, connected} = ExWapp.connect(client)
    assert ExWapp.status(connected) == :connected
    assert_receive {:ex_wapp_event, %ExWapp.Event{type: :status, payload: :connected}}

    assert {:ok, pairing, "qr-payload"} = ExWapp.pair(connected)
    assert ExWapp.status(pairing) == :pairing
    assert_receive {:ex_wapp_event, %ExWapp.Event{type: :qr, payload: "qr-payload"}}
  end

  test "send_message/2 sends a high-level message without an ExWapp process" do
    client = new_client()

    assert {:ok, updated, message_id} =
             ExWapp.send_message(client, to: "15550001111@s.whatsapp.net", text: "hello")

    assert is_binary(message_id)
    assert ExWapp.last_error(updated) == nil

    assert_receive {:adapter_send_message,
                    %ExWapp.Message{
                      id: ^message_id,
                      to: "15550001111@s.whatsapp.net",
                      type: :text,
                      body: "hello"
                    }}

    assert_receive {:ex_wapp_event,
                    %ExWapp.Event{
                      type: :message_sent,
                      payload: %{id: ^message_id, to: "15550001111@s.whatsapp.net"}
                    }}
  end

  test "receive_message/3 delegates inbound payloads and emits returned events" do
    client = new_client()

    assert {:ok, updated, [%ExWapp.Event{} = event]} =
             ExWapp.receive_message(client, %{from: "15550001111@s.whatsapp.net", text: "hi"})

    assert updated.trace |> hd() |> Map.fetch!(:operation) == :receive_message
    assert event.type == :message_received

    assert_receive {:ex_wapp_event,
                    %ExWapp.Event{
                      type: :message_received,
                      payload: %{from: "15550001111@s.whatsapp.net", text: "hi"}
                    }}
  end

  test "contact and group APIs delegate through the high-level transport" do
    client = new_client()

    assert {:ok, [%ExWapp.Contact{}]} = ExWapp.list_contacts(client)

    assert {:ok, %ExWapp.Contact{full_name: "Alice"}} =
             ExWapp.get_contact(client, "15550001111@s.whatsapp.net")

    assert {:ok, synced} = ExWapp.sync_contacts(client)
    assert_receive {:ex_wapp_event, %ExWapp.Event{type: :contacts_synced}}

    assert {:ok, _} = ExWapp.create_contact(synced, "15550001111@s.whatsapp.net", "Alice")
    assert_receive {:ex_wapp_event, %ExWapp.Event{type: :contact_created}}

    assert {:ok, [%ExWapp.Chat{}]} = ExWapp.list_chats(client)
    assert {:ok, [%ExWapp.Chat{is_group: true}]} = ExWapp.list_groups(client)
    assert {:ok, %ExWapp.Chat{jid: "123@g.us"}} = ExWapp.get_chat(client, "123@g.us")
  end

  test "message history APIs delegate through the high-level transport" do
    client = new_client()
    jid = "15550001111@s.whatsapp.net"

    assert {:ok, [%{id: "m1"}]} = ExWapp.get_messages(client, jid, limit: 10, offset: 5)
    assert_receive {:adapter_get_messages, ^jid, [limit: 10, offset: 5]}

    assert {:ok, stream} = ExWapp.all_messages(client, jid)
    assert_receive {:adapter_stream_messages, ^jid, [limit: :all, order: :oldest_first]}
    refute_receive {:adapter_stream_item, _}

    assert [%{id: "m1"}] = Enum.to_list(stream)
    assert_receive {:adapter_stream_item, "m1"}

    assert {:ok, _client} = ExWapp.delete_messages(client, jid, ["m1"])
    assert_receive {:adapter_delete_messages, ^jid, ["m1"]}
  end

  test "send_image/4 and send_audio/4 build high-level media messages" do
    client = new_client()

    assert {:ok, _client, image_id} =
             ExWapp.send_image(client, "15550001111@s.whatsapp.net", {:bytes, "img"},
               mimetype: "image/jpeg"
             )

    assert_receive {:adapter_send_message,
                    %ExWapp.Message{id: ^image_id, type: :image, body: {:bytes, "img"}}}

    assert {:ok, _client, audio_id} =
             ExWapp.send_audio(client, "15550001111@s.whatsapp.net", {:bytes, "aud"},
               mimetype: "audio/ogg; codecs=opus",
               ptt: true
             )

    assert_receive {:adapter_send_message,
                    %ExWapp.Message{id: ^audio_id, type: :audio, body: {:bytes, "aud"}}}
  end

  test "adapter failures return structured client errors" do
    client = ExWapp.new(store: ExWapp.Store.Memory, metadata: %{test_pid: self()})

    assert {:error, %ExWapp.Error{} = error, failed} = ExWapp.connect(client)
    assert error.operation == :connect
    assert error.phase == :transport
    assert error.reason == :missing_transport
    assert failed.status == :error
    assert ExWapp.last_error(failed) == error
  end

  test "built-in session transport wires high-level send into session engine" do
    session_id = "session_transport_#{System.unique_integer([:positive])}"
    on_exit(fn -> ExWapp.Session.Supervisor.stop_session(session_id) end)

    client =
      ExWapp.new(
        session_id: session_id,
        store: ExWapp.Store.Memory,
        transport: ExWapp.Client.Transport.Session,
        runtime: [iq: [default_timeout_ms: 1_234]],
        metadata: %{session_opts: [reconnect: false]}
      )

    assert {:error, %ExWapp.Error{} = error, failed} =
             ExWapp.send_message(client, to: "15550001111@s.whatsapp.net", text: "hello")

    assert error.reason == {:not_connected, :idle}
    assert is_pid(failed.metadata.session_pid)
    assert ExWapp.Session.state(failed.metadata.session_pid) == :idle

    assert get_in(ExWapp.Session.runtime_config(failed.metadata.session_pid), [
             :iq,
             :default_timeout_ms
           ]) == 1_234

    assert %ExWapp.Session.Options{session_id: ^session_id, reconnect: false} =
             :sys.get_state(failed.metadata.session_pid).opts
  end

  test "built-in session transport converts session subscriber messages into events" do
    client =
      ExWapp.new(
        session_id: "recv_session",
        store: ExWapp.Store.Memory,
        transport: ExWapp.Client.Transport.Session,
        events: TestEvents,
        metadata: %{test_pid: self()}
      )

    payload = {:ex_wapp_message, "15550001111@s.whatsapp.net", %{id: "m1", text: "hi"}}

    assert {:ok, _client, [%ExWapp.Event{} = event]} = ExWapp.receive_message(client, payload)
    assert event.type == :message_received
    assert event.payload.jid == "15550001111@s.whatsapp.net"
    assert event.payload.message.text == "hi"
  end

  defp new_client do
    ExWapp.new(
      session_id: "acc_1",
      store: ExWapp.Store.Memory,
      transport: FakeTransport,
      events: TestEvents,
      metadata: %{test_pid: self()}
    )
  end
end
