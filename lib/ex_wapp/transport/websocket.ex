defmodule ExWapp.Transport.WebSocket do
  @moduledoc """
  Optional wire-level WebSocket/Noise process for WhatsApp Web.

  This module exchanges already-prepared binary nodes and frames. It does not
  own session supervision, Signal sessions, device fanout, sender keys,
  synchronized state, retry, or reconnect policy. It therefore must not be
  used as a shortcut for high-level message sending.

  Use `ExWapp.Client.Transport.Session` for production messaging. Use this
  module directly only for protocol tooling or as the wire layer underneath a
  complete session implementation.
  """

  use WebSockex
  require Logger

  alias ExWapp.{Binary, Client, Noise, Store}
  alias ExWapp.Noise.ClientPayload
  alias ExWapp.Transport.Frame

  @url "wss://web.whatsapp.com/ws/chat"
  @origin "https://web.whatsapp.com"

  defmodule State do
    @moduledoc false
    defstruct client: nil,
              owner: nil,
              store: nil,
              noise: nil,
              noise_opts: [],
              buffer: <<>>,
              header_seen?: false,
              header_sent?: false

    @type t :: %__MODULE__{
            client: Client.t(),
            owner: pid(),
            store: Store.t(),
            noise: Noise.t() | nil,
            noise_opts: keyword(),
            buffer: binary(),
            header_seen?: boolean(),
            header_sent?: boolean()
          }
  end

  @type event ::
          {:connected, pid()}
          | {:disconnected, term()}
          | {:node, Binary.binary_node()}
          | {:raw, binary()}
          | {:handshake, :started | :completed}
          | {:error, term()}

  @doc """
  Starts a WebSockex process.

  Events are sent to `:owner` as `{:ex_wapp_transport, event}` messages.
  """
  @spec start_link(Client.t(), keyword()) :: GenServer.on_start()
  def start_link(%Client{} = client, opts \\ []) do
    owner = Keyword.get(opts, :owner, self())
    url = Keyword.get(opts, :url, @url)
    headers = Keyword.get(opts, :headers, [{"Origin", @origin}])
    store = Store.new(Keyword.get(opts, :store, client.store))
    noise_opts = Keyword.get(opts, :noise, [])

    state = %State{
      client: client,
      owner: owner,
      store: store,
      noise_opts: noise_opts
    }

    Logger.info(
      "[ExWapp.Transport.WebSocket] connecting session_id=#{inspect(client.session_id)}"
    )

    ExWapp.Telemetry.execute([:ex_wapp, :transport, :websocket, :connect], %{count: 1}, %{
      session_id: client.session_id,
      url: url
    })

    WebSockex.start_link(url, __MODULE__, state, extra_headers: headers)
  end

  @doc """
  Sends an already-prepared binary node through the wire transport.

  The caller is responsible for all required session and Signal processing.
  """
  @spec send_node(pid(), Binary.binary_node() | tuple()) :: :ok
  def send_node(pid, node), do: WebSockex.cast(pid, {:send_node, node})

  @doc """
  Sends an already encoded plaintext payload through a running transport.
  """
  @spec send_payload(pid(), binary()) :: :ok
  def send_payload(pid, payload), do: WebSockex.cast(pid, {:send_payload, payload})

  @doc """
  Creates a transport state machine without opening a socket.

  Useful for host-owned sockets and tests.
  """
  @spec new(Client.t(), keyword()) :: State.t()
  def new(%Client{} = client, opts \\ []) do
    %State{
      client: client,
      owner: Keyword.get(opts, :owner, self()),
      store: Store.new(Keyword.get(opts, :store, client.store)),
      noise_opts: Keyword.get(opts, :noise, [])
    }
  end

  @doc """
  Starts Noise and returns the first WebSocket payload to send.
  """
  @spec connect(State.t()) :: {:ok, State.t(), binary()} | {:error, term()}
  def connect(%State{} = state) do
    noise_opts =
      state.noise_opts
      |> Keyword.put_new(:client_payload_fun, &ClientPayload.build/1)
      |> Keyword.put(:store, state.store)

    with {:ok, client_hello, noise} <- Noise.init(noise_opts) do
      Logger.debug("[ExWapp.Transport.WebSocket] noise handshake started")
      notify_owner(state, {:handshake, :started})

      {:ok, %{state | noise: noise, header_sent?: true},
       encode_socket_payload(client_hello, state)}
    end
  end

  @doc """
  Encodes a node into an encrypted WebSocket payload.
  """
  @spec encode_node(State.t(), Binary.binary_node() | tuple()) ::
          {:ok, State.t(), binary()} | {:error, term()}
  def encode_node(%State{} = state, node) do
    with {:ok, encoded} <- Binary.encode(node) do
      encode_payload(state, encoded)
    end
  end

  @doc """
  Encrypts and frames a plaintext transport payload.
  """
  @spec encode_payload(State.t(), binary()) :: {:ok, State.t(), binary()} | {:error, term()}
  def encode_payload(%State{noise: %Noise{phase: :transport} = noise} = state, plaintext) do
    with {:ok, ciphertext, noise} <- Noise.encrypt(noise, plaintext) do
      next_state = %{state | noise: noise, header_sent?: true}
      payload = Frame.encode(ciphertext, include_header: not state.header_sent?)

      ExWapp.Telemetry.execute([:ex_wapp, :transport, :websocket, :frame_sent], %{
        bytes: byte_size(payload)
      })

      {:ok, next_state, payload}
    end
  end

  def encode_payload(%State{noise: %Noise{}}, _plaintext), do: {:error, :not_connected}
  def encode_payload(_state, _plaintext), do: {:error, :not_connected}

  @doc """
  Decodes inbound WebSocket bytes into raw payloads or decoded nodes.
  """
  @spec receive_bytes(State.t(), binary()) ::
          {:ok, State.t(), [event()]} | {:error, term()}
  def receive_bytes(%State{} = state, bytes) when is_binary(bytes) do
    {buffer, header_seen?, proceed?} = consume_header(state.buffer <> bytes, state.header_seen?)
    state = %{state | buffer: buffer, header_seen?: header_seen?}

    case proceed? do
      true ->
        process_decoded_frames(state, buffer)

      false ->
        {:ok, state, []}
    end
  end

  @spec process_decoded_frames(State.t(), binary()) ::
          {:ok, State.t(), [event()]} | {:error, term()}
  defp process_decoded_frames(state, buffer) do
    {frames, rest} = Frame.decode(buffer)
    state = %{state | buffer: rest}

    Enum.reduce_while(frames, {:ok, state, []}, fn frame, {:ok, acc_state, events} ->
      case process_frame(acc_state, frame) do
        {:ok, next_state, frame_events} -> {:cont, {:ok, next_state, events ++ frame_events}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  @doc false
  @impl true
  @spec handle_connect(term(), State.t()) ::
          {:reply, {:binary, binary()}, State.t()} | {:ok, State.t()}
  def handle_connect(_conn, %State{} = state) do
    notify_owner(state, {:connected, self()})

    case connect(state) do
      {:ok, next_state, payload} -> {:reply, {:binary, payload}, next_state}
      {:error, reason} -> handle_transport_error(state, reason)
    end
  end

  @doc false
  @impl true
  @spec handle_disconnect(term(), State.t()) :: {:ok, State.t()}
  def handle_disconnect(reason, %State{} = state) do
    Logger.info("[ExWapp.Transport.WebSocket] disconnected reason=#{inspect(reason)}")
    notify_owner(state, {:disconnected, reason})

    ExWapp.Telemetry.execute([:ex_wapp, :transport, :websocket, :disconnect], %{count: 1}, %{
      session_id: state.client.session_id,
      reason: inspect(reason)
    })

    {:ok, state}
  end

  @doc false
  @impl true
  @spec handle_frame(term(), State.t()) ::
          {:ok, State.t()}
          | {:reply, {:binary, binary()} | [{:binary, binary()}], State.t()}
  def handle_frame({:binary, bytes}, %State{} = state) do
    case receive_bytes(state, bytes) do
      {:ok, next_state, events} ->
        {raw_replies, owner_events} = split_raw_replies(events)
        Enum.each(owner_events, &notify_owner(next_state, &1))

        case raw_replies do
          [] ->
            {:ok, next_state}

          [reply] ->
            {:reply, {:binary, reply}, %{next_state | header_sent?: true}}

          replies ->
            {:reply, Enum.map(replies, &{:binary, &1}), %{next_state | header_sent?: true}}
        end

      {:error, reason} ->
        handle_transport_error(state, reason)
    end
  end

  def handle_frame(frame, %State{} = state) do
    Logger.debug("[ExWapp.Transport.WebSocket] ignoring non-binary frame=#{inspect(frame)}")
    {:ok, state}
  end

  @doc false
  @impl true
  @spec handle_cast(
          {:send_node, Binary.binary_node() | tuple()} | {:send_payload, binary()},
          State.t()
        ) :: {:reply, {:binary, binary()}, State.t()} | {:ok, State.t()}
  def handle_cast({:send_node, node}, %State{} = state) do
    case encode_node(state, node) do
      {:ok, next_state, payload} -> {:reply, {:binary, payload}, next_state}
      {:error, reason} -> handle_transport_error(state, reason)
    end
  end

  def handle_cast({:send_payload, plaintext}, %State{} = state) do
    case encode_payload(state, plaintext) do
      {:ok, next_state, payload} -> {:reply, {:binary, payload}, next_state}
      {:error, reason} -> handle_transport_error(state, reason)
    end
  end

  @spec process_frame(State.t(), binary()) :: {:ok, State.t(), [event()]} | {:error, term()}
  defp process_frame(%State{noise: %Noise{phase: :handshake} = noise} = state, frame) do
    with {:ok, client_finish, noise} <- Noise.handle_server_hello(noise, frame) do
      payload = encode_socket_payload(client_finish, state)
      state = %{state | noise: noise, header_sent?: true}
      notify_owner(state, {:handshake, :completed})
      {:ok, state, [{:raw, payload}]}
    end
  end

  defp process_frame(%State{noise: %Noise{phase: :transport} = noise} = state, frame) do
    with {:ok, plaintext, noise} <- Noise.decrypt(noise, frame),
         {:ok, node} <- Binary.decode(plaintext) do
      state = %{state | noise: noise}

      ExWapp.Telemetry.execute([:ex_wapp, :transport, :websocket, :frame_received], %{
        bytes: byte_size(frame)
      })

      {:ok, state, [{:node, node}]}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp process_frame(_state, _frame), do: {:error, :not_connected}

  @spec encode_socket_payload(binary(), State.t()) :: binary()
  defp encode_socket_payload(payload, %State{} = state) do
    Frame.encode(payload, include_header: not state.header_sent?)
  end

  @spec consume_header(binary(), boolean()) :: {binary(), boolean(), boolean()}
  defp consume_header(buffer, false) do
    header = Frame.header()
    size = byte_size(header)

    cond do
      byte_size(buffer) < size ->
        {buffer, false, false}

      binary_part(buffer, 0, size) == header ->
        {binary_part(buffer, size, byte_size(buffer) - size), true, true}

      true ->
        {buffer, true, true}
    end
  end

  defp consume_header(buffer, true), do: {buffer, true, true}

  @spec handle_transport_error(State.t(), term()) :: {:ok, State.t()}
  defp handle_transport_error(%State{} = state, reason) do
    Logger.error("[ExWapp.Transport.WebSocket] error=#{inspect(reason)}")
    notify_owner(state, {:error, reason})

    ExWapp.Telemetry.execute([:ex_wapp, :transport, :websocket, :error], %{count: 1}, %{
      session_id: state.client.session_id,
      reason: inspect(reason)
    })

    {:ok, state}
  end

  @spec notify_owner(State.t(), event()) :: :ok
  defp notify_owner(%State{owner: owner}, event) when is_pid(owner) do
    send(owner, {:ex_wapp_transport, event})
    :ok
  end

  @spec split_raw_replies([event()]) :: {[binary()], [event()]}
  defp split_raw_replies(events) do
    Enum.reduce(events, {[], []}, fn
      {:raw, payload}, {raws, owner_events} -> {[payload | raws], owner_events}
      event, {raws, owner_events} -> {raws, [event | owner_events]}
    end)
    |> then(fn {raws, owner_events} -> {Enum.reverse(raws), Enum.reverse(owner_events)} end)
  end
end
