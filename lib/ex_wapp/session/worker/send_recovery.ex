defmodule ExWapp.Session.Worker.SendRecovery do
  @moduledoc """
  What the session does when a send does not land.

  Three recoveries live here, in the order the server pushes the session through
  them:

  - **resend** — the payload of every outgoing message is remembered briefly so
    it can be sent again without asking the caller to rebuild it
  - **repair** — a rejected send usually means the peer's Signal session is
    stale, so it is dropped and renegotiated before the resend goes out
  - **placeholder** — when a message arrives that this device cannot decrypt at
    all, the primary device is asked to send it again

  Retries run in worker processes started from here; like everything else called
  by the session, this code runs inside the session process, so those workers are
  started by it and report back to its mailbox.

  A rejection is only reported to the caller once no recovery is left: reporting
  early would surface an error for a message that is about to be resent
  successfully.
  """

  require Logger

  # Keeping every payload would grow the session unboundedly; 512 covers the
  # window where a resend is still meaningful.
  @max_outgoing_retry_payloads 512

  alias ExWapp.Config
  alias ExWapp.Log
  alias ExWapp.Messages
  alias ExWapp.Session.JIDUtils
  alias ExWapp.Session.SendCoordinator
  alias ExWapp.Session.Worker
  alias ExWapp.Session.Worker.Outbound
  alias ExWapp.Session.Worker.Retry
  alias ExWapp.Session.Worker.SendHealth
  alias ExWapp.Session.Worker.SignalSessions
  alias ExWapp.Session.Worker.Subscribers

  def maybe_retry_outgoing_message(state, jid, message_id, retry_meta) do
    max_attempts = Config.get(state.runtime_cfg, [:send, :max_outgoing_retry_attempts], 2)

    {_started?, new_state} =
      retry_outgoing_message(state, jid, message_id, retry_meta, max_attempts)

    new_state
  end

  # Returns whether a retry worker was actually started alongside the new state,
  # because a caller repairing a rejected send has to know: nothing was resent
  # means the rejection it withheld is the final verdict and has to be reported.
  @spec retry_outgoing_message(
          map(),
          String.t(),
          String.t(),
          map(),
          non_neg_integer(),
          keyword()
        ) ::
          {boolean(), map()}

  # Returns whether a retry worker was actually started alongside the new state,
  # because a caller repairing a rejected send has to know: nothing was resent
  # means the rejection it withheld is the final verdict and has to be reported.
  @spec retry_outgoing_message(
          Worker.t(),
          String.t(),
          String.t(),
          map(),
          non_neg_integer(),
          keyword()
        ) :: {boolean(), Worker.t()}
  defp retry_outgoing_message(state, jid, message_id, retry_meta, max_attempts, opts \\ []) do
    session_pid = self()
    retries_before = total_retry_attempts(state)

    new_state =
      Retry.maybe_retry_outgoing_message(state, jid, message_id,
        max_attempts: max_attempts,
        counter_scope: Keyword.get(opts, :counter_scope, "outbound_retry"),
        normalize_jid: &JIDUtils.normalize_for_signal/1,
        start_worker: &start_send_worker/3,
        register_worker: &register_send_worker/4,
        outgoing_payloads: Map.get(state, :outgoing_retry_payloads, %{}),
        retry_meta: retry_meta,
        send_fun: fn normalized_jid, text ->
          retry_state = SignalSessions.clear_for_jid(state, normalized_jid)

          retry_opts =
            [
              retry_message_id: message_id,
              suppress_outgoing_chat_add: true
            ]
            |> maybe_put_retry_own_device_destination(retry_meta)

          do_send_text_worker(session_pid, retry_state, normalized_jid, text, retry_opts)
        end
      )

    retries_after = total_retry_attempts(new_state)
    delta = max(retries_after - retries_before, 0)

    if delta > 0 do
      state_with_retries =
        update_in(new_state.send_health.retries_total, fn value -> (value || 0) + delta end)

      SendHealth.broadcast_event(state_with_retries, :retry, %{
        jid: jid,
        message_id: message_id,
        retries_started: delta
      })

      {true, state_with_retries}
    else
      {false, new_state}
    end
  end

  # The server refused the message because the Signal session it was encrypted
  # under no longer matches the one the peer is using. Resending the same bytes
  # reproduces the rejection exactly, so the retained payload is re-encrypted
  # after the peer's sessions are dropped, which forces a fresh prekey fetch on
  # the way back out. `Retry` reuses the original message ID, so the peer still
  # deduplicates it and a caller awaiting delivery keeps correlating on the ID it
  # was handed.
  #
  # `Receipt` withholds the delivery event for exactly this case, so a repair
  # that never starts has to report the failure here or the caller waits for an
  # ack that is not coming.
  @spec repair_session_and_retry(map(), String.t(), String.t(), ExWapp.Error.Ack.t()) :: map()

  # The server refused the message because the Signal session it was encrypted
  # under no longer matches the one the peer is using. Resending the same bytes
  # reproduces the rejection exactly, so the retained payload is re-encrypted
  # after the peer's sessions are dropped, which forces a fresh prekey fetch on
  # the way back out. `Retry` reuses the original message ID, so the peer still
  # deduplicates it and a caller awaiting delivery keeps correlating on the ID it
  # was handed.
  #
  # `Receipt` withholds the delivery event for exactly this case, so a repair
  # that never starts has to report the failure here or the caller waits for an
  # ack that is not coming.
  @spec repair_session_and_retry(Worker.t(), String.t(), String.t(), ExWapp.Error.Ack.t()) ::
          Worker.t()
  def repair_session_and_retry(state, message_id, jid, ack) do
    attempts = session_repair_attempts(state, message_id)
    max_attempts = Config.get(state.runtime_cfg, [:send, :max_session_repair_attempts], 2)
    delay_ms = session_repair_delay_ms(state, attempts)

    cond do
      attempts >= max_attempts ->
        report_session_rejection(state, message_id, jid, ack, "repair budget spent")

      delay_ms > 0 ->
        # A repair that renegotiated from a freshly fetched bundle and was
        # refused again is not evidence that the payload is unsendable: the same
        # payload, to the same peer, over another fresh session, has gone through
        # seconds later. Something on the far side is still catching up, and the
        # only lever this client has is to stop racing it.
        Logger.warning(
          "[SEND] Session rejected again id=#{Log.reference(message_id)} " <>
            "to=#{Log.reference(jid)} code=#{ack.code}; repair #{attempts + 1}/#{max_attempts} " <>
            "in #{delay_ms}ms"
        )

        Process.send_after(self(), {:session_repair_due, message_id, jid, ack}, delay_ms)
        state

      true ->
        run_session_repair(state, message_id, jid, ack, attempts, max_attempts)
    end
  end

  @spec run_session_repair(
          map(),
          String.t(),
          String.t(),
          ExWapp.Error.Ack.t(),
          non_neg_integer(),
          non_neg_integer()
        ) :: map()

  def run_session_repair(state, message_id, jid, ack, attempts, max_attempts) do
    Logger.warning(
      "[SEND] Session rejected id=#{Log.reference(message_id)} to=#{Log.reference(jid)} " <>
        "code=#{ack.code}; dropping peer sessions and resending " <>
        "(repair #{attempts + 1}/#{max_attempts})"
    )

    # No `:recipient` hint: an ack can come back addressed in the peer's other
    # family, and pinning the own-device destination to it would put a PN inside
    # a LID send. The resend derives that destination from the JID it actually
    # sends to, which `Retry` takes from the retained payload.
    case retry_outgoing_message(state, jid, message_id, %{}, max_attempts,
           counter_scope: "session_repair"
         ) do
      {true, new_state} ->
        new_state

      {false, new_state} ->
        report_session_rejection(new_state, message_id, jid, ack, "repair unavailable")
    end
  end

  defp report_session_rejection(state, message_id, jid, ack, reason) do
    Logger.warning(
      "[SEND] Session repair gave up for id=#{Log.reference(message_id)} " <>
        "to=#{Log.reference(jid)} (#{reason}); reporting rejection to caller"
    )

    Subscribers.broadcast_delivery(state.session_id, message_id, :failed, %{
      jid: jid,
      error: ack
    })

    state
  end

  # `Retry` owns the repair counter and keys it by the JID it resends to, which
  # is taken from the retained payload and need not be the JID the rejection
  # arrived on — an ack can come back in the peer's other addressing family. The
  # message ID is what both sides agree on, so the count is read back through it.
  @spec session_repair_attempts(map(), String.t()) :: non_neg_integer()

  # `Retry` owns the repair counter and keys it by the JID it resends to, which
  # is taken from the retained payload and need not be the JID the rejection
  # arrived on — an ack can come back in the peer's other addressing family. The
  # message ID is what both sides agree on, so the count is read back through it.
  @spec session_repair_attempts(Worker.t(), String.t()) :: non_neg_integer()
  def session_repair_attempts(state, message_id) do
    suffix = "|" <> message_id

    state
    |> Map.get(:retry_counters, %{})
    |> Enum.filter(fn {key, _count} ->
      String.starts_with?(key, "session_repair|") and String.ends_with?(key, suffix)
    end)
    |> Enum.map(&elem(&1, 1))
    |> Enum.max(fn -> 0 end)
  end

  @spec session_repair_delay_ms(map(), non_neg_integer()) :: non_neg_integer()

  defp session_repair_delay_ms(state, attempts) do
    case Config.get(state.runtime_cfg, [:send, :session_repair_backoff_ms], [0, 3_000]) do
      [] -> 0
      schedule -> Enum.at(schedule, attempts, List.last(schedule))
    end
  end

  def maybe_start_placeholder_resend_request(
        state,
        chat_jid,
        sender_jid,
        message_id,
        metadata
      ) do
    if placeholder_resend_ready?(state, chat_jid, sender_jid, message_id) do
      start_placeholder_resend_request(state, chat_jid, sender_jid, message_id, metadata)
    else
      Logger.warning(
        "[PLACEHOLDER] Cannot request unavailable message id=#{Log.reference(message_id)}: " <>
          placeholder_block_reason(state, chat_jid, sender_jid, message_id)
      )

      state
    end
  end

  defp placeholder_block_reason(state, chat_jid, sender_jid, message_id) do
    cond do
      not is_map(state) -> "session state unavailable"
      not resend_status_ready?(state) -> "status=#{inspect(Map.get(state, :status))}"
      not is_pid(Map.get(state, :conn)) -> "transport is not connected"
      not valid_resend_ref?(chat_jid) -> "chat reference is #{resend_ref_kind(chat_jid)}"
      not valid_resend_ref?(sender_jid) -> "sender reference is #{resend_ref_kind(sender_jid)}"
      not valid_resend_ref?(message_id) -> "message id is #{resend_ref_kind(message_id)}"
      true -> "unknown precondition"
    end
  end

  defp resend_status_ready?(state), do: Map.get(state, :status) in [:connected, :syncing]

  defp resend_ref_kind(nil), do: "nil"

  defp resend_ref_kind(value) when is_binary(value), do: "empty"

  defp resend_ref_kind(%module{}), do: "a #{inspect(module)} struct instead of a string"

  defp resend_ref_kind(_value), do: "not a string"

  defp start_placeholder_resend_request(state, chat_jid, sender_jid, message_id, metadata) do
    session_pid = self()

    proto =
      Messages.build_placeholder_resend_proto(chat_jid, sender_jid, message_id,
        from_me: is_map(metadata) and Map.get(metadata, :from_me) == true
      )

    task = fn ->
      peer_state = Map.put(state, :outbound_iq_router, session_pid)
      Outbound.send_peer_proto_worker(session_pid, peer_state, proto)
    end

    case start_send_worker(state, "placeholder_resend:#{message_id}", task) do
      {:ok, worker, mon} ->
        Logger.debug(
          "[PLACEHOLDER] Requesting unavailable message id=#{Log.reference(message_id)} chat=#{Log.reference(chat_jid)} from primary device"
        )

        register_send_worker(state, worker, mon, {:placeholder_resend, message_id})

      {:error, reason} ->
        Logger.warning(
          "[PLACEHOLDER] Failed to start resend request for id=#{Log.reference(message_id)}: #{Log.reason(reason)}"
        )

        state
    end
  end

  defp placeholder_resend_ready?(%{status: status, conn: conn}, chat_jid, sender_jid, message_id) do
    status in [:connected, :syncing] and is_pid(conn) and valid_resend_ref?(chat_jid) and
      valid_resend_ref?(sender_jid) and valid_resend_ref?(message_id)
  end

  defp placeholder_resend_ready?(_state, _chat_jid, _sender_jid, _message_id), do: false

  defp valid_resend_ref?(value), do: is_binary(value) and value != ""

  # Outbound message dispatch

  def do_send_text_worker(session_pid, state, jid, text, opts) do
    state = Map.put(state, :outbound_iq_router, session_pid)
    Outbound.send_text_worker(session_pid, state, jid, text, opts)
  end

  defp maybe_put_retry_own_device_destination(opts, %{recipient: recipient}) do
    recipient =
      recipient
      |> JIDUtils.normalize_with_device()
      |> JIDUtils.strip_device()

    if recipient == "" do
      opts
    else
      Keyword.put(opts, :own_device_destination_jid, recipient)
    end
  end

  defp maybe_put_retry_own_device_destination(opts, _retry_meta), do: opts

  def remember_outgoing_retry_payload(state, jid, text, message_id)
      when is_binary(jid) and is_binary(message_id) do
    normalized_text = normalize_outbound_text(text)

    if normalized_text == "" do
      state
    else
      payloads = Map.get(state, :outgoing_retry_payloads, %{})

      updated_payloads =
        payloads
        |> Map.put(message_id, %{
          jid: JIDUtils.normalize_for_signal(jid),
          text: normalized_text,
          inserted_at_ms: System.monotonic_time(:millisecond)
        })
        |> trim_outgoing_retry_payloads()

      %{state | outgoing_retry_payloads: updated_payloads}
    end
  end

  def remember_outgoing_retry_payload(state, _jid, _text, _message_id), do: state

  defp trim_outgoing_retry_payloads(payloads)
       when is_map(payloads) and map_size(payloads) > @max_outgoing_retry_payloads do
    payloads
    |> Enum.sort_by(fn {_message_id, payload} -> Map.get(payload, :inserted_at_ms, 0) end, :desc)
    |> Enum.take(@max_outgoing_retry_payloads)
    |> Map.new()
  end

  defp trim_outgoing_retry_payloads(payloads), do: payloads

  def register_send_worker(state, worker, mon, label, from \\ nil) do
    coordinator = SendCoordinator.register(state.send_coordinator, worker, mon, label, from)
    %{state | send_coordinator: coordinator}
  end

  # QR subscriber delivery

  def normalize_retry_participant(participant) do
    case JIDUtils.normalize_with_device(participant) do
      "" -> nil
      jid -> jid
    end
  end

  def start_send_worker(%Worker{send_worker_sup: sup}, label, fun)
      when is_pid(sup) and is_function(fun, 0) do
    session_pid = self()

    case Task.Supervisor.start_child(sup, fn ->
           run_send_worker_fun(session_pid, fun)
         end) do
      {:ok, worker} ->
        mon = Process.monitor(worker)
        {:ok, worker, mon}

      {:error, reason} ->
        Logger.warning("[SEND] Failed to start worker for #{label}: #{Log.reason(reason)}")
        {:error, reason}
    end
  end

  def start_send_worker(_state, label, _fun) do
    {:error, {:missing_send_worker_supervisor, label}}
  end

  defp run_send_worker_fun(session_pid, fun) when is_pid(session_pid) and is_function(fun, 0) do
    result = safe_run_send_worker(fun)
    send(session_pid, {:send_worker_finished, self(), result})
  end

  defp safe_run_send_worker(fun) do
    fun.()
  rescue
    exception ->
      {:error, {:send_worker_exception, exception.__struct__, Exception.message(exception)}}
  catch
    kind, reason -> {:error, {:send_worker_caught, kind, reason}}
  end

  def normalize_outbound_text(text) when is_binary(text), do: text

  def normalize_outbound_text(text) when is_list(text), do: IO.iodata_to_binary(text)

  def normalize_outbound_text(_), do: ""

  defp total_retry_attempts(state) do
    state.retry_counters
    |> Map.values()
    |> Enum.sum()
  end
end
