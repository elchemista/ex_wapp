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

  ## What lives here, and what does not

  This module owns the process: the state struct, the GenServer callbacks and
  the decision of what each incoming message means. The work each decision
  triggers lives in a module named after the concern, all of them called from
  this process — a module is not a process, so the transport is still linked to
  the session, monitors are registered against it and timers land in its mailbox.

    * `ExWapp.Session.Worker.Connection` — opening, tearing down and retrying the
      transport, and the connection events it reports
    * `ExWapp.Session.Worker.SendRecovery` — resending, repairing a rejected
      peer session, and asking the primary device for a placeholder resend
    * `ExWapp.Session.Worker.SendHealth` — send counters and the error guard
    * `ExWapp.Session.Worker.SignalSessions` — loading, persisting and pruning
      Signal sessions
    * `ExWapp.Session.Worker.PostAuth` — the prekey and passive handshake that
      follows a successful login
    * `ExWapp.Session.Worker.NodeHandler` — turning an inbound stanza into state
      plus a list of actions
    * `ExWapp.Session.Worker.Outbound` / `OutboundConfirmation` / `Retry` — the
      send path and its delivery confirmations
    * `ExWapp.Session.Worker.Subscribers` / `Events` — what the session reports
      to subscribers and to telemetry

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

      idle -> connecting -> handshaking -> syncing -> connected
        ^                                                  |
        |                                                  v
        +<---------------- disconnected <------------------+
  """

  use GenServer
  require Logger

  alias ExWapp.AppState.Engine

  alias ExWapp.{
    Binary,
    Call,
    Config,
    Log,
    Media,
    Message,
    Messages,
    Pairing,
    Quota,
    RateLimiter,
    Store
  }

  alias ExWapp.Pairing.LinkCode
  alias ExWapp.Signal.{PrekeyFetcher, SessionStore}

  alias ExWapp.Session.{
    Account,
    AppStateSync,
    InboundRouter,
    InitialSync,
    Options,
    OutboundQueue,
    SendCoordinator
  }

  alias ExWapp.Session.Outbound.{Command, Content}

  alias ExWapp.AppState.Engine
  alias ExWapp.Session.Account

  alias ExWapp.Session.Worker.{
    Connection,
    Events,
    NodeHandler,
    OutboundConfirmation,
    PostAuth,
    Safety,
    SendHealth,
    SendRecovery,
    SignalSessions,
    Subscribers
  }

  @typedoc "Human readable events emitted during the pairing flow."
  @type qr_event ::
          {:code, String.t()} | {:pairing_code, String.t()} | :success | {:error, term()}

  @typedoc "Session status"
  @type status ::
          :idle | :connecting | :handshaking | :syncing | :connected | :disconnected

  @explicit_app_state_sync_timeout :timer.minutes(5)

  defstruct [
    :store,
    :store_owned?,
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
    send_coordinator: %SendCoordinator{},
    opts: [],
    runtime_cfg: %{},
    send_health: SendHealth.default(),
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
    pending_media_retries: %{},
    initial_sync: %InitialSync{},
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
          store_owned?: boolean(),
          transport_mod: module(),
          outbound_queue: pid() | nil,
          inbound_router: pid() | nil,
          send_worker_sup: pid() | nil,
          initial_sync: InitialSync.t(),
          session_id: term() | nil,
          health_timer: reference() | nil,
          qr_subscribers: %{reference() => {pid(), reference()}},
          message_subscribers: %{reference() => {pid(), reference()}},
          send_coordinator: SendCoordinator.t(),
          opts: Options.t(),
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
          post_auth_phase: atom(),
          prekey_count_query_id: binary() | nil,
          prekey_upload_iq_id: binary() | nil,
          pending_prekey_upload: list(),
          passive_iq_id: binary() | nil,
          digest_iq_id: binary() | nil,
          retry_counters: map(),
          outgoing_retry_payloads: map(),
          outbound_confirmations: map(),
          pending_media_retries: map(),
          stats: map()
        }

  # Session API

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
  @spec start_link(keyword() | Options.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, Options.gen_server_options(opts))
  end

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

  @doc "Requests phone-number pairing while the Noise transport is awaiting authentication."
  @spec request_pairing_code(GenServer.server(), String.t(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def request_pairing_code(server, phone, opts \\ []) do
    GenServer.call(server, {:request_pairing_code, phone, opts}, 30_000)
  end

  @doc """
  Unsubscribes from QR code events.
  """
  @spec unsubscribe_qr(GenServer.server(), reference()) :: :ok
  def unsubscribe_qr(server, ref), do: GenServer.cast(server, {:unsubscribe_qr, ref})

  @doc "Send an app state mutation (server-synced)."
  @spec send_app_state(GenServer.server(), map()) :: {:ok, map(), map()} | {:error, term()}
  def send_app_state(server, patch_info) do
    GenServer.call(server, {:app_state_mutation, patch_info}, @explicit_app_state_sync_timeout)
  end

  @doc "Fetch and apply the contact app-state collection (`critical_unblock_low`)."
  @spec sync_contacts(GenServer.server()) :: :ok | {:error, term()}
  def sync_contacts(server),
    do: GenServer.call(server, :sync_contacts, @explicit_app_state_sync_timeout)

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
          15_000 -> {[{:error, :timeout}], subscription}
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

  # GenServer lifecycle

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)

    options =
      case Options.from_start_options(opts) do
        {:ok, options} -> options
        {:error, reason} -> raise ArgumentError, "invalid session options: #{inspect(reason)}"
      end

    runtime_cfg = options.runtime
    store_input = options.store
    store = Store.new(store_input)
    log_store_capabilities(store)
    log_client_version_age(runtime_cfg)
    session_id = options.session_id
    transport_mod = options.transport

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
      opts: options,
      runtime_cfg: runtime_cfg,
      store: store,
      store_owned?: not is_struct(store_input),
      transport_mod: transport_mod,
      outbound_queue: outbound_queue,
      inbound_router: inbound_router,
      send_worker_sup: send_worker_sup,
      session_id: session_id,
      pairing: Pairing.new(store),
      signal_sessions: SignalSessions.load(store),
      rate_limiter: RateLimiter.new(),
      quota: Quota.new(runtime_cfg),
      safety: Safety.new()
    }

    Events.emit_telemetry(:init, %{session_id: session_id}, state)

    if options.auto_connect do
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

  def handle_call(
        {:request_pairing_code, phone, opts},
        _from,
        %{status: :handshaking, transport_ready?: true, outbound_queue: outbound_queue} = state
      )
      when is_binary(phone) and is_list(opts) and is_pid(outbound_queue) do
    case LinkCode.request(state.store, phone, opts, state.runtime_cfg) do
      {:ok, %{code: code, request_id: request_id, node: node, jid: jid}} ->
        OutboundQueue.enqueue_node(outbound_queue, node)

        Subscribers.notify_qr(state, {:pairing_code, code}, fn ->
          Events.emit_telemetry(
            :qr,
            %{subscriber_count: map_size(state.qr_subscribers)},
            state,
            %{event: :pairing_code}
          )
        end)

        Subscribers.broadcast_lifecycle(
          state.session_id,
          {:ex_wapp_session, :pairing_code, %{code: code, jid: jid}}
        )

        {:reply, {:ok, code},
         %{state | pairing: Pairing.mark_waiting_for_code(state.pairing, request_id)}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:request_pairing_code, _phone, _opts}, _from, state) do
    {:reply, {:error, {:pairing_not_ready, state.status}}, state}
  end

  def handle_call({:send_message, %Message{} = message}, from, state) do
    case dispatch_outbound_message(state, message, from) do
      {:ok, new_state} -> {:noreply, new_state}
      {:error, reason, error_state} -> {:reply, {:error, reason}, error_state}
    end
  end

  def handle_call({:send_message, _message}, _from, state),
    do: {:reply, {:error, :invalid_message}, state}

  def handle_call({:download_media, %Media.Ref{} = ref, opts}, from, state)
      when is_list(opts) do
    if state.status in [:connected, :syncing] and is_pid(state.conn) do
      session_pid = self()

      task = fn -> safe_download_media(session_pid, state, ref, opts) end

      case SendRecovery.start_send_worker(state, "media_download", task) do
        {:ok, worker, mon} ->
          {:noreply,
           SendRecovery.register_send_worker(state, worker, mon, "media_download", from)}

        {:error, reason} ->
          {:reply, {:error, {:download_worker_start_failed, reason}}, state}
      end
    else
      {:reply, {:error, {:not_connected, state.status}}, state}
    end
  end

  def handle_call({:download_media, _ref, _opts}, _from, state) do
    {:reply, {:error, :invalid_media_reference}, state}
  end

  def handle_call({:retry_media, message_id, opts}, from, %{status: status} = state)
      when status in [:connected, :syncing] and is_binary(message_id) and is_list(opts) do
    with false <- Map.has_key?(state.pending_media_retries, message_id),
         {chat_jid, message} <- Store.find_message_by_id(state.store, message_id),
         %Media.Ref{media_key: media_key} = ref <- message_media_ref(message),
         true <- is_binary(media_key) and byte_size(media_key) == 32,
         own_jid when is_binary(own_jid) and own_jid != "" <-
           Account.local_account_base_jid(state.store) do
      receipt =
        Media.build_retry_receipt(
          message_id,
          own_jid,
          chat_jid,
          Map.get(message, :from_me, false) == true,
          SendRecovery.normalize_retry_participant(Map.get(message, :participant)),
          media_key
        )

      timeout_ms = retry_media_timeout(opts)
      timer = Process.send_after(self(), {:media_retry_timeout, message_id}, timeout_ms)

      pending = %{
        from: from,
        timer: timer,
        media_key: media_key,
        ref: ref,
        message: message,
        chat_jid: chat_jid
      }

      OutboundQueue.enqueue_node(state.outbound_queue, receipt)

      {:noreply,
       %{state | pending_media_retries: Map.put(state.pending_media_retries, message_id, pending)}}
    else
      true -> {:reply, {:error, :media_retry_already_pending}, state}
      nil -> {:reply, {:error, :message_not_found}, state}
      %Media.Ref{} -> {:reply, {:error, :invalid_media_key}, state}
      _ -> {:reply, {:error, :not_media}, state}
    end
  end

  def handle_call({:retry_media, _message_id, _opts}, _from, state) do
    {:reply, {:error, {:not_connected, state.status}}, state}
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

  def handle_call({:send_typing, _jid, _composing}, _from, %{status: status} = state)
      when status != :connected do
    {:reply, {:error, {:not_connected, status}}, state}
  end

  def handle_call({:send_typing, _jid, _composing}, _from, %{conn: conn} = state)
      when not is_pid(conn) do
    {:reply, {:error, {:not_connected, state.status}}, state}
  end

  def handle_call({:send_typing, jid, composing}, _from, %{conn: conn} = state) do
    case Account.local_account_chatstate_jid(state.store, jid) do
      "" ->
        {:reply, {:error, :local_identity_unavailable}, state}

      from_jid ->
        node = Messages.build_typing(jid, from_jid, composing)
        {:reply, state.transport_mod.send_node(conn, node), state}
    end
  end

  def handle_call({:send_iq, node, message_id}, from, %{status: status, conn: conn} = state)
      when status in [:connected, :syncing] and is_pid(conn) do
    timeout_ms = Config.get(state.runtime_cfg, [:iq, :default_timeout_ms], 30_000)
    send_iq_call(node, message_id, timeout_ms, from, state)
  end

  def handle_call(
        {:send_iq, node, message_id, timeout_ms},
        from,
        %{status: status, conn: conn} = state
      )
      when status in [:connected, :syncing] and is_pid(conn) and is_integer(timeout_ms) and
             timeout_ms > 0 do
    send_iq_call(node, message_id, timeout_ms, from, state)
  end

  def handle_call({:send_iq, _node, _message_id}, _from, state) do
    {:reply, {:error, {:not_connected, state.status}}, state}
  end

  def handle_call({:send_iq, _node, _message_id, _timeout_ms}, _from, state) do
    {:reply, {:error, {:not_connected, state.status}}, state}
  end

  def handle_call(
        {:send_worker_iq, worker_pid, %Binary.Node{attrs: attrs} = node},
        _from,
        %{status: status, conn: conn} = state
      )
      when status in [:connected, :syncing] and is_pid(conn) and is_pid(worker_pid) do
    iq_id = Map.get(attrs || %{}, "id")

    with :ok <- ensure_worker_iq_capacity(state),
         :ok <- ensure_iq_id_available(state, iq_id),
         true <- SendCoordinator.registered?(state.send_coordinator, worker_pid),
         {:ok, coordinator} <-
           SendCoordinator.register_iq(state.send_coordinator, worker_pid, iq_id),
         :ok <- state.transport_mod.send_node(conn, node) do
      {:reply, :ok, %{state | send_coordinator: coordinator}}
    else
      false -> {:reply, {:error, :unknown_send_worker}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
      other -> {:reply, other, state}
    end
  end

  def handle_call({:send_worker_iq, _worker_pid, _node}, _from, state) do
    {:reply, {:error, {:not_connected, state.status}}, state}
  end

  # ── App State Sync Operations ──

  def handle_call({:app_state_mutation, patch_info}, from, %{status: :connected} = state) do
    session_pid = self()

    # Spawn a worker to avoid deadlock: send_mutation calls GenServer.call(session, {:send_iq, ...})
    # which would deadlock if run inside handle_call of the same GenServer.
    case SendRecovery.start_send_worker(state, "app_state_mutation", fn ->
           try do
             Engine.send_mutation(
               session_pid,
               patch_info,
               state.store,
               Call.retention_options(state.runtime_cfg)
             )
           rescue
             e -> {:error, {:exception, e}}
           end
         end) do
      {:ok, worker, mon} ->
        new_state =
          SendRecovery.register_send_worker(state, worker, mon, "app_state_mutation", from)

        {:noreply, new_state}

      {:error, reason} ->
        {:reply, {:error, {:send_worker_start_failed, reason}}, state}
    end
  end

  def handle_call({:app_state_mutation, _patch_info}, _from, state) do
    {:reply, {:error, {:not_connected, state.status}}, state}
  end

  def handle_call(:sync_contacts, from, %{status: :connected} = state) do
    if AppStateSync.keys_available?(state.store) do
      start_contact_sync_worker(state, from)
    else
      Logger.debug(
        "[APP_STATE] Contact sync skipped while app-state keys are unavailable session=#{Log.reference(state.session_id)}"
      )

      {:reply, {:error, :app_state_keys_unavailable}, state}
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
    sessions = SignalSessions.normalize(sessions)
    SignalSessions.persist(state.store, sessions)
    {:reply, :ok, %{state | signal_sessions: sessions}}
  end

  def handle_call({:subscribe_messages, pid}, _from, state) do
    ref = make_ref()
    mon = Process.monitor(pid)
    new_state = put_in(state.message_subscribers[ref], {pid, mon})
    {:reply, {:ok, ref}, new_state}
  end

  @spec send_iq_call(Binary.Node.t(), String.t(), pos_integer(), GenServer.from(), t()) ::
          {:reply, term(), t()} | {:noreply, t()}
  defp send_iq_call(node, message_id, timeout_ms, from, state) do
    max_pending = Config.get(state.runtime_cfg, [:iq, :max_pending_requests], 1_000)

    pending_count =
      map_size(state.pending_iqs) + SendCoordinator.iq_route_count(state.send_coordinator)

    cond do
      pending_count >= max_pending ->
        {:reply, {:error, :too_many_pending_iq_requests}, state}

      Map.has_key?(state.pending_iqs, message_id) or
          SendCoordinator.has_iq?(state.send_coordinator, message_id) ->
        {:reply, {:error, {:duplicate_iq_id, message_id}}, state}

      true ->
        case state.transport_mod.send_node(state.conn, node) do
          :ok ->
            timer = Process.send_after(self(), {:iq_timeout, message_id}, timeout_ms)
            pending = %{from: from, timer: timer}
            new_state = %{state | pending_iqs: Map.put(state.pending_iqs, message_id, pending)}
            {:noreply, new_state}

          error ->
            {:reply, error, state}
        end
    end
  end

  defp ensure_worker_iq_capacity(state) do
    max_pending = Config.get(state.runtime_cfg, [:iq, :max_pending_requests], 1_000)

    pending_count =
      map_size(state.pending_iqs) + SendCoordinator.iq_route_count(state.send_coordinator)

    if pending_count < max_pending, do: :ok, else: {:error, :too_many_pending_iq_requests}
  end

  defp ensure_iq_id_available(state, iq_id) when is_binary(iq_id) and iq_id != "" do
    if Map.has_key?(state.pending_iqs, iq_id) or
         SendCoordinator.has_iq?(state.send_coordinator, iq_id) do
      {:error, {:duplicate_iq_id, iq_id}}
    else
      :ok
    end
  end

  defp ensure_iq_id_available(_state, _iq_id), do: {:error, :invalid_iq_route}

  @impl true
  def handle_cast(:connect, %__MODULE__{status: status} = state)
      when status in [:idle, :disconnected] do
    Logger.debug("[SESSION] handle_cast(:connect) - status=#{status}, scheduling connect...")
    {:noreply, Connection.schedule_connect(state, 0)}
  end

  def handle_cast(:connect, state) do
    Logger.debug("[SESSION] handle_cast(:connect) IGNORED - status=#{state.status}")
    {:noreply, state}
  end

  def handle_cast(:disconnect, state) do
    new_state = Connection.do_disconnect(state, :user_requested)
    {:noreply, %{new_state | status: :idle, reconnect_attempts: 0}}
  end

  def handle_cast(:pause_sends, state) do
    new_state =
      state
      |> SendHealth.put(:paused, true)
      |> SendHealth.put(:last_guard_action, :pause)

    SendHealth.broadcast_event(new_state, :control, %{action: :pause_sends})
    {:noreply, new_state}
  end

  def handle_cast(:resume_sends, state) do
    new_state =
      state
      |> SendHealth.put(:paused, false)
      |> SendHealth.put(:consecutive_send_errors, 0)
      |> SendHealth.put(:last_guard_action, :resume)

    SendHealth.broadcast_event(new_state, :control, %{action: :resume_sends})
    {:noreply, new_state}
  end

  def handle_cast(:stop_worker, state) do
    SendHealth.broadcast_event(state, :control, %{action: :stop_worker})
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
    {:noreply, Connection.do_connect(state)}
  end

  def handle_info(:health_check, state) do
    new_state = Connection.do_health_check(state)
    {:noreply, new_state}
  end

  def handle_info({:reconnect, attempt}, state) do
    Logger.debug("Reconnection attempt #{attempt}")
    Events.emit_telemetry(:reconnect, %{attempt: attempt}, state)
    {:noreply, Connection.do_connect(%{state | reconnect_attempts: attempt})}
  end

  # Connection process exited
  def handle_info({:EXIT, pid, reason}, %__MODULE__{conn: pid} = state) do
    Logger.warning("Connection process exited: #{Log.reason(reason)}")
    new_state = Connection.handle_connection_exit(state, reason)
    {:noreply, new_state}
  end

  def handle_info({:EXIT, pid, reason}, %__MODULE__{outbound_queue: pid} = state) do
    Logger.warning("[SESSION] outbound queue exited: #{Log.reason(reason)}")
    {:noreply, Connection.restart_outbound_queue(state)}
  end

  def handle_info({:EXIT, pid, reason}, %__MODULE__{inbound_router: pid} = state) do
    Logger.warning("[SESSION] inbound router exited: #{Log.reason(reason)}")
    {:noreply, Connection.restart_inbound_router(state)}
  end

  def handle_info({:EXIT, pid, reason}, %__MODULE__{send_worker_sup: pid} = state) do
    Logger.warning("[SESSION] send worker supervisor exited: #{Log.reason(reason)}")
    state = Connection.fail_all_send_workers(state, {:send_worker_supervisor_exited, reason})

    case Task.Supervisor.start_link() do
      {:ok, send_worker_sup} ->
        {:noreply, %{state | send_worker_sup: send_worker_sup}}

      {:error, restart_reason} ->
        Logger.error(
          "[SESSION] failed to restart send worker supervisor: #{Log.reason(restart_reason)}"
        )

        {:noreply, %{state | send_worker_sup: nil}}
    end
  end

  def handle_info({:EXIT, pid, reason}, state) do
    case finish_send_worker(state, pid, {:error, {:send_worker_exited, reason}}) do
      {:ok, new_state} -> {:noreply, new_state}
      :not_found -> {:noreply, state}
    end
  end

  # Connection events from Conn process
  def handle_info({:connection_event, event}, state) do
    Logger.debug(
      "[SESSION] connection_event session=#{Log.reference(state.session_id)} event=#{inspect(Connection.connection_event_summary(event))} status_before=#{inspect(state.status)} post_auth_phase=#{inspect(state.post_auth_phase)}"
    )

    new_state = Connection.handle_connection_event(event, state)

    Logger.debug(
      "[SESSION] connection_event handled session=#{Log.reference(state.session_id)} event=#{inspect(Connection.connection_event_summary(event))} status_after=#{inspect(new_state.status)} post_auth_phase=#{inspect(new_state.post_auth_phase)}"
    )

    {:noreply, new_state}
  catch
    kind, reason ->
      Logger.error("Error handling connection event: #{kind} #{Log.reason(reason)}")
      new_state = Events.update_stats(state, :errors)
      {:noreply, new_state}
  end

  # The initial sync has no wall-clock deadline. Its monitor is the safety
  # mechanism: if the task exits without reporting a result, release the gate
  # and surface the failure instead of leaving the session stuck in :syncing.
  def handle_info(
        {:DOWN, ref, :process, pid, reason},
        %__MODULE__{initial_sync: %InitialSync{monitor: ref, task: pid}} = state
      ) do
    failure_reason = {:task_exited_without_result, reason}

    Logger.warning(
      "[APP_STATE] initial sync task exited without a result session=#{Log.reference(state.session_id)} reason=#{Log.reason(reason)}"
    )

    AppStateSync.broadcast_failure(
      state.session_id,
      self(),
      failure_reason,
      %{task_exit_reason: reason}
    )

    state =
      state
      |> Connection.clear_initial_sync_task()
      |> maybe_mark_synced()

    {:noreply, state}
  end

  def handle_info({:send_worker_finished, pid, result}, state) when is_pid(pid) do
    case finish_send_worker(state, pid, result) do
      {:ok, new_state} -> {:noreply, new_state}
      :not_found -> {:noreply, state}
    end
  end

  # Monitor DOWN for subscribers and ordinary send workers.
  def handle_info({:DOWN, mon, :process, _pid, reason}, state) do
    case send_worker_down(state, mon, reason) do
      {:ok, new_state} -> {:noreply, new_state}
      :not_found -> {:noreply, cleanup_dead_subscriber(state, mon)}
    end
  end

  # PubSub send command - dispatched via ExWapp.send_message("session_id", jid, text)
  def handle_info({:ex_wapp_send, jid, text}, state) do
    message = Message.text(jid, text)

    case dispatch_outbound_message(state, message, nil) do
      {:ok, new_state} ->
        {:noreply, new_state}

      {:error, reason, error_state} ->
        Logger.warning(
          "[SESSION] PubSub send blocked for #{Log.reference(jid)}: #{Log.reason(reason)}"
        )

        {:noreply, error_state}
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
      "[WORKER] New message from=#{Log.reference(jid)} id=#{Log.reference(Map.get(message, :id))} session=#{Log.reference(state.session_id)}"
    )

    Events.emit_telemetry(
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

  # Call state change parsed from an inbound <call> stanza - notify subscribers
  def handle_info({:call_event, %ExWapp.Call{} = call}, state) do
    Logger.info(
      "[WORKER] Call event id=#{Log.reference(call.id)} status=#{inspect(call.status)} jid=#{Log.reference(call.chat_jid)} session=#{Log.reference(state.session_id)}"
    )

    Events.emit_telemetry(
      :call_event,
      %{event_count: 1},
      state,
      %{call_id: call.id, status: call.status, jid: call.chat_jid}
    )

    Subscribers.broadcast_call(state.session_id, call)
    {:noreply, state}
  end

  def handle_info(
        {:request_placeholder_resend, chat_jid, sender_jid, message_id, metadata},
        state
      ) do
    {:noreply,
     SendRecovery.maybe_start_placeholder_resend_request(
       state,
       chat_jid,
       sender_jid,
       message_id,
       metadata
     )}
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
  def handle_info({:app_state_sync_collections, collection_names}, %{status: status} = state)
      when status in [:connected, :syncing] and is_list(collection_names) do
    AppStateSync.refresh(
      state.send_worker_sup,
      self(),
      state.store,
      collection_names,
      :notification,
      nil,
      state.runtime_cfg
    )

    {:noreply, state}
  end

  def handle_info(
        {:app_state_initial_sync, _collection_names},
        %{status: status, initial_sync: %InitialSync{task: task}} = state
      )
      when status in [:connected, :syncing] and is_pid(task),
      do: {:noreply, state}

  def handle_info({:app_state_initial_sync, collection_names}, %{status: status} = state)
      when status in [:connected, :syncing] and is_list(collection_names) do
    cond do
      not AppStateSync.initial_enabled?(state) ->
        Logger.debug(
          "[APP_STATE] Automatic initial sync disabled session=#{Log.reference(state.session_id)}"
        )

        {:noreply, state}

      not AppStateSync.keys_available?(state.store) ->
        Logger.debug(
          "[APP_STATE] Initial sync still waiting for app-state keys session=#{Log.reference(state.session_id)}"
        )

        {:noreply, state}

      true ->
        state = enter_initial_sync_gate(state)

        case AppStateSync.refresh(
               state.send_worker_sup,
               self(),
               state.store,
               collection_names,
               :initial,
               state.session_id,
               state.runtime_cfg
             ) do
          {:ok, task_pid} ->
            task_ref = Process.monitor(task_pid)
            initial_sync = InitialSync.track(state.initial_sync, task_pid, task_ref)

            {:noreply, %{state | initial_sync: initial_sync}}

          {:error, reason} ->
            AppStateSync.broadcast_failure(
              state.session_id,
              self(),
              {:task_start_failed, reason},
              %{collection_names: collection_names}
            )

            {:noreply,
             state
             |> maybe_mark_synced()}
        end
    end
  end

  # Initial app-state sync finished (success or failure): the session is usable,
  # so leave the :syncing gate and allow outbound sends again. Include the task
  # pid so a late result from a cancelled connection cycle cannot release a
  # newer sync task.
  def handle_info(
        {:initial_sync_finished, task_pid, _result},
        %{initial_sync: %InitialSync{task: task_pid}} = state
      )
      when is_pid(task_pid) do
    Logger.debug(
      "[APP_STATE] initial sync finished; marking session connected session=#{Log.reference(state.session_id)}"
    )

    state =
      state
      |> Connection.clear_initial_sync_task()
      |> maybe_mark_synced()

    {:noreply, state}
  end

  def handle_info({:initial_sync_finished, _task_pid, _result}, state), do: {:noreply, state}

  def handle_info({:app_state_sync_collections, _}, state), do: {:noreply, state}

  def handle_info({:app_state_initial_sync, _}, state), do: {:noreply, state}

  def handle_info({:outbound_error, _item, reason}, state) do
    Logger.warning("[SESSION] outbound queue error: #{Log.reason(reason)}")
    Events.emit_telemetry(:error, %{reason: reason, phase: :outbound}, state)
    state = Events.update_stats(state, :errors)
    state = SendHealth.increment_outbound_queue_errors(state, reason)

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
    sessions = SignalSessions.normalize(sessions)
    session_count = sessions |> SessionStore.list_sessions() |> length()
    Logger.debug("[SEND] Async signal session update received (sessions=#{session_count})")
    SignalSessions.persist(state.store, sessions)
    {:noreply, %{state | signal_sessions: sessions}}
  end

  def handle_info({:refill_prekeys, server_count}, state)
      when is_integer(server_count) and server_count >= 0 do
    {next_state, actions} = PostAuth.refill_from_notification(state, server_count)

    Enum.each(actions, &NodeHandler.safe_handle_action(&1, next_state))
    {:noreply, next_state}
  end

  def handle_info({:refresh_identity_session, jid}, %{status: status} = state)
      when status in [:connected, :syncing] and is_binary(jid) do
    session = self()

    case Task.Supervisor.start_child(state.send_worker_sup, fn ->
           result = PrekeyFetcher.fetch_prekeys(session, jid)
           send(session, {:identity_prekey_bundle, jid, result})
         end) do
      {:ok, _pid} ->
        :ok

      {:error, reason} ->
        Logger.warning("[IDENTITY] Refresh worker failed: #{Log.reason(reason)}")
    end

    {:noreply, state}
  end

  def handle_info({:refresh_identity_session, _jid}, state), do: {:noreply, state}

  def handle_info({:identity_prekey_bundle, jid, {:ok, bundle}}, state) do
    {:noreply, SignalSessions.install_refreshed_identity(state, jid, bundle)}
  end

  def handle_info({:identity_prekey_bundle, jid, {:error, reason}}, state) do
    Logger.warning("[IDENTITY] Could not refresh #{Log.reference(jid)}: #{Log.reason(reason)}")
    {:noreply, state}
  end

  def handle_info({:media_retry_timeout, message_id}, state) do
    case Map.pop(state.pending_media_retries, message_id) do
      {nil, _pending} ->
        {:noreply, state}

      {%{from: from}, remaining} ->
        GenServer.reply(from, {:error, :media_retry_timeout})
        {:noreply, %{state | pending_media_retries: remaining}}
    end
  end

  def handle_info({:retry_outgoing_message, jid, message_id}, state) do
    {:noreply, SendRecovery.maybe_retry_outgoing_message(state, jid, message_id, %{})}
  end

  def handle_info({:retry_outgoing_message, jid, message_id, retry_meta}, state) do
    {:noreply, SendRecovery.maybe_retry_outgoing_message(state, jid, message_id, retry_meta)}
  end

  def handle_info({:ack_session_rejection, message_id, jid, ack}, state) do
    {:noreply, SendRecovery.repair_session_and_retry(state, message_id, jid, ack)}
  end

  def handle_info({:session_repair_due, message_id, jid, ack}, state) do
    attempts = SendRecovery.session_repair_attempts(state, message_id)
    max_attempts = Config.get(state.runtime_cfg, [:send, :max_session_repair_attempts], 2)

    {:noreply,
     SendRecovery.run_session_repair(state, message_id, jid, ack, attempts, max_attempts)}
  end

  def handle_info({:send_result, jid, text, {:ok, message_id}, strategy, attempt}, state) do
    state =
      state
      |> SendRecovery.remember_outgoing_retry_payload(jid, text, message_id)
      |> SendHealth.clear_consecutive_send_errors()

    {:noreply, schedule_outbound_confirmation(state, jid, text, message_id, strategy, attempt)}
  end

  def handle_info({:send_result, jid, _text, {:error, reason}, strategy, attempt}, state) do
    state =
      SendHealth.register_send_error(state, {:send_failed, reason}, %{
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
            &SendRecovery.start_send_worker/3,
            &SendRecovery.do_send_text_worker/5,
            &SendRecovery.register_send_worker/4,
            max_silent_drop_fallback_attempts:
              Config.get(state.runtime_cfg, [:send, :max_silent_drop_fallback_attempts], 1),
            on_drop: fn jid, drop_message_id, attempt ->
              send(self(), {:silent_drop_failed, jid, drop_message_id, attempt})
            end
          )

        new_state = SendHealth.register_drop_timeout(new_state, message_id, confirmation)

        case maybe_apply_send_error_guard(new_state, {:drop_timeout, message_id}) do
          {:continue, guarded_state} -> {:noreply, guarded_state}
          {:stop, stop_reason, guarded_state} -> {:stop, stop_reason, guarded_state}
        end
    end
  end

  def handle_info({:silent_drop_failed, jid, message_id, attempt}, state) do
    state =
      SendHealth.register_send_error(
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
    {:noreply, Connection.restart_connection_now(state, reason)}
  end

  def handle_info(msg, state) do
    Logger.debug("Unhandled message: #{Log.term_summary(msg)}")
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Session terminating: #{Log.reason(reason)}")
    Events.emit_telemetry(:terminate, %{reason: reason}, state)

    Subscribers.broadcast_lifecycle(
      state.session_id,
      {:ex_wapp_session, :terminated, reason, Events.lifecycle_event_meta(state)}
    )

    if state.session_id do
      try do
        Phoenix.PubSub.unsubscribe(ExWapp.PubSub, "ex_wapp:commands:#{state.session_id}")
      rescue
        _ -> :ok
      end
    end

    # Stop every operation that can still mutate the store before persisting
    # the final snapshot. Then explicitly stop linked helpers, because normal
    # exits are ignored by linked processes when this worker traps exits.
    state = Connection.do_disconnect(state, reason)
    flush_store(state.store)
    stop_session_helpers(state)
    close_owned_store(state)
    :ok
  end

  @impl true
  def format_status(status) when is_map(status) do
    status
    |> Map.update(:reason, :redacted, &Log.safe_term/1)
    |> Map.update(:message, :redacted, &Log.safe_term/1)
    |> Map.update(:state, :redacted, &format_status_state/1)
    |> Map.put(:log, [])
  end

  # Establishing and closing connections

  defp log_store_capabilities(store) do
    case Store.missing_optional_callbacks(store) do
      [] ->
        :ok

      missing ->
        # Not an error: a minimal adapter is legitimate. But the fallbacks it
        # silently gets have different semantics from a real implementation, so
        # the substitution should be visible at start rather than inferred from
        # odd behaviour later.
        Logger.info(
          "[SESSION] store_adapter=#{inspect(store.__struct__)} using generic fallbacks for " <>
            inspect(missing)
        )
    end
  end

  defp log_client_version_age(runtime_cfg) do
    configured = get_in(runtime_cfg, [:protocol, :client_version])

    case Config.client_version_status(configured) do
      {:stale, age} ->
        Logger.warning(
          "[SESSION] built-in client_version is #{age} days old; WhatsApp may refuse the " <>
            "handshake. Override :client_version under the :protocol runtime config."
        )

      _ ->
        :ok
    end
  end

  # Reconnect scheduling and backoff

  # Periodic health checks

  # A reconnect is the one moment this client knows its view of every peer may
  # have gone stale without being told: messages it never saw were exchanged
  # while the socket was down, and a session file restored from a snapshot comes
  # back with ratchets the peers moved past long ago. Dropping the sessions that
  # look one-way here costs one prekey fetch on the next send to those peers, and
  # buys back the case where the alternative is an unbounded run of rejected
  # sends. Deployments that restore the store from an external snapshot can turn
  # `reset_sessions_on_connect` on and pay that cost for every peer instead.
  # Transport and authentication events

  # Outbound message dispatch

  defp dispatch_outbound_message(state, message, from) do
    with {:ok, message} <- Command.prepare(message),
         {:ok, state} <- SendHealth.ensure_send_enabled(state, message.to),
         :ok <- Connection.ensure_connected_for_send(state),
         {:ok, policy_state} <- enforce_send_policies(state, message.to) do
      task = outbound_message_task(self(), policy_state, message)

      case SendRecovery.start_send_worker(policy_state, message.to, task) do
        {:ok, worker, mon} ->
          new_state =
            policy_state
            |> SendRecovery.register_send_worker(worker, mon, message.to, from)
            |> Events.update_stats(:messages_sent)

          {:ok, new_state}

        {:error, reason} ->
          {:error, {:send_worker_start_failed, reason}, policy_state}
      end
    else
      {:error, reason, blocked_state} -> {:error, reason, blocked_state}
      {:error, reason} -> {:error, reason, state}
    end
  end

  defp outbound_message_task(
         session_pid,
         state,
         %Message{type: :text, to: jid, body: text, opts: opts}
       ) do
    primary_send_task_fun(session_pid, state, jid, text, :primary, 0, opts)
  end

  defp outbound_message_task(
         session_pid,
         state,
         %Message{} = message
       ) do
    fn -> Content.send(session_pid, state, message) end
  end

  # Worker function - runs in a separate process so it can wait for IQ responses
  defp safe_download_media(session_pid, state, ref, opts) do
    with {:ok, bytes} <-
           Media.HTTP.download(state, ref, Keyword.put(opts, :session, session_pid)) do
      {:ok,
       %Media.Download{
         ref: ref,
         bytes: bytes,
         mimetype: ref.mimetype,
         metadata: ref.metadata
       }}
    end
  rescue
    exception -> {:error, {:media_download_exception, exception}}
  catch
    kind, reason -> {:error, {:media_download_throw, kind, reason}}
  end

  defp primary_send_task_fun(session_pid, state, jid, text, strategy, attempt, opts) do
    fn ->
      result = SendRecovery.do_send_text_worker(session_pid, state, jid, text, opts)
      send(session_pid, {:send_result, jid, text, result, strategy, attempt})
      result
    end
  end

  defp schedule_outbound_confirmation(state, jid, text, message_id, strategy, attempt)
       when is_binary(jid) and is_binary(message_id) and is_integer(attempt) and attempt >= 0 do
    confirm_timeout_ms = configured_confirm_timeout_ms(state.runtime_cfg)
    max_fallback_attempts = configured_max_fallback_attempts(state.runtime_cfg)
    normalized_text = SendRecovery.normalize_outbound_text(text)

    OutboundConfirmation.schedule(state, jid, normalized_text, message_id, strategy, attempt,
      timeout_ms: confirm_timeout_ms,
      max_silent_drop_fallback_attempts: max_fallback_attempts
    )
  end

  defp schedule_outbound_confirmation(state, _jid, _text, _message_id, _strategy, _attempt),
    do: state

  # QR subscriber delivery

  defp remove_qr_subscriber(state, ref), do: Subscribers.remove_qr_subscriber(state, ref)

  defp cleanup_dead_subscriber(state, dead_mon),
    do: Subscribers.cleanup_dead_subscriber(state, dead_mon)

  # Message subscriber delivery

  defp notify_message_subscribers(state, jid, message),
    do: Subscribers.notify_message_subscribers(state, jid, message)

  defp remove_message_subscriber(state, ref),
    do: Subscribers.remove_message_subscriber(state, ref)

  # Session state helpers

  defp message_media_ref(%{media: %Media.Ref{} = ref}), do: ref

  defp message_media_ref(%{content: %ExWapp.Message.Content{media: %Media.Ref{} = ref}}),
    do: ref

  defp message_media_ref(_message), do: nil

  defp retry_media_timeout(opts) do
    case Keyword.get(opts, :timeout, 30_000) do
      value when is_integer(value) and value > 0 -> value
      _ -> 30_000
    end
  end

  defp flush_store(nil), do: :ok

  defp flush_store(store) do
    case Store.flush(store) do
      :ok -> :ok
      {:error, reason} -> Logger.warning("[SESSION] Failed flushing store: #{Log.reason(reason)}")
    end
  rescue
    error ->
      Logger.warning("[SESSION] Failed flushing store: #{Log.reason(error)}")
      :ok
  end

  defp stop_session_helpers(state) do
    stop_gen_server(state.outbound_queue, :outbound_queue)
    stop_gen_server(state.inbound_router, :inbound_router)
    stop_task_supervisor(state.send_worker_sup)
    :ok
  end

  defp stop_gen_server(pid, label) when is_pid(pid) do
    if Process.alive?(pid), do: GenServer.stop(pid, :normal, 5_000)
    :ok
  rescue
    exception ->
      Logger.warning("[SESSION] Failed stopping #{label}: #{Log.reason(exception)}")
      :ok
  catch
    :exit, reason ->
      Logger.warning("[SESSION] Failed stopping #{label}: #{Log.reason(reason)}")
      :ok
  end

  defp stop_gen_server(_pid, _label), do: :ok

  defp stop_task_supervisor(pid) when is_pid(pid) do
    if Process.alive?(pid), do: Supervisor.stop(pid, :normal, 5_000)
    :ok
  rescue
    exception ->
      Logger.warning("[SESSION] Failed stopping send worker supervisor: #{Log.reason(exception)}")

      :ok
  catch
    :exit, reason ->
      Logger.warning("[SESSION] Failed stopping send worker supervisor: #{Log.reason(reason)}")

      :ok
  end

  defp stop_task_supervisor(_pid), do: :ok

  defp close_owned_store(%{store_owned?: true, store: store}) do
    case Store.close(store) do
      :ok -> :ok
      {:error, reason} -> Logger.warning("[SESSION] Failed closing store: #{Log.reason(reason)}")
    end
  rescue
    exception ->
      Logger.warning("[SESSION] Failed closing store: #{Log.reason(exception)}")
      :ok
  catch
    kind, reason ->
      Logger.warning("[SESSION] Failed closing store: #{Log.reason({kind, reason})}")
      :ok
  end

  defp close_owned_store(_state), do: :ok

  defp start_contact_sync_worker(state, from) do
    session_pid = self()

    case SendRecovery.start_send_worker(
           state,
           "app_state_sync_contacts",
           fn ->
             fetch_contacts_collection(session_pid, state.store, state.runtime_cfg)
           end
         ) do
      {:ok, worker, mon} ->
        {:noreply,
         SendRecovery.register_send_worker(state, worker, mon, "app_state_sync_contacts", from)}

      {:error, reason} ->
        {:reply, {:error, {:send_worker_start_failed, reason}}, state}
    end
  end

  defp fetch_contacts_collection(session_pid, store, runtime_cfg) do
    Engine.fetch_collection(
      session_pid,
      store,
      "critical_unblock_low",
      Call.retention_options(runtime_cfg)
    )
  rescue
    error -> {:error, {:exception, error}}
  end

  defp finish_send_worker(state, pid, result) do
    case SendCoordinator.complete(state.send_coordinator, pid) do
      {:ok, operation, coordinator} ->
        Process.demonitor(operation.monitor, [:flush])
        Connection.reply_send_caller(operation.from, result)
        {:ok, %{state | send_coordinator: coordinator}}

      {:error, :not_found, _coordinator} ->
        :not_found
    end
  end

  defp send_worker_down(state, monitor, reason) do
    case SendCoordinator.down(state.send_coordinator, monitor) do
      {:ok, operation, coordinator} ->
        result = {:error, {:send_worker_exited, reason}}
        Connection.reply_send_caller(operation.from, result)

        Logger.warning(
          "[SEND] Worker exited label=#{inspect(operation.label)} reason=#{Log.reason(reason)}"
        )

        {:ok, %{state | send_coordinator: coordinator}}

      {:error, :not_found, _coordinator} ->
        :not_found
    end
  end

  defp maybe_log_inbound_node(%Binary.Node{tag: tag}) when tag in ["iq", "chatstate"], do: :ok

  defp maybe_log_inbound_node(%Binary.Node{} = node) do
    Logger.debug(
      "[WORKER] Inbound node tag=#{node.tag} attrs=#{inspect(Map.keys(node.attrs || %{}))}"
    )
  end

  defp enforce_send_policies(state, jid) do
    with {:ok, state} <- Safety.check_send_allowed(state),
         {:ok, state} <- Quota.check_and_increment(state, jid),
         {:ok, state} <- RateLimiter.check_and_update(state, jid) do
      {:ok, state}
    else
      {:error, reason, policy_state} ->
        Events.emit_telemetry(:error, %{reason: reason, phase: :send_policy}, policy_state, %{
          jid: jid
        })

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

  defp maybe_apply_send_error_guard(state, reason) do
    guard_cfg = Config.get(state.runtime_cfg, [:send_error_guard], %{})

    if Map.get(guard_cfg, :enabled, false) do
      apply_enabled_send_error_guard(state, reason, guard_cfg)
    else
      {:continue, state}
    end
  end

  defp apply_enabled_send_error_guard(state, reason, guard_cfg) do
    metrics = SendHealth.guard_metrics(state)

    case SendHealth.guard_trigger_reason(metrics, guard_cfg) do
      nil ->
        {:continue, state}

      trigger_reason ->
        action = Map.get(guard_cfg, :action, :stop_session)
        notify_only = Map.get(guard_cfg, :notify_only, false)

        state =
          state
          |> SendHealth.increment(:guard_trips)
          |> SendHealth.put(:last_guard_action, action)
          |> SendHealth.put(:last_guard_reason, trigger_reason)

        SendHealth.broadcast_event(state, :guard_trip, %{
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

  defp continue_or_apply_guard_action(state, _action, _trigger_reason, notify_only)
       when notify_only in [true],
       do: {:continue, state}

  defp continue_or_apply_guard_action(state, action, trigger_reason, _notify_only),
    do: apply_guard_action(state, action, trigger_reason)

  defp apply_guard_action(state, :none, _trigger_reason), do: {:continue, state}

  defp apply_guard_action(state, :pause, trigger_reason) do
    state =
      state
      |> SendHealth.put(:paused, true)
      |> SendHealth.put(:hard_stopped, false)
      |> SendHealth.put(:last_guard_reason, trigger_reason)

    {:continue, state}
  end

  defp apply_guard_action(state, :disconnect, trigger_reason) do
    state =
      state
      |> SendHealth.put(:paused, true)
      |> SendHealth.put(:hard_stopped, true)
      |> SendHealth.put(:last_guard_reason, trigger_reason)
      |> Connection.do_disconnect({:send_error_guard_trip, trigger_reason})
      |> Map.put(:status, :idle)
      |> Map.put(:reconnect_attempts, 0)

    {:continue, state}
  end

  defp apply_guard_action(state, :stop_session, trigger_reason) do
    state =
      state
      |> SendHealth.put(:paused, true)
      |> SendHealth.put(:hard_stopped, true)
      |> SendHealth.put(:last_guard_reason, trigger_reason)

    {:stop, {:send_error_guard_trip, trigger_reason}, state}
  end

  defp apply_guard_action(state, _unknown, _trigger_reason), do: {:continue, state}

  defp apply_control_action(state, :pause_sends, source) do
    state =
      state
      |> SendHealth.put(:paused, true)
      |> SendHealth.put(:last_guard_action, {:pause_sends, source})

    SendHealth.broadcast_event(state, :control, %{source: source, action: :pause_sends})
    {:noreply, state}
  end

  defp apply_control_action(state, :resume_sends, source) do
    state =
      state
      |> SendHealth.put(:paused, false)
      |> SendHealth.put(:hard_stopped, false)
      |> SendHealth.put(:consecutive_send_errors, 0)
      |> SendHealth.put(:last_guard_action, {:resume_sends, source})

    SendHealth.broadcast_event(state, :control, %{source: source, action: :resume_sends})
    {:noreply, state}
  end

  defp apply_control_action(state, :disconnect, source) do
    state =
      state
      |> Connection.do_disconnect({:control_disconnect, source})
      |> Map.put(:status, :idle)
      |> Map.put(:reconnect_attempts, 0)

    SendHealth.broadcast_event(state, :control, %{source: source, action: :disconnect})
    {:noreply, state}
  end

  defp apply_control_action(state, :stop_session, source) do
    SendHealth.broadcast_event(state, :control, %{source: source, action: :stop_session})
    {:stop, {:control, :stop_session, source}, state}
  end

  defp apply_control_action(state, action, source) do
    SendHealth.broadcast_event(state, :control, %{source: source, action: :unknown, value: action})

    {:noreply, state}
  end

  defp calculate_uptime(%{connected_at: nil}), do: 0

  defp calculate_uptime(%{connected_at: connected_at}) do
    DateTime.diff(DateTime.utc_now(), connected_at, :second)
  end

  # ── Initial sync gate ──────────────────────────────────────────────────────
  # While the initial app-state sync runs the session is :syncing, which blocks
  # outbound sends. There is intentionally no elapsed-time cutoff: completion,
  # task failure, disconnect, or session termination are the only exits.

  defp enter_initial_sync_gate(%{status: :connected} = state),
    do: %{state | status: :syncing}

  defp enter_initial_sync_gate(state), do: state

  defp maybe_mark_synced(%{status: :syncing} = state), do: %{state | status: :connected}
  defp maybe_mark_synced(state), do: state

  defp format_status_state(state) when is_map(state) do
    %{
      status: Map.get(state, :status),
      session: Log.reference(Map.get(state, :session_id)),
      transport_connected?: is_pid(Map.get(state, :conn)),
      pending_iqs: state |> Map.get(:pending_iqs, %{}) |> map_size(),
      message_subscribers: state |> Map.get(:message_subscribers, %{}) |> map_size(),
      qr_subscribers: state |> Map.get(:qr_subscribers, %{}) |> map_size()
    }
  end

  defp format_status_state(_state), do: :redacted
end
