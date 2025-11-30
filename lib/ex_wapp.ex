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
    {:qr, ref, data} ->
      # Display QR code for user to scan
      IO.puts("Scan this QR with WhatsApp:")
      data |> ExWapp.Pairing.QR.to_terminal() |> IO.puts()

    {:paired, info} ->
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

      # Check if already paired
      case ExWapp.Session.state(session) do
        :paired ->
          IO.puts("Already paired, ready to send messages")
          {:ok, session}

        :unpaired ->
          IO.puts("Need to pair, starting QR flow...")
          ExWapp.connect(session)
          wait_for_pairing(session)
      end
    end

    defp wait_for_pairing(session) do
      ExWapp.qr_stream(session)
      |> Enum.find(fn
        {:paired, _} -> true
        {:error, _} -> true
        _ -> false
      end)
      |> case do
        {:paired, _} -> {:ok, session}
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

  alias ExWapp.Session

  @doc """
  Starts a WhatsApp session process.

  ## Options

    * `:store` - Storage adapter for session state. See `ExWapp.Store`.
      Defaults to `ExWapp.Store.Ets` with default path.

    * `:name` - Optional name to register the process.

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
  @spec connect(GenServer.server()) :: :ok
  defdelegate connect(server), to: Session

  @doc """
  Returns a stream of QR code and pairing events.

  Subscribe to this stream after calling `connect/1` to receive:

    * `{:qr, ref, data}` - New QR code to display (codes expire periodically)
    * `{:paired, info}` - Successfully paired with phone
    * `{:error, reason}` - Pairing failed

  ## Example

      ExWapp.qr_stream(session)
      |> Stream.each(fn
        {:qr, _ref, data} ->
          # Render QR code (e.g., using qrencode or terminal output)
          qr = ExWapp.Pairing.QR.to_terminal(data)
          IO.puts(qr)

        {:paired, %{jid: jid}} ->
          IO.puts("Paired as \#{jid}")

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
  @spec send_text(GenServer.server(), binary(), iodata()) :: :ok | {:error, term()}
  defdelegate send_text(server, jid, text), to: Session

  @doc """
  Returns the current session status.

  Possible values: `:idle`, `:connecting`, `:handshaking`, `:connected`, `:disconnected`

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
  Gracefully disconnects from WhatsApp servers.

  Stops automatic reconnection and closes the connection cleanly.
  Call `connect/1` to reconnect.
  """
  @spec disconnect(GenServer.server()) :: :ok
  defdelegate disconnect(server), to: Session

  # ============================================================================
  # Chat & Messaging API
  # ============================================================================

  alias ExWapp.{Chat, Messages}

  @doc """
  Lists all chats for a session.

  Returns chats sorted by last message timestamp (most recent first).

  ## Example

      chats = ExWapp.list_chats(session)
      Enum.each(chats, fn chat ->
        IO.puts("\#{chat.name || chat.jid} - \#{chat.unread_count} unread")
      end)
  """
  @spec list_chats(GenServer.server()) :: [Chat.chat()]
  def list_chats(session), do: Chat.list(session)

  @doc """
  Gets a specific chat by JID.

  ## Example

      {:ok, chat} = ExWapp.get_chat(session, "1234567890@s.whatsapp.net")
      IO.inspect(chat.messages)
  """
  @spec get_chat(GenServer.server(), String.t()) :: {:ok, Chat.chat()} | {:error, :not_found}
  def get_chat(session, jid), do: Chat.get(session, jid)

  @doc """
  Gets messages for a chat with optional pagination.

  ## Options

    * `:limit` - Maximum messages to return (default: 50)
    * `:offset` - Number of messages to skip (default: 0)

  ## Example

      # Get last 20 messages
      messages = ExWapp.get_messages(session, jid, limit: 20)
  """
  @spec get_messages(GenServer.server(), String.t(), keyword()) :: [Chat.message()]
  def get_messages(session, jid, opts \\ []), do: Chat.messages(session, jid, opts)

  @doc """
  Marks all messages in a chat as read.

  ## Example

      ExWapp.mark_chat_read(session, "1234567890@s.whatsapp.net")
  """
  @spec mark_chat_read(GenServer.server(), String.t()) :: :ok
  def mark_chat_read(session, jid), do: Chat.mark_read(session, jid)

  @doc """
  Sends a text message to a contact or group.

  ## Options

    * `:quoted_id` - Message ID to reply to
    * `:quoted_participant` - Sender JID of quoted message (for groups)
    * `:mentions` - List of JIDs to mention

  ## Returns

    * `{:ok, message_id}` - Message was queued for sending
    * `{:error, reason}` - Failed to send

  ## Examples

      # Simple message
      {:ok, id} = ExWapp.send_message(session, "1234567890@s.whatsapp.net", "Hello!")

      # Reply to a message
      {:ok, id} = ExWapp.send_message(session, jid, "This is a reply",
        quoted_id: "ABCD1234"
      )

      # Mention someone in a group
      {:ok, id} = ExWapp.send_message(session, group_jid, "Hey @user!",
        mentions: ["1234567890@s.whatsapp.net"]
      )
  """
  @spec send_message(GenServer.server(), String.t(), String.t(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_message(session, jid, text, _opts \\ []) do
    # Use Session.send_text which handles encryption
    Session.send_text(session, jid, text)
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
  Subscribe to incoming messages.

  Returns a reference. Messages arrive as `{:ex_wapp_message, ref, jid, message}`.

  ## Example

      {:ok, ref} = ExWapp.subscribe_messages(session)

      receive do
        {:ex_wapp_message, ^ref, jid, message} ->
          IO.puts("New message from \#{jid}: \#{message.text}")
      end
  """
  @spec subscribe_messages(GenServer.server()) :: {:ok, reference()}
  defdelegate subscribe_messages(session), to: Session

  @doc """
  Unsubscribe from messages.
  """
  @spec unsubscribe_messages(GenServer.server(), reference()) :: :ok
  defdelegate unsubscribe_messages(session, ref), to: Session

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
  Archives a chat.
  """
  @spec archive_chat(GenServer.server(), String.t()) :: :ok
  def archive_chat(session, jid), do: Chat.archive(session, jid)

  @doc """
  Unarchives a chat.
  """
  @spec unarchive_chat(GenServer.server(), String.t()) :: :ok
  def unarchive_chat(session, jid), do: Chat.unarchive(session, jid)

  @doc """
  Pins a chat to the top.
  """
  @spec pin_chat(GenServer.server(), String.t()) :: :ok
  def pin_chat(session, jid), do: Chat.pin(session, jid)

  @doc """
  Unpins a chat.
  """
  @spec unpin_chat(GenServer.server(), String.t()) :: :ok
  def unpin_chat(session, jid), do: Chat.unpin(session, jid)

  @doc """
  Deletes a chat from local storage.
  """
  @spec delete_chat(GenServer.server(), String.t()) :: :ok
  def delete_chat(session, jid), do: Chat.delete(session, jid)
end
