defmodule ExWapp.Session.HistorySync do
  @moduledoc false

  require Logger

  alias ExWapp.{Log, Media, Store}
  alias ExWapp.Message.Handler.Inbound.Sync
  alias ExWapp.Proto.HistorySync, as: Proto
  alias ExWapp.Session.Worker
  alias ExWapp.Session.Worker.{Events, SendRecovery, Subscribers}

  @spec start(Worker.t(), Proto.blob_ref(), term(), term()) :: Worker.t()
  def start(state, blob, from, id) do
    session = self()
    metadata = Map.take(blob, [:sync_type, :chunk_order, :progress])
    projection_state = Map.take(state, [:store, :session_id, :runtime_cfg])

    task = fn -> download_and_apply(projection_state, session, blob, from, id) end

    case start_worker(state, task) do
      {:ok, worker, monitor} ->
        Logger.info(
          "[HISTORY_SYNC] Downloading blob sync_type=#{inspect(blob.sync_type)} chunk_order=#{inspect(blob.chunk_order)}"
        )

        SendRecovery.register_send_worker(state, worker, monitor, {:history_sync, metadata})

      {:error, reason} ->
        complete(state, metadata, {:error, reason})
        state
    end
  end

  @spec download_and_apply(map(), pid(), Proto.blob_ref(), term(), term()) ::
          {:ok, map()} | {:error, term()}
  defp download_and_apply(state, session, blob, from, id) do
    with {:ok, bytes} <- Media.HTTP.download(%{}, media_ref(blob), session: session),
         {:ok, history} <- Proto.parse_history_payload({:compressed, bytes}, blob.sync_type),
         :ok <-
           Store.batch(state.store, :history_sync, fn ->
             Sync.apply_history_sync(history, session, state, from, id)
             :ok
           end) do
      {:ok,
       %{
         conversations: length(history.conversations),
         messages: Enum.sum(Enum.map(history.conversations, &length(&1.messages)))
       }}
    end
  end

  defp start_worker(state, task) do
    SendRecovery.start_send_worker(state, "history_sync", task)
  catch
    :exit, reason -> {:error, {:task_supervisor_exit, reason}}
  end

  @spec complete(Worker.t(), map(), {:ok, map()} | {:error, term()}) :: :ok
  def complete(state, metadata, {:ok, counts}) do
    Logger.info(
      "[HISTORY_SYNC] Downloaded and applied blob sync_type=#{inspect(metadata.sync_type)} conversations=#{counts.conversations} messages=#{counts.messages}"
    )

    Subscribers.broadcast_lifecycle(
      state.session_id,
      {:ex_wapp_session, :history_sync, :completed,
       Events.lifecycle_event_meta(state, Map.merge(metadata, counts))}
    )
  end

  def complete(state, metadata, {:error, reason}) do
    Logger.warning(
      "[HISTORY_SYNC] Blob sync failed sync_type=#{inspect(metadata.sync_type)} reason=#{Log.reason(reason)}"
    )

    Subscribers.broadcast_lifecycle(
      state.session_id,
      {:ex_wapp_session, :history_sync, :failed, reason,
       Events.lifecycle_event_meta(state, metadata)}
    )
  end

  defp media_ref(blob) do
    %Media.Ref{
      type: :history,
      direct_path: blob.direct_path,
      media_key: blob.media_key,
      file_sha256: blob.file_sha256,
      file_enc_sha256: blob.file_enc_sha256,
      file_length: blob.file_length
    }
  end
end
