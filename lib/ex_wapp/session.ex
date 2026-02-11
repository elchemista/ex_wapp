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
  @max_reconnect_attempts :infinity
  @health_check_interval_ms 30_000

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

        # Handle other IQ types through pairing
        true ->
          {pairing, actions} = Pairing.apply_node(state.pairing, node)

          pairing =
            case maybe_reset_pairing(actions, pairing) do
              {:ok, new_pairing} -> new_pairing
              :noop -> pairing
            end

          {%{state | pairing: pairing}, actions}
      end
    end
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

  defp handle_connection_node(%Binary.Node{tag: "success", attrs: attrs}, state) do
    Logger.info("[SESSION] Received success node - login successful!")

    # Store LID if present
    lid = Map.get(attrs, "lid")

    if lid do
      Logger.info("[SESSION] LID from success: #{inspect(lid)}")
      # TODO: Store LID in session data
    end

    # Reference: whatsmeow/connectionevents.go handleConnectSuccess()
    # After success, we need to:
    # 1. Check/upload prekeys (CRITICAL for device linking!)
    # 2. Send SetPassive(false)

    prekey_actions =
      case ExWapp.Prekeys.build_prekey_upload(state.store, initial: true) do
        {:ok, prekey_node, prekeys} ->
          persist_uploaded_prekeys(state.store, prekeys)
          Logger.info("[SESSION] Uploading initial prekeys")
          [{:send_node, prekey_node}]

        {:error, reason} ->
          Logger.warning("[SESSION] Cannot upload prekeys: #{inspect(reason)}")
          []
      end

    passive_iq = build_set_passive_iq(false)

    actions = prekey_actions ++ [{:send_node, passive_iq}]
    Logger.info("[SESSION] Sending #{length(actions)} post-success actions")
    {state, actions}
  end

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
        code == "401" and conflict_type == "device_removed" ->
          Logger.error("[SESSION] Device was removed! Need to re-pair from scratch.")
          Logger.error("[SESSION] Delete session file and scan QR code again.")
          notify_qr(state, {:error, :device_removed})
          state

        code == "515" ->
          Logger.warning("[SESSION] Got 515, will reconnect...")
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

  defp build_receipt_ack(to, id, participant, type) do
    attrs = %{
      "id" => id,
      "to" => to,
      "type" => type
    }

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

  defp handle_pairing_action(_action, _state), do: :ok

  # ============================================================================
  # Message Sending
  # ============================================================================

  # Worker function - runs in a separate process so it can wait for IQ responses
  defp do_send_text_worker(session_pid, state, jid, text) do
    jid = normalize_jid_for_signal(jid)

    case ensure_signal_session_worker(state, jid) do
      {:ok, updated_sessions, prekey_bundles} ->
        # Now send with encryption
        do_send_encrypted(session_pid, state, updated_sessions, jid, text, prekey_bundles)

      {:error, reason} ->
        {:error, {:session_failed, reason}}
    end
  end

  defp ensure_signal_session_worker(state, jid) do
    signal_sessions = state.signal_sessions || ExWapp.Signal.SessionStore.new()

    if ExWapp.Signal.SessionStore.has_session?(signal_sessions, jid) do
      Logger.info("[SEND] Have session for #{jid}")
      {:ok, signal_sessions, %{}}
    else
      Logger.info("[SEND] No session for #{jid}, fetching prekeys...")
      fetch_prekeys_worker(state, jid, signal_sessions)
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

  defp process_prekey_response(store, response_node, jid, signal_sessions) do
    case parse_prekey_response(response_node) do
      {:ok, bundles} ->
        Logger.info("[PREKEY] Parsed #{length(bundles)} prekey bundles, creating sessions")

        # Get local identity
        data = Store.load!(store)
        signal_data = Map.get(data, :signal, %{})
        local_identity = Map.get(signal_data, :identity_key)
        local_reg_id = Map.get(signal_data, :registration_id, 0)

        if local_identity do
          create_sessions_for_bundles(
            signal_sessions,
            jid,
            bundles,
            local_identity,
            local_reg_id
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
         prekey_bundles
       ) do
    message_id = ExWapp.Messages.generate_id()
    timestamp = System.system_time(:second)

    proto = ExWapp.Messages.build_text_proto(text, [])

    case ExWapp.Proto.Message.encode(proto) do
      {:ok, payload} ->
        padded_payload = ExWapp.Signal.Encryption.pad_message(payload)

        targets = resolve_encryption_targets(signal_sessions, jid, prekey_bundles || %{})

        Logger.info("[SEND] Encrypting for #{length(targets)} targets: #{inspect(targets)}")

        case encrypt_for_targets(
               store,
               signal_sessions,
               targets,
               padded_payload,
               prekey_bundles || %{}
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
                include_identity
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
         local_reg_id
       ) do
    requested_jid = normalize_jid_for_signal(requested_jid)

    case Enum.reduce_while(
           bundles,
           {:ok, signal_sessions, %{}, false},
           fn bundle, {:ok, sessions, bundle_map, aliased_requested_jid?} ->
             device_jid =
               bundle
               |> Map.get(:device_jid, requested_jid)
               |> normalize_jid_with_device()

             device_jid = if device_jid == "", do: requested_jid, else: device_jid

             Logger.info(
               "[PREKEY] Creating session for device_jid=#{device_jid} (request_jid=#{requested_jid})"
             )

             case ExWapp.Signal.SessionStore.get_or_create_session(
                    sessions,
                    device_jid,
                    local_identity,
                    bundle,
                    local_reg_id
                  ) do
               {:ok, created_session, base_key, updated_sessions} ->
                 updated_sessions =
                   if aliased_requested_jid? do
                     updated_sessions
                   else
                     maybe_alias_signal_session(
                       updated_sessions,
                       requested_jid,
                       device_jid,
                       created_session
                     )
                   end

                 Logger.info(
                   "[PREKEY] Session ready for #{device_jid}, base_key=#{if base_key, do: byte_size(base_key), else: "nil"} bytes"
                 )

                 bundle_with_info =
                   bundle
                   |> Map.put(:base_key, base_key)
                   |> Map.put(:device_jid, device_jid)

                 {:cont,
                  {:ok, updated_sessions, Map.put(bundle_map, device_jid, bundle_with_info), true}}

               {:error, reason} ->
                 {:halt, {:error, {:session_create_failed, device_jid, reason}}}
             end
           end
         ) do
      {:ok, updated_sessions, bundle_map, _aliased_requested_jid?}
      when map_size(bundle_map) > 0 ->
        {:ok, updated_sessions, bundle_map}

      {:ok, _updated_sessions, _bundle_map, _aliased_requested_jid?} ->
        {:error, :no_sessions_created}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp resolve_encryption_targets(signal_sessions, jid, prekey_bundles) do
    targets =
      cond do
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

    targets
    |> Enum.map(&normalize_jid_with_device/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> drop_base_alias_targets()
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

  defp encrypt_for_targets(store, signal_sessions, targets, padded_payload, prekey_bundles) do
    result =
      Enum.reduce(
        targets,
        %{nodes: [], sessions: signal_sessions, include_identity: false, errors: []},
        fn target_jid, acc ->
          target_jid = normalize_jid_with_device(target_jid)
          bundle = Map.get(prekey_bundles, target_jid, %{})
          bundle_for_encrypt = if is_binary(Map.get(bundle, :base_key)), do: bundle, else: %{}

          case ExWapp.Signal.Encryption.encrypt_for_recipient_sync(
                 store,
                 acc.sessions,
                 target_jid,
                 padded_payload,
                 bundle_for_encrypt
               ) do
            {:ok, ciphertext, enc_type, updated_sessions} ->
              node = build_participant_encrypted_node(target_jid, ciphertext, enc_type)

              %{
                acc
                | nodes: [node | acc.nodes],
                  sessions: updated_sessions,
                  include_identity: acc.include_identity or enc_type == :prekey
              }

            {:error, reason} ->
              Logger.warning(
                "[SEND] Failed to encrypt for target=#{target_jid}: #{inspect(reason)}"
              )

              %{acc | errors: [{target_jid, reason} | acc.errors]}
          end
        end
      )

    if result.nodes == [] do
      {:error, {:no_encrypted_targets, Enum.reverse(result.errors)}}
    else
      {:ok, Enum.reverse(result.nodes), result.sessions, result.include_identity}
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
         timestamp,
         store,
         include_identity
       ) do
    attrs = %{
      "id" => message_id,
      "to" => strip_device_from_jid(jid),
      "type" => "text",
      "t" => Integer.to_string(timestamp)
    }

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

    %Binary.Node{
      tag: "message",
      attrs: attrs,
      content: content
    }
  end

  # Main entry point - ensures session exists before sending (deprecated, use worker)
  defp do_send_text_with_session(
         %{status: :connected, conn: conn, store: store} = state,
         jid,
         text
       )
       when is_pid(conn) do
    # Normalize JID
    jid = normalize_jid_for_signal(jid)

    # Get current signal sessions
    signal_sessions = state.signal_sessions || ExWapp.Signal.SessionStore.new()

    # Check if we have a session
    if ExWapp.Signal.SessionStore.has_session?(signal_sessions, jid) do
      Logger.info("[SEND] Have session for #{jid}, encrypting directly")
      {do_send_text(state, jid, text), state}
    else
      # Need to fetch prekeys and create session
      Logger.info("[SEND] No session for #{jid}, fetching prekeys...")

      case fetch_prekeys_and_create_session(state, jid) do
        {:ok, updated_state} ->
          Logger.info("[SEND] Session created, now encrypting")
          {do_send_text(updated_state, jid, text), updated_state}

        {:error, reason} ->
          Logger.error("[SEND] Failed to create session: #{inspect(reason)}")
          {{:error, {:session_creation_failed, reason}}, state}
      end
    end
  end

  defp do_send_text_with_session(%{status: status} = state, _jid, _text) do
    {{:error, {:not_connected, status}}, state}
  end

  # Fetch prekeys from server and create a Signal session
  defp fetch_prekeys_and_create_session(%{conn: conn, store: store} = state, jid) do
    Logger.info("[PREKEY] Fetching prekeys for #{jid}")

    # Build prekey request
    message_id = generate_request_id()
    request_node = build_prekey_request(jid, message_id)

    # Send and wait for response (blocking)
    case send_and_wait_for_iq(state, request_node, message_id, 30_000) do
      {:ok, response_node} ->
        Logger.info("[PREKEY] Got prekey response")

        # Parse the prekey bundle
        case parse_prekey_response(response_node) do
          {:ok, [bundle | _]} ->
            Logger.info("[PREKEY] Parsed bundle for #{jid}")

            # Get local identity key
            data = Store.load!(store)
            signal_data = Map.get(data, :signal, %{})
            local_identity = Map.get(signal_data, :identity_key)
            local_reg_id = Map.get(signal_data, :registration_id, 0)

            if local_identity do
              # Create session using X3DH
              signal_sessions = state.signal_sessions || ExWapp.Signal.SessionStore.new()

              case ExWapp.Signal.SessionStore.get_or_create_session(
                     signal_sessions,
                     jid,
                     local_identity,
                     bundle,
                     local_reg_id
                   ) do
                {:ok, _session, _base_key, updated_sessions} ->
                  Logger.info("[PREKEY] Session created for #{jid}")
                  {:ok, %{state | signal_sessions: updated_sessions}}

                {:error, reason} ->
                  {:error, {:session_create_failed, reason}}
              end
            else
              {:error, :no_local_identity}
            end

          {:error, reason} ->
            {:error, {:prekey_parse_failed, reason}}
        end

      {:error, reason} ->
        {:error, {:prekey_fetch_failed, reason}}
    end
  end

  # Send IQ and wait for response synchronously
  # Uses an Agent to communicate between the IQ handler and this function
  defp send_and_wait_for_iq(%{conn: conn} = state, node, message_id, timeout) do
    # Create a simple agent to store the response
    {:ok, agent} = Agent.start_link(fn -> nil end)

    # Store the agent in process dictionary so IQ handler can find it
    Process.put({:iq_callback, message_id}, agent)

    # Send the IQ
    case send_transport_node(state, conn, node) do
      :ok ->
        # Poll for response
        result = poll_for_iq_response(agent, message_id, timeout)

        # Cleanup
        Process.delete({:iq_callback, message_id})
        Agent.stop(agent)

        result

      error ->
        Process.delete({:iq_callback, message_id})
        Agent.stop(agent)
        error
    end
  end

  defp poll_for_iq_response(agent, message_id, timeout) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_poll_for_iq_response(agent, message_id, deadline)
  end

  defp do_poll_for_iq_response(agent, message_id, deadline) do
    now = System.monotonic_time(:millisecond)

    if now >= deadline do
      {:error, :timeout}
    else
      case Agent.get(agent, & &1) do
        nil ->
          # Not received yet, sleep briefly and retry
          Process.sleep(50)
          do_poll_for_iq_response(agent, message_id, deadline)

        response ->
          {:ok, response}
      end
    end
  end

  defp build_prekey_request(jid, message_id) do
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
          content: [
            %Binary.Node{
              tag: "user",
              attrs: %{"jid" => jid},
              content: nil
            }
          ]
        }
      ]
    }
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

  defp do_send_text(%{status: :connected, conn: conn, store: store} = state, jid, text)
       when is_pid(conn) do
    message_id = ExWapp.Messages.generate_id()
    timestamp = System.system_time(:second)

    # Build the message proto
    proto = ExWapp.Messages.build_text_proto(text, [])

    case ExWapp.Proto.Message.encode(proto) do
      {:ok, payload} ->
        # Pad the payload for encryption
        padded_payload = ExWapp.Signal.Encryption.pad_message(payload)

        # Encrypt with Signal protocol (pass store directly to avoid deadlock)
        case ExWapp.Signal.Encryption.encrypt_for_recipient_sync(
               store,
               state.signal_sessions,
               jid,
               padded_payload
             ) do
          {:ok, encrypted, enc_type, _updated_sessions} ->
            # Build the encrypted message node (no device identity for existing sessions)
            node =
              build_encrypted_message_node(
                jid,
                message_id,
                encrypted,
                enc_type,
                timestamp,
                store,
                enc_type == :prekey
              )

            # TODO: Save updated_sessions back to state

            # Record the outgoing message
            message = %{
              id: message_id,
              from_me: true,
              timestamp: timestamp,
              text: text,
              status: :pending,
              participant: nil,
              raw: nil
            }

            ExWapp.Chat.add_message(store, jid, message)

            # Send via connection
            case send_transport_node(state, conn, node) do
              :ok ->
                Logger.info("Sent encrypted message to #{jid}: #{message_id}")
                {:ok, message_id}

              error ->
                error
            end

          {:error, :no_identity_key} ->
            # No identity key - can't encrypt
            Logger.warning("No encryption keys, cannot send encrypted message")
            {:error, :no_identity_key}

          {:error, :no_session} ->
            # No session for recipient - would need to fetch prekeys
            # For now, fall back to unencrypted (WhatsApp will reject this)
            Logger.warning("No Signal session for #{jid}, sending unencrypted (will likely fail)")
            node = ExWapp.Messages.build_message_node(jid, message_id, payload, timestamp, [])

            case send_transport_node(state, conn, node) do
              :ok -> {:ok, message_id}
              error -> error
            end

          {:error, reason} ->
            {:error, {:encryption_failed, reason}}
        end

      {:error, reason} ->
        {:error, {:proto_encode, reason}}
    end
  end

  defp do_send_text(%{status: status}, _jid, _text) do
    {:error, {:not_connected, status}}
  end

  defp build_encrypted_message_node(
         jid,
         message_id,
         ciphertext,
         enc_type,
         timestamp,
         store,
         include_identity
       ) do
    type_str = enc_type_to_wire(enc_type)
    base_jid = strip_device_from_jid(jid)

    attrs = %{
      "id" => message_id,
      "to" => base_jid,
      "type" => "text",
      "t" => Integer.to_string(timestamp)
    }

    enc_node = %Binary.Node{
      tag: "enc",
      attrs: %{
        "v" => "2",
        "type" => type_str
      },
      content: Binary.raw(ciphertext)
    }

    # Wrap enc node in participants -> to
    participants_node = %Binary.Node{
      tag: "participants",
      attrs: %{},
      content: [
        %Binary.Node{
          tag: "to",
          attrs: %{"jid" => jid},
          content: [enc_node]
        }
      ]
    }

    # For prekey messages, include device-identity as sibling to participants
    content =
      if include_identity and enc_type == :prekey do
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

    %Binary.Node{
      tag: "message",
      attrs: attrs,
      content: content
    }
  end

  defp get_device_identity_node(store) do
    data = Store.load!(store)

    # Prefer the validated self-signed ADV payload from pairing.
    # Re-encoding from partially decoded structs can drift from the original payload.
    case Map.get(data, :pairing) do
      %{adv_self_signed: payload} when is_binary(payload) ->
        Logger.info("[SEND] Using adv_self_signed device identity: #{byte_size(payload)} bytes")

        node = %Binary.Node{
          tag: "device-identity",
          attrs: %{},
          content: Binary.raw(payload)
        }

        {:ok, node}

      %{adv: %{signed: signed}} ->
        case ExWapp.Pairing.ADV.encode_signed_device_identity(
               signed,
               include_signature_key: true
             ) do
          {:ok, payload} ->
            Logger.info("[SEND] Using encoded ADV signed identity: #{byte_size(payload)} bytes")

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
