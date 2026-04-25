defmodule ExWapp.Error do
  @moduledoc """
  Structured error returned by high-level ExWapp client operations.

  The `:operation` field names the public API call, while `:phase` narrows the
  failure to the protocol/integration step that failed.
  """

  defexception [:operation, :phase, :reason, :message_id, :trace_id, metadata: %{}]

  @type t :: %__MODULE__{
          operation: atom(),
          phase: atom() | nil,
          reason: term(),
          message_id: String.t() | nil,
          trace_id: term() | nil,
          metadata: map()
        }

  @doc """
  Builds an ExWapp error.
  """
  @spec new(atom(), atom() | nil, term(), keyword()) :: t()
  def new(operation, phase, reason, opts \\ []) when is_atom(operation) do
    %__MODULE__{
      operation: operation,
      phase: phase,
      reason: reason,
      message_id: Keyword.get(opts, :message_id),
      trace_id: Keyword.get(opts, :trace_id),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @impl true
  def message(%__MODULE__{operation: operation, phase: phase, reason: reason}) do
    phase_part = if phase, do: " #{phase}", else: ""
    "ex_wapp #{operation}#{phase_part} failed: #{inspect(reason)}"
  end
end
