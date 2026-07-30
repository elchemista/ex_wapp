defmodule ExWapp.Session.Worker.Connection do
  @moduledoc """
  The session's connection lifecycle: opening the transport, reacting to what it
  reports, tearing it down and deciding when to try again.

  Everything here runs inside the session process — the worker calls these
  functions, so the transport is linked to it, `Process.monitor/1` registers the
  monitor against it and timers fire back into its mailbox, exactly as when this
  code sat in `ExWapp.Session.Worker`. Nothing is moved to another process; only
  the code moved out of the module.

  Teardown is deliberately tolerant: a disconnect cancels timers, drains pending
  callers and stops child processes, and each of those steps has to run even if
  an earlier one found nothing to clean up.
  """

  require Logger

  alias ExWapp.Binary
  alias ExWapp.Config
  alias ExWapp.Log
  alias ExWapp.Noise.ClientPayload
  alias ExWapp.Session.AppStateSync
  alias ExWapp.Session.InboundRouter
  alias ExWapp.Session.InitialSync
  alias ExWapp.Session.OutboundQueue
  alias ExWapp.Session.SendCoordinator
  alias ExWapp.Session.Worker
  alias ExWapp.Session.Worker.Events
  alias ExWapp.Session.Worker.NodeHandler
  alias ExWapp.Session.Worker.Resilience
  alias ExWapp.Session.Worker.SignalSessions
  alias ExWapp.Session.Worker.Subscribers

  def do_connect(%Worker{status: status} = state)
      when status not in [:idle, :disconnected] do
    Logger.debug("[SESSION] do_connect SKIPPED - status=#{status} not in [:idle, :disconnected]")
    state
  end

  def do_connect(%Worker{} = state) do
    Logger.debug("[SESSION] do_connect starting connection...")
    Logger.debug("[SESSION] store_adapter=#{inspect(state.store.__struct__)}")
    Events.emit_telemetry(:connect, %{attempt: state.reconnect_attempts}, state)

    case safe_start_connection(state) do
      {:ok, conn_pid} ->
        Logger.debug("[SESSION] ✓ Connection started: #{inspect(conn_pid)}")
        conn_ref = Process.monitor(conn_pid)

        %{
          state
          | conn: conn_pid,
            conn_ref: conn_ref,
            status: :connecting,
            transport_ready?: false
        }
        |> schedule_health_check()

      {:error, reason} ->
        Logger.debug("[SESSION] ✗ Connection FAILED: #{Log.reason(reason)}")
        Logger.error("Failed to start connection: #{Log.reason(reason)}")
        Events.emit_telemetry(:error, %{reason: reason, phase: :connect}, state)

        if vext_managed_runtime?(state) do
          disconnect_reason = {:connect_failed, reason}

          Subscribers.broadcast_lifecycle(
            state.session_id,
            {:ex_wapp_session, :disconnected, disconnect_reason,
             Events.lifecycle_event_meta(state)}
          )

          state
          |> Events.update_stats(:errors)
          |> Map.put(:status, :disconnected)
          |> Map.put(:last_disconnect_reason, disconnect_reason)
        else
          Events.notify_qr(state, {:error, reason})
          schedule_reconnect(state, reason)
        end
    end
  end

  defp safe_start_connection(state) do
    Logger.debug("[SESSION] safe_start_connection calling transport.start_link...")

    noise_opts =
      state.opts.noise
      |> Keyword.put_new(
        :client_payload_fun,
        &ClientPayload.build(&1, state.runtime_cfg)
      )

    result =
      state.transport_mod.start_link(session: self(), store: state.store, noise: noise_opts)

    Logger.debug("[SESSION] transport.start_link result: #{Log.reason(result)}")
    result
  rescue
    e ->
      Logger.debug("[SESSION] ✗ transport.start_link EXCEPTION: #{Log.reason(e)}")
      {:error, {:exception, e}}
  catch
    :exit, reason ->
      Logger.debug("[SESSION] ✗ transport.start_link EXIT: #{Log.reason(reason)}")
      {:error, {:exit, reason}}
  end

  def do_disconnect(%Worker{conn: nil} = state, reason) do
    state =
      state
      |> cancel_health_check()
      |> cancel_session_tasks(reason)
      |> clear_pending_requests(reason)

    OutboundQueue.clear_conn(state.outbound_queue)

    %{
      state
      | transport_ready?: false,
        post_auth_phase: :idle,
        prekey_count_query_id: nil,
        prekey_upload_iq_id: nil,
        pending_prekey_upload: [],
        passive_iq_id: nil,
        digest_iq_id: nil
    }
  end

  def do_disconnect(%Worker{conn: conn, conn_ref: ref} = state, reason) do
    if ref, do: Process.demonitor(ref, [:flush])

    state =
      state
      |> cancel_health_check()
      |> cancel_session_tasks(reason)
      |> clear_pending_requests(reason)

    OutboundQueue.clear_conn(state.outbound_queue)

    # Gracefully stop connection
    try do
      GenServer.stop(conn, :normal, 5_000)
    catch
      :exit, _ -> :ok
    end

    Events.emit_telemetry(:disconnected, %{reason: reason}, state)

    Subscribers.broadcast_lifecycle(
      state.session_id,
      {:ex_wapp_session, :disconnected, reason, Events.lifecycle_event_meta(state)}
    )

    %{
      state
      | conn: nil,
        conn_ref: nil,
        status: :disconnected,
        last_disconnect_reason: reason,
        connected_at: nil,
        transport_ready?: false,
        post_auth_phase: :idle,
        prekey_count_query_id: nil,
        prekey_upload_iq_id: nil,
        pending_prekey_upload: [],
        passive_iq_id: nil,
        digest_iq_id: nil
    }
  end

  def handle_connection_exit(state, reason) do
    OutboundQueue.clear_conn(state.outbound_queue)

    next_state =
      state
      |> cancel_session_tasks(reason)
      |> clear_pending_requests(reason)
      |> cancel_health_check()
      |> Map.merge(%{
        conn: nil,
        conn_ref: nil,
        status: :disconnected,
        last_disconnect_reason: reason,
        connected_at: nil,
        transport_ready?: false,
        post_auth_phase: :idle,
        prekey_count_query_id: nil,
        prekey_upload_iq_id: nil,
        pending_prekey_upload: [],
        passive_iq_id: nil,
        digest_iq_id: nil
      })
      |> Events.update_stats(:reconnects)

    Events.emit_telemetry(:disconnected, %{reason: reason}, next_state)

    Subscribers.broadcast_lifecycle(
      next_state.session_id,
      {:ex_wapp_session, :disconnected, reason, Events.lifecycle_event_meta(next_state)}
    )

    if vext_managed_runtime?(next_state) do
      next_state
    else
      Events.notify_qr(next_state, {:error, {:disconnected, reason}})
      schedule_reconnect(next_state, reason)
    end
  end

  # Reconnect scheduling and backoff

  def schedule_connect(state, delay_ms) do
    Logger.debug("[SESSION] schedule_connect with delay=#{delay_ms}ms")
    Process.send_after(self(), :connect, delay_ms)
    # Don't change status here - do_connect will set it after successful connection
    state
  end

  def restart_connection_now(state, reason) do
    reconnect_cfg = Config.get(state, [:runtime_cfg, :reconnect], %{})

    if Resilience.reconnect_enabled?(state, reconnect_cfg) do
      state
      |> do_disconnect(reason)
      |> Map.put(:reconnect_attempts, 0)
      |> schedule_connect(0)
    else
      Logger.error(
        "[SESSION] Immediate reconnect suppressed: reconnect disabled, reason=#{Log.reason(reason)}"
      )

      state
      |> do_disconnect(reason)
      |> Map.put(:reconnect_attempts, 0)
      |> Map.put(:status, :idle)
    end
  end

  defp schedule_reconnect(state, _reason) do
    if vext_managed_runtime?(state) do
      Logger.debug("[SESSION] Reconnect delegated to Vext runtime owner")
      %{state | status: :disconnected}
    else
      case Resilience.reconnect_decision(state) do
        :session_invalid ->
          Logger.error(
            "[SESSION] Session invalid (401), not reconnecting. Clear session to re-pair."
          )

          Events.notify_qr(state, {:error, :session_invalid})
          %{state | status: :idle}

        {:reconnect, attempt, delay} ->
          Logger.debug("Scheduling reconnect attempt #{attempt} in #{delay}ms")
          Process.send_after(self(), {:reconnect, attempt}, delay)

          %{state | status: :disconnected}

        :give_up ->
          Logger.error("Reconnect disabled or max reconnect attempts reached, giving up")
          Events.notify_qr(state, {:error, :max_reconnect_attempts})
          %{state | status: :idle}
      end
    end
  end

  # Periodic health checks

  defp schedule_health_check(state) do
    interval_ms = Config.get(state.runtime_cfg, [:health, :check_interval_ms], 30_000)
    timer = Process.send_after(self(), :health_check, interval_ms)
    %{state | health_timer: timer}
  end

  defp cancel_health_check(%{health_timer: nil} = state), do: state

  defp cancel_health_check(%{health_timer: timer} = state) do
    Process.cancel_timer(timer)
    %{state | health_timer: nil}
  end

  # A reconnect is the one moment this client knows its view of every peer may
  # have gone stale without being told: messages it never saw were exchanged
  # while the socket was down, and a session file restored from a snapshot comes
  # back with ratchets the peers moved past long ago. Dropping the sessions that
  # look one-way here costs one prekey fetch on the next send to those peers, and
  # buys back the case where the alternative is an unbounded run of rejected
  # sends. Deployments that restore the store from an external snapshot can turn
  # `reset_sessions_on_connect` on and pay that cost for every peer instead.

  def do_health_check(%{conn: nil} = state), do: state

  def do_health_check(%{conn: conn} = state) when is_pid(conn) do
    if Process.alive?(conn) do
      # Keepalive is a lightweight client ping.
      # Presence and passive-state assertions belong to the post-auth path, not
      # to every health tick.
      if state.status in [:connected, :syncing] and is_pid(state.outbound_queue) do
        ping_node = %ExWapp.Binary.Node{
          tag: "iq",
          attrs: %{
            "id" => to_string(System.unique_integer([:positive])),
            "to" => "s.whatsapp.net",
            "type" => "get",
            "xmlns" => "w:p"
          },
          content: [
            %ExWapp.Binary.Node{tag: "ping", attrs: %{}, content: nil}
          ]
        }

        OutboundQueue.enqueue_node(state.outbound_queue, ping_node)
      end

      schedule_health_check(state)
    else
      Logger.warning("Connection process died unexpectedly")
      handle_connection_exit(state, :process_died)
    end
  end

  # Transport and authentication events

  def handle_connection_event({:noise, :handshake_started}, state) do
    %{
      state
      | status: :handshaking,
        transport_ready?: false
    }
  end

  def handle_connection_event({:transport, :connected}, state) do
    %{state | status: :connecting, transport_ready?: false}
  end

  def handle_connection_event({:transport, {:closed, reason}}, %{conn: nil} = state) do
    Logger.debug(
      "[SESSION] Ignoring stale transport close: #{inspect(connection_close_reason_summary(reason))}"
    )

    state
  end

  def handle_connection_event({:transport, {:closed, reason}}, state) do
    Logger.warning(
      "[SESSION] Transport closed: #{inspect(connection_close_reason_summary(reason))}"
    )

    handle_connection_exit(state, {:transport_closed, reason})
  end

  def handle_connection_event({:noise, :handshake_completed}, state) do
    Logger.debug("[SESSION] Noise handshake completed, waiting for post-auth success")

    state =
      %{
        state
        | status: :handshaking,
          transport_ready?: true,
          post_auth_phase: :idle,
          prekey_count_query_id: nil,
          prekey_upload_iq_id: nil,
          pending_prekey_upload: [],
          passive_iq_id: nil,
          digest_iq_id: nil
      }

    maybe_set_conn(state.outbound_queue, state)

    Subscribers.broadcast_lifecycle(
      state.session_id,
      {:ex_wapp_session, :transport_ready, Events.lifecycle_event_meta(state)}
    )

    state
  end

  def handle_connection_event({:auth, :success_received}, state) do
    Subscribers.broadcast_lifecycle(
      state.session_id,
      {:ex_wapp_session, :connected, Events.lifecycle_event_meta(state)}
    )

    state
  end

  def handle_connection_event({:auth, :ready}, state) do
    Events.emit_telemetry(:connected, %{}, state)

    initial_sync? =
      AppStateSync.initial_enabled?(state) and AppStateSync.keys_available?(state.store)

    state =
      %{
        state
        | status: if(initial_sync?, do: :syncing, else: :connected),
          reconnect_attempts: 0,
          connected_at: DateTime.utc_now(),
          post_auth_phase: :complete
      }
      |> SignalSessions.refresh_on_connect()

    Subscribers.broadcast_lifecycle(
      state.session_id,
      {:ex_wapp_session, :post_auth_ready,
       Events.lifecycle_event_meta(state, %{initial_sync_pending?: initial_sync?})}
    )

    AppStateSync.schedule_initial(state, self())
  end

  def handle_connection_event({:connection_message, %Binary.Node{} = node}, state) do
    # ACK at the connection boundary, before routing/decryption/persistence.
    # This keeps protocol liveness independent from application work.
    node
    |> NodeHandler.immediate_actions()
    |> Enum.each(&NodeHandler.safe_handle_action(&1, state))

    InboundRouter.route(state.inbound_router, node)
    state
  end

  def handle_connection_event({:connection_binary, _payload}, state), do: state

  def handle_connection_event({:error, reason}, state) do
    Logger.warning("Connection error: #{Log.reason(reason)}")
    Events.emit_telemetry(:error, %{reason: reason}, state)
    state = Events.update_stats(state, :errors)

    if vext_managed_runtime?(state) do
      Subscribers.broadcast_error(state.session_id, reason)
      state
    else
      Events.notify_qr(state, {:error, reason})
      state
    end
  end

  def handle_connection_event(event, state) do
    Logger.debug("Unhandled connection event: #{inspect(connection_event_summary(event))}")
    state
  end

  defp vext_managed_runtime?(%{runtime_cfg: runtime_cfg}) do
    Config.get(runtime_cfg, [:ownership, :vext_managed], false)
  end

  # Message subscriber delivery

  def restart_outbound_queue(state) do
    {:ok, outbound_queue} =
      OutboundQueue.start_link(
        session: self(),
        transport: state.transport_mod,
        max_size: Config.get(state.runtime_cfg, [:queue, :max_size], 10_000),
        drop_policy: Config.get(state.runtime_cfg, [:queue, :drop_policy], :reject_new),
        flush_batch_size: Config.get(state.runtime_cfg, [:queue, :flush_batch_size], 100),
        flush_tick_ms: Config.get(state.runtime_cfg, [:queue, :flush_tick_ms], 10)
      )

    maybe_set_conn(outbound_queue, state)
    %{state | outbound_queue: outbound_queue}
  end

  def restart_inbound_router(state) do
    {:ok, inbound_router} = InboundRouter.start_link(session: self())
    %{state | inbound_router: inbound_router}
  end

  defp maybe_set_conn(_outbound_queue, %{transport_ready?: false}), do: :ok

  defp maybe_set_conn(_outbound_queue, %{conn: nil}), do: :ok

  defp maybe_set_conn(outbound_queue, %{transport_ready?: true, conn: conn})
       when is_pid(outbound_queue) and is_pid(conn) do
    OutboundQueue.set_conn(outbound_queue, conn)
  end

  defp maybe_set_conn(_outbound_queue, _state), do: :ok

  def fail_all_send_workers(state, reason) do
    {operations, iq_routes, coordinator} = SendCoordinator.drain(state.send_coordinator)

    Enum.each(operations, fn operation ->
      Process.demonitor(operation.monitor, [:flush])
      reply_send_caller(operation.from, {:error, reason})
    end)

    Enum.each(iq_routes, fn {iq_id, worker_pid} ->
      if Process.alive?(worker_pid), do: send(worker_pid, {:prekey_error, iq_id, reason})
    end)

    %{state | send_coordinator: coordinator}
  end

  def reply_send_caller(nil, _result), do: :ok

  def reply_send_caller(from, result), do: GenServer.reply(from, result)

  defp clear_pending_requests(state, reason) do
    Enum.each(state.pending_iqs, &cancel_pending_call(&1, reason))
    Enum.each(state.outbound_confirmations, &cancel_pending_timer/1)
    Enum.each(state.pending_media_retries, &cancel_pending_call(&1, reason))

    state
    |> fail_all_send_workers({:disconnected, reason})
    |> Map.put(:pending_iqs, %{})
    |> Map.put(:outbound_confirmations, %{})
    |> Map.put(:pending_media_retries, %{})
  end

  defp cancel_session_tasks(state, reason) do
    if InitialSync.active?(state.initial_sync) do
      Logger.debug(
        "[APP_STATE] cancelling initial sync session=#{Log.reference(state.session_id)} reason=#{Log.reason(reason)}"
      )
    end

    state = clear_initial_sync_task(state)

    state.send_worker_sup
    |> task_supervisor_children()
    |> Enum.each(&terminate_supervised_task(state.send_worker_sup, &1))

    state
  end

  defp task_supervisor_children(supervisor) when is_pid(supervisor) do
    Task.Supervisor.children(supervisor)
  rescue
    _ -> []
  catch
    :exit, _ -> []
  end

  defp task_supervisor_children(_supervisor), do: []

  defp terminate_supervised_task(supervisor, task_pid)
       when is_pid(supervisor) and is_pid(task_pid) do
    Task.Supervisor.terminate_child(supervisor, task_pid)
  rescue
    _ -> :ok
  catch
    :exit, _ -> :ok
  end

  defp terminate_supervised_task(_supervisor, _task_pid), do: :ok

  defp cancel_pending_call({_id, pending}, reason) do
    cancel_pending_timer(pending)

    case Map.get(pending, :from) do
      nil -> :ok
      from -> GenServer.reply(from, {:error, {:disconnected, reason}})
    end
  end

  defp cancel_pending_timer({_id, pending}), do: cancel_pending_timer(pending)

  defp cancel_pending_timer(pending) do
    case Map.get(pending, :timer) do
      timer when is_reference(timer) -> Process.cancel_timer(timer)
      _ -> :ok
    end
  end

  def ensure_connected_for_send(%{status: status}) when status != :connected,
    do: {:error, {:not_connected, status}}

  def ensure_connected_for_send(%{conn: conn, status: status}) when not is_pid(conn),
    do: {:error, {:not_connected, status}}

  def ensure_connected_for_send(_state), do: :ok

  def clear_initial_sync_task(%{initial_sync: %InitialSync{monitor: ref} = initial_sync} = state) do
    if is_reference(ref), do: Process.demonitor(ref, [:flush])
    %{state | initial_sync: InitialSync.reset(initial_sync)}
  end

  def connection_event_summary({:connection_message, %Binary.Node{} = node}) do
    {:connection_message,
     %{tag: node.tag, attrs: node.attrs |> then(&(&1 || %{})) |> Map.keys() |> Enum.sort()}}
  end

  def connection_event_summary({:connection_binary, payload}) when is_binary(payload),
    do: {:connection_binary, %{bytes: byte_size(payload)}}

  def connection_event_summary({:transport, {:closed, reason}}),
    do: {:transport, {:closed, connection_close_reason_summary(reason)}}

  def connection_event_summary(event), do: Log.safe_term(event)

  defp connection_close_reason_summary(%{__struct__: module}),
    do: %{type: inspect(module)}

  defp connection_close_reason_summary(reason) when is_map(reason) do
    reason
    |> Map.take([:reason, :attempt_number, :code])
    |> Map.new(fn {key, value} -> {key, Log.safe_term(value)} end)
  end

  defp connection_close_reason_summary(reason), do: Log.safe_term(reason)
end
