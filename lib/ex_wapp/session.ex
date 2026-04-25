defmodule ExWapp.Session do
  @moduledoc """
  Public direct-session API for WhatsApp runtime processes.

  Use this module when your application wants to own an OTP session directly:

      {:ok, pid} = ExWapp.Session.start_link(store: ExWapp.Store.Memory)
      :ok = ExWapp.Session.connect(pid)
      {:ok, message_id} = ExWapp.Session.send_text(pid, jid, "hello")

  The GenServer callback implementation lives in `ExWapp.Session.Worker`, which
  is an internal runtime module. Application code should call this module.
  """

  alias ExWapp.AppState.Engine
  alias ExWapp.Session.Worker

  @typedoc "Human readable events emitted during the pairing flow."
  @type qr_event :: {:code, String.t()} | :success | {:error, term()}

  @typedoc "Session status"
  @type status :: :idle | :connecting | :handshaking | :connected | :disconnected

  @opaque t :: Worker.t()

  @doc """
  Returns the OTP child spec for a direct session process.
  """
  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) when is_list(opts) do
    %{
      id: Keyword.get(opts, :id, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      restart: :transient,
      type: :worker
    }
  end

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
    GenServer.start_link(Worker, opts, Keyword.take(opts, [:name]))
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

  @doc "Returns the current session state for inspection."
  @spec state(GenServer.server()) :: status()
  def state(server), do: GenServer.call(server, :get_status)

  @doc "Returns session statistics."
  @spec stats(GenServer.server()) :: map()
  def stats(server), do: GenServer.call(server, :get_stats)

  @doc """
  Returns the session_id for this session.

  Returns `nil` when no explicit session_id was provided.
  """
  @spec get_session_id(GenServer.server()) :: term() | nil
  def get_session_id(server), do: GenServer.call(server, :get_session_id)

  @doc "Returns the resolved runtime configuration for this session."
  @spec runtime_config(GenServer.server()) :: map()
  def runtime_config(server), do: GenServer.call(server, :get_runtime_config)

  @doc "Returns current policy status (safety, quota, rate limiter snapshots)."
  @spec policy_status(GenServer.server()) :: map()
  def policy_status(server), do: GenServer.call(server, :get_policy_status)

  @doc "Returns current send health counters/guard state."
  @spec health_status(GenServer.server()) :: map()
  def health_status(server), do: GenServer.call(server, :get_health_status)

  @doc "Pause outbound sends for this session."
  @spec pause_sends(GenServer.server()) :: :ok
  def pause_sends(server), do: GenServer.cast(server, :pause_sends)

  @doc "Resume outbound sends for this session."
  @spec resume_sends(GenServer.server()) :: :ok
  def resume_sends(server), do: GenServer.cast(server, :resume_sends)

  @doc "Stops the session worker immediately."
  @spec stop_worker(GenServer.server()) :: :ok
  def stop_worker(server), do: GenServer.cast(server, :stop_worker)

  @doc "Flushes any pending store writes for this session."
  @spec flush_store(GenServer.server()) :: :ok | {:error, term()}
  def flush_store(server), do: GenServer.call(server, :flush_store)

  @doc """
  Exports a flushed, encoded snapshot of the session store.

  Returns `{:ok, %{data: map, blob: binary, checksum: binary}}` on success.
  The blob uses `ExWapp.Store.Codec` and the checksum is lowercase SHA-256 hex.
  """
  @spec export_snapshot(GenServer.server()) :: {:ok, map()} | {:error, term()}
  def export_snapshot(server), do: GenServer.call(server, :export_snapshot)

  @doc """
  Sends a WhatsApp typing/chatstate indicator.

  `composing` defaults to `true`; pass `false` to send the paused state.
  """
  @spec send_typing(GenServer.server(), binary(), boolean()) :: :ok | {:error, term()}
  def send_typing(server, jid, composing \\ true) do
    GenServer.call(server, {:send_typing, jid, composing})
  end

  @doc "Subscribes to QR code events."
  @spec subscribe_qr(GenServer.server()) :: {:ok, reference()}
  def subscribe_qr(server), do: GenServer.call(server, {:subscribe_qr, self()})

  @doc "Unsubscribes from QR code events."
  @spec unsubscribe_qr(GenServer.server(), reference()) :: :ok
  def unsubscribe_qr(server, ref), do: GenServer.cast(server, {:unsubscribe_qr, ref})

  @doc "Subscribe to incoming messages."
  @spec subscribe_messages(GenServer.server()) :: {:ok, reference()}
  def subscribe_messages(server), do: GenServer.call(server, {:subscribe_messages, self()})

  @doc "Unsubscribe from messages."
  @spec unsubscribe_messages(GenServer.server(), reference()) :: :ok
  def unsubscribe_messages(server, ref), do: GenServer.cast(server, {:unsubscribe_messages, ref})

  @doc "Queues a plain text message for sending."
  @spec send_text(GenServer.server(), binary(), iodata(), timeout()) ::
          {:ok, String.t()} | {:error, term()}
  def send_text(server, jid, text, timeout \\ 5_000) do
    GenServer.call(server, {:send_text, jid, IO.iodata_to_binary(text)}, timeout)
  end

  @doc "Queues an image message for sending."
  @spec send_image(GenServer.server(), binary(), ExWapp.Media.source(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_image(server, jid, source, opts \\ []) do
    GenServer.call(server, {:send_media, :image, jid, source, opts})
  end

  @doc "Queues an audio message for sending."
  @spec send_audio(GenServer.server(), binary(), ExWapp.Media.source(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_audio(server, jid, source, opts \\ []) do
    GenServer.call(server, {:send_media, :audio, jid, source, opts})
  end

  @doc "Downloads and decrypts a media reference."
  @spec download_media(GenServer.server(), ExWapp.Media.Ref.t(), keyword()) ::
          {:ok, ExWapp.Media.Download.t()} | {:error, term()}
  def download_media(server, ref, opts \\ []) do
    GenServer.call(server, {:download_media, ref, opts}, 60_000)
  end

  @doc "Send an app state mutation (server-synced)."
  @spec send_app_state(GenServer.server(), map()) :: {:ok, map(), map()} | {:error, term()}
  def send_app_state(server, patch_info) do
    GenServer.call(server, {:app_state_mutation, patch_info}, 30_000)
  end

  @doc "Archive a chat (server-synced)."
  @spec archive_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def archive_chat(server, jid) do
    patch = Engine.build_archive(jid, true)

    case send_app_state(server, patch) do
      {:ok, _, _} -> :ok
      error -> error
    end
  end

  @doc "Unarchive a chat (server-synced)."
  @spec unarchive_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def unarchive_chat(server, jid) do
    patch = Engine.build_archive(jid, false)

    case send_app_state(server, patch) do
      {:ok, _, _} -> :ok
      error -> error
    end
  end

  @doc "Delete a chat (server-synced)."
  @spec delete_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def delete_chat(server, jid) do
    patch = Engine.build_delete_chat(jid)

    case send_app_state(server, patch) do
      {:ok, _, _} -> :ok
      error -> error
    end
  end

  @doc "Create or update a contact (server-synced)."
  @spec create_contact(GenServer.server(), String.t(), String.t()) :: :ok | {:error, term()}
  def create_contact(server, jid, name) do
    patch = Engine.build_contact(jid, name)

    case send_app_state(server, patch) do
      {:ok, _, _} -> :ok
      error -> error
    end
  end

  @doc "Delete a contact (server-synced)."
  @spec delete_contact(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def delete_contact(server, jid) do
    patch = Engine.build_delete_contact(jid)

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
          300_000 -> {[], subscription}
        end
      end,
      fn {:ok, ref} -> unsubscribe_messages(server, ref) end
    )
  end
end
