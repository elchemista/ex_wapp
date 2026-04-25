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
  end

  defmodule TestEvents do
    @behaviour ExWapp.Events

    @impl true
    def emit(client, event) do
      send(client.metadata.test_pid, {:ex_wapp_event, event})
      :ok
    end
  end

  defmodule WrappedClient do
    use ExWapp.Client,
      store: ExWapp.Store.Memory,
      transport: FakeTransport,
      events: TestEvents
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

  test "use ExWapp.Client generates wrapper helpers without owning OTP" do
    client = WrappedClient.new(session_id: "wrapped", metadata: %{test_pid: self()})

    assert {:ok, connected} = WrappedClient.connect(client)
    assert connected.status == :connected

    assert {:ok, _client, message_id} =
             WrappedClient.send_message(connected,
               to: "15550001111@s.whatsapp.net",
               text: "from wrapper"
             )

    assert_receive {:adapter_send_message, %ExWapp.Message{id: ^message_id}}
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
        metadata: %{session_opts: [reconnect: false]}
      )

    assert {:error, %ExWapp.Error{} = error, failed} =
             ExWapp.send_message(client, to: "15550001111@s.whatsapp.net", text: "hello")

    assert error.reason == {:not_connected, :idle}
    assert is_pid(failed.metadata.session_pid)
    assert ExWapp.Session.state(failed.metadata.session_pid) == :idle
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
