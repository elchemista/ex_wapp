defmodule ExWapp.Client.Transport do
  @moduledoc """
  Behaviour for high-level, runtime-neutral ExWapp transport adapters.

  The adapter is owned by the host application. It may be backed by a GenServer,
  GenStateMachine, direct WebSocket process, test double, or any other runtime.
  """

  alias ExWapp.{Client, Message}

  @callback connect(Client.t()) :: {:ok, Client.t()} | {:error, term()}
  @callback pair(Client.t()) :: {:ok, Client.t(), term()} | {:error, term()}
  @callback disconnect(Client.t()) :: {:ok, Client.t()} | :ok | {:error, term()}
  @callback send_message(Client.t(), Message.t()) ::
              {:ok, String.t()}
              | {:ok, Client.t(), String.t()}
              | {:error, Client.t(), term()}
              | {:error, term()}
  @callback receive_message(Client.t(), term(), keyword()) ::
              {:ok, Client.t(), [ExWapp.Event.t()]}
              | {:ok, [ExWapp.Event.t()]}
              | {:error, term()}

  @optional_callbacks pair: 1, disconnect: 1, receive_message: 3
end

defmodule ExWapp.Client.Transport.Noop do
  @moduledoc """
  Default high-level transport adapter.

  It intentionally does not perform network IO. Configure a transport adapter in
  real applications.
  """

  @behaviour ExWapp.Client.Transport

  alias ExWapp.{Client, Message}

  @impl true
  @spec connect(Client.t()) :: {:error, :missing_transport}
  def connect(_client), do: {:error, :missing_transport}

  @impl true
  @spec send_message(Client.t(), Message.t()) :: {:error, :missing_transport}
  def send_message(_client, _message), do: {:error, :missing_transport}
end

defmodule ExWapp.Client.Transport.WebSocket do
  @moduledoc """
  High-level client transport that starts the optional WebSocket process.

  The process is owned by the caller supplied in client metadata:

      ExWapp.new(
        transport: ExWapp.Client.Transport.WebSocket,
        metadata: %{owner: self()}
      )

  WebSocket events are delivered as `{:ex_wapp_transport, event}` messages.
  """

  @behaviour ExWapp.Client.Transport

  alias ExWapp.{Client, Message}

  @impl true
  @spec connect(Client.t()) :: {:ok, Client.t()} | {:error, term()}
  def connect(%Client{} = client) do
    opts = Map.get(client.metadata, :websocket, [])
    owner = Map.get(client.metadata, :owner, self())

    case ExWapp.Transport.WebSocket.start_link(client, Keyword.put_new(opts, :owner, owner)) do
      {:ok, pid} ->
        {:ok, put_in(client.metadata[:transport_pid], pid)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  @spec disconnect(Client.t()) :: {:ok, Client.t()}
  def disconnect(%Client{} = client) do
    case get_in(client.metadata, [:transport_pid]) do
      pid when is_pid(pid) -> Process.exit(pid, :normal)
      _ -> :ok
    end

    {:ok, update_in(client.metadata, &Map.delete(&1, :transport_pid))}
  end

  @impl true
  @spec send_message(Client.t(), Message.t()) :: {:ok, Client.t(), String.t()} | {:error, term()}
  def send_message(%Client{} = client, %Message{} = message) do
    case get_in(client.metadata, [:transport_pid]) do
      pid when is_pid(pid) ->
        node = build_unencrypted_node(message)
        :ok = ExWapp.Transport.WebSocket.send_node(pid, node)
        {:ok, client, message.id}

      _ ->
        {:error, :not_connected}
    end
  end

  @spec build_unencrypted_node(Message.t()) :: ExWapp.Binary.binary_node()
  defp build_unencrypted_node(%Message{type: :text, to: to, body: text, id: id, opts: opts}) do
    timestamp = System.system_time(:second)
    proto = ExWapp.Messages.build_text_proto(text, opts)
    {:ok, payload} = ExWapp.Proto.Message.encode(proto)
    ExWapp.Messages.build_message_node(to, id, IO.iodata_to_binary(payload), timestamp, opts)
  end

  defp build_unencrypted_node(%Message{type: :typing, to: to, body: composing}) do
    ExWapp.Messages.build_typing(to, composing)
  end

  defp build_unencrypted_node(%Message{type: :read_receipt, to: to, body: ids}) do
    ExWapp.Messages.build_receipt_node(to, ids, "read")
  end
end

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

      timeout = get_in(client.metadata, [:pair_timeout]) || 30_000

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
  def send_message(%Client{} = client, %Message{type: :text, to: to, body: text}) do
    case ensure_session(client) do
      {:ok, client, session} ->
        case Session.send_text(session, to, text) do
          {:ok, message_id} -> {:ok, client, message_id}
          {:error, reason} -> {:error, client, reason}
        end

      {:error, reason} ->
        {:error, reason}
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
