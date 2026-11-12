defmodule ExWapp.Store.PathLock do
  @moduledoc false
  use GenServer

  # Local-node lock: use a transactional external adapter when multiple BEAM
  # nodes need the same account. Include node() to avoid locking unrelated paths
  # on other machines connected through Erlang distribution.
  def canonical(path), do: canonical(Path.expand(path), 0)

  defp canonical(_path, depth) when depth > 40,
    do: raise(ArgumentError, "store path has a symlink cycle")

  defp canonical(path, depth) do
    Enum.reduce(Path.split(path), "", fn part, parent ->
      candidate = if parent == "", do: part, else: Path.join(parent, part)

      case File.read_link(candidate) do
        {:ok, target} -> canonical(Path.expand(target, Path.dirname(candidate)), depth + 1)
        _ -> candidate
      end
    end)
  end

  def start(path) do
    GenServer.start(__MODULE__, {path, self()}, name: {:global, {__MODULE__, node(), path}})
  end

  def watch_flush(lock, pid), do: GenServer.call(lock, {:watch_flush, pid})
  def attach(lock, owner), do: GenServer.call(lock, {:attach, owner})
  def release(nil), do: :ok

  def release(lock) do
    GenServer.stop(lock, :normal)
  catch
    :exit, _ -> :ok
  end

  @impl true
  def init({path, owner}),
    do: {:ok, %{path: path, monitor: Process.monitor(owner), owner_down?: false, flushes: %{}}}

  @impl true
  def handle_call({:watch_flush, pid}, _from, state) do
    ref = Process.monitor(pid)
    {:reply, :ok, %{state | flushes: Map.put(state.flushes, ref, pid)}}
  end

  def handle_call({:attach, owner}, _from, state) do
    Process.demonitor(state.monitor, [:flush])
    {:reply, :ok, %{state | monitor: Process.monitor(owner)}}
  end

  @impl true
  def handle_info({:DOWN, monitor, :process, _pid, _reason}, %{monitor: monitor} = state) do
    # The flush helper can be inside a filesystem operation when its Writer
    # dies. Do not let a replacement Writer open the path until it has exited.
    Enum.each(state.flushes, fn {_ref, pid} -> Process.exit(pid, :kill) end)
    finish_if_unused(%{state | owner_down?: true})
  end

  def handle_info({:DOWN, monitor, :process, _pid, _reason}, state) do
    finish_if_unused(%{state | flushes: Map.delete(state.flushes, monitor)})
  end

  defp finish_if_unused(%{owner_down?: true, flushes: flushes} = state)
       when map_size(flushes) == 0,
       do: {:stop, :normal, state}

  defp finish_if_unused(state), do: {:noreply, state}
end
