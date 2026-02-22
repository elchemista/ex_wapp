defmodule ExWapp.Session.Worker.OutboundConfirmation do
  @moduledoc """
  Tracks outbound message delivery confirmation and handles the
  silent-drop fallback strategy for self-chat messages.
  """

  require Logger

  alias ExWapp.Chat
  alias ExWapp.Session.{Account, JIDUtils}

  @default_max_silent_drop_fallback_attempts 1

  @doc """
  Schedules a confirmation timer for an outbound message when the
  destination is the user's own JID.

  Returns the updated state.
  """
  @spec schedule(map(), String.t(), String.t(), String.t(), term(), non_neg_integer(),
          timeout_ms: pos_integer()
        ) :: map()
  def schedule(state, jid, text, message_id, _strategy, attempt, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, 6_000)

    max_fallback_attempts =
      Keyword.get(
        opts,
        :max_silent_drop_fallback_attempts,
        @default_max_silent_drop_fallback_attempts
      )

    if watch_self_chat?(state.store, jid, attempt, max_fallback_attempts) do
      timer =
        Process.send_after(
          self(),
          {:outbound_confirm_timeout, message_id},
          timeout_ms
        )

      confirmation = %{
        jid: JIDUtils.normalize_for_signal(jid),
        text: IO.iodata_to_binary(text),
        attempt: attempt,
        timer: timer
      }

      confirmations = Map.put(state.outbound_confirmations, message_id, confirmation)
      %{state | outbound_confirmations: confirmations}
    else
      state
    end
  end

  @doc """
  Handles the confirmation timeout: checks message status and optionally
  retries via fallback.

  `start_worker_fn` receives `(state, jid, fun)` and must return
  `{:ok, worker, mon} | {:error, reason}`.

  `send_fn` receives `(session_pid, state, jid, text, opts)` and performs the
  actual send.

  Returns the updated state.
  """
  @spec handle_timeout(
          map(),
          String.t(),
          map(),
          (map(), String.t(), (-> term()) -> {:ok, pid(), reference()} | {:error, term()}),
          (pid(), map(), String.t(), String.t(), keyword() -> term()),
          (map(), pid(), reference(), String.t() -> map()),
          keyword()
        ) :: map()
  def handle_timeout(state, message_id, confirmation, start_worker_fn, send_fn, register_fn) do
    handle_timeout(state, message_id, confirmation, start_worker_fn, send_fn, register_fn, [])
  end

  def handle_timeout(
        state,
        message_id,
        confirmation,
        start_worker_fn,
        send_fn,
        register_fn,
        opts
      ) do
    %{jid: jid, text: text, attempt: attempt} = confirmation

    max_fallback_attempts =
      Keyword.get(
        opts,
        :max_silent_drop_fallback_attempts,
        @default_max_silent_drop_fallback_attempts
      )

    on_drop = Keyword.get(opts, :on_drop, fn _jid, _message_id, _attempt -> :ok end)

    case outbound_message_status(state.store, jid, message_id) do
      status when status in [:delivered, :read, :received] ->
        Logger.debug("[SEND] Outbound confirmed id=#{message_id} status=#{status}")
        state

      :failed ->
        state

      _other ->
        if attempt < max_fallback_attempts do
          Logger.warning(
            "[SEND] Message id=#{message_id} to=#{jid} remained unconfirmed; retrying with fallback self-chat strategy"
          )

          mark_message_failed(state.store, message_id)

          start_silent_drop_fallback(
            state,
            jid,
            text,
            attempt + 1,
            message_id,
            start_worker_fn,
            send_fn,
            register_fn
          )
        else
          Logger.error(
            "[SEND] Message id=#{message_id} to=#{jid} still unconfirmed after fallback; marking as failed"
          )

          mark_message_failed(state.store, message_id)
          on_drop.(jid, message_id, attempt)
          state
        end
    end
  end

  # ============================================================================
  # Internal helpers
  # ============================================================================

  defp start_silent_drop_fallback(
         state,
         jid,
         text,
         attempt,
         previous_message_id,
         start_worker_fn,
         send_fn,
         register_fn
       ) do
    session_pid = self()

    case start_worker_fn.(state, jid, fn ->
           run_silent_drop_fallback_send(
             session_pid,
             state,
             jid,
             text,
             attempt,
             previous_message_id,
             send_fn
           )
         end) do
      {:ok, worker, mon} ->
        register_fn.(state, worker, mon, jid)

      {:error, reason} ->
        Logger.warning("[SEND] Failed to start fallback worker for #{jid}: #{inspect(reason)}")
        state
    end
  end

  defp run_silent_drop_fallback_send(
         session_pid,
         state,
         jid,
         text,
         attempt,
         previous_message_id,
         send_fn
       ) do
    result = send_fn.(session_pid, state, jid, text, self_chat_mode: :recipient_primary)
    send(session_pid, {:send_result, jid, text, result, :fallback, attempt})
    log_silent_drop_fallback_result(result, jid, previous_message_id)
    result
  end

  defp log_silent_drop_fallback_result({:ok, new_id}, jid, previous_message_id) do
    Logger.warning(
      "[SEND] Fallback resend for #{jid} previous_id=#{previous_message_id} new_id=#{new_id}"
    )
  end

  defp log_silent_drop_fallback_result({:error, reason}, jid, previous_message_id) do
    Logger.warning(
      "[SEND] Fallback resend failed for #{jid} previous_id=#{previous_message_id}: #{inspect(reason)}"
    )
  end

  defp watch_self_chat?(store, jid, attempt, max_fallback_attempts)
       when is_integer(attempt) and is_integer(max_fallback_attempts) and
              attempt <= max_fallback_attempts do
    own_base_jid = Account.local_account_base_jid(store)
    own_lid_jid = Account.local_account_lid_jid(store)

    own_user_parts =
      [own_base_jid, own_lid_jid]
      |> Enum.map(&jid_user_part/1)
      |> Enum.reject(&(&1 == ""))
      |> MapSet.new()

    dest_user = jid_user_part(jid)
    dest_user != "" and MapSet.member?(own_user_parts, dest_user)
  end

  defp watch_self_chat?(_store, _jid, _attempt, _max_fallback_attempts), do: false

  defp outbound_message_status(nil, _jid, _message_id), do: :unknown

  defp outbound_message_status(store, jid, message_id) do
    with nil <- find_outgoing_message_in_chat(store, jid, message_id),
         nil <- find_outgoing_message_in_chat(store, strip_device_from_jid(jid), message_id),
         nil <- find_outgoing_message_any_chat(store, message_id) do
      :unknown
    else
      %{status: status} when is_atom(status) -> status
      _ -> :unknown
    end
  end

  defp find_outgoing_message_in_chat(store, jid, message_id)
       when is_binary(jid) and jid != "" and is_binary(message_id) do
    store
    |> Chat.messages(jid, limit: 1000)
    |> Enum.find(fn message ->
      Map.get(message, :id) == message_id and Map.get(message, :from_me) == true
    end)
  end

  defp find_outgoing_message_in_chat(_store, _jid, _message_id), do: nil

  defp find_outgoing_message_any_chat(store, message_id) when is_binary(message_id) do
    store
    |> Chat.list()
    |> Enum.find_value(fn chat ->
      Enum.find(chat.messages, fn message ->
        Map.get(message, :id) == message_id and Map.get(message, :from_me) == true
      end)
    end)
  end

  defp find_outgoing_message_any_chat(_store, _message_id), do: nil

  defp mark_message_failed(nil, _message_id), do: :ok

  defp mark_message_failed(store, message_id) when is_binary(message_id) do
    Chat.update_message_status_by_id(store, message_id, :failed)
  end

  defp mark_message_failed(_store, _message_id), do: :ok

  defp jid_user_part(jid) when is_binary(jid) do
    jid
    |> JIDUtils.normalize_for_signal()
    |> String.split("@", parts: 2)
    |> case do
      [user, _server] -> Regex.replace(~r/:\d+$/, user, "")
      _ -> ""
    end
  end

  defp jid_user_part(_), do: ""

  defp strip_device_from_jid(jid) when is_binary(jid) do
    String.replace(jid, ~r/:(\d+)@/, "@")
  end

  defp strip_device_from_jid(_), do: ""
end
