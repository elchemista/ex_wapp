defmodule ExWapp.Session do
  @moduledoc """
  Coordinates the lifecycle of a WhatsApp Web connection.
  """

  use GenServer
  require Logger

  alias ExWapp.{Binary, Conn, Pairing, Store}

  @typedoc """
  Human readable events emitted during the pairing flow.
  """
  @type qr_event :: {:code, String.t()} | :success | {:error, term()}

  defstruct status: :idle,
            conn: nil,
            store: nil,
            qr_subscribers: %{},
            opts: [],
            pairing: nil

  @type state :: %__MODULE__{
          status: :idle | :connecting | :connected,
          conn: pid() | nil,
          store: Store.t() | nil,
          qr_subscribers: %{reference() => {pid(), reference()}},
          opts: keyword(),
          pairing: Pairing.state()
        }

  @doc """
  Starts the session process.

  Options:

    * `:name`  – register the process under a given name
    * `:store` – a store backend in one of the forms:
                 - `nil` (default ETS)
                 - `MyStoreModule`
                 - `{MyStoreModule, opts}`
                 - `%MyStoreStruct{}` (already initialized)
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))
  end

  @doc "Bootstraps the network connection asynchronously."
  @spec connect(GenServer.server()) :: :ok
  def connect(server), do: GenServer.cast(server, :connect)

  @doc "Internal API for testing / stream setup."
  @spec subscribe_qr(GenServer.server()) :: {:ok, reference()}
  def subscribe_qr(server), do: GenServer.call(server, {:subscribe_qr, self()})

  @doc "Cancels a previously created QR subscription."
  @spec unsubscribe_qr(GenServer.server(), reference()) :: :ok
  def unsubscribe_qr(server, ref), do: GenServer.cast(server, {:unsubscribe_qr, ref})

  @doc "Queues a plain text message for sending."
  @spec send_text(GenServer.server(), binary(), iodata()) :: :ok
  def send_text(server, jid, text),
    do: GenServer.cast(server, {:send_text, jid, IO.iodata_to_binary(text)})

  @doc "Builds a lazy stream of QR pairing events."
  @spec qr_stream(GenServer.server()) :: Enumerable.t()
  def qr_stream(server) do
    Stream.resource(
      fn -> subscribe_qr(server) end,
      fn subscription = {:ok, ref} ->
        receive do
          {:ex_wapp_qr, ^ref, event} -> {[event], subscription}
          {:ex_wapp_qr_closed, ^ref} -> {:halt, subscription}
        end
      end,
      fn {:ok, ref} -> unsubscribe_qr(server, ref) end
    )
  end

  @impl true
  def init(opts) do
    store = Store.new(Keyword.get(opts, :store))

    {:ok,
     %__MODULE__{
       opts: opts,
       store: store,
       pairing: Pairing.new(store)
     }}
  end

  @impl true
  def handle_cast(:connect, %__MODULE__{status: :idle} = state) do
    Process.send(self(), :bootstrap_connection, [])
    {:noreply, %{state | status: :connecting}}
  end

  def handle_cast(:connect, state), do: {:noreply, state}

  def handle_cast({:unsubscribe_qr, ref}, state) do
    case Map.pop(state.qr_subscribers, ref) do
      {nil, _} ->
        {:noreply, state}

      {{pid, mon}, subscribers} ->
        Process.demonitor(mon, [:flush])
        send(pid, {:ex_wapp_qr_closed, ref})
        {:noreply, %{state | qr_subscribers: subscribers}}
    end
  end

  def handle_cast({:send_text, jid, text}, state) do
    _ = maybe_send_text(state, jid, text)
    {:noreply, state}
  end

  @impl true
  def handle_call({:subscribe_qr, pid}, _from, state) do
    ref = make_ref()
    mon = Process.monitor(pid)
    new_state = %{state | qr_subscribers: Map.put(state.qr_subscribers, ref, {pid, mon})}
    {:reply, {:ok, ref}, new_state}
  end

  @impl true
  def handle_info(:bootstrap_connection, state) do
    {:noreply, do_bootstrap(state)}
  end

  def handle_info({:notify_qr, event}, state) do
    notify_qr(state, event)
    {:noreply, state}
  end

  def handle_info({:connection_event, {:noise, :handshake_started}}, state) do
    {:noreply, state}
  end

  def handle_info({:connection_event, {:noise, :handshake_completed}}, state) do
    {:noreply, %{state | status: :connected}}
  end

  def handle_info({:connection_event, {:connection_message, %Binary.Node{} = node}}, state) do
    {new_state, actions} = handle_connection_node(node, state)
    Enum.each(actions, &handle_pairing_action(&1, new_state))
    {:noreply, new_state}
  end

  def handle_info({:connection_event, {:connection_binary, _payload}}, state),
    do: {:noreply, state}

  def handle_info({:connection_event, {:error, reason}}, state) do
    notify_qr(state, {:error, reason})
    {:noreply, state}
  end

  def handle_info({:DOWN, mon, :process, _pid, _reason}, state) do
    new_subscribers =
      Enum.reduce(state.qr_subscribers, %{}, fn
        {ref, {pid, ref_mon}}, acc when ref_mon == mon ->
          send(pid, {:ex_wapp_qr_closed, ref})
          acc

        {ref, subscriber}, acc ->
          Map.put(acc, ref, subscriber)
      end)

    {:noreply, %{state | qr_subscribers: new_subscribers}}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp handle_connection_node(%Binary.Node{tag: "iq"} = node, state) do
    {pairing, actions} = Pairing.apply_node(state.pairing, node)

    pairing =
      case maybe_reset_pairing(actions, pairing) do
        {:ok, new_pairing} -> new_pairing
        :noop -> pairing
      end

    {%{state | pairing: pairing}, actions}
  end

  defp handle_connection_node(%Binary.Node{tag: "success"}, state) do
    {state, [:restart_stream]}
  end

  defp handle_connection_node(%Binary.Node{tag: "stream:features"}, state) do
    {state, []}
  end

  defp handle_connection_node(node, state) do
    Logger.debug("unhandled node: #{inspect(node)}")
    {state, []}
  end

  defp do_bootstrap(%__MODULE__{conn: nil} = state) do
    case Conn.start_link(session: self(), store: state.store, opts: state.opts) do
      {:ok, pid} ->
        %{state | conn: pid}

      {:error, reason} ->
        notify_qr(state, {:error, reason})
        %{state | status: :idle}
    end
  end

  defp do_bootstrap(state), do: state

  defp maybe_send_text(state, _jid, _text) do
    case state.status do
      :connected -> :ok
      _ -> {:error, :not_connected}
    end
  end

  defp notify_qr(state, event) do
    Enum.each(state.qr_subscribers, fn {ref, {pid, _mon}} ->
      send(pid, {:ex_wapp_qr, ref, event})
    end)
  end

  defp handle_pairing_action({:send_node, node}, %__MODULE__{conn: conn}) when is_pid(conn) do
    :ok = Conn.send_node(conn, node)
  end

  defp handle_pairing_action({:qr, code}, state), do: notify_qr(state, {:code, code})
  defp handle_pairing_action({:status, :success}, state), do: notify_qr(state, :success)
  defp handle_pairing_action({:error, reason}, state), do: notify_qr(state, {:error, reason})

  defp handle_pairing_action(:restart_stream, %__MODULE__{conn: conn}) when is_pid(conn) do
    :ok = Conn.restart_stream(conn)
  end

  defp handle_pairing_action(_other, _state), do: :ok

  defp maybe_reset_pairing(actions, pairing) do
    if Enum.any?(actions, &match?({:status, :success}, &1)) do
      {:ok, Pairing.new(pairing.store)}
    else
      :noop
    end
  end
end
