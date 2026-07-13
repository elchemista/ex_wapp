defmodule ExWapp.Message.Handler.Inbound do
  @moduledoc false

  require Logger

  alias ExWapp.{Chat, JID}
  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.{Common, Wire}
  alias ExWapp.Message.Handler.Inbound.{Content, Decryptor, Envelope, Projection, Sync}
  alias ExWapp.Session.DeviceCache
  alias ExWapp.Signal.SessionStore

  @max_retry_receipt_count 2

  @spec handle_message(Node.t(), pid(), map()) :: {:ok, map(), [term()]}
  def handle_message(%Node{attrs: attrs, content: content}, session, state) do
    from =
      case Map.get(attrs, "from", "") do
        %JID{} = jid -> jid
        jid when is_binary(jid) -> jid
        _ -> ""
      end

    id = Map.get(attrs, "id", "")
    type = Map.get(attrs, "type", "text")
    timestamp = Common.parse_timestamp(Map.get(attrs, "t"))
    participant = Map.get(attrs, "participant")

    Logger.debug("Received message from=#{from} id=#{id} type=#{type}")
    state = Envelope.persist_lid_mappings(state, attrs, from, participant)
    Envelope.persist_observed_devices(state, attrs, from, participant)

    message_data = Wire.extract_message_content(content, type)
    {message_data, state} = maybe_decrypt_message(message_data, state, from, participant, attrs)
    state = Sync.ingest(message_data, session, state, from, id)
    from_me = Envelope.from_me?(attrs, from, state, message_data)

    message = %{
      id: id,
      from_me: from_me,
      timestamp: timestamp,
      text: message_data[:text],
      status: if(from_me, do: :sent, else: :received),
      participant: participant,
      media: message_data[:media],
      location: message_data[:location],
      contact: message_data[:contact],
      event: message_data[:event],
      raw: %{
        type: type,
        attrs: attrs,
        media: message_data[:media],
        media_type: message_data[:media_type],
        content_type: message_data[:content_type],
        location: message_data[:location],
        contact: message_data[:contact],
        event: message_data[:event],
        from_me: from_me
      }
    }

    is_protocol = message_data[:message_content_type] == :protocol
    suppress_message? = transient_encrypted_placeholder?(message_data)

    if not is_protocol and not suppress_message? do
      if target = Common.chat_target(session, state) do
        Projection.update_chat_name(target, from, attrs)
        Chat.add_message(target, from, message)
      end

      if is_pid(session) do
        send(session, {:new_message, from, message})
      end
    else
      maybe_log_suppressed_message(is_protocol, suppress_message?, from, id, message_data)
    end

    {actions, state} = build_receipt_actions(from, id, participant, attrs, message_data, state)
    updated_state = Common.update_stats(state, :messages_received)
    {:ok, updated_state, actions}
  end

  @doc false
  @spec persist_notification_devices(map(), term()) :: :ok
  def persist_notification_devices(state, content) when is_map(state) and is_list(content) do
    store = Map.get(state, :store)

    content
    |> Enum.flat_map(fn
      %Node{attrs: attrs} when is_map(attrs) ->
        attrs
        |> Map.values()
        |> Enum.map(&Common.normalize_jid_with_device/1)
        |> Enum.filter(&String.contains?(&1, "@"))

      _ ->
        []
    end)
    |> Enum.uniq()
    |> Enum.each(&DeviceCache.persist_observed_device(store, &1))

    :ok
  end

  def persist_notification_devices(_state, _content), do: :ok

  @spec maybe_decrypt_message(map(), map(), term(), term(), map()) :: {map(), map()}
  defp maybe_decrypt_message(
         %{encrypted: true} = message_data,
         state,
         from,
         participant,
         attrs
       ) do
    case Decryptor.decrypt(message_data, state, from, participant, attrs) do
      {:ok, decrypt_result, updated_state} ->
        {Content.decode_decrypted(decrypt_result), updated_state}

      {:error, updated_message_data, updated_state} ->
        {updated_message_data, updated_state}
    end
  end

  defp maybe_decrypt_message(message_data, state, _from, _participant, _attrs),
    do: {message_data, state}

  defp transient_encrypted_placeholder?(%{encrypted: true, decrypt_status: {:error, _}}), do: true
  defp transient_encrypted_placeholder?(%{placeholder_unavailable: true}), do: true
  defp transient_encrypted_placeholder?(_message_data), do: false

  defp maybe_log_suppressed_message(true, _suppress_message?, _from, _id, _message_data), do: :ok

  defp maybe_log_suppressed_message(_is_protocol, true, from, id, message_data) do
    Logger.debug(
      "[DECRYPT] Suppressing undecryptable encrypted placeholder from=#{Common.normalize_jid_with_device(from)} id=#{id} reason=#{inspect(Map.get(message_data, :decrypt_status))}"
    )
  end

  defp maybe_log_suppressed_message(_is_protocol, _suppress_message?, _from, _id, _message_data),
    do: :ok

  defp build_receipt_actions(from, id, participant, attrs, message_data, state) do
    cond do
      invalid_receipt_target?(from, id) ->
        {[], state}

      needs_retry_receipt?(message_data) ->
        build_retry_receipt_actions(from, id, participant, attrs, message_data, state)

      true ->
        build_delivery_receipt_actions(from, id, participant, attrs, message_data, state)
    end
  end

  defp invalid_receipt_target?(from, id), do: from == "" or id in [nil, ""]

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

  defp build_delivery_receipt_actions(from, id, participant, attrs, message_data, state) do
    receipt_type = delivery_receipt_type(from, attrs, state)
    receipt_meta = %{recipient: Map.get(attrs, "recipient")}

    actions =
      [{:send_receipt, from, id, participant, receipt_type, receipt_meta}] ++
        placeholder_resend_actions(from, id, participant, 1, message_data) ++
        signal_sessions_update_actions(message_data)

    {actions, state}
  end

  defp placeholder_resend_actions(from, id, participant, retry_count, message_data) do
    if needs_placeholder_resend_request?(message_data) and retry_count == 1 do
      sender = if is_binary(participant) and participant != "", do: participant, else: from
      [{:request_placeholder_resend, Common.strip_device_from_jid(from), sender, id}]
    else
      []
    end
  end

  defp delivery_receipt_type(from, attrs, state) do
    if Common.normalize_jid(from) in local_recipient_jids(state, attrs) do
      if Map.get(attrs, "type") == "peer_msg", do: "peer_msg", else: "sender"
    else
      nil
    end
  end

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

  defp needs_retry_receipt?(%{decrypt_status: {:error, _}}), do: true
  defp needs_retry_receipt?(_), do: false
  defp needs_placeholder_resend_request?(%{placeholder_unavailable: true}), do: true

  defp needs_placeholder_resend_request?(%{decrypt_status: {:error, reason}, encrypted: true}) do
    reason in [:no_ciphertext_candidates, :no_payload_candidates] or
      match?({:decrypt_failed_for_payload, _, _}, reason)
  end

  defp needs_placeholder_resend_request?(_), do: false

  defp signal_sessions_update_actions(%{signal_sessions_update: sessions}) do
    if SessionStore.store?(sessions), do: [{:signal_sessions_updated, sessions}], else: []
  end

  defp signal_sessions_update_actions(_message_data), do: []

  defp next_retry_count(state, from, id, participant, message_data) when is_map(state) do
    key = retry_counter_key(from, id, participant)
    counters = Map.get(state, :retry_counters, %{})
    local_next = Map.get(counters, key, 0) + 1
    incoming_next = incoming_retry_count(message_data) + 1
    next = if local_next == 1 and incoming_next > 1, do: incoming_next, else: local_next
    {next, Map.put(state, :retry_counters, Map.put(counters, key, next))}
  end

  defp next_retry_count(state, _from, _id, _participant, _message_data), do: {1, state}

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

  defp retry_counter_key(from, id, participant) do
    [
      Common.normalize_jid_with_device(from),
      to_string(id || ""),
      Common.normalize_jid_with_device(participant)
    ]
    |> Enum.join("|")
  end
end
