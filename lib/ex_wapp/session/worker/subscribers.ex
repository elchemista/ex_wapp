defmodule ExWapp.Session.Worker.Subscribers do
  @moduledoc """
  Subscriber bookkeeping for QR and message streams.
  """

  @spec notify_qr(map(), term(), (-> any())) :: :ok
  def notify_qr(state, event, emit_telemetry_fun) when is_function(emit_telemetry_fun, 0) do
    emit_telemetry_fun.()

    Enum.each(state.qr_subscribers, fn {ref, {pid, _mon}} ->
      send(pid, {:ex_wapp_qr, ref, event})
    end)
  end

  @spec remove_qr_subscriber(map(), reference()) :: map()
  def remove_qr_subscriber(state, ref) do
    case Map.pop(state.qr_subscribers, ref) do
      {nil, _} ->
        state

      {{pid, mon}, subscribers} ->
        Process.demonitor(mon, [:flush])
        send(pid, {:ex_wapp_qr_closed, ref})
        %{state | qr_subscribers: subscribers}
    end
  end

  @spec cleanup_dead_subscriber(map(), reference()) :: map()
  def cleanup_dead_subscriber(state, dead_mon) do
    new_qr =
      state.qr_subscribers
      |> Enum.reject(fn {_ref, {_pid, mon}} -> mon == dead_mon end)
      |> Map.new()

    new_msg =
      state.message_subscribers
      |> Enum.reject(fn {_ref, {_pid, mon}} -> mon == dead_mon end)
      |> Map.new()

    %{state | qr_subscribers: new_qr, message_subscribers: new_msg}
  end

  @spec notify_message_subscribers(map(), String.t(), map()) :: :ok
  def notify_message_subscribers(state, jid, message) do
    # Direct-send to legacy subscribers (backwards compatible)
    Enum.each(state.message_subscribers, fn {ref, {pid, _mon}} ->
      send(pid, {:ex_wapp_message, ref, jid, message})
    end)

    # PubSub broadcast for decoupled subscribers
    broadcast_via_pubsub(Map.get(state, :session_id), jid, message)
  end

  defp broadcast_via_pubsub(session_id, jid, message) do
    # Per-session topic (uses session_id when available, pid as fallback)
    topic_key = session_id || self()

    Phoenix.PubSub.broadcast(
      ExWapp.PubSub,
      "ex_wapp:messages:#{topic_key}",
      {:ex_wapp_message, jid, message}
    )

    # Global topic (all sessions)
    Phoenix.PubSub.broadcast(
      ExWapp.PubSub,
      "ex_wapp:messages",
      {:ex_wapp_message, topic_key, jid, message}
    )
  rescue
    # PubSub may not be started in some test scenarios
    _ -> :ok
  end

  @doc """
  Broadcasts a session lifecycle event via PubSub.

  Events are sent on two topics:
  - Per-session: `"ex_wapp:session:<session_id>"` with payload as-is
  - Global: `"ex_wapp:session"` with `{session_id, payload}`
  """
  @spec broadcast_lifecycle(term(), term()) :: :ok
  def broadcast_lifecycle(session_id, event) do
    topic_key = session_id || self()

    Phoenix.PubSub.broadcast(
      ExWapp.PubSub,
      "ex_wapp:session:#{topic_key}",
      event
    )

    Phoenix.PubSub.broadcast(
      ExWapp.PubSub,
      "ex_wapp:session",
      {topic_key, event}
    )
  rescue
    _ -> :ok
  end

  @doc """
  Broadcasts session health events (errors, drops, retries, guard trips).

  Events are sent on:
  - per-session: `"ex_wapp:health:<session_id>"`
  - global: `"ex_wapp:health"` with `{session_id, payload}`
  """
  @spec broadcast_health(term(), term()) :: :ok
  def broadcast_health(session_id, event) do
    topic_key = session_id || self()

    Phoenix.PubSub.broadcast(
      ExWapp.PubSub,
      "ex_wapp:health:#{topic_key}",
      event
    )

    Phoenix.PubSub.broadcast(
      ExWapp.PubSub,
      "ex_wapp:health",
      {topic_key, event}
    )
  rescue
    _ -> :ok
  end

  @spec remove_message_subscriber(map(), reference()) :: map()
  def remove_message_subscriber(state, ref) do
    case Map.pop(state.message_subscribers, ref) do
      {nil, _} ->
        state

      {{pid, mon}, subscribers} ->
        Process.demonitor(mon, [:flush])
        send(pid, {:ex_wapp_messages_closed, ref})
        %{state | message_subscribers: subscribers}
    end
  end
end
