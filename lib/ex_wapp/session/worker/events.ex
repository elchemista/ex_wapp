defmodule ExWapp.Session.Worker.Events do
  @moduledoc """
  What the session tells the outside world: telemetry, lifecycle metadata and
  the QR notifications that carry an error.

  These are the cross-cutting emissions every part of the session reaches for,
  so they live here rather than in any one concern. Emitting never fails the
  caller: a broken telemetry handler or subscriber must not take the session
  down with it.

  Called from the session process, so `self()` in the lifecycle metadata is the
  session's own pid, exactly as when this lived inside the worker.
  """

  alias ExWapp.Session.Worker
  alias ExWapp.Session.Worker.Subscribers
  alias ExWapp.Telemetry

  @doc "Emits a telemetry event, tagged with the session's current status."
  @spec emit_telemetry(atom() | [atom()], map(), Worker.t(), map()) :: :ok
  def emit_telemetry(event, measurements, state, extra_metadata \\ %{}) do
    maybe_broadcast_pubsub_error(event, measurements, extra_metadata, state)

    metadata = %{
      status: state.status,
      reconnect_attempts: state.reconnect_attempts,
      session_id: state.session_id
    }

    Telemetry.execute(
      event,
      Map.merge(%{system_time: System.system_time()}, measurements),
      Map.merge(metadata, extra_metadata)
    )
  rescue
    _ -> :ok
  end

  @doc "The session snapshot carried by every lifecycle message to subscribers."
  @spec lifecycle_event_meta(Worker.t(), map() | keyword()) :: map()
  def lifecycle_event_meta(state, extra \\ %{}) do
    extra
    |> Map.new()
    |> Map.merge(%{
      runtime_ref: self(),
      session_id: state.session_id,
      status: state.status,
      transport_ready?: state.transport_ready?,
      post_auth_phase: state.post_auth_phase
    })
  end

  @doc "Notifies QR subscribers of a failure, counting it in telemetry."
  @spec notify_qr(Worker.t(), {:error, term()}) :: :ok
  def notify_qr(state, {:error, _} = event) do
    Subscribers.notify_qr(state, event, fn ->
      emit_telemetry(
        :qr,
        %{subscriber_count: map_size(state.qr_subscribers)},
        state,
        %{event: :error}
      )
    end)
  end

  @doc "Bumps one of the session's counters."
  @spec update_stats(Worker.t(), atom()) :: Worker.t()
  def update_stats(state, key) do
    update_in(state.stats[key], &((&1 || 0) + 1))
  end

  # Error telemetry doubles as the session's error channel for PubSub listeners.
  @spec maybe_broadcast_pubsub_error(atom() | [atom()], map(), map(), Worker.t()) :: :ok
  defp maybe_broadcast_pubsub_error(:error, measurements, extra_metadata, state) do
    reason =
      case {Map.get(measurements, :phase), Map.get(measurements, :reason)} do
        {phase, reason} when not is_nil(phase) and not is_nil(reason) -> {phase, reason}
        {_, reason} when not is_nil(reason) -> reason
        _ -> {:error_event, measurements, extra_metadata}
      end

    Subscribers.broadcast_error(state.session_id, reason)
  rescue
    _ -> :ok
  end

  defp maybe_broadcast_pubsub_error(_event, _measurements, _extra_metadata, _state), do: :ok
end
