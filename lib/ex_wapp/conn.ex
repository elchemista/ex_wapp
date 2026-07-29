defmodule ExWapp.Conn do
  @moduledoc """
  Thin wrapper around the WhatsApp WebSocket transport.

  The module is responsible for driving the Noise handshake and routing
  decrypted nodes back to the owning `ExWapp.Session` process.
  """

  use WebSockex
  @behaviour ExWapp.Transport
  require Logger

  alias ExWapp.{Binary, Log, Noise, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Binary.Raw
  alias ExWapp.Noise.ClientPayload
  alias ExWapp.Transport.Frame
  alias ExWapp.Transport.TLS

  @url "wss://web.whatsapp.com/ws/chat"
  @origin "https://web.whatsapp.com"

  defmodule State do
    @moduledoc """
    Runtime state owned by `ExWapp.Conn`.

    It keeps the session and store references together with the Noise handshake and
    partial WebSocket frame buffers used while the connection is active.
    """
    defstruct session: nil,
              store: nil,
              noise: nil,
              noise_opts: [],
              buffer: <<>>,
              header_sent?: false,
              header_seen?: false,
              stream_started?: false

    @type t :: %__MODULE__{
            session: pid() | nil,
            store: ExWapp.Store.t() | nil,
            noise: ExWapp.Noise.t() | nil,
            noise_opts: keyword(),
            buffer: binary(),
            header_sent?: boolean(),
            header_seen?: boolean(),
            stream_started?: boolean()
          }
  end

  @type options :: [
          session: pid(),
          store: ExWapp.Store.t(),
          noise: keyword()
        ]

  @doc """
  Starts the WebSocket process.
  """
  @impl ExWapp.Transport
  @spec start_link(options()) :: GenServer.on_start()
  def start_link(opts) do
    Logger.debug("[CONN] start_link called")
    session = Keyword.fetch!(opts, :session)
    store = Keyword.fetch!(opts, :store) |> ExWapp.Store.new()
    noise_opts = Keyword.get(opts, :noise, [])

    # Mirror the Go client: only set Origin header explicitly
    # The websocket library handles Connection, Upgrade, Sec-WebSocket-* headers
    headers = [
      {"Origin", @origin}
    ]

    Logger.debug("[CONN] Connecting to #{@url}...")

    state = %State{
      session: session,
      store: store,
      noise_opts: noise_opts
    }

    websockex_opts = Keyword.put(TLS.websockex_options(@url), :extra_headers, headers)
    result = WebSockex.start_link(@url, __MODULE__, state, websockex_opts)
    Logger.debug("[CONN] WebSockex.start_link result: #{Log.reason(result)}")
    result
  end

  @doc """
  Asks the connection process to send a binary node.
  """
  @impl ExWapp.Transport
  @spec send_node(pid(), Binary.binary_node() | tuple()) :: :ok
  def send_node(pid, node), do: WebSockex.cast(pid, {:send_node, node})

  @doc "Restarts the XML stream after SASL success."
  @impl ExWapp.Transport
  @spec restart_stream(pid()) :: :ok
  def restart_stream(pid), do: WebSockex.cast(pid, :restart_stream)

  @impl true
  @doc false
  @spec handle_connect(term(), State.t()) ::
          {:ok, State.t()} | {:close, State.t()}
  def handle_connect(_conn, %State{} = state) do
    Logger.debug("[CONN] WebSocket connected, starting Noise handshake")
    notify_session(state.session, {:transport, :connected})

    noise_opts =
      state.noise_opts
      |> Keyword.put_new(:client_payload_fun, &ClientPayload.build/1)
      |> Keyword.delete(:store)

    Logger.debug("[CONN] Calling Noise.init")

    try do
      result = Noise.init(Keyword.put(noise_opts, :store, state.store))
      Logger.debug("[CONN] Noise.init completed")

      case result do
        {:ok, client_hello, noise_state} ->
          Logger.debug("[CONN] Noise.init success, client_hello=#{byte_size(client_hello)} bytes")
          state = %{state | noise: noise_state}
          {state, frame} = build_reply(state, client_hello)
          Logger.debug("[CONN] Sending client hello frame")
          notify_session(state.session, {:noise, :handshake_started})
          send(self(), {:send_raw_frame, frame})
          {:ok, state}

        {:error, reason} ->
          Logger.error("[CONN] Noise.init failed: #{Log.reason(reason)}")
          notify_session(state.session, {:error, reason})
          {:close, state}
      end
    rescue
      e in _ ->
        Logger.error("[CONN] Noise.init crashed: #{Log.reason(e)}")
        notify_session(state.session, {:error, {:crash, e}})
        {:close, state}
    end
  end

  @impl true
  @doc false
  @spec handle_disconnect(term(), State.t()) :: {:ok, State.t()}
  def handle_disconnect(reason, state) do
    Logger.warning("[CONN] WebSocket disconnected: #{Log.reason(reason)}")
    notify_session(state.session, {:transport, {:closed, reason}})
    # Returning {:ok, state} allows WebSockex to terminate this process.
    {:ok, state}
  end

  @impl true
  @doc false
  @spec handle_frame(term(), State.t()) ::
          {:ok, State.t()} | {:reply, term(), State.t()} | {:close, State.t()}
  def handle_frame(frame_data, %State{} = state) do
    Logger.debug("[CONN] Received frame from server")
    handle_binary_frame(frame_data, state)
  end

  defp handle_binary_frame({:binary, payload}, %State{} = state) do
    Logger.debug("[CONN] Frame: #{byte_size(payload)} bytes")

    buffer = state.buffer <> payload
    {buffer, header_seen?, proceed?} = maybe_consume_header(buffer, state.header_seen?)
    state = %{state | header_seen?: header_seen?}

    if proceed? do
      {frames, rest} = Frame.decode(buffer)
      noise_phase = if state.noise, do: state.noise.phase, else: nil

      Logger.debug(
        "[CONN] Decoded #{length(frames)} frame(s), noise_phase=#{inspect(noise_phase)}"
      )

      state = %{state | buffer: rest}

      case process_frames(frames, state) do
        {:ok, new_state, []} -> {:ok, new_state}
        {:ok, new_state, replies} -> {:reply, replies, new_state}
        {:close, new_state} -> {:close, new_state}
      end
    else
      {:ok, %{state | buffer: buffer}}
    end
  end

  defp handle_binary_frame(other, state) do
    Logger.warning("Received non-binary frame: #{Log.term_summary(other)}")
    {:ok, state}
  end

  @impl true
  @doc false
  @spec handle_cast(term(), State.t()) ::
          {:reply, term(), State.t()} | {:noreply, State.t()}
  def handle_cast({:send_node, node}, %State{noise: %Noise{phase: :transport} = noise} = state) do
    with {:ok, encoded} <- Binary.encode(node),
         :ok <- log_outgoing_node(node, encoded),
         {:ok, ciphertext, noise_state} <- Noise.encrypt(noise, encoded) do
      state = %{state | noise: noise_state}
      {state, reply} = build_reply(state, ciphertext)
      Logger.debug("sending encrypted node size=#{byte_size(ciphertext)}")
      {:reply, reply, state}
    else
      {:error, reason} ->
        Logger.error("cannot send node: #{Log.reason(reason)}")
        notify_session(state.session, {:error, reason})
        {:ok, state}
    end
  end

  @doc false
  def handle_cast({:send_node, _node}, state) do
    Logger.warning("dropping outbound node before Noise handshake completes")
    {:ok, state}
  end

  @doc false
  def handle_cast(:restart_stream, %State{} = state) do
    state = %{state | stream_started?: false}

    # WebSockex accepts {:ok, state} or {:reply, single_frame, state} — a bare
    # frame list dies in Frame.encode_frame and {:noreply, _} is a badreply
    # that terminates the process. Extra frames go through the mailbox, where
    # each handle_info reply carries exactly one frame.
    case maybe_send_stream_start(state) do
      {:ok, new_state, []} ->
        {:ok, new_state}

      {:ok, new_state, [reply | rest]} ->
        Enum.each(rest, &send(self(), {:send_raw_frame, &1}))
        {:reply, reply, new_state}
    end
  end

  @impl true
  @doc false
  @spec handle_info(term(), State.t()) ::
          {:reply, term(), State.t()} | {:ok, State.t()}
  def handle_info({:send_raw_frame, frame}, state) do
    Logger.debug("[CONN] Sending raw frame (#{byte_size(elem(frame, 1))} bytes)")
    {:reply, frame, state}
  end

  def handle_info({:send_client_finish, frame}, state) do
    Logger.debug("[CONN] Sending client_finish")
    # Mark stream as started - whatsmeow doesn't send xmlstreamstart, server just sends messages
    {:reply, frame, %{state | stream_started?: true}}
  end

  def handle_info(msg, state) do
    Logger.warning("Unexpected message in Conn: #{Log.term_summary(msg)}")
    {:ok, state}
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
    Logger.debug("[CONN] Processing server hello")

    case Noise.handle_server_hello(noise, frame) do
      {:ok, client_finish, noise_state} ->
        Logger.debug("[CONN] Server hello processed, phase=#{inspect(noise_state.phase)}")
        state = %{state | noise: noise_state}
        {state, reply} = build_reply(state, client_finish)
        Logger.debug("[CONN] Sending client_finish")
        notify_session(state.session, {:noise, :handshake_completed})
        send(self(), {:send_client_finish, reply})
        {:ok, state, []}

      {:error, reason} ->
        Logger.error("[CONN] Noise handshake failed: #{Log.reason(reason)}")
        notify_session(state.session, {:error, reason})
        {:close, state}
    end
  end

  defp handle_payload_frame(%State{noise: %Noise{phase: :transport} = noise} = state, frame) do
    Logger.debug("[CONN] Transport frame: #{byte_size(frame)} bytes")

    case Noise.decrypt(noise, frame) do
      {:ok, plaintext, noise_state} ->
        Logger.debug("[CONN] Decrypted: #{byte_size(plaintext)} bytes")
        state = %{state | noise: noise_state}
        handle_decrypted_payload(state, plaintext)

      {:error, reason, noise_state} ->
        Logger.warning("[CONN] Decrypt failed: #{Log.reason(reason)}")
        notify_session(state.session, {:error, {:decrypt_failed, reason, frame}})
        {:ok, %{state | noise: noise_state}, []}

      {:error, reason} ->
        Logger.warning("[CONN] Decrypt failed: #{Log.reason(reason)}")
        notify_session(state.session, {:error, {:decrypt_failed, reason, frame}})
        {:ok, state, []}
    end
  end

  defp handle_payload_frame(state, _frame) do
    Logger.error("[CONN] Unknown frame in unknown phase, closing")
    {:close, state}
  end

  defp handle_decrypted_payload(state, <<>>) do
    notify_session(state.session, {:connection_message, :empty})
    {:ok, state, []}
  end

  defp handle_decrypted_payload(state, plaintext) do
    with {:ok, unpacked} <- Binary.unpack(plaintext),
         {:ok, node} <- Binary.decode(unpacked) do
      Logger.debug("[CONN] Received node: <#{node.tag}>")

      notify_session(state.session, {:connection_message, node})
      {:ok, state, []}
    else
      {:error, reason} ->
        Logger.warning("[CONN] Failed to decode payload: #{Log.reason(reason)}")
        notify_session(state.session, {:connection_binary, plaintext})
        {:ok, state, []}
    end
  end

  defp build_reply(%State{} = state, payload) do
    include_header = not state.header_sent?
    frame = Frame.encode(payload, include_header: include_header)

    header_hex =
      if include_header do
        Base.encode16(Frame.header(), case: :lower)
      else
        "none"
      end

    Logger.debug(
      "sending frame include_header=#{include_header} header_hex=#{header_hex} payload=#{byte_size(payload)} bytes frame=#{byte_size(frame)} bytes"
    )

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

  defp normalize_replies(replies) when is_list(replies), do: replies

  defp maybe_send_stream_start(%State{noise: %Noise{phase: :transport} = noise} = state) do
    Logger.debug("[CONN] Sending stream_start only (no handshake for initial pairing)")

    with {:ok, stream_start} <- build_stream_start_node(state),
         {:ok, stream_bin} <- Binary.encode(stream_start),
         _ =
           Logger.debug("[CONN] stream_start bytes=#{byte_size(stream_bin)}"),
         {:ok, stream_cipher, noise_state} <- Noise.encrypt(noise, stream_bin),
         {new_state, stream_reply} <-
           build_reply(%{state | noise: noise_state, stream_started?: true}, stream_cipher) do
      Logger.debug("[CONN] Stream start ready (#{byte_size(stream_cipher)} bytes)")
      {:ok, new_state, [stream_reply]}
    else
      {:error, reason} ->
        Logger.error("[CONN] failed to send stream start: #{Log.reason(reason)}")
        {:ok, state, []}
    end
  end

  defp maybe_send_stream_start(%State{noise: noise} = state) do
    phase = if noise, do: noise.phase, else: nil

    Logger.warning(
      "[CONN] maybe_send_stream_start skipped - noise phase=#{inspect(phase)} (not :transport)"
    )

    {:ok, state, []}
  end

  defp log_outgoing_node(node, _encoded) do
    log_outgoing_node_line(node, "Sending node: #{node_to_xml(node)}")
    :ok
  rescue
    _ ->
      log_outgoing_node_line(node, "Sending node: #{Log.term_summary(node)}")
      :ok
  end

  defp log_outgoing_node_line(node, message) do
    if quiet_iq_result?(node) do
      Logger.debug(message)
    else
      Logger.debug(message)
    end
  end

  # Server pings are answered with bare-domain IQ results and can be frequent.
  # Keep them at debug level so message/receipt flow is easier to inspect.
  defp quiet_iq_result?(%Node{tag: "iq", attrs: attrs}) do
    Map.get(attrs, "type") == "result" and
      Map.get(attrs, "id") in [nil, ""] and
      server_jid?(Map.get(attrs, "to"))
  end

  defp quiet_iq_result?(_), do: false

  defp server_jid?(%ExWapp.JID{server: "s.whatsapp.net", user: user}) when user in [nil, ""],
    do: true

  defp server_jid?("s.whatsapp.net"), do: true
  defp server_jid?(_), do: false

  defp node_to_xml(%Node{tag: tag, attrs: attrs, content: nil}) do
    "<#{tag}#{attrs_to_string(attrs)}/>"
  end

  defp node_to_xml(%Node{tag: tag, attrs: attrs, content: []}) do
    "<#{tag}#{attrs_to_string(attrs)}/>"
  end

  defp node_to_xml(%Node{tag: tag, attrs: attrs, content: content}) when is_binary(content) do
    "<#{tag}#{attrs_to_string(attrs)}>[binary #{byte_size(content)} bytes]</#{tag}>"
  end

  defp node_to_xml(%Node{tag: tag, attrs: attrs, content: %Raw{data: data}}) do
    "<#{tag}#{attrs_to_string(attrs)}>[raw #{byte_size(data)} bytes]</#{tag}>"
  end

  defp node_to_xml(%Node{tag: tag, attrs: attrs, content: content})
       when is_list(content) and length(content) > 20 do
    "<#{tag}#{attrs_to_string(attrs)}>[#{length(content)} children]</#{tag}>"
  end

  defp node_to_xml(%Node{tag: tag, attrs: attrs, content: content}) when is_list(content) do
    inner = Enum.map_join(content, "", &node_to_xml/1)
    "<#{tag}#{attrs_to_string(attrs)}>#{inner}</#{tag}>"
  end

  defp node_to_xml(other), do: Log.term_summary(other)

  defp attrs_to_string(attrs) do
    attrs
    |> Log.attrs()
    |> Enum.map_join("", fn
      {key, true} ->
        " #{key}"

      {key, value} ->
        " #{key}=\"#{value}\""
    end)
  end

  defp build_stream_start_node(%State{store: store}) do
    data = Store.load!(store)
    info = Map.get(data, :client_info, %{})

    # Minimal attributes matching whatsmeow implementation
    attrs = %{"to" => "s.whatsapp.net"}
    attrs = maybe_put_attr(attrs, "resource", stream_resource(info))

    {:ok, %Binary.Node{tag: "xmlstreamstart", attrs: attrs, content: nil}}
  end

  defp stream_resource(%{stream_resource: resource}) when is_binary(resource) and resource != "",
    do: resource

  defp stream_resource(%{device_name: name}) when is_binary(name) and name != "",
    do: name

  defp stream_resource(%{phone_id: phone_id}) when is_binary(phone_id) and phone_id != "",
    do: phone_id

  defp stream_resource(_), do: "EX_WAPP"

  defp maybe_put_attr(attrs, key, value), do: Map.put(attrs, key, value)
end
