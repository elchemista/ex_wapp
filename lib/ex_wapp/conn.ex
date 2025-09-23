defmodule ExWapp.Conn do
  @moduledoc """
  Thin wrapper around the WhatsApp WebSocket transport.

  The module is responsible for driving the Noise handshake and routing
  decrypted nodes back to the owning `ExWapp.Session` process.
  """

  use WebSockex
  require Logger

  alias ExWapp.{Binary, Noise, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Binary.Raw
  alias ExWapp.Noise.ClientPayload
  alias ExWapp.Transport.Frame

  @url "wss://web.whatsapp.com/ws/chat"
  @origin "https://web.whatsapp.com"

  defmodule State do
    @moduledoc false
    defstruct session: nil,
              store: nil,
              noise: nil,
              noise_opts: [],
              buffer: <<>>,
              header_sent?: false,
              header_seen?: false,
              stream_started?: false
  end

  @type options :: [
          session: pid(),
          store: ExWapp.Store.t(),
          noise: keyword()
        ]

  @doc """
  Starts the WebSocket process.
  """
  @spec start_link(options()) :: GenServer.on_start()
  def start_link(opts) do
    session = Keyword.fetch!(opts, :session)
    store = Keyword.fetch!(opts, :store)
    noise_opts = Keyword.get(opts, :noise, [])

    headers = [
      {"Origin", @origin},
      {"Sec-WebSocket-Protocol", "binary"},
      {"Sec-WebSocket-Extensions", "permessage-deflate; client_max_window_bits"},
      {"User-Agent",
       "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"},
      {"Cache-Control", "no-cache"},
      {"Pragma", "no-cache"},
      {"Sec-Fetch-Dest", "websocket"},
      {"Sec-Fetch-Mode", "websocket"},
      {"Sec-Fetch-Site", "same-origin"}
    ]

    state = %State{
      session: session,
      store: store,
      noise_opts: noise_opts
    }

    WebSockex.start_link(@url, __MODULE__, state, extra_headers: headers)
  end

  @doc """
  Asks the connection process to send a binary node.
  """
  @spec send_node(pid(), Binary.binary_node() | tuple()) :: :ok
  def send_node(pid, node), do: WebSockex.cast(pid, {:send_node, node})

  @doc "Restarts the XML stream after SASL success."
  @spec restart_stream(pid()) :: :ok
  def restart_stream(pid), do: WebSockex.cast(pid, :restart_stream)

  @impl true
  def handle_connect(_conn, %State{} = state) do
    Logger.info("websocket connected; Noise handshake pending")
    notify_session(state.session, {:transport, :connected})

    noise_opts =
      state.noise_opts
      |> Keyword.put_new(:client_payload_fun, &ClientPayload.build/1)
      |> Keyword.delete(:store)

    case Noise.init(Keyword.put(noise_opts, :store, state.store)) do
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

      Enum.each(frames, fn frame ->
        Logger.debug(
          "received frame size=#{byte_size(frame)} phase=#{state.noise && state.noise.phase}"
        )
      end)

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
         :ok <- log_outgoing_node(node, encoded),
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

  def handle_cast(:restart_stream, %State{} = state) do
    state = %{state | stream_started?: false}

    case maybe_send_stream_start(state) do
      {:ok, new_state, []} -> {:noreply, new_state}
      {:ok, new_state, replies} -> {:reply, replies, new_state}
    end
  end

  defp process_frames(frames, state) do
    Enum.reduce_while(frames, {:ok, state, []}, fn frame, {:ok, acc_state, replies} ->
      case handle_payload_frame(acc_state, frame) do
        {:ok, next_state, responses} ->
          {:cont, {:ok, next_state, replies ++ normalize_replies(responses)}}

        {:close, next_state} ->
          {:halt, {:close, next_state}}
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

        with {:ok, state, extra_replies} <- maybe_send_stream_start(state) do
          notify_session(state.session, {:noise, :handshake_completed})
          {:ok, state, [reply | extra_replies]}
        end

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
    {:ok, state, []}
  end

  defp handle_decrypted_payload(state, plaintext) do
    with {:ok, unpacked} <- Binary.unpack(plaintext),
         {:ok, node} <- Binary.decode(unpacked) do
      Logger.debug("Received node: #{node_to_xml(node)}")
      notify_session(state.session, {:connection_message, node})
      {:ok, state, []}
    else
      {:error, reason} ->
        Logger.warning("failed to decode binary payload: #{inspect(reason)}")
        notify_session(state.session, {:connection_binary, plaintext})
        {:ok, state, []}
    end
  end

  defp build_reply(%State{} = state, payload) do
    include_header = not state.header_sent?
    frame = Frame.encode(payload, include_header: include_header)
    Logger.debug("Frame payload (#{byte_size(payload)} bytes): #{hex(payload)}")
    Logger.debug("Websocket frame (#{byte_size(frame)} bytes): #{hex(frame)}")
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

  defp normalize_replies(nil), do: []
  defp normalize_replies(replies) when is_list(replies), do: replies
  defp normalize_replies(reply), do: [reply]

  defp maybe_send_stream_start(%State{stream_started?: true} = state), do: {:ok, state, []}

  defp maybe_send_stream_start(%State{noise: %Noise{phase: :transport} = noise} = state) do
    with {:ok, stream_start} <- build_stream_start_node(state),
         {:ok, stream_bin} <- Binary.encode(stream_start),
         {:ok, stream_cipher, noise_state} <- Noise.encrypt(noise, stream_bin),
         {state, stream_reply} <- build_reply(%{state | noise: noise_state}, stream_cipher),
         {:ok, handshake_node} <- build_handshake_node(),
         {:ok, handshake_bin} <- Binary.encode(handshake_node),
         {:ok, handshake_cipher, noise_state} <- Noise.encrypt(state.noise, handshake_bin),
         {state, handshake_reply} <-
           build_reply(%{state | noise: noise_state, stream_started?: true}, handshake_cipher) do
      {:ok, state, [stream_reply, handshake_reply]}
    else
      {:error, reason} ->
        Logger.error("failed to send stream start: #{inspect(reason)}")
        {:ok, state, []}
    end
  end

  defp maybe_send_stream_start(state), do: {:ok, state, []}

  defp hex(data) do
    Base.encode16(data, case: :lower)
  end

  defp log_outgoing_node(node, encoded) do
    case Binary.decode(encoded) do
      {:ok, decoded} ->
        Logger.info("Sending node: #{node_to_xml(decoded)}")

      {:error, _} ->
        Logger.info("Sending node: #{inspect(node)}")
    end

    :ok
  rescue
    _ ->
      Logger.info("Sending node: #{inspect(node)}")
      :ok
  end

  defp node_to_xml(%Node{tag: tag, attrs: attrs, content: nil}) do
    "<#{tag}#{attrs_to_string(attrs)}/>"
  end

  defp node_to_xml(%Node{tag: tag, attrs: attrs, content: []}) do
    "<#{tag}#{attrs_to_string(attrs)}/>"
  end

  defp node_to_xml(%Node{tag: tag, attrs: attrs, content: content}) when is_binary(content) do
    "<#{tag}#{attrs_to_string(attrs)}>#{content}</#{tag}>"
  end

  defp node_to_xml(%Node{tag: tag, attrs: attrs, content: %Raw{data: data}}) do
    "<#{tag}#{attrs_to_string(attrs)}>[raw #{byte_size(data)} bytes]</#{tag}>"
  end

  defp node_to_xml(%Node{tag: tag, attrs: attrs, content: content}) when is_list(content) do
    inner = content |> Enum.map(&node_to_xml/1) |> Enum.join()
    "<#{tag}#{attrs_to_string(attrs)}>#{inner}</#{tag}>"
  end

  defp node_to_xml(other), do: inspect(other)

  defp attrs_to_string(attrs) do
    attrs
    |> Enum.map(fn
      {key, true} -> " #{key}"
      {key, value} -> " #{key}=\"#{value}\""
    end)
    |> Enum.join()
  end

  defp build_stream_start_node(%State{store: store}) do
    data = Store.load!(store)
    info = Map.get(data, :client_info, %{})

    attrs =
      %{
        "to" => "s.whatsapp.net",
        "xmlns" => "jabber:client",
        "xmlns:stream" => "http://etherx.jabber.org/streams",
        "version" => "1.0"
      }
      |> maybe_put_attr("resource", stream_resource(info))
      |> maybe_put_attr("id", stream_id(info))

    {:ok, %Binary.Node{tag: "xmlstreamstart", attrs: attrs, content: nil}}
  end

  defp build_handshake_node do
    {:ok, %Binary.Node{tag: "handshake", attrs: %{}, content: nil}}
  end

  defp stream_resource(%{stream_resource: resource}) when is_binary(resource) and resource != "",
    do: resource

  defp stream_resource(%{device_name: name}) when is_binary(name) and name != "",
    do: name

  defp stream_resource(%{phone_id: phone_id}) when is_binary(phone_id) and phone_id != "",
    do: phone_id

  defp stream_resource(_), do: "EX_WAPP"

  defp stream_id(%{stream_id: id}) when is_binary(id) and id != "", do: id
  defp stream_id(_), do: generate_stream_id()

  defp generate_stream_id do
    4
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  defp maybe_put_attr(attrs, _key, nil), do: attrs
  defp maybe_put_attr(attrs, key, value), do: Map.put(attrs, key, value)
end
