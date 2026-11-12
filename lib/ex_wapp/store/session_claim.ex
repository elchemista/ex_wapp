defmodule ExWapp.Store.SessionClaim do
  @moduledoc false
  use GenServer

  def claim(store_owner), do: claim(store_owner, 3)

  defp claim(store_owner, attempts) do
    # A separate process owns the global name: the session itself may already
    # have a global GenServer name, and OTP permits only one per process.
    case GenServer.start(__MODULE__, {self(), store_owner},
           name: {:global, {__MODULE__, node(), store_owner}}
         ) do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, pid}} ->
        case acquire(pid) do
          :ok -> :ok
          :gone when attempts > 0 -> claim(store_owner, attempts - 1)
          _ -> raise ArgumentError, "this store already belongs to another live WhatsApp session"
        end

      {:error, reason} ->
        raise ArgumentError, "cannot claim WhatsApp session store: #{inspect(reason)}"
    end
  end

  defp acquire(pid) do
    GenServer.call(pid, {:acquire, self()})
  catch
    :exit, {:noproc, _} -> :gone
    :exit, {:normal, _} -> :gone
  end

  @impl true
  def init({session, store_owner}) do
    if Process.alive?(store_owner) do
      {:ok,
       %{
         session: session,
         session_monitor: Process.monitor(session),
         store_owner: store_owner,
         store_monitor: Process.monitor(store_owner)
       }}
    else
      {:stop, :store_closed}
    end
  end

  @impl true
  def handle_call({:acquire, session}, _from, state) do
    if Process.alive?(state.store_owner) and
         (session == state.session or not Process.alive?(state.session)) do
      Process.demonitor(state.session_monitor, [:flush])
      {:reply, :ok, %{state | session: session, session_monitor: Process.monitor(session)}}
    else
      {:reply, {:error, :store_claimed}, state}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    if ref in [state.session_monitor, state.store_monitor],
      do: {:stop, :normal, state},
      else: {:noreply, state}
  end
end
