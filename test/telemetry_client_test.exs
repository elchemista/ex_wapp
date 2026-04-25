defmodule ExWapp.TelemetryClientTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  defmodule FailingTransport do
    @behaviour ExWapp.Client.Transport

    def connect(_client), do: {:error, :boom}
    def send_message(_client, _message), do: {:error, :boom}
  end

  defmodule OkTransport do
    @behaviour ExWapp.Client.Transport

    def connect(client), do: {:ok, client}
    def send_message(client, message), do: {:ok, client, message.id}
  end

  def handle_telemetry(event, measurements, metadata, pid) do
    send(pid, {:telemetry, event, measurements, metadata})
  end

  test "high-level facade emits telemetry start/stop events" do
    parent = self()
    handler_id = {:ex_wapp_client_telemetry_test, self()}

    :ok =
      ExWapp.Telemetry.attach_many(
        handler_id,
        &__MODULE__.handle_telemetry/4,
        parent
      )

    on_exit(fn -> ExWapp.Telemetry.detach(handler_id) end)

    client = ExWapp.new(store: ExWapp.Store.Memory, transport: OkTransport, session_id: "t1")

    assert {:ok, _client} = ExWapp.connect(client)

    assert_receive {:telemetry, [:ex_wapp, :client, :connect, :start], _, %{session_id: "t1"}}
    assert_receive {:telemetry, [:ex_wapp, :client, :connect, :stop], %{duration: duration}, _}
    assert is_integer(duration)
  end

  test "telemetry event adapter forwards high-level events" do
    parent = self()
    handler_id = {:ex_wapp_event_telemetry_test, self()}

    :ok =
      ExWapp.Telemetry.attach_many(
        handler_id,
        &__MODULE__.handle_telemetry/4,
        parent
      )

    on_exit(fn -> ExWapp.Telemetry.detach(handler_id) end)

    client =
      ExWapp.new(
        store: ExWapp.Store.Memory,
        transport: OkTransport,
        events: ExWapp.Events.Telemetry,
        session_id: "events"
      )

    assert {:ok, _client} = ExWapp.connect(client)

    assert_receive {:telemetry, [:ex_wapp, :event, :emit], %{count: 1},
                    %{session_id: "events", event_type: :status}}
  end

  test "high-level facade logs failures" do
    client = ExWapp.new(store: ExWapp.Store.Memory, transport: FailingTransport)

    log =
      capture_log(fn ->
        assert {:error, %ExWapp.Error{reason: :boom}, _client} = ExWapp.connect(client)
      end)

    assert log =~ "connect failed"
    assert log =~ ":boom"
  end
end
