defmodule ExWapp.Session.Worker do
  @moduledoc """
  Coordinates the lifecycle of a WhatsApp Web connection.

  This GenServer is designed for long-running production use with:
  - Automatic reconnection with exponential backoff
  - Connection health monitoring
  - Graceful degradation on errors
  - Telemetry events for observability
  - Crash recovery via supervision

  ## Supervision

  For production use, run Session under `ExWapp.Session.Supervisor`:

      {:ok, sup} = ExWapp.Session.Supervisor.start_link(
        store: {ExWapp.Store.Ets, path: "/var/lib/myapp/wa.etf"}
      )
      session = ExWapp.Session.Supervisor.session(sup)

  ## Telemetry Events

  The session emits the following telemetry events:

    * `[:ex_wapp, :session, :init]` - Session process initialized
    * `[:ex_wapp, :session, :connect]` - Connection attempt
    * `[:ex_wapp, :session, :connected]` - Successfully connected
    * `[:ex_wapp, :session, :disconnected]` - Connection lost
    * `[:ex_wapp, :session, :reconnect]` - Reconnection attempt
    * `[:ex_wapp, :session, :error]` - Error occurred
    * `[:ex_wapp, :session, :qr]` - QR lifecycle event (`:code`, `:success`, `:error`)
    * `[:ex_wapp, :session, :message_received]` - Message persisted/forwarded
    * `[:ex_wapp, :session, :message_sent]` - Message sent to transport
    * `[:ex_wapp, :session, :terminate]` - Session terminate callback

  ## State Machine

      idle -> connecting -> handshaking -> connected
        ^                                      |
        |                                      v
        +<-------- disconnected <--------------+
  """

  use GenServer
  require Logger

  alias ExWapp.{Binary, Chat, MapPath, Pairing, Store, Telemetry}

  alias ExWapp.Session.{
    Account,
    Inbound,
    InboundRouter,
    JIDUtils,
    Outbound,
    OutboundQueue,
    Resilience,
    Retry,
    Subscribers
  }

  @health_check_interval_ms 30_000
  @min_prekey_threshold 5
  @max_outgoing_retry_attempts 2
  @silent_drop_confirm_timeout_ms 6_000
  @max_silent_drop_fallback_attempts 1

  @typedoc "Human readable events emitted during the pairing flow."
  @type qr_event :: {:code, String.t()} | :success | {:error, term()}

  @typedoc "Session status"
  @type status :: :idle | :connecting | :handshaking | :connected | :disconnected

  defstruct [
    :store,
    :transport_mod,
    :pairing,
    :conn,
    :conn_ref,
    :outbound_queue,
    :inbound_router,
    :send_worker_sup,
    :session_id,
    :health_timer,
    status: :idle,
    qr_subscribers: %{},
    message_subscribers: %{},
    send_workers: %{},
    send_worker_mons: %{},
    opts: [],
    reconnect_attempts: 0,
    last_disconnect_reason: nil,
    connected_at: nil,
    session_invalid: false,
    pending_iqs: %{},
    signal_sessions: nil,
    retry_counters: %{},
    outbound_confirmations: %{},
    prekey_count_query_id: nil,
    stats: %{
      messages_sent: 0,
      messages_received: 0,
      reconnects: 0,
      errors: 0
    }
  ]

  @type t :: %__MODULE__{
          status: status(),
          conn: pid() | nil,
          conn_ref: reference() | nil,
          store: Store.t() | nil,
          transport_mod: module(),
          outbound_queue: pid() | nil,
          inbound_router: pid() | nil,
          send_worker_sup: pid() | nil,
          session_id: term() | nil,
          health_timer: reference() | nil,
          qr_subscribers: %{reference() => {pid(), reference()}},
          message_subscribers: %{reference() => {pid(), reference()}},
          send_workers: %{pid() => binary()},
          send_worker_mons: %{reference() => pid()},
          opts: keyword(),
          pairing: Pairing.state(),
          reconnect_attempts: non_neg_integer(),
          last_disconnect_reason: term() | nil,
          connected_at: DateTime.t() | nil,
          retry_counters: map(),
          outbound_confirmations: map(),
          stats: map()
        }

  # ============================================================================
  # Public API
  # ============================================================================

  @doc """
  Starts the session process.

  ## Options

    * `:name` - Register the process under a given name
    * `:store` - Storage adapter (see `ExWapp.Store`)
    * `:supervisor` - Parent supervisor PID (set automatically by Supervisor)
    * `:auto_connect` - Connect automatically on start (default: false)
    * `:reconnect` - Enable automatic reconnection (default: true)
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))
  end

  @doc """
  Initiates connection to WhatsApp servers.

  Returns immediately. Use `qr_stream/1` to receive connection events.
  """
  @spec connect(GenServer.server()) :: :ok
  def connect(server), do: GenServer.cast(server, :connect)

  @doc """
  Gracefully disconnects from WhatsApp servers.

  Stops reconnection attempts and closes the connection cleanly.
  """
  @spec disconnect(GenServer.server()) :: :ok
  def disconnect(server), do: GenServer.cast(server, :disconnect)

  @doc """
  Returns the current session state for inspection.
  """
  @spec state(GenServer.server()) :: status()
  def state(server), do: GenServer.call(server, :get_status)

  @doc """
  Returns session statistics.
  """
  @spec stats(GenServer.server()) :: map()
  def stats(server), do: GenServer.call(server, :get_stats)

  @doc """
  Subscribes to QR code events.
  """
  @spec subscribe_qr(GenServer.server()) :: {:ok, reference()}
  def subscribe_qr(server), do: GenServer.call(server, {:subscribe_qr, self()})

  @doc """
  Unsubscribes from QR code events.
  """
  @spec unsubscribe_qr(GenServer.server(), reference()) :: :ok
  def unsubscribe_qr(server, ref), do: GenServer.cast(server, {:unsubscribe_qr, ref})

  @doc """
  Queues a plain text message for sending.
  """
  @spec send_text(GenServer.server(), binary(), iodata()) :: :ok | {:error, term()}
  def send_text(server, jid, text) do
    GenServer.call(server, {:send_text, jid, IO.iodata_to_binary(text)})
  end

  @doc """
  Builds a lazy stream of QR pairing events.

  The stream yields events until pairing succeeds, fails, or is cancelled.
  """
  @spec qr_stream(GenServer.server()) :: Enumerable.t()
  def qr_stream(server) do
    Stream.resource(
      fn -> subscribe_qr(server) end,
      fn {:ok, ref} = subscription ->
        receive do
          {:ex_wapp_qr, ^ref, event} -> {[event], subscription}
          {:ex_wapp_qr_closed, ^ref} -> {:halt, subscription}
        after
          60_000 -> {[{:error, :timeout}], subscription}
        end
      end,
      fn {:ok, ref} -> unsubscribe_qr(server, ref) end
    )
  end

  @doc """
  Subscribe to incoming messages.

  Returns a reference that will be included in message notifications.
  Messages arrive as `{:ex_wapp_message, ref, jid, message}`.
  """
  @spec subscribe_messages(GenServer.server()) :: {:ok, reference()}
  def subscribe_messages(server) do
    GenServer.call(server, {:subscribe_messages, self()})
  end

  @doc """
  Unsubscribe from messages.
  """
  @spec unsubscribe_messages(GenServer.server(), reference()) :: :ok
  def unsubscribe_messages(server, ref) do
    GenServer.cast(server, {:unsubscribe_messages, ref})
  end

  @doc """
  Builds a lazy stream of incoming messages.

  Each element is a tuple of `{jid, message}`.
  """
  @spec message_stream(GenServer.server()) :: Enumerable.t()
  def message_stream(server) do
    Stream.resource(
      fn -> subscribe_messages(server) end,
      fn {:ok, ref} = subscription ->
        receive do
          {:ex_wapp_message, ^ref, jid, message} -> {[{jid, message}], subscription}
          {:ex_wapp_messages_closed, ^ref} -> {:halt, subscription}
        after
          # 5 min timeout, continue waiting
          300_000 -> {[], subscription}
        end
      end,
      fn {:ok, ref} -> unsubscribe_messages(server, ref) end
    )
  end

  # ============================================================================
  # GenServer Callbacks
  # ============================================================================

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)

    store = Store.new(Keyword.get(opts, :store))
    session_id = Keyword.get(opts, :session_id)
    transport_mod = Keyword.get(opts, :transport, ExWapp.Conn)

    # Register with Registry if session_id provided
    if session_id do
      Registry.register(ExWapp.Session.Registry, session_id, self())
    end

    {:ok, outbound_queue} =
      OutboundQueue.start_link(session: self(), transport: transport_mod)

    {:ok, inbound_router} = InboundRouter.start_link(session: self())
    {:ok, send_worker_sup} = Task.Supervisor.start_link()

    state = %__MODULE__{
      opts: opts,
      store: store,
      transport_mod: transport_mod,
      outbound_queue: outbound_queue,
      inbound_router: inbound_router,
      send_worker_sup: send_worker_sup,
      session_id: session_id,
      pairing: Pairing.new(store)
    }

    emit_telemetry(:init, %{session_id: session_id}, state)

    if Keyword.get(opts, :auto_connect, false) do
      send(self(), :connect)
    end

    {:ok, state}
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, state.status, state}
  end

  def handle_call(:get_stats, _from, state) do
    stats =
      state.stats
      |> Map.put(:status, state.status)
      |> Map.put(:connected_at, state.connected_at)
      |> Map.put(:reconnect_attempts, state.reconnect_attempts)
      |> Map.put(:uptime_seconds, calculate_uptime(state))

    {:reply, stats, state}
  end

  def handle_call({:subscribe_qr, pid}, _from, state) do
    ref = make_ref()
    mon = Process.monitor(pid)
    new_state = put_in(state.qr_subscribers[ref], {pid, mon})
    {:reply, {:ok, ref}, new_state}
  end

  def handle_call({:send_text, jid, text}, from, state) do
    # Spawn a worker to handle the full send flow (including prekey fetch if needed)
    # This allows us to wait for IQ responses without blocking the GenServer
    session_pid = self()

    case start_send_worker(
           state,
           jid,
           fn ->
             result = do_send_text_worker(session_pid, state, jid, text)
             send(session_pid, {:send_result, jid, text, result, :primary, 0})
             result
           end,
           from
         ) do
      {:ok, worker, mon} ->
        new_state =
          state
          |> Map.update(:send_workers, %{worker => jid}, fn workers ->
            Map.put(workers, worker, jid)
          end)
          |> Map.update(:send_worker_mons, %{mon => worker}, fn mons ->
            Map.put(mons, mon, worker)
          end)

        {:noreply, update_stats(new_state, :messages_sent)}

      {:error, reason} ->
        {:reply, {:error, {:send_worker_start_failed, reason}}, state}
    end
  end

  def handle_call(:get_store, _from, state) do
    {:reply, state.store, state}
  end

  def handle_call(:get_conn, _from, state) do
    {:reply, state.conn, state}
  end

  def handle_call({:send_iq, node, message_id}, from, %{status: :connected, conn: conn} = state)
      when is_pid(conn) do
    # Send the IQ node
    case state.transport_mod.send_node(conn, node) do
      :ok ->
        # Register pending IQ with timeout
        timer = Process.send_after(self(), {:iq_timeout, message_id}, 30_000)
        pending = %{from: from, timer: timer}
        new_state = %{state | pending_iqs: Map.put(state.pending_iqs, message_id, pending)}
        {:noreply, new_state}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:send_iq, _node, _message_id}, _from, state) do
    {:reply, {:error, {:not_connected, state.status}}, state}
  end

  def handle_call(:get_signal_sessions, _from, state) do
    {:reply, state.signal_sessions, state}
  end

  def handle_call({:update_signal_sessions, sessions}, _from, state) do
    {:reply, :ok, %{state | signal_sessions: sessions}}
  end

  def handle_call({:subscribe_messages, pid}, _from, state) do
    ref = make_ref()
    mon = Process.monitor(pid)
    new_state = put_in(state.message_subscribers[ref], {pid, mon})
    {:reply, {:ok, ref}, new_state}
  end

  @impl true
  def handle_cast(:connect, %__MODULE__{status: status} = state)
      when status in [:idle, :disconnected] do
    Logger.debug("[SESSION] handle_cast(:connect) - status=#{status}, scheduling connect...")
    {:noreply, schedule_connect(state, 0)}
  end

  def handle_cast(:connect, state) do
    Logger.debug("[SESSION] handle_cast(:connect) IGNORED - status=#{state.status}")
    {:noreply, state}
  end

  def handle_cast(:disconnect, state) do
    new_state = do_disconnect(state, :user_requested)
    {:noreply, %{new_state | status: :idle, reconnect_attempts: 0}}
  end

  def handle_cast({:unsubscribe_qr, ref}, state) do
    new_state = remove_qr_subscriber(state, ref)
    {:noreply, new_state}
  end

  def handle_cast({:unsubscribe_messages, ref}, state) do
    new_state = remove_message_subscriber(state, ref)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:connect, state) do
    Logger.debug("[SESSION] handle_info(:connect) - calling do_connect...")
    {:noreply, do_connect(state)}
  end

  def handle_info(:health_check, state) do
    new_state = do_health_check(state)
    {:noreply, new_state}
  end

  def handle_info({:reconnect, attempt}, state) do
    Logger.info("Reconnection attempt #{attempt}")
    emit_telemetry(:reconnect, %{attempt: attempt}, state)
    {:noreply, do_connect(%{state | reconnect_attempts: attempt})}
  end

  # Connection process exited
  def handle_info({:EXIT, pid, reason}, %__MODULE__{conn: pid} = state) do
    Logger.warning("Connection process exited: #{inspect(reason)}")
    new_state = handle_connection_exit(state, reason)
    {:noreply, new_state}
  end

  def handle_info({:EXIT, pid, reason}, %__MODULE__{outbound_queue: pid} = state) do
    Logger.warning("[SESSION] outbound queue exited: #{inspect(reason)}")
    {:noreply, restart_outbound_queue(state)}
  end

  def handle_info({:EXIT, pid, reason}, %__MODULE__{inbound_router: pid} = state) do
    Logger.warning("[SESSION] inbound router exited: #{inspect(reason)}")
    {:noreply, restart_inbound_router(state)}
  end

  def handle_info({:EXIT, pid, reason}, %__MODULE__{send_worker_sup: pid} = state) do
    Logger.warning("[SESSION] send worker supervisor exited: #{inspect(reason)}")

    case Task.Supervisor.start_link() do
      {:ok, send_worker_sup} ->
        {:noreply,
         %{state | send_worker_sup: send_worker_sup, send_workers: %{}, send_worker_mons: %{}}}

      {:error, restart_reason} ->
        Logger.error(
          "[SESSION] failed to restart send worker supervisor: #{inspect(restart_reason)}"
        )

        {:noreply, %{state | send_worker_sup: nil, send_workers: %{}, send_worker_mons: %{}}}
    end
  end

  def handle_info({:EXIT, pid, _reason}, %__MODULE__{send_workers: workers} = state) do
    send_worker_mons =
      state.send_worker_mons
      |> Enum.reject(fn {_mon, worker_pid} -> worker_pid == pid end)
      |> Map.new()

    {:noreply,
     %{state | send_workers: Map.delete(workers, pid), send_worker_mons: send_worker_mons}}
  end

  # Connection events from Conn process
  def handle_info({:connection_event, event}, state) do
    new_state = handle_connection_event(event, state)
    {:noreply, new_state}
  catch
    kind, reason ->
      Logger.error("Error handling connection event: #{kind} #{inspect(reason)}")
      new_state = update_stats(state, :errors)
      {:noreply, new_state}
  end

  # Monitor DOWN for QR subscribers
  def handle_info({:DOWN, mon, :process, _pid, _reason}, state) do
    new_state =
      state
      |> cleanup_dead_subscriber(mon)
      |> cleanup_dead_send_worker(mon)

    {:noreply, new_state}
  end

  # New message received - notify subscribers
  def handle_info({:new_message, jid, message}, state) do
    emit_telemetry(
      :message_received,
      %{message_count: 1},
      state,
      %{
        jid: jid,
        message_id: Map.get(message, :id),
        type: get_in(message, [:raw, :type])
      }
    )

    notify_message_subscribers(state, jid, message)
    {:noreply, state}
  end

  # Inbound node routed by InboundRouter process
  def handle_info({:inbound_node, %Binary.Node{} = node}, state) do
    {new_state, actions} = safe_handle_node(node, state)
    Enum.each(actions, &safe_handle_action(&1, new_state))
    {:noreply, new_state}
  end

  def handle_info({:outbound_error, _item, reason}, state) do
    Logger.warning("[SESSION] outbound queue error: #{inspect(reason)}")
    emit_telemetry(:error, %{reason: reason, phase: :outbound}, state)
    {:noreply, update_stats(state, :errors)}
  end

  # IQ timeout
  def handle_info({:iq_timeout, message_id}, state) do
    case Map.pop(state.pending_iqs, message_id) do
      {nil, _} ->
        {:noreply, state}

      {%{from: from}, pending_iqs} ->
        GenServer.reply(from, {:error, :timeout})
        {:noreply, %{state | pending_iqs: pending_iqs}}
    end
  end

  def handle_info({:signal_sessions_updated, sessions}, state) do
    session_count = map_size(Map.get(sessions || %{}, :sessions, %{}))
    Logger.info("[SEND] Async signal session update received (sessions=#{session_count})")
    {:noreply, %{state | signal_sessions: sessions}}
  end

  def handle_info({:retry_outgoing_message, jid, message_id}, state) do
    {:noreply, maybe_retry_outgoing_message(state, jid, message_id)}
  end

  def handle_info({:send_result, jid, text, {:ok, message_id}, strategy, attempt}, state) do
    {:noreply, schedule_outbound_confirmation(state, jid, text, message_id, strategy, attempt)}
  end

  def handle_info({:send_result, _jid, _text, {:error, _reason}, _strategy, _attempt}, state) do
    {:noreply, state}
  end

  def handle_info({:outbound_confirm_timeout, message_id}, state) do
    case Map.pop(state.outbound_confirmations, message_id) do
      {nil, _} ->
        {:noreply, state}

      {confirmation, confirmations} ->
        state = %{state | outbound_confirmations: confirmations}
        {:noreply, handle_outbound_confirmation_timeout(state, message_id, confirmation)}
    end
  end

  def handle_info(msg, state) do
    Logger.debug("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Session terminating: #{inspect(reason)}")
    emit_telemetry(:terminate, %{reason: reason}, state)
    do_disconnect(state, reason)
    :ok
  end

  # ============================================================================
  # Connection Management
  # ============================================================================

  defp do_connect(%__MODULE__{status: status} = state)
       when status not in [:idle, :disconnected] do
    Logger.debug("[SESSION] do_connect SKIPPED - status=#{status} not in [:idle, :disconnected]")
    state
  end

  defp do_connect(%__MODULE__{} = state) do
    Logger.debug("[SESSION] do_connect starting connection...")
    Logger.debug("[SESSION] store=#{inspect(state.store)}")
    emit_telemetry(:connect, %{attempt: state.reconnect_attempts}, state)

    case safe_start_connection(state) do
      {:ok, conn_pid} ->
        Logger.debug("[SESSION] ✓ Connection started: #{inspect(conn_pid)}")
        conn_ref = Process.monitor(conn_pid)
        OutboundQueue.set_conn(state.outbound_queue, conn_pid)

        %{state | conn: conn_pid, conn_ref: conn_ref, status: :connecting}
        |> schedule_health_check()

      {:error, reason} ->
        Logger.debug("[SESSION] ✗ Connection FAILED: #{inspect(reason)}")
        Logger.error("Failed to start connection: #{inspect(reason)}")
        emit_telemetry(:error, %{reason: reason, phase: :connect}, state)
        notify_qr(state, {:error, reason})
        schedule_reconnect(state, reason)
    end
  end

  defp safe_start_connection(state) do
    Logger.debug("[SESSION] safe_start_connection calling transport.start_link...")
    noise_opts = Keyword.get(state.opts, :noise, [])

    result =
      state.transport_mod.start_link(session: self(), store: state.store, noise: noise_opts)

    Logger.debug("[SESSION] transport.start_link result: #{inspect(result)}")
    result
  rescue
    e ->
      Logger.debug("[SESSION] ✗ transport.start_link EXCEPTION: #{inspect(e)}")
      {:error, {:exception, e}}
  catch
    :exit, reason ->
      Logger.debug("[SESSION] ✗ transport.start_link EXIT: #{inspect(reason)}")
      {:error, {:exit, reason}}
  end

  defp do_disconnect(%__MODULE__{conn: nil} = state, _reason) do
    OutboundQueue.clear_conn(state.outbound_queue)
    state
  end

  defp do_disconnect(%__MODULE__{conn: conn, conn_ref: ref} = state, reason) do
    if ref, do: Process.demonitor(ref, [:flush])
    state = state |> cancel_health_check() |> clear_pending_requests(reason)
    OutboundQueue.clear_conn(state.outbound_queue)

    # Gracefully stop connection
    try do
      GenServer.stop(conn, :normal, 5_000)
    catch
      :exit, _ -> :ok
    end

    emit_telemetry(:disconnected, %{reason: reason}, state)

    %{
      state
      | conn: nil,
        conn_ref: nil,
        status: :disconnected,
        last_disconnect_reason: reason,
        connected_at: nil
    }
  end

  defp handle_connection_exit(state, reason) do
    OutboundQueue.clear_conn(state.outbound_queue)

    state
    |> clear_pending_requests(reason)
    |> cancel_health_check()
    |> Map.merge(%{
      conn: nil,
      conn_ref: nil,
      status: :disconnected,
      last_disconnect_reason: reason,
      connected_at: nil
    })
    |> update_stats(:reconnects)
    |> then(fn s ->
      emit_telemetry(:disconnected, %{reason: reason}, s)
      notify_qr(s, {:error, {:disconnected, reason}})
      schedule_reconnect(s, reason)
    end)
  end

  # ============================================================================
  # Reconnection with Exponential Backoff
  # ============================================================================

  defp schedule_connect(state, delay_ms) do
    Logger.debug("[SESSION] schedule_connect with delay=#{delay_ms}ms")
    Process.send_after(self(), :connect, delay_ms)
    # Don't change status here - do_connect will set it after successful connection
    state
  end

  defp restart_connection_now(state, reason) do
    state
    |> do_disconnect(reason)
    |> Map.put(:reconnect_attempts, 0)
    |> schedule_connect(0)
  end

  defp schedule_reconnect(state, _reason) do
    case Resilience.reconnect_decision(state) do
      :session_invalid ->
        Logger.warning(
          "[SESSION] Session invalid (401), not reconnecting. Clear session to re-pair."
        )

        notify_qr(state, {:error, :session_invalid})
        %{state | status: :idle}

      {:reconnect, attempt, delay} ->
        Logger.info("Scheduling reconnect attempt #{attempt} in #{delay}ms")
        Process.send_after(self(), {:reconnect, attempt}, delay)

        %{state | status: :disconnected}

      :give_up ->
        Logger.warning("Max reconnect attempts reached, giving up")
        notify_qr(state, {:error, :max_reconnect_attempts})
        %{state | status: :idle}
    end
  end

  # ============================================================================
  # Health Monitoring
  # ============================================================================

  defp schedule_health_check(state) do
    timer = Process.send_after(self(), :health_check, @health_check_interval_ms)
    %{state | health_timer: timer}
  end

  defp cancel_health_check(%{health_timer: nil} = state), do: state

  defp cancel_health_check(%{health_timer: timer} = state) do
    Process.cancel_timer(timer)
    %{state | health_timer: nil}
  end

  defp do_health_check(%{conn: nil} = state), do: state

  defp do_health_check(%{conn: conn} = state) when is_pid(conn) do
    if Process.alive?(conn) do
      schedule_health_check(state)
    else
      Logger.warning("Connection process died unexpectedly")
      handle_connection_exit(state, :process_died)
    end
  end

  # ============================================================================
  # Connection Event Handling
  # ============================================================================

  defp handle_connection_event({:noise, :handshake_started}, state) do
    %{state | status: :handshaking}
  end

  defp handle_connection_event({:transport, :connected}, state) do
    %{state | status: :connecting}
  end

  defp handle_connection_event({:transport, {:closed, reason}}, state) do
    Logger.warning("[SESSION] Transport closed: #{inspect(reason)}")
    handle_connection_exit(state, {:transport_closed, reason})
  end

  defp handle_connection_event({:noise, :handshake_completed}, state) do
    emit_telemetry(:connected, %{}, state)

    %{state | status: :connected, reconnect_attempts: 0, connected_at: DateTime.utc_now()}
  end

  defp handle_connection_event({:connection_message, %Binary.Node{} = node}, state) do
    InboundRouter.route(state.inbound_router, node)
    state
  end

  defp handle_connection_event({:connection_binary, _payload}, state), do: state

  defp handle_connection_event({:error, reason}, state) do
    Logger.warning("Connection error: #{inspect(reason)}")
    emit_telemetry(:error, %{reason: reason}, state)
    notify_qr(state, {:error, reason})
    update_stats(state, :errors)
  end

  defp handle_connection_event(event, state) do
    Logger.debug("Unhandled connection event: #{inspect(event)}")
    state
  end

  # ============================================================================
  # Node Handling with Error Recovery
  # ============================================================================

  defp safe_handle_node(node, state) do
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
    Logger.info("[SESSION] Received success node - login successful!")

    # Persist LID if present (Baileys: CB:success -> creds.update me.lid)
    lid = Map.get(attrs, "lid")
    state = persist_lid_and_mapping(state, lid)

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

    Logger.info(
      "[SESSION] Sending prekey count query (id=#{query_id}) + passive IQ + presence available"
    )

    {state, actions}
  end

  # Handle ib (initialization) node - server sends this after successful login
  # Reference: whatsmeow/connectionevents.go handleIB()
  defp handle_connection_node(%Binary.Node{tag: "ib", content: children}, state) do
    Logger.info("[SESSION] Received ib (initialization) node")

    if is_list(children) do
      Enum.each(children, fn child ->
        case child do
          %Binary.Node{tag: "offline_preview", attrs: attrs} ->
            Logger.info("[SESSION] Offline preview: #{inspect(attrs)}")

          %Binary.Node{tag: "offline", attrs: attrs} ->
            Logger.info("[SESSION] Offline sync completed: #{inspect(attrs)}")

          %Binary.Node{tag: "dirty", attrs: attrs} ->
            Logger.debug("[SESSION] Dirty state: #{inspect(attrs)}")

          other ->
            Logger.debug("[SESSION] IB child: #{inspect(other.tag)}")
        end
      end)
    end

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
        Logger.error("[SESSION] Unauthorized - session invalid, stopping reconnects")
        Logger.error("[SESSION] Please clear session and re-pair")
        notify_qr(state, {:error, :unauthorized})
        # Mark session as invalid to stop reconnection attempts
        {%{state | session_invalid: true, status: :idle}, []}

      "403" ->
        Logger.error("[SESSION] Forbidden - account may be banned")
        notify_qr(state, {:error, :forbidden})
        {%{state | session_invalid: true, status: :idle}, []}

      "405" ->
        Logger.error("[SESSION] Client outdated")
        notify_qr(state, {:error, :client_outdated})
        {state, []}

      _ ->
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
    conflict_type =
      if is_list(children) do
        case Enum.find(children, fn c -> c.tag == "conflict" end) do
          %Binary.Node{attrs: conflict_attrs} -> Map.get(conflict_attrs, "type")
          _ -> nil
        end
      else
        nil
      end

    new_state =
      cond do
        code == "401" ->
          Logger.error("[SESSION] Device was removed (401)! Need to re-pair from scratch.")
          Logger.error("[SESSION] Delete session file and scan QR code again.")
          notify_qr(state, {:error, :device_removed})
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
      &build_receipt_ack/4,
      fn to, id, participant, message_t, retry_count, error_code, retry_meta ->
        build_retry_receipt_ack(
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

  # -- IQ helpers (extracted from handle_connection_node "iq" clause) --

  defp forward_iq_to_workers(state, iq_type, iq_id, node)
       when iq_type in ["result", "error"] and iq_id != nil do
    workers = Map.get(state, :send_workers, %{})

    if map_size(workers) > 0 do
      Logger.debug("[SESSION] Forwarding IQ #{iq_id} to #{map_size(workers)} workers")
      msg_tag = if iq_type == "result", do: :prekey_response, else: :prekey_error

      Enum.each(workers, fn {worker_pid, _jid} ->
        if Process.alive?(worker_pid), do: send(worker_pid, {msg_tag, iq_id, node})
      end)
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

  defp dispatch_iq(state, _node, attrs, "urn:xmpp:ping", "get", _iq_id) do
    Logger.debug("[SESSION] Received ping, sending pong")
    {state, [{:send_node, build_iq_result(attrs)}]}
  end

  defp dispatch_iq(state, node, _attrs, _xmlns, "result", iq_id)
       when state.prekey_count_query_id != nil and iq_id == state.prekey_count_query_id do
    handle_prekey_count_response(node, state)
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

  # --- Helpers for handle_connection_node("success") ---

  defp persist_lid_and_mapping(state, nil), do: state

  defp persist_lid_and_mapping(state, lid) when is_binary(lid) do
    Logger.info("[SESSION] LID from success: #{inspect(lid)}")

    data = Store.load!(state.store)

    # Persist LID in client_info
    client_info = Map.get(data, :client_info, %{})
    client_info = Map.put(client_info, :lid, lid)

    # Create own PN<->LID mapping (Baileys: storeLIDPNMappings)
    own_pn =
      MapPath.first(data, [
        ["pairing", "device", "jid"],
        ["client_info", "jid"]
      ])

    lid_mapping = Map.get(data, :lid_mapping, %{})

    lid_mapping =
      if own_pn do
        pn_normalized = normalize_jid_string(to_string(own_pn))
        lid_normalized = normalize_jid_string(to_string(lid))

        Logger.info(
          "[SESSION] Storing own PN<->LID mapping: #{pn_normalized} <-> #{lid_normalized}"
        )

        lid_mapping
        |> Map.put({:pn_to_lid, pn_normalized}, lid_normalized)
        |> Map.put({:lid_to_pn, lid_normalized}, pn_normalized)
      else
        lid_mapping
      end

    data =
      data
      |> Map.put(:client_info, client_info)
      |> Map.put(:lid_mapping, lid_mapping)

    Store.persist(state.store, data)
    state
  end

  defp persist_lid_and_mapping(state, _), do: state

  # Handle prekey count response from server (Baileys: uploadPreKeysToServerIfRequired)
  defp handle_prekey_count_response(%Binary.Node{content: content}, state) do
    state = %{state | prekey_count_query_id: nil}

    server_count = ExWapp.Prekeys.parse_count_response(content)
    Logger.info("[SESSION] Server prekey count: #{server_count}")

    data = Store.load!(state.store)
    signal = Map.get(data, :signal, %{})
    local_count = signal |> Map.get(:prekeys, %{}) |> map_size()

    # Baileys logic: if server count == 0 -> INITIAL (812), low -> refill (50)
    # For fresh devices, server_count == 0 always needs full initial upload
    cond do
      server_count == 0 ->
        Logger.info(
          "[SESSION] No prekeys on server, uploading initial batch (local=#{local_count})"
        )

        do_prekey_upload(state, initial: true)

      server_count <= @min_prekey_threshold ->
        Logger.info("[SESSION] Server prekeys low (#{server_count}), uploading refill batch")
        do_prekey_upload(state, initial: false)

      true ->
        Logger.info(
          "[SESSION] Prekey count OK (server=#{server_count}, local=#{local_count}), skipping upload"
        )

        {state, []}
    end
  end

  defp do_prekey_upload(state, opts) do
    case ExWapp.Prekeys.build_prekey_upload(state.store, opts) do
      {:ok, prekey_node, prekeys} ->
        persist_uploaded_prekeys(state.store, prekeys)
        initial = Keyword.get(opts, :initial, false)
        Logger.info("[SESSION] Uploading prekeys (initial=#{initial}, count=#{length(prekeys)})")
        {state, [{:send_node, prekey_node}]}

      {:error, reason} ->
        Logger.warning("[SESSION] Cannot upload prekeys: #{inspect(reason)}")
        {state, []}
    end
  end

  defp normalize_jid_string(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
  end

  defp normalize_jid_string(_), do: ""

  defp persist_uploaded_prekeys(store, prekeys) when is_list(prekeys) do
    data = Store.load!(store)
    signal = Map.get(data, :signal, %{})
    existing_prekeys = Map.get(signal, :prekeys, %{})

    merged_prekeys =
      Enum.reduce(prekeys, existing_prekeys, fn
        %{key_id: id, public: pub, private: priv}, acc ->
          Map.put(acc, id, %{id: id, public: pub, private: priv})

        _, acc ->
          acc
      end)

    next_prekey_id =
      prekeys
      |> Enum.map(&Map.get(&1, :key_id))
      |> Enum.filter(&is_integer/1)
      |> case do
        [] -> Map.get(signal, :next_prekey_id, 1)
        ids -> Enum.max(ids) + 1
      end

    updated_signal =
      signal
      |> Map.put(:prekeys, merged_prekeys)
      |> Map.put(:next_prekey_id, next_prekey_id)

    Store.persist(store, Map.put(data, :signal, updated_signal))
    :ok
  rescue
    error ->
      Logger.warning("[SESSION] Failed to persist uploaded prekeys: #{inspect(error)}")
      :ok
  end

  # --- End helpers for handle_connection_node("success") ---

  defp build_receipt_ack(to, id, participant, type) do
    attrs = %{
      "id" => id,
      "to" => to
    }

    # Only add type if non-nil (peer category messages omit it)
    attrs = if type, do: Map.put(attrs, "type", type), else: attrs
    attrs = if participant, do: Map.put(attrs, "participant", participant), else: attrs

    %Binary.Node{
      tag: "receipt",
      attrs: attrs,
      content: nil
    }
  end

  defp build_retry_receipt_ack(
         store,
         to,
         id,
         participant,
         message_t,
         retry_count,
         error_code,
         retry_meta
       ) do
    attrs = %{
      "id" => id,
      "to" => to,
      "type" => "retry"
    }

    attrs = if participant, do: Map.put(attrs, "participant", participant), else: attrs
    attrs = maybe_put_retry_recipient(attrs, retry_meta)
    attrs = maybe_put_retry_category(attrs, retry_meta)

    retry_attrs =
      %{
        "v" => "1",
        "id" => id,
        "t" => retry_timestamp(message_t),
        "count" => Integer.to_string(max(retry_count || 1, 1))
      }
      |> maybe_put_retry_error(error_code)

    retry_node = %Binary.Node{
      tag: "retry",
      attrs: retry_attrs,
      content: nil
    }

    content =
      case local_registration_node(store) do
        nil -> [retry_node]
        registration_node -> [retry_node, registration_node]
      end

    content =
      if retry_keys_needed?(retry_count) do
        case local_retry_keys_node(store) do
          {:ok, keys_node} ->
            content ++ [keys_node]

          {:error, reason} ->
            Logger.warning("[SESSION] Retry keys unavailable: #{inspect(reason)}")
            content
        end
      else
        content
      end

    %Binary.Node{
      tag: "receipt",
      attrs: attrs,
      content: content
    }
  end

  defp maybe_put_retry_error(attrs, error_code) when is_integer(error_code) and error_code >= 0 do
    Map.put(attrs, "error", Integer.to_string(error_code))
  end

  defp maybe_put_retry_error(attrs, _), do: attrs

  defp maybe_put_retry_recipient(attrs, %{recipient: recipient})
       when is_binary(recipient) and recipient != "" do
    Map.put(attrs, "recipient", recipient)
  end

  defp maybe_put_retry_recipient(attrs, _), do: attrs

  defp maybe_put_retry_category(attrs, %{category: category})
       when is_binary(category) and category != "" do
    Map.put(attrs, "category", category)
  end

  defp maybe_put_retry_category(attrs, _), do: attrs

  defp retry_timestamp(message_t) when is_binary(message_t) and message_t != "", do: message_t
  defp retry_timestamp(message_t) when is_integer(message_t), do: Integer.to_string(message_t)
  defp retry_timestamp(_), do: Integer.to_string(System.system_time(:second))

  defp retry_keys_needed?(retry_count) when is_integer(retry_count), do: retry_count >= 2
  defp retry_keys_needed?(_), do: false

  defp local_retry_keys_node(nil), do: {:error, :missing_store}

  defp local_retry_keys_node(store) do
    data = Store.load!(store)
    signal = Map.get(data, :signal, %{})

    with {:ok, identity_pub} <- local_identity_public(signal),
         {:ok, signed_prekey} <- local_signed_prekey(signal),
         {:ok, prekey_id, prekey_public} <- generate_retry_prekey(store, data, signal),
         {:ok, device_identity_node} <- Account.get_device_identity_node(store),
         %Binary.Node{content: %Binary.Raw{data: device_identity_payload}} <- device_identity_node do
      type_node = %Binary.Node{tag: "type", attrs: %{}, content: Binary.raw(<<5>>)}
      identity_node = %Binary.Node{tag: "identity", attrs: %{}, content: Binary.raw(identity_pub)}
      prekey_node = prekey_to_node(prekey_id, prekey_public)
      signed_prekey_node = signed_prekey_to_node(signed_prekey)

      keys_content = [
        type_node,
        identity_node,
        prekey_node,
        signed_prekey_node,
        %Binary.Node{
          tag: "device-identity",
          attrs: %{},
          content: Binary.raw(device_identity_payload)
        }
      ]

      {:ok, %Binary.Node{tag: "keys", attrs: %{}, content: keys_content}}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :invalid_device_identity}
    end
  rescue
    error -> {:error, {:retry_keys_build_failed, error}}
  end

  defp local_identity_public(%{identity_key: %{public: pub}})
       when is_binary(pub) and byte_size(pub) == 32 do
    {:ok, pub}
  end

  defp local_identity_public(_), do: {:error, :missing_identity_public}

  defp local_signed_prekey(%{signed_prekeys: signed})
       when is_map(signed) and map_size(signed) > 0 do
    signed
    |> Enum.find(fn
      {id, %{public: pub, signature: sig}}
      when is_integer(id) and is_binary(pub) and byte_size(pub) == 32 and is_binary(sig) and
             byte_size(sig) == 64 ->
        true

      _ ->
        false
    end)
    |> case do
      {id, prekey} -> {:ok, Map.put(prekey, :id, id)}
      nil -> {:error, :missing_signed_prekey}
    end
  end

  defp local_signed_prekey(_), do: {:error, :missing_signed_prekey}

  defp generate_retry_prekey(store, data, signal) do
    next_id =
      cond do
        is_integer(signal[:next_prekey_id]) and signal[:next_prekey_id] > 0 ->
          signal[:next_prekey_id]

        is_map(signal[:prekeys]) and map_size(signal[:prekeys]) > 0 ->
          signal[:prekeys] |> Map.keys() |> Enum.max() |> Kernel.+(1)

        true ->
          1
      end

    prekey = ExWapp.Signal.Keys.generate_prekey(next_id)
    prekeys = Map.get(signal, :prekeys, %{}) |> Map.put(next_id, prekey)

    updated_signal =
      signal
      |> Map.put(:prekeys, prekeys)
      |> Map.put(:next_prekey_id, next_id + 1)
      |> Map.put(:updated_at, System.system_time(:second))

    :ok = Store.persist(store, Map.put(data, :signal, updated_signal))

    {:ok, next_id, prekey.public}
  end

  defp prekey_to_node(id, public), do: Account.prekey_to_node(id, public)

  defp signed_prekey_to_node(signed_prekey), do: Account.signed_prekey_to_node(signed_prekey)

  defp local_registration_node(store), do: Account.local_registration_node(store)

  # ============================================================================
  # Action Handling with Error Recovery
  # ============================================================================

  defp safe_handle_action(action, state) do
    handle_pairing_action(action, state)
  rescue
    e ->
      Logger.error("Error handling action #{inspect(action)}: #{inspect(e)}")
  catch
    :exit, reason ->
      Logger.error("Exit handling action #{inspect(action)}: #{inspect(reason)}")
  end

  defp handle_pairing_action({:send_node, node}, %__MODULE__{outbound_queue: outbound_queue})
       when is_pid(outbound_queue) do
    OutboundQueue.enqueue_node(outbound_queue, node)
  end

  defp handle_pairing_action({:qr, code}, state), do: notify_qr(state, {:code, code})
  defp handle_pairing_action({:status, :success}, state), do: notify_qr(state, :success)
  defp handle_pairing_action({:error, reason}, state), do: notify_qr(state, {:error, reason})

  defp handle_pairing_action(:restart_stream, %__MODULE__{outbound_queue: outbound_queue})
       when is_pid(outbound_queue) do
    OutboundQueue.restart_stream(outbound_queue)
  end

  defp handle_pairing_action({:retry_outgoing_message, jid, message_id}, _state) do
    send(self(), {:retry_outgoing_message, jid, message_id})
  end

  defp handle_pairing_action(_action, _state), do: :ok

  defp maybe_retry_outgoing_message(state, jid, message_id) do
    session_pid = self()

    Retry.maybe_retry_outgoing_message(state, jid, message_id,
      max_attempts: @max_outgoing_retry_attempts,
      normalize_jid: &JIDUtils.normalize_for_signal/1,
      start_worker: &start_send_worker/3,
      send_fun: fn normalized_jid, text ->
        do_send_text_worker(session_pid, state, normalized_jid, text)
      end
    )
  end

  # ============================================================================
  # Message Sending
  # ============================================================================

  # Worker function - runs in a separate process so it can wait for IQ responses
  defp do_send_text_worker(session_pid, state, jid, text, opts \\ []) do
    Outbound.send_text_worker(session_pid, state, jid, text, opts)
  end

  defp schedule_outbound_confirmation(state, jid, text, message_id, _strategy, attempt) do
    if watch_self_chat_confirmation?(state.store, jid, attempt) do
      timer =
        Process.send_after(
          self(),
          {:outbound_confirm_timeout, message_id},
          @silent_drop_confirm_timeout_ms
        )

      confirmation = %{
        jid: JIDUtils.normalize_for_signal(jid),
        text: IO.iodata_to_binary(text),
        attempt: attempt,
        timer: timer
      }

      confirmations = Map.put(state.outbound_confirmations, message_id, confirmation)
      %{state | outbound_confirmations: confirmations}
    else
      state
    end
  end

  defp handle_outbound_confirmation_timeout(
         state,
         message_id,
         %{jid: jid, text: text, attempt: attempt}
       ) do
    case outbound_message_status(state.store, jid, message_id) do
      status when status in [:delivered, :read, :received] ->
        Logger.info("[SEND] Outbound confirmed id=#{message_id} status=#{status}")
        state

      :failed ->
        state

      _other ->
        if attempt < @max_silent_drop_fallback_attempts do
          Logger.warning(
            "[SEND] Message id=#{message_id} to=#{jid} remained unconfirmed after #{@silent_drop_confirm_timeout_ms}ms; retrying with fallback self-chat strategy"
          )

          mark_message_failed(state.store, message_id)
          start_silent_drop_fallback_worker(state, jid, text, attempt + 1, message_id)
        else
          Logger.error(
            "[SEND] Message id=#{message_id} to=#{jid} still unconfirmed after fallback; marking as failed"
          )

          mark_message_failed(state.store, message_id)
          state
        end
    end
  end

  defp start_silent_drop_fallback_worker(state, jid, text, attempt, previous_message_id) do
    session_pid = self()

    case start_send_worker(state, jid, fn ->
           result =
             do_send_text_worker(session_pid, state, jid, text,
               self_chat_mode: :recipient_primary
             )

           send(session_pid, {:send_result, jid, text, result, :fallback, attempt})

           case result do
             {:ok, new_id} ->
               Logger.warning(
                 "[SEND] Fallback resend for #{jid} previous_id=#{previous_message_id} new_id=#{new_id}"
               )

             {:error, reason} ->
               Logger.warning(
                 "[SEND] Fallback resend failed for #{jid} previous_id=#{previous_message_id}: #{inspect(reason)}"
               )
           end

           result
         end) do
      {:ok, worker, mon} ->
        register_send_worker(state, worker, mon, jid)

      {:error, reason} ->
        Logger.warning("[SEND] Failed to start fallback worker for #{jid}: #{inspect(reason)}")
        state
    end
  end

  defp watch_self_chat_confirmation?(nil, _jid, _attempt), do: false

  defp watch_self_chat_confirmation?(store, jid, attempt)
       when is_integer(attempt) and attempt <= @max_silent_drop_fallback_attempts do
    own_base_jid = Account.local_account_base_jid(store)
    own_lid_jid = Account.local_account_lid_jid(store)

    own_user_parts =
      [own_base_jid, own_lid_jid]
      |> Enum.map(&jid_user_part/1)
      |> Enum.reject(&(&1 == ""))
      |> MapSet.new()

    dest_user = jid_user_part(jid)
    dest_user != "" and MapSet.member?(own_user_parts, dest_user)
  end

  defp watch_self_chat_confirmation?(_store, _jid, _attempt), do: false

  defp outbound_message_status(nil, _jid, _message_id), do: :unknown

  defp outbound_message_status(store, jid, message_id) do
    with nil <- find_outgoing_message_in_chat(store, jid, message_id),
         nil <- find_outgoing_message_in_chat(store, strip_device_from_jid(jid), message_id),
         nil <- find_outgoing_message_any_chat(store, message_id) do
      :unknown
    else
      %{status: status} when is_atom(status) -> status
      _ -> :unknown
    end
  end

  defp find_outgoing_message_in_chat(store, jid, message_id)
       when is_binary(jid) and jid != "" and is_binary(message_id) do
    store
    |> Chat.messages(jid, limit: 1000)
    |> Enum.find(fn message ->
      Map.get(message, :id) == message_id and Map.get(message, :from_me) == true
    end)
  end

  defp find_outgoing_message_in_chat(_store, _jid, _message_id), do: nil

  defp find_outgoing_message_any_chat(store, message_id) when is_binary(message_id) do
    store
    |> Chat.list()
    |> Enum.find_value(fn chat ->
      Enum.find(chat.messages, fn message ->
        Map.get(message, :id) == message_id and Map.get(message, :from_me) == true
      end)
    end)
  end

  defp find_outgoing_message_any_chat(_store, _message_id), do: nil

  defp mark_message_failed(nil, _message_id), do: :ok

  defp mark_message_failed(store, message_id) when is_binary(message_id) do
    Chat.update_message_status_by_id(store, message_id, :failed)
  end

  defp mark_message_failed(_store, _message_id), do: :ok

  defp jid_user_part(jid) when is_binary(jid) do
    jid
    |> JIDUtils.normalize_for_signal()
    |> String.split("@", parts: 2)
    |> case do
      [user, _server] -> Regex.replace(~r/:\d+$/, user, "")
      _ -> ""
    end
  end

  defp jid_user_part(_), do: ""

  defp strip_device_from_jid(jid) when is_binary(jid) do
    String.replace(jid, ~r/:(\d+)@/, "@")
  end

  defp strip_device_from_jid(_), do: ""

  defp register_send_worker(state, worker, mon, jid) do
    state
    |> Map.update(:send_workers, %{worker => jid}, fn workers ->
      Map.put(workers, worker, jid)
    end)
    |> Map.update(:send_worker_mons, %{mon => worker}, fn mons ->
      Map.put(mons, mon, worker)
    end)
  end

  # ============================================================================
  # QR Subscriber Management
  # ============================================================================

  defp notify_qr(state, event) do
    Subscribers.notify_qr(state, event, fn ->
      emit_telemetry(
        :qr,
        %{subscriber_count: map_size(state.qr_subscribers)},
        state,
        %{event: qr_event_kind(event)}
      )
    end)
  end

  defp remove_qr_subscriber(state, ref), do: Subscribers.remove_qr_subscriber(state, ref)

  defp cleanup_dead_subscriber(state, dead_mon),
    do: Subscribers.cleanup_dead_subscriber(state, dead_mon)

  # ============================================================================
  # Message Subscriber Management
  # ============================================================================

  defp notify_message_subscribers(state, jid, message),
    do: Subscribers.notify_message_subscribers(state, jid, message)

  defp remove_message_subscriber(state, ref),
    do: Subscribers.remove_message_subscriber(state, ref)

  # ============================================================================
  # Helpers
  # ============================================================================

  defp restart_outbound_queue(state) do
    {:ok, outbound_queue} =
      OutboundQueue.start_link(session: self(), transport: state.transport_mod)

    maybe_set_conn(outbound_queue, state.conn)
    %{state | outbound_queue: outbound_queue}
  end

  defp restart_inbound_router(state) do
    {:ok, inbound_router} = InboundRouter.start_link(session: self())
    %{state | inbound_router: inbound_router}
  end

  defp maybe_set_conn(_outbound_queue, nil), do: :ok

  defp maybe_set_conn(outbound_queue, conn) when is_pid(conn),
    do: OutboundQueue.set_conn(outbound_queue, conn)

  defp start_send_worker(state, jid, fun) do
    start_send_worker(state, jid, fun, nil)
  end

  defp start_send_worker(%__MODULE__{send_worker_sup: sup}, jid, fun, from)
       when is_pid(sup) and is_function(fun, 0) do
    case Task.Supervisor.start_child(sup, fn ->
           result = fun.()
           if from, do: GenServer.reply(from, result)
         end) do
      {:ok, worker} ->
        mon = Process.monitor(worker)
        {:ok, worker, mon}

      {:error, reason} ->
        Logger.warning("[SEND] Failed to start worker for #{jid}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp start_send_worker(_state, jid, _fun, _from) do
    {:error, {:missing_send_worker_supervisor, jid}}
  end

  defp cleanup_dead_send_worker(%__MODULE__{send_workers: workers} = state, mon)
       when is_reference(mon) do
    case Map.pop(state.send_worker_mons, mon) do
      {nil, mons} ->
        %{state | send_worker_mons: mons}

      {pid, mons} ->
        %{state | send_workers: Map.delete(workers, pid), send_worker_mons: mons}
    end
  end

  defp cleanup_dead_send_worker(state, _mon), do: state

  defp maybe_reset_pairing(actions, pairing) do
    if Enum.any?(actions, &match?({:status, :success}, &1)) do
      {:ok, Pairing.new(pairing.store)}
    else
      :noop
    end
  end

  defp clear_pending_requests(state, reason) do
    Enum.each(state.pending_iqs, fn {_message_id, pending} ->
      timer = Map.get(pending, :timer)
      if timer, do: Process.cancel_timer(timer)

      case Map.get(pending, :from) do
        nil -> :ok
        from -> GenServer.reply(from, {:error, {:disconnected, reason}})
      end
    end)

    Enum.each(state.send_workers, fn {pid, _jid} ->
      if Process.alive?(pid) do
        send(pid, {:prekey_error, :transport_closed, reason})
      end
    end)

    Enum.each(state.outbound_confirmations, fn {_message_id, confirmation} ->
      case Map.get(confirmation, :timer) do
        timer when is_reference(timer) -> Process.cancel_timer(timer)
        _ -> :ok
      end
    end)

    %{
      state
      | pending_iqs: %{},
        send_workers: %{},
        send_worker_mons: %{},
        outbound_confirmations: %{}
    }
  end

  defp update_stats(state, key) do
    update_in(state.stats[key], &((&1 || 0) + 1))
  end

  defp calculate_uptime(%{connected_at: nil}), do: 0

  defp calculate_uptime(%{connected_at: connected_at}) do
    DateTime.diff(DateTime.utc_now(), connected_at, :second)
  end

  defp emit_telemetry(event, measurements, state, extra_metadata \\ %{}) do
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
    # Don't crash if telemetry fails
    _ -> :ok
  end

  defp qr_event_kind({:code, _}), do: :code
  defp qr_event_kind(:success), do: :success
  defp qr_event_kind({:error, _}), do: :error
end
