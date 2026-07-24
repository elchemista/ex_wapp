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
    Config,
    Log,
    Media,
    Message,
    Messages,
    Pairing,
    Quota,
    RateLimiter,
    Store,
    Telemetry
  }

  alias ExWapp.Pairing.LinkCode
  alias ExWapp.Signal.{PrekeyFetcher, SessionStore}

  alias ExWapp.Session.{
    Account,
    AppStateSync,
    InboundRouter,
    InitialSync,
    JIDUtils,
    Options,
    OutboundQueue,
    SendCoordinator
  }

  alias ExWapp.Session.Outbound.{Command, Content}

  alias ExWapp.Session.Worker.{
    NodeHandler,
    Outbound,
    OutboundConfirmation,
    PostAuth,
    Resilience,
    Retry,
    Safety,
    Subscribers
  }

  @typedoc "Human readable events emitted during the pairing flow."
  @type qr_event ::
          {:code, String.t()} | {:pairing_code, String.t()} | :success | {:error, term()}

  @typedoc "Session status"
  @type status ::
          :idle | :connecting | :handshaking | :syncing | :connected | :disconnected

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
      signal_sessions: load_persisted_signal_sessions(store),
      rate_limiter: RateLimiter.new(),
      quota: Quota.new(runtime_cfg),
      safety: Safety.new()
    }

    emit_telemetry(:init, %{session_id: session_id}, state)

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
          emit_telemetry(
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

      case start_send_worker(state, "media_download", task) do
        {:ok, worker, mon} ->
          {:noreply, register_send_worker(state, worker, mon, "media_download", from)}

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
          normalize_retry_participant(Map.get(message, :participant)),
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
    case start_send_worker(state, "app_state_mutation", fn ->
           try do
             ExWapp.AppState.Engine.send_mutation(session_pid, patch_info, state.store)
           rescue
             e -> {:error, {:exception, e}}
           end
         end) do
      {:ok, worker, mon} ->
        new_state = register_send_worker(state, worker, mon, "app_state_mutation", from)

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
    sessions = normalize_persisted_signal_sessions(sessions)
    persist_signal_sessions_store(state.store, sessions)
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
    Logger.warning("Connection process exited: #{Log.reason(reason)}")
    new_state = handle_connection_exit(state, reason)
    {:noreply, new_state}
  end

  def handle_info({:EXIT, pid, reason}, %__MODULE__{outbound_queue: pid} = state) do
    Logger.warning("[SESSION] outbound queue exited: #{Log.reason(reason)}")
    {:noreply, restart_outbound_queue(state)}
  end

  def handle_info({:EXIT, pid, reason}, %__MODULE__{inbound_router: pid} = state) do
    Logger.warning("[SESSION] inbound router exited: #{Log.reason(reason)}")
    {:noreply, restart_inbound_router(state)}
  end

  def handle_info({:EXIT, pid, reason}, %__MODULE__{send_worker_sup: pid} = state) do
    Logger.warning("[SESSION] send worker supervisor exited: #{Log.reason(reason)}")
    state = fail_all_send_workers(state, {:send_worker_supervisor_exited, reason})

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
      "[SESSION] connection_event session=#{Log.reference(state.session_id)} event=#{inspect(connection_event_summary(event))} status_before=#{inspect(state.status)} post_auth_phase=#{inspect(state.post_auth_phase)}"
    )

    new_state = handle_connection_event(event, state)

    Logger.debug(
      "[SESSION] connection_event handled session=#{Log.reference(state.session_id)} event=#{inspect(connection_event_summary(event))} status_after=#{inspect(new_state.status)} post_auth_phase=#{inspect(new_state.post_auth_phase)}"
    )

    {:noreply, new_state}
  catch
    kind, reason ->
      Logger.error("Error handling connection event: #{kind} #{Log.reason(reason)}")
      new_state = update_stats(state, :errors)
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
      |> clear_initial_sync_task()
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

  def handle_info(
        {:request_placeholder_resend, chat_jid, sender_jid, message_id, metadata},
        state
      ) do
    {:noreply,
     maybe_start_placeholder_resend_request(
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
      :notification
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
               state.session_id
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
      |> clear_initial_sync_task()
      |> maybe_mark_synced()

    {:noreply, state}
  end

  def handle_info({:initial_sync_finished, _task_pid, _result}, state), do: {:noreply, state}

  def handle_info({:app_state_sync_collections, _}, state), do: {:noreply, state}

  def handle_info({:app_state_initial_sync, _}, state), do: {:noreply, state}

  def handle_info({:outbound_error, _item, reason}, state) do
    Logger.warning("[SESSION] outbound queue error: #{Log.reason(reason)}")
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
    sessions = normalize_persisted_signal_sessions(sessions)
    session_count = sessions |> SessionStore.list_sessions() |> length()
    Logger.debug("[SEND] Async signal session update received (sessions=#{session_count})")
    persist_signal_sessions_store(state.store, sessions)
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
    {:noreply, install_refreshed_identity_session(state, jid, bundle)}
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
    {:noreply, maybe_retry_outgoing_message(state, jid, message_id, %{})}
  end

  def handle_info({:retry_outgoing_message, jid, message_id, retry_meta}, state) do
    {:noreply, maybe_retry_outgoing_message(state, jid, message_id, retry_meta)}
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
    Logger.debug("Unhandled message: #{Log.term_summary(msg)}")
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Session terminating: #{Log.reason(reason)}")
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

    # Stop every operation that can still mutate the store before persisting
    # the final snapshot. Then explicitly stop linked helpers, because normal
    # exits are ignored by linked processes when this worker traps exits.
    state = do_disconnect(state, reason)
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

  defp do_connect(%__MODULE__{status: status} = state)
       when status not in [:idle, :disconnected] do
    Logger.debug("[SESSION] do_connect SKIPPED - status=#{status} not in [:idle, :disconnected]")
    state
  end

  defp do_connect(%__MODULE__{} = state) do
    Logger.debug("[SESSION] do_connect starting connection...")
    Logger.debug("[SESSION] store_adapter=#{inspect(state.store.__struct__)}")
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
        Logger.debug("[SESSION] ✗ Connection FAILED: #{Log.reason(reason)}")
        Logger.error("Failed to start connection: #{Log.reason(reason)}")
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
      state.opts.noise
      |> Keyword.put_new(
        :client_payload_fun,
        &ExWapp.Noise.ClientPayload.build(&1, state.runtime_cfg)
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

  defp do_disconnect(%__MODULE__{conn: nil} = state, reason) do
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

  defp do_disconnect(%__MODULE__{conn: conn, conn_ref: ref} = state, reason) do
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

  # Reconnect scheduling and backoff

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

  defp handle_connection_event({:noise, :handshake_started}, state) do
    %{
      state
      | status: :handshaking,
        transport_ready?: false
    }
  end

  defp handle_connection_event({:transport, :connected}, state) do
    %{state | status: :connecting, transport_ready?: false}
  end

  defp handle_connection_event({:transport, {:closed, reason}}, %{conn: nil} = state) do
    Logger.debug(
      "[SESSION] Ignoring stale transport close: #{inspect(connection_close_reason_summary(reason))}"
    )

    state
  end

  defp handle_connection_event({:transport, {:closed, reason}}, state) do
    Logger.warning(
      "[SESSION] Transport closed: #{inspect(connection_close_reason_summary(reason))}"
    )

    handle_connection_exit(state, {:transport_closed, reason})
  end

  defp handle_connection_event({:noise, :handshake_completed}, state) do
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

    Subscribers.broadcast_lifecycle(
      state.session_id,
      {:ex_wapp_session, :post_auth_ready,
       lifecycle_event_meta(state, %{initial_sync_pending?: initial_sync?})}
    )

    AppStateSync.schedule_initial(state, self())
  end

  defp handle_connection_event({:connection_message, %Binary.Node{} = node}, state) do
    # ACK at the connection boundary, before routing/decryption/persistence.
    # This keeps protocol liveness independent from application work.
    node
    |> NodeHandler.immediate_actions()
    |> Enum.each(&NodeHandler.safe_handle_action(&1, state))

    InboundRouter.route(state.inbound_router, node)
    state
  end

  defp handle_connection_event({:connection_binary, _payload}, state), do: state

  defp handle_connection_event({:error, reason}, state) do
    Logger.warning("Connection error: #{Log.reason(reason)}")
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
    Logger.debug("Unhandled connection event: #{inspect(connection_event_summary(event))}")
    state
  end

  defp maybe_retry_outgoing_message(state, jid, message_id, retry_meta) do
    session_pid = self()
    max_attempts = Config.get(state.runtime_cfg, [:send, :max_outgoing_retry_attempts], 2)
    retries_before = total_retry_attempts(state)

    new_state =
      Retry.maybe_retry_outgoing_message(state, jid, message_id,
        max_attempts: max_attempts,
        normalize_jid: &JIDUtils.normalize_for_signal/1,
        start_worker: &start_send_worker/3,
        register_worker: &register_send_worker/4,
        outgoing_payloads: Map.get(state, :outgoing_retry_payloads, %{}),
        retry_meta: retry_meta,
        send_fun: fn normalized_jid, text ->
          retry_state = clear_signal_sessions_for_jid_in_memory(state, normalized_jid)

          retry_opts =
            [
              retry_message_id: message_id,
              suppress_outgoing_chat_add: true
            ]
            |> maybe_put_retry_own_device_destination(retry_meta)

          do_send_text_worker(session_pid, retry_state, normalized_jid, text, retry_opts)
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

  defp maybe_start_placeholder_resend_request(
         state,
         chat_jid,
         sender_jid,
         message_id,
         metadata
       ) do
    if placeholder_resend_ready?(state, chat_jid, sender_jid, message_id) do
      start_placeholder_resend_request(state, chat_jid, sender_jid, message_id, metadata)
    else
      Logger.warning(
        "[PLACEHOLDER] Cannot request unavailable message id=#{Log.reference(message_id)} while status=#{inspect(Map.get(state, :status))}"
      )

      state
    end
  end

  defp start_placeholder_resend_request(state, chat_jid, sender_jid, message_id, metadata) do
    session_pid = self()

    proto =
      Messages.build_placeholder_resend_proto(chat_jid, sender_jid, message_id,
        from_me: is_map(metadata) and Map.get(metadata, :from_me) == true
      )

    task = fn ->
      peer_state = Map.put(state, :outbound_iq_router, session_pid)
      Outbound.send_peer_proto_worker(session_pid, peer_state, proto)
    end

    case start_send_worker(state, "placeholder_resend:#{message_id}", task) do
      {:ok, worker, mon} ->
        Logger.debug(
          "[PLACEHOLDER] Requesting unavailable message id=#{Log.reference(message_id)} chat=#{Log.reference(chat_jid)} from primary device"
        )

        register_send_worker(state, worker, mon, {:placeholder_resend, message_id})

      {:error, reason} ->
        Logger.warning(
          "[PLACEHOLDER] Failed to start resend request for id=#{Log.reference(message_id)}: #{Log.reason(reason)}"
        )

        state
    end
  end

  defp placeholder_resend_ready?(%{status: status, conn: conn}, chat_jid, sender_jid, message_id) do
    status in [:connected, :syncing] and is_pid(conn) and valid_resend_ref?(chat_jid) and
      valid_resend_ref?(sender_jid) and valid_resend_ref?(message_id)
  end

  defp placeholder_resend_ready?(_state, _chat_jid, _sender_jid, _message_id), do: false

  defp valid_resend_ref?(value), do: is_binary(value) and value != ""

  # Outbound message dispatch

  defp dispatch_outbound_message(state, message, from) do
    with {:ok, message} <- Command.prepare(message),
         {:ok, state} <- ensure_send_enabled(state, message.to),
         :ok <- ensure_connected_for_send(state),
         {:ok, policy_state} <- enforce_send_policies(state, message.to) do
      task = outbound_message_task(self(), policy_state, message)

      case start_send_worker(policy_state, message.to, task) do
        {:ok, worker, mon} ->
          new_state =
            policy_state
            |> register_send_worker(worker, mon, message.to, from)
            |> update_stats(:messages_sent)

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
  defp do_send_text_worker(session_pid, state, jid, text, opts) do
    state = Map.put(state, :outbound_iq_router, session_pid)
    Outbound.send_text_worker(session_pid, state, jid, text, opts)
  end

  defp maybe_put_retry_own_device_destination(opts, %{recipient: recipient}) do
    recipient =
      recipient
      |> JIDUtils.normalize_with_device()
      |> JIDUtils.strip_device()

    if recipient == "" do
      opts
    else
      Keyword.put(opts, :own_device_destination_jid, recipient)
    end
  end

  defp maybe_put_retry_own_device_destination(opts, _retry_meta), do: opts

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
      result = do_send_text_worker(session_pid, state, jid, text, opts)
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

  defp register_send_worker(state, worker, mon, label, from \\ nil) do
    coordinator = SendCoordinator.register(state.send_coordinator, worker, mon, label, from)
    %{state | send_coordinator: coordinator}
  end

  # QR subscriber delivery

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

  # Message subscriber delivery

  defp notify_message_subscribers(state, jid, message),
    do: Subscribers.notify_message_subscribers(state, jid, message)

  defp remove_message_subscriber(state, ref),
    do: Subscribers.remove_message_subscriber(state, ref)

  # Session state helpers

  defp load_persisted_signal_sessions(store) do
    store
    |> Store.load_signal_sessions()
    |> normalize_persisted_signal_sessions()
  rescue
    error ->
      Logger.warning("[SESSION] Failed to load persisted signal sessions: #{Log.reason(error)}")
      nil
  end

  defp normalize_persisted_signal_sessions(nil), do: SessionStore.new_ets()
  defp normalize_persisted_signal_sessions(%SessionStore.Ref{} = persisted), do: persisted

  defp normalize_persisted_signal_sessions(%{sessions: sessions} = persisted)
       when is_map(sessions) do
    normalized =
      SessionStore.new()
      |> Map.merge(persisted)
      |> Map.put(:pending_prekeys, Map.get(persisted, :pending_prekeys, %{}))
      |> Map.put(:session_touched_at_ms, Map.get(persisted, :session_touched_at_ms, %{}))

    SessionStore.new_ets(normalized)
  end

  defp normalize_persisted_signal_sessions(_), do: SessionStore.new_ets()

  defp persist_signal_sessions_store(nil, _sessions), do: :ok

  defp persist_signal_sessions_store(store, sessions) do
    if SessionStore.store?(sessions) do
      case Store.persist_signal_sessions(store, sessions) do
        :ok ->
          flush_store(store)
          :ok

        {:error, reason} ->
          Logger.warning("[SESSION] Failed to persist signal sessions: #{Log.reason(reason)}")
          :ok
      end
    else
      :ok
    end
  rescue
    error ->
      Logger.warning("[SESSION] Failed to persist signal sessions: #{Log.reason(error)}")
      :ok
  end

  defp install_refreshed_identity_session(state, jid, bundle) do
    data = Store.load!(state.store)
    local_identity = get_in(data, [:signal, :identity_key])
    local_registration_id = get_in(data, [:signal, :registration_id]) || 0

    with true <- SessionStore.store?(state.signal_sessions),
         %{private: private, public: public} = identity <- local_identity,
         true <- is_binary(private) and is_binary(public),
         target_jid when is_binary(target_jid) <- Map.get(bundle, :jid) || jid,
         {:ok, _session, _base_key, sessions} <-
           SessionStore.get_or_create_session(
             state.signal_sessions,
             target_jid,
             identity,
             bundle,
             local_registration_id,
             force: true
           ) do
      persist_signal_sessions_store(state.store, sessions)
      %{state | signal_sessions: sessions}
    else
      reason ->
        Logger.warning(
          "[IDENTITY] Invalid refreshed bundle for #{Log.reference(jid)}: #{Log.reason(reason)}"
        )

        state
    end
  rescue
    error ->
      Logger.warning(
        "[IDENTITY] Failed installing refreshed bundle for #{Log.reference(jid)}: #{Log.reason(error)}"
      )

      state
  end

  defp message_media_ref(%{media: %Media.Ref{} = ref}), do: ref

  defp message_media_ref(%{content: %ExWapp.Message.Content{media: %Media.Ref{} = ref}}),
    do: ref

  defp message_media_ref(_message), do: nil

  defp normalize_retry_participant(participant) do
    case JIDUtils.normalize_with_device(participant) do
      "" -> nil
      jid -> jid
    end
  end

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

  defp start_contact_sync_worker(state, from) do
    session_pid = self()

    case start_send_worker(
           state,
           "app_state_sync_contacts",
           fn -> fetch_contacts_collection(session_pid, state.store) end
         ) do
      {:ok, worker, mon} ->
        {:noreply, register_send_worker(state, worker, mon, "app_state_sync_contacts", from)}

      {:error, reason} ->
        {:reply, {:error, {:send_worker_start_failed, reason}}, state}
    end
  end

  defp fetch_contacts_collection(session_pid, store) do
    Engine.fetch_collection(session_pid, store, "critical_unblock_low")
  rescue
    error -> {:error, {:exception, error}}
  end

  defp start_send_worker(%__MODULE__{send_worker_sup: sup}, label, fun)
       when is_pid(sup) and is_function(fun, 0) do
    session_pid = self()

    case Task.Supervisor.start_child(sup, fn ->
           run_send_worker_fun(session_pid, fun)
         end) do
      {:ok, worker} ->
        mon = Process.monitor(worker)
        {:ok, worker, mon}

      {:error, reason} ->
        Logger.warning("[SEND] Failed to start worker for #{label}: #{Log.reason(reason)}")
        {:error, reason}
    end
  end

  defp start_send_worker(_state, label, _fun) do
    {:error, {:missing_send_worker_supervisor, label}}
  end

  defp run_send_worker_fun(session_pid, fun) when is_pid(session_pid) and is_function(fun, 0) do
    result = safe_run_send_worker(fun)
    send(session_pid, {:send_worker_finished, self(), result})
  end

  defp safe_run_send_worker(fun) do
    fun.()
  rescue
    exception ->
      {:error, {:send_worker_exception, exception.__struct__, Exception.message(exception)}}
  catch
    kind, reason -> {:error, {:send_worker_caught, kind, reason}}
  end

  defp finish_send_worker(state, pid, result) do
    case SendCoordinator.complete(state.send_coordinator, pid) do
      {:ok, operation, coordinator} ->
        Process.demonitor(operation.monitor, [:flush])
        reply_send_caller(operation.from, result)
        {:ok, %{state | send_coordinator: coordinator}}

      {:error, :not_found, _coordinator} ->
        :not_found
    end
  end

  defp send_worker_down(state, monitor, reason) do
    case SendCoordinator.down(state.send_coordinator, monitor) do
      {:ok, operation, coordinator} ->
        result = {:error, {:send_worker_exited, reason}}
        reply_send_caller(operation.from, result)

        Logger.warning(
          "[SEND] Worker exited label=#{inspect(operation.label)} reason=#{Log.reason(reason)}"
        )

        {:ok, %{state | send_coordinator: coordinator}}

      {:error, :not_found, _coordinator} ->
        :not_found
    end
  end

  defp fail_all_send_workers(state, reason) do
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

  defp reply_send_caller(nil, _result), do: :ok
  defp reply_send_caller(from, result), do: GenServer.reply(from, result)

  defp maybe_log_inbound_node(%Binary.Node{tag: tag}) when tag in ["iq", "chatstate"], do: :ok

  defp maybe_log_inbound_node(%Binary.Node{} = node) do
    Logger.debug(
      "[WORKER] Inbound node tag=#{node.tag} attrs=#{inspect(Map.keys(node.attrs || %{}))}"
    )
  end

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

  defp ensure_connected_for_send(%{status: status}) when status != :connected,
    do: {:error, {:not_connected, status}}

  defp ensure_connected_for_send(%{conn: conn, status: status}) when not is_pid(conn),
    do: {:error, {:not_connected, status}}

  defp ensure_connected_for_send(_state), do: :ok

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

  # ── Initial sync gate ──────────────────────────────────────────────────────
  # While the initial app-state sync runs the session is :syncing, which blocks
  # outbound sends. There is intentionally no elapsed-time cutoff: completion,
  # task failure, disconnect, or session termination are the only exits.

  defp enter_initial_sync_gate(%{status: :connected} = state),
    do: %{state | status: :syncing}

  defp enter_initial_sync_gate(state), do: state

  defp maybe_mark_synced(%{status: :syncing} = state), do: %{state | status: :connected}
  defp maybe_mark_synced(state), do: state

  defp clear_initial_sync_task(%{initial_sync: %InitialSync{monitor: ref} = initial_sync} = state) do
    if is_reference(ref), do: Process.demonitor(ref, [:flush])
    %{state | initial_sync: InitialSync.reset(initial_sync)}
  end

  defp connection_event_summary({:connection_message, %Binary.Node{} = node}) do
    {:connection_message,
     %{tag: node.tag, attrs: node.attrs |> then(&(&1 || %{})) |> Map.keys() |> Enum.sort()}}
  end

  defp connection_event_summary({:connection_binary, payload}) when is_binary(payload),
    do: {:connection_binary, %{bytes: byte_size(payload)}}

  defp connection_event_summary({:transport, {:closed, reason}}),
    do: {:transport, {:closed, connection_close_reason_summary(reason)}}

  defp connection_event_summary(event), do: Log.safe_term(event)

  defp connection_close_reason_summary(%{__struct__: module}),
    do: %{type: inspect(module)}

  defp connection_close_reason_summary(reason) when is_map(reason) do
    reason
    |> Map.take([:reason, :attempt_number, :code])
    |> Map.new(fn {key, value} -> {key, Log.safe_term(value)} end)
  end

  defp connection_close_reason_summary(reason), do: Log.safe_term(reason)

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
