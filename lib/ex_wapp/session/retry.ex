defmodule ExWapp.Session.Retry do
  @moduledoc """
  Outbound retry and message lookup helpers for Session.
  """

  require Logger

  @type start_worker_fun :: (map(), binary(), (-> any()) ->
                               {:ok, pid(), reference()} | {:error, term()})
  @type send_fun :: (binary(), binary() -> {:ok, binary()} | {:error, term()})
  @type normalize_fun :: (binary() -> binary())

  def maybe_retry_outgoing_message(state, jid, message_id, opts) when is_map(state) do
    normalize_jid = Keyword.fetch!(opts, :normalize_jid)
    start_worker = Keyword.fetch!(opts, :start_worker)
    send_fun = Keyword.fetch!(opts, :send_fun)
    max_attempts = Keyword.fetch!(opts, :max_attempts)

    normalized_jid = normalize_jid.(jid)
    counter_key = outbound_retry_counter_key(normalized_jid, message_id)
    attempts = Map.get(state.retry_counters, counter_key, 0)

    cond do
      attempts >= max_attempts ->
        Logger.warning(
          "[SEND] Skipping retry for message id=#{message_id} to=#{normalized_jid}: max attempts reached"
        )

        state

      true ->
        case find_outgoing_message_text(state.store, normalized_jid, message_id) do
          {:ok, text} ->
            Logger.warning(
              "[SEND] Retrying outbound message id=#{message_id} to=#{normalized_jid} (attempt #{attempts + 1}/#{max_attempts})"
            )

            case start_worker.(state, normalized_jid, fn ->
                   result = send_fun.(normalized_jid, text)

                   case result do
                     {:ok, new_id} ->
                       Logger.info(
                         "[SEND] Retry for message id=#{message_id} succeeded with new id=#{new_id}"
                       )

                     {:error, reason} ->
                       Logger.warning(
                         "[SEND] Retry for message id=#{message_id} failed: #{inspect(reason)}"
                       )
                   end
                 end) do
              {:ok, worker, mon} ->
                retry_counters = Map.put(state.retry_counters, counter_key, attempts + 1)
                send_workers = Map.put(state.send_workers, worker, normalized_jid)
                send_worker_mons = Map.put(state.send_worker_mons, mon, worker)

                %{
                  state
                  | retry_counters: retry_counters,
                    send_workers: send_workers,
                    send_worker_mons: send_worker_mons
                }

              {:error, reason} ->
                Logger.warning(
                  "[SEND] Cannot retry message id=#{message_id} for #{normalized_jid}: #{inspect(reason)}"
                )

                state
            end

          {:error, reason} ->
            Logger.warning(
              "[SEND] Cannot retry message id=#{message_id} for #{normalized_jid}: #{inspect(reason)}"
            )

            state
        end
    end
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
    |> ExWapp.Chat.messages(jid, limit: 500)
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

  defp find_outgoing_message_text_any_chat(store, message_id) do
    store
    |> ExWapp.Chat.list()
    |> Enum.find_value(fn chat ->
      chat.messages
      |> Enum.find_value(fn message ->
        if Map.get(message, :id) == message_id and Map.get(message, :from_me) and
             is_binary(Map.get(message, :text)) do
          {:ok, Map.get(message, :text)}
        else
          nil
        end
      end)
    end)
    |> case do
      nil -> {:error, :message_not_found}
      {:ok, _text} = result -> result
    end
  end
end
