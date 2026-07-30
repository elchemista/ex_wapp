defmodule ExWapp.Session.Worker.SendHealth do
  @moduledoc """
  Tracks how well outbound sending is going, and decides when to trip the guard.

  Owns the `send_health` field of the session state: error and drop counters,
  the one-minute rolling windows behind the per-minute thresholds, and the
  paused/hard-stopped gates that block sending.

  Deciding is separate from acting: `guard_trigger_reason/2` is pure and answers
  "have we crossed a threshold", while stopping or disconnecting the session
  stays with `ExWapp.Session.Worker`, which owns the transport and the process.
  """

  alias ExWapp.Session.Worker
  alias ExWapp.Session.Worker.Subscribers

  @window_ms 60_000

  @default %{
    paused: false,
    hard_stopped: false,
    send_errors_total: 0,
    consecutive_send_errors: 0,
    retries_total: 0,
    drops_total: 0,
    outbound_queue_errors_total: 0,
    guard_trips: 0,
    last_error_reason: nil,
    last_error_at_ms: nil,
    last_guard_action: nil,
    last_guard_reason: nil,
    errors_window_ms: [],
    drops_window_ms: []
  }

  @type metrics :: %{
          consecutive: non_neg_integer(),
          errors_min: non_neg_integer(),
          drops_min: non_neg_integer()
        }
  @type trigger_reason :: {atom(), non_neg_integer()} | nil

  @doc "The counters a fresh session starts from."
  @spec default() :: map()
  def default, do: @default

  @doc "Reads one counter, falling back to `default` when it was never set."
  @spec get(Worker.t(), atom(), term()) :: term()
  def get(state, key, default), do: Map.get(snapshot(state), key, default)

  @doc "Writes one counter."
  @spec put(Worker.t(), atom(), term()) :: Worker.t()
  def put(state, key, value) do
    %{state | send_health: Map.put(snapshot(state), key, value)}
  end

  @doc "Adds to one counter, treating a missing counter as zero."
  @spec increment(Worker.t(), atom(), integer()) :: Worker.t()
  def increment(state, key, by \\ 1) do
    %{state | send_health: Map.update(snapshot(state), key, by, &((&1 || 0) + by))}
  end

  @doc """
  Rejects a send while the guard holds the session paused or hard-stopped.

  A rejection is itself recorded as a send error, so repeated attempts against a
  closed gate keep the counters honest.
  """
  @spec ensure_send_enabled(Worker.t(), String.t()) ::
          {:ok, Worker.t()} | {:error, atom(), Worker.t()}
  def ensure_send_enabled(state, jid) do
    cond do
      get(state, :hard_stopped, false) ->
        blocked =
          register_send_error(state, :send_guard_hard_stopped, %{jid: jid, source: :guard_gate})

        {:error, :send_guard_hard_stopped, blocked}

      get(state, :paused, false) ->
        blocked = register_send_error(state, :send_paused, %{jid: jid, source: :guard_gate})
        {:error, :send_paused, blocked}

      true ->
        {:ok, state}
    end
  end

  @doc "Records a failed send and broadcasts it to health subscribers."
  @spec register_send_error(Worker.t(), term(), map()) :: Worker.t()
  def register_send_error(state, reason, metadata) when is_map(metadata) do
    now = now_ms()

    state =
      state
      |> increment(:send_errors_total)
      |> increment(:consecutive_send_errors)
      |> put(:errors_window_ms, prune_window(get(state, :errors_window_ms, []), now))
      |> put(:last_error_reason, reason)
      |> put(:last_error_at_ms, now)

    broadcast_event(state, :send_error, Map.merge(%{reason: reason}, metadata))
    state
  end

  @doc "Records a message dropped after its confirmation never arrived."
  @spec register_drop_timeout(Worker.t(), String.t(), map()) :: Worker.t()
  def register_drop_timeout(state, message_id, confirmation) do
    now = now_ms()

    state =
      state
      |> increment(:drops_total)
      |> put(:drops_window_ms, prune_window(get(state, :drops_window_ms, []), now))

    broadcast_event(state, :drop_timeout, %{
      message_id: message_id,
      jid: Map.get(confirmation, :jid),
      attempt: Map.get(confirmation, :attempt)
    })

    state
  end

  @doc "Clears the consecutive-error streak after a send finally succeeds."
  @spec clear_consecutive_send_errors(Worker.t()) :: Worker.t()
  def clear_consecutive_send_errors(state), do: put(state, :consecutive_send_errors, 0)

  @doc "Records an outbound-queue failure, which is counted apart from send errors."
  @spec increment_outbound_queue_errors(Worker.t(), term()) :: Worker.t()
  def increment_outbound_queue_errors(state, reason) do
    state =
      state
      |> increment(:outbound_queue_errors_total)
      |> put(:last_error_reason, {:outbound_queue_error, reason})
      |> put(:last_error_at_ms, now_ms())

    broadcast_event(state, :outbound_queue_error, %{reason: reason})
    state
  end

  @doc "The three numbers the guard thresholds are compared against."
  @spec guard_metrics(Worker.t()) :: metrics()
  def guard_metrics(state) do
    %{
      consecutive: get(state, :consecutive_send_errors, 0),
      errors_min: length(get(state, :errors_window_ms, [])),
      drops_min: length(get(state, :drops_window_ms, []))
    }
  end

  @doc """
  Names the threshold that has been crossed, or `nil` while all are within range.

  Pure: given the metrics and the configured limits it decides nothing else.
  """
  @spec guard_trigger_reason(metrics(), map()) :: trigger_reason()
  def guard_trigger_reason(metrics, guard_cfg) do
    max_consecutive = Map.get(guard_cfg, :max_consecutive_errors, 3)
    max_errors_min = Map.get(guard_cfg, :max_errors_per_minute, 20)
    max_drops_min = Map.get(guard_cfg, :max_drops_per_minute, 10)

    cond do
      metrics.consecutive >= max_consecutive -> {:max_consecutive_errors, metrics.consecutive}
      metrics.errors_min >= max_errors_min -> {:max_errors_per_minute, metrics.errors_min}
      metrics.drops_min >= max_drops_min -> {:max_drops_per_minute, metrics.drops_min}
      true -> nil
    end
  end

  @doc "Publishes a health event, never failing the caller if delivery breaks."
  @spec broadcast_event(Worker.t(), atom(), map()) :: :ok
  def broadcast_event(state, type, metadata) when is_map(metadata) do
    Subscribers.broadcast_health(state.session_id, {:ex_wapp_health, type, metadata})
  rescue
    _ -> :ok
  end

  @spec snapshot(Worker.t()) :: map()
  defp snapshot(state), do: state.send_health || @default

  # Only the last minute counts towards the per-minute thresholds.
  @spec prune_window([integer()], integer()) :: [integer()]
  defp prune_window(values, now_ms) when is_list(values) do
    threshold = now_ms - @window_ms
    Enum.filter([now_ms | values], &(&1 >= threshold))
  end

  @spec now_ms() :: integer()
  defp now_ms, do: System.monotonic_time(:millisecond)
end
