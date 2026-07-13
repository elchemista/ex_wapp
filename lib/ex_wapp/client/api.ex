defmodule ExWapp.Client.API do
  @moduledoc """
  Runtime-neutral operations for `ExWapp.Client`.

  This module contains the high-level client workflow used by the public
  `ExWapp` facade. It coordinates transport adapters, client status updates,
  telemetry, tracing, and event emission without depending on a session process
  directly.
  """

  require Logger

  alias ExWapp.{Chat, Client, Error, Event, Message, Messages}

  @type client_error :: {:error, Error.t(), Client.t()}
  @type message_result :: {:ok, Client.t(), String.t()} | client_error()
  @type mutation_result :: {:ok, Client.t()} | client_error()
  @type download_result :: {:ok, Client.t(), ExWapp.Media.Download.t()} | client_error()
  @typep read_result(value) :: {:ok, value} | client_error()

  @doc """
  Connects a client through its configured transport adapter.

  Emits client connect telemetry and records a status event when the transport
  succeeds.
  """
  @spec connect(Client.t()) :: {:ok, Client.t()} | client_error()
  def connect(%Client{} = client) do
    start_ms = System.monotonic_time(:millisecond)
    emit_connect_start(client)

    client.transport.connect(client)
    |> finish_connect(client, start_ms)
  end

  @doc """
  Starts pairing through the configured transport adapter.

  On success the client moves to `:pairing` and a QR event is emitted with the
  transport payload.
  """
  @spec pair(Client.t()) :: {:ok, Client.t(), term()} | client_error()
  def pair(%Client{} = client) do
    case client.transport.pair(client) do
      {:ok, updated_client, qr_payload} ->
        updated_client = %{updated_client | status: :pairing}

        :ok =
          emit_event(
            updated_client,
            Event.new(:qr, qr_payload, session_id: updated_client.session_id)
          )

        {:ok, updated_client, qr_payload}

      {:error, reason} ->
        client_error(client, :pair, :transport, reason)
    end
  end

  @doc """
  Disconnects a client through its configured transport adapter.
  """
  @spec disconnect(Client.t()) :: {:ok, Client.t()} | client_error()
  def disconnect(%Client{} = client) do
    case client.transport.disconnect(client) do
      {:ok, updated_client} -> {:ok, %{updated_client | status: :disconnected}}
      :ok -> {:ok, %{client | status: :disconnected}}
      {:error, reason} -> client_error(client, :disconnect, :transport, reason)
    end
  end

  @doc """
  Sends a text message from keyword options.

  Required options are `:to` and `:text`; remaining options are passed to
  `ExWapp.Message.text/3`.
  """
  @spec send_message(Client.t(), keyword()) :: message_result()
  def send_message(%Client{} = client, opts) when is_list(opts) do
    opts
    |> text_message()
    |> send_client_message(client, :send_message)
  end

  @doc """
  Sends an image message through the configured transport adapter.
  """
  @spec send_image(Client.t(), String.t(), ExWapp.Media.source(), keyword()) :: message_result()
  def send_image(%Client{} = client, to, source, opts \\ []) do
    to
    |> Message.image(source, opts)
    |> send_client_message(client, :send_image)
  end

  @doc """
  Sends an audio message through the configured transport adapter.
  """
  @spec send_audio(Client.t(), String.t(), ExWapp.Media.source(), keyword()) :: message_result()
  def send_audio(%Client{} = client, to, source, opts \\ []) do
    to
    |> Message.audio(source, opts)
    |> send_client_message(client, :send_audio)
  end

  @doc """
  Sends a document message through the configured transport adapter.
  """
  @spec send_document(Client.t(), String.t(), ExWapp.Media.source(), keyword()) ::
          message_result()
  def send_document(%Client{} = client, to, source, opts \\ []) do
    to
    |> Message.document(source, opts)
    |> send_client_message(client, :send_document)
  end

  @doc """
  Sends a GPS location through the configured transport adapter.
  """
  @spec send_location(Client.t(), String.t(), number(), number(), keyword()) :: message_result()
  def send_location(%Client{} = client, to, latitude, longitude, opts \\ []) do
    to
    |> Message.location(latitude, longitude, opts)
    |> send_client_message(client, :send_location)
  end

  @doc """
  Sends a WhatsApp contact card through the configured transport adapter.
  """
  @spec send_contact(Client.t(), String.t(), String.t(), String.t(), keyword()) ::
          message_result()
  def send_contact(%Client{} = client, to, display_name, vcard, opts \\ []) do
    to
    |> Message.contact(display_name, vcard, opts)
    |> send_client_message(client, :send_contact)
  end

  @doc """
  Sends WhatsApp's calendar event message through the configured transport.
  """
  @spec send_event(
          Client.t(),
          String.t(),
          String.t(),
          integer() | DateTime.t(),
          keyword()
        ) :: message_result()
  def send_event(%Client{} = client, to, name, start_time, opts \\ []) do
    to
    |> Message.event(name, start_time, opts)
    |> send_client_message(client, :send_event)
  end

  @doc """
  Downloads and decrypts a media reference through the configured transport.
  """
  @spec download_media(Client.t(), ExWapp.Media.Ref.t(), keyword()) :: download_result()
  def download_media(%Client{} = client, %ExWapp.Media.Ref{} = ref, opts \\ []) do
    if Code.ensure_loaded?(client.transport) and
         function_exported?(client.transport, :download_media, 3) do
      client.transport.download_media(client, ref, opts)
      |> normalize_downloaded_media(client)
    else
      client_error(client, :download_media, :transport, :unsupported_operation)
    end
  end

  @doc """
  Handles an inbound transport payload and emits any returned events.
  """
  @spec receive_message(Client.t(), term(), keyword()) ::
          {:ok, Client.t(), [Event.t()]} | client_error()
  def receive_message(%Client{} = client, payload, opts \\ []) do
    client.transport.receive_message(client, payload, opts)
    |> normalize_received_events(client)
  end

  @doc """
  Lists contacts through the configured transport adapter.
  """
  @spec list_contacts(Client.t()) :: read_result([ExWapp.Contact.t()])
  def list_contacts(%Client{} = client), do: client_read(client, :list_contacts, [])

  @doc """
  Fetches one contact by JID through the configured transport adapter.
  """
  @spec get_contact(Client.t(), String.t()) :: read_result(ExWapp.Contact.t() | nil)
  def get_contact(%Client{} = client, jid), do: client_read(client, :get_contact, [jid])

  @doc """
  Synchronizes contacts through the configured transport adapter.
  """
  @spec sync_contacts(Client.t()) :: mutation_result()
  def sync_contacts(%Client{} = client),
    do: client_mutation(client, :sync_contacts, [], :contacts_synced)

  @doc """
  Creates a contact through the configured transport adapter.
  """
  @spec create_contact(Client.t(), String.t(), String.t()) :: mutation_result()
  def create_contact(%Client{} = client, jid, name),
    do: client_mutation(client, :create_contact, [jid, name], :contact_created)

  @doc """
  Deletes a contact through the configured transport adapter.
  """
  @spec delete_contact(Client.t(), String.t()) :: mutation_result()
  def delete_contact(%Client{} = client, jid),
    do: client_mutation(client, :delete_contact, [jid], :contact_deleted)

  @doc """
  Lists chats through the configured transport adapter.
  """
  @spec list_chats(Client.t()) :: read_result([Chat.chat()])
  def list_chats(%Client{} = client), do: client_read(client, :list_chats, [])

  @doc """
  Lists group chats through the configured transport adapter.
  """
  @spec list_groups(Client.t()) :: read_result([Chat.chat()])
  def list_groups(%Client{} = client), do: client_read(client, :list_groups, [])

  @doc """
  Fetches one chat by JID through the configured transport adapter.
  """
  @spec get_chat(Client.t(), String.t()) :: read_result(Chat.chat())
  def get_chat(%Client{} = client, jid), do: client_read(client, :get_chat, [jid])

  @doc """
  Gets locally retained messages for a chat through the configured transport.

  The `:limit` option accepts a non-negative integer or `:all`; `:offset`
  skips messages from the newest-first result.
  """
  @spec get_messages(Client.t(), String.t(), keyword()) :: read_result([Chat.message()])
  def get_messages(%Client{} = client, jid, opts \\ []),
    do: client_read(client, :get_messages, [jid, opts])

  @doc """
  Builds a lazy stream over locally retained messages.

  The stream is oldest first by default and delegates cursor ownership to the
  configured adapter. It does not trigger remote WhatsApp history retrieval.
  """
  @spec stream_messages(Client.t(), String.t(), keyword()) :: read_result(Enumerable.t())
  def stream_messages(%Client{} = client, jid, opts \\ []),
    do: client_read(client, :stream_messages, [jid, opts])

  @doc """
  Returns a lazy stream over every locally retained message.
  """
  @spec all_messages(Client.t(), String.t(), keyword()) :: read_result(Enumerable.t())
  def all_messages(%Client{} = client, jid, opts \\ []),
    do: stream_messages(client, jid, Keyword.put_new(opts, :limit, :all))

  @doc """
  Deletes selected local messages after durable wrapper persistence.
  """
  @spec delete_messages(Client.t(), String.t(), [String.t()]) :: mutation_result()
  def delete_messages(%Client{} = client, jid, message_ids),
    do: client_mutation(client, :delete_messages, [jid, message_ids], :messages_deleted)

  @doc """
  Returns the current client status.
  """
  @spec status(Client.t()) :: Client.status()
  def status(%Client{} = client), do: client.status

  @doc """
  Returns the most recent structured client error, if any.
  """
  @spec last_error(Client.t()) :: Error.t() | nil
  def last_error(%Client{} = client), do: client.last_error

  @doc """
  Returns a compact diagnostics map for logging, debugging, or health checks.
  """
  @spec diagnostics(Client.t()) :: map()
  def diagnostics(%Client{} = client) do
    %{
      session_id: client.session_id,
      status: client.status,
      last_error: client.last_error,
      trace: client.trace,
      metadata: client.metadata
    }
  end

  @spec text_message(keyword()) :: Message.t()
  defp text_message(opts) do
    to = Keyword.fetch!(opts, :to)
    text = Keyword.fetch!(opts, :text)

    Message.text(to, text, Keyword.drop(opts, [:to, :text]))
  end

  @spec send_client_message(Message.t(), Client.t(), atom()) :: message_result()
  defp send_client_message(%Message{} = message, %Client{} = client, operation) do
    message = ensure_message_id(message, client)

    client.transport.send_message(client, message)
    |> normalize_sent_message(client, message, operation)
  end

  @spec ensure_message_id(Message.t(), Client.t()) :: Message.t()
  defp ensure_message_id(%Message{id: nil} = message, %Client{} = client) do
    %{message | id: Messages.generate_id(client.session_id)}
  end

  defp ensure_message_id(%Message{} = message, %Client{}), do: message

  @spec normalize_sent_message(term(), Client.t(), Message.t(), atom()) :: message_result()
  defp normalize_sent_message(
         {:ok, %Client{} = updated_client, message_id},
         _client,
         message,
         operation
       ) do
    {:ok, record_sent_message(updated_client, message, message_id, operation), message_id}
  end

  defp normalize_sent_message({:ok, message_id}, %Client{} = client, message, operation) do
    {:ok, record_sent_message(client, message, message_id, operation), message_id}
  end

  defp normalize_sent_message(
         {:error, %Client{} = updated_client, reason},
         _client,
         _message,
         operation
       ) do
    client_error(updated_client, operation, :transport, reason)
  end

  defp normalize_sent_message({:error, reason}, %Client{} = client, _message, operation) do
    client_error(client, operation, :transport, reason)
  end

  @spec normalize_downloaded_media(term(), Client.t()) :: download_result()
  defp normalize_downloaded_media(
         {:ok, %Client{} = updated_client, %ExWapp.Media.Download{} = download},
         _client
       ) do
    {:ok, Client.trace(updated_client, :download_media), download}
  end

  defp normalize_downloaded_media({:ok, %ExWapp.Media.Download{} = download}, client) do
    {:ok, Client.trace(client, :download_media), download}
  end

  defp normalize_downloaded_media({:error, reason}, client) do
    client_error(client, :download_media, :transport, reason)
  end

  @spec record_sent_message(Client.t(), Message.t(), String.t(), atom()) :: Client.t()
  defp record_sent_message(%Client{} = client, %Message{} = message, message_id, operation) do
    updated_client = Client.trace(client, operation, %{message_id: message_id})

    event =
      Event.new(:message_sent, %{id: message_id, to: message.to, type: message.type},
        session_id: updated_client.session_id
      )

    :ok = emit_event(updated_client, event)
    updated_client
  end

  @spec normalize_received_events(term(), Client.t()) ::
          {:ok, Client.t(), [Event.t()]} | client_error()
  defp normalize_received_events({:ok, %Client{} = updated_client, events}, _client)
       when is_list(events) do
    :ok = ExWapp.Events.emit_many(updated_client, events)
    {:ok, Client.trace(updated_client, :receive_message, %{event_count: length(events)}), events}
  end

  defp normalize_received_events({:ok, events}, %Client{} = client) when is_list(events) do
    :ok = ExWapp.Events.emit_many(client, events)
    {:ok, Client.trace(client, :receive_message, %{event_count: length(events)}), events}
  end

  defp normalize_received_events({:error, reason}, %Client{} = client) do
    client_error(client, :receive_message, :transport, reason)
  end

  @spec client_read(Client.t(), atom(), [term()]) :: read_result(term())
  defp client_read(%Client{} = client, function, args) do
    arity = length(args) + 1

    if Code.ensure_loaded?(client.transport) and
         function_exported?(client.transport, function, arity) do
      case apply(client.transport, function, [client | args]) do
        {:ok, value} -> {:ok, value}
        {:error, reason} -> client_error(client, function, :transport, reason)
      end
    else
      client_error(client, function, :transport, :unsupported_operation)
    end
  end

  @spec client_mutation(Client.t(), atom(), [term()], atom()) :: mutation_result()
  defp client_mutation(%Client{} = client, function, args, event_type) do
    case apply(client.transport, function, [client | args]) do
      {:ok, %Client{} = updated_client} ->
        finish_client_mutation(updated_client, function, event_type)

      :ok ->
        finish_client_mutation(client, function, event_type)

      {:error, reason} ->
        client_error(client, function, :transport, reason)
    end
  end

  @spec finish_client_mutation(Client.t(), atom(), atom()) :: {:ok, Client.t()}
  defp finish_client_mutation(%Client{} = client, function, event_type) do
    :ok = emit_event(client, Event.new(event_type, %{}, session_id: client.session_id))
    {:ok, Client.trace(client, function)}
  end

  @spec finish_connect(term(), Client.t(), integer()) :: {:ok, Client.t()} | client_error()
  defp finish_connect({:ok, %Client{} = updated_client}, %Client{} = client, start_ms) do
    status = connected_status(client, updated_client)
    updated_client = %{updated_client | status: status} |> Client.trace(:connect)

    :ok =
      emit_event(
        updated_client,
        Event.new(:status, status, session_id: updated_client.session_id)
      )

    emit_connect_stop(client, start_ms)

    {:ok, updated_client}
  end

  defp finish_connect({:error, reason}, %Client{} = client, start_ms) do
    emit_connect_exception(client, start_ms, reason)
    client_error(client, :connect, :transport, reason)
  end

  @spec connected_status(Client.t(), Client.t()) :: Client.status()
  defp connected_status(%Client{} = original, %Client{} = updated) do
    if updated.status == original.status, do: :connected, else: updated.status
  end

  @spec emit_connect_start(Client.t()) :: :ok
  defp emit_connect_start(%Client{} = client) do
    :telemetry.execute([:ex_wapp, :client, :connect, :start], %{count: 1}, %{
      session_id: client.session_id
    })
  end

  @spec emit_connect_stop(Client.t(), integer()) :: :ok
  defp emit_connect_stop(%Client{} = client, start_ms) do
    :telemetry.execute([:ex_wapp, :client, :connect, :stop], connect_duration(start_ms), %{
      session_id: client.session_id
    })
  end

  @spec emit_connect_exception(Client.t(), integer(), term()) :: :ok
  defp emit_connect_exception(%Client{} = client, start_ms, reason) do
    :telemetry.execute([:ex_wapp, :client, :connect, :exception], connect_duration(start_ms), %{
      session_id: client.session_id,
      reason: reason
    })
  end

  @spec connect_duration(integer()) :: %{duration: integer()}
  defp connect_duration(start_ms) do
    %{duration: System.monotonic_time(:millisecond) - start_ms}
  end

  @spec emit_event(Client.t(), Event.t()) :: :ok
  defp emit_event(%Client{} = client, %Event{} = event) do
    case ExWapp.Events.emit(client, event) do
      :ok -> :ok
      {:error, _reason} -> :ok
    end
  end

  @spec client_error(Client.t(), atom(), atom(), term()) :: client_error()
  defp client_error(%Client{} = client, operation, phase, reason) do
    error = Error.new(operation, phase, reason)

    failed_client =
      %{client | status: :error, last_error: error}
      |> Client.trace(operation, %{error: reason})

    Logger.error("#{operation} failed: #{inspect(reason)}")

    {:error, error, failed_client}
  end
end
