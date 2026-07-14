defmodule ExWapp.Message.Handler.Inbound do
  @moduledoc """
  Coordinates the inbound message pipeline after a `<message>` node reaches a
  session.

  Sender resolution, decryption, canonical content decoding, synchronization,
  persistence, publication, and receipt generation are delegated to focused
  modules. Wrappers therefore receive normalized `ExWapp.Message.Content`
  values instead of interpreting wire payloads themselves.
  """

  require Logger

  alias ExWapp.JID
  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.{Common, Wire}

  alias ExWapp.Message.Handler.Inbound.{
    Content,
    Decryptor,
    Envelope,
    Publisher,
    Receipts,
    Sync
  }

  alias ExWapp.Session.DeviceCache

  @doc "Processes an inbound message node and returns updated state plus protocol actions."
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
    message_data = Content.normalize(message_data)

    own_sender? = Envelope.own_sender?(attrs, from, participant, state)
    state = Sync.ingest(message_data, session, state, from, id, own_sender?)
    from_me = Envelope.from_me?(attrs, from, state, message_data)

    Publisher.publish(
      message_data,
      %{
        id: id,
        from: from,
        from_me: from_me,
        timestamp: timestamp,
        participant: participant,
        type: type,
        attrs: attrs
      },
      session,
      state
    )

    {actions, state} = Receipts.build_actions(from, id, participant, attrs, message_data, state)
    updated_state = Common.update_stats(state, :messages_received)
    {:ok, updated_state, actions}
  end

  @doc "Records device JIDs advertised by a notification in the session cache."
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
end
