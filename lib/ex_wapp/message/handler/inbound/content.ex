defmodule ExWapp.Message.Handler.Inbound.Content do
  @moduledoc """
  Decodes inbound plaintext into the canonical message-content contract.

  This module is the single recognition point for decrypted text, media,
  location, contact, event, protocol, and unsupported content. It also keeps
  the legacy map fields populated for compatibility.
  """

  require Logger

  alias ExWapp.Media.Ref
  alias ExWapp.Message.Content, as: MessageContent
  alias ExWapp.Message.Handler.Inbound.Decryptor
  alias ExWapp.Message.Handler.Wire

  @doc """
  Classifies decrypted plaintext and merges canonical plus legacy fields.
  """
  @spec decode_decrypted(Decryptor.success()) :: map()
  def decode_decrypted(decrypt_result) do
    canonical = decode_plaintext(decrypt_result)
    log_decrypted_message(canonical, decrypt_result)

    decrypt_result.message_data
    |> Map.merge(MessageContent.to_legacy(canonical))
    |> Map.put(:content, canonical)
    |> Map.put(:decrypt_status, :ok)
    |> Map.put(:from_me, device_sent_message_payload?(decrypt_result.plaintext))
  end

  @doc """
  Ensures plain, failed, and already-decoded messages all carry canonical content.
  """
  @spec normalize(map()) :: map()
  def normalize(message_data) when is_map(message_data) do
    canonical = MessageContent.from_legacy(message_data)

    message_data
    |> Map.merge(MessageContent.to_legacy(canonical))
    |> Map.put(:content, canonical)
  end

  @spec decode_plaintext(Decryptor.success()) :: MessageContent.t()
  defp decode_plaintext(decrypt_result) do
    plaintext = decrypt_result.plaintext

    {content_type, decoded_text} =
      Wire.classify_decrypted_content(
        plaintext,
        decrypt_result.sender_key_distribution_count
      )

    fallback_text =
      decoded_text ||
        "(encrypted: #{Map.get(decrypt_result.payload, :enc_type, decrypt_result.enc_type)})"

    diagnostics = %{
      enc_type: Map.get(decrypt_result.payload, :enc_type, decrypt_result.enc_type),
      plaintext_size: byte_size(plaintext),
      sender_jid: decrypt_result.sender_jid
    }

    case content_type do
      :protocol ->
        MessageContent.new(:protocol,
          text: fallback_text,
          protocol_payload: plaintext,
          diagnostics: diagnostics
        )

      :user_message ->
        plaintext
        |> Wire.apply_media_from_plaintext(%{})
        |> canonical_user_content(decoded_text, fallback_text, diagnostics)
    end
  end

  @spec canonical_user_content(map(), binary() | nil, binary(), map()) :: MessageContent.t()
  defp canonical_user_content(
         %{media: %Ref{} = media} = fields,
         _decoded_text,
         _fallback_text,
         diagnostics
       ) do
    MessageContent.new(:media,
      text: Map.get(fields, :text),
      media: media,
      media_type: Map.get(fields, :media_type) || media.type,
      diagnostics: diagnostics
    )
  end

  defp canonical_user_content(
         %{location: location} = fields,
         _decoded_text,
         _fallback_text,
         diagnostics
       )
       when is_map(location) do
    MessageContent.new(:location,
      text: Map.get(fields, :text),
      location: location,
      diagnostics: diagnostics
    )
  end

  defp canonical_user_content(
         %{contact: contact} = fields,
         _decoded_text,
         _fallback_text,
         diagnostics
       )
       when is_map(contact) do
    MessageContent.new(:contact,
      text: Map.get(fields, :text),
      contact: contact,
      diagnostics: diagnostics
    )
  end

  defp canonical_user_content(
         %{event: event} = fields,
         _decoded_text,
         _fallback_text,
         diagnostics
       )
       when is_map(event) do
    MessageContent.new(:event,
      text: Map.get(fields, :text),
      event: event,
      diagnostics: diagnostics
    )
  end

  defp canonical_user_content(_fields, decoded_text, _fallback_text, diagnostics)
       when is_binary(decoded_text) do
    MessageContent.new(:text, text: decoded_text, diagnostics: diagnostics)
  end

  defp canonical_user_content(_fields, _decoded_text, fallback_text, diagnostics) do
    MessageContent.new(:unsupported, text: fallback_text, diagnostics: diagnostics)
  end

  @spec log_decrypted_message(MessageContent.t(), Decryptor.success()) :: :ok
  defp log_decrypted_message(%MessageContent{kind: :protocol}, decrypt_result) do
    Logger.debug(
      "[DECRYPT] Protocol message (#{Map.get(decrypt_result.payload, :enc_type)}), plaintext_size=#{byte_size(decrypt_result.plaintext)} — skipping chat display"
    )
  end

  defp log_decrypted_message(%MessageContent{kind: :unsupported}, decrypt_result) do
    plaintext = decrypt_result.plaintext
    preview_size = min(byte_size(plaintext), 24)
    preview = Base.encode16(binary_part(plaintext, 0, preview_size), case: :lower)

    Logger.warning(
      "[DECRYPT] Decrypted payload but could not classify content. sender_jid=#{decrypt_result.sender_jid} enc_type=#{Map.get(decrypt_result.payload, :enc_type)} plaintext_size=#{byte_size(plaintext)} preview=#{preview}"
    )

    log_decrypt_success(decrypt_result, "(unsupported)")
  end

  defp log_decrypted_message(content, decrypt_result) do
    log_decrypt_success(decrypt_result, content.text)
  end

  @spec log_decrypt_success(Decryptor.success(), binary() | nil) :: :ok
  defp log_decrypt_success(decrypt_result, text) do
    Logger.debug(
      "[DECRYPT] Success! sender_jid=#{decrypt_result.sender_jid} enc_type=#{Map.get(decrypt_result.payload, :enc_type)} plaintext_size=#{byte_size(decrypt_result.plaintext)} text=#{inspect(String.slice(text || "", 0, 50))}"
    )
  end

  @spec device_sent_message_payload?(binary()) :: boolean()
  defp device_sent_message_payload?(payload) do
    match?({:ok, _wrapped}, Wire.find_length_delimited_field(payload, 31))
  end
end
