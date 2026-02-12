defmodule ExWapp.Session do
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

  alias ExWapp.{Binary, Pairing, Store, Telemetry}
  alias ExWapp.Session.{InboundRouter, OutboundQueue}

  # Reconnection configuration
  @initial_backoff_ms 1_000
  @max_backoff_ms 300_000
  @backoff_multiplier 2
  @health_check_interval_ms 30_000
  @min_prekey_threshold 5
  @max_outgoing_retry_attempts 2

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
    :session_id,
    :health_timer,
    status: :idle,
    qr_subscribers: %{},
    message_subscribers: %{},
    send_workers: %{},
    opts: [],
    reconnect_attempts: 0,
    last_disconnect_reason: nil,
    connected_at: nil,
    session_invalid: false,
    pending_iqs: %{},
    signal_sessions: nil,
    retry_counters: %{},
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
          session_id: term() | nil,
          health_timer: reference() | nil,
          qr_subscribers: %{reference() => {pid(), reference()}},
          message_subscribers: %{reference() => {pid(), reference()}},
          send_workers: %{pid() => binary()},
          opts: keyword(),
          pairing: Pairing.state(),
          reconnect_attempts: non_neg_integer(),
          last_disconnect_reason: term() | nil,
          connected_at: DateTime.t() | nil,
          retry_counters: map(),
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

    state = %__MODULE__{
      opts: opts,
      store: store,
      transport_mod: transport_mod,
      outbound_queue: outbound_queue,
      inbound_router: inbound_router,
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

    worker =
      spawn_link(fn ->
        result = do_send_text_worker(session_pid, state, jid, text)
        GenServer.reply(from, result)
      end)

    # Store the worker so we can forward IQ responses to it
    new_state = Map.update(state, :send_workers, %{worker => jid}, &Map.put(&1, worker, jid))
    {:noreply, update_stats(new_state, :messages_sent)}
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

  def handle_info({:EXIT, pid, _reason}, %__MODULE__{send_workers: workers} = state) do
    {:noreply, %{state | send_workers: Map.delete(workers, pid)}}
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
    new_state = cleanup_dead_subscriber(state, mon)
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
    cond do
      state.session_invalid ->
        Logger.warning(
          "[SESSION] Session invalid (401), not reconnecting. Clear session to re-pair."
        )

        notify_qr(state, {:error, :session_invalid})
        %{state | status: :idle}

      should_reconnect?(state) ->
        attempt = state.reconnect_attempts + 1
        delay = calculate_backoff(attempt)

        Logger.info("Scheduling reconnect attempt #{attempt} in #{delay}ms")
        Process.send_after(self(), {:reconnect, attempt}, delay)

        %{state | status: :disconnected}

      true ->
        Logger.warning("Max reconnect attempts reached, giving up")
        notify_qr(state, {:error, :max_reconnect_attempts})
        %{state | status: :idle}
    end
  end

  defp should_reconnect?(state) do
    not state.session_invalid and reconnect_enabled?(state) and under_max_attempts?(state)
  end

  defp reconnect_enabled?(state) do
    Keyword.get(state.opts, :reconnect, true)
  end

  defp under_max_attempts?(_state), do: true

  defp calculate_backoff(attempt) do
    delay = @initial_backoff_ms * :math.pow(@backoff_multiplier, attempt - 1)
    jitter = :rand.uniform(1000)
    min(trunc(delay) + jitter, @max_backoff_ms)
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

    # Check if this is a prekey response - forward to any waiting workers
    state =
      if iq_type in ["result", "error"] and iq_id do
        workers = Map.get(state, :send_workers, %{})

        if map_size(workers) > 0 do
          Logger.info("[SESSION] Forwarding IQ #{iq_id} to #{map_size(workers)} workers")
          # Forward to all workers (they'll match on message_id)
          Enum.each(workers, fn {worker_pid, _jid} ->
            if Process.alive?(worker_pid) do
              if iq_type == "result" do
                send(worker_pid, {:prekey_response, iq_id, node})
              else
                send(worker_pid, {:prekey_error, iq_id, node})
              end
            end
          end)
        end

        state
      else
        state
      end

    # Check if this is a response to a pending IQ request
    {state, pending_handled} =
      if iq_type in ["result", "error"] and iq_id do
        case Map.pop(state.pending_iqs, iq_id) do
          {nil, _} ->
            {state, false}

          {%{from: from, timer: timer}, pending_iqs} ->
            Process.cancel_timer(timer)

            if iq_type == "result" do
              GenServer.reply(from, {:ok, node})
            else
              GenServer.reply(from, {:error, node})
            end

            {%{state | pending_iqs: pending_iqs}, true}
        end
      else
        {state, false}
      end

    # If we handled it as a pending IQ, we're done
    if pending_handled do
      {state, []}
    else
      cond do
        # Handle ping requests - respond with pong
        xmlns == "urn:xmpp:ping" and iq_type == "get" ->
          Logger.debug("[SESSION] Received ping, sending pong")
          pong = build_iq_result(attrs)
          {state, [{:send_node, pong}]}

        # Handle prekey count response (from count-driven upload flow)
        state.prekey_count_query_id != nil and iq_id == state.prekey_count_query_id and
            iq_type == "result" ->
          handle_prekey_count_response(node, state)

        # Handle other IQ types through pairing
        true ->
          {pairing, actions} = Pairing.apply_node(state.pairing, node)

          pairing =
            case maybe_reset_pairing(actions, pairing) do
              {:ok, new_pairing} -> new_pairing
              :noop -> pairing
            end

          # If pairing didn't produce actions AND this is a get/set IQ,
          # we MUST respond with a result to prevent server timeout
          actions =
            if actions == [] and iq_type in ["get", "set"] do
              Logger.info(
                "[SESSION] Auto-responding to unhandled IQ: xmlns=#{xmlns} type=#{iq_type} id=#{iq_id}"
              )

              [{:send_node, build_iq_result(attrs)}]
            else
              actions
            end

          {%{state | pairing: pairing}, actions}
      end
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
        code == "401" or (code == "401" and conflict_type == "device_removed") ->
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
    case ExWapp.MessageHandler.handle_node(node, self(), state) do
      {:ok, new_state} ->
        {new_state, []}

      {:ok, new_state, actions} ->
        # Convert MessageHandler actions to our action format
        converted_actions =
          Enum.map(actions, fn
            {:send_receipt, to, id, participant, type} ->
              {:send_node, build_receipt_ack(to, id, participant, type)}

            {:send_retry_receipt, to, id, participant, message_t, retry_count, error_code,
             retry_meta} ->
              {:send_node,
               build_retry_receipt_ack(
                 state.store,
                 to,
                 id,
                 participant,
                 message_t,
                 retry_count,
                 error_code,
                 retry_meta
               )}

            other ->
              other
          end)

        {new_state, converted_actions}
    end
  end

  defp handle_connection_node(node, state) do
    Logger.debug("Unhandled node: #{inspect(node.tag)}")
    {update_stats(state, :messages_received), []}
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
      get_in(data, [:pairing, :device, "jid"]) ||
        get_in(data, [:pairing, :device, :jid]) ||
        get_in(data, [:client_info, :jid])

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
         {:ok, device_identity_node} <- get_device_identity_node(store),
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

  defp prekey_to_node(id, public)
       when is_integer(id) and is_binary(public) and byte_size(public) == 32 do
    <<_::8, id3::binary-3>> = <<id::big-32>>

    %Binary.Node{
      tag: "key",
      attrs: %{},
      content: [
        %Binary.Node{tag: "id", attrs: %{}, content: Binary.raw(id3)},
        %Binary.Node{tag: "value", attrs: %{}, content: Binary.raw(public)}
      ]
    }
  end

  defp signed_prekey_to_node(%{id: id, public: public, signature: signature})
       when is_integer(id) and is_binary(public) and byte_size(public) == 32 and
              is_binary(signature) and byte_size(signature) == 64 do
    <<_::8, id3::binary-3>> = <<id::big-32>>

    %Binary.Node{
      tag: "skey",
      attrs: %{},
      content: [
        %Binary.Node{tag: "id", attrs: %{}, content: Binary.raw(id3)},
        %Binary.Node{tag: "value", attrs: %{}, content: Binary.raw(public)},
        %Binary.Node{tag: "signature", attrs: %{}, content: Binary.raw(signature)}
      ]
    }
  end

  defp local_registration_node(nil), do: nil

  defp local_registration_node(store) do
    data = Store.load!(store)

    registration_id =
      get_in(data, [:signal, :registration_id]) ||
        get_in(data, [:pairing, :signal, :registration_id])

    if is_integer(registration_id) and registration_id >= 0 and registration_id <= 0xFFFFFFFF do
      %Binary.Node{
        tag: "registration",
        attrs: %{},
        content: Binary.raw(<<registration_id::32>>)
      }
    else
      nil
    end
  rescue
    _ -> nil
  end

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
    normalized_jid = normalize_jid_for_signal(jid)
    counter_key = outbound_retry_counter_key(normalized_jid, message_id)
    attempts = Map.get(state.retry_counters, counter_key, 0)

    cond do
      attempts >= @max_outgoing_retry_attempts ->
        Logger.warning(
          "[SEND] Skipping retry for message id=#{message_id} to=#{normalized_jid}: max attempts reached"
        )

        state

      true ->
        case find_outgoing_message_text(state.store, normalized_jid, message_id) do
          {:ok, text} ->
            Logger.warning(
              "[SEND] Retrying outbound message id=#{message_id} to=#{normalized_jid} (attempt #{attempts + 1}/#{@max_outgoing_retry_attempts})"
            )

            session_pid = self()

            worker =
              spawn_link(fn ->
                result = do_send_text_worker(session_pid, state, normalized_jid, text)

                case result do
                  {:ok, new_id} ->
                    Logger.info(
                      "[SEND] Retry for message id=#{message_id} succeeded with new id=#{new_id}"
                    )

                  {:error, reason} ->
                    Logger.warning(
                      "[SEND] Retry for message id=#{message_id} failed: #{inspect(reason)}"
                    )
                end
              end)

            retry_counters = Map.put(state.retry_counters, counter_key, attempts + 1)
            send_workers = Map.put(state.send_workers, worker, normalized_jid)

            %{state | retry_counters: retry_counters, send_workers: send_workers}

          {:error, reason} ->
            Logger.warning(
              "[SEND] Cannot retry message id=#{message_id} for #{normalized_jid}: #{inspect(reason)}"
            )

            state
        end
    end
  end

  defp outbound_retry_counter_key(jid, message_id) do
    "outbound_retry|#{jid}|#{message_id}"
  end

  defp find_outgoing_message_text(nil, _jid, _message_id), do: {:error, :missing_store}

  defp find_outgoing_message_text(store, jid, message_id) do
    case find_outgoing_message_text_in_chat(store, jid, message_id) do
      {:ok, _text} = ok ->
        ok

      {:error, _} ->
        find_outgoing_message_text_any_chat(store, message_id)
    end
  rescue
    error ->
      {:error, {:lookup_failed, error}}
  end

  defp find_outgoing_message_text_in_chat(store, jid, message_id) do
    store
    |> ExWapp.Chat.messages(jid, limit: 500)
    |> Enum.find_value(fn message ->
      if Map.get(message, :id) == message_id and Map.get(message, :from_me) and
           is_binary(Map.get(message, :text)) do
        {:ok, Map.get(message, :text)}
      else
        nil
      end
    end)
    |> case do
      nil -> {:error, :message_not_found}
      {:ok, _text} = result -> result
    end
  end

  defp find_outgoing_message_text_any_chat(store, message_id) do
    store
    |> ExWapp.Chat.list()
    |> Enum.find_value(fn chat ->
      chat.messages
      |> Enum.find_value(fn message ->
        if Map.get(message, :id) == message_id and Map.get(message, :from_me) and
             is_binary(Map.get(message, :text)) do
          {:ok, Map.get(message, :text)}
        else
          nil
        end
      end)
    end)
    |> case do
      nil -> {:error, :message_not_found}
      {:ok, _text} = result -> result
    end
  end

  # ============================================================================
  # Message Sending
  # ============================================================================

  # Worker function - runs in a separate process so it can wait for IQ responses
  defp do_send_text_worker(session_pid, state, jid, text) do
    normalized_jid = normalize_jid_with_device(jid)

    if ExWapp.JID.is_group?(normalized_jid) do
      do_send_group_worker(session_pid, state, normalized_jid, text)
    else
      jid = normalize_jid_for_signal(normalized_jid)

      case ensure_signal_session_worker(state, jid) do
        {:ok, updated_sessions, prekey_bundles, target_hints} ->
          # Now send with encryption
          do_send_encrypted(
            session_pid,
            state,
            updated_sessions,
            jid,
            text,
            prekey_bundles,
            target_hints
          )

        {:error, reason} ->
          {:error, {:session_failed, reason}}
      end
    end
  end

  defp do_send_group_worker(
         session_pid,
         %{conn: conn, store: store} = state,
         group_jid,
         text
       )
       when is_pid(conn) do
    group_jid = strip_device_from_jid(normalize_jid_with_device(group_jid))
    message_id = ExWapp.Messages.generate_id()
    timestamp = System.system_time(:second)

    with {:ok, group_info} <- query_group_info_worker(state, group_jid),
         {:ok, updated_sessions, prekey_bundles, distribution_targets} <-
           ensure_group_sender_key_sessions_worker(state, group_jid, group_info.participants),
         proto <- ExWapp.Messages.build_text_proto(text, []),
         {:ok, payload} <- ExWapp.Proto.Message.encode(proto),
         {:ok, distribution_payload, skmsg_payload} <-
           build_group_sender_key_payloads(store, group_jid, payload),
         distribution_target_specs <-
           Enum.map(distribution_targets, &%{jid: &1, payload_kind: :recipient}),
         {:ok, participant_nodes, persisted_sessions, include_identity} <-
           encrypt_for_targets(
             store,
             updated_sessions,
             distribution_target_specs,
             %{recipient: distribution_payload},
             prekey_bundles || %{}
           ) do
      persist_signal_sessions(session_pid, persisted_sessions)

      pending_message = %{
        id: message_id,
        from_me: true,
        timestamp: timestamp,
        text: text,
        status: :pending,
        participant: nil,
        raw: nil
      }

      ExWapp.Chat.add_message(store, group_jid, pending_message)

      node =
        build_group_encrypted_message_node(
          group_jid,
          message_id,
          participant_nodes,
          skmsg_payload,
          group_info.addressing_mode,
          store,
          include_identity
        )

      case send_transport_node(state, conn, node) do
        :ok ->
          Logger.info(
            "[SEND] Sent group encrypted message to #{group_jid} (distribution_targets=#{length(participant_nodes)})"
          )

          emit_telemetry(
            :message_sent,
            %{message_count: 1, payload_bytes: byte_size(payload)},
            state,
            %{jid: group_jid, message_id: message_id, encryption: :group_sender_key}
          )

          {:ok, message_id}

        error ->
          ExWapp.Chat.update_message_status(store, group_jid, message_id, :failed)
          error
      end
    else
      {:error, reason} ->
        Logger.error("[SEND] Group send failed for #{group_jid}: #{inspect(reason)}")
        {:error, {:group_send_failed, reason}}
    end
  end

  defp do_send_group_worker(_session_pid, %{status: status}, _group_jid, _text),
    do: {:error, {:not_connected, status}}

  defp build_group_sender_key_payloads(store, group_jid, message_payload) do
    padded_group_payload = ExWapp.Signal.Encryption.pad_message(message_payload)
    sender_identity = local_account_sender_key_jid(store)

    with true <- sender_identity != "" or {:error, :missing_sender_identity},
         {:ok, distribution_payload} <-
           ExWapp.Signal.SenderKey.create_outbound_distribution_message(
             store,
             group_jid,
             sender_identity
           ),
         {:ok, skmsg_payload} <-
           ExWapp.Signal.SenderKey.encrypt_outbound_group_message(
             store,
             group_jid,
             sender_identity,
             padded_group_payload
           ) do
      {:ok, ExWapp.Signal.Encryption.pad_message(distribution_payload), skmsg_payload}
    else
      false -> {:error, :missing_sender_identity}
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_group_sender_key_sessions_worker(state, group_jid, participant_jids) do
    signal_sessions = state.signal_sessions || ExWapp.Signal.SessionStore.new()
    own_base_jid = local_account_base_jid(state.store)
    own_lid_jid = local_account_lid_jid(state.store)
    own_device_id = local_account_device_id(state.store)

    query_jids =
      (participant_jids ++ [own_base_jid, own_lid_jid])
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.map(&strip_device_from_jid/1)
      |> Enum.uniq()

    device_map =
      case query_device_list_worker(state, query_jids) do
        {:ok, map} ->
          Logger.info("[SEND] Group usync device map for #{group_jid}: #{inspect(map)}")
          map

        {:error, reason} ->
          Logger.warning("[SEND] Group usync query failed for #{group_jid}: #{inspect(reason)}")

          %{}
      end

    distribution_targets =
      query_jids
      |> Enum.flat_map(fn participant ->
        base_participant = strip_device_from_jid(participant)

        case Map.get(device_map, base_participant, []) do
          [] -> [base_participant]
          devices -> devices
        end
      end)
      |> normalize_target_list()
      |> Enum.reject(
        &group_current_device_target?(&1, own_device_id, [own_base_jid, own_lid_jid])
      )
      |> Enum.uniq()

    Logger.info(
      "[SEND] Group sender-key distribution targets for #{group_jid}: #{inspect(distribution_targets)}"
    )

    own_identity_set =
      [own_base_jid, own_lid_jid]
      |> Enum.map(&jid_identity/1)
      |> Enum.reject(fn {user, server} -> user == "" or server == "" end)
      |> MapSet.new()

    devices_needing_prekeys =
      Enum.filter(distribution_targets, fn device_jid ->
        target_identity = jid_identity(device_jid)

        # Pragmatic sync fix: always refresh our own targets so distribution fanout
        # to phone/other linked devices starts with a clean pkmsg bootstrap.
        MapSet.member?(own_identity_set, target_identity) or
          not ExWapp.Signal.SessionStore.has_session?(signal_sessions, device_jid)
      end)

    {updated_sessions, prekey_bundles} =
      if devices_needing_prekeys == [] do
        {signal_sessions, %{}}
      else
        Logger.info(
          "[SEND] Fetching group prekeys for #{length(devices_needing_prekeys)} devices: #{inspect(devices_needing_prekeys)}"
        )

        case fetch_prekeys_batch_worker(state, devices_needing_prekeys, signal_sessions) do
          {:ok, sessions, bundles} ->
            {sessions, bundles}

          {:error, reason} ->
            Logger.warning(
              "[SEND] Group batch prekey fetch failed: #{inspect(reason)}, retrying individually"
            )

            fetch_prekeys_individually_worker(state, devices_needing_prekeys, signal_sessions)
        end
      end

    {updated_sessions, prekey_bundles} =
      retry_missing_prekeys_worker(
        state,
        devices_needing_prekeys,
        updated_sessions,
        prekey_bundles,
        "group"
      )

    case updated_sessions do
      {:error, reason} ->
        {:error, reason}

      sessions ->
        {:ok, sessions, prekey_bundles, distribution_targets}
    end
  end

  defp group_current_device_target?(target_jid, own_device_id, own_identities) do
    target_identity = jid_identity(target_jid)

    own_identity_set =
      own_identities
      |> Enum.map(&jid_identity/1)
      |> Enum.reject(fn {user, server} -> user == "" or server == "" end)
      |> MapSet.new()

    MapSet.member?(own_identity_set, target_identity) and
      current_device_target?(target_jid, own_device_id)
  end

  defp build_group_encrypted_message_node(
         group_jid,
         message_id,
         participant_nodes,
         skmsg_payload,
         addressing_mode,
         store,
         include_identity
       ) do
    attrs = %{
      "id" => message_id,
      "to" => strip_device_from_jid(group_jid),
      "type" => "text"
    }

    attrs =
      maybe_put_message_attr(attrs, "addressing_mode", normalize_addressing_mode(addressing_mode))

    participant_jids = extract_participant_jids(participant_nodes)
    attrs = maybe_put_message_attr(attrs, "phash", generate_participant_hash_v2(participant_jids))

    participants_content =
      if participant_nodes == [] do
        []
      else
        [
          %Binary.Node{
            tag: "participants",
            attrs: %{},
            content: participant_nodes
          }
        ]
      end

    skmsg_node = %Binary.Node{
      tag: "enc",
      attrs: %{"v" => "2", "type" => "skmsg"},
      content: Binary.raw(skmsg_payload)
    }

    content =
      if include_identity do
        case get_device_identity_node(store) do
          {:ok, identity_node} ->
            participants_content ++ [identity_node, skmsg_node]

          _ ->
            participants_content ++ [skmsg_node]
        end
      else
        participants_content ++ [skmsg_node]
      end

    %Binary.Node{
      tag: "message",
      attrs: attrs,
      content: content
    }
  end

  defp normalize_addressing_mode(mode) when mode in ["lid", "pn"], do: mode
  defp normalize_addressing_mode(_), do: nil

  defp query_group_info_worker(%{conn: conn} = state, group_jid) do
    message_id = generate_request_id()
    query_node = build_group_info_query(group_jid, message_id)

    Logger.info("[GROUP] Querying group info for #{group_jid}")

    case send_transport_node(state, conn, query_node) do
      :ok ->
        receive do
          {:prekey_response, ^message_id, response_node} ->
            parse_group_info_response(response_node, group_jid)

          {:prekey_error, ^message_id, error} ->
            {:error, {:group_info_query_error, error}}
        after
          15_000 ->
            {:error, :group_info_timeout}
        end

      error ->
        {:error, {:group_info_send_failed, error}}
    end
  end

  defp build_group_info_query(group_jid, message_id) do
    %Binary.Node{
      tag: "iq",
      attrs: %{
        "id" => message_id,
        "xmlns" => "w:g2",
        "type" => "get",
        "to" => strip_device_from_jid(group_jid)
      },
      content: [
        %Binary.Node{
          tag: "query",
          attrs: %{"request" => "interactive"},
          content: nil
        }
      ]
    }
  end

  defp parse_group_info_response(
         %Binary.Node{tag: "iq", attrs: %{"type" => "result"}, content: content},
         group_jid
       )
       when is_list(content) do
    group_node = find_child(content, "group")

    if is_nil(group_node) do
      {:error, :missing_group_node}
    else
      participants =
        (group_node.content || [])
        |> Enum.filter(&match?(%Binary.Node{tag: "participant"}, &1))
        |> Enum.flat_map(&extract_group_participant_identities/1)
        |> normalize_target_list()
        |> Enum.map(&strip_device_from_jid/1)
        |> Enum.reject(&(&1 == group_jid))
        |> Enum.uniq()

      if participants == [] do
        {:error, :empty_group_participants}
      else
        addressing_mode = Map.get(group_node.attrs || %{}, "addressing_mode")
        {:ok, %{participants: participants, addressing_mode: addressing_mode}}
      end
    end
  end

  defp parse_group_info_response(%Binary.Node{attrs: %{"type" => "error"}} = node, _group_jid),
    do: {:error, {:group_info_error, node}}

  defp parse_group_info_response(_response, _group_jid),
    do: {:error, :invalid_group_info_response}

  defp extract_group_participant_identities(%Binary.Node{attrs: attrs}) when is_map(attrs) do
    [
      attrs["jid"],
      attrs["lid"],
      attrs["phone_number"],
      attrs["pn"]
    ]
    |> Enum.map(&normalize_jid_with_device/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp extract_group_participant_identities(_), do: []

  defp ensure_signal_session_worker(state, jid) do
    signal_sessions = state.signal_sessions || ExWapp.Signal.SessionStore.new()
    own_sender_jid = local_account_sender_identity_for_destination(state.store, jid)
    own_device_id = local_account_device_id(state.store)
    recipient_base_jid = strip_device_from_jid(normalize_jid_with_device(jid))

    # Step 1: Discover devices for both recipient and own JID via usync
    query_jids =
      if own_sender_jid != "" and own_sender_jid != recipient_base_jid do
        [recipient_base_jid, own_sender_jid]
      else
        [recipient_base_jid]
      end

    device_map =
      case query_device_list_worker(state, query_jids) do
        {:ok, map} ->
          Logger.info("[SEND] USync device map: #{inspect(map)}")
          map

        {:error, reason} ->
          Logger.warning(
            "[SEND] USync query failed (#{inspect(reason)}), falling back to prekey-only discovery"
          )

          %{}
      end

    # Step 2: Determine all device JIDs that need sessions
    recipient_devices =
      case Map.get(device_map, recipient_base_jid, []) do
        [] -> [recipient_base_jid]
        devices -> devices
      end
      |> normalize_target_list()

    own_devices_all = Map.get(device_map, own_sender_jid, []) |> normalize_target_list()

    # Filter out current device from own devices (for encryption targets)
    own_devices =
      own_devices_all
      |> Enum.reject(&current_device_target?(&1, own_device_id))

    # All usync devices INCLUDING current device — needed for phash (whatsmeow parity)
    all_usync_devices = normalize_target_list(recipient_devices ++ own_devices_all)

    Logger.info("[SEND] Discovered recipient devices: #{inspect(recipient_devices)}")
    Logger.info("[SEND] Discovered own devices (excl. self): #{inspect(own_devices)}")

    # Step 3: Find devices that need prekey fetch.
    # Follow WhatsMeow/Baileys behavior: reuse any existing session regardless of
    # whether the target is recipient or one of our own devices.
    all_device_jids = normalize_target_list(recipient_devices ++ own_devices)

    lid_mapping = load_lid_mapping(state.store)

    # Match whatsmeow: check existing sessions by BOTH wire JID and LID-mapped JID,
    # but fetch prekeys using the ORIGINAL wire JIDs (PN), not the LID-mapped ones.
    # The server expects prekey requests with PN JIDs; LID mapping is only for
    # Signal session storage/encryption (see whatsmeow send.go:1261-1289).
    devices_needing_prekeys =
      Enum.filter(all_device_jids, fn device_jid ->
        device_jid = normalize_jid_with_device(device_jid)
        signal_jid = resolve_signal_encryption_jid(device_jid, lid_mapping)

        not (ExWapp.Signal.SessionStore.has_session?(signal_sessions, signal_jid) or
               ExWapp.Signal.SessionStore.has_session?(signal_sessions, device_jid))
      end)
      |> normalize_target_list()

    # Step 4: Fetch prekeys for all devices that need them (batch)
    {updated_sessions, prekey_bundles} =
      if devices_needing_prekeys != [] do
        Logger.info(
          "[SEND] Fetching prekeys for #{length(devices_needing_prekeys)} devices: #{inspect(devices_needing_prekeys)}"
        )

        case fetch_prekeys_batch_worker(state, devices_needing_prekeys, signal_sessions) do
          {:ok, sessions, bundles} ->
            {sessions, bundles}

          {:error, reason} ->
            Logger.warning(
              "[SEND] Batch prekey fetch failed: #{inspect(reason)}, trying individual fetch"
            )

            # Fallback: fetch prekeys individually for recipient at least
            case fetch_prekeys_worker(state, recipient_base_jid, signal_sessions) do
              {:ok, sessions, bundles} -> {sessions, bundles}
              {:error, reason2} -> {:error, reason2}
            end
        end
      else
        Logger.info("[SEND] All #{length(all_device_jids)} devices already have sessions")
        {signal_sessions, %{}}
      end

    {updated_sessions, prekey_bundles} =
      retry_missing_prekeys_worker(
        state,
        devices_needing_prekeys,
        updated_sessions,
        prekey_bundles,
        "dm"
      )

    case updated_sessions do
      {:error, reason} ->
        {:error, reason}

      sessions ->
        {:ok, sessions, prekey_bundles,
         %{
           recipient_devices: recipient_devices,
           own_devices: own_devices,
           own_identity_jid: own_sender_jid,
           all_usync_devices: all_usync_devices
         }}
    end
  end

  # Fetch prekeys for multiple device JIDs in a single IQ request
  defp fetch_prekeys_batch_worker(
         %{conn: conn, store: store} = state,
         device_jids,
         signal_sessions
       )
       when is_list(device_jids) and device_jids != [] do
    message_id = generate_request_id()
    request_node = build_prekey_request(device_jids, message_id)

    Logger.info("[PREKEY] Sending batch prekey request for #{length(device_jids)} devices")

    case send_transport_node(state, conn, request_node) do
      :ok ->
        receive do
          {:prekey_response, ^message_id, response_node} ->
            Logger.info("[PREKEY] Got batch prekey response")
            process_prekey_response(store, response_node, nil, signal_sessions)

          {:prekey_error, ^message_id, error} ->
            {:error, {:prekey_fetch_error, error}}
        after
          30_000 ->
            {:error, :prekey_timeout}
        end

      error ->
        {:error, {:send_failed, error}}
    end
  end

  defp fetch_prekeys_worker(%{conn: conn, store: store} = state, jid, signal_sessions) do
    message_id = generate_request_id()
    request_node = build_prekey_request(jid, message_id)

    Logger.info("[PREKEY] Sending prekey request for #{jid}")

    # Send the IQ - we'll receive the response directly since we're not a GenServer
    case send_transport_node(state, conn, request_node) do
      :ok ->
        # Wait for response - the session will forward it to us
        receive do
          {:prekey_response, ^message_id, response_node} ->
            Logger.info("[PREKEY] Got prekey response")
            process_prekey_response(store, response_node, jid, signal_sessions)

          {:prekey_error, ^message_id, error} ->
            {:error, {:prekey_fetch_error, error}}
        after
          30_000 ->
            {:error, :prekey_timeout}
        end

      error ->
        {:error, {:send_failed, error}}
    end
  end

  defp fetch_prekeys_individually_worker(state, device_jids, signal_sessions)
       when is_list(device_jids) do
    Enum.reduce_while(device_jids, {:ok, signal_sessions, %{}}, fn device_jid,
                                                                   {:ok, sessions, bundles} ->
      case fetch_prekeys_worker(state, device_jid, sessions) do
        {:ok, updated_sessions, fetched_bundles} ->
          {:cont, {:ok, updated_sessions, Map.merge(bundles, fetched_bundles || %{})}}

        {:error, reason} ->
          {:halt, {:error, {:prekey_fetch_failed, device_jid, reason}}}
      end
    end)
  end

  defp retry_missing_prekeys_worker(
         _state,
         _requested_device_jids,
         {:error, _reason} = error,
         _prekey_bundles,
         _context
       ),
       do: {error, %{}}

  defp retry_missing_prekeys_worker(
         state,
         requested_device_jids,
         sessions,
         prekey_bundles,
         context
       )
       when is_map(sessions) do
    prekey_bundles = prekey_bundles || %{}

    requested =
      requested_device_jids
      |> normalize_target_list()
      |> MapSet.new()

    returned =
      prekey_bundles
      |> Map.keys()
      |> normalize_target_list()
      |> MapSet.new()

    missing =
      requested
      |> MapSet.difference(returned)
      |> MapSet.to_list()
      |> Enum.sort()

    if missing == [] do
      {sessions, prekey_bundles}
    else
      Logger.warning(
        "[SEND] Missing #{context} prekey bundles for #{length(missing)} device(s), retrying individually: #{inspect(missing)}"
      )

      case fetch_prekeys_individually_worker(state, missing, sessions) do
        {:ok, retried_sessions, retried_bundles} ->
          {retried_sessions, Map.merge(prekey_bundles, retried_bundles || %{})}

        {:error, reason} ->
          Logger.warning("[SEND] Individual #{context} prekey retry failed: #{inspect(reason)}")

          {sessions, prekey_bundles}
      end
    end
  end

  defp retry_missing_prekeys_worker(
         _state,
         _requested_device_jids,
         sessions,
         prekey_bundles,
         _context
       ),
       do: {sessions, prekey_bundles || %{}}

  defp process_prekey_response(store, response_node, requested_jid, signal_sessions) do
    case parse_prekey_response(response_node) do
      {:ok, bundles} ->
        Logger.info("[PREKEY] Parsed #{length(bundles)} prekey bundles, creating sessions")

        # Get local identity
        data = Store.load!(store)
        signal_data = Map.get(data, :signal, %{})
        local_identity = Map.get(signal_data, :identity_key)
        local_reg_id = Map.get(signal_data, :registration_id, 0)
        lid_mapping = load_lid_mapping(store)

        if local_identity do
          create_sessions_for_bundles(
            signal_sessions,
            requested_jid,
            bundles,
            local_identity,
            local_reg_id,
            lid_mapping
          )
        else
          {:error, :no_local_identity}
        end

      {:error, reason} ->
        {:error, {:prekey_parse_failed, reason}}
    end
  end

  defp do_send_encrypted(
         session_pid,
         %{conn: conn, store: store} = state,
         signal_sessions,
         jid,
         text,
         prekey_bundles,
         target_hints
       ) do
    message_id = ExWapp.Messages.generate_id()
    timestamp = System.system_time(:second)

    proto = ExWapp.Messages.build_text_proto(text, [])

    case ExWapp.Proto.Message.encode(proto) do
      {:ok, payload} ->
        recipient_payload = ExWapp.Signal.Encryption.pad_message(payload)

        own_payload =
          case build_own_devices_payload(proto, jid) do
            {:ok, own_payload} ->
              ExWapp.Signal.Encryption.pad_message(own_payload)

            {:error, reason} ->
              Logger.warning(
                "[SEND] Failed to build own-device payload for #{jid}, reusing primary payload: #{inspect(reason)}"
              )

              recipient_payload
          end

        all_prekey_bundles = prekey_bundles || %{}

        recipient_prekey_bundles =
          filter_prekey_bundles_for_identity(all_prekey_bundles, jid)

        hinted_recipient_targets = Map.get(target_hints || %{}, :recipient_devices, [])

        recipient_targets =
          resolve_encryption_targets(
            signal_sessions,
            jid,
            recipient_prekey_bundles,
            hinted_recipient_targets
          )

        own_base_jid = local_account_base_jid(store)
        own_sender_jid = Map.get(target_hints || %{}, :own_identity_jid, own_base_jid)
        own_device_id = local_account_device_id(store)
        hinted_own_targets = Map.get(target_hints || %{}, :own_devices, [])
        all_usync_devices = Map.get(target_hints || %{}, :all_usync_devices, [])

        own_targets =
          resolve_own_device_targets(
            signal_sessions,
            own_sender_jid,
            own_device_id,
            hinted_own_targets
          )

        own_lid_jid = local_account_lid_jid(store)

        # Match whatsmeow: compare user parts only (not full {user, server} tuples),
        # since own JIDs may use different server suffixes (@s.whatsapp.net vs @lid).
        own_user_parts =
          [own_base_jid, own_sender_jid, own_lid_jid]
          |> Enum.map(&jid_user_part/1)
          |> Enum.reject(&(&1 == ""))
          |> MapSet.new()

        dest_user = jid_user_part(jid)
        self_chat_destination? = dest_user != "" and MapSet.member?(own_user_parts, dest_user)

        recipient_targets =
          if self_chat_destination? do
            recipient_targets
            |> normalize_target_list()
            |> Enum.reject(&current_device_target?(&1, own_device_id))
          else
            recipient_targets
          end

        {target_specs, own_targets} =
          if self_chat_destination? do
            self_sync_targets = normalize_target_list(recipient_targets ++ own_targets)
            self_specs = Enum.map(self_sync_targets, &%{jid: &1, payload_kind: :own})
            {self_specs, self_sync_targets}
          else
            {build_dm_target_specs(recipient_targets, own_targets), own_targets}
          end

        if self_chat_destination? do
          Logger.info("[SEND] Self-chat detected: routing all non-self targets as own payload")
        end

        Logger.info("[SEND] Recipient targets for #{jid}: #{inspect(recipient_targets)}")
        Logger.info("[SEND] Own-device targets: #{inspect(own_targets)}")
        Logger.info("[SEND] Final fanout targets: #{inspect(target_specs)}")

        case encrypt_for_targets(
               store,
               signal_sessions,
               target_specs,
               %{recipient: recipient_payload, own: own_payload},
               all_prekey_bundles
             ) do
          {:ok, participant_nodes, updated_sessions, include_identity} ->
            persist_signal_sessions(session_pid, updated_sessions)

            pending_message = %{
              id: message_id,
              from_me: true,
              timestamp: timestamp,
              text: text,
              status: :pending,
              participant: nil,
              raw: nil
            }

            ExWapp.Chat.add_message(store, jid, pending_message)

            node =
              build_multi_device_encrypted_message_node(
                jid,
                message_id,
                participant_nodes,
                timestamp,
                store,
                include_identity,
                all_usync_devices
              )

            case send_transport_node(state, conn, node) do
              :ok ->
                Logger.info(
                  "[SEND] Sent encrypted message to #{length(participant_nodes)} targets (base=#{jid})"
                )

                emit_telemetry(
                  :message_sent,
                  %{message_count: 1, payload_bytes: byte_size(payload)},
                  state,
                  %{jid: jid, message_id: message_id, encryption: :multi_device}
                )

                {:ok, message_id}

              error ->
                ExWapp.Chat.update_message_status(store, jid, message_id, :failed)
                error
            end

          {:error, reason} ->
            Logger.error("[SEND] Encryption failed for all targets: #{inspect(reason)}")
            {:error, {:encryption_failed, reason}}
        end

      {:error, reason} ->
        {:error, {:proto_encode, reason}}
    end
  end

  defp create_sessions_for_bundles(
         signal_sessions,
         requested_jid,
         bundles,
         local_identity,
         local_reg_id,
         lid_mapping
       ) do
    requested_jid = normalize_jid_for_signal(requested_jid)

    case Enum.reduce_while(
           bundles,
           {:ok, signal_sessions, %{}},
           fn bundle, {:ok, sessions, bundle_map} ->
             device_jid =
               bundle
               |> Map.get(:device_jid, requested_jid)
               |> normalize_jid_with_device()

             device_jid = if device_jid == "", do: requested_jid, else: device_jid
             signal_jid = resolve_signal_encryption_jid(device_jid, lid_mapping)
             signal_jid = if signal_jid == "", do: device_jid, else: signal_jid

             if device_jid == "" do
               {:halt, {:error, :invalid_device_jid}}
             else
                Logger.info(
                  "[PREKEY] Creating session for wire_jid=#{device_jid} signal_jid=#{signal_jid} (request_jid=#{requested_jid})"
                )

                case ExWapp.Signal.SessionStore.get_or_create_session(
                      sessions,
                      signal_jid,
                      local_identity,
                      bundle,
                      local_reg_id
                    ) do
                 {:ok, created_session, base_key, updated_sessions} ->
                   updated_sessions =
                     updated_sessions
                     |> maybe_alias_signal_session(requested_jid, signal_jid, created_session)
                     |> maybe_alias_signal_session(device_jid, signal_jid, created_session)

                   Logger.info(
                     "[PREKEY] Session ready for wire_jid=#{device_jid} signal_jid=#{signal_jid}, base_key=#{if base_key, do: byte_size(base_key), else: "nil"} bytes"
                   )

                   bundle_with_info =
                     bundle
                     |> Map.put(:base_key, base_key)
                      |> Map.put(:device_jid, device_jid)
                      |> Map.put(:signal_jid, signal_jid)

                   bundle_map =
                     bundle_map
                     |> Map.put(device_jid, bundle_with_info)
                     |> maybe_put_bundle_alias(signal_jid, device_jid, bundle_with_info)

                   {:cont,
                    {:ok, updated_sessions, bundle_map}}

                 {:error, reason} ->
                   {:halt, {:error, {:session_create_failed, device_jid, reason}}}
               end
             end
           end
         ) do
      {:ok, updated_sessions, bundle_map} when map_size(bundle_map) > 0 ->
        {:ok, updated_sessions, bundle_map}

      {:ok, _updated_sessions, _bundle_map} ->
        {:error, :no_sessions_created}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_put_bundle_alias(bundle_map, alias_jid, source_jid, bundle)
       when is_binary(alias_jid) and is_binary(source_jid) and alias_jid != "" and source_jid != "" and
              alias_jid != source_jid do
    Map.put(bundle_map, alias_jid, bundle)
  end

  defp maybe_put_bundle_alias(bundle_map, _alias_jid, _source_jid, _bundle), do: bundle_map

  defp resolve_encryption_targets(signal_sessions, jid, prekey_bundles, hinted_targets) do
    targets =
      cond do
        is_list(hinted_targets) and hinted_targets != [] ->
          hinted_targets

        is_map(prekey_bundles) and map_size(prekey_bundles) > 0 ->
          Map.keys(prekey_bundles)

        true ->
          list_session_targets_for_jid(signal_sessions, jid)
      end

    targets =
      if targets == [] do
        [jid]
      else
        targets
      end

    normalized_targets = normalize_target_list(targets)

    if is_list(hinted_targets) and hinted_targets != [] do
      normalized_targets
    else
      drop_base_alias_targets(normalized_targets)
    end
  end

  defp filter_prekey_bundles_for_identity(prekey_bundles, jid)
       when is_map(prekey_bundles) and map_size(prekey_bundles) > 0 do
    identity = jid_identity(jid)

    prekey_bundles
    |> Enum.filter(fn {candidate, _bundle} -> jid_identity(candidate) == identity end)
    |> Map.new()
  end

  defp filter_prekey_bundles_for_identity(_prekey_bundles, _jid), do: %{}

  defp resolve_own_device_targets(signal_sessions, own_base_jid, own_device_id, hinted_targets) do
    if own_base_jid == "" do
      []
    else
      targets =
        if is_list(hinted_targets) and hinted_targets != [] do
          hinted_targets
        else
          list_session_targets_for_jid(signal_sessions, own_base_jid)
        end

      targets
      |> normalize_target_list()
      |> Enum.uniq()
      |> Enum.reject(&current_device_target?(&1, own_device_id))
    end
  end

  defp normalize_target_list(targets) when is_list(targets) do
    targets
    |> Enum.map(&normalize_jid_with_device/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp normalize_target_list(_), do: []

  defp build_dm_target_specs(recipient_targets, own_targets) do
    specs =
      Enum.map(recipient_targets, &%{jid: &1, payload_kind: :recipient}) ++
        Enum.map(own_targets, &%{jid: &1, payload_kind: :own})

    Enum.reduce(specs, [], fn %{jid: jid, payload_kind: payload_kind} = spec, acc ->
      case Enum.find_index(acc, fn existing -> existing.jid == jid end) do
        nil ->
          acc ++ [spec]

        idx when payload_kind == :own ->
          existing = Enum.at(acc, idx)

          if existing.payload_kind == :own do
            acc
          else
            Logger.info("[SEND] Promoting target #{jid} to own payload for sync copy")
            List.replace_at(acc, idx, %{existing | payload_kind: :own})
          end

        _ ->
          acc
      end
    end)
  end

  defp current_device_target?(jid, own_device_id)
       when is_integer(own_device_id) and own_device_id >= 0 do
    case jid_device_id(jid) do
      nil -> own_device_id == 0
      device_id -> device_id == own_device_id
    end
  end

  defp current_device_target?(_jid, _own_device_id), do: false

  defp jid_device_id(jid) when is_binary(jid) do
    case Regex.run(~r/^[^@]+:(\d+)@/, jid) do
      [_, value] ->
        case Integer.parse(value) do
          {device_id, ""} -> device_id
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp jid_device_id(%ExWapp.JID{device: device}) when is_integer(device), do: device
  defp jid_device_id(_), do: nil

  defp load_lid_mapping(nil), do: %{}

  defp load_lid_mapping(store) do
    store
    |> Store.load!()
    |> Map.get(:lid_mapping, %{})
  rescue
    _ -> %{}
  end

  defp resolve_signal_encryption_jid(target_jid, lid_mapping) do
    target_jid = normalize_jid_with_device(target_jid)
    base_target_jid = strip_device_from_jid(target_jid)

    cond do
      target_jid == "" ->
        ""

      lid_jid?(base_target_jid) ->
        target_jid

      true ->
        mapped_lid =
          Map.get(lid_mapping || %{}, {:pn_to_lid, base_target_jid})
          |> normalize_jid_with_device()

        if mapped_lid == "" do
          target_jid
        else
          maybe_apply_device_to_mapped_jid(target_jid, mapped_lid)
        end
    end
  end

  defp maybe_apply_device_to_mapped_jid(source_jid, mapped_jid) do
    case {jid_device_id(source_jid), String.split(mapped_jid, "@", parts: 2)} do
      {device_id, [user, server]} when is_integer(device_id) and device_id > 0 ->
        user = Regex.replace(~r/:\d+$/, user, "")
        "#{user}:#{device_id}@#{server}"

      _ ->
        mapped_jid
    end
  end

  defp local_account_base_jid(nil), do: ""

  defp local_account_base_jid(store) do
    data = Store.load!(store)

    data
    |> local_account_jid_value()
    |> normalize_jid_with_device()
    |> strip_device_from_jid()
  rescue
    _ -> ""
  end

  defp local_account_device_id(nil), do: 0

  defp local_account_device_id(store) do
    data = Store.load!(store)
    signal_device_id = get_in(data, [:signal, :device_id])

    case local_account_jid_value(data) do
      %ExWapp.JID{device: device} when is_integer(device) and device >= 0 ->
        device

      jid when is_binary(jid) ->
        jid_device_id(jid) || signal_device_id || 0

      _ ->
        signal_device_id || 0
    end
  rescue
    _ -> 0
  end

  defp local_account_lid_jid(nil), do: ""

  defp local_account_lid_jid(store) do
    data = Store.load!(store)

    data
    |> local_account_lid_value()
    |> normalize_jid_with_device()
    |> strip_device_from_jid()
  rescue
    _ -> ""
  end

  defp local_account_sender_key_jid(nil), do: ""

  defp local_account_sender_key_jid(store) do
    lid = local_account_lid_jid(store)
    if lid != "", do: lid, else: local_account_base_jid(store)
  end

  defp local_account_sender_identity_for_destination(nil, _destination_jid), do: ""

  defp local_account_sender_identity_for_destination(store, destination_jid) do
    destination_jid = normalize_jid_with_device(destination_jid)
    own_base = local_account_base_jid(store)
    own_lid = local_account_lid_jid(store)

    cond do
      lid_jid?(destination_jid) and own_lid != "" ->
        own_lid

      own_base != "" ->
        own_base

      own_lid != "" ->
        own_lid

      true ->
        ""
    end
  end

  defp lid_jid?(jid) when is_binary(jid) do
    String.ends_with?(jid, "@lid") or String.ends_with?(jid, "@hosted.lid")
  end

  defp lid_jid?(_), do: false

  defp local_account_jid_value(data) do
    get_in(data, [:pairing, :device, "jid"]) ||
      get_in(data, [:pairing, :device, :jid]) ||
      get_in(data, [:pairing, "device", "jid"]) ||
      get_in(data, [:pairing, "device", :jid]) ||
      get_in(data, ["pairing", :device, "jid"]) ||
      get_in(data, ["pairing", :device, :jid]) ||
      get_in(data, ["pairing", "device", "jid"]) ||
      get_in(data, ["pairing", "device", :jid]) ||
      get_in(data, [:client_info, :jid]) ||
      get_in(data, [:client_info, "jid"]) ||
      get_in(data, ["client_info", :jid]) ||
      get_in(data, ["client_info", "jid"])
  end

  defp local_account_lid_value(data) do
    get_in(data, [:pairing, :device, "lid"]) ||
      get_in(data, [:pairing, :device, :lid]) ||
      get_in(data, [:pairing, "device", "lid"]) ||
      get_in(data, [:pairing, "device", :lid]) ||
      get_in(data, ["pairing", :device, "lid"]) ||
      get_in(data, ["pairing", :device, :lid]) ||
      get_in(data, ["pairing", "device", "lid"]) ||
      get_in(data, ["pairing", "device", :lid]) ||
      get_in(data, [:client_info, :lid]) ||
      get_in(data, [:client_info, "lid"]) ||
      get_in(data, ["client_info", :lid]) ||
      get_in(data, ["client_info", "lid"])
  end

  defp build_own_devices_payload(proto_message, destination_jid) do
    wrapped = %ExWapp.Proto.Message{
      deviceSentMessage: %ExWapp.Proto.DeviceSentMessage{
        destinationJid: strip_device_from_jid(destination_jid),
        message: proto_message,
        phash: nil
      }
    }

    ExWapp.Proto.Message.encode(wrapped)
  end

  defp list_session_targets_for_jid(signal_sessions, jid) do
    target_identity = jid_identity(jid)
    sessions = Map.get(signal_sessions || %{}, :sessions, %{})

    sessions
    |> Map.keys()
    |> Enum.filter(fn candidate -> jid_identity(candidate) == target_identity end)
  end

  defp drop_base_alias_targets(targets) when is_list(targets) do
    if Enum.any?(targets, &jid_has_explicit_device?/1) do
      Enum.reject(targets, fn target -> not jid_has_explicit_device?(target) end)
    else
      targets
    end
  end

  defp encrypt_for_targets(store, signal_sessions, target_specs, payloads, prekey_bundles) do
    lid_mapping = load_lid_mapping(store)

    result =
      Enum.reduce(
        target_specs,
        %{nodes: [], sessions: signal_sessions, include_identity: false, errors: []},
        fn %{jid: target_jid, payload_kind: payload_kind}, acc ->
          target_jid = normalize_jid_with_device(target_jid)
          mapped_jid = resolve_signal_encryption_jid(target_jid, lid_mapping)

          signal_jid =
            cond do
              mapped_jid == "" or mapped_jid == target_jid ->
                target_jid

              true ->
                mapped_jid
            end

          sessions =
            if signal_jid != target_jid do
              ensure_signal_session_alias(acc.sessions, signal_jid, target_jid)
            else
              acc.sessions
            end

          if signal_jid != target_jid do
            Logger.info(
              "[SEND] Encrypting wire_jid=#{target_jid} using signal_jid=#{signal_jid}"
            )
          end

          padded_payload = Map.get(payloads, payload_kind, Map.get(payloads, :recipient))

          bundle =
            Map.get(prekey_bundles, target_jid) || Map.get(prekey_bundles, signal_jid) || %{}

          bundle_for_encrypt = if is_binary(Map.get(bundle, :base_key)), do: bundle, else: %{}

          if is_binary(padded_payload) do
            encrypt_result =
              ExWapp.Signal.Encryption.encrypt_for_recipient_sync(
                store,
                sessions,
                signal_jid,
                padded_payload,
                bundle_for_encrypt
              )

            encrypt_result =
              case encrypt_result do
                {:error, :no_session} when signal_jid != target_jid ->
                  Logger.info(
                    "[SEND] No session for signal_jid=#{signal_jid}, retrying with wire jid=#{target_jid}"
                  )

                  ExWapp.Signal.Encryption.encrypt_for_recipient_sync(
                    store,
                    sessions,
                    target_jid,
                    padded_payload,
                    bundle_for_encrypt
                  )

                other ->
                  other
              end

            case encrypt_result do
              {:ok, ciphertext, enc_type, updated_sessions} ->
                updated_sessions =
                  if signal_jid != target_jid do
                    ensure_signal_session_alias(updated_sessions, signal_jid, target_jid)
                  else
                    updated_sessions
                  end

                node = build_participant_encrypted_node(target_jid, ciphertext, enc_type)

                %{
                  acc
                  | nodes: [node | acc.nodes],
                    sessions: updated_sessions,
                    include_identity: acc.include_identity or enc_type == :prekey
                }

              {:error, reason} ->
                Logger.warning(
                  "[SEND] Failed to encrypt for wire_jid=#{target_jid} signal_jid=#{signal_jid}: #{inspect(reason)}"
                )

                %{acc | errors: [{target_jid, reason} | acc.errors]}
            end
          else
            Logger.warning("[SEND] Missing payload for target=#{target_jid} kind=#{payload_kind}")
            %{acc | errors: [{target_jid, :missing_payload} | acc.errors]}
          end
        end
      )

    if result.nodes == [] do
      {:error, {:no_encrypted_targets, Enum.reverse(result.errors)}}
    else
      {:ok, Enum.reverse(result.nodes), result.sessions, result.include_identity}
    end
  end

  defp ensure_signal_session_alias(signal_sessions, alias_jid, source_jid) do
    alias_jid = normalize_jid_with_device(alias_jid)
    source_jid = normalize_jid_with_device(source_jid)

    cond do
      alias_jid == "" or source_jid == "" or alias_jid == source_jid ->
        signal_sessions

      ExWapp.Signal.SessionStore.has_session?(signal_sessions, alias_jid) ->
        signal_sessions

      true ->
        case ExWapp.Signal.SessionStore.get_session(signal_sessions, source_jid) do
          {:ok, session} ->
            Logger.info("[SEND] Migrating session #{source_jid} -> #{alias_jid}")
            ExWapp.Signal.SessionStore.put_session(signal_sessions, alias_jid, session)

          :not_found ->
            signal_sessions
        end
    end
  end

  defp build_participant_encrypted_node(jid, ciphertext, enc_type) do
    %Binary.Node{
      tag: "to",
      attrs: %{"jid" => jid},
      content: [
        %Binary.Node{
          tag: "enc",
          attrs: %{
            "v" => "2",
            "type" => enc_type_to_wire(enc_type)
          },
          content: Binary.raw(ciphertext)
        }
      ]
    }
  end

  defp build_multi_device_encrypted_message_node(
         jid,
         message_id,
         participant_nodes,
         _timestamp,
         store,
         include_identity,
         all_usync_devices
       ) do
    attrs = %{
      "id" => message_id,
      "to" => strip_device_from_jid(jid),
      "type" => "text"
    }

    # Match whatsmeow: phash is computed from ALL usync devices (including current device),
    # not just the encrypted targets. See whatsmeow send.go:859 participantListHashV2(allDevices).
    phash_jids =
      if all_usync_devices != [] do
        all_usync_devices
      else
        extract_participant_jids(participant_nodes)
      end

    attrs = maybe_put_message_attr(attrs, "phash", generate_participant_hash_v2(phash_jids))

    participants_node = %Binary.Node{
      tag: "participants",
      attrs: %{},
      content: participant_nodes
    }

    content =
      if include_identity do
        case get_device_identity_node(store) do
          {:ok, identity_node} ->
            Logger.info("[SEND] Including device-identity in message")
            [participants_node, identity_node]

          _ ->
            [participants_node]
        end
      else
        [participants_node]
      end

    # Append tctoken for 1:1 messages if available (Baileys: messages-send.ts)
    base_jid = strip_device_from_jid(jid)
    content = maybe_append_tctoken(content, base_jid, store)

    %Binary.Node{
      tag: "message",
      attrs: attrs,
      content: content
    }
  end

  defp extract_participant_jids(participant_nodes) when is_list(participant_nodes) do
    participant_nodes
    |> Enum.map(fn
      %Binary.Node{attrs: attrs} -> Map.get(attrs, "jid", "")
      _ -> ""
    end)
    |> Enum.reject(&(&1 == ""))
  end

  defp extract_participant_jids(_), do: []

  defp generate_participant_hash_v2([]), do: nil

  defp generate_participant_hash_v2(participants) when is_list(participants) do
    participants =
      participants
      |> Enum.map(&to_string/1)
      |> Enum.sort()

    # Match whatsmeow: base64-encode first 6 bytes of SHA256 hash (raw, no padding).
    <<first_6_bytes::binary-size(6), _rest::binary>> =
      participants
      |> Enum.join("")
      |> then(&:crypto.hash(:sha256, &1))

    "2:" <> Base.encode64(first_6_bytes, padding: false)
  end

  defp maybe_put_message_attr(attrs, _key, nil), do: attrs
  defp maybe_put_message_attr(attrs, key, value), do: Map.put(attrs, key, value)

  defp build_prekey_request(jid, message_id) when is_binary(jid) do
    build_prekey_request([jid], message_id)
  end

  defp build_prekey_request(jids, message_id) when is_list(jids) do
    user_nodes =
      Enum.map(jids, fn jid ->
        %Binary.Node{
          tag: "user",
          attrs: %{"jid" => jid},
          content: nil
        }
      end)

    %Binary.Node{
      tag: "iq",
      attrs: %{
        "id" => message_id,
        "xmlns" => "encrypt",
        "type" => "get",
        "to" => "s.whatsapp.net"
      },
      content: [
        %Binary.Node{
          tag: "key",
          attrs: %{},
          content: user_nodes
        }
      ]
    }
  end

  # --- USync device list query (WhatsApp multi-device discovery) ---

  defp build_usync_device_query(jids, message_id) when is_list(jids) do
    user_nodes =
      Enum.map(jids, fn jid ->
        %Binary.Node{
          tag: "user",
          attrs: %{"jid" => strip_device_from_jid(jid)},
          content: nil
        }
      end)

    %Binary.Node{
      tag: "iq",
      attrs: %{
        "id" => message_id,
        "xmlns" => "usync",
        "type" => "get",
        "to" => "s.whatsapp.net"
      },
      content: [
        %Binary.Node{
          tag: "usync",
          attrs: %{
            "sid" => generate_request_id(),
            "mode" => "query",
            "last" => "true",
            "index" => "0",
            "context" => "message"
          },
          content: [
            %Binary.Node{
              tag: "query",
              attrs: %{},
              content: [
                %Binary.Node{
                  tag: "devices",
                  attrs: %{"version" => "2"},
                  content: nil
                }
              ]
            },
            %Binary.Node{
              tag: "list",
              attrs: %{},
              content: user_nodes
            }
          ]
        }
      ]
    }
  end

  defp parse_usync_device_response(%Binary.Node{
         tag: "iq",
         attrs: %{"type" => "result"},
         content: content
       })
       when is_list(content) do
    # Response structure: <iq><usync><list><user jid=...><devices><device-list><device id=.../></device-list></devices></user></list></usync></iq>
    usync_node = find_child(content, "usync")
    list_node = if usync_node, do: find_child(usync_node.content || [], "list"), else: nil

    user_nodes =
      if list_node do
        (list_node.content || [])
        |> Enum.filter(&match?(%Binary.Node{tag: "user"}, &1))
      else
        []
      end

    device_map =
      Enum.reduce(user_nodes, %{}, fn user_node, acc ->
        user_jid =
          case Map.get(user_node.attrs || %{}, "jid") do
            %ExWapp.JID{} = jid -> ExWapp.JID.to_string(jid)
            jid when is_binary(jid) -> jid
            _ -> nil
          end

        if user_jid do
          base_jid = strip_device_from_jid(user_jid)
          user_part = base_jid |> String.split("@", parts: 2) |> hd()
          server = base_jid |> String.split("@", parts: 2) |> List.last()

          devices_node = find_child(user_node.content || [], "devices")

          device_list_node =
            if devices_node, do: find_child(devices_node.content || [], "device-list"), else: nil

          device_jids =
            if device_list_node do
              (device_list_node.content || [])
              |> Enum.filter(&match?(%Binary.Node{tag: "device"}, &1))
              |> Enum.map(fn device_node ->
                device_id =
                  case Map.get(device_node.attrs || %{}, "id") do
                    id when is_integer(id) -> id
                    id when is_binary(id) -> String.to_integer(id)
                    _ -> 0
                  end

                if device_id == 0 do
                  "#{user_part}@#{server}"
                else
                  "#{user_part}:#{device_id}@#{server}"
                end
              end)
            else
              # Fallback: return base JID if no device list
              [base_jid]
            end

          Map.put(acc, base_jid, device_jids)
        else
          acc
        end
      end)

    {:ok, device_map}
  end

  defp parse_usync_device_response(%Binary.Node{attrs: %{"type" => "error"}} = node) do
    {:error, {:usync_error, node}}
  end

  defp parse_usync_device_response(_), do: {:error, :invalid_usync_response}

  @doc false
  defp query_device_list_worker(%{conn: conn} = state, jids) when is_list(jids) do
    message_id = generate_request_id()
    query_node = build_usync_device_query(jids, message_id)

    Logger.info("[USYNC] Querying device list for #{inspect(jids)}")

    case send_transport_node(state, conn, query_node) do
      :ok ->
        receive do
          {:prekey_response, ^message_id, response_node} ->
            Logger.info("[USYNC] Got device list response")
            parse_usync_device_response(response_node)

          {:prekey_error, ^message_id, error} ->
            Logger.warning("[USYNC] Device list query error: #{inspect(error)}")
            {:error, {:usync_query_error, error}}
        after
          15_000 ->
            Logger.warning("[USYNC] Device list query timed out")
            {:error, :usync_timeout}
        end

      error ->
        {:error, {:usync_send_failed, error}}
    end
  end

  defp parse_prekey_response(%Binary.Node{
         tag: "iq",
         attrs: %{"type" => "result"},
         content: content
       })
       when is_list(content) do
    case find_child(content, "list") do
      %Binary.Node{content: users} when is_list(users) ->
        user_nodes =
          Enum.filter(users, &match?(%Binary.Node{tag: "user"}, &1))

        bundles =
          Enum.reduce(user_nodes, [], fn user_node, acc ->
            case parse_user_prekey_bundle(user_node) do
              {:ok, bundle} ->
                device_jid =
                  user_node
                  |> extract_user_jid()
                  |> normalize_jid_with_device()

                Logger.info("[PREKEY] Parsed bundle for device_jid=#{inspect(device_jid)}")
                [Map.put(bundle, :device_jid, device_jid) | acc]

              {:error, reason} ->
                Logger.warning("[PREKEY] Skipping invalid bundle node: #{inspect(reason)}")
                acc
            end
          end)
          |> Enum.reverse()

        if bundles == [] do
          {:error, :no_valid_bundles_in_response}
        else
          {:ok, bundles}
        end

      _ ->
        {:error, :no_list_in_response}
    end
  end

  defp parse_prekey_response(%Binary.Node{attrs: %{"type" => "error"}} = node) do
    {:error, {:iq_error, node}}
  end

  defp parse_prekey_response(_), do: {:error, :invalid_response}

  defp extract_user_jid(%Binary.Node{attrs: attrs}) do
    case Map.get(attrs, "jid") do
      %ExWapp.JID{} = jid -> ExWapp.JID.to_string(jid)
      jid when is_binary(jid) -> jid
      _ -> nil
    end
  end

  defp parse_user_prekey_bundle(%Binary.Node{attrs: attrs, content: content})
       when is_list(content) do
    _jid = Map.get(attrs, "jid")

    # Extract registration ID
    registration = find_child(content, "registration")
    registration_id = if registration, do: parse_binary_int(registration.content), else: 0

    # Extract identity key
    identity = find_child(content, "identity")
    identity_key = if identity, do: extract_binary(identity.content), else: nil

    # Extract signed prekey
    skey = find_child(content, "skey")
    signed_prekey = if skey, do: parse_signed_prekey_node(skey), else: nil

    # Extract one-time prekey (optional)
    key = find_child(content, "key")
    one_time_prekey = if key, do: parse_prekey_node(key), else: nil

    if identity_key && signed_prekey do
      {:ok,
       %{
         registration_id: registration_id,
         identity_key: identity_key,
         signed_prekey: signed_prekey,
         prekey: one_time_prekey
       }}
    else
      {:error, :incomplete_bundle}
    end
  end

  defp parse_user_prekey_bundle(_), do: {:error, :invalid_user_node}

  defp parse_signed_prekey_node(%Binary.Node{content: content}) when is_list(content) do
    id_node = find_child(content, "id")
    value_node = find_child(content, "value")
    sig_node = find_child(content, "signature")

    id = if id_node, do: parse_key_id(id_node.content), else: 0
    public = if value_node, do: extract_binary(value_node.content), else: nil
    signature = if sig_node, do: extract_binary(sig_node.content), else: nil

    if public && signature do
      %{id: id, public: public, signature: signature}
    else
      nil
    end
  end

  defp parse_signed_prekey_node(_), do: nil

  defp parse_prekey_node(%Binary.Node{content: content}) when is_list(content) do
    id_node = find_child(content, "id")
    value_node = find_child(content, "value")

    id = if id_node, do: parse_key_id(id_node.content), else: 0
    public = if value_node, do: extract_binary(value_node.content), else: nil

    if public, do: %{id: id, public: public}, else: nil
  end

  defp parse_prekey_node(_), do: nil

  defp find_child(content, tag) when is_list(content) do
    Enum.find(content, fn
      %Binary.Node{tag: ^tag} -> true
      _ -> false
    end)
  end

  defp find_child(_, _), do: nil

  defp extract_binary(nil), do: nil
  defp extract_binary(binary) when is_binary(binary), do: binary
  defp extract_binary({:raw, binary}), do: binary
  defp extract_binary(%Binary.Raw{data: binary}), do: binary
  defp extract_binary([item]), do: extract_binary(item)
  defp extract_binary(_), do: nil

  defp parse_binary_int(content) do
    case extract_binary(content) do
      nil ->
        0

      <<int::32>> ->
        int

      bin when is_binary(bin) and byte_size(bin) >= 4 ->
        <<int::32>> = binary_part(bin, 0, 4)
        int

      _ ->
        0
    end
  end

  defp parse_key_id(content) do
    case extract_binary(content) do
      nil -> 0
      <<id::24>> -> id
      <<_::8, id::24>> -> id
      bin when is_binary(bin) -> :binary.decode_unsigned(bin)
      _ -> 0
    end
  end

  defp normalize_jid_for_signal(jid) when is_binary(jid) do
    jid
    |> normalize_jid_with_device()
    |> strip_device_from_jid()
  end

  defp normalize_jid_for_signal(_), do: ""

  defp normalize_jid_with_device(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
  end

  defp normalize_jid_with_device(%ExWapp.JID{} = jid),
    do: jid |> ExWapp.JID.to_string() |> normalize_jid_with_device()

  defp normalize_jid_with_device(_), do: ""

  defp strip_device_from_jid(jid) when is_binary(jid) do
    String.replace(jid, ~r/:(\d+)@/, "@")
  end

  defp strip_device_from_jid(%ExWapp.JID{} = jid),
    do: jid |> ExWapp.JID.to_string() |> strip_device_from_jid()

  defp strip_device_from_jid(_), do: ""

  defp jid_has_explicit_device?(jid) when is_binary(jid) do
    jid
    |> String.split("@", parts: 2)
    |> case do
      [user, _server] -> String.contains?(user, ":")
      _ -> false
    end
  end

  defp jid_has_explicit_device?(_), do: false

  defp jid_identity(jid) do
    jid =
      jid
      |> normalize_jid_with_device()
      |> strip_device_from_jid()

    case String.split(jid, "@", parts: 2) do
      [user, server] when user != "" and server != "" -> {user, server}
      _ -> {"", ""}
    end
  end

  defp jid_user_part(jid) when is_binary(jid) do
    jid
    |> normalize_jid_with_device()
    |> strip_device_from_jid()
    |> String.split("@", parts: 2)
    |> case do
      [user, _server] when user != "" -> user
      _ -> ""
    end
  end

  defp jid_user_part(_), do: ""

  defp maybe_append_tctoken(content, jid, store) do
    is_group = String.contains?(jid, "@g.us")

    if is_group do
      content
    else
      data = Store.load!(store)
      tctokens = Map.get(data, :tctokens, %{})

      case Map.get(tctokens, jid) do
        %{token: token} when is_binary(token) ->
          Logger.debug("[SEND] Appending tctoken for #{jid}")

          tctoken_node = %Binary.Node{
            tag: "tctoken",
            attrs: %{},
            content: Binary.raw(token)
          }

          content ++ [tctoken_node]

        _ ->
          content
      end
    end
  rescue
    _ -> content
  end

  defp get_device_identity_node(store) do
    data = Store.load!(store)

    # For outgoing messages, the device-identity MUST include accountSignatureKey
    # so recipients can verify our device identity (whatsmeow behavior).
    # The adv_self_signed payload (encoded WITHOUT accountSignatureKey) is only
    # correct for pair-device-sign ACK — NOT for message device-identity.
    case Map.get(data, :pairing) do
      %{adv: %{signed: signed}} ->
        case ExWapp.Pairing.ADV.encode_signed_device_identity(
               signed,
               include_signature_key: true
             ) do
          {:ok, payload} ->
            Logger.info(
              "[SEND] Using ADV signed identity with accountSignatureKey: #{byte_size(payload)} bytes"
            )

            node = %Binary.Node{
              tag: "device-identity",
              attrs: %{},
              content: Binary.raw(payload)
            }

            {:ok, node}

          {:error, reason} ->
            Logger.warning(
              "[SEND] Failed to encode ADV signed identity, falling back: #{inspect(reason)}"
            )

            get_device_identity_node_fallback(data)
        end

      %{device_identity: device_identity} when is_binary(device_identity) ->
        Logger.info("[SEND] Found device_identity: #{byte_size(device_identity)} bytes")

        node = %Binary.Node{
          tag: "device-identity",
          attrs: %{},
          content: Binary.raw(device_identity)
        }

        {:ok, node}

      %{adv_device_identity: adv_identity} when is_binary(adv_identity) ->
        Logger.info("[SEND] Found adv_device_identity: #{byte_size(adv_identity)} bytes")

        node = %Binary.Node{
          tag: "device-identity",
          attrs: %{},
          content: Binary.raw(adv_identity)
        }

        {:ok, node}

      _ ->
        get_device_identity_node_fallback(data)
    end
  end

  defp get_device_identity_node_fallback(data) do
    case Map.get(data, :pairing) do
      %{device_identity: device_identity} when is_binary(device_identity) ->
        Logger.info(
          "[SEND] Falling back to raw device_identity: #{byte_size(device_identity)} bytes"
        )

        node = %Binary.Node{
          tag: "device-identity",
          attrs: %{},
          content: Binary.raw(device_identity)
        }

        {:ok, node}

      %{adv_device_identity: adv_identity} when is_binary(adv_identity) ->
        Logger.info(
          "[SEND] Falling back to raw adv_device_identity: #{byte_size(adv_identity)} bytes"
        )

        node = %Binary.Node{
          tag: "device-identity",
          attrs: %{},
          content: Binary.raw(adv_identity)
        }

        {:ok, node}

      _ ->
        Logger.warning("[SEND] No device identity found in pairing data")
        {:error, :no_device_identity}
    end
  end

  defp enc_type_to_wire(:prekey), do: "pkmsg"
  defp enc_type_to_wire(:whisper), do: "msg"
  defp enc_type_to_wire("prekey"), do: "pkmsg"
  defp enc_type_to_wire("pkmsg"), do: "pkmsg"
  defp enc_type_to_wire("msg"), do: "msg"
  defp enc_type_to_wire(_), do: "msg"

  # ============================================================================
  # QR Subscriber Management
  # ============================================================================

  defp notify_qr(state, event) do
    emit_telemetry(
      :qr,
      %{subscriber_count: map_size(state.qr_subscribers)},
      state,
      %{event: qr_event_kind(event)}
    )

    Enum.each(state.qr_subscribers, fn {ref, {pid, _mon}} ->
      send(pid, {:ex_wapp_qr, ref, event})
    end)
  end

  defp remove_qr_subscriber(state, ref) do
    case Map.pop(state.qr_subscribers, ref) do
      {nil, _} ->
        state

      {{pid, mon}, subscribers} ->
        Process.demonitor(mon, [:flush])
        send(pid, {:ex_wapp_qr_closed, ref})
        %{state | qr_subscribers: subscribers}
    end
  end

  defp cleanup_dead_subscriber(state, dead_mon) do
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

  # ============================================================================
  # Message Subscriber Management
  # ============================================================================

  defp notify_message_subscribers(state, jid, message) do
    Enum.each(state.message_subscribers, fn {ref, {pid, _mon}} ->
      send(pid, {:ex_wapp_message, ref, jid, message})
    end)
  end

  defp remove_message_subscriber(state, ref) do
    case Map.pop(state.message_subscribers, ref) do
      {nil, _} ->
        state

      {{pid, mon}, subscribers} ->
        Process.demonitor(mon, [:flush])
        send(pid, {:ex_wapp_messages_closed, ref})
        %{state | message_subscribers: subscribers}
    end
  end

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

  defp send_transport_node(%{transport_mod: transport_mod}, conn, node) when is_pid(conn) do
    transport_mod.send_node(conn, node)
  rescue
    e -> {:error, {:exception, e}}
  end

  defp persist_signal_sessions(session_pid, sessions) do
    GenServer.call(session_pid, {:update_signal_sessions, sessions})
  rescue
    _ ->
      # Fallback for edge cases where the worker no longer can call the session.
      send(session_pid, {:signal_sessions_updated, sessions})
      :ok
  end

  defp maybe_alias_signal_session(signal_sessions, requested_jid, device_jid, session) do
    requested_jid = normalize_jid_for_signal(requested_jid)
    device_jid = normalize_jid_with_device(device_jid)

    if requested_jid != "" and device_jid != "" and requested_jid != device_jid do
      Logger.info("[PREKEY] Aliasing session #{requested_jid} -> #{device_jid}")
      ExWapp.Signal.SessionStore.put_session(signal_sessions, requested_jid, session)
    else
      signal_sessions
    end
  end

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

    %{state | pending_iqs: %{}, send_workers: %{}}
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
