defmodule ExWapp.Conn do
  @moduledoc """
  Thin wrapper around the WhatsApp WebSocket transport.

  The module boots the TLS WebSocket required by WhatsApp Web and delegates
  frame parsing to the `ExWapp.Noise` and `ExWapp.Binary` layers. Only a
  skeleton is implemented so far – the actual Noise handshake and node
  exchange still have to be wired in.
  """

  use WebSockex
  require Logger

  alias ExWapp.Noise

  @url "wss://web.whatsapp.com/ws/chat"
  @origin "https://web.whatsapp.com"

  defmodule State do
    @moduledoc false
    defstruct [:session, :store, :noise]
  end

  @type options :: [session: pid(), store: any(), opts: keyword()]

  @doc """
  Starts the WebSocket process.

  The session pid is used to report handshake progress and errors. The
  store reference can be leveraged later to persist Noise static keys.
  """
  @spec start_link(options()) :: GenServer.on_start()
  def start_link(opts) do
    session = Keyword.fetch!(opts, :session)
    noise_state = Noise.new()
    headers = [{"Origin", @origin}]

    state = %State{
      session: session,
      store: Keyword.get(opts, :store),
      noise: noise_state
    }

    WebSockex.start_link(@url, __MODULE__, state, extra_headers: headers)
  end

  @doc """
  Asks the connection process to send a binary node.

  The heavy lifting happens in `Noise.wrap_outgoing/2`; this helper only
  marshals the node through the WebSockex message API.
  """
  @spec send_node(pid(), term()) :: :ok
  def send_node(pid, node), do: WebSockex.cast(pid, {:send_node, node})

  @impl true
  def handle_connect(_conn, state) do
    Logger.info("websocket connected; Noise handshake pending")
    notify_session(state.session, {:transport, :connected})
    {:ok, state}
  end

  @impl true
  def handle_disconnect(_reason, state) do
    notify_session(state.session, {:transport, :closed})
    {:ok, state}
  end

  @impl true
  def handle_frame({:binary, payload}, state) do
    case Noise.handle_incoming(state.noise, payload) do
      {:error, reason} ->
        Logger.error("failed to handle incoming frame: #{inspect(reason)}")
        notify_session(state.session, {:error, reason})
        {:close, state}

      other ->
        Logger.warning("ignoring Noise payload: #{inspect(other)}")
        {:ok, state}
    end
  end

  def handle_frame(_other, state), do: {:ok, state}

  @impl true
  def handle_cast({:send_node, node}, state) do
    case Noise.wrap_outgoing(state.noise, node) do
      {:error, reason} ->
        Logger.error("cannot send node: #{inspect(reason)}")
        notify_session(state.session, {:error, reason})
        {:ok, state}

      other ->
        Logger.warning("unexpected Noise outcome on send: #{inspect(other)}")
        {:ok, state}
    end
  end

  defp notify_session(pid, message) when is_pid(pid), do: send(pid, {:connection_event, message})

end
