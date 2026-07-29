defmodule ExWapp.Message.Handler.Inbound.Receipts do
  @moduledoc """
  Builds delivery, retry, placeholder-resend, and Signal-session actions.

  This module is a pure action planner apart from diagnostic logging. Transport
  effects remain in the session worker that executes the returned actions.
  """

  require Logger

  alias ExWapp.{JID, Store}
  alias ExWapp.Message.Handler.Common
  alias ExWapp.Message.Handler.Inbound.Envelope
  alias ExWapp.Signal.{SessionStore, WireFormat}

  @max_retry_receipt_count 2
  @duplicate_decrypt_reasons [:message_key_not_found]

  # Failures the peer cannot resend its way out of: whatever it holds for this
  # device — a one-time prekey that is gone, a signed prekey this device never
  # had, or no session at all — cannot produce ciphertext this device can open.
  # Only a new key bundle changes that.
  @key_material_decrypt_reasons [:prekey_not_found, :unknown_signed_prekey, :no_session]

  @doc """
  Plans receipt-related actions for one normalized inbound message.
  """
  @spec build_actions(term(), term(), term(), map(), map(), map()) :: {[term()], map()}
  def build_actions(from, id, participant, attrs, message_data, state) do
    cond do
      invalid_receipt_target?(from, id) ->
        {[], state}

      duplicate_decrypt_error?(Map.get(message_data, :decrypt_status)) and
          stored_message?(state, from, id) ->
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
          recipient: Map.get(attrs, "recipient"),
          force_keys?: key_material_error?(Map.get(message_data, :decrypt_status))
        }

        [
          {:send_retry_receipt, from, id, participant, Map.get(attrs, "t"), retry_count,
           retry_reason_code, retry_meta}
        ] ++
          placeholder_resend_actions(
            from,
            id,
            participant,
            retry_count,
            attrs,
            message_data,
            state
          ) ++
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
    duplicate_reason = Map.get(message_data, :decrypt_status)

    Logger.debug(
      "[DECRYPT] Suppressing encrypted redelivery for stored chat message " <>
        "id=#{ExWapp.Log.reference(id)} chat=#{ExWapp.Log.reference(from)} " <>
        "ratchet_replay_proof?=true " <>
        "reason=#{ExWapp.Log.reason(duplicate_reason)}"
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
        placeholder_resend_actions(from, id, participant, 1, attrs, message_data, state) ++
        signal_sessions_update_actions(message_data)

    {actions, state}
  end

  @spec placeholder_resend_actions(
          term(),
          term(),
          term(),
          pos_integer(),
          map(),
          map(),
          map()
        ) :: [term()]
  defp placeholder_resend_actions(
         from,
         id,
         participant,
         retry_count,
         attrs,
         message_data,
         state
       ) do
    if needs_placeholder_resend_request?(message_data) and retry_count == 1 do
      sender = placeholder_sender(from, participant)
      from_me = placeholder_from_me?(attrs, from, participant, state, message_data)
      chat_jid = placeholder_chat_jid(from, attrs, from_me)

      [
        {:request_placeholder_resend, chat_jid, sender, id, %{from_me: from_me}}
      ]
    else
      []
    end
  end

  @doc false
  @spec placeholder_sender(term(), term()) :: String.t()
  def placeholder_sender(from, participant) do
    # The binary decoder hands JID structs for JID-typed attributes, so both
    # references are normalized here. The resend request is dropped downstream
    # when the sender is not a non-empty binary.
    case Common.normalize_jid_with_device(participant) do
      "" -> Common.normalize_jid_with_device(from)
      sender -> sender
    end
  end

  @spec placeholder_from_me?(map(), term(), term(), map(), map()) :: boolean()
  defp placeholder_from_me?(attrs, from, participant, state, message_data) do
    Envelope.from_me?(attrs, from, state, message_data) or
      Envelope.own_sender?(attrs, from, participant, state)
  end

  @spec placeholder_chat_jid(term(), map(), boolean()) :: String.t()
  defp placeholder_chat_jid(from, attrs, true) do
    normalized_from = Common.normalize_jid(from)

    if JID.group?(normalized_from) or JID.broadcast?(normalized_from) do
      normalized_from
    else
      [
        Map.get(attrs, "recipient"),
        Map.get(attrs, "peer_recipient_pn"),
        Map.get(attrs, "peer_recipient_lid"),
        from
      ]
      |> Enum.map(&Common.normalize_jid/1)
      |> Enum.find("", &(&1 != ""))
    end
  end

  defp placeholder_chat_jid(from, _attrs, false), do: Common.normalize_jid(from)

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

  defp stored_message?(state, from, id)
       when is_map(state) and is_binary(id) and id != "" do
    chat_jid = Common.normalize_jid(from)

    case {Map.get(state, :store), chat_jid} do
      {nil, _chat_jid} -> false
      {_store, ""} -> false
      {store, chat_jid} -> not is_nil(Store.find_message(store, chat_jid, id))
    end
  rescue
    _error -> false
  catch
    _kind, _reason -> false
  end

  defp stored_message?(_state, _from, _id), do: false

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
    key = retry_counter_key(from, id, participant, message_data)
    counters = Map.get(state, :retry_counters, %{})
    local_next = Map.get(counters, key, 0) + 1
    incoming_next = incoming_retry_count(message_data) + 1
    next = if local_next == 1 and incoming_next > 1, do: incoming_next, else: local_next
    {next, ExWapp.Session.RetryCounters.put(state, key, next)}
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

  @spec retry_counter_key(term(), term(), term(), map()) :: binary()
  defp retry_counter_key(from, id, participant, message_data) do
    sender = Common.normalize_jid_with_device(from)
    participant = Common.normalize_jid_with_device(participant)

    case missing_prekey_fingerprint(message_data) do
      nil ->
        [sender, to_string(id || ""), participant]
        |> Enum.join("|")

      fingerprint ->
        ["missing_prekey", sender, participant, fingerprint]
        |> Enum.join("|")
    end
  end

  @spec missing_prekey_fingerprint(map()) :: binary() | nil
  defp missing_prekey_fingerprint(message_data) when is_map(message_data) do
    decrypt_status = Map.get(message_data, :decrypt_status)
    candidates = Map.get(message_data, :enc_candidates, [])

    if missing_prekey_error?(decrypt_status) and is_list(candidates) do
      Enum.find_value(candidates, &prekey_candidate_fingerprint/1)
    end
  end

  defp missing_prekey_fingerprint(_message_data), do: nil

  @spec prekey_candidate_fingerprint(term()) :: binary() | nil
  defp prekey_candidate_fingerprint(%{enc_type: "pkmsg", ciphertext: ciphertext})
       when is_binary(ciphertext) do
    case WireFormat.parse_prekey_signal_message(ciphertext) do
      {:ok, parsed} ->
        {
          Map.get(parsed, :registration_id),
          Map.get(parsed, :prekey_id),
          Map.get(parsed, :signed_prekey_id),
          Map.get(parsed, :base_key),
          Map.get(parsed, :identity_key)
        }
        |> :erlang.term_to_binary()
        |> then(&:crypto.hash(:sha256, &1))
        |> Base.encode16(case: :lower)

      {:error, _reason} ->
        nil
    end
  end

  defp prekey_candidate_fingerprint(_candidate), do: nil

  @spec missing_prekey_error?(term()) :: boolean()
  defp missing_prekey_error?(reason), do: root_decrypt_reason(reason) == :prekey_not_found

  @doc false
  @spec key_material_error?(term()) :: boolean()
  def key_material_error?(reason),
    do: root_decrypt_reason(reason) in @key_material_decrypt_reasons

  # Decrypt failures arrive wrapped once per layer that tried and gave up — the
  # payload, then the sender candidate within it — so the reason a receipt has to
  # act on is always at the bottom of that nesting.
  @spec root_decrypt_reason(term()) :: term()
  defp root_decrypt_reason({:error, reason}), do: root_decrypt_reason(reason)

  defp root_decrypt_reason({:decrypt_failed_for_payload, _payload, reason}),
    do: root_decrypt_reason(reason)

  defp root_decrypt_reason({:decrypt_failed_for_candidate, _candidate, reason}),
    do: root_decrypt_reason(reason)

  defp root_decrypt_reason(reason), do: reason
end
