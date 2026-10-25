defmodule ExWapp.TelemetryAdapterTest do
  use ExUnit.Case, async: false

  alias ExWapp.Telemetry

  defmodule Recorder do
    @behaviour Telemetry.Adapter

    def execute(event, measurements, %{session_id: pid} = metadata) do
      send(pid, {:instrumented, event, measurements, metadata})
      :ok
    end

    def attach_many(id, events, handler, config) do
      send(id, {:attached, events, handler, config})
      :ok
    end

    def detach(id) do
      send(id, :detached)
      :ok
    end
  end

  defmodule Emitter do
    @behaviour Telemetry.Adapter
    def execute(_event, _measurements, _metadata), do: :ok
  end

  defmodule BrokenAdapter do
    @behaviour Telemetry.Adapter

    def execute(_event, _measurements, metadata) do
      case Map.get(metadata, :failure, :raise) do
        :raise -> raise "instrumentation failed"
        :throw -> throw(:instrumentation_failed)
        :exit -> exit(:instrumentation_failed)
      end
    end

    def attach_many(:invalid, _events, _handler, _config), do: :unexpected
    def attach_many(:crash, _events, _handler, _config), do: raise("attach failed")
    def attach_many(_id, _events, _handler, _config), do: {:error, :already_exists}
    def detach(_id), do: exit(:backend_unavailable)
  end

  defmodule Transport do
    @behaviour ExWapp.Client.Transport
    def connect(client), do: {:ok, client}
    def send_message(client, message), do: {:ok, client, message.id}
  end

  setup do
    previous = Application.fetch_env(:ex_wapp, :telemetry_adapter)

    on_exit(fn ->
      case previous do
        {:ok, value} -> Application.put_env(:ex_wapp, :telemetry_adapter, value)
        :error -> Application.delete_env(:ex_wapp, :telemetry_adapter)
      end
    end)

    :ok
  end

  test "instrumentation is disabled without an adapter even when telemetry is installed" do
    Application.delete_env(:ex_wapp, :telemetry_adapter)
    id = {:disabled, self()}
    parent = self()

    :ok = :telemetry.attach_many(id, Telemetry.events(), &__MODULE__.receive_event/4, parent)
    on_exit(fn -> :telemetry.detach(id) end)

    assert :ok = Telemetry.execute(:connect, %{count: 1})
    assert {:ok, _client} = ExWapp.connect(client())
    refute_receive {:unexpected_telemetry, _}
    assert {:error, :telemetry_not_configured} = Telemetry.attach_many(id, &receive_event/4)
    assert {:error, :telemetry_not_configured} = Telemetry.detach(id)
  end

  test "instrumentation loads and runs when the telemetry package is absent from the code path" do
    source = """
    false = Code.ensure_loaded?(:telemetry)
    :ok = ExWapp.Telemetry.execute(:connect, %{count: 1})
    Application.put_env(:ex_wapp, :telemetry_adapter, :telemetry)
    :ok = ExWapp.Telemetry.execute(:connect, %{count: 1})
    {:error, {:invalid_telemetry_adapter, :telemetry}} = ExWapp.Telemetry.detach(:id)
    """

    {output, status} =
      System.cmd(
        System.find_executable("elixir"),
        [
          "--erl",
          "+S 2:2",
          "-r",
          Path.expand("../lib/ex_wapp/telemetry.ex", __DIR__),
          "-e",
          source
        ],
        stderr_to_stdout: true
      )

    assert status == 0, output
  end

  test "custom backend receives session, client and high-level event instrumentation" do
    Application.put_env(:ex_wapp, :telemetry_adapter, Recorder)

    assert :ok = Telemetry.execute(:connected, %{count: 1}, %{session_id: self()})
    assert_receive {:instrumented, [:ex_wapp, :session, :connected], %{count: 1}, _}

    assert {:ok, _client} = ExWapp.connect(client())
    assert_receive {:instrumented, [:ex_wapp, :client, :connect, :start], %{count: 1}, _}
    assert_receive {:instrumented, [:ex_wapp, :client, :connect, :stop], %{duration: duration}, _}
    assert is_integer(duration)
    assert_receive {:instrumented, [:ex_wapp, :event, :emit], %{count: 1}, %{event_type: :status}}

    handler = &receive_event/4
    assert :ok = Telemetry.attach_many(self(), handler, :configuration)
    assert_receive {:attached, events, ^handler, :configuration}
    assert events == Telemetry.events()
    assert :ok = Telemetry.detach(self())
    assert_receive :detached
  end

  test "custom backends can implement emission without handler management" do
    Application.put_env(:ex_wapp, :telemetry_adapter, Emitter)
    assert :ok = Telemetry.execute(:connect, %{})

    assert {:error, {:unsupported_telemetry_callback, :attach_many}} =
             Telemetry.attach_many(:id, &receive_event/4)

    assert {:error, {:unsupported_telemetry_callback, :detach}} = Telemetry.detach(:id)
  end

  test "invalid or unavailable adapters cannot break client operations" do
    for adapter <- ["not a module", MissingInstrumentationBackend, String] do
      Application.put_env(:ex_wapp, :telemetry_adapter, adapter)
      assert :ok = Telemetry.execute(:connect, %{})
      assert {:ok, _client} = ExWapp.connect(client())
      assert {:error, _} = Telemetry.attach_many(:id, &receive_event/4)
    end
  end

  test "backend exceptions, throws and exits are isolated from protocol operations" do
    Application.put_env(:ex_wapp, :telemetry_adapter, BrokenAdapter)

    for failure <- [:raise, :throw, :exit] do
      assert :ok = Telemetry.execute(:connect, %{}, %{failure: failure})
    end

    assert {:ok, _client} = ExWapp.connect(client())

    session =
      start_supervised!({ExWapp.Session, store: ExWapp.Store.Memory, auto_connect: false})

    assert ExWapp.state(session) == :idle
    assert Process.alive?(session)

    assert {:error, :already_exists} = Telemetry.attach_many(:exists, &receive_event/4)

    assert {:error, :invalid_telemetry_response} =
             Telemetry.attach_many(:invalid, &receive_event/4)

    assert {:error, %RuntimeError{}} = Telemetry.attach_many(:crash, &receive_event/4)
    assert {:error, {:exit, :backend_unavailable}} = Telemetry.detach(:id)
  end

  def receive_event(event, _measurements, _metadata, pid),
    do: send(pid, {:unexpected_telemetry, event})

  defp client do
    ExWapp.new(
      store: ExWapp.Store.Memory,
      transport: Transport,
      events: ExWapp.Events.Telemetry,
      session_id: self()
    )
  end
end
