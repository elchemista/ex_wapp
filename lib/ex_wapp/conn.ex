defmodule ExWapp.Conn do
  @moduledoc """
  Thin wrapper around the WhatsApp WebSocket transport.

  The module is responsible for driving the Noise handshake and routing
  decrypted nodes back to the owning `ExWapp.Session` process.
  """

  use WebSockex
  require Logger

  alias ExWapp.Binary
  alias ExWapp.Noise
  alias ExWapp.Noise.ClientPayload
  alias ExWapp.Transport.Frame

  @url "wss://web.whatsapp.com/ws/chat"
  @origin "https://web.whatsapp.com"

  defmodule State do
    @moduledoc false
    defstruct session: nil,
              store: nil,
              noise: nil,
              buffer: <<>>,
              header_sent?: false,
              header_seen?: false
  end

  @type options :: [session: pid(), store: ExWapp.Store.t()]

  @doc """
  Starts the WebSocket process.
  """
  @spec start_link(options()) :: GenServer.on_start()
  def start_link(opts) do
    session = Keyword.fetch!(opts, :session)
    store = Keyword.fetch!(opts, :store)
    headers = [{"Origin", @origin}]

    state = %State{
      session: session,
      store: store
    }

    WebSockex.start_link(@url, __MODULE__, state, extra_headers: headers)
  end

  @doc """
  Asks the connection process to send a binary node.
  """
  @spec send_node(pid(), Binary.binary_node() | tuple()) :: :ok
  def send_node(pid, node), do: WebSockex.cast(pid, {:send_node, node})

  @impl true
  def handle_connect(_conn, %State{} = state) do
    Logger.info("websocket connected; Noise handshake pending")
    notify_session(state.session, {:transport, :connected})

    case Noise.init(store: state.store, client_payload_fun: &ClientPayload.build/1) do
      {:ok, client_hello, noise_state} ->
        state = %{state | noise: noise_state}
        {state, reply} = build_reply(state, client_hello)
        notify_session(state.session, {:noise, :handshake_started})
        {:reply, reply, state}

      {:error, reason} ->
        Logger.error("failed to build Noise handshake: #{inspect(reason)}")
        notify_session(state.session, {:error, reason})
        {:close, state}
    end
  end

  @impl true
  def handle_disconnect(_reason, state) do
    notify_session(state.session, {:transport, :closed})
    {:ok, state}
  end

  @impl true
  def handle_frame({:binary, payload}, %State{} = state) do
    buffer = state.buffer <> payload
    {buffer, header_seen?, proceed?} = maybe_consume_header(buffer, state.header_seen?)
    state = %{state | header_seen?: header_seen?}

    if not proceed? do
      {:ok, %{state | buffer: buffer}}
    else
      {frames, rest} = Frame.decode(buffer)
      state = %{state | buffer: rest}

      case process_frames(frames, state) do
        {:ok, new_state, []} -> {:ok, new_state}
        {:ok, new_state, replies} -> {:reply, replies, new_state}
        {:close, new_state} -> {:close, new_state}
      end
    end
  end

  def handle_frame(_other, state), do: {:ok, state}

  @impl true
  def handle_cast({:send_node, node}, %State{noise: %Noise{phase: :transport} = noise} = state) do
    with {:ok, encoded} <- Binary.encode(node),
         {:ok, ciphertext, noise_state} <- Noise.encrypt(noise, encoded) do
      state = %{state | noise: noise_state}
      {state, reply} = build_reply(state, ciphertext)
      {:reply, reply, state}
    else
      {:error, reason} ->
        Logger.error("cannot send node: #{inspect(reason)}")
        notify_session(state.session, {:error, reason})
        {:noreply, state}
    end
  end

  def handle_cast({:send_node, _node}, state) do
    Logger.warning("dropping outbound node before Noise handshake completes")
    {:noreply, state}
  end

  defp process_frames(frames, state) do
    Enum.reduce_while(frames, {:ok, state, []}, fn frame, {:ok, acc_state, replies} ->
      case handle_payload_frame(acc_state, frame) do
        {:ok, next_state, nil} -> {:cont, {:ok, next_state, replies}}
        {:ok, next_state, reply} -> {:cont, {:ok, next_state, replies ++ [reply]}}
        {:close, next_state} -> {:halt, {:close, next_state}}
      end
    end)
    |> case do
      {:ok, new_state, replies} -> {:ok, new_state, replies}
      {:close, new_state} -> {:close, new_state}
    end
  end

  defp handle_payload_frame(%State{noise: %Noise{phase: :handshake} = noise} = state, frame) do
    case Noise.handle_server_hello(noise, frame) do
      {:ok, client_finish, noise_state} ->
        state = %{state | noise: noise_state}
        {state, reply} = build_reply(state, client_finish)
        notify_session(state.session, {:noise, :handshake_completed})
        {:ok, state, reply}

      {:error, reason} ->
        Logger.error("Noise handshake failed: #{inspect(reason)}")
        notify_session(state.session, {:error, reason})
        {:close, state}
    end
  end

  defp handle_payload_frame(%State{noise: %Noise{phase: :transport} = noise} = state, frame) do
    case Noise.decrypt(noise, frame) do
      {:ok, plaintext, noise_state} ->
        state = %{state | noise: noise_state}
        handle_decrypted_payload(state, plaintext)

      {:error, reason} ->
        Logger.error("failed to decrypt payload: #{inspect(reason)}")
        notify_session(state.session, {:error, reason})
        {:close, state}
    end
  end

  defp handle_payload_frame(state, _frame), do: {:close, state}

  defp handle_decrypted_payload(state, <<>>) do
    notify_session(state.session, {:connection_message, :empty})
    {:ok, state, nil}
  end

  defp handle_decrypted_payload(state, plaintext) do
    with {:ok, unpacked} <- Binary.unpack(plaintext),
         {:ok, node} <- Binary.decode(unpacked) do
      notify_session(state.session, {:connection_message, node})
      {:ok, state, nil}
    else
      {:error, reason} ->
        Logger.warning("failed to decode binary payload: #{inspect(reason)}")
        notify_session(state.session, {:connection_binary, plaintext})
        {:ok, state, nil}
    end
  end

  defp build_reply(%State{} = state, payload) do
    include_header = not state.header_sent?
    frame = Frame.encode(payload, include_header: include_header)
    {%{state | header_sent?: true}, {:binary, frame}}
  end

  defp maybe_consume_header(buffer, true), do: {buffer, true, true}

  defp maybe_consume_header(buffer, false) do
    header = Frame.header()
    header_size = byte_size(header)

    cond do
      byte_size(buffer) < header_size ->
        {buffer, false, false}

      binary_part(buffer, 0, header_size) == header ->
        {binary_part(buffer, header_size, byte_size(buffer) - header_size), true, true}

      true ->
        {buffer, true, true}
    end
  end

  defp notify_session(pid, message) when is_pid(pid), do: send(pid, {:connection_event, message})
end
