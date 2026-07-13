defmodule ExWapp.Client.Transport.Session do
  @moduledoc """
  Built-in high-level transport backed by the full `ExWapp.Session` engine.

  This adapter is the production path for WhatsApp communication. It delegates
  connection lifecycle, Noise/WebSocket frames, authentication, Signal
  encryption, device discovery, storage, outbound confirmation, and inbound
  message delivery to the session worker.

      client =
        ExWapp.new(
          session_id: "agent-1",
          store: {ExWapp.Store.Ets, path: "agent-1.etf"},
          transport: ExWapp.Client.Transport.Session
        )

      {:ok, client} = ExWapp.connect(client)
      {:ok, client, message_id} = ExWapp.send_message(client, to: jid, text: "hello")

  Session events are also available directly from the worker with
  `ExWapp.Session.qr_stream/1`, `ExWapp.Session.message_stream/1`, or PubSub.
  The worker pid is stored in `client.metadata[:session_pid]`.
  """

  @behaviour ExWapp.Client.Transport

  require Logger

  alias ExWapp.{Client, Event, Message, Session}

  @impl true
  @spec connect(Client.t()) :: {:ok, Client.t()} | {:error, term()}
  def connect(%Client{} = client) do
    with {:ok, client, session} <- ensure_session(client) do
      Logger.info("[ExWapp.SessionTransport] connect session_id=#{inspect(client.session_id)}")
      :ok = Session.connect(session)
      {:ok, %{client | status: :connecting}}
    end
  end

  @impl true
  @spec pair(Client.t()) :: {:ok, Client.t(), term()} | {:error, term()}
  def pair(%Client{} = client) do
    with {:ok, client, session} <- ensure_session(client),
         {:ok, ref} <- Session.subscribe_qr(session) do
      :ok = Session.connect(session)

      timeout = get_in(client.metadata, [:pair_timeout]) || 15_000

      receive do
        {:ex_wapp_qr, ^ref, event} ->
          Session.unsubscribe_qr(session, ref)
          {:ok, %{client | status: :pairing}, event}

        {:ex_wapp_qr_closed, ^ref} ->
          {:error, :pairing_closed}
      after
        timeout ->
          Session.unsubscribe_qr(session, ref)
          {:ok, %{client | status: :pairing}, :pending}
      end
    end
  end

  @impl true
  @spec disconnect(Client.t()) :: {:ok, Client.t()}
  def disconnect(%Client{} = client) do
    case session_pid(client) do
      pid when is_pid(pid) ->
        Logger.info(
          "[ExWapp.SessionTransport] disconnect session_id=#{inspect(client.session_id)}"
        )

        Session.disconnect(pid)

      _ ->
        :ok
    end

    {:ok, client}
  end

  @impl true
  @spec send_message(Client.t(), Message.t()) ::
          {:ok, Client.t(), String.t()} | {:error, Client.t(), term()} | {:error, term()}
  def send_message(%Client{} = client, %Message{type: :text, to: to, body: text, id: id}) do
    case ensure_session(client) do
      {:ok, client, session} ->
        case Session.send_text(session, to, text) do
          :ok -> {:ok, client, id}
          {:error, reason} -> {:error, client, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def send_message(%Client{} = client, %Message{type: type} = message)
      when type in [:image, :audio, :document, :location, :contact, :event] do
    with {:ok, client, session} <- ensure_session(client) do
      opts = Keyword.put(message.opts, :retry_message_id, message.id)

      session
      |> send_session_content(message, opts)
      |> normalize_session_send(client)
    end
  end

  def send_message(_client, %Message{type: type}), do: {:error, {:unsupported_message_type, type}}

  @impl true
  @spec receive_message(Client.t(), term(), keyword()) :: {:ok, Client.t(), [Event.t()]}
  def receive_message(%Client{} = client, {:ex_wapp_message, ref, jid, message}, _opts)
      when is_reference(ref) do
    {:ok, client, [message_event(client, jid, message)]}
  end

  def receive_message(%Client{} = client, {:ex_wapp_message, jid, message}, _opts) do
    {:ok, client, [message_event(client, jid, message)]}
  end

  def receive_message(%Client{} = client, {:ex_wapp_message, session_id, jid, message}, _opts) do
    event_client = %{client | session_id: client.session_id || session_id}
    {:ok, client, [message_event(event_client, jid, message)]}
  end

  def receive_message(%Client{} = client, _payload, _opts), do: {:ok, client, []}

  @impl true
  def list_contacts(%Client{} = client), do: {:ok, ExWapp.Contact.list(client.store)}

  @impl true
  def get_contact(%Client{} = client, jid), do: {:ok, ExWapp.Contact.get(client.store, jid)}

  @impl true
  def sync_contacts(%Client{} = client) do
    with {:ok, client, session} <- ensure_session(client),
         :ok <- Session.sync_contacts(session) do
      {:ok, client}
    end
  end

  @impl true
  def create_contact(%Client{} = client, jid, name) do
    with {:ok, client, session} <- ensure_session(client),
         :ok <- Session.create_contact(session, jid, name) do
      {:ok, client}
    end
  end

  @impl true
  def update_contact(%Client{} = client, jid, attrs) do
    name = contact_name_from_attrs(attrs)

    if is_binary(name) and name != "" do
      create_contact(client, jid, name)
    else
      {:error, :missing_contact_name}
    end
  end

  @impl true
  def delete_contact(%Client{} = client, jid) do
    with {:ok, client, session} <- ensure_session(client),
         :ok <- Session.delete_contact(session, jid) do
      {:ok, client}
    end
  end

  @impl true
  def list_chats(%Client{} = client), do: {:ok, ExWapp.Chat.list(client.store)}

  @impl true
  def list_groups(%Client{} = client), do: {:ok, ExWapp.Chat.list_groups(client.store)}

  @impl true
  def get_chat(%Client{} = client, jid), do: ExWapp.Chat.get(client.store, jid)

  @impl true
  def get_messages(%Client{} = client, jid, opts),
    do: {:ok, ExWapp.Chat.messages(client.store, jid, opts)}

  @impl true
  def stream_messages(%Client{} = client, jid, opts),
    do: {:ok, ExWapp.Chat.stream_messages(client.store, jid, opts)}

  @impl true
  def delete_messages(%Client{} = client, jid, message_ids) do
    case ExWapp.Chat.delete_messages(client.store, jid, message_ids) do
      :ok -> {:ok, client}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def download_media(%Client{} = client, %ExWapp.Media.Ref{} = ref, opts) do
    with {:ok, client, session} <- ensure_session(client),
         {:ok, download} <- Session.download_media(session, ref, opts) do
      {:ok, client, download}
    end
  end

  defp send_session_content(session, %Message{type: :image, to: to, body: source}, opts),
    do: Session.send_image(session, to, source, opts)

  defp send_session_content(session, %Message{type: :audio, to: to, body: source}, opts),
    do: Session.send_audio(session, to, source, opts)

  defp send_session_content(session, %Message{type: :document, to: to, body: source}, opts),
    do: Session.send_document(session, to, source, opts)

  defp send_session_content(
         session,
         %Message{type: :location, to: to, body: %{latitude: latitude, longitude: longitude}},
         opts
       ),
       do: Session.send_location(session, to, latitude, longitude, opts)

  defp send_session_content(
         session,
         %Message{type: :contact, to: to, body: %{display_name: name, vcard: vcard}},
         opts
       ),
       do: Session.send_contact(session, to, name, vcard, opts)

  defp send_session_content(
         session,
         %Message{type: :event, to: to, body: %{name: name, start_time: start_time}},
         opts
       ),
       do: Session.send_event(session, to, name, start_time, opts)

  @spec normalize_session_send(
          {:ok, String.t()} | {:error, term()},
          Client.t()
        ) :: {:ok, Client.t(), String.t()} | {:error, Client.t(), term()}
  defp normalize_session_send({:ok, message_id}, client),
    do: {:ok, client, message_id}

  defp normalize_session_send({:error, reason}, client),
    do: {:error, client, reason}

  defp contact_name_from_attrs(attrs) when is_list(attrs) do
    Keyword.get(attrs, :full_name) || Keyword.get(attrs, :name) || Keyword.get(attrs, :push_name)
  end

  defp contact_name_from_attrs(attrs) when is_map(attrs) do
    Map.get(attrs, :full_name) || Map.get(attrs, :name) || Map.get(attrs, :push_name) ||
      Map.get(attrs, "full_name") || Map.get(attrs, "name") || Map.get(attrs, "push_name")
  end

  defp contact_name_from_attrs(_), do: nil

  @spec ensure_session(Client.t()) :: {:ok, Client.t(), pid()} | {:error, term()}
  defp ensure_session(%Client{} = client) do
    case session_pid(client) do
      pid when is_pid(pid) ->
        if Process.alive?(pid) do
          {:ok, client, pid}
        else
          start_session(%{client | metadata: Map.delete(client.metadata, :session_pid)})
        end

      _ ->
        start_session(client)
    end
  end

  @spec start_session(Client.t()) :: {:ok, Client.t(), pid()} | {:error, term()}
  defp start_session(%Client{} = client) do
    opts =
      client.metadata
      |> Map.get(:session_opts, [])
      |> Keyword.put_new(:store, client.store)

    start_result =
      if is_nil(client.session_id) do
        Session.start_link(opts)
      else
        start_supervised_session(client.session_id, opts)
      end

    case start_result do
      {:ok, pid} ->
        client = put_in(client.metadata[:session_pid], pid)
        {:ok, client, pid}

      {:error, {:already_started, pid}} when is_pid(pid) ->
        client = put_in(client.metadata[:session_pid], pid)
        {:ok, client, pid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec start_supervised_session(term(), keyword()) :: {:ok, pid()} | {:error, term()}
  defp start_supervised_session(session_id, opts) do
    if Process.whereis(ExWapp.Session.Supervisor) do
      Session.Supervisor.start_session(session_id, opts)
    else
      opts
      |> Keyword.put_new(:session_id, session_id)
      |> Session.start_link()
    end
  end

  @spec session_pid(Client.t()) :: pid() | nil
  defp session_pid(%Client{} = client), do: get_in(client.metadata, [:session_pid])

  @spec message_event(Client.t(), String.t(), map()) :: Event.t()
  defp message_event(%Client{} = client, jid, message) do
    Event.new(:message_received, %{jid: jid, message: message}, session_id: client.session_id)
  end
end
