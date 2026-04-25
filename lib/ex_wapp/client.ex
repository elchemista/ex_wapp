defmodule ExWapp.Client do
  @moduledoc """
  High-level, runtime-neutral ExWapp client.

  Store this struct wherever your application owns session state: a GenServer,
  a GenStateMachine, ETS, a job, or plain functional code in tests/scripts.
  """

  alias ExWapp.{Config, Store}

  defstruct [
    :session_id,
    :store,
    :transport,
    :events,
    :runtime,
    :status,
    :last_error,
    metadata: %{},
    trace: []
  ]

  @type status :: :new | :pairing | :connecting | :connected | :disconnected | :error

  @type t :: %__MODULE__{
          session_id: term() | nil,
          store: Store.t(),
          transport: module(),
          events: module(),
          runtime: map(),
          status: status(),
          last_error: ExWapp.Error.t() | nil,
          metadata: map(),
          trace: [map()]
        }

  @doc """
  Creates a high-level client.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    runtime =
      case Config.resolve(opts) do
        {:ok, cfg} -> cfg
        {:error, reason} -> raise ArgumentError, "invalid runtime config: #{inspect(reason)}"
      end

    %__MODULE__{
      session_id: Keyword.get(opts, :session_id),
      store: Store.new(Keyword.get(opts, :store)),
      transport: Keyword.get(opts, :transport, ExWapp.Client.Transport.Noop),
      events: Keyword.get(opts, :events, ExWapp.Events.Noop),
      runtime: runtime,
      status: Keyword.get(opts, :status, :new),
      metadata: Keyword.get(opts, :metadata, %{}),
      trace: []
    }
  end

  @doc """
  Records a compact trace entry on the client.
  """
  @spec trace(t(), atom(), map()) :: t()
  def trace(%__MODULE__{} = client, operation, metadata \\ %{}) when is_atom(operation) do
    entry = %{
      operation: operation,
      at: System.system_time(:millisecond),
      metadata: metadata
    }

    %{client | trace: [entry | Enum.take(client.trace, 49)]}
  end
end
