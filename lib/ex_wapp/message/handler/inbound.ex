defmodule ExWapp.Message.Handler.Inbound do
  @moduledoc false

  require Logger

  alias ExWapp.{Chat, JID}
  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.{Common, Wire}
  alias ExWapp.Message.Handler.Inbound.{
    Content,
    Decryptor,
    Envelope,
    Projection,
    Receipts,
    Sync
  }

  alias ExWapp.Session.DeviceCache

  @doc false
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

    {actions, state} = Receipts.build_actions(from, id, participant, attrs, message_data, state)
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

  @spec transient_encrypted_placeholder?(map()) :: boolean()
  defp transient_encrypted_placeholder?(%{encrypted: true, decrypt_status: {:error, _}}), do: true
  defp transient_encrypted_placeholder?(%{placeholder_unavailable: true}), do: true
  defp transient_encrypted_placeholder?(_message_data), do: false

  @spec maybe_log_suppressed_message(boolean(), boolean(), term(), term(), map()) :: :ok
  defp maybe_log_suppressed_message(true, _suppress_message?, _from, _id, _message_data), do: :ok

  defp maybe_log_suppressed_message(_is_protocol, true, from, id, message_data) do
    Logger.debug(
      "[DECRYPT] Suppressing undecryptable encrypted placeholder from=#{Common.normalize_jid_with_device(from)} id=#{id} reason=#{inspect(Map.get(message_data, :decrypt_status))}"
    )
  end

  defp maybe_log_suppressed_message(_is_protocol, _suppress_message?, _from, _id, _message_data),
    do: :ok
end
