defmodule ExWapp.Session.Worker.NodeHandler do
  @moduledoc """
  Dispatches inbound `Binary.Node` stanzas received after the Noise handshake.

  Every public function returns `{state, actions}` where *actions* is a list
  of tuples the caller (Worker) will execute (e.g. `{:send_node, node}`).
  """

  require Logger

  alias ExWapp.{Binary, Pairing}

  alias ExWapp.Session.OutboundQueue

  alias ExWapp.Session.Worker.{
    Inbound,
    PostAuth,
    ReceiptBuilder,
    Safety,
    Subscribers
  }

  # ============================================================================
  # Public
  # ============================================================================

  @doc """
  Safely handles a node, catching any exceptions.
  """
  @spec safe_handle_node(Binary.Node.t(), map()) :: {map(), list()}
  def safe_handle_node(node, state) do
    handle_connection_node(node, state)
  rescue
    e ->
      Logger.error("Error handling node: #{inspect(e)}")
      {update_stats(state, :errors), []}
  catch
    :exit, reason ->
      Logger.error("Exit handling node: #{inspect(reason)}")
      {update_stats(state, :errors), []}
  end

  @doc """
  Safely executes an action returned by a node handler.
  """
  @spec safe_handle_action(term(), map()) :: :ok
  def safe_handle_action(action, state) do
    handle_pairing_action(action, state)
  rescue
    e ->
      Logger.error("Error handling action #{inspect(action)}: #{inspect(e)}")
  catch
    :exit, reason ->
      Logger.error("Exit handling action #{inspect(action)}: #{inspect(reason)}")
  end

  # ============================================================================
  # Node dispatch
  # ============================================================================

  defp handle_connection_node(%Binary.Node{tag: "iq", attrs: attrs} = node, state) do
    xmlns = Map.get(attrs, "xmlns", "")
    iq_type = Map.get(attrs, "type", "")
    iq_id = Map.get(attrs, "id")

    state = forward_iq_to_workers(state, iq_type, iq_id, node)
    {state, pending_handled} = resolve_pending_iq(state, iq_type, iq_id, node)

    if pending_handled do
      {state, []}
    else
      dispatch_iq(state, node, attrs, xmlns, iq_type, iq_id)
    end
  end

  defp handle_connection_node(%Binary.Node{tag: "success", attrs: attrs}, state) do
    Logger.debug("[SESSION] Received success node - login successful!")

    # Persist LID if present (Baileys: CB:success -> creds.update me.lid)
    lid = Map.get(attrs, "lid")
    state = PostAuth.persist_lid_and_mapping(state, lid)

    # Reference: Baileys socket.ts CB:success handler
    # 1. Query server prekey count (count-driven upload, not unconditional)
    # 2. Send SetPassive(false)
    # 3. digestKeyBundle (optional, skip for now)
    prekey_count_query = ExWapp.Prekeys.build_prekey_count_query()
    query_id = Map.get(prekey_count_query.attrs, "id")

    passive_iq = build_set_passive_iq(false)

    state = %{state | prekey_count_query_id: query_id}

    # Send presence available to show as online (Baileys: sendPresenceUpdate)
    presence_node = %Binary.Node{
      tag: "presence",
      attrs: %{"type" => "available"},
      content: nil
    }

    actions = [
      {:send_node, prekey_count_query},
      {:send_node, passive_iq},
      {:send_node, presence_node}
    ]

    Logger.debug(
      "[SESSION] Sending prekey count query (id=#{query_id}) + passive IQ + presence available"
    )

    {state, actions}
  end

  # Handle ib (initialization) node - server sends this after successful login
  # Reference: whatsmeow/connectionevents.go handleIB()
  defp handle_connection_node(%Binary.Node{tag: "ib", content: children}, state) do
    Logger.debug("[SESSION] Received ib (initialization) node")

    log_ib_children(children)

    {state, []}
  end

  # Handle failure node - login/connection failed
  defp handle_connection_node(%Binary.Node{tag: "failure", attrs: attrs}, state) do
    reason = Map.get(attrs, "reason", "unknown")
    location = Map.get(attrs, "location", "unknown")

    Logger.error("[SESSION] Connection failure: reason=#{reason}, location=#{location}")

    # 401 = unauthorized/logged out
    # 403 = forbidden
    # 405 = client outdated
    case reason do
      "401" ->
        broadcast_error_event(state, {:connection_failure, :unauthorized, location})
        Logger.error("[SESSION] Unauthorized - session invalid, stopping reconnects")
        Logger.error("[SESSION] Please clear session and re-pair")
        notify_qr(state, {:error, :unauthorized})
        state = Safety.record_signal(state, :unauthorized)
        # Mark session as invalid to stop reconnection attempts
        {%{state | session_invalid: true, status: :idle}, []}

      "403" ->
        broadcast_error_event(state, {:connection_failure, :forbidden, location})
        Logger.error("[SESSION] Forbidden - account may be banned")
        notify_qr(state, {:error, :forbidden})
        state = Safety.record_signal(state, :forbidden)
        {%{state | session_invalid: true, status: :idle}, []}

      "405" ->
        broadcast_error_event(state, {:connection_failure, :client_outdated, location})
        Logger.error("[SESSION] Client outdated")
        notify_qr(state, {:error, :client_outdated})
        {state, []}

      _ ->
        broadcast_error_event(state, {:connection_failure, {:unknown, reason}, location})
        Logger.error("[SESSION] Unknown failure reason: #{reason}")
        notify_qr(state, {:error, {:failure, reason}})
        {state, []}
    end
  end

  defp handle_connection_node(%Binary.Node{tag: "stream:features"}, state) do
    {state, []}
  end

  # Handle stream:error - server-side errors
  # Reference: whatsmeow/connectionevents.go handleStreamError()
  defp handle_connection_node(
         %Binary.Node{tag: "stream:error", attrs: attrs, content: children},
         state
       ) do
    code = Map.get(attrs, "code", "unknown")
    Logger.error("[SESSION] Stream error: code=#{code}")

    # Check for conflict type in children
    conflict_type = extract_conflict_type(children)
    broadcast_error_event(state, {:stream_error, code, conflict_type})

    new_state =
      cond do
        code == "401" ->
          Logger.error("[SESSION] Device was removed (401)! Need to re-pair from scratch.")
          Logger.error("[SESSION] Delete session file and scan QR code again.")
          notify_qr(state, {:error, :device_removed})
          state = Safety.record_signal(state, :device_removed)
          # Stop reconnection - device is permanently invalid
          %{state | status: :disconnected, reconnect_attempts: 999}

        code == "515" ->
          Logger.warning("[SESSION] Got 515, will reconnect...")
          state

        code == "503" ->
          Logger.warning("[SESSION] Got 503 (service unavailable), will reconnect...")
          state

        conflict_type == "replaced" ->
          Logger.error("[SESSION] Stream replaced by another connection, restarting transport")
          notify_qr(state, {:error, :stream_replaced})
          state = Safety.record_signal(state, :stream_replaced)
          restart_connection_now(state, :stream_replaced)

        true ->
          Logger.error("[SESSION] Unknown stream error: code=#{code}, conflict=#{conflict_type}")
          state
      end

    {new_state, []}
  end

  # Handle incoming messages and notifications via MessageHandler
  defp handle_connection_node(%Binary.Node{tag: tag} = node, state)
       when tag in ["message", "notification", "receipt", "ack", "call", "presence", "chatstate"] do
    Inbound.handle_message_node(
      node,
      state,
      &ReceiptBuilder.build_receipt_ack/4,
      fn to, id, participant, message_t, retry_count, error_code, retry_meta ->
        ReceiptBuilder.build_retry_receipt_ack(
          state.store,
          to,
          id,
          participant,
          message_t,
          retry_count,
          error_code,
          retry_meta
        )
      end
    )
  end

  defp handle_connection_node(node, state) do
    Logger.debug("Unhandled node: #{inspect(node.tag)}")
    {update_stats(state, :messages_received), []}
  end

  # ============================================================================
  # IQ helpers
  # ============================================================================

  defp forward_iq_to_workers(state, iq_type, iq_id, node)
       when iq_type in ["result", "error"] and iq_id != nil do
    workers = Map.get(state, :send_workers, %{})

    if map_size(workers) > 0 do
      Logger.debug("[SESSION] Forwarding IQ #{iq_id} to #{map_size(workers)} workers")
      msg_tag = if iq_type == "result", do: :prekey_response, else: :prekey_error
      broadcast_iq_to_workers(workers, msg_tag, iq_id, node)
    end

    state
  end

  defp forward_iq_to_workers(state, _iq_type, _iq_id, _node), do: state

  defp resolve_pending_iq(state, iq_type, iq_id, node)
       when iq_type in ["result", "error"] and iq_id != nil do
    case Map.pop(state.pending_iqs, iq_id) do
      {nil, _} ->
        {state, false}

      {%{from: from, timer: timer}, pending_iqs} ->
        Process.cancel_timer(timer)
        reply = if iq_type == "result", do: {:ok, node}, else: {:error, node}
        GenServer.reply(from, reply)
        {%{state | pending_iqs: pending_iqs}, true}
    end
  end

  defp resolve_pending_iq(state, _iq_type, _iq_id, _node), do: {state, false}

  defp log_ib_children(children) when is_list(children), do: Enum.each(children, &log_ib_child/1)
  defp log_ib_children(_children), do: :ok

  defp log_ib_child(%Binary.Node{tag: "offline_preview", attrs: attrs}) do
    Logger.debug("[SESSION] Offline preview: #{inspect(attrs)}")
  end

  defp log_ib_child(%Binary.Node{tag: "offline", attrs: attrs}) do
    Logger.debug("[SESSION] Offline sync completed: #{inspect(attrs)}")
  end

  defp log_ib_child(%Binary.Node{tag: "dirty", attrs: attrs}) do
    Logger.debug("[SESSION] Dirty state: #{inspect(attrs)}")
  end

  defp log_ib_child(%Binary.Node{tag: tag}) do
    Logger.debug("[SESSION] IB child: #{inspect(tag)}")
  end

  defp log_ib_child(_child), do: :ok

  defp extract_conflict_type(children) when is_list(children) do
    case Enum.find(children, &match?(%Binary.Node{tag: "conflict"}, &1)) do
      %Binary.Node{attrs: conflict_attrs} -> Map.get(conflict_attrs, "type")
      _ -> nil
    end
  end

  defp extract_conflict_type(_children), do: nil

  defp broadcast_iq_to_workers(workers, msg_tag, iq_id, node) when is_map(workers) do
    Enum.each(workers, fn {worker_pid, _jid} ->
      send_iq_to_worker(worker_pid, msg_tag, iq_id, node)
    end)
  end

  defp send_iq_to_worker(worker_pid, msg_tag, iq_id, node) when is_pid(worker_pid) do
    if Process.alive?(worker_pid), do: send(worker_pid, {msg_tag, iq_id, node})
  end

  defp send_iq_to_worker(_worker_pid, _msg_tag, _iq_id, _node), do: :ok

  defp dispatch_iq(state, _node, attrs, "urn:xmpp:ping", "get", _iq_id) do
    Logger.debug("[SESSION] Received ping, sending pong")
    {state, [{:send_node, build_iq_result(attrs)}]}
  end

  defp dispatch_iq(state, node, _attrs, _xmlns, "result", iq_id)
       when state.prekey_count_query_id != nil and iq_id == state.prekey_count_query_id do
    PostAuth.handle_prekey_count_response(node, state)
  end

  defp dispatch_iq(state, node, attrs, xmlns, iq_type, iq_id) do
    {pairing, actions} = Pairing.apply_node(state.pairing, node)

    pairing =
      case maybe_reset_pairing(actions, pairing) do
        {:ok, new_pairing} -> new_pairing
        :noop -> pairing
      end

    actions =
      if actions == [] and iq_type in ["get", "set"] do
        Logger.debug(
          "[SESSION] Auto-responding to unhandled IQ: xmlns=#{xmlns} type=#{iq_type} id=#{iq_id}"
        )

        [{:send_node, build_iq_result(attrs)}]
      else
        actions
      end

    {%{state | pairing: pairing}, actions}
  end

  # ============================================================================
  # Node builders
  # ============================================================================

  defp build_iq_result(attrs) do
    result_attrs = %{"type" => "result"}

    result_attrs =
      case Map.get(attrs, "from") do
        nil -> result_attrs
        from -> Map.put(result_attrs, "to", from)
      end

    result_attrs =
      case Map.get(attrs, "id") do
        nil -> result_attrs
        id -> Map.put(result_attrs, "id", id)
      end

    %Binary.Node{tag: "iq", attrs: result_attrs, content: nil}
  end

  # Build SetPassive IQ - tells server whether we're passive (not receiving messages) or active
  # Reference: whatsmeow/connectionevents.go SetPassive()
  defp build_set_passive_iq(passive) do
    tag = if passive, do: "passive", else: "active"
    request_id = generate_request_id()

    %Binary.Node{
      tag: "iq",
      attrs: %{
        "id" => request_id,
        "xmlns" => "passive",
        "type" => "set",
        "to" => "s.whatsapp.net"
      },
      content: [%Binary.Node{tag: tag, attrs: %{}, content: nil}]
    }
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64() |> String.slice(0, 16)
  end

  # ============================================================================
  # Action dispatch
  # ============================================================================

  defp handle_pairing_action({:send_node, node}, %{outbound_queue: outbound_queue})
       when is_pid(outbound_queue) do
    OutboundQueue.enqueue_node(outbound_queue, node)
  end

  defp handle_pairing_action({:qr, code}, state), do: notify_qr(state, {:code, code})
  defp handle_pairing_action({:status, :success}, state), do: notify_qr(state, :success)
  defp handle_pairing_action({:error, reason}, state), do: notify_qr(state, {:error, reason})

  defp handle_pairing_action(:restart_stream, %{outbound_queue: outbound_queue})
       when is_pid(outbound_queue) do
    OutboundQueue.restart_stream(outbound_queue)
  end

  defp handle_pairing_action({:retry_outgoing_message, jid, message_id}, _state) do
    send(self(), {:retry_outgoing_message, jid, message_id})
  end

  defp handle_pairing_action(_action, _state), do: :ok

  # ============================================================================
  # Internal helpers
  # ============================================================================

  defp notify_qr(state, event) do
    Subscribers.notify_qr(state, event, fn -> :ok end)
  end

  defp broadcast_error_event(state, reason) do
    Subscribers.broadcast_error(Map.get(state, :session_id), reason)
  rescue
    _ -> :ok
  end

  defp restart_connection_now(state, reason) do
    # Delegate back to the worker process
    send(self(), {:restart_connection, reason})
    state
  end

  defp maybe_reset_pairing(actions, pairing) do
    if Enum.any?(actions, &match?({:status, :success}, &1)) do
      {:ok, Pairing.new(pairing.store)}
    else
      :noop
    end
  end

  defp update_stats(state, key) do
    update_in(state.stats[key], &((&1 || 0) + 1))
  end
end
