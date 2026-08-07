defmodule ExWapp.Session.AppStateSync do
  @moduledoc false

  require Logger

  alias ExWapp.AppState.Engine
  alias ExWapp.{Call, Config, Log, Store}
  alias ExWapp.Session.Worker.Subscribers

  @type source :: :initial | :notification

  @spec schedule_initial(map(), pid()) :: map()
  def schedule_initial(state, session_pid) when is_map(state) and is_pid(session_pid) do
    cond do
      not initial_enabled?(state) ->
        Logger.debug(
          "[APP_STATE] Automatic initial sync disabled session=#{Log.reference(state.session_id)}"
        )

      keys_available?(state.store) ->
        send(session_pid, {:app_state_initial_sync, Engine.all_collections()})

      true ->
        Logger.debug(
          "[APP_STATE] Deferring initial sync until app-state keys are available session=#{Log.reference(state.session_id)}"
        )
    end

    state
  end

  @spec initial_enabled?(map()) :: boolean()
  def initial_enabled?(state) when is_map(state) do
    Config.get(state.runtime_cfg, [:app_state, :initial_sync_enabled], true)
  end

  @spec keys_available?(term()) :: boolean()
  def keys_available?(store) do
    store
    |> Store.load!()
    |> Map.get(:app_state_keys, %{})
    |> map_size()
    |> Kernel.>(0)
  rescue
    _ -> false
  catch
    _, _ -> false
  end

  @spec refresh(pid() | nil, pid(), term(), [term()], source(), term(), map()) ::
          {:ok, pid()} | {:error, term()}
  def refresh(
        task_supervisor,
        session_pid,
        store,
        collection_names,
        source,
        session_id \\ nil,
        runtime_cfg \\ %{}
      ) do
    names =
      collection_names
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()

    task = fn ->
      result = safe_run_refresh(session_pid, store, names, source, session_id, runtime_cfg)

      if source == :initial do
        send(session_pid, {:initial_sync_finished, self(), result})
      end

      result
    end

    case start_refresh_task(task_supervisor, task) do
      {:ok, task_pid} ->
        {:ok, task_pid}

      {:error, reason} ->
        Logger.warning(
          "[APP_STATE] Failed to start collection refresh source=#{source}: #{Log.reason(reason)}"
        )

        {:error, reason}
    end
  end

  @spec broadcast_failure(term(), pid(), term(), map()) :: :ok
  def broadcast_failure(session_id, session_pid, reason, payload) do
    Subscribers.broadcast_lifecycle(
      session_id,
      {:ex_wapp_session, :initial_sync, :failed, reason,
       event_payload(session_id, session_pid, payload)}
    )
  rescue
    exception ->
      Logger.warning(
        "[APP_STATE] failed to broadcast initial sync failure: #{Log.reason(exception)}"
      )

      :ok
  catch
    _kind, _reason -> :ok
  end

  @spec start_refresh_task(pid() | nil, (-> term())) :: {:ok, pid()} | {:error, term()}
  defp start_refresh_task(task_supervisor, task)
       when is_pid(task_supervisor) and is_function(task, 0) do
    Task.Supervisor.start_child(task_supervisor, task)
  catch
    :exit, reason -> {:error, {:task_supervisor_exit, reason}}
  end

  defp start_refresh_task(_task_supervisor, _task),
    do: {:error, :task_supervisor_unavailable}

  @spec safe_run_refresh(pid(), term(), [String.t()], source(), term(), map()) ::
          :completed | :failed | :ok
  defp safe_run_refresh(session_pid, store, names, source, session_id, runtime_cfg) do
    run_refresh(session_pid, store, names, source, session_id, runtime_cfg)
  rescue
    exception ->
      reason = {:exception, exception.__struct__}

      Logger.warning(
        "[APP_STATE] collection refresh crashed source=#{source} reason=#{Log.reason(reason)}"
      )

      maybe_broadcast_unexpected_failure(source, session_id, session_pid, reason)
      :failed
  catch
    kind, caught_reason ->
      reason = {kind, caught_reason}

      Logger.warning(
        "[APP_STATE] collection refresh stopped source=#{source} reason=#{Log.reason(reason)}"
      )

      maybe_broadcast_unexpected_failure(source, session_id, session_pid, reason)
      :failed
  end

  @spec maybe_broadcast_unexpected_failure(source(), term(), pid(), term()) :: :ok
  defp maybe_broadcast_unexpected_failure(:initial, session_id, session_pid, reason) do
    broadcast_failure(session_id, session_pid, reason, %{})
  end

  defp maybe_broadcast_unexpected_failure(
         _source,
         _session_id,
         _session_pid,
         _reason
       ),
       do: :ok

  @spec run_refresh(pid(), term(), [String.t()], source(), term(), map()) ::
          :completed | :failed | :ok
  defp run_refresh(session_pid, store, names, :initial, session_id, runtime_cfg) do
    Subscribers.broadcast_lifecycle(
      session_id,
      {:ex_wapp_session, :initial_sync, :started,
       event_payload(session_id, session_pid, %{collection_names: names})}
    )

    :ok = begin_store_batch(store, :initial_app_state_sync)
    total_count = length(names)

    {success_count, failures} =
      names
      |> Enum.with_index(1)
      |> Enum.reduce({0, []}, fn {collection_name, index}, counts ->
        refresh_collection(
          session_pid,
          store,
          session_id,
          collection_name,
          index,
          total_count,
          counts,
          runtime_cfg
        )
      end)

    flush_result = finish_store_batch(store, :initial_app_state_sync)
    failures = Enum.reverse(failures)

    broadcast_outcome(
      session_id,
      session_pid,
      names,
      success_count,
      failures,
      flush_result
    )

    sync_outcome(failures, flush_result)
  end

  defp run_refresh(session_pid, store, names, _source, _session_id, runtime_cfg) do
    Enum.each(names, fn collection_name ->
      _ = fetch_collection(session_pid, store, collection_name, runtime_cfg)
    end)
  end

  @spec refresh_collection(
          pid(),
          term(),
          term(),
          String.t(),
          pos_integer(),
          non_neg_integer(),
          {non_neg_integer(), [map()]},
          map()
        ) :: {non_neg_integer(), [map()]}
  defp refresh_collection(
         session_pid,
         store,
         session_id,
         collection_name,
         index,
         total_count,
         {successes, failures},
         runtime_cfg
       ) do
    started_at = System.monotonic_time(:millisecond)

    broadcast_progress(session_id, session_pid, %{
      collection_name: collection_name,
      index: index,
      total_count: total_count,
      status: :started
    })

    case fetch_collection(session_pid, store, collection_name, runtime_cfg) do
      :ok ->
        duration_ms = elapsed_ms(started_at)

        Logger.info(
          "[APP_STATE] Initial sync collection completed collection=#{collection_name} progress=#{index}/#{total_count} duration_ms=#{duration_ms}"
        )

        broadcast_progress(session_id, session_pid, %{
          collection_name: collection_name,
          index: index,
          total_count: total_count,
          status: :completed,
          duration_ms: duration_ms
        })

        {successes + 1, failures}

      {:error, reason} ->
        duration_ms = elapsed_ms(started_at)

        broadcast_progress(session_id, session_pid, %{
          collection_name: collection_name,
          index: index,
          total_count: total_count,
          status: :failed,
          duration_ms: duration_ms,
          reason: reason
        })

        {successes, [%{collection: collection_name, reason: reason} | failures]}
    end
  end

  @spec broadcast_outcome(term(), pid(), [String.t()], non_neg_integer(), [map()], term()) ::
          :ok
  defp broadcast_outcome(session_id, session_pid, names, success_count, [], :ok) do
    Subscribers.broadcast_lifecycle(
      session_id,
      {:ex_wapp_session, :initial_sync, :completed,
       event_payload(session_id, session_pid, %{
         collection_names: names,
         success_count: success_count,
         skipped: false
       })}
    )
  end

  defp broadcast_outcome(session_id, session_pid, names, success_count, failures, :ok) do
    reason = {:collection_fetch_failed, failures}

    Subscribers.broadcast_lifecycle(
      session_id,
      {:ex_wapp_session, :initial_sync, :failed, reason,
       event_payload(session_id, session_pid, %{
         collection_names: names,
         success_count: success_count,
         failures: failures
       })}
    )
  end

  defp broadcast_outcome(
         session_id,
         session_pid,
         names,
         success_count,
         failures,
         {:error, flush_reason}
       ) do
    reason = {:final_store_flush_failed, flush_reason}

    Subscribers.broadcast_lifecycle(
      session_id,
      {:ex_wapp_session, :initial_sync, :failed, reason,
       event_payload(session_id, session_pid, %{
         collection_names: names,
         success_count: success_count,
         failures: failures,
         flush_reason: flush_reason
       })}
    )
  end

  @spec sync_outcome([map()], term()) :: :completed | :failed
  defp sync_outcome([], :ok), do: :completed
  defp sync_outcome(_failures, _flush_result), do: :failed

  @spec begin_store_batch(term(), atom()) :: :ok | {:error, term()}
  defp begin_store_batch(%_{} = store, reason) when is_atom(reason),
    do: Store.begin_batch(store, reason)

  defp begin_store_batch(_store, _reason), do: :ok

  @spec finish_store_batch(term(), atom()) :: :ok | {:error, term()}
  defp finish_store_batch(%_{} = store, reason) when is_atom(reason),
    do: Store.finish_batch(store, reason)

  defp finish_store_batch(_store, _reason), do: :ok

  @spec fetch_collection(pid(), term(), String.t(), map()) :: :ok | {:error, term()}
  defp fetch_collection(session_pid, store, collection_name, runtime_cfg) do
    case Engine.fetch_collection(
           session_pid,
           store,
           collection_name,
           Call.retention_options(runtime_cfg)
         ) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("[APP_STATE] Failed to fetch #{collection_name}: #{Log.reason(reason)}")
        {:error, reason}
    end
  rescue
    error ->
      Logger.warning("[APP_STATE] Failed to fetch #{collection_name}: #{Log.reason(error)}")

      {:error, {:exception, error}}
  catch
    kind, reason ->
      Logger.warning(
        "[APP_STATE] Failed to fetch #{collection_name}: #{Log.reason({kind, reason})}"
      )

      {:error, {kind, reason}}
  end

  @spec broadcast_progress(term(), pid(), map()) :: :ok
  defp broadcast_progress(session_id, session_pid, payload) do
    Subscribers.broadcast_lifecycle(
      session_id,
      {:ex_wapp_session, :initial_sync, :progress,
       event_payload(session_id, session_pid, payload)}
    )
  end

  @spec event_payload(term(), pid(), map()) :: map()
  defp event_payload(session_id, session_pid, payload) do
    payload
    |> Map.new()
    |> Map.merge(%{runtime_ref: session_pid, session_id: session_id})
  end

  @spec elapsed_ms(integer()) :: non_neg_integer()
  defp elapsed_ms(started_at),
    do: max(System.monotonic_time(:millisecond) - started_at, 0)
end
