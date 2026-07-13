defmodule ExWapp.Message.Handler.Inbound.Content do
  @moduledoc """
  Decodes already-decrypted inbound plaintext into the existing message map.

  This module does not decrypt Signal payloads or publish events. It preserves
  the current map contract while centralizing plaintext classification,
  protocol handling, media extraction, and decrypt diagnostics.
  """

  require Logger

  alias ExWapp.Message.Handler.Inbound.Decryptor
  alias ExWapp.Message.Handler.Wire

  @doc """
  Classifies decrypted plaintext and merges decoded fields into message data.
  """
  @spec decode_decrypted(Decryptor.success()) :: map()
  def decode_decrypted(decrypt_result) do
    plaintext = decrypt_result.plaintext
    payload = decrypt_result.payload

    {content_type, decoded_text} =
      Wire.classify_decrypted_content(
        plaintext,
        decrypt_result.sender_key_distribution_count
      )

    text = decoded_text || "(encrypted: #{Map.get(payload, :enc_type, decrypt_result.enc_type)})"

    log_decrypted_message(
      content_type,
      decoded_text,
      decrypt_result.sender_jid,
      payload,
      plaintext,
      text
    )

    build_decoded_message_data(
      decrypt_result.message_data,
      text,
      content_type,
      plaintext
    )
  end

  @spec log_decrypted_message(
          term(),
          String.t() | nil,
          String.t(),
          map(),
          binary(),
          String.t()
        ) :: :ok
  defp log_decrypted_message(:protocol, _decoded_text, _sender_jid, payload, plaintext, _text) do
    Logger.debug(
      "[DECRYPT] Protocol message (#{Map.get(payload, :enc_type)}), plaintext_size=#{byte_size(plaintext)} — skipping chat display"
    )
  end

  defp log_decrypted_message(_content_type, decoded_text, sender_jid, payload, plaintext, text) do
    if is_nil(decoded_text) do
      preview_size = min(byte_size(plaintext), 24)
      preview = Base.encode16(binary_part(plaintext, 0, preview_size), case: :lower)

      Logger.warning(
        "[DECRYPT] Decrypted payload but could not extract text. sender_jid=#{sender_jid} enc_type=#{Map.get(payload, :enc_type)} plaintext_size=#{byte_size(plaintext)} preview=#{preview}"
      )
    end

    Logger.debug(
      "[DECRYPT] Success! sender_jid=#{sender_jid} enc_type=#{Map.get(payload, :enc_type)} plaintext_size=#{byte_size(plaintext)} text=#{inspect(String.slice(text || "", 0, 50))}"
    )
  end

  @spec build_decoded_message_data(map(), String.t(), term(), binary()) :: map()
  defp build_decoded_message_data(message_data, text, :protocol, plaintext) do
    message_data
    |> Map.put(:text, text)
    |> Map.put(:decrypt_status, :ok)
    |> Map.put(:message_content_type, :protocol)
    |> Map.put(:protocol_payload, plaintext)
    |> Map.put(:from_me, device_sent_message_payload?(plaintext))
  end

  defp build_decoded_message_data(message_data, text, content_type, plaintext) do
    message_data
    |> Map.put(:text, text)
    |> Map.put(:decrypt_status, :ok)
    |> Map.put(:message_content_type, content_type)
    |> Map.put(:from_me, device_sent_message_payload?(plaintext))
    |> Wire.apply_media_from_plaintext(plaintext)
  end

  @spec device_sent_message_payload?(binary()) :: boolean()
  defp device_sent_message_payload?(payload) do
    match?({:ok, _wrapped}, Wire.find_length_delimited_field(payload, 31))
  end
end
