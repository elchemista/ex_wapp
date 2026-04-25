defmodule ExWapp.Session.Worker do
  @moduledoc """
  Coordinates the lifecycle of a WhatsApp Web connection.

  When started with `runtime.ownership.vext_managed: true`, the worker behaves
  as a transport engine only: it still emits raw lifecycle facts, but leaves
  reconnect and product-level stop policy to the external owner.

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

  alias ExWapp.AppState.Engine
  alias ExWapp.{Binary, Config, Pairing, Quota, RateLimiter, Store, Telemetry}
  alias ExWapp.Signal.SessionStore

  alias ExWapp.Session.{InboundRouter, JIDUtils, OutboundQueue}

  alias ExWapp.Session.Worker.{
    NodeHandler,
    Outbound,
    OutboundConfirmation,
    Resilience,
    Retry,
    Safety,
    Subscribers
  }

  @typedoc "Human readable events emitted during the pairing flow."
  @type qr_event :: {:code, String.t()} | :success | {:error, term()}

  @typedoc "Session status"
  @type status :: :idle | :connecting | :handshaking | :connected | :disconnected

  @default_send_health %{
    paused: false,
    hard_stopped: false,
    send_errors_total: 0,
    consecutive_send_errors: 0,
    retries_total: 0,
    drops_total: 0,
    outbound_queue_errors_total: 0,
    guard_trips: 0,
    last_error_reason: nil,
    last_error_at_ms: nil,
    last_guard_action: nil,
    last_guard_reason: nil,
    errors_window_ms: [],
    drops_window_ms: []
  }

  @max_outgoing_retry_payloads 512

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
    runtime_cfg: %{},
    send_health: @default_send_health,
    rate_limiter: %{},
    quota: %{},
    safety: %{},
    reconnect_attempts: 0,
    last_disconnect_reason: nil,
    connected_at: nil,
    transport_ready?: false,
    server_time_offset_ms: 0,
    session_invalid: false,
    pending_iqs: %{},
    signal_sessions: nil,
    retry_counters: %{},
    outgoing_retry_payloads: %{},
    outbound_confirmations: %{},
    app_state_initial_sync_requested: false,
    post_auth_phase: :idle,
    prekey_count_query_id: nil,
    prekey_upload_iq_id: nil,
    pending_prekey_upload: [],
    passive_iq_id: nil,
    digest_iq_id: nil,
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
          runtime_cfg: map(),
          send_health: map(),
          rate_limiter: map(),
          quota: map(),
          safety: map(),
          pairing: Pairing.state(),
          reconnect_attempts: non_neg_integer(),
          last_disconnect_reason: term() | nil,
          connected_at: DateTime.t() | nil,
          transport_ready?: boolean(),
          server_time_offset_ms: integer(),
          app_state_initial_sync_requested: boolean(),
          post_auth_phase: atom(),
          prekey_count_query_id: binary() | nil,
          prekey_upload_iq_id: binary() | nil,
          pending_prekey_upload: list(),
          passive_iq_id: binary() | nil,
          digest_iq_id: binary() | nil,
          retry_counters: map(),
          outgoing_retry_payloads: map(),
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
    * `:runtime` - Runtime hardening settings override (deep-merged)
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

  @doc "Returns the resolved runtime configuration for this session."
  @spec get_runtime_config(GenServer.server()) :: map()
  def get_runtime_config(server), do: GenServer.call(server, :get_runtime_config)

  @doc "Returns current policy status (safety, quota, rate limiter snapshots)."
  @spec get_policy_status(GenServer.server()) :: map()
  def get_policy_status(server), do: GenServer.call(server, :get_policy_status)

  @doc "Returns current send health counters/guard state."
  @spec get_health_status(GenServer.server()) :: map()
  def get_health_status(server), do: GenServer.call(server, :get_health_status)

  @doc "Pause outbound sends for this session."
  @spec pause_sends(GenServer.server()) :: :ok
  def pause_sends(server), do: GenServer.cast(server, :pause_sends)

  @doc "Resume outbound sends for this session."
  @spec resume_sends(GenServer.server()) :: :ok
  def resume_sends(server), do: GenServer.cast(server, :resume_sends)

  @doc "Stops the session worker immediately."
  @spec stop_worker(GenServer.server()) :: :ok
  def stop_worker(server), do: GenServer.cast(server, :stop_worker)

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
  @spec send_text(GenServer.server(), binary(), iodata()) :: {:ok, String.t()} | {:error, term()}
  def send_text(server, jid, text) do
    GenServer.call(server, {:send_text, jid, IO.iodata_to_binary(text)})
  end

  @doc "Send an app state mutation (server-synced)."
  @spec send_app_state(GenServer.server(), map()) :: {:ok, map(), map()} | {:error, term()}
  def send_app_state(server, patch_info) do
    GenServer.call(server, {:app_state_mutation, patch_info}, 30_000)
  end

  @doc "Archive a chat (server-synced)."
  @spec archive_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def archive_chat(server, jid) do
    patch = ExWapp.AppState.Engine.build_archive(jid, true)

    case send_app_state(server, patch) do
      {:ok, _, _} -> :ok
      error -> error
    end
  end

  @doc "Unarchive a chat (server-synced)."
  @spec unarchive_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def unarchive_chat(server, jid) do
    patch = ExWapp.AppState.Engine.build_archive(jid, false)

    case send_app_state(server, patch) do
      {:ok, _, _} -> :ok
      error -> error
    end
  end

  @doc "Delete a chat (server-synced)."
  @spec delete_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def delete_chat(server, jid) do
    patch = ExWapp.AppState.Engine.build_delete_chat(jid)

    case send_app_state(server, patch) do
      {:ok, _, _} -> :ok
      error -> error
    end
  end

  @doc "Create or update a contact (server-synced)."
  @spec create_contact(GenServer.server(), String.t(), String.t()) :: :ok | {:error, term()}
  def create_contact(server, jid, name) do
    patch = ExWapp.AppState.Engine.build_contact(jid, name)

    case send_app_state(server, patch) do
      {:ok, _, _} -> :ok
      error -> error
    end
  end

  @doc "Delete a contact (server-synced)."
  @spec delete_contact(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def delete_contact(server, jid) do
    patch = ExWapp.AppState.Engine.build_delete_contact(jid)

    case send_app_state(server, patch) do
      {:ok, _, _} -> :ok
      error -> error
    end
  end

  @doc "Fetch and apply the contact app-state collection (`critical_unblock_low`)."
  @spec sync_contacts(GenServer.server()) :: :ok | {:error, term()}
  def sync_contacts(server), do: GenServer.call(server, :sync_contacts, 30_000)

  @doc "List all contacts."
  @spec list_contacts(GenServer.server()) :: [ExWapp.Contact.t()]
  def list_contacts(server), do: GenServer.call(server, :list_contacts)

  @doc "Get a specific contact by JID."
  @spec get_contact(GenServer.server(), String.t()) :: ExWapp.Contact.t() | nil
  def get_contact(server, jid), do: GenServer.call(server, {:get_contact, jid})

  @doc "Get chat info (metadata) for a JID."
  @spec get_chat_info(GenServer.server(), String.t()) ::
          {:ok, ExWapp.Chat.chat()} | {:error, :not_found}
  def get_chat_info(server, jid), do: GenServer.call(server, {:get_chat_info, jid})

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

    runtime_cfg =
      case Config.resolve(opts) do
        {:ok, cfg} ->
          cfg

        {:error, reason} ->
          raise ArgumentError, "invalid runtime config: #{inspect(reason)}"
      end

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
      OutboundQueue.start_link(
        session: self(),
        transport: transport_mod,
        max_size: Config.get(runtime_cfg, [:queue, :max_size], 10_000),
        drop_policy: Config.get(runtime_cfg, [:queue, :drop_policy], :reject_new),
        flush_batch_size: Config.get(runtime_cfg, [:queue, :flush_batch_size], 100),
        flush_tick_ms: Config.get(runtime_cfg, [:queue, :flush_tick_ms], 10)
      )

    {:ok, inbound_router} = InboundRouter.start_link(session: self())
    {:ok, send_worker_sup} = Task.Supervisor.start_link()

    state = %__MODULE__{
      opts: opts,
      runtime_cfg: runtime_cfg,
      store: store,
      transport_mod: transport_mod,
      outbound_queue: outbound_queue,
      inbound_router: inbound_router,
      send_worker_sup: send_worker_sup,
      session_id: session_id,
      pairing: Pairing.new(store),
      signal_sessions: load_persisted_signal_sessions(store),
      rate_limiter: RateLimiter.new(),
      quota: Quota.new(runtime_cfg),
      safety: Safety.new()
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

  def handle_call({:send_text, _jid, _text}, _from, %{status: status} = state)
      when status != :connected do
    {:reply, {:error, {:not_connected, status}}, state}
  end

  def handle_call({:send_text, _jid, _text}, _from, %{conn: conn} = state)
      when not is_pid(conn) do
    {:reply, {:error, {:not_connected, state.status}}, state}
  end

  def handle_call({:send_text, jid, text}, from, state) do
    with {:ok, state} <- ensure_send_enabled(state, jid),
         {:ok, policy_state} <- enforce_send_policies(state, jid) do
      # Spawn a worker to handle the full send flow (including prekey fetch if needed)
      # This allows us to wait for IQ responses without blocking the GenServer
      session_pid = self()

      case start_send_worker(
             policy_state,
             jid,
             primary_send_task_fun(session_pid, policy_state, jid, text, :primary, 0),
             from
           ) do
        {:ok, worker, mon} ->
          new_state = register_send_worker(policy_state, worker, mon, jid)

          {:noreply, update_stats(new_state, :messages_sent)}

        {:error, reason} ->
          {:reply, {:error, {:send_worker_start_failed, reason}}, policy_state}
      end
    else
      {:error, reason, blocked_state} ->
        {:reply, {:error, reason}, blocked_state}
    end
  end

  def handle_call(:get_store, _from, state) do
    {:reply, state.store, state}
  end

  def handle_call(:get_runtime_config, _from, state) do
    {:reply, state.runtime_cfg, state}
  end

  def handle_call(:get_policy_status, _from, state) do
    {:reply, policy_status(state), state}
  end

  def handle_call(:get_health_status, _from, state) do
    {:reply, state.send_health, state}
  end

  def handle_call(:get_session_id, _from, state) do
    {:reply, state.session_id, state}
  end

  def handle_call(:get_conn, _from, state) do
    {:reply, state.conn, state}
  end

  def handle_call({:send_iq, node, message_id}, from, %{status: :connected, conn: conn} = state)
      when is_pid(conn) do
    max_pending = Config.get(state.runtime_cfg, [:iq, :max_pending_requests], 1_000)

    if map_size(state.pending_iqs) >= max_pending do
      {:reply, {:error, :too_many_pending_iq_requests}, state}
    else
      # Send the IQ node
      case state.transport_mod.send_node(conn, node) do
        :ok ->
          # Register pending IQ with timeout
          timeout_ms = Config.get(state.runtime_cfg, [:iq, :default_timeout_ms], 30_000)
          timer = Process.send_after(self(), {:iq_timeout, message_id}, timeout_ms)
          pending = %{from: from, timer: timer}
          new_state = %{state | pending_iqs: Map.put(state.pending_iqs, message_id, pending)}
          {:noreply, new_state}

        error ->
          {:reply, error, state}
      end
    end
  end

  def handle_call({:send_iq, _node, _message_id}, _from, state) do
    {:reply, {:error, {:not_connected, state.status}}, state}
  end

  # ── App State Sync Operations ──

  def handle_call({:app_state_mutation, patch_info}, from, %{status: :connected} = state) do
    session_pid = self()

    # Spawn a worker to avoid deadlock: send_mutation calls GenServer.call(session, {:send_iq, ...})
    # which would deadlock if run inside handle_call of the same GenServer.
    case start_send_worker(
           state,
           "app_state_mutation",
           fn ->
             try do
               ExWapp.AppState.Engine.send_mutation(session_pid, patch_info, state.store)
             rescue
               e -> {:error, {:exception, e}}
             end
           end,
           from
         ) do
      {:ok, worker, mon} ->
        new_state =
          state
          |> Map.update(:send_workers, %{worker => "app_state"}, fn workers ->
            Map.put(workers, worker, "app_state")
          end)
          |> Map.update(:send_worker_mons, %{mon => worker}, fn mons ->
            Map.put(mons, mon, worker)
          end)

        {:noreply, new_state}

      {:error, reason} ->
        {:reply, {:error, {:send_worker_start_failed, reason}}, state}
    end
  end

  def handle_call({:app_state_mutation, _patch_info}, _from, state) do
    {:reply, {:error, {:not_connected, state.status}}, state}
  end

  def handle_call(:sync_contacts, from, %{status: :connected} = state) do
    session_pid = self()

    case start_send_worker(
           state,
           "app_state_sync_contacts",
           fn ->
             try do
               Engine.fetch_collection(session_pid, state.store, "critical_unblock_low")
             rescue
               e -> {:error, {:exception, e}}
             end
           end,
           from
         ) do
      {:ok, worker, mon} ->
        {:noreply, register_send_worker(state, worker, mon, "app_state_sync_contacts")}

      {:error, reason} ->
        {:reply, {:error, {:send_worker_start_failed, reason}}, state}
    end
  end

  def handle_call(:sync_contacts, _from, state) do
    {:reply, {:error, {:not_connected, state.status}}, state}
  end

  def handle_call(:list_contacts, _from, state) do
    {:reply, ExWapp.Contact.list(state.store), state}
  end

  def handle_call({:get_contact, jid}, _from, state) do
    {:reply, ExWapp.Contact.get(state.store, jid), state}
  end

  def handle_call({:get_chat_info, jid}, _from, state) do
    {:reply, ExWapp.Chat.get(state.store, jid), state}
  end

  def handle_call(:get_signal_sessions, _from, state) do
    {:reply, state.signal_sessions, state}
  end

  def handle_call({:update_signal_sessions, sessions}, _from, state) do
    persist_signal_sessions_store(state.store, sessions)
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

  def handle_cast(:pause_sends, state) do
    new_state =
      state
      |> health_put(:paused, true)
      |> health_put(:last_guard_action, :pause)

    broadcast_health_event(new_state, :control, %{action: :pause_sends})
    {:noreply, new_state}
  end

  def handle_cast(:resume_sends, state) do
    new_state =
      state
      |> health_put(:paused, false)
      |> health_put(:consecutive_send_errors, 0)
      |> health_put(:last_guard_action, :resume)

    broadcast_health_event(new_state, :control, %{action: :resume_sends})
    {:noreply, new_state}
  end

  def handle_cast(:stop_worker, state) do
    broadcast_health_event(state, :control, %{action: :stop_worker})
    {:stop, {:control, :stop_worker}, state}
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
    Logger.debug("Reconnection attempt #{attempt}")
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
    Logger.debug(
      "[SESSION] connection_event session_id=#{state.session_id} event=#{inspect(event, limit: 80)} status_before=#{inspect(state.status)} post_auth_phase=#{inspect(state.post_auth_phase)}"
    )

    new_state = handle_connection_event(event, state)

    Logger.debug(
      "[SESSION] connection_event handled session_id=#{state.session_id} event=#{inspect(event, limit: 80)} status_after=#{inspect(new_state.status)} post_auth_phase=#{inspect(new_state.post_auth_phase)}"
    )

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
    with {:ok, state} <- ensure_send_enabled(state, jid),
         {:ok, policy_state} <- enforce_send_policies(state, jid) do
      session_pid = self()

      case start_send_worker(
             policy_state,
             jid,
             primary_send_task_fun(session_pid, policy_state, jid, text, :primary, 0)
           ) do
        {:ok, worker, mon} ->
          {:noreply,
           policy_state
           |> register_send_worker(worker, mon, jid)
           |> update_stats(:messages_sent)}

        {:error, reason} ->
          Logger.warning("[SESSION] PubSub send failed for #{jid}: #{inspect(reason)}")
          {:noreply, policy_state}
      end
    else
      {:error, reason, blocked_state} ->
        Logger.warning("[SESSION] PubSub send blocked for #{jid}: #{inspect(reason)}")
        {:noreply, blocked_state}
    end
  end

  def handle_info({:ex_wapp_control, action}, state) do
    case apply_control_action(state, action, :pubsub_command) do
      {:noreply, new_state} -> {:noreply, new_state}
      {:stop, reason, new_state} -> {:stop, reason, new_state}
    end
  end

  # New message received - notify subscribers
  def handle_info({:new_message, jid, message}, state) do
    Logger.info(
      "[WORKER] New message from=#{inspect(jid)} id=#{Map.get(message, :id)} text=#{inspect(String.slice(Map.get(message, :text, "") || "", 0, 80))} session_id=#{state.session_id}"
    )

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
    maybe_log_inbound_node(node)

    {new_state, actions} = NodeHandler.safe_handle_node(node, state)
    Enum.each(actions, &NodeHandler.safe_handle_action(&1, new_state))
    {:noreply, new_state}
  end

  # App state sync notification — triggered by MessageHandler when server pushes
  # collection changes from another device
  def handle_info({:app_state_sync_collections, collection_names}, %{status: :connected} = state)
      when is_list(collection_names) do
    refresh_app_state_collections(self(), state.store, collection_names, :notification)

    {:noreply, state}
  end

  def handle_info(
        {:app_state_initial_sync, _collection_names},
        %{status: :connected, app_state_initial_sync_requested: true} = state
      ),
      do: {:noreply, state}

  def handle_info({:app_state_initial_sync, collection_names}, %{status: :connected} = state)
      when is_list(collection_names) do
    refresh_app_state_collections(
      self(),
      state.store,
      collection_names,
      :initial,
      state.session_id
    )

    {:noreply, %{state | app_state_initial_sync_requested: true}}
  end

  def handle_info({:app_state_sync_collections, _}, state), do: {:noreply, state}

  def handle_info({:app_state_initial_sync, _}, state), do: {:noreply, state}

  def handle_info({:outbound_error, _item, reason}, state) do
    Logger.warning("[SESSION] outbound queue error: #{inspect(reason)}")
    emit_telemetry(:error, %{reason: reason, phase: :outbound}, state)
    state = update_stats(state, :errors)
    state = increment_outbound_queue_errors(state, reason)

    case maybe_apply_send_error_guard(state, {:outbound_queue_error, reason}) do
      {:continue, new_state} -> {:noreply, new_state}
      {:stop, stop_reason, new_state} -> {:stop, stop_reason, new_state}
    end
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
    session_count = sessions |> SessionStore.list_sessions() |> length()
    Logger.debug("[SEND] Async signal session update received (sessions=#{session_count})")
    persist_signal_sessions_store(state.store, sessions)
    {:noreply, %{state | signal_sessions: sessions}}
  end

  def handle_info({:retry_outgoing_message, jid, message_id}, state) do
    {:noreply, maybe_retry_outgoing_message(state, jid, message_id)}
  end

  def handle_info({:send_result, jid, text, {:ok, message_id}, strategy, attempt}, state) do
    state =
      state
      |> remember_outgoing_retry_payload(jid, text, message_id)
      |> clear_consecutive_send_errors()

    {:noreply, schedule_outbound_confirmation(state, jid, text, message_id, strategy, attempt)}
  end

  def handle_info({:send_result, jid, _text, {:error, reason}, strategy, attempt}, state) do
    state =
      register_send_error(state, {:send_failed, reason}, %{
        jid: jid,
        strategy: strategy,
        attempt: attempt
      })

    case maybe_apply_send_error_guard(state, {:send_failed, reason}) do
      {:continue, new_state} -> {:noreply, new_state}
      {:stop, stop_reason, new_state} -> {:stop, stop_reason, new_state}
    end
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
            &register_send_worker/4,
            max_silent_drop_fallback_attempts:
              Config.get(state.runtime_cfg, [:send, :max_silent_drop_fallback_attempts], 1),
            on_drop: fn jid, drop_message_id, attempt ->
              send(self(), {:silent_drop_failed, jid, drop_message_id, attempt})
            end
          )

        new_state = register_drop_timeout(new_state, message_id, confirmation)

        case maybe_apply_send_error_guard(new_state, {:drop_timeout, message_id}) do
          {:continue, guarded_state} -> {:noreply, guarded_state}
          {:stop, stop_reason, guarded_state} -> {:stop, stop_reason, guarded_state}
        end
    end
  end

  def handle_info({:silent_drop_failed, jid, message_id, attempt}, state) do
    state =
      register_send_error(
        state,
        {:silent_drop_failed, message_id},
        %{jid: jid, attempt: attempt}
      )

    case maybe_apply_send_error_guard(state, {:silent_drop_failed, message_id}) do
      {:continue, new_state} -> {:noreply, new_state}
      {:stop, stop_reason, new_state} -> {:stop, stop_reason, new_state}
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
    Logger.debug("Session terminating: #{inspect(reason)}")
    emit_telemetry(:terminate, %{reason: reason}, state)

    Subscribers.broadcast_lifecycle(
      state.session_id,
      {:ex_wapp_session, :terminated, reason, lifecycle_event_meta(state)}
    )

    if state.session_id do
      try do
        Phoenix.PubSub.unsubscribe(ExWapp.PubSub, "ex_wapp:commands:#{state.session_id}")
      rescue
        _ -> :ok
      end
    end

    flush_store(state.store)
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

        %{
          state
          | conn: conn_pid,
            conn_ref: conn_ref,
            status: :connecting,
            transport_ready?: false
        }
        |> schedule_health_check()

      {:error, reason} ->
        Logger.debug("[SESSION] ✗ Connection FAILED: #{inspect(reason)}")
        Logger.error("Failed to start connection: #{inspect(reason)}")
        emit_telemetry(:error, %{reason: reason, phase: :connect}, state)

        if vext_managed_runtime?(state) do
          disconnect_reason = {:connect_failed, reason}

          Subscribers.broadcast_lifecycle(
            state.session_id,
            {:ex_wapp_session, :disconnected, disconnect_reason, lifecycle_event_meta(state)}
          )

          state
          |> update_stats(:errors)
          |> Map.put(:status, :disconnected)
          |> Map.put(:last_disconnect_reason, disconnect_reason)
        else
          notify_qr(state, {:error, reason})
          schedule_reconnect(state, reason)
        end
    end
  end

  defp safe_start_connection(state) do
    Logger.debug("[SESSION] safe_start_connection calling transport.start_link...")

    noise_opts =
      state.opts
      |> Keyword.get(:noise, [])
      |> Keyword.put_new(
        :client_payload_fun,
        &ExWapp.Noise.ClientPayload.build(&1, state.runtime_cfg)
      )

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

    %{
      state
      | app_state_initial_sync_requested: false,
        transport_ready?: false,
        post_auth_phase: :idle,
        prekey_count_query_id: nil,
        prekey_upload_iq_id: nil,
        pending_prekey_upload: [],
        passive_iq_id: nil,
        digest_iq_id: nil
    }
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

    Subscribers.broadcast_lifecycle(
      state.session_id,
      {:ex_wapp_session, :disconnected, reason, lifecycle_event_meta(state)}
    )

    %{
      state
      | conn: nil,
        conn_ref: nil,
        status: :disconnected,
        last_disconnect_reason: reason,
        connected_at: nil,
        transport_ready?: false,
        app_state_initial_sync_requested: false,
        post_auth_phase: :idle,
        prekey_count_query_id: nil,
        prekey_upload_iq_id: nil,
        pending_prekey_upload: [],
        passive_iq_id: nil,
        digest_iq_id: nil
    }
  end

  defp handle_connection_exit(state, reason) do
    OutboundQueue.clear_conn(state.outbound_queue)

    next_state =
      state
      |> clear_pending_requests(reason)
      |> cancel_health_check()
      |> Map.merge(%{
        conn: nil,
        conn_ref: nil,
        status: :disconnected,
        last_disconnect_reason: reason,
        connected_at: nil,
        transport_ready?: false,
        app_state_initial_sync_requested: false,
        post_auth_phase: :idle,
        prekey_count_query_id: nil,
        prekey_upload_iq_id: nil,
        pending_prekey_upload: [],
        passive_iq_id: nil,
        digest_iq_id: nil
      })
      |> update_stats(:reconnects)

    emit_telemetry(:disconnected, %{reason: reason}, next_state)

    Subscribers.broadcast_lifecycle(
      next_state.session_id,
      {:ex_wapp_session, :disconnected, reason, lifecycle_event_meta(next_state)}
    )

    if vext_managed_runtime?(next_state) do
      next_state
    else
      notify_qr(next_state, {:error, {:disconnected, reason}})
      schedule_reconnect(next_state, reason)
    end
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
    reconnect_cfg = Config.get(state, [:runtime_cfg, :reconnect], %{})

    if Resilience.reconnect_enabled?(state, reconnect_cfg) do
      state
      |> do_disconnect(reason)
      |> Map.put(:reconnect_attempts, 0)
      |> schedule_connect(0)
    else
      Logger.error(
        "[SESSION] Immediate reconnect suppressed: reconnect disabled, reason=#{inspect(reason)}"
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

          notify_qr(state, {:error, :session_invalid})
          %{state | status: :idle}

        {:reconnect, attempt, delay} ->
          Logger.debug("Scheduling reconnect attempt #{attempt} in #{delay}ms")
          Process.send_after(self(), {:reconnect, attempt}, delay)

          %{state | status: :disconnected}

        :give_up ->
          Logger.error("Reconnect disabled or max reconnect attempts reached, giving up")
          notify_qr(state, {:error, :max_reconnect_attempts})
          %{state | status: :idle}
      end
    end
  end

  # ============================================================================
  # Health Monitoring
  # ============================================================================

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

  defp clear_signal_sessions_for_jid_in_memory(%{signal_sessions: nil} = state, _jid), do: state

  defp clear_signal_sessions_for_jid_in_memory(state, jid) do
    %{
      state
      | signal_sessions: clear_signal_sessions_in_store(state.signal_sessions, jid, state.store)
    }
  end

  defp clear_signal_sessions_in_store(signal_sessions, jid, store) do
    lid_mapping = ExWapp.Session.Account.load_lid_mapping(store)
    SessionStore.delete_sessions_for_user(signal_sessions, jid, lid_mapping)
  end

  defp do_health_check(%{conn: nil} = state), do: state

  defp do_health_check(%{conn: conn} = state) when is_pid(conn) do
    if Process.alive?(conn) do
      # Keepalive is a lightweight client ping.
      # Presence and passive-state assertions belong to the post-auth path, not
      # to every health tick.
      if state.status == :connected and is_pid(state.outbound_queue) do
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

  # ============================================================================
  # Connection Event Handling
  # ============================================================================

  defp handle_connection_event({:noise, :handshake_started}, state) do
    %{
      state
      | status: :handshaking,
        app_state_initial_sync_requested: false,
        transport_ready?: false
    }
  end

  defp handle_connection_event({:transport, :connected}, state) do
    %{state | status: :connecting, transport_ready?: false}
  end

  defp handle_connection_event({:transport, {:closed, reason}}, %{conn: nil} = state) do
    Logger.debug("[SESSION] Ignoring stale transport close: #{inspect(reason)}")
    state
  end

  defp handle_connection_event({:transport, {:closed, reason}}, state) do
    Logger.warning("[SESSION] Transport closed: #{inspect(reason)}")
    handle_connection_exit(state, {:transport_closed, reason})
  end

  defp handle_connection_event({:noise, :handshake_completed}, state) do
    Logger.debug("[SESSION] Noise handshake completed, waiting for post-auth success")

    state =
      %{
        state
        | status: :handshaking,
          transport_ready?: true,
          app_state_initial_sync_requested: false,
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
      {:ex_wapp_session, :transport_ready, lifecycle_event_meta(state)}
    )

    state
  end

  defp handle_connection_event({:auth, :success_received}, state) do
    Subscribers.broadcast_lifecycle(
      state.session_id,
      {:ex_wapp_session, :connected, lifecycle_event_meta(state)}
    )

    state
  end

  defp handle_connection_event({:auth, :ready}, state) do
    emit_telemetry(:connected, %{}, state)

    Subscribers.broadcast_lifecycle(
      state.session_id,
      {:ex_wapp_session, :post_auth_ready, lifecycle_event_meta(state)}
    )

    state =
      %{
        state
        | status: :connected,
          reconnect_attempts: 0,
          connected_at: DateTime.utc_now(),
          post_auth_phase: :complete
      }

    maybe_schedule_initial_app_state_sync(state)
  end

  defp handle_connection_event({:connection_message, %Binary.Node{} = node}, state) do
    InboundRouter.route(state.inbound_router, node)
    state
  end

  defp handle_connection_event({:connection_binary, _payload}, state), do: state

  defp handle_connection_event({:error, reason}, state) do
    Logger.warning("Connection error: #{inspect(reason)}")
    emit_telemetry(:error, %{reason: reason}, state)
    state = update_stats(state, :errors)

    if vext_managed_runtime?(state) do
      Subscribers.broadcast_error(state.session_id, reason)
      state
    else
      notify_qr(state, {:error, reason})
      state
    end
  end

  defp handle_connection_event(event, state) do
    Logger.debug("Unhandled connection event: #{inspect(event)}")
    state
  end

  defp maybe_retry_outgoing_message(state, jid, message_id) do
    session_pid = self()
    max_attempts = Config.get(state.runtime_cfg, [:send, :max_outgoing_retry_attempts], 2)
    retries_before = total_retry_attempts(state)

    new_state =
      Retry.maybe_retry_outgoing_message(state, jid, message_id,
        max_attempts: max_attempts,
        normalize_jid: &JIDUtils.normalize_for_signal/1,
        start_worker: &start_send_worker/3,
        outgoing_payloads: Map.get(state, :outgoing_retry_payloads, %{}),
        send_fun: fn normalized_jid, text ->
          retry_state = clear_signal_sessions_for_jid_in_memory(state, normalized_jid)

          do_send_text_worker(session_pid, retry_state, normalized_jid, text,
            retry_message_id: message_id,
            suppress_outgoing_chat_add: true
          )
        end
      )

    retries_after = total_retry_attempts(new_state)
    delta = max(retries_after - retries_before, 0)

    if delta > 0 do
      state_with_retries =
        update_in(new_state.send_health.retries_total, fn value -> (value || 0) + delta end)

      broadcast_health_event(state_with_retries, :retry, %{
        jid: jid,
        message_id: message_id,
        retries_started: delta
      })

      state_with_retries
    else
      new_state
    end
  end

  # ============================================================================
  # Message Sending
  # ============================================================================

  # Worker function - runs in a separate process so it can wait for IQ responses
  defp do_send_text_worker(session_pid, state, jid, text, opts \\ []) do
    Outbound.send_text_worker(session_pid, state, jid, text, opts)
  end

  defp primary_send_task_fun(session_pid, state, jid, text, strategy, attempt) do
    fn ->
      result = do_send_text_worker(session_pid, state, jid, text)
      send(session_pid, {:send_result, jid, text, result, strategy, attempt})
      result
    end
  end

  defp schedule_outbound_confirmation(state, jid, text, message_id, strategy, attempt)
       when is_binary(jid) and is_binary(message_id) and is_integer(attempt) and attempt >= 0 do
    confirm_timeout_ms = configured_confirm_timeout_ms(state.runtime_cfg)
    max_fallback_attempts = configured_max_fallback_attempts(state.runtime_cfg)
    normalized_text = normalize_outbound_text(text)

    OutboundConfirmation.schedule(state, jid, normalized_text, message_id, strategy, attempt,
      timeout_ms: confirm_timeout_ms,
      max_silent_drop_fallback_attempts: max_fallback_attempts
    )
  end

  defp schedule_outbound_confirmation(state, _jid, _text, _message_id, _strategy, _attempt),
    do: state

  defp remember_outgoing_retry_payload(state, jid, text, message_id)
       when is_binary(jid) and is_binary(message_id) do
    normalized_text = normalize_outbound_text(text)

    if normalized_text == "" do
      state
    else
      payloads = Map.get(state, :outgoing_retry_payloads, %{})

      updated_payloads =
        payloads
        |> Map.put(message_id, %{
          jid: JIDUtils.normalize_for_signal(jid),
          text: normalized_text,
          inserted_at_ms: System.monotonic_time(:millisecond)
        })
        |> trim_outgoing_retry_payloads()

      %{state | outgoing_retry_payloads: updated_payloads}
    end
  end

  defp remember_outgoing_retry_payload(state, _jid, _text, _message_id), do: state

  defp trim_outgoing_retry_payloads(payloads)
       when is_map(payloads) and map_size(payloads) > @max_outgoing_retry_payloads do
    payloads
    |> Enum.sort_by(fn {_message_id, payload} -> Map.get(payload, :inserted_at_ms, 0) end, :desc)
    |> Enum.take(@max_outgoing_retry_payloads)
    |> Map.new()
  end

  defp trim_outgoing_retry_payloads(payloads), do: payloads

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

  defp notify_qr(state, {:error, _} = event) do
    Subscribers.notify_qr(state, event, fn ->
      emit_telemetry(
        :qr,
        %{subscriber_count: map_size(state.qr_subscribers)},
        state,
        %{event: :error}
      )
    end)
  end

  defp remove_qr_subscriber(state, ref), do: Subscribers.remove_qr_subscriber(state, ref)

  defp cleanup_dead_subscriber(state, dead_mon),
    do: Subscribers.cleanup_dead_subscriber(state, dead_mon)

  defp vext_managed_runtime?(%{runtime_cfg: runtime_cfg}) when is_map(runtime_cfg) do
    Config.get(runtime_cfg, [:ownership, :vext_managed], false)
  end

  defp vext_managed_runtime?(_state), do: false

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

  defp load_persisted_signal_sessions(store) do
    store
    |> Store.load_signal_sessions()
    |> normalize_persisted_signal_sessions()
  rescue
    error ->
      Logger.warning("[SESSION] Failed to load persisted signal sessions: #{inspect(error)}")
      nil
  end

  defp normalize_persisted_signal_sessions(nil), do: nil
  defp normalize_persisted_signal_sessions(%SessionStore.Ref{} = persisted), do: persisted

  defp normalize_persisted_signal_sessions(%{sessions: sessions} = persisted)
       when is_map(sessions) do
    SessionStore.new()
    |> Map.merge(persisted)
    |> Map.put(:pending_prekeys, Map.get(persisted, :pending_prekeys, %{}))
    |> Map.put(:session_touched_at_ms, Map.get(persisted, :session_touched_at_ms, %{}))
  end

  defp normalize_persisted_signal_sessions(_), do: nil

  defp persist_signal_sessions_store(nil, _sessions), do: :ok

  defp persist_signal_sessions_store(store, sessions) do
    if SessionStore.store?(sessions) do
      case Store.persist_signal_sessions(store, sessions) do
        :ok ->
          flush_store(store)
          :ok

        {:error, reason} ->
          Logger.warning("[SESSION] Failed to persist signal sessions: #{inspect(reason)}")
          :ok
      end
    else
      :ok
    end
  rescue
    error ->
      Logger.warning("[SESSION] Failed to persist signal sessions: #{inspect(error)}")
      :ok
  end

  defp flush_store(nil), do: :ok

  defp flush_store(store) do
    if function_exported?(store.__struct__, :flush, 1) do
      case store.__struct__.flush(store) do
        :ok -> :ok
        {:error, reason} -> Logger.warning("[SESSION] Failed flushing store: #{inspect(reason)}")
      end
    else
      :ok
    end
  rescue
    error ->
      Logger.warning("[SESSION] Failed flushing store: #{inspect(error)}")
      :ok
  end

  defp restart_outbound_queue(state) do
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

  defp restart_inbound_router(state) do
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

  defp lifecycle_event_meta(state, extra \\ %{}) do
    extra
    |> Map.new()
    |> Map.merge(%{
      runtime_ref: self(),
      session_id: state.session_id,
      status: state.status,
      transport_ready?: state.transport_ready?,
      post_auth_phase: state.post_auth_phase
    })
  end

  defp initial_sync_event_payload(session_id, runtime_ref, payload) do
    payload
    |> Map.new()
    |> Map.merge(%{
      runtime_ref: runtime_ref,
      session_id: session_id
    })
  end

  defp start_send_worker(state, jid, fun) do
    start_send_worker(state, jid, fun, nil)
  end

  defp start_send_worker(%__MODULE__{send_worker_sup: sup}, jid, fun, from)
       when is_pid(sup) and is_function(fun, 0) do
    case Task.Supervisor.start_child(sup, fn ->
           run_send_worker_fun(fun, from)
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

  defp run_send_worker_fun(fun, from) when is_function(fun, 0) do
    result = fun.()
    if from, do: GenServer.reply(from, result)
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

  defp maybe_log_inbound_node(%Binary.Node{tag: tag}) when tag in ["iq", "chatstate"], do: :ok

  defp maybe_log_inbound_node(%Binary.Node{} = node) do
    Logger.debug(
      "[WORKER] Inbound node tag=#{node.tag} attrs=#{inspect(Map.keys(node.attrs || %{}))}"
    )
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

  defp enforce_send_policies(state, jid) do
    with {:ok, state} <- Safety.check_send_allowed(state),
         {:ok, state} <- Quota.check_and_increment(state, jid),
         {:ok, state} <- RateLimiter.check_and_update(state, jid) do
      {:ok, state}
    else
      {:error, reason, policy_state} ->
        emit_telemetry(:error, %{reason: reason, phase: :send_policy}, policy_state, %{jid: jid})
        emit_policy_telemetry(reason, jid, policy_state)
        {:error, reason, policy_state}
    end
  end

  defp policy_status(state) do
    rate_limiter = state.rate_limiter || %{}

    %{
      safety: Safety.status(state),
      quota: state.quota,
      send_health: state.send_health,
      rate_limiter: %{
        global: rate_limiter[:global],
        per_jid_keys: map_size(rate_limiter[:per_jid] || %{}),
        per_group_keys: map_size(rate_limiter[:per_group] || %{})
      }
    }
  end

  defp emit_policy_telemetry(reason, jid, state) do
    metadata = %{jid: jid, session_id: state.session_id, reason: reason}

    case reason do
      {:rate_limited, scope, retry_after_ms} ->
        :telemetry.execute(
          [:ex_wapp, :rate, :limited],
          %{count: 1, retry_after_ms: retry_after_ms},
          Map.put(metadata, :scope, scope)
        )

      {:quota_exceeded, scope} ->
        :telemetry.execute(
          [:ex_wapp, :quota, :exceeded],
          %{count: 1},
          Map.put(metadata, :scope, scope)
        )

      {:safety_cooloff, retry_after_ms} ->
        :telemetry.execute(
          [:ex_wapp, :safety, :trip],
          %{count: 1, retry_after_ms: retry_after_ms},
          metadata
        )

      :forbidden_locked ->
        :telemetry.execute([:ex_wapp, :safety, :trip], %{count: 1}, metadata)
    end
  rescue
    _ -> :ok
  end

  defp configured_confirm_timeout_ms(runtime_cfg) do
    case Config.get(runtime_cfg, [:send, :confirm_timeout_ms], 6_000) do
      value when is_integer(value) and value > 0 -> value
      _ -> 6_000
    end
  end

  defp configured_max_fallback_attempts(runtime_cfg) do
    case Config.get(runtime_cfg, [:send, :max_silent_drop_fallback_attempts], 1) do
      value when is_integer(value) and value >= 0 -> value
      _ -> 1
    end
  end

  defp normalize_outbound_text(text) when is_binary(text), do: text
  defp normalize_outbound_text(text) when is_list(text), do: IO.iodata_to_binary(text)
  defp normalize_outbound_text(_), do: ""

  defp ensure_send_enabled(state, jid) do
    cond do
      health_get(state, :hard_stopped, false) ->
        blocked_state =
          register_send_error(
            state,
            :send_guard_hard_stopped,
            %{jid: jid, source: :guard_gate}
          )

        {:error, :send_guard_hard_stopped, blocked_state}

      health_get(state, :paused, false) ->
        blocked_state = register_send_error(state, :send_paused, %{jid: jid, source: :guard_gate})
        {:error, :send_paused, blocked_state}

      true ->
        {:ok, state}
    end
  end

  defp increment_outbound_queue_errors(state, reason) do
    state =
      state
      |> health_inc(:outbound_queue_errors_total)
      |> health_put(:last_error_reason, {:outbound_queue_error, reason})
      |> health_put(:last_error_at_ms, now_ms())

    broadcast_health_event(state, :outbound_queue_error, %{reason: reason})
    state
  end

  defp clear_consecutive_send_errors(state) do
    health_put(state, :consecutive_send_errors, 0)
  end

  defp register_send_error(state, reason, metadata) when is_map(metadata) do
    now = now_ms()

    errors_window = prune_old_window([now | health_get(state, :errors_window_ms, [])], now)

    state =
      state
      |> health_inc(:send_errors_total)
      |> health_inc(:consecutive_send_errors)
      |> health_put(:errors_window_ms, errors_window)
      |> health_put(:last_error_reason, reason)
      |> health_put(:last_error_at_ms, now)

    broadcast_health_event(state, :send_error, Map.merge(%{reason: reason}, metadata))
    state
  end

  defp register_drop_timeout(state, message_id, confirmation) do
    now = now_ms()

    drops_window = prune_old_window([now | health_get(state, :drops_window_ms, [])], now)

    state =
      state
      |> health_inc(:drops_total)
      |> health_put(:drops_window_ms, drops_window)

    broadcast_health_event(state, :drop_timeout, %{
      message_id: message_id,
      jid: Map.get(confirmation, :jid),
      attempt: Map.get(confirmation, :attempt)
    })

    state
  end

  defp maybe_apply_send_error_guard(state, reason) do
    guard_cfg = Config.get(state.runtime_cfg, [:send_error_guard], %{})

    if Map.get(guard_cfg, :enabled, false) do
      apply_enabled_send_error_guard(state, reason, guard_cfg)
    else
      {:continue, state}
    end
  end

  defp apply_enabled_send_error_guard(state, reason, guard_cfg) do
    metrics = send_error_guard_metrics(state)

    case compute_guard_trigger_reason(metrics, guard_cfg) do
      nil ->
        {:continue, state}

      trigger_reason ->
        action = Map.get(guard_cfg, :action, :stop_session)
        notify_only = Map.get(guard_cfg, :notify_only, false)

        state =
          state
          |> health_inc(:guard_trips)
          |> health_put(:last_guard_action, action)
          |> health_put(:last_guard_reason, trigger_reason)

        broadcast_health_event(state, :guard_trip, %{
          action: action,
          reason: reason,
          trigger_reason: trigger_reason,
          consecutive_send_errors: metrics.consecutive,
          errors_per_minute: metrics.errors_min,
          drops_per_minute: metrics.drops_min,
          notify_only: notify_only
        })

        continue_or_apply_guard_action(state, action, trigger_reason, notify_only)
    end
  end

  defp send_error_guard_metrics(state) do
    %{
      consecutive: health_get(state, :consecutive_send_errors, 0),
      errors_min: length(health_get(state, :errors_window_ms, [])),
      drops_min: length(health_get(state, :drops_window_ms, []))
    }
  end

  defp compute_guard_trigger_reason(metrics, guard_cfg) do
    max_consecutive = Map.get(guard_cfg, :max_consecutive_errors, 3)
    max_errors_min = Map.get(guard_cfg, :max_errors_per_minute, 20)
    max_drops_min = Map.get(guard_cfg, :max_drops_per_minute, 10)

    cond do
      metrics.consecutive >= max_consecutive ->
        {:max_consecutive_errors, metrics.consecutive}

      metrics.errors_min >= max_errors_min ->
        {:max_errors_per_minute, metrics.errors_min}

      metrics.drops_min >= max_drops_min ->
        {:max_drops_per_minute, metrics.drops_min}

      true ->
        nil
    end
  end

  defp continue_or_apply_guard_action(state, _action, _trigger_reason, notify_only)
       when notify_only in [true],
       do: {:continue, state}

  defp continue_or_apply_guard_action(state, action, trigger_reason, _notify_only),
    do: apply_guard_action(state, action, trigger_reason)

  defp apply_guard_action(state, :none, _trigger_reason), do: {:continue, state}

  defp apply_guard_action(state, :pause, trigger_reason) do
    state =
      state
      |> health_put(:paused, true)
      |> health_put(:hard_stopped, false)
      |> health_put(:last_guard_reason, trigger_reason)

    {:continue, state}
  end

  defp apply_guard_action(state, :disconnect, trigger_reason) do
    state =
      state
      |> health_put(:paused, true)
      |> health_put(:hard_stopped, true)
      |> health_put(:last_guard_reason, trigger_reason)
      |> do_disconnect({:send_error_guard_trip, trigger_reason})
      |> Map.put(:status, :idle)
      |> Map.put(:reconnect_attempts, 0)

    {:continue, state}
  end

  defp apply_guard_action(state, :stop_session, trigger_reason) do
    state =
      state
      |> health_put(:paused, true)
      |> health_put(:hard_stopped, true)
      |> health_put(:last_guard_reason, trigger_reason)

    {:stop, {:send_error_guard_trip, trigger_reason}, state}
  end

  defp apply_guard_action(state, _unknown, _trigger_reason), do: {:continue, state}

  defp apply_control_action(state, :pause_sends, source) do
    state =
      state
      |> health_put(:paused, true)
      |> health_put(:last_guard_action, {:pause_sends, source})

    broadcast_health_event(state, :control, %{source: source, action: :pause_sends})
    {:noreply, state}
  end

  defp apply_control_action(state, :resume_sends, source) do
    state =
      state
      |> health_put(:paused, false)
      |> health_put(:hard_stopped, false)
      |> health_put(:consecutive_send_errors, 0)
      |> health_put(:last_guard_action, {:resume_sends, source})

    broadcast_health_event(state, :control, %{source: source, action: :resume_sends})
    {:noreply, state}
  end

  defp apply_control_action(state, :disconnect, source) do
    state =
      state
      |> do_disconnect({:control_disconnect, source})
      |> Map.put(:status, :idle)
      |> Map.put(:reconnect_attempts, 0)

    broadcast_health_event(state, :control, %{source: source, action: :disconnect})
    {:noreply, state}
  end

  defp apply_control_action(state, :stop_session, source) do
    broadcast_health_event(state, :control, %{source: source, action: :stop_session})
    {:stop, {:control, :stop_session, source}, state}
  end

  defp apply_control_action(state, action, source) do
    broadcast_health_event(state, :control, %{source: source, action: :unknown, value: action})
    {:noreply, state}
  end

  defp broadcast_health_event(state, type, metadata) when is_map(metadata) do
    Subscribers.broadcast_health(state.session_id, {:ex_wapp_health, type, metadata})
  rescue
    _ -> :ok
  end

  defp send_health(state), do: state.send_health || @default_send_health

  defp health_get(state, key, default), do: Map.get(send_health(state), key, default)

  defp health_put(state, key, value) do
    %{state | send_health: Map.put(send_health(state), key, value)}
  end

  defp health_inc(state, key, by \\ 1) do
    %{state | send_health: Map.update(send_health(state), key, by, &((&1 || 0) + by))}
  end

  defp now_ms, do: System.monotonic_time(:millisecond)

  defp prune_old_window(values, now_ms) when is_list(values) do
    threshold = now_ms - 60_000
    Enum.filter(values, &(&1 >= threshold))
  end

  defp total_retry_attempts(state) do
    state.retry_counters
    |> Map.values()
    |> Enum.sum()
  end

  defp update_stats(state, key) do
    update_in(state.stats[key], &((&1 || 0) + 1))
  end

  defp calculate_uptime(%{connected_at: nil}), do: 0

  defp calculate_uptime(%{connected_at: connected_at}) do
    DateTime.diff(DateTime.utc_now(), connected_at, :second)
  end

  defp emit_telemetry(event, measurements, state, extra_metadata \\ %{}) do
    maybe_broadcast_pubsub_error(event, measurements, extra_metadata, state)

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

  defp maybe_broadcast_pubsub_error(:error, measurements, extra_metadata, state) do
    reason =
      case {Map.get(measurements, :phase), Map.get(measurements, :reason)} do
        {phase, reason} when not is_nil(phase) and not is_nil(reason) -> {phase, reason}
        {_, reason} when not is_nil(reason) -> reason
        _ -> {:error_event, measurements, extra_metadata}
      end

    Subscribers.broadcast_error(state.session_id, reason)
  rescue
    _ -> :ok
  end

  defp maybe_broadcast_pubsub_error(_event, _measurements, _extra_metadata, _state), do: :ok

  # ============================================================================
  # App State Sync
  # ============================================================================

  defp maybe_schedule_initial_app_state_sync(state) do
    if has_app_state_keys?(state.store) do
      send(self(), {:app_state_initial_sync, Engine.all_collections()})
    else
      Logger.debug(
        "[APP_STATE] Deferring initial sync until app-state keys are available session_id=#{inspect(state.session_id)}"
      )
    end

    state
  end

  defp has_app_state_keys?(store) do
    store
    |> Store.load!()
    |> Map.get(:app_state_keys, %{})
    |> map_size()
    |> Kernel.>(0)
  rescue
    _ -> false
  end

  defp refresh_app_state_collections(
         session_pid,
         store,
         collection_names,
         source,
         session_id \\ nil
       ) do
    names =
      collection_names
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()

    spawn(fn ->
      run_app_state_collection_refresh(session_pid, store, names, source, session_id)
    end)
  end

  defp run_app_state_collection_refresh(session_pid, store, names, :initial, session_id) do
    Subscribers.broadcast_lifecycle(
      session_id,
      {:ex_wapp_session, :initial_sync, :started,
       initial_sync_event_payload(session_id, session_pid, %{collection_names: names})}
    )

    :ok = begin_store_batch(store, :initial_app_state_sync)

    {success_count, failures} =
      Enum.reduce(names, {0, []}, fn collection_name, {successes, failures} ->
        case fetch_app_state_collection(session_pid, store, collection_name) do
          :ok ->
            {successes + 1, failures}

          {:error, reason} ->
            {successes, [%{collection: collection_name, reason: reason} | failures]}
        end
      end)

    flush_result = finish_store_batch(store, :initial_app_state_sync)
    failures = Enum.reverse(failures)

    case {failures, flush_result} do
      {[], :ok} ->
        Subscribers.broadcast_lifecycle(
          session_id,
          {:ex_wapp_session, :initial_sync, :completed,
           initial_sync_event_payload(session_id, session_pid, %{
             collection_names: names,
             success_count: success_count,
             skipped: false
           })}
        )

      {failures, :ok} ->
        reason = {:collection_fetch_failed, failures}

        Subscribers.broadcast_lifecycle(
          session_id,
          {:ex_wapp_session, :initial_sync, :failed, reason,
           initial_sync_event_payload(session_id, session_pid, %{
             collection_names: names,
             success_count: success_count,
             failures: failures
           })}
        )

      {failures, {:error, flush_reason}} ->
        reason = {:final_store_flush_failed, flush_reason}

        Subscribers.broadcast_lifecycle(
          session_id,
          {:ex_wapp_session, :initial_sync, :failed, reason,
           initial_sync_event_payload(session_id, session_pid, %{
             collection_names: names,
             success_count: success_count,
             failures: failures,
             flush_reason: flush_reason
           })}
        )
    end
  end

  defp run_app_state_collection_refresh(session_pid, store, names, _source, _session_id) do
    Enum.each(names, fn collection_name ->
      _ = fetch_app_state_collection(session_pid, store, collection_name)
    end)
  end

  defp begin_store_batch(%module{} = store, reason) when is_atom(reason) do
    if function_exported?(module, :begin_batch, 2) do
      apply(module, :begin_batch, [store, reason])
    else
      :ok
    end
  end

  defp begin_store_batch(_store, _reason), do: :ok

  defp finish_store_batch(%module{} = store, reason) when is_atom(reason) do
    if function_exported?(module, :finish_batch, 2) do
      apply(module, :finish_batch, [store, reason])
    else
      :ok
    end
  end

  defp finish_store_batch(_store, _reason), do: :ok

  defp fetch_app_state_collection(session_pid, store, collection_name) do
    case ExWapp.AppState.Engine.fetch_collection(session_pid, store, collection_name) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("[APP_STATE] Failed to fetch #{collection_name}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
