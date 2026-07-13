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
    outgoing_payloads = Keyword.get(opts, :outgoing_payloads, %{})
    retry_meta = Keyword.get(opts, :retry_meta, %{})

    normalized_jid = normalize_jid.(jid)

    do_retry(
      state,
      normalized_jid,
      message_id,
      max_attempts,
      start_worker,
      send_fun,
      outgoing_payloads,
      retry_meta
    )
  end

  defp do_retry(
         state,
         jid,
         message_id,
         max_attempts,
         start_worker,
         send_fun,
         outgoing_payloads,
         retry_meta
       ) do
    case find_outgoing_message(state.store, jid, message_id, outgoing_payloads) do
      {:ok, retry_jid, text} ->
        counter_key = outbound_retry_counter_key(retry_jid, message_id)
        attempts = Map.get(state.retry_counters, counter_key, 0)

        if attempts >= max_attempts do
          Logger.warning(
            "[SEND] Skipping retry for message id=#{message_id} to=#{retry_jid}: max attempts reached (requested_by=#{jid})"
          )

          state
        else
          Logger.warning(
            "[SEND] Retrying outbound message id=#{message_id} to=#{retry_jid} (requested_by=#{jid}, recipient=#{inspect(Map.get(retry_meta, :recipient))}, attempt #{attempts + 1}/#{max_attempts})"
          )

          spawn_retry_worker(state, retry_jid, message_id, attempts, text, start_worker, send_fun)
        end

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

  defp find_outgoing_message(store, jid, message_id, outgoing_payloads) do
    case find_outgoing_message_in_cache(outgoing_payloads, jid, message_id) do
      {:ok, _retry_jid, _text} = ok ->
        ok

      :error ->
        find_outgoing_message_in_store(store, jid, message_id)
    end
  end

  defp find_outgoing_message_in_store(nil, _jid, _message_id), do: {:error, :missing_store}

  defp find_outgoing_message_in_store(store, jid, message_id) do
    case find_outgoing_message_in_chat(store, jid, message_id) do
      {:ok, _retry_jid, _text} = ok ->
        ok

      {:error, _} ->
        find_outgoing_message_any_chat(store, message_id)
    end
  rescue
    error ->
      {:error, {:lookup_failed, error}}
  end

  defp find_outgoing_message_in_cache(outgoing_payloads, jid, message_id)
       when is_map(outgoing_payloads) and is_binary(message_id) do
    case Map.get(outgoing_payloads, message_id) do
      %{text: text} = payload when is_binary(text) and text != "" ->
        cached_jid = Map.get(payload, :jid, "")

        retry_jid =
          case cached_jid do
            value when is_binary(value) and value != "" -> value
            _ -> jid
          end

        {:ok, retry_jid, text}

      _payload ->
        :error
    end
  end

  defp find_outgoing_message_in_cache(_outgoing_payloads, _jid, _message_id), do: :error

  defp find_outgoing_message_in_chat(store, jid, message_id) do
    store
    |> Chat.messages(jid, limit: 500)
    |> find_outgoing_text_by_id(jid, message_id)
  end

  defp find_outgoing_message_any_chat(store, message_id) do
    case Chat.find_message_by_id(store, message_id) do
      {jid, message} -> find_outgoing_text_by_id([message], jid, message_id)
      nil -> {:error, :message_not_found}
    end
  end

  defp find_outgoing_text_by_id(messages, jid, message_id) do
    messages
    |> Enum.find_value(fn message ->
      if Map.get(message, :id) == message_id and Map.get(message, :from_me) and
           is_binary(Map.get(message, :text)) do
        {:ok, jid, Map.get(message, :text)}
      else
        nil
      end
    end)
    |> case do
      nil -> {:error, :message_not_found}
      {:ok, _retry_jid, _text} = result -> result
    end
  end
end
