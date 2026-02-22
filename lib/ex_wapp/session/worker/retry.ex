defmodule ExWapp.Session.Worker.Retry do
  @moduledoc """
  Outbound retry and message lookup helpers for Session.
  """

  require Logger

  alias ExWapp.Chat

  @type start_worker_fun :: (map(), binary(), (-> any()) ->
                               {:ok, pid(), reference()} | {:error, term()})
  @type send_fun :: (binary(), binary() -> {:ok, binary()} | {:error, term()})
  @type normalize_fun :: (binary() -> binary())

  @spec maybe_retry_outgoing_message(map(), String.t(), String.t(), keyword()) :: map()
  def maybe_retry_outgoing_message(state, jid, message_id, opts) when is_map(state) do
    normalize_jid = Keyword.fetch!(opts, :normalize_jid)
    start_worker = Keyword.fetch!(opts, :start_worker)
    send_fun = Keyword.fetch!(opts, :send_fun)
    max_attempts = Keyword.fetch!(opts, :max_attempts)

    normalized_jid = normalize_jid.(jid)
    counter_key = outbound_retry_counter_key(normalized_jid, message_id)
    attempts = Map.get(state.retry_counters, counter_key, 0)

    if attempts >= max_attempts do
      Logger.warning(
        "[SEND] Skipping retry for message id=#{message_id} to=#{normalized_jid}: max attempts reached"
      )

      state
    else
      do_retry(state, normalized_jid, message_id, attempts, max_attempts, start_worker, send_fun)
    end
  end

  defp do_retry(state, jid, message_id, attempts, max_attempts, start_worker, send_fun) do
    case find_outgoing_message_text(state.store, jid, message_id) do
      {:ok, text} ->
        Logger.warning(
          "[SEND] Retrying outbound message id=#{message_id} to=#{jid} (attempt #{attempts + 1}/#{max_attempts})"
        )

        spawn_retry_worker(state, jid, message_id, attempts, text, start_worker, send_fun)

      {:error, reason} ->
        Logger.warning(
          "[SEND] Cannot retry message id=#{message_id} for #{jid}: #{inspect(reason)}"
        )

        state
    end
  end

  defp spawn_retry_worker(state, jid, message_id, attempts, text, start_worker, send_fun) do
    case start_worker.(state, jid, fn ->
           log_retry_result(send_fun.(jid, text), message_id)
         end) do
      {:ok, worker, mon} ->
        counter_key = outbound_retry_counter_key(jid, message_id)

        %{
          state
          | retry_counters: Map.put(state.retry_counters, counter_key, attempts + 1),
            send_workers: Map.put(state.send_workers, worker, jid),
            send_worker_mons: Map.put(state.send_worker_mons, mon, worker)
        }

      {:error, reason} ->
        Logger.warning(
          "[SEND] Cannot retry message id=#{message_id} for #{jid}: #{inspect(reason)}"
        )

        state
    end
  end

  defp log_retry_result({:ok, new_id}, message_id) do
    Logger.debug("[SEND] Retry for message id=#{message_id} succeeded with new id=#{new_id}")
  end

  defp log_retry_result({:error, reason}, message_id) do
    Logger.warning("[SEND] Retry for message id=#{message_id} failed: #{inspect(reason)}")
  end

  defp outbound_retry_counter_key(jid, message_id) do
    "outbound_retry|#{jid}|#{message_id}"
  end

  defp find_outgoing_message_text(nil, _jid, _message_id), do: {:error, :missing_store}

  defp find_outgoing_message_text(store, jid, message_id) do
    case find_outgoing_message_text_in_chat(store, jid, message_id) do
      {:ok, _text} = ok ->
        ok

      {:error, _} ->
        find_outgoing_message_text_any_chat(store, message_id)
    end
  rescue
    error ->
      {:error, {:lookup_failed, error}}
  end

  defp find_outgoing_message_text_in_chat(store, jid, message_id) do
    store
    |> Chat.messages(jid, limit: 500)
    |> find_outgoing_text_by_id(message_id)
  end

  defp find_outgoing_message_text_any_chat(store, message_id) do
    store
    |> Chat.list()
    |> Enum.find_value(fn chat ->
      chat.messages
      |> find_outgoing_text_by_id(message_id)
      |> case do
        {:ok, _} = ok -> ok
        _ -> nil
      end
    end)
    |> case do
      nil -> {:error, :message_not_found}
      {:ok, _text} = result -> result
    end
  end

  defp find_outgoing_text_by_id(messages, message_id) do
    messages
    |> Enum.find_value(fn message ->
      if Map.get(message, :id) == message_id and Map.get(message, :from_me) and
           is_binary(Map.get(message, :text)) do
        {:ok, Map.get(message, :text)}
      else
        nil
      end
    end)
    |> case do
      nil -> {:error, :message_not_found}
      {:ok, _text} = result -> result
    end
  end
end
