defmodule ExWapp.Session.Worker.Subscribers do
  @moduledoc """
  Subscriber bookkeeping for QR and message streams.
  """

  require Logger

  alias ExWapp.Log
  alias ExWapp.Session.Worker

  @spec notify_qr(Worker.t(), term(), (-> any())) :: :ok
  def notify_qr(state, event, emit_telemetry_fun) when is_function(emit_telemetry_fun, 0) do
    emit_telemetry_fun.()

    Enum.each(state.qr_subscribers, fn {ref, {pid, _mon}} ->
      send(pid, {:ex_wapp_qr, ref, event})
    end)
  end

  @spec remove_qr_subscriber(Worker.t(), reference()) :: Worker.t()
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

  @spec cleanup_dead_subscriber(Worker.t(), reference()) :: Worker.t()
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

  @spec notify_message_subscribers(Worker.t(), String.t(), map()) :: :ok
  def notify_message_subscribers(state, jid, message) do
    Logger.info(
      "[ExWapp.Subscribers] notify_message_subscribers jid=#{Log.reference(jid)} session=#{Log.reference(Map.get(state, :session_id))} direct_subscribers=#{map_size(Map.get(state, :message_subscribers, %{}))} message_id=#{Log.reference(Map.get(message, :id) || Map.get(message, "id"))}"
    )

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
    message_id = Map.get(message, :id) || Map.get(message, "id")

    Logger.debug(
      "[ExWapp.Subscribers] broadcasting topic=#{Log.reference(topic_key)} global_topic=ex_wapp:messages jid=#{Log.reference(jid)} message_id=#{Log.reference(message_id)}"
    )

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
  Broadcasts a session error via lifecycle PubSub topics.

  Message format:
  - `{:ex_wapp_session, :error, reason}`
  """
  @spec broadcast_error(term(), term()) :: :ok
  def broadcast_error(session_id, reason) do
    broadcast_lifecycle(session_id, {:ex_wapp_session, :error, reason})
  end

  @doc """
  Broadcasts a transient reconnect notice via lifecycle PubSub topics.

  Emitted for recoverable server-side conditions (e.g. `503`/`515` stream
  errors) so owners can stay calm instead of treating them as a hard error.

  Message format:
  - `{:ex_wapp_session, :reconnecting, reason}`
  """
  @spec broadcast_reconnecting(term(), term()) :: :ok
  def broadcast_reconnecting(session_id, reason) do
    broadcast_lifecycle(session_id, {:ex_wapp_session, :reconnecting, reason})
  end

  @doc """
  Broadcasts the server's verdict on an outbound message.

  WhatsApp answers a message it accepts with an `<ack>` and stays silent for one
  it drops, so this is the only positive confirmation a sender ever gets. It is
  published because the session already observes it while the caller cannot:
  without it the only way to learn a send succeeded is to poll stored message
  status, which is both slower and unable to distinguish "refused" from "no
  answer yet".

  Events are sent on:
  - per-session: `"ex_wapp:delivery:<session_id>"`
  - global: `"ex_wapp:delivery"` with `{session_id, payload}`

  Message format:
  - `{:ex_wapp_delivery, message_id, :sent, %{jid: jid}}`
  - `{:ex_wapp_delivery, message_id, :failed, %{jid: jid, error: %ExWapp.Error.Ack{}}}`
  """
  @spec broadcast_delivery(term(), String.t(), atom(), map()) :: :ok
  def broadcast_delivery(session_id, message_id, status, meta) do
    topic_key = session_id || self()
    event = {:ex_wapp_delivery, message_id, status, meta}

    Phoenix.PubSub.broadcast(ExWapp.PubSub, "ex_wapp:delivery:#{topic_key}", event)
    Phoenix.PubSub.broadcast(ExWapp.PubSub, "ex_wapp:delivery", {topic_key, event})
    :ok
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

  @spec remove_message_subscriber(Worker.t(), reference()) :: Worker.t()
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
