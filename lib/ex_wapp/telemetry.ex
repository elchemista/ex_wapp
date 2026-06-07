defmodule ExWapp.Telemetry do
  @moduledoc """
  Telemetry helpers and canonical event list for ExWapp.

  All events use the `[:ex_wapp, :session, ...]` prefix.
  """

  @prefix [:ex_wapp, :session]

  @events [
    @prefix ++ [:init],
    @prefix ++ [:connect],
    @prefix ++ [:connected],
    @prefix ++ [:disconnected],
    @prefix ++ [:reconnect],
    @prefix ++ [:error],
    @prefix ++ [:terminate],
    @prefix ++ [:qr],
    @prefix ++ [:message_received],
    @prefix ++ [:message_sent],
    [:ex_wapp, :rate, :limited],
    [:ex_wapp, :quota, :exceeded],
    [:ex_wapp, :safety, :trip],
    [:ex_wapp, :policy, :blocked_send],
    [:ex_wapp, :client, :connect, :start],
    [:ex_wapp, :client, :connect, :stop],
    [:ex_wapp, :client, :connect, :exception],
    [:ex_wapp, :event, :emit]
  ]

  @type event_name :: [atom()]

  @doc """
  Returns all canonical ExWapp telemetry events.
  """
  @spec events() :: [event_name()]
  def events, do: @events

  @doc """
  Executes an ExWapp session event.
  """
  @spec execute(atom() | [atom()], map(), map()) :: :ok
  def execute(event, measurements, metadata \\ %{})

  def execute(event, measurements, metadata)
      when is_atom(event) and is_map(measurements) and is_map(metadata) do
    :telemetry.execute(@prefix ++ [event], measurements, metadata)
  end

  def execute(event, measurements, metadata)
      when is_list(event) and is_map(measurements) and is_map(metadata) do
    :telemetry.execute(event, measurements, metadata)
  end

  @doc """
  Attaches one handler to all ExWapp session events.
  """
  @spec attach_many(
          handler_id :: term(),
          handler :: :telemetry.handler_function(),
          config :: term()
        ) :: :ok | {:error, :already_exists}
  def attach_many(handler_id, handler, config \\ nil) when is_function(handler, 4) do
    :telemetry.attach_many(handler_id, @events, handler, config)
  end

  @doc """
  Detaches a telemetry handler.
  """
  @spec detach(term()) :: :ok | {:error, :not_found}
  def detach(handler_id), do: :telemetry.detach(handler_id)
end
