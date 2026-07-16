defmodule ExWapp.Session.OutboundQueue do
  @moduledoc """
  Per-session outbound command queue.

  It serializes transport writes and keeps pending commands while the transport
  connection is unavailable.
  """

  use GenServer
  require Logger

  alias ExWapp.Log

  @type item :: {:send_node, term()} | :restart_stream

  defstruct session: nil,
            transport: ExWapp.Conn,
            conn: nil,
            queue: :queue.new(),
            max_size: 10_000,
            drop_policy: :reject_new,
            flush_batch_size: 100,
            flush_tick_ms: 10,
            flush_timer: nil

  @type t :: %__MODULE__{
          session: pid(),
          transport: module(),
          conn: pid() | nil,
          queue: :queue.queue(item()),
          max_size: pos_integer(),
          drop_policy: :reject_new | :drop_oldest,
          flush_batch_size: pos_integer(),
          flush_tick_ms: pos_integer(),
          flush_timer: reference() | nil
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
      transport: Keyword.get(opts, :transport, ExWapp.Conn),
      max_size: Keyword.get(opts, :max_size, 10_000),
      drop_policy: Keyword.get(opts, :drop_policy, :reject_new),
      flush_batch_size: Keyword.get(opts, :flush_batch_size, 100),
      flush_tick_ms: Keyword.get(opts, :flush_tick_ms, 10)
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
    state = enqueue_item(state, item)
    {:noreply, flush(state)}
  end

  @impl true
  def handle_info(:flush_queue, state) do
    state = %{state | flush_timer: nil}
    {:noreply, flush(state)}
  end

  defp flush(%{conn: nil} = state), do: state

  defp flush(state) do
    {state, sent_count} = flush_batch(state, state.flush_batch_size)

    if sent_count >= state.flush_batch_size and :queue.len(state.queue) > 0 do
      schedule_flush(state)
    else
      state
    end
  end

  defp flush_batch(state, remaining) when remaining <= 0, do: {state, 0}

  defp flush_batch(%{queue: queue} = state, remaining) do
    case :queue.out(queue) do
      {:empty, _queue} ->
        {state, 0}

      {{:value, item}, rest} ->
        case dispatch(item, state) do
          :ok ->
            next_state = %{state | queue: rest}
            {final_state, sent_rest} = flush_batch(next_state, remaining - 1)
            {final_state, sent_rest + 1}

          {:error, reason} ->
            Logger.warning("[OUTBOUND] dispatch failed: #{Log.reason(reason)}")
            send(state.session, {:outbound_error, item, reason})
            {%{state | queue: :queue.in_r(item, rest)}, 0}
        end
    end
  end

  defp schedule_flush(%{flush_timer: nil} = state) do
    timer = Process.send_after(self(), :flush_queue, state.flush_tick_ms)
    %{state | flush_timer: timer}
  end

  defp schedule_flush(state), do: state

  defp enqueue_item(state, item) do
    queue_len = :queue.len(state.queue)

    cond do
      queue_len < state.max_size ->
        %{state | queue: :queue.in(item, state.queue)}

      state.drop_policy == :drop_oldest ->
        trimmed =
          case :queue.out(state.queue) do
            {:empty, q} -> q
            {{:value, _oldest}, rest} -> rest
          end

        %{state | queue: :queue.in(item, trimmed)}

      true ->
        send(state.session, {:outbound_error, item, :queue_full})
        state
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
