defmodule ExWapp.Session.Worker.Pending do
  @moduledoc false

  defstruct outbound_confirmations: %{},
            pending_media_retries: %{},
            history_requests: %{},
            history_blob_queue: [],
            delayed_sends: %{},
            pending_session_repairs: %{}

  @type t :: %__MODULE__{
          outbound_confirmations: map(),
          pending_media_retries: map(),
          history_requests: map(),
          history_blob_queue: list(),
          delayed_sends: map(),
          pending_session_repairs: map()
        }
  @type field ::
          :outbound_confirmations
          | :pending_media_retries
          | :history_requests
          | :history_blob_queue
          | :delayed_sends
          | :pending_session_repairs

  @spec get(map(), field()) :: map() | list()
  def get(state, field), do: state |> Map.get(:pending, %__MODULE__{}) |> Map.fetch!(field)

  @spec put(state, field(), map() | list()) :: state when state: map()
  def put(state, field, value) do
    pending = state |> Map.get(:pending, %__MODULE__{}) |> Map.put(field, value)
    Map.put(state, :pending, pending)
  end
end
