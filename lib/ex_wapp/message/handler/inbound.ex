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

  alias ExWapp.Binary.Node
  alias ExWapp.JID
  alias ExWapp.Log
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
    envelope = build_envelope(attrs)

    Logger.debug(
      "Received message from=#{Log.reference(envelope.from)} id=#{Log.reference(envelope.id)} type=#{envelope.type}"
    )

    state = persist_envelope_metadata(state, attrs, envelope)

    message_data = Wire.extract_message_content(content, envelope.type)

    {message_data, state} =
      maybe_decrypt_message(
        message_data,
        state,
        envelope.from,
        envelope.participant,
        attrs
      )

    message_data = Content.normalize(message_data)

    state = ingest_protocol_sync(message_data, session, state, envelope)

    envelope =
      Map.put(
        envelope,
        :from_me,
        Envelope.from_me?(attrs, envelope.from, state, message_data)
      )

    {actions, state} =
      Receipts.build_actions(
        envelope.from,
        envelope.id,
        envelope.participant,
        attrs,
        message_data,
        state
      )

    state = publish_application_message(message_data, envelope, session, state)
    {:ok, Common.update_stats(state, :messages_received), actions}
  end

  @spec build_envelope(map()) :: map()
  defp build_envelope(attrs) do
    %{
      id: Map.get(attrs, "id", ""),
      from: normalize_sender(Map.get(attrs, "from", "")),
      from_me: false,
      timestamp: Common.parse_timestamp(Map.get(attrs, "t")),
      participant: Map.get(attrs, "participant"),
      type: Map.get(attrs, "type", "text"),
      attrs: attrs
    }
  end

  @spec normalize_sender(term()) :: JID.t() | String.t()
  defp normalize_sender(%JID{} = jid), do: jid
  defp normalize_sender(jid) when is_binary(jid), do: jid
  defp normalize_sender(_jid), do: ""

  @spec persist_envelope_metadata(map(), map(), map()) :: map()
  defp persist_envelope_metadata(state, attrs, envelope) do
    state =
      Envelope.persist_lid_mappings(
        state,
        attrs,
        envelope.from,
        envelope.participant
      )

    Envelope.persist_observed_devices(state, attrs, envelope.from, envelope.participant)
    state
  end

  @spec ingest_protocol_sync(map(), term(), map(), map()) :: map()
  defp ingest_protocol_sync(message_data, session, state, envelope) do
    own_sender? =
      Envelope.own_sender?(
        envelope.attrs,
        envelope.from,
        envelope.participant,
        state
      )

    Sync.ingest(
      message_data,
      session,
      state,
      envelope.from,
      envelope.id,
      own_sender?
    )
  rescue
    exception ->
      record_phase_failure(state, :protocol_sync, envelope, {:exception, exception})
  catch
    kind, reason ->
      record_phase_failure(state, :protocol_sync, envelope, {:caught, kind, reason})
  end

  @spec publish_application_message(map(), map(), term(), map()) :: map()
  defp publish_application_message(message_data, envelope, session, state) do
    case Publisher.publish(message_data, envelope, session, state) do
      {:published, _message} -> state
      {:suppressed, _message} -> state
      {:error, reason} -> record_phase_failure(state, :application_publish, envelope, reason)
    end
  end

  @spec record_phase_failure(map(), atom(), map(), term()) :: map()
  defp record_phase_failure(state, phase, envelope, reason) do
    Logger.error(
      "[INBOUND] phase=#{phase} failed from=#{Log.reference(envelope.from)} id=#{Log.reference(envelope.id)} reason=#{format_failure(reason)}"
    )

    Common.update_stats(state, :errors)
  end

  @spec format_failure(term()) :: String.t()
  defp format_failure({:exception, exception}), do: Log.reason(exception)

  defp format_failure({:caught, kind, reason}),
    do: "#{kind}: #{Log.reason(reason)}"

  defp format_failure(reason), do: Log.reason(reason)

  @doc "Records device JIDs advertised by a notification in the session cache."
  @spec persist_notification_devices(map(), term()) :: :ok
  def persist_notification_devices(state, content) when is_map(state) and is_list(content) do
    store = Map.get(state, :store)

    content
    |> Enum.flat_map(&notification_device_jids/1)
    |> Enum.uniq()
    |> Enum.each(&DeviceCache.persist_observed_device(store, &1))

    :ok
  end

  def persist_notification_devices(_state, _content), do: :ok

  defp notification_device_jids(%Node{attrs: attrs, content: content}) do
    current =
      (attrs || %{})
      |> Map.values()
      |> Enum.map(&Common.normalize_jid_with_device/1)
      |> Enum.filter(&String.contains?(&1, "@"))

    nested =
      if is_list(content), do: Enum.flat_map(content, &notification_device_jids/1), else: []

    current ++ nested
  end

  defp notification_device_jids(_node), do: []

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
