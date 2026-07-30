defmodule ExWapp.Message.Handler.Inbound.Content do
  @moduledoc """
  Decodes inbound plaintext into the canonical message-content contract.

  This module is the single recognition point for decrypted text, media,
  location, contact, event, protocol, and unsupported content. It also keeps
  the legacy map fields populated for compatibility.
  """

  require Logger

  alias ExWapp.{Log, Media.Ref}
  alias ExWapp.Message.Content, as: MessageContent
  alias ExWapp.Message.Handler.Inbound.Decryptor
  alias ExWapp.Message.Handler.Wire.ContentDecoder
  alias WAWebProtobufsE2E.Message

  @doc """
  Classifies decrypted plaintext and merges canonical plus legacy fields.
  """
  @spec decode_decrypted(Decryptor.success()) :: map()
  def decode_decrypted(decrypt_result) do
    decoded = ContentDecoder.decode(decrypt_result.plaintext)

    canonical =
      decode_decoded_message(decoded, decrypt_result.plaintext,
        sender_key_distribution_count: decrypt_result.sender_key_distribution_count,
        enc_type: Map.get(decrypt_result.payload, :enc_type, decrypt_result.enc_type),
        sender_jid: decrypt_result.sender_jid
      )

    log_decrypted_message(canonical, decrypt_result)

    from_me =
      case decoded do
        {:ok, message} -> ContentDecoder.device_sent_message?(message)
        :error -> false
      end

    decrypt_result.message_data
    |> Map.merge(MessageContent.to_legacy(canonical))
    |> Map.put(:content, canonical)
    |> Map.put(:decrypt_status, :ok)
    |> Map.put(:from_me, from_me)
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

  @doc """
  Decodes one plaintext protobuf payload to canonical inbound content.
  """
  @spec decode_plaintext(binary(), keyword()) :: MessageContent.t()
  def decode_plaintext(plaintext, opts \\ []) when is_binary(plaintext) and is_list(opts) do
    plaintext |> ContentDecoder.decode() |> decode_decoded_message(plaintext, opts)
  end

  @doc """
  Decodes an already-parsed E2E message to canonical inbound content.

  `plaintext` is only used for diagnostics and the protocol passthrough payload,
  so callers that already hold the decoded struct never re-encode it.
  """
  @spec decode_message(%Message{}, binary(), keyword()) :: MessageContent.t()
  def decode_message(%Message{} = message, plaintext, opts \\ [])
      when is_binary(plaintext) and is_list(opts) do
    decode_decoded_message({:ok, message}, plaintext, opts)
  end

  @spec decode_decoded_message({:ok, %Message{}} | :error, binary(), keyword()) ::
          MessageContent.t()
  defp decode_decoded_message(decoded, plaintext, opts) do
    sender_key_distribution_count = Keyword.get(opts, :sender_key_distribution_count, 0)
    enc_type = Keyword.get(opts, :enc_type, "msg")
    sender_jid = Keyword.get(opts, :sender_jid, "")

    {content_type, decoded_text} =
      case decoded do
        {:ok, message} ->
          ContentDecoder.classify_message(message, sender_key_distribution_count)

        :error ->
          {:user_message, nil}
      end

    fallback_text = decoded_text || "(encrypted: #{enc_type})"

    diagnostics = %{
      enc_type: enc_type,
      plaintext_size: byte_size(plaintext),
      sender_jid: sender_jid
    }

    case content_type do
      :protocol ->
        MessageContent.new(:protocol,
          text: fallback_text,
          protocol_payload: plaintext,
          diagnostics: diagnostics
        )

      :user_message ->
        decoded
        |> apply_media_fields()
        |> canonical_user_content(decoded_text, fallback_text, diagnostics)
    end
  end

  @spec apply_media_fields({:ok, %Message{}} | :error) :: map()
  defp apply_media_fields({:ok, message}),
    do: ContentDecoder.apply_media_from_message(%{}, message)

  defp apply_media_fields(:error), do: %{}

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

    Logger.warning(
      "[DECRYPT] Decrypted payload but could not classify content. sender=#{Log.reference(decrypt_result.sender_jid)} enc_type=#{Map.get(decrypt_result.payload, :enc_type)} plaintext_size=#{byte_size(plaintext)}"
    )

    log_decrypt_success(decrypt_result, "(unsupported)")
  end

  defp log_decrypted_message(content, decrypt_result) do
    log_decrypt_success(decrypt_result, content.text)
  end

  @spec log_decrypt_success(Decryptor.success(), binary() | nil) :: :ok
  defp log_decrypt_success(decrypt_result, _text) do
    Logger.debug(
      "[DECRYPT] Success! sender=#{Log.reference(decrypt_result.sender_jid)} enc_type=#{Map.get(decrypt_result.payload, :enc_type)} plaintext_size=#{byte_size(decrypt_result.plaintext)}"
    )
  end
end
