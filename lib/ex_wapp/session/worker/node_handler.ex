defmodule ExWapp.Session.Worker.NodeHandler do
  @moduledoc """
  Dispatches inbound `Binary.Node` stanzas received after the Noise handshake.

  Every public function returns `{state, actions}` where *actions* is a list
  of tuples the caller (Worker) will execute (e.g. `{:send_node, node}`).
  """

  require Logger

  alias ExWapp.{Binary, Config, Pairing}

  alias ExWapp.Session.OutboundQueue

  alias ExWapp.Session.Worker.{
    Inbound,
    PostAuth,
    ReceiptBuilder,
    Safety,
    Subscribers
  }

  # Safe node entry point

  @doc """
  Safely handles a node, catching any exceptions.
  """
  @spec safe_handle_node(Binary.Node.t(), map()) :: {map(), list()}
  def safe_handle_node(node, state) do
    Logger.debug(
      "[NODE_HANDLER] handling node session_id=#{inspect(Map.get(state, :session_id))} tag=#{node.tag} attrs=#{inspect(loggable_attrs(node.attrs || %{}), limit: 50)}"
    )

    {next_state, actions} = handle_connection_node(node, state)

    Logger.debug(
      "[NODE_HANDLER] handled node session_id=#{inspect(Map.get(next_state, :session_id))} tag=#{node.tag} actions=#{length(actions)} status=#{inspect(Map.get(next_state, :status))} post_auth_phase=#{inspect(Map.get(next_state, :post_auth_phase))}"
    )

    {next_state, actions}
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
    Logger.debug(
      "[NODE_HANDLER] executing action session_id=#{inspect(Map.get(state, :session_id))} action=#{inspect(compact_action(action), limit: 80)}"
    )

    handle_pairing_action(action, state)
  rescue
    e ->
      Logger.error("Error handling action #{inspect(action)}: #{inspect(e)}")
  catch
    :exit, reason ->
      Logger.error("Exit handling action #{inspect(action)}: #{inspect(reason)}")
  end

  # Dispatch by node type

  defp handle_connection_node(%Binary.Node{tag: "iq", attrs: attrs} = node, state) do
    xmlns = Map.get(attrs, "xmlns", "")
    iq_type = Map.get(attrs, "type", "")
    iq_id = Map.get(attrs, "id")

    Logger.debug(
      "[NODE_HANDLER] iq received session_id=#{inspect(Map.get(state, :session_id))} id=#{inspect(iq_id)} type=#{inspect(iq_type)} xmlns=#{inspect(xmlns)} pending_iqs=#{map_size(Map.get(state, :pending_iqs, %{}))} post_auth_ids=#{inspect(%{prekey_count_query_id: Map.get(state, :prekey_count_query_id), prekey_upload_iq_id: Map.get(state, :prekey_upload_iq_id), passive_iq_id: Map.get(state, :passive_iq_id), digest_iq_id: Map.get(state, :digest_iq_id)})}"
    )

    state = forward_iq_to_workers(state, iq_type, iq_id, node)
    {state, pending_handled} = resolve_pending_iq(state, iq_type, iq_id, node)

    if pending_handled do
      Logger.debug(
        "[NODE_HANDLER] iq handled by pending request session_id=#{inspect(Map.get(state, :session_id))} id=#{inspect(iq_id)}"
      )

      {state, []}
    else
      dispatch_iq(state, node, attrs, xmlns, iq_type, iq_id)
    end
  end

  defp handle_connection_node(%Binary.Node{tag: "success", attrs: attrs}, state) do
    Logger.info(
      "[SESSION] Received <success> node - login successful! attrs=#{inspect(Map.keys(attrs))}"
    )

    # Persist LID if present (Baileys: CB:success -> creds.update me.lid)
    lid = Map.get(attrs, "lid")

    state =
      state
      |> PostAuth.persist_lid_and_mapping(lid)
      |> update_server_time_offset(attrs)

    {next_state, actions} = PostAuth.start(state, &build_set_passive_iq/0)
    {next_state, [:mark_auth_connected | actions]}
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
        maybe_notify_qr_error(state, :unauthorized)
        state = Safety.record_signal(state, :unauthorized)
        # Mark session as invalid to stop reconnection attempts
        {%{state | session_invalid: true, status: :idle}, []}

      "403" ->
        broadcast_error_event(state, {:connection_failure, :forbidden, location})
        Logger.error("[SESSION] Forbidden - account may be banned")
        maybe_notify_qr_error(state, :forbidden)
        state = Safety.record_signal(state, :forbidden)
        {%{state | session_invalid: true, status: :idle}, []}

      "405" ->
        broadcast_error_event(state, {:connection_failure, :client_outdated, location})
        Logger.error("[SESSION] Client outdated")
        maybe_notify_qr_error(state, :client_outdated)
        {state, []}

      _ ->
        broadcast_error_event(state, {:connection_failure, {:unknown, reason}, location})
        Logger.error("[SESSION] Unknown failure reason: #{reason}")
        maybe_notify_qr_error(state, {:failure, reason})
        {state, []}
    end
  end

  defp handle_connection_node(%Binary.Node{tag: "stream:features"}, state) do
    Logger.debug(
      "[NODE_HANDLER] stream features received session_id=#{inspect(Map.get(state, :session_id))}"
    )

    {state, []}
  end

  defp handle_connection_node(%Binary.Node{tag: "xmlstreamend"}, state) do
    Logger.warning("[SESSION] Received xmlstreamend, closing transport")
    send(self(), {:connection_event, {:transport, {:closed, :xmlstreamend}}})
    {state, []}
  end

  # Handle stream:error - server-side errors
  # Reference: whatsmeow/connectionevents.go handleStreamError()
  defp handle_connection_node(
         %Binary.Node{tag: "stream:error", attrs: attrs, content: children},
         state
       ) do
    code = Map.get(attrs, "code", "unknown")
    first_child_tag = first_stream_error_child_tag(children)
    children_summary = summarize_stream_error_children(children)

    if transient_stream_error?(code) do
      Logger.warning("[SESSION] Recoverable stream error: code=#{code}; reconnecting")
    else
      Logger.error("[SESSION] Stream error: code=#{code}")
      Logger.error("[SESSION] Stream error attrs: #{inspect(attrs, limit: :infinity)}")

      Logger.error(
        "[SESSION] Stream error children summary: #{inspect(children_summary, limit: :infinity)}"
      )

      Logger.error(
        "[SESSION] Stream error raw children: #{inspect(children, limit: :infinity, printable_limit: 8_000)}"
      )
    end

    # Check for conflict type in children
    conflict_type = extract_conflict_type(children)
    stream_error_reason = {:stream_error, code, conflict_type}

    # Recoverable server-side conditions (503/515) are announced as a soft
    # "reconnecting" notice rather than a hard error, so owners don't raise
    # user-facing alerts for transient blips that the runtime recovers from.
    if transient_stream_error?(code) do
      broadcast_reconnecting_event(state, stream_error_reason)
    else
      broadcast_error_event(state, stream_error_reason)
    end

    new_state =
      cond do
        code == "401" ->
          Logger.error("[SESSION] Device was removed (401)! Need to re-pair from scratch.")
          Logger.error("[SESSION] Delete session file and scan QR code again.")
          maybe_notify_qr_error(state, :device_removed)
          state = Safety.record_signal(state, :device_removed)
          # Mark session invalid, then trigger the normal disconnect path in Worker.
          state
          |> Map.put(:session_invalid, true)
          |> mark_transport_closed(stream_error_reason)

        conflict_type == "replaced" ->
          Logger.error("[SESSION] Stream replaced by another connection, restarting transport")
          maybe_notify_qr_error(state, :stream_replaced)
          state = Safety.record_signal(state, :stream_replaced)
          restart_connection_now(state, :stream_replaced)

        code == "515" ->
          Logger.warning("[SESSION] Got 515, will reconnect...")
          mark_transport_closed(state, stream_error_reason)

        code == "503" ->
          Logger.warning("[SESSION] Got 503 (service unavailable), will reconnect...")
          mark_transport_closed(state, stream_error_reason)

        true ->
          Logger.error(
            "[SESSION] Unknown stream error: code=#{code}, conflict=#{conflict_type}, first_child=#{inspect(first_child_tag)}"
          )

          mark_transport_closed(state, stream_error_reason)
      end

    {new_state, []}
  end

  # Handle incoming messages and notifications via MessageHandler
  defp handle_connection_node(%Binary.Node{tag: tag} = node, state)
       when tag in ["message", "notification", "receipt", "ack", "call", "presence", "chatstate"] do
    Logger.debug(
      "[NODE_HANDLER] routing inbound content node session_id=#{inspect(Map.get(state, :session_id))} tag=#{tag} attrs=#{inspect(loggable_attrs(node.attrs || %{}), limit: 60)}"
    )

    Inbound.handle_message_node(
      node,
      state,
      &ReceiptBuilder.build_receipt_ack/5,
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
    Logger.debug(
      "[NODE_HANDLER] unhandled node session_id=#{inspect(Map.get(state, :session_id))} tag=#{inspect(node.tag)} attrs=#{inspect(loggable_attrs(node.attrs || %{}), limit: 60)}"
    )

    {update_stats(state, :messages_received), []}
  end

  # IQ routing and pending-request handling

  defp forward_iq_to_workers(state, iq_type, iq_id, node)
       when iq_type in ["result", "error"] and iq_id != nil do
    workers = Map.get(state, :send_workers, %{})

    if map_size(workers) > 0 do
      Logger.debug("[SESSION] Forwarding IQ #{iq_id} to #{map_size(workers)} workers")
      msg_tag = if iq_type == "result", do: :prekey_response, else: :prekey_error
      broadcast_iq_to_workers(workers, msg_tag, iq_id, node)
    else
      Logger.debug("[NODE_HANDLER] no send workers waiting for IQ id=#{inspect(iq_id)}")
    end

    state
  end

  defp forward_iq_to_workers(state, _iq_type, _iq_id, _node), do: state

  defp resolve_pending_iq(state, iq_type, iq_id, node)
       when iq_type in ["result", "error"] and iq_id != nil do
    case Map.pop(state.pending_iqs, iq_id) do
      {nil, _} ->
        Logger.debug("[NODE_HANDLER] no pending IQ match for id=#{inspect(iq_id)}")
        {state, false}

      {%{from: from, timer: timer}, pending_iqs} ->
        Process.cancel_timer(timer)
        reply = if iq_type == "result", do: {:ok, node}, else: {:error, node}
        GenServer.reply(from, reply)

        Logger.debug(
          "[NODE_HANDLER] resolved pending IQ id=#{inspect(iq_id)} reply_type=#{iq_type}"
        )

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

  defp first_stream_error_child_tag([%Binary.Node{tag: tag} | _]) when is_binary(tag), do: tag
  defp first_stream_error_child_tag(_children), do: nil

  defp summarize_stream_error_children(children) when is_list(children) do
    Enum.map(children, fn
      %Binary.Node{tag: tag, attrs: attrs, content: content} ->
        %{
          tag: tag,
          attrs: attrs,
          child_count: child_count(content),
          binary_bytes: binary_bytes(content)
        }

      other ->
        %{unexpected: inspect(other, limit: 20, printable_limit: 500)}
    end)
  end

  defp summarize_stream_error_children(_children), do: []

  defp child_count(content) when is_list(content), do: length(content)
  defp child_count(_content), do: 0

  defp binary_bytes(content) when is_binary(content), do: byte_size(content)
  defp binary_bytes(_content), do: 0

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

  defp dispatch_iq(state, node, attrs, xmlns, iq_type, iq_id) do
    case maybe_handle_post_auth_iq(state, node, iq_type, iq_id) do
      {:handled, next_state, actions} ->
        {next_state, actions}

      :unhandled ->
        dispatch_iq_default(state, node, attrs, xmlns, iq_type, iq_id)
    end
  end

  defp dispatch_iq_default(state, node, attrs, xmlns, iq_type, iq_id) do
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

  defp maybe_handle_post_auth_iq(state, node, "result", iq_id)
       when is_binary(iq_id) and state.prekey_count_query_id != nil and
              iq_id == state.prekey_count_query_id do
    Logger.debug("[NODE_HANDLER] matched post-auth prekey count IQ id=#{iq_id}")

    {next_state, actions} =
      PostAuth.handle_prekey_count_response(node, state, &build_set_passive_iq/0)

    {:handled, next_state, actions}
  end

  defp maybe_handle_post_auth_iq(state, node, iq_type, iq_id)
       when iq_type in ["result", "error"] and is_binary(iq_id) and
              state.prekey_upload_iq_id != nil and iq_id == state.prekey_upload_iq_id do
    Logger.debug("[NODE_HANDLER] matched post-auth prekey upload IQ id=#{iq_id} type=#{iq_type}")

    {next_state, actions} =
      PostAuth.handle_prekey_upload_response(node, iq_type, state, &build_set_passive_iq/0)

    {:handled, next_state, actions}
  end

  defp maybe_handle_post_auth_iq(state, node, iq_type, iq_id)
       when iq_type in ["result", "error"] and is_binary(iq_id) and
              state.passive_iq_id != nil and iq_id == state.passive_iq_id do
    Logger.debug("[NODE_HANDLER] matched post-auth passive IQ id=#{iq_id} type=#{iq_type}")

    {next_state, actions} =
      PostAuth.handle_passive_response(
        node,
        iq_type,
        state,
        &build_digest_query/0,
        fn -> build_unified_session_node(state) end
      )

    {:handled, next_state, actions}
  end

  defp maybe_handle_post_auth_iq(state, node, iq_type, iq_id)
       when iq_type in ["result", "error"] and is_binary(iq_id) and
              state.digest_iq_id != nil and iq_id == state.digest_iq_id do
    Logger.debug("[NODE_HANDLER] matched post-auth digest IQ id=#{iq_id} type=#{iq_type}")

    {next_state, actions} =
      PostAuth.handle_digest_response(node, iq_type, state, fn ->
        build_unified_session_node(state)
      end)

    {:handled, next_state, actions}
  end

  defp maybe_handle_post_auth_iq(_state, _node, _iq_type, _iq_id), do: :unhandled

  # Protocol response builders

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
  defp build_set_passive_iq(passive \\ false) do
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

  defp build_digest_query do
    %Binary.Node{
      tag: "iq",
      attrs: %{
        "id" => generate_request_id(),
        "xmlns" => "encrypt",
        "type" => "get",
        "to" => "s.whatsapp.net"
      },
      content: [%Binary.Node{tag: "digest", attrs: %{}, content: nil}]
    }
  end

  defp build_unified_session_node(state) do
    %Binary.Node{
      tag: "ib",
      attrs: %{},
      content: [
        %Binary.Node{
          tag: "unified_session",
          attrs: %{"id" => unified_session_id(state)},
          content: nil
        }
      ]
    }
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64() |> String.slice(0, 16)
  end

  defp unified_session_id(state) do
    offset_ms = Map.get(state, :server_time_offset_ms, 0)

    rem(
      System.system_time(:millisecond) + offset_ms + 3 * 24 * 60 * 60 * 1000,
      7 * 24 * 60 * 60 * 1000
    )
    |> Integer.to_string()
  end

  # Executing pairing and session actions

  defp handle_pairing_action({:send_node, node}, %{outbound_queue: outbound_queue})
       when is_pid(outbound_queue) do
    Logger.debug(
      "[NODE_HANDLER] enqueueing outbound node action tag=#{node.tag} attrs=#{inspect(loggable_attrs(node.attrs || %{}), limit: 60)}"
    )

    OutboundQueue.enqueue_node(outbound_queue, node)
  end

  defp handle_pairing_action({:qr, code}, state), do: notify_qr(state, {:code, code})

  defp handle_pairing_action({:status, :success}, state), do: notify_qr(state, :success)

  defp handle_pairing_action({:pairing_success, :link_code, jid}, state) do
    Subscribers.broadcast_lifecycle(
      Map.get(state, :session_id),
      {:ex_wapp_session, :pairing_success, %{via: :link_code, jid: jid}}
    )

    :ok
  end

  defp handle_pairing_action(:mark_authenticated, _state),
    do:
      (
        Logger.debug("[NODE_HANDLER] dispatching auth ready event")
        send(self(), {:connection_event, {:auth, :ready}})
      )

  defp handle_pairing_action(:mark_auth_connected, _state),
    do:
      (
        Logger.debug("[NODE_HANDLER] dispatching auth connected event")
        send(self(), {:connection_event, {:auth, :success_received}})
      )

  defp handle_pairing_action({:error, reason}, state), do: notify_qr(state, {:error, reason})

  defp handle_pairing_action(:restart_stream, %{outbound_queue: outbound_queue})
       when is_pid(outbound_queue) do
    OutboundQueue.restart_stream(outbound_queue)
  end

  defp handle_pairing_action({:retry_outgoing_message, jid, message_id}, _state) do
    send(self(), {:retry_outgoing_message, jid, message_id})
  end

  defp handle_pairing_action({:retry_outgoing_message, jid, message_id, retry_meta}, _state) do
    send(self(), {:retry_outgoing_message, jid, message_id, retry_meta})
  end

  defp handle_pairing_action({:signal_sessions_updated, sessions}, _state) do
    if ExWapp.Signal.SessionStore.store?(sessions) do
      send(self(), {:signal_sessions_updated, sessions})
    end
  end

  defp handle_pairing_action({:refresh_identity_session, jid}, _state) do
    send(self(), {:refresh_identity_session, jid})
    :ok
  end

  defp handle_pairing_action({:refill_prekeys, server_count}, _state) do
    send(self(), {:refill_prekeys, server_count})
    :ok
  end

  defp handle_pairing_action({:resolve_media_retry, from, result}, state) do
    GenServer.reply(from, result)

    Subscribers.broadcast_lifecycle(
      Map.get(state, :session_id),
      {:ex_wapp_session, :media_retry, result}
    )

    :ok
  end

  defp handle_pairing_action({:contacts_changed, payload}, state) do
    Subscribers.broadcast_lifecycle(
      Map.get(state, :session_id),
      {:ex_wapp_session, :contacts_changed, payload}
    )

    send(self(), {:app_state_sync_collections, ["critical_unblock_low"]})
    :ok
  end

  defp handle_pairing_action(_action, _state), do: :ok

  # Subscriber and state helpers

  defp notify_qr(state, event) do
    Subscribers.notify_qr(state, event, fn -> :ok end)
  end

  defp broadcast_error_event(state, reason) do
    Subscribers.broadcast_error(Map.get(state, :session_id), reason)
  rescue
    _ -> :ok
  end

  defp broadcast_reconnecting_event(state, reason) do
    Subscribers.broadcast_reconnecting(Map.get(state, :session_id), reason)
  rescue
    _ -> :ok
  end

  # Recoverable, server-driven stream errors that the runtime reconnects from.
  defp transient_stream_error?(code), do: code in ["503", "515"]

  defp restart_connection_now(state, reason) do
    # Delegate back to the worker process
    send(self(), {:restart_connection, reason})
    state
  end

  defp mark_transport_closed(state, reason) do
    # Route through Worker's transport-close path so disconnect events are emitted consistently.
    send(self(), {:connection_event, {:transport, {:closed, reason}}})
    state
  end

  defp update_server_time_offset(state, attrs) when is_map(attrs) do
    case Map.get(attrs, "t") do
      value when is_binary(value) ->
        case Integer.parse(value) do
          {unix_seconds, ""} when unix_seconds > 0 ->
            local_ms = System.system_time(:millisecond)
            offset_ms = unix_seconds * 1000 - local_ms
            Map.put(state, :server_time_offset_ms, offset_ms)

          _ ->
            state
        end

      _ ->
        state
    end
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

  defp maybe_notify_qr_error(state, reason) do
    if vext_managed_runtime?(state) do
      :ok
    else
      notify_qr(state, {:error, reason})
    end
  end

  defp vext_managed_runtime?(%{runtime_cfg: runtime_cfg}) when is_map(runtime_cfg) do
    Config.get(runtime_cfg, [:ownership, :vext_managed], false)
  end

  defp vext_managed_runtime?(_state), do: false

  defp loggable_attrs(attrs) when is_map(attrs) do
    attrs
    |> Enum.map(fn {key, value} -> {key, loggable_attr_value(value)} end)
    |> Enum.into(%{})
  end

  defp loggable_attrs(value), do: value

  defp loggable_attr_value(%{__struct__: module} = value) do
    %{struct: inspect(module), value: inspect(value, limit: 20)}
  end

  defp loggable_attr_value(value) when is_binary(value) and byte_size(value) > 120 do
    String.slice(value, 0, 120)
  end

  defp loggable_attr_value(value), do: value

  defp compact_action({:send_node, %Binary.Node{} = node}) do
    {:send_node,
     %{
       tag: node.tag,
       attrs: loggable_attrs(node.attrs || %{}),
       child_count: if(is_list(node.content), do: length(node.content), else: 0)
     }}
  end

  defp compact_action(other), do: other
end
