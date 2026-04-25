defmodule ExWapp.Telemetry do
  @moduledoc """
  Telemetry helpers for the runtime-neutral ExWapp client API.

  Events use the `[:ex_wapp, ...]` prefix and are emitted by the high-level
  facade and the optional telemetry event adapter.
  """

  @events [
    [:ex_wapp, :client, :connect, :start],
    [:ex_wapp, :client, :connect, :stop],
    [:ex_wapp, :client, :connect, :exception],
    [:ex_wapp, :client, :pair, :start],
    [:ex_wapp, :client, :pair, :stop],
    [:ex_wapp, :client, :pair, :exception],
    [:ex_wapp, :client, :disconnect, :start],
    [:ex_wapp, :client, :disconnect, :stop],
    [:ex_wapp, :client, :disconnect, :exception],
    [:ex_wapp, :client, :send_message, :start],
    [:ex_wapp, :client, :send_message, :stop],
    [:ex_wapp, :client, :send_message, :exception],
    [:ex_wapp, :client, :receive_message, :start],
    [:ex_wapp, :client, :receive_message, :stop],
    [:ex_wapp, :client, :receive_message, :exception],
    [:ex_wapp, :event, :emit],
    [:ex_wapp, :transport, :websocket, :connect],
    [:ex_wapp, :transport, :websocket, :disconnect],
    [:ex_wapp, :transport, :websocket, :frame_received],
    [:ex_wapp, :transport, :websocket, :frame_sent],
    [:ex_wapp, :transport, :websocket, :error],
    [:ex_wapp, :session, :init],
    [:ex_wapp, :session, :connect],
    [:ex_wapp, :session, :connected],
    [:ex_wapp, :session, :disconnected],
    [:ex_wapp, :session, :reconnect],
    [:ex_wapp, :session, :error],
    [:ex_wapp, :session, :qr],
    [:ex_wapp, :session, :message_received],
    [:ex_wapp, :session, :message_sent],
    [:ex_wapp, :session, :terminate]
  ]

  @type event_name :: [atom()]

  @doc """
  Returns all canonical telemetry events.
  """
  @spec events() :: [event_name()]
  def events, do: @events

  @doc """
  Emits a telemetry event.
  """
  @spec execute(event_name(), map(), map()) :: :ok
  def execute(event, measurements, metadata \\ [])

  def execute(event, measurements, metadata)
      when is_list(event) and is_map(measurements) do
    :telemetry.execute(event, measurements, Map.new(metadata))
  end

  def execute(event, measurements, metadata)
      when is_atom(event) and is_map(measurements) do
    execute([:ex_wapp, :session, event], measurements, metadata)
  end

  @doc """
  Attaches one handler to all ExWapp telemetry events.
  """
  @spec attach_many(term(), :telemetry.handler_function(), term()) ::
          :ok | {:error, :already_exists}
  def attach_many(handler_id, handler, config \\ nil) when is_function(handler, 4) do
    :telemetry.attach_many(handler_id, @events, handler, config)
  end

  @doc """
  Detaches a telemetry handler.
  """
  @spec detach(term()) :: :ok | {:error, :not_found}
  def detach(handler_id), do: :telemetry.detach(handler_id)
end
