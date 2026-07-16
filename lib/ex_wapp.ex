defmodule ExWapp do
  @moduledoc """
  Elixir client for WhatsApp Web.

  ExWapp implements the WhatsApp Web protocol, allowing you to send and receive
  messages through a linked companion device. This is the same protocol used by
  WhatsApp Web in browsers.

  ## Quick Start

  ```elixir
  # Start a session with default ETS storage
  {:ok, session} = ExWapp.start_link()

  # Connect to WhatsApp servers
  ExWapp.connect(session)

  # Stream QR codes for pairing
  ExWapp.qr_stream(session)
  |> Stream.each(fn
    {:code, data} ->
      # Display QR code for user to scan
      IO.puts("Scan this QR with WhatsApp:")
      data |> ExWapp.Pairing.QR.to_terminal() |> IO.puts()

    :success ->
      IO.puts("Successfully paired!")

    {:error, reason} ->
      IO.puts("Pairing failed: \#{inspect(reason)}")
  end)
  |> Stream.run()
  ```

  ## Architecture

  ExWapp is organized into several layers:

  - **Transport** (`ExWapp.Conn`) - WebSocket connection to WhatsApp servers
  - **Noise Protocol** (`ExWapp.Noise`) - End-to-end encryption handshake
  - **Signal Protocol** (`ExWapp.Signal`) - Message encryption (Double Ratchet)
  - **Binary Encoding** (`ExWapp.Binary`) - WhatsApp's custom XML-binary format
  - **Session** (`ExWapp.Session`) - State machine orchestrating the above

  ## Storage Adapters

  Session state (keys, identity, message history) is persisted via storage adapters.
  See `ExWapp.Store` for the behaviour and built-in implementations:

  ```elixir
  # Default: ETS with file persistence
  ExWapp.start_link(store: nil)

  # ETS with custom path
  ExWapp.start_link(store: {ExWapp.Store.Ets, path: "/my/path.etf"})

  # In-memory for testing
  ExWapp.start_link(store: ExWapp.Store.Memory)

  # Custom adapter (e.g., PostgreSQL)
  ExWapp.start_link(store: {MyApp.PostgresStore, user_id: 123})
  ```

  ## Example: Persistent Session

  ```elixir
  defmodule MyApp.WhatsApp do
    @store_path "/var/lib/myapp/whatsapp_session.etf"

    def start do
      {:ok, session} = ExWapp.start_link(
        store: {ExWapp.Store.Ets, path: @store_path}
      )

      case ExWapp.state(session) do
        :connected ->
          IO.puts("Already connected")
          {:ok, session}

        _other ->
          ExWapp.connect(session)
          wait_for_pairing(session)
      end
    end

    defp wait_for_pairing(session) do
      ExWapp.qr_stream(session)
      |> Enum.find(fn
        :success -> true
        {:error, _} -> true
        _ -> false
      end)
      |> case do
        :success -> {:ok, session}
        {:error, reason} -> {:error, reason}
      end
    end
  end
  ```

  ## Protocol Details

  For implementation details, see:
  - `FLOW.md` - Detailed protocol documentation
  - `ExWapp.Noise` - Noise_XX_25519_AESGCM_SHA256 handshake
  - `ExWapp.Signal` - X3DH and Double Ratchet
  """

  alias ExWapp.{Chat, Client, Error, Event, Messages, Session}

  @doc """
  Creates a high-level, runtime-neutral client.
  """
  @spec new(keyword()) :: Client.t()
  def new(opts \\ []), do: Client.new(opts)

  @doc """
  Starts a WhatsApp session process.

  ## Options

    * `:store` - Storage adapter for session state. See `ExWapp.Store`.
      Defaults to `ExWapp.Store.Ets` with default path.

    * `:name` - Optional name to register the process.

    * `:runtime` - Per-session runtime config overrides (same shape as
      `config :ex_wapp, :runtime`).

    * `:client_version` / `:wa_version` - Optional shorthand override for
      `runtime.protocol.client_version`. Accepted forms:
      `"2.3000.1034187832"`, `{2, 3000, 1034187832}`, or
      `%{primary: 2, secondary: 3000, tertiary: 1034187832}`.

  ## Examples

      # Anonymous session with default storage
      {:ok, session} = ExWapp.start_link()

      # Named session with custom storage
      {:ok, _} = ExWapp.start_link(
        name: MyApp.WhatsApp,
        store: {ExWapp.Store.Ets, path: "/tmp/wa.etf"}
      )

      # For testing
      {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    Session.start_link(opts)
  end

  @doc """
  Initiates connection to WhatsApp servers.

  This starts the Noise handshake and pairing flow. The call returns
  immediately; use `qr_stream/1` to receive pairing events.

  ## Example

      {:ok, session} = ExWapp.start_link()
      :ok = ExWapp.connect(session)

      # Now stream QR codes
      ExWapp.qr_stream(session) |> Stream.run()
  """
  @spec connect(Client.t() | GenServer.server()) ::
          {:ok, Client.t()} | {:error, Error.t(), Client.t()} | :ok
  def connect(%Client{} = client), do: Client.API.connect(client)
  def connect(server), do: Session.connect(server)

  @doc """
  Requests phone-number pairing instead of displaying a QR code.

  Invoke it after `connect/1` when the transport is ready for pairing. The
  returned code is entered in WhatsApp under **Link a device with phone
  number**.
  """
  @spec request_pairing_code(GenServer.server(), String.t(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  defdelegate request_pairing_code(session, phone, opts \\ []), to: Session

  @doc """
  Starts pairing for a high-level client.
  """
  @spec pair(Client.t()) :: {:ok, Client.t(), term()} | {:error, Error.t(), Client.t()}
  def pair(%Client{} = client), do: Client.API.pair(client)

  @doc """
  Returns a stream of QR code and pairing events.

  Subscribe to this stream after calling `connect/1` to receive:

    * `{:code, data}` - New QR code payload to display (codes expire periodically)
    * `{:pairing_code, code}` - Phone-number pairing code requested through `request_pairing_code/3`
    * `:success` - Successfully paired with phone
    * `{:error, reason}` - Pairing failed

  ## Example

      ExWapp.qr_stream(session)
      |> Stream.each(fn
        {:code, data} ->
          # Render QR code (e.g., using qrencode or terminal output)
          qr = ExWapp.Pairing.QR.to_terminal(data)
          IO.puts(qr)

        :success ->
          IO.puts("Paired successfully")

        {:error, :timeout} ->
          IO.puts("QR expired, generating new one...")
      end)
      |> Stream.run()
  """
  @spec qr_stream(GenServer.server()) :: Enumerable.t()
  defdelegate qr_stream(server), to: Session

  @doc """
  Sends a text message to a WhatsApp contact or group.

  The session must be paired before sending messages. The `jid` is the
  recipient's WhatsApp ID (phone number for individuals, group ID for groups).

  ## Examples

      # Send to individual (use full JID format)
      ExWapp.send_text(session, "1234567890@s.whatsapp.net", "Hello!")

      # Send to group
      ExWapp.send_text(session, "123456789-987654321@g.us", "Hello group!")
  """
  @spec send_text(GenServer.server(), binary(), iodata()) ::
          {:ok, String.t()} | {:error, term()}
  defdelegate send_text(server, jid, text), to: Session

  @doc """
  Returns the current session status.

  Possible values: `:idle`, `:connecting`, `:handshaking`, `:syncing`,
  `:connected`, `:disconnected`.

  ## Example

      iex> ExWapp.state(session)
      :connected
  """
  @spec state(GenServer.server()) :: Session.status()
  defdelegate state(server), to: Session

  @doc """
  Returns session statistics for monitoring.

  ## Example

      iex> ExWapp.stats(session)
      %{
        status: :connected,
        connected_at: ~U[2024-01-15 10:30:00Z],
        uptime_seconds: 3600,
        messages_sent: 42,
        messages_received: 128,
        reconnects: 1,
        errors: 0
      }
  """
  @spec stats(GenServer.server()) :: map()
  defdelegate stats(server), to: Session

  @doc """
  Returns the session_id for a session process.

  Returns `nil` when no explicit `:session_id` option was provided at start.

  ## Example

      session_id = ExWapp.get_session_id(session)
  """
  @spec get_session_id(GenServer.server()) :: term() | nil
  defdelegate get_session_id(server), to: Session

  @doc """
  Returns the effective runtime configuration for a running session.
  """
  @spec runtime_config(GenServer.server()) :: map()
  defdelegate runtime_config(server), to: Session

  @doc """
  Returns current policy status (safety breaker, quota, rate limiter snapshot).
  """
  @spec policy_status(GenServer.server()) :: map()
  defdelegate policy_status(server), to: Session

  @doc """
  Returns send health counters and guard state for a running session.
  """
  @spec health_status(GenServer.server()) :: map()
  defdelegate health_status(server), to: Session

  @doc """
  Gracefully disconnects from WhatsApp servers.

  Stops automatic reconnection and closes the connection cleanly.
  Call `connect/1` to reconnect.
  """
  @spec disconnect(Client.t() | GenServer.server()) ::
          {:ok, Client.t()} | {:error, Error.t(), Client.t()} | :ok
  def disconnect(%Client{} = client), do: Client.API.disconnect(client)

  def disconnect(server), do: Session.disconnect(server)

  @doc """
  Lists all chats for a session.

  Returns chats sorted by last message timestamp (most recent first).

  ## Example

      chats = ExWapp.list_chats(session)
      Enum.each(chats, fn chat ->
        IO.puts("\#{chat.name || chat.jid} - \#{chat.unread_count} unread")
      end)
  """
  @spec list_chats(Client.t() | GenServer.server()) ::
          {:ok, [Chat.chat()]} | {:error, Error.t(), Client.t()} | [Chat.chat()]
  def list_chats(%Client{} = client), do: Client.API.list_chats(client)
  def list_chats(session), do: Chat.list(session)

  @doc """
  Lists only group chats for a session.

  Returns chats where JID ends with `@g.us`, sorted by most recent activity.
  """
  @spec list_groups(Client.t() | GenServer.server()) ::
          {:ok, [Chat.chat()]} | {:error, Error.t(), Client.t()} | [Chat.chat()]
  def list_groups(%Client{} = client), do: Client.API.list_groups(client)
  def list_groups(session), do: Chat.list_groups(session)

  @doc """
  Gets a specific chat by JID.

  ## Example

      {:ok, chat} = ExWapp.get_chat(session, "1234567890@s.whatsapp.net")
      IO.inspect(ExWapp.get_messages(session, chat.jid, limit: 20))
  """
  @spec get_chat(Client.t() | GenServer.server(), String.t()) ::
          {:ok, Chat.chat()} | {:error, Error.t(), Client.t()} | {:error, :not_found}
  def get_chat(%Client{} = client, jid), do: Client.API.get_chat(client, jid)
  def get_chat(session, jid), do: Chat.get(session, jid)

  @doc """
  Gets locally retained messages for a chat, newest first.

  With a high-level client this returns `{:ok, messages}` (or a structured
  client error); with a direct session it returns the message list.

  ## Options

    * `:limit` - Maximum messages to return (default: 50), or `:all`
    * `:offset` - Number of messages to skip (default: 0)

  `limit: :all` reads every message retained locally for that chat. It does
  not trigger an on-demand download of older WhatsApp history.

  ## Examples

      {:ok, recent} = ExWapp.get_messages(client, jid, limit: 20)
      all_local = ExWapp.get_messages(session, jid, limit: :all)
  """
  @spec get_messages(Client.t() | GenServer.server(), String.t(), keyword()) ::
          {:ok, [Chat.message()]} | {:error, Error.t(), Client.t()} | [Chat.message()]
  def get_messages(target, jid, opts \\ [])
  def get_messages(%Client{} = client, jid, opts), do: Client.API.get_messages(client, jid, opts)
  def get_messages(session, jid, opts), do: Chat.messages(session, jid, opts)

  @doc """
  Builds a lazy stream over locally retained messages.

  The default order is oldest first, which is suitable for inserting history
  into a wrapper database. Message payloads are read from the dedicated message
  store one at a time; the complete history is not stored in or loaded through
  the chat struct.

  ## Options

    * `:order` - `:oldest_first` (default) or `:newest_first`
    * `:offset` - Number of records to skip (default: 0)
    * `:limit` - Optional maximum; defaults to `:all`

  This stream represents local history and does not request older messages
  from WhatsApp.
  """
  @spec stream_messages(Client.t() | GenServer.server(), String.t(), keyword()) ::
          {:ok, Enumerable.t()} | {:error, Error.t(), Client.t()} | Enumerable.t()
  def stream_messages(target, jid, opts \\ [])

  def stream_messages(%Client{} = client, jid, opts),
    do: Client.API.stream_messages(client, jid, opts)

  def stream_messages(session, jid, opts), do: Chat.stream_messages(session, jid, opts)

  @doc """
  Returns the unbounded local message stream for a chat.

  This is the explicit convenience form of stream_messages/3.
  """
  @spec all_messages(Client.t() | GenServer.server(), String.t(), keyword()) ::
          {:ok, Enumerable.t()} | {:error, Error.t(), Client.t()} | Enumerable.t()
  def all_messages(target, jid, opts \\ [])
  def all_messages(%Client{} = client, jid, opts), do: Client.API.all_messages(client, jid, opts)
  def all_messages(session, jid, opts), do: Chat.all_messages(session, jid, opts)

  @doc """
  Deletes selected local messages after they have been persisted elsewhere.

  Delete only IDs that the wrapper has committed successfully. With a client,
  the updated client is returned; with a direct session/store the result is
  `:ok` or a store error.
  """
  @spec delete_messages(
          Client.t() | GenServer.server(),
          String.t(),
          [String.t()]
        ) :: {:ok, Client.t()} | {:error, Error.t(), Client.t()} | :ok | {:error, term()}
  def delete_messages(%Client{} = client, jid, message_ids),
    do: Client.API.delete_messages(client, jid, message_ids)

  def delete_messages(session, jid, message_ids),
    do: Chat.delete_messages(session, jid, message_ids)

  @doc """
  Marks all messages in a chat as read.

  ## Example

      ExWapp.mark_chat_read(session, "1234567890@s.whatsapp.net")
  """
  @spec mark_chat_read(GenServer.server(), String.t()) :: :ok
  def mark_chat_read(session, jid), do: Chat.mark_read(session, jid)

  @doc """
  Sends a text message to a contact or group.

  Accepts either a session pid or a session_id string.

  When called with a **pid**, the call is synchronous and returns the message ID.
  When called with a **session_id string**, the send command is dispatched via
  PubSub (fire-and-forget) and returns `:ok` immediately.

  ## Returns

    * `{:ok, message_id}` - Message was queued for sending (pid path)
    * `:ok` - Send command dispatched via PubSub (session_id path)
    * `{:error, reason}` - Failed to send

  ## Examples

      # With session pid (synchronous, returns message_id)
      {:ok, id} = ExWapp.send_message(session, "1234567890@s.whatsapp.net", "Hello!")

      # With session_id string (fire-and-forget via PubSub)
      :ok = ExWapp.send_message("my_session", "1234567890@s.whatsapp.net", "Hello!")
  """
  @spec send_message(Client.t(), keyword()) ::
          {:ok, Client.t(), String.t()} | {:error, Error.t(), Client.t()}
  def send_message(%Client{} = client, opts) when is_list(opts),
    do: Client.API.send_message(client, opts)

  @spec send_message(pid() | binary(), String.t(), String.t()) ::
          {:ok, String.t()} | :ok | {:error, term()}
  def send_message(session, jid, text)

  def send_message(session, jid, text) when is_pid(session) do
    Session.send_text(session, jid, text)
  end

  def send_message(session_id, jid, text) when is_binary(session_id) do
    Phoenix.PubSub.broadcast(
      ExWapp.PubSub,
      "ex_wapp:commands:#{session_id}",
      {:ex_wapp_send, jid, text}
    )
  end

  @doc """
  Sends an image through a high-level client.
  """
  @spec send_image(Client.t() | GenServer.server(), String.t(), ExWapp.Media.source(), keyword()) ::
          {:ok, Client.t(), String.t()}
          | {:error, Error.t(), Client.t()}
          | {:ok, String.t()}
          | {:error, term()}
  def send_image(target, to, source, opts \\ [])

  def send_image(%Client{} = client, to, source, opts),
    do: Client.API.send_image(client, to, source, opts)

  def send_image(session, to, source, opts), do: Session.send_image(session, to, source, opts)

  @doc """
  Sends audio through a high-level client.
  """
  @spec send_audio(Client.t() | GenServer.server(), String.t(), ExWapp.Media.source(), keyword()) ::
          {:ok, Client.t(), String.t()}
          | {:error, Error.t(), Client.t()}
          | {:ok, String.t()}
          | {:error, term()}
  def send_audio(target, to, source, opts \\ [])

  def send_audio(%Client{} = client, to, source, opts),
    do: Client.API.send_audio(client, to, source, opts)

  def send_audio(session, to, source, opts), do: Session.send_audio(session, to, source, opts)

  @doc "Sends a document through a high-level client or a session process."
  @spec send_document(
          Client.t() | GenServer.server(),
          String.t(),
          ExWapp.Media.source(),
          keyword()
        ) ::
          {:ok, Client.t(), String.t()}
          | {:error, Error.t(), Client.t()}
          | {:ok, String.t()}
          | {:error, term()}
  def send_document(target, to, source, opts \\ [])

  def send_document(%Client{} = client, to, source, opts),
    do: Client.API.send_document(client, to, source, opts)

  def send_document(session, to, source, opts),
    do: Session.send_document(session, to, source, opts)

  @doc "Sends a GPS location through a high-level client or a session process."
  @spec send_location(
          Client.t() | GenServer.server(),
          String.t(),
          number(),
          number(),
          keyword()
        ) ::
          {:ok, Client.t(), String.t()}
          | {:error, Error.t(), Client.t()}
          | {:ok, String.t()}
          | {:error, term()}
  def send_location(target, to, latitude, longitude, opts \\ [])

  def send_location(%Client{} = client, to, latitude, longitude, opts),
    do: Client.API.send_location(client, to, latitude, longitude, opts)

  def send_location(session, to, latitude, longitude, opts),
    do: Session.send_location(session, to, latitude, longitude, opts)

  @doc "Sends one vCard contact through a high-level client or session process."
  @spec send_contact(
          Client.t() | GenServer.server(),
          String.t(),
          String.t(),
          String.t(),
          keyword()
        ) ::
          {:ok, Client.t(), String.t()}
          | {:error, Error.t(), Client.t()}
          | {:ok, String.t()}
          | {:error, term()}
  def send_contact(target, to, display_name, vcard, opts \\ [])

  def send_contact(%Client{} = client, to, display_name, vcard, opts),
    do: Client.API.send_contact(client, to, display_name, vcard, opts)

  def send_contact(session, to, display_name, vcard, opts),
    do: Session.send_contact(session, to, display_name, vcard, opts)

  @doc "Sends WhatsApp's experimental calendar event message."
  @spec send_event(
          Client.t() | GenServer.server(),
          String.t(),
          String.t(),
          integer() | DateTime.t(),
          keyword()
        ) ::
          {:ok, Client.t(), String.t()}
          | {:error, Error.t(), Client.t()}
          | {:ok, String.t()}
          | {:error, term()}
  def send_event(target, to, name, start_time, opts \\ [])

  def send_event(%Client{} = client, to, name, start_time, opts),
    do: Client.API.send_event(client, to, name, start_time, opts)

  def send_event(session, to, name, start_time, opts),
    do: Session.send_event(session, to, name, start_time, opts)

  @doc "Downloads and decrypts image, audio, or document media."
  @spec download_media(
          Client.t() | GenServer.server(),
          ExWapp.Media.Ref.t(),
          keyword()
        ) ::
          {:ok, Client.t(), ExWapp.Media.Download.t()}
          | {:error, Error.t(), Client.t()}
          | {:ok, ExWapp.Media.Download.t()}
          | {:error, term()}
  def download_media(target, ref, opts \\ [])

  def download_media(%Client{} = client, ref, opts),
    do: Client.API.download_media(client, ref, opts)

  def download_media(session, ref, opts), do: Session.download_media(session, ref, opts)

  @doc "Requests a fresh direct path for locally stored media by message ID."
  @spec retry_media(GenServer.server(), String.t(), keyword()) ::
          {:ok, ExWapp.Media.Ref.t()} | {:error, term()}
  def retry_media(session, message_id, opts \\ []),
    do: Session.retry_media(session, message_id, opts)

  @doc """
  Handles an inbound payload through a high-level client transport.
  """
  @spec receive_message(Client.t(), term(), keyword()) ::
          {:ok, Client.t(), [Event.t()]} | {:error, Error.t(), Client.t()}
  def receive_message(%Client{} = client, payload, opts \\ []),
    do: Client.API.receive_message(client, payload, opts)

  @doc """
  Returns the status of a high-level client.
  """
  @spec status(Client.t()) :: Client.status()
  def status(%Client{} = client), do: Client.API.status(client)

  @doc """
  Returns the last structured error recorded on a high-level client.
  """
  @spec last_error(Client.t()) :: Error.t() | nil
  def last_error(%Client{} = client), do: Client.API.last_error(client)

  @doc """
  Returns a compact diagnostics map for a high-level client.
  """
  @spec diagnostics(Client.t()) :: map()
  def diagnostics(%Client{} = client), do: Client.API.diagnostics(client)

  @doc """
  Controls a session worker using either pid (direct cast) or session_id (PubSub command).

  Supported actions:
  - `:pause_sends`
  - `:resume_sends`
  - `:disconnect`
  - `:stop_session`
  """
  @spec control_session(
          pid() | binary(),
          :pause_sends | :resume_sends | :disconnect | :stop_session
        ) ::
          :ok
  def control_session(session, action)

  def control_session(session, action) when is_pid(session) do
    case action do
      :pause_sends -> Session.pause_sends(session)
      :resume_sends -> Session.resume_sends(session)
      :disconnect -> Session.disconnect(session)
      :stop_session -> Session.stop_worker(session)
    end
  end

  def control_session(session_id, action) when is_binary(session_id) do
    Phoenix.PubSub.broadcast(
      ExWapp.PubSub,
      "ex_wapp:commands:#{session_id}",
      {:ex_wapp_control, action}
    )
  end

  @doc """
  Sends a read receipt to mark messages as read.

  ## Example

      ExWapp.send_read_receipt(session, jid, ["MSG_ID_1", "MSG_ID_2"])
  """
  @spec send_read_receipt(GenServer.server(), String.t(), [String.t()]) :: :ok | {:error, term()}
  def send_read_receipt(session, jid, message_ids) do
    Messages.send_read_receipt(session, jid, message_ids)
  end

  @doc """
  Sends a typing indicator to a chat.

  ## Example

      # Show typing
      ExWapp.send_typing(session, jid, true)

      # Stop typing
      ExWapp.send_typing(session, jid, false)
  """
  @spec send_typing(GenServer.server(), String.t(), boolean()) :: :ok | {:error, term()}
  def send_typing(session, jid, composing \\ true) do
    node = Messages.build_typing(jid, composing)

    try do
      conn = GenServer.call(session, :get_conn)
      if conn, do: ExWapp.Conn.send_node(conn, node), else: {:error, :not_connected}
    catch
      :exit, _ -> {:error, :session_unavailable}
    end
  end

  @doc """
  Builds a lazy stream of incoming messages.

  Each element is a tuple of `{jid, message}`.

  ## Example

      ExWapp.message_stream(session)
      |> Stream.each(fn {jid, msg} ->
        IO.puts("[\#{jid}] \#{msg.text}")
      end)
      |> Stream.run()
  """
  @spec message_stream(GenServer.server()) :: Enumerable.t()
  defdelegate message_stream(session), to: Session

  @doc """
  Subscribe the calling process to a session's events via PubSub.

  Subscribes to **both** incoming messages and session lifecycle events
  in a single call. Accepts either a session pid or a session_id string.

  ## Messages received

  - `{:ex_wapp_message, jid, message}` - incoming WhatsApp message
  - `{:ex_wapp_session, :connected}` - session connected
  - `{:ex_wapp_session, :error, reason}` - session-level error event
  - `{:ex_wapp_session, :disconnected, reason}` - session disconnected
  - `{:ex_wapp_session, :terminated, reason}` - session process stopped
  - `{:ex_wapp_health, type, metadata}` - send health/error/guard events

  ## Example

      ExWapp.subscribe(session)
      # or
      ExWapp.subscribe("my_session")

      def handle_info({:ex_wapp_message, jid, message}, state) do
        IO.puts("Message from \#{jid}")
        {:noreply, state}
      end

      def handle_info({:ex_wapp_session, :connected}, state) do
        {:noreply, assign(state, :status, :connected)}
      end

      def handle_info({:ex_wapp_session, :disconnected, _reason}, state) do
        {:noreply, assign(state, :status, :disconnected)}
      end
  """
  @spec subscribe(pid() | term()) :: :ok | {:error, term()}
  def subscribe(session) when is_pid(session) do
    session_id = Session.get_session_id(session) || session
    Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:messages:#{session_id}")
    Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:session:#{session_id}")
    Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:health:#{session_id}")
  end

  def subscribe(session_id) do
    Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:messages:#{session_id}")
    Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:session:#{session_id}")
    Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:health:#{session_id}")
  end

  @doc """
  Unsubscribe the calling process from a session's events.

  Unsubscribes from both messages and lifecycle topics.
  Accepts either a session pid or a session_id string.
  """
  @spec unsubscribe(pid() | term()) :: :ok
  def unsubscribe(session) when is_pid(session) do
    session_id = Session.get_session_id(session) || session
    Phoenix.PubSub.unsubscribe(ExWapp.PubSub, "ex_wapp:messages:#{session_id}")
    Phoenix.PubSub.unsubscribe(ExWapp.PubSub, "ex_wapp:session:#{session_id}")
    Phoenix.PubSub.unsubscribe(ExWapp.PubSub, "ex_wapp:health:#{session_id}")
  end

  def unsubscribe(session_id) do
    Phoenix.PubSub.unsubscribe(ExWapp.PubSub, "ex_wapp:messages:#{session_id}")
    Phoenix.PubSub.unsubscribe(ExWapp.PubSub, "ex_wapp:session:#{session_id}")
    Phoenix.PubSub.unsubscribe(ExWapp.PubSub, "ex_wapp:health:#{session_id}")
  end

  @doc """
  Subscribe to events from ALL sessions via PubSub.

  Subscribes to both global messages and global lifecycle topics.

  ## Messages received

  - `{:ex_wapp_message, session_id, jid, message}` - message from any session
  - `{session_id, {:ex_wapp_session, event, ...}}` - lifecycle from any session
  - `{session_id, {:ex_wapp_health, type, metadata}}` - health events from any session
  """
  @spec subscribe_all() :: :ok | {:error, term()}
  def subscribe_all do
    Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:messages")
    Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:session")
    Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:health")
  end

  @doc """
  Unsubscribe from all global topics (messages + lifecycle).
  """
  @spec unsubscribe_all() :: :ok
  def unsubscribe_all do
    Phoenix.PubSub.unsubscribe(ExWapp.PubSub, "ex_wapp:messages")
    Phoenix.PubSub.unsubscribe(ExWapp.PubSub, "ex_wapp:session")
    Phoenix.PubSub.unsubscribe(ExWapp.PubSub, "ex_wapp:health")
  end

  @doc """
  Archives a chat (server-synced via app state).

  Falls back to local-only archive if not connected.
  """
  @spec archive_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def archive_chat(session, jid) do
    case Session.archive_chat(session, jid) do
      :ok -> :ok
      {:error, {:not_connected, _}} -> Chat.archive(session, jid)
      error -> error
    end
  end

  @doc """
  Unarchives a chat (server-synced via app state).
  """
  @spec unarchive_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def unarchive_chat(session, jid) do
    case Session.unarchive_chat(session, jid) do
      :ok -> :ok
      {:error, {:not_connected, _}} -> Chat.unarchive(session, jid)
      error -> error
    end
  end

  @doc """
  Pins a chat to the top (server-synced via app state).
  """
  @spec pin_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def pin_chat(session, jid) do
    patch = ExWapp.AppState.Engine.build_pin(jid, true)

    case Session.send_app_state(session, patch) do
      {:ok, _, _} -> :ok
      {:error, {:not_connected, _}} -> Chat.pin(session, jid)
      error -> error
    end
  end

  @doc """
  Unpins a chat (server-synced via app state).
  """
  @spec unpin_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def unpin_chat(session, jid) do
    patch = ExWapp.AppState.Engine.build_pin(jid, false)

    case Session.send_app_state(session, patch) do
      {:ok, _, _} -> :ok
      {:error, {:not_connected, _}} -> Chat.unpin(session, jid)
      error -> error
    end
  end

  @doc """
  Deletes a chat (server-synced via app state).
  """
  @spec delete_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def delete_chat(session, jid) do
    case Session.delete_chat(session, jid) do
      :ok -> :ok
      {:error, {:not_connected, _}} -> Chat.delete(session, jid)
      error -> error
    end
  end

  @doc """
  Mutes a chat (server-synced via app state).

  `mute_end_timestamp` is milliseconds epoch, or -1 for forever, or 0/nil to unmute.
  """
  @spec mute_chat(GenServer.server(), String.t(), integer()) :: :ok | {:error, term()}
  def mute_chat(session, jid, mute_end_timestamp \\ -1) do
    patch = ExWapp.AppState.Engine.build_mute(jid, true, mute_end_timestamp)

    case Session.send_app_state(session, patch) do
      {:ok, _, _} -> :ok
      error -> error
    end
  end

  @doc """
  Unmutes a chat (server-synced via app state).
  """
  @spec unmute_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def unmute_chat(session, jid) do
    patch = ExWapp.AppState.Engine.build_mute(jid, false)

    case Session.send_app_state(session, patch) do
      {:ok, _, _} -> :ok
      error -> error
    end
  end

  @doc """
  Marks a chat as read (server-synced via app state).
  """
  @spec mark_chat_as_read(GenServer.server(), String.t()) :: :ok | {:error, term()}
  def mark_chat_as_read(session, jid) do
    patch = ExWapp.AppState.Engine.build_mark_read(jid, true)

    case Session.send_app_state(session, patch) do
      {:ok, _, _} -> :ok
      {:error, {:not_connected, _}} -> Chat.mark_read(session, jid)
      error -> error
    end
  end

  @doc """
  Creates or updates a contact (server-synced via app state).
  """
  @spec create_contact(Client.t() | GenServer.server(), String.t(), String.t()) ::
          {:ok, Client.t()} | {:error, Error.t(), Client.t()} | :ok | {:error, term()}
  def create_contact(%Client{} = client, jid, name),
    do: Client.API.create_contact(client, jid, name)

  defdelegate create_contact(session, jid, name), to: Session

  @doc """
  Deletes a contact (server-synced via app state).
  """
  @spec delete_contact(Client.t() | GenServer.server(), String.t()) ::
          {:ok, Client.t()} | {:error, Error.t(), Client.t()} | :ok | {:error, term()}
  def delete_contact(%Client{} = client, jid),
    do: Client.API.delete_contact(client, jid)

  defdelegate delete_contact(session, jid), to: Session

  @doc """
  Fetches and applies the contacts collection from app state (`critical_unblock_low`).
  """
  @spec sync_contacts(Client.t() | GenServer.server()) ::
          {:ok, Client.t()} | {:error, Error.t(), Client.t()} | :ok | {:error, term()}
  def sync_contacts(%Client{} = client),
    do: Client.API.sync_contacts(client)

  defdelegate sync_contacts(session), to: Session

  @doc """
  Lists all contacts.
  """
  @spec list_contacts(Client.t() | GenServer.server()) ::
          {:ok, [ExWapp.Contact.t()]} | {:error, Error.t(), Client.t()} | [ExWapp.Contact.t()]
  def list_contacts(%Client{} = client), do: Client.API.list_contacts(client)
  defdelegate list_contacts(session), to: Session

  @doc """
  Gets a specific contact by JID.
  """
  @spec get_contact(Client.t() | GenServer.server(), String.t()) ::
          {:ok, ExWapp.Contact.t() | nil}
          | {:error, Error.t(), Client.t()}
          | ExWapp.Contact.t()
          | nil
  def get_contact(%Client{} = client, jid), do: Client.API.get_contact(client, jid)
  defdelegate get_contact(session, jid), to: Session

  @doc """
  Returns local metadata for a specific chat.
  """
  @spec get_chat_info(GenServer.server(), String.t()) ::
          {:ok, ExWapp.Chat.chat()} | {:error, :not_found}
  defdelegate get_chat_info(session, jid), to: Session
end
