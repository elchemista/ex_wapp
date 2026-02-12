defmodule ExWapp.Session.Subscribers do
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
    Enum.each(state.message_subscribers, fn {ref, {pid, _mon}} ->
      send(pid, {:ex_wapp_message, ref, jid, message})
    end)
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
