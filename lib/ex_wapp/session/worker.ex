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

  alias ExWapp.{Binary, Pairing, Store, Telemetry}

  alias ExWapp.Session.{InboundRouter, JIDUtils, OutboundQueue}

  alias ExWapp.Session.Worker.{
    NodeHandler,
    Outbound,
    OutboundConfirmation,
    Resilience,
    Retry,
    Subscribers
  }

  @health_check_interval_ms 30_000
  @max_outgoing_retry_attempts 2
  @silent_drop_confirm_timeout_ms 6_000

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
  Returns the session_id for this worker (set at start_link via `:session_id` option).

  Returns `nil` when no explicit session_id was provided.
  """
  @spec get_session_id(GenServer.server()) :: term() | nil
  def get_session_id(server), do: GenServer.call(server, :get_session_id)

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

    # Register with Registry and subscribe to PubSub commands if session_id provided
    if session_id do
      Registry.register(ExWapp.Session.Registry, session_id, self())

      try do
        Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:commands:#{session_id}")
      rescue
        _ -> :ok
      end
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

  def handle_call(:get_session_id, _from, state) do
    {:reply, state.session_id, state}
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

  # PubSub send command - dispatched via ExWapp.send_message("session_id", jid, text)
  def handle_info({:ex_wapp_send, jid, text}, state) do
    session_pid = self()

    case start_send_worker(
           state,
           jid,
           fn ->
             result = do_send_text_worker(session_pid, state, jid, text)
             send(session_pid, {:send_result, jid, text, result, :primary, 0})
             result
           end
         ) do
      {:ok, worker, mon} ->
        {:noreply,
         state |> register_send_worker(worker, mon, jid) |> update_stats(:messages_sent)}

      {:error, reason} ->
        Logger.warning("[SESSION] PubSub send failed for #{jid}: #{inspect(reason)}")
        {:noreply, state}
    end
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
    {new_state, actions} = NodeHandler.safe_handle_node(node, state)
    Enum.each(actions, &NodeHandler.safe_handle_action(&1, new_state))
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

        new_state =
          OutboundConfirmation.handle_timeout(
            state,
            message_id,
            confirmation,
            &start_send_worker/3,
            &do_send_text_worker/5,
            &register_send_worker/4
          )

        {:noreply, new_state}
    end
  end

  # NodeHandler delegates stream:error "replaced" back to Worker
  def handle_info({:restart_connection, reason}, state) do
    {:noreply, restart_connection_now(state, reason)}
  end

  def handle_info(msg, state) do
    Logger.debug("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Session terminating: #{inspect(reason)}")
    emit_telemetry(:terminate, %{reason: reason}, state)
    Subscribers.broadcast_lifecycle(state.session_id, {:ex_wapp_session, :terminated, reason})

    if state.session_id do
      try do
        Phoenix.PubSub.unsubscribe(ExWapp.PubSub, "ex_wapp:commands:#{state.session_id}")
      rescue
        _ -> :ok
      end
    end

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
    Subscribers.broadcast_lifecycle(state.session_id, {:ex_wapp_session, :disconnected, reason})

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
    Subscribers.broadcast_lifecycle(state.session_id, {:ex_wapp_session, :connected})

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

  defp schedule_outbound_confirmation(state, jid, text, message_id, strategy, attempt) do
    OutboundConfirmation.schedule(state, jid, text, message_id, strategy, attempt,
      timeout_ms: @silent_drop_confirm_timeout_ms
    )
  end

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
