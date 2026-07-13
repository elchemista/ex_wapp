defmodule ExWapp.Message.Handler.Inbound.Publisher do
  @moduledoc """
  Projects normalized inbound data into the public chat message and event stream.

  This boundary owns chat persistence and `:new_message` publication. It does
  not parse wire payloads, decrypt Signal content, or plan receipts.
  """

  require Logger

  alias ExWapp.Chat
  alias ExWapp.Message.Handler.Common
  alias ExWapp.Message.Handler.Inbound.Projection

  @type envelope :: %{
          required(:id) => term(),
          required(:from) => term(),
          required(:from_me) => boolean(),
          required(:timestamp) => integer(),
          required(:participant) => term(),
          required(:type) => term(),
          required(:attrs) => map()
        }

  @doc """
  Persists and publishes one normalized inbound message unless it is internal.
  """
  @spec publish(map(), envelope(), term(), map()) ::
          {:published, map()} | {:suppressed, map()}
  def publish(message_data, envelope, session, state) do
    message = build_public_message(message_data, envelope)
    is_protocol = Map.get(message_data, :message_content_type) == :protocol
    suppress_message? = transient_encrypted_placeholder?(message_data)

    if not is_protocol and not suppress_message? do
      persist_message(message, envelope, session, state)
      publish_event(message, envelope, session)
      {:published, message}
    else
      log_suppressed_message(is_protocol, suppress_message?, envelope, message_data)
      {:suppressed, message}
    end
  end

  @spec build_public_message(map(), envelope()) :: map()
  defp build_public_message(message_data, envelope) do
    from_me = Map.fetch!(envelope, :from_me)
    type = Map.fetch!(envelope, :type)
    attrs = Map.fetch!(envelope, :attrs)

    %{
      id: Map.fetch!(envelope, :id),
      content: Map.fetch!(message_data, :content),
      from_me: from_me,
      timestamp: Map.fetch!(envelope, :timestamp),
      text: Map.get(message_data, :text),
      status: if(from_me, do: :sent, else: :received),
      participant: Map.fetch!(envelope, :participant),
      media: Map.get(message_data, :media),
      location: Map.get(message_data, :location),
      contact: Map.get(message_data, :contact),
      event: Map.get(message_data, :event),
      raw: %{
        type: type,
        attrs: attrs,
        content: Map.fetch!(message_data, :content),
        media: Map.get(message_data, :media),
        media_type: Map.get(message_data, :media_type),
        content_type: Map.get(message_data, :content_type),
        location: Map.get(message_data, :location),
        contact: Map.get(message_data, :contact),
        event: Map.get(message_data, :event),
        from_me: from_me
      }
    }
  end

  @spec persist_message(map(), envelope(), term(), map()) :: :ok
  defp persist_message(message, envelope, session, state) do
    case Common.chat_target(session, state) do
      nil ->
        :ok

      target ->
        Projection.update_chat_name(
          target,
          Map.fetch!(envelope, :from),
          Map.fetch!(envelope, :attrs)
        )

        Chat.add_message(target, Map.fetch!(envelope, :from), message)
    end
  end

  @spec publish_event(map(), envelope(), term()) :: :ok
  defp publish_event(message, envelope, session) do
    if is_pid(session) do
      send(session, {:new_message, Map.fetch!(envelope, :from), message})
    end

    :ok
  end

  @spec transient_encrypted_placeholder?(map()) :: boolean()
  defp transient_encrypted_placeholder?(%{encrypted: true, decrypt_status: {:error, _}}), do: true
  defp transient_encrypted_placeholder?(%{placeholder_unavailable: true}), do: true
  defp transient_encrypted_placeholder?(_message_data), do: false

  @spec log_suppressed_message(boolean(), boolean(), envelope(), map()) :: :ok
  defp log_suppressed_message(true, _suppress_message?, _envelope, _message_data), do: :ok

  defp log_suppressed_message(_is_protocol, true, envelope, message_data) do
    Logger.debug(
      "[DECRYPT] Suppressing undecryptable encrypted placeholder from=#{Common.normalize_jid_with_device(Map.fetch!(envelope, :from))} id=#{Map.fetch!(envelope, :id)} reason=#{inspect(Map.get(message_data, :decrypt_status))}"
    )
  end

  defp log_suppressed_message(_is_protocol, _suppress_message?, _envelope, _message_data),
    do: :ok
end
