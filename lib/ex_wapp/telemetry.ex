defmodule ExWapp.Telemetry do
  @moduledoc """
  Optional instrumentation and canonical event list for ExWapp.

  Session events use the `[:ex_wapp, :session, ...]` prefix. Store, app-state,
  safety, quota, and client events use their corresponding ExWapp domain prefix.

  Events are ignored unless the host application configures an adapter:

      config :ex_wapp, :telemetry_adapter, :telemetry

  Add `:telemetry` to your application's dependencies to use that backend, or
  configure a module implementing `ExWapp.Telemetry.Adapter`. Emission is best
  effort: an unavailable or failing adapter never interrupts protocol work.
  Adapter callbacks execute in the caller's process and should return promptly.
  """

  defmodule Adapter do
    @moduledoc """
    Contract for host-owned instrumentation backends.

    `execute/3` is required. Handler management is optional; implement
    `attach_many/4` and `detach/1` to support the corresponding helpers in
    `ExWapp.Telemetry`. The Erlang `:telemetry` module already has this interface.
    """

    @callback execute([atom()], map(), map()) :: :ok
    @callback attach_many(term(), [[atom()]], ExWapp.Telemetry.handler(), term()) ::
                :ok | {:error, term()}
    @callback detach(term()) :: :ok | {:error, term()}
    @optional_callbacks attach_many: 4, detach: 1
  end

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
    [:ex_wapp, :event, :emit],
    [:ex_wapp, :app_state, :external_blob],
    [:ex_wapp, :app_state, :decode],
    [:ex_wapp, :app_state, :dispatch],
    [:ex_wapp, :store, :flush]
  ]

  @type event_name :: [atom()]
  @type handler :: (event_name(), map(), map(), term() -> term())

  @doc """
  Returns all canonical ExWapp telemetry events.
  """
  @spec events() :: [event_name()]
  def events, do: @events

  @doc """
  Emits an event through the configured adapter, or does nothing if disabled.

  Atoms expand to the session prefix; lists are passed through unchanged.
  Adapter errors are ignored so instrumentation cannot fail an operation.
  """
  @spec execute(atom() | [atom()], map(), map()) :: :ok
  def execute(event, measurements, metadata \\ %{})

  def execute(event, measurements, metadata)
      when is_atom(event) and is_map(measurements) and is_map(metadata) do
    execute(@prefix ++ [event], measurements, metadata)
  end

  def execute(event, measurements, metadata)
      when is_list(event) and is_map(measurements) and is_map(metadata) do
    invoke(:execute, [event, measurements, metadata])
    :ok
  end

  @doc """
  Attaches one handler to all canonical ExWapp events using the adapter.

  Returns `{:error, :telemetry_not_configured}` when disabled or
  `{:error, {:unsupported_telemetry_callback, :attach_many}}` for an adapter
  that only supports emission.
  """
  @spec attach_many(
          handler_id :: term(),
          handler :: handler(),
          config :: term()
        ) :: :ok | {:error, term()}
  def attach_many(handler_id, handler, config \\ nil) when is_function(handler, 4) do
    invoke(:attach_many, [handler_id, @events, handler, config])
  end

  @doc """
  Detaches a handler using the configured adapter.

  Returns an error if instrumentation or adapter handler management is unavailable.
  """
  @spec detach(term()) :: :ok | {:error, term()}
  def detach(handler_id), do: invoke(:detach, [handler_id])

  defp invoke(function, args) do
    adapter = Application.get_env(:ex_wapp, :telemetry_adapter)

    cond do
      is_nil(adapter) ->
        {:error, :telemetry_not_configured}

      not is_atom(adapter) or not Code.ensure_loaded?(adapter) ->
        {:error, {:invalid_telemetry_adapter, adapter}}

      not function_exported?(adapter, function, length(args)) ->
        {:error, {:unsupported_telemetry_callback, function}}

      true ->
        normalize_result(apply(adapter, function, args))
    end
  rescue
    exception -> {:error, exception}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp normalize_result(:ok), do: :ok
  defp normalize_result({:error, _reason} = error), do: error
  defp normalize_result(_other), do: {:error, :invalid_telemetry_response}
end
