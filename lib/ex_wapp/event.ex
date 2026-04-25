defmodule ExWapp.Event do
  @moduledoc """
  Runtime-neutral events emitted by the high-level client API.

  Applications can route these through PubSub, process messages, webhooks,
  logs, tests, or any other subscription mechanism by implementing
  `ExWapp.Events`.
  """

  defstruct [:type, :payload, :session_id, :at, metadata: %{}]

  @type type ::
          :qr
          | :status
          | :message_sent
          | :message_received
          | :disconnected
          | :error
          | atom()

  @type t :: %__MODULE__{
          type: type(),
          payload: term(),
          session_id: term() | nil,
          at: DateTime.t(),
          metadata: map()
        }

  @doc """
  Creates an event with the current UTC timestamp.
  """
  @spec new(type(), term(), keyword()) :: t()
  def new(type, payload, opts \\ []) when is_atom(type) do
    %__MODULE__{
      type: type,
      payload: payload,
      session_id: Keyword.get(opts, :session_id),
      at: Keyword.get(opts, :at, DateTime.utc_now()),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end
end
