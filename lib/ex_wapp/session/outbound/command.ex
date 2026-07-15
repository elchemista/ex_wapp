defmodule ExWapp.Session.Outbound.Command do
  @moduledoc false

  alias ExWapp.Message

  @supported_types [:text, :image, :audio, :document, :location, :contact, :event]

  @spec prepare(Message.t()) :: {:ok, Message.t()} | {:error, term()}
  def prepare(%Message{} = message) do
    with :ok <- validate_type(message.type),
         :ok <- validate_recipient(message.to),
         :ok <- validate_options(message.opts),
         :ok <- validate_message_id(message.id),
         :ok <- validate_body(message.type, message.body) do
      {:ok, normalize_message_id(message)}
    end
  end

  def prepare(_message), do: {:error, :invalid_message}

  defp validate_type(type) when type in @supported_types, do: :ok
  defp validate_type(type), do: {:error, {:unsupported_message_type, type}}

  defp validate_recipient(recipient) when is_binary(recipient) and recipient != "", do: :ok
  defp validate_recipient(_recipient), do: {:error, :invalid_recipient}

  defp validate_options(options) when is_list(options) do
    if Keyword.keyword?(options), do: :ok, else: {:error, :invalid_send_options}
  end

  defp validate_options(_options), do: {:error, :invalid_send_options}

  defp validate_message_id(nil), do: :ok
  defp validate_message_id(message_id) when is_binary(message_id) and message_id != "", do: :ok
  defp validate_message_id(_message_id), do: {:error, :invalid_message_id}

  defp validate_body(:text, body) when is_binary(body), do: :ok
  defp validate_body(:text, _body), do: {:error, :invalid_message_body}
  defp validate_body(_type, _body), do: :ok

  defp normalize_message_id(%Message{id: nil, opts: options} = message) do
    case Keyword.get(options, :retry_message_id) do
      message_id when is_binary(message_id) and message_id != "" ->
        %{message | id: message_id}

      _other ->
        message
    end
  end

  defp normalize_message_id(%Message{id: message_id, opts: options} = message) do
    %{message | opts: Keyword.put(options, :retry_message_id, message_id)}
  end
end
