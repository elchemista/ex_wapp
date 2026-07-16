defmodule ExWapp.TelemetryTest do
  use ExUnit.Case, async: false

  def handle_telemetry(event, measurements, metadata, pid) when is_pid(pid) do
    send(pid, {:telemetry_event, event, measurements, metadata})
  end

  setup do
    parent = self()
    handler_id = {:ex_wapp_test, parent, System.unique_integer([:positive])}

    :ok = ExWapp.Telemetry.attach_many(handler_id, &__MODULE__.handle_telemetry/4, parent)

    on_exit(fn ->
      ExWapp.Telemetry.detach(handler_id)
      :ok
    end)

    :ok
  end

  test "events/0 exposes canonical event names" do
    events = ExWapp.Telemetry.events()
    assert [:ex_wapp, :session, :connect] in events
    assert [:ex_wapp, :session, :message_received] in events
    assert [:ex_wapp, :session, :message_sent] in events
    assert [:ex_wapp, :session, :qr] in events
    assert [:ex_wapp, :app_state, :external_blob] in events
    assert [:ex_wapp, :app_state, :decode] in events
    assert [:ex_wapp, :app_state, :dispatch] in events
    assert [:ex_wapp, :store, :flush] in events
  end

  test "emits message_received telemetry from session" do
    {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)

    send(session, {:new_message, "123@s.whatsapp.net", %{id: "m1", raw: %{type: "text"}}})

    assert_receive {:telemetry_event, [:ex_wapp, :session, :message_received], measurements,
                    metadata},
                   1_000

    assert measurements.message_count == 1
    assert metadata.jid == "123@s.whatsapp.net"
    assert metadata.message_id == "m1"
    assert metadata.type == "text"

    GenServer.stop(session)
  end

  test "emits qr telemetry on connection error path" do
    {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)

    send(session, {:connection_event, {:error, :test_error}})

    assert_receive {:telemetry_event, [:ex_wapp, :session, :qr], _measurements, metadata}, 1_000
    assert metadata.event == :error

    GenServer.stop(session)
  end
end
