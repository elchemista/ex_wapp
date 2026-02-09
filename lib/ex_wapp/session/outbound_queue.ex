defmodule ExWapp.Session.OutboundQueue do
  @moduledoc """
  Per-session outbound command queue.

  It serializes transport writes and keeps pending commands while the transport
  connection is unavailable.
  """

  use GenServer
  require Logger

  @type item :: {:send_node, term()} | :restart_stream

  defstruct session: nil,
            transport: ExWapp.Conn,
            conn: nil,
            queue: :queue.new()

  @type t :: %__MODULE__{
          session: pid(),
          transport: module(),
          conn: pid() | nil,
          queue: :queue.queue(item())
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec set_conn(pid(), pid()) :: :ok
  def set_conn(pid, conn), do: GenServer.cast(pid, {:set_conn, conn})

  @spec clear_conn(pid()) :: :ok
  def clear_conn(pid), do: GenServer.cast(pid, :clear_conn)

  @spec enqueue_node(pid(), term()) :: :ok
  def enqueue_node(pid, node), do: GenServer.cast(pid, {:enqueue, {:send_node, node}})

  @spec restart_stream(pid()) :: :ok
  def restart_stream(pid), do: GenServer.cast(pid, {:enqueue, :restart_stream})

  @impl true
  def init(opts) do
    state = %__MODULE__{
      session: Keyword.fetch!(opts, :session),
      transport: Keyword.get(opts, :transport, ExWapp.Conn)
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:set_conn, conn}, state) do
    {:noreply, flush(%{state | conn: conn})}
  end

  def handle_cast(:clear_conn, state) do
    {:noreply, %{state | conn: nil}}
  end

  def handle_cast({:enqueue, item}, state) do
    state = %{state | queue: :queue.in(item, state.queue)}
    {:noreply, flush(state)}
  end

  defp flush(%{conn: nil} = state), do: state

  defp flush(%{queue: queue} = state) do
    case :queue.out(queue) do
      {:empty, _queue} ->
        state

      {{:value, item}, rest} ->
        case dispatch(item, state) do
          :ok ->
            flush(%{state | queue: rest})

          {:error, reason} ->
            Logger.warning("[OUTBOUND] dispatch failed: #{inspect(reason)}")
            send(state.session, {:outbound_error, item, reason})
            %{state | queue: :queue.in_r(item, rest)}
        end
    end
  end

  defp dispatch({:send_node, node}, %{transport: transport, conn: conn}) do
    transport.send_node(conn, node)
  rescue
    e -> {:error, {:exception, e}}
  end

  defp dispatch(:restart_stream, %{transport: transport, conn: conn}) do
    transport.restart_stream(conn)
  rescue
    e -> {:error, {:exception, e}}
  end
end
