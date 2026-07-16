defmodule ExWapp.Store.Ets.Writer do
  @moduledoc false

  use GenServer

  require Logger

  alias ExWapp.Store.Ets

  defstruct [:store, batches: %{}, dirty?: false]

  @type mutation_result ::
          {:ok, :changed | :unchanged}
          | {:ok, term(), :changed | :unchanged}
          | {:error, term()}

  @spec start_link(Ets.t()) :: GenServer.on_start()
  def start_link(store), do: GenServer.start_link(__MODULE__, store)

  @spec mutate(pid(), (-> mutation_result())) :: :ok | {:error, term()}
  def mutate(writer, fun) when is_pid(writer) and is_function(fun, 0) do
    GenServer.call(writer, {:mutate, fun}, :infinity)
  end

  @spec read(pid(), (-> term())) :: term()
  def read(writer, fun) when is_pid(writer) and is_function(fun, 0) do
    GenServer.call(writer, {:read, fun}, :infinity)
  end

  @spec clear(pid(), (-> :ok | {:error, term()})) :: :ok | {:error, term()}
  def clear(writer, fun) when is_pid(writer) and is_function(fun, 0) do
    GenServer.call(writer, {:clear, fun}, :infinity)
  end

  @spec begin_batch(pid(), term()) :: :ok
  def begin_batch(writer, reason), do: GenServer.call(writer, {:begin_batch, reason})

  @spec finish_batch(pid(), term()) :: :ok | {:error, term()}
  def finish_batch(writer, reason), do: GenServer.call(writer, {:finish_batch, reason}, :infinity)

  @spec flush(pid()) :: :ok | {:error, term()}
  def flush(writer), do: GenServer.call(writer, :flush, :infinity)

  @spec stop(pid()) :: :ok | {:error, term()}
  def stop(writer) when is_pid(writer) do
    if Process.alive?(writer), do: GenServer.call(writer, :close, :infinity), else: :ok
  catch
    :exit, {:noproc, _} -> :ok
    :exit, :noproc -> :ok
  end

  @impl true
  def init(store), do: {:ok, %__MODULE__{store: store}}

  @impl true
  def handle_call({:read, fun}, _from, state) do
    {:reply, run_read(fun), state}
  end

  def handle_call({:mutate, fun}, {caller, _tag}, state) do
    case run_mutation(fun) do
      {:ok, :unchanged} ->
        {:reply, :ok, state}

      {:ok, :changed} ->
        state
        |> Map.put(:dirty?, true)
        |> maybe_flush(caller)
        |> reply_with_flush_result()

      {:ok, reply, :unchanged} ->
        {:reply, reply, state}

      {:ok, reply, :changed} ->
        state
        |> Map.put(:dirty?, true)
        |> maybe_flush(caller)
        |> reply_with_flush_result(reply)

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:clear, fun}, _from, state) do
    result = run_clear(fun)
    state = if result == :ok, do: %{state | dirty?: false}, else: state
    {:reply, result, state}
  end

  def handle_call({:begin_batch, reason}, {caller, _tag}, state) do
    {:reply, :ok, %{state | batches: add_batch(state.batches, caller, reason)}}
  end

  def handle_call({:finish_batch, reason}, {caller, _tag}, state) do
    case remove_batch(state.batches, caller, reason) do
      {:ok, batches} ->
        state
        |> Map.put(:batches, batches)
        |> flush_state()
        |> reply_with_flush_result()

      {:nested, batches} ->
        {:reply, :ok, %{state | batches: batches}}

      :not_found ->
        {:reply, {:error, :batch_not_started}, state}
    end
  end

  def handle_call(:flush, _from, state) do
    state
    |> flush_state()
    |> reply_with_flush_result()
  end

  def handle_call(:close, _from, state) do
    case flush_state(state) do
      {:ok, state} -> {:stop, :normal, :ok, state}
      {{:error, _reason} = error, state} -> {:stop, :normal, error, state}
    end
  end

  @impl true
  def handle_info({:"ETS-TRANSFER", _table, _from, _gift}, state), do: {:noreply, state}

  def handle_info({:DOWN, monitor, :process, owner, _reason}, state) do
    case Map.get(state.batches, owner) do
      %{monitor: ^monitor} ->
        state = %{state | batches: Map.delete(state.batches, owner)}

        case flush_state(state) do
          {:ok, state} ->
            {:noreply, state}

          {{:error, reason}, state} ->
            Logger.error(
              "[STORE] failed to flush abandoned batch reason=#{ExWapp.Log.reason(reason)}"
            )

            {:noreply, state}
        end

      _other ->
        {:noreply, state}
    end
  end

  defp run_mutation(fun) do
    case fun.() do
      {:ok, status} when status in [:changed, :unchanged] -> {:ok, status}
      {:ok, reply, status} when status in [:changed, :unchanged] -> {:ok, reply, status}
      {:error, _reason} = error -> error
      other -> {:error, {:invalid_store_mutation_result, other}}
    end
  rescue
    exception -> {:error, {:store_mutation_failed, exception}}
  catch
    kind, reason -> {:error, {:store_mutation_failed, {kind, reason}}}
  end

  # A user-supplied reader must never take down the process that owns every ETS
  # table. Return a regular store error while leaving the writer and tables
  # alive, matching the isolation already provided for updater callbacks.
  defp run_read(fun) do
    fun.()
  rescue
    exception -> {:error, {:store_read_failed, exception}}
  catch
    kind, reason -> {:error, {:store_read_failed, {kind, reason}}}
  end

  defp run_clear(fun) do
    case fun.() do
      :ok -> :ok
      {:error, _reason} = error -> error
      other -> {:error, {:invalid_store_clear_result, other}}
    end
  rescue
    exception -> {:error, {:store_clear_failed, exception}}
  catch
    kind, reason -> {:error, {:store_clear_failed, {kind, reason}}}
  end

  defp maybe_flush(%__MODULE__{batches: batches} = state, caller) do
    if Map.has_key?(batches, caller), do: {:ok, state}, else: flush_state(state)
  end

  defp flush_state(%__MODULE__{dirty?: false} = state), do: {:ok, state}

  defp flush_state(%__MODULE__{} = state) do
    case isolated_flush(state.store) do
      :ok -> {:ok, %{state | dirty?: false}}
      {:error, _reason} = error -> {error, state}
    end
  end

  # Store encoding and compression can briefly allocate several times the
  # snapshot size. Keeping that work on a short-lived process prevents a
  # long-running writer from retaining an oversized heap after a large sync.
  defp isolated_flush(store) do
    owner = self()
    result_ref = make_ref()

    {pid, monitor} =
      spawn_monitor(fn ->
        send(owner, {result_ref, Ets.flush_snapshot(store)})
      end)

    receive do
      {^result_ref, result} ->
        Process.demonitor(monitor, [:flush])
        result

      {:DOWN, ^monitor, :process, ^pid, reason} ->
        {:error, {:snapshot_process_failed, reason}}
    end
  end

  defp reply_with_flush_result({:ok, state}), do: {:reply, :ok, state}
  defp reply_with_flush_result({{:error, _reason} = error, state}), do: {:reply, error, state}

  defp reply_with_flush_result({:ok, state}, reply), do: {:reply, reply, state}

  defp reply_with_flush_result({{:error, _reason} = error, state}, _reply),
    do: {:reply, error, state}

  defp add_batch(batches, owner, reason) do
    case Map.fetch(batches, owner) do
      {:ok, batch} ->
        Map.put(batches, owner, %{
          batch
          | count: batch.count + 1,
            reasons: [reason | batch.reasons]
        })

      :error ->
        Map.put(batches, owner, %{
          count: 1,
          monitor: Process.monitor(owner),
          reasons: [reason]
        })
    end
  end

  defp remove_batch(batches, owner, reason) do
    case Map.get(batches, owner) do
      %{count: count} = batch when count > 1 ->
        updated = %{batch | count: count - 1, reasons: List.delete(batch.reasons, reason)}
        {:nested, Map.put(batches, owner, updated)}

      %{monitor: monitor} ->
        Process.demonitor(monitor, [:flush])
        {:ok, Map.delete(batches, owner)}

      nil ->
        :not_found
    end
  end
end
