defmodule ExWapp.Message.Handler.Inbound.Receipts do
  @moduledoc """
  Builds delivery, retry, placeholder-resend, and Signal-session actions.

  This module is a pure action planner apart from diagnostic logging. Transport
  effects remain in the session worker that executes the returned actions.
  """

  require Logger

  alias ExWapp.Message.Handler.Common
  alias ExWapp.Message.Handler.Inbound.Envelope
  alias ExWapp.Signal.SessionStore

  @max_retry_receipt_count 2
  @duplicate_decrypt_reasons [:message_key_not_found, :prekey_not_found, :key_unavailable]

  @doc """
  Plans receipt-related actions for one normalized inbound message.
  """
  @spec build_actions(term(), term(), term(), map(), map(), map()) :: {[term()], map()}
  def build_actions(from, id, participant, attrs, message_data, state) do
    cond do
      invalid_receipt_target?(from, id) ->
        {[], state}

      duplicate_decrypt_error?(Map.get(message_data, :decrypt_status)) ->
        build_duplicate_delivery_receipt_actions(
          from,
          id,
          participant,
          attrs,
          message_data,
          state
        )

      needs_retry_receipt?(message_data) ->
        build_retry_receipt_actions(from, id, participant, attrs, message_data, state)

      true ->
        build_delivery_receipt_actions(from, id, participant, attrs, message_data, state)
    end
  end

  @spec invalid_receipt_target?(term(), term()) :: boolean()
  defp invalid_receipt_target?(from, id), do: from == "" or id in [nil, ""]

  @spec build_retry_receipt_actions(term(), term(), term(), map(), map(), map()) ::
          {[term()], map()}
  defp build_retry_receipt_actions(from, id, participant, attrs, message_data, state) do
    retry_reason_code = retry_reason_code(Map.get(message_data, :decrypt_status))
    {retry_count, updated_state} = next_retry_count(state, from, id, participant, message_data)

    actions =
      if retry_count > @max_retry_receipt_count do
        Logger.warning(
          "[DECRYPT] Not sending more retry receipts for #{id}: count=#{retry_count}"
        )

        signal_sessions_update_actions(message_data)
      else
        retry_meta = %{
          category: Map.get(attrs, "category"),
          recipient: Map.get(attrs, "recipient")
        }

        [
          {:send_retry_receipt, from, id, participant, Map.get(attrs, "t"), retry_count,
           retry_reason_code, retry_meta}
        ] ++
          placeholder_resend_actions(from, id, participant, retry_count, message_data) ++
          signal_sessions_update_actions(message_data)
      end

    {actions, updated_state}
  end

  @spec build_duplicate_delivery_receipt_actions(term(), term(), term(), map(), map(), map()) ::
          {[term()], map()}
  defp build_duplicate_delivery_receipt_actions(
         from,
         id,
         participant,
         attrs,
         message_data,
         state
       ) do
    Logger.debug(
      "[DECRYPT] Treating #{ExWapp.Log.reference(id)} as an already-decrypted Signal duplicate"
    )

    receipt_type = delivery_receipt_type(from, attrs, state)
    receipt_meta = %{recipient: Map.get(attrs, "recipient")}

    actions =
      [{:send_receipt, from, id, participant, receipt_type, receipt_meta}] ++
        signal_sessions_update_actions(message_data)

    {actions, state}
  end

  @spec build_delivery_receipt_actions(term(), term(), term(), map(), map(), map()) ::
          {[term()], map()}
  defp build_delivery_receipt_actions(from, id, participant, attrs, message_data, state) do
    receipt_type = delivery_receipt_type(from, attrs, state)
    receipt_meta = %{recipient: Map.get(attrs, "recipient")}

    actions =
      [{:send_receipt, from, id, participant, receipt_type, receipt_meta}] ++
        placeholder_resend_actions(from, id, participant, 1, message_data) ++
        signal_sessions_update_actions(message_data)

    {actions, state}
  end

  @spec placeholder_resend_actions(term(), term(), term(), pos_integer(), map()) :: [term()]
  defp placeholder_resend_actions(from, id, participant, retry_count, message_data) do
    if needs_placeholder_resend_request?(message_data) and retry_count == 1 do
      sender = if is_binary(participant) and participant != "", do: participant, else: from
      [{:request_placeholder_resend, Common.strip_device_from_jid(from), sender, id}]
    else
      []
    end
  end

  @spec delivery_receipt_type(term(), map(), map()) :: binary() | nil
  defp delivery_receipt_type(from, attrs, state) do
    if Common.normalize_jid(from) in Envelope.local_recipient_jids(state, attrs) do
      if Map.get(attrs, "type") == "peer_msg", do: "peer_msg", else: "sender"
    else
      nil
    end
  end

  @spec retry_reason_code(term()) :: non_neg_integer()
  defp retry_reason_code(
         {:error,
          {:decrypt_failed_for_payload, _, {:decrypt_failed_for_candidate, _, :invalid_mac}}}
       ),
       do: 7

  defp retry_reason_code(
         {:error,
          {:decrypt_failed_for_payload, _,
           {:decrypt_failed_for_candidate, _, :unknown_signed_prekey}}}
       ),
       do: 3

  defp retry_reason_code(
         {:error,
          {:decrypt_failed_for_payload, _, {:decrypt_failed_for_candidate, _, :no_session}}}
       ),
       do: 1

  defp retry_reason_code(_), do: 0

  @doc false
  @spec duplicate_decrypt_error?(term()) :: boolean()
  def duplicate_decrypt_error?(reason) when reason in @duplicate_decrypt_reasons, do: true

  def duplicate_decrypt_error?({:error, reason}),
    do: duplicate_decrypt_error?(reason)

  def duplicate_decrypt_error?({:decrypt_failed_for_payload, _enc_type, reason}),
    do: duplicate_decrypt_error?(reason)

  def duplicate_decrypt_error?({:decrypt_failed_for_candidate, _candidate, reason}),
    do: duplicate_decrypt_error?(reason)

  def duplicate_decrypt_error?(_reason), do: false

  @spec needs_retry_receipt?(map()) :: boolean()
  defp needs_retry_receipt?(%{decrypt_status: {:error, _}}), do: true
  defp needs_retry_receipt?(_), do: false

  @spec needs_placeholder_resend_request?(map()) :: boolean()
  defp needs_placeholder_resend_request?(%{placeholder_unavailable: true}), do: true

  defp needs_placeholder_resend_request?(%{decrypt_status: {:error, reason}, encrypted: true}) do
    reason in [:no_ciphertext_candidates, :no_payload_candidates] or
      match?({:decrypt_failed_for_payload, _, _}, reason)
  end

  defp needs_placeholder_resend_request?(_), do: false

  @spec signal_sessions_update_actions(map()) :: [term()]
  defp signal_sessions_update_actions(%{signal_sessions_update: sessions}) do
    if SessionStore.store?(sessions), do: [{:signal_sessions_updated, sessions}], else: []
  end

  defp signal_sessions_update_actions(_message_data), do: []

  @spec next_retry_count(map(), term(), term(), term(), map()) ::
          {pos_integer(), map()}
  defp next_retry_count(state, from, id, participant, message_data) when is_map(state) do
    key = retry_counter_key(from, id, participant)
    counters = Map.get(state, :retry_counters, %{})
    local_next = Map.get(counters, key, 0) + 1
    incoming_next = incoming_retry_count(message_data) + 1
    next = if local_next == 1 and incoming_next > 1, do: incoming_next, else: local_next
    {next, Map.put(state, :retry_counters, Map.put(counters, key, next))}
  end

  defp next_retry_count(state, _from, _id, _participant, _message_data), do: {1, state}

  @spec incoming_retry_count(map()) :: non_neg_integer()
  defp incoming_retry_count(%{enc_candidates: candidates})
       when is_list(candidates) and candidates != [] do
    candidates
    |> Enum.map(&Map.get(&1, :enc_count))
    |> Enum.filter(&is_integer/1)
    |> case do
      [] -> 0
      counts -> Enum.max(counts)
    end
  end

  defp incoming_retry_count(%{enc_count: count}) when is_integer(count), do: count
  defp incoming_retry_count(_), do: 0

  @spec retry_counter_key(term(), term(), term()) :: binary()
  defp retry_counter_key(from, id, participant) do
    [
      Common.normalize_jid_with_device(from),
      to_string(id || ""),
      Common.normalize_jid_with_device(participant)
    ]
    |> Enum.join("|")
  end
end
