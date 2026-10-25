defmodule ExWapp.Events do
  @moduledoc """
  Behaviour for delivering high-level ExWapp events.

  This deliberately does not prescribe PubSub, process messages, or OTP. Host
  applications choose how subscriptions work by implementing this behaviour.
  """

  alias ExWapp.{Client, Event}

  @callback emit(Client.t(), Event.t()) :: :ok | {:error, term()}

  @doc """
  Emits one event through the client's configured event adapter.
  """
  @spec emit(Client.t(), Event.t()) :: :ok | {:error, term()}
  def emit(%Client{} = client, %Event{} = event) do
    adapter = client.events
    adapter.emit(client, event)
  end

  @doc """
  Emits events in order and stops on the first adapter error.
  """
  @spec emit_many(Client.t(), [Event.t()]) :: :ok | {:error, term()}
  def emit_many(%Client{} = client, events) when is_list(events) do
    Enum.reduce_while(events, :ok, fn event, :ok ->
      case emit(client, event) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
end

defmodule ExWapp.Events.Noop do
  @moduledoc """
  Default event adapter that ignores events.
  """

  @behaviour ExWapp.Events

  @impl true
  @spec emit(ExWapp.Client.t(), ExWapp.Event.t()) :: :ok
  def emit(_client, _event), do: :ok
end

defmodule ExWapp.Events.Telemetry do
  @moduledoc """
  Event adapter that forwards high-level ExWapp events to `ExWapp.Telemetry`.

  Configure the instrumentation backend with `:telemetry_adapter`, then select
  this event adapter:

      ExWapp.new(events: ExWapp.Events.Telemetry, ...)

  With no instrumentation backend configured, events are ignored.
  """

  @behaviour ExWapp.Events

  @impl true
  @spec emit(ExWapp.Client.t(), ExWapp.Event.t()) :: :ok
  def emit(client, event) do
    ExWapp.Telemetry.execute(
      [:ex_wapp, :event, :emit],
      %{count: 1},
      %{
        session_id: client.session_id,
        event_type: event.type,
        event_metadata: event.metadata
      }
    )
  end
end
