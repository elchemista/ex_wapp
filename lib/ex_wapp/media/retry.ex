defmodule ExWapp.Media.Retry do
  @moduledoc """
  Implements WhatsApp's media re-upload protocol.

  When a CDN object is no longer available, a companion sends a
  `<receipt type="server-error">` containing an authenticated
  `ServerErrorReceipt`. The phone answers with a `mediaretry` notification
  carrying a fresh direct path encrypted with the same key.
  """

  import Bitwise

  alias ExWapp.Binary
  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.Common

  @retry_hkdf_info "WhatsApp Media Retry Notification"
  @gcm_tag_size 16

  @type result :: :general_error | :success | :not_found | :decryption_error | non_neg_integer()

  @doc "Derives the AES-256-GCM key used by media-retry payloads."
  @spec retry_key(binary()) :: binary()
  def retry_key(media_key) when is_binary(media_key) and byte_size(media_key) == 32 do
    hkdf_sha256(media_key, :binary.copy(<<0>>, 32), @retry_hkdf_info, 32)
  end

  @doc """
  Builds a media re-upload request addressed to the local primary identity.

  `participant_jid` is required only when the original message belongs to a
  group. The encrypted protobuf is authenticated with the message ID as AAD.
  """
  @spec build_receipt(
          String.t(),
          String.t(),
          String.t(),
          boolean(),
          String.t() | nil,
          binary()
        ) :: Node.t()
  def build_receipt(msg_id, own_jid, chat_jid, from_me, participant_jid, media_key)
      when is_binary(msg_id) and msg_id != "" and is_binary(own_jid) and own_jid != "" and
             is_binary(chat_jid) and chat_jid != "" and is_boolean(from_me) do
    iv = :crypto.strong_rand_bytes(12)
    plaintext = encode_server_error_receipt(msg_id)
    enc_p = encrypt_gcm(plaintext, retry_key(media_key), iv, msg_id)

    rmr_attrs =
      %{"jid" => chat_jid, "from_me" => to_string(from_me)}
      |> maybe_put_participant(participant_jid)

    %Node{
      tag: "receipt",
      attrs: %{"id" => msg_id, "to" => own_jid, "type" => "server-error"},
      content: [
        %Node{
          tag: "encrypt",
          attrs: %{},
          content: [
            %Node{tag: "enc_p", attrs: %{}, content: Binary.raw(enc_p)},
            %Node{tag: "enc_iv", attrs: %{}, content: Binary.raw(iv)}
          ]
        },
        %Node{tag: "rmr", attrs: rmr_attrs, content: nil}
      ]
    }
  end

  @doc """
  Decrypts a `mediaretry` notification.

  A successful result returns the refreshed direct path. Error code `2` is the
  wire-level indication that the phone no longer has the media.
  """
  @spec decode_notification(Node.t(), binary()) :: {:ok, String.t()} | {:error, term()}
  def decode_notification(%Node{} = node, media_key) do
    case child(node.content, "error") do
      %Node{attrs: attrs} ->
        case Map.get(attrs || %{}, "code") do
          "2" -> {:error, :not_on_phone}
          code -> {:error, {:server_error, code}}
        end

      nil ->
        decrypt_notification(node, media_key)
    end
  end

  @doc false
  @spec encode_notification(String.t(), String.t(), result(), binary() | nil) :: binary()
  def encode_notification(stanza_id, direct_path, result, message_secret \\ nil) do
    <<>>
    |> encode_length_delimited(1, stanza_id)
    |> encode_length_delimited(2, direct_path)
    |> encode_varint_field(3, result_to_integer(result))
    |> encode_length_delimited(4, message_secret)
  end

  @doc false
  @spec encrypt_notification(binary(), binary(), binary(), String.t()) :: binary()
  def encrypt_notification(plaintext, media_key, iv, msg_id)
      when is_binary(plaintext) and is_binary(iv) and byte_size(iv) == 12 do
    encrypt_gcm(plaintext, retry_key(media_key), iv, msg_id)
  end

  @doc false
  @spec decode_server_error_receipt(binary()) :: {:ok, String.t()} | {:error, term()}
  def decode_server_error_receipt(payload) when is_binary(payload) do
    with {:ok, fields} <- decode_fields(payload, %{}),
         stanza_id when is_binary(stanza_id) and stanza_id != "" <- Map.get(fields, 1) do
      {:ok, stanza_id}
    else
      nil -> {:error, :missing_stanza_id}
      "" -> {:error, :missing_stanza_id}
      {:error, _} = error -> error
      _ -> {:error, :malformed_server_error_receipt}
    end
  end

  defp decrypt_notification(%Node{attrs: attrs, content: content}, media_key) do
    msg_id = Map.get(attrs || %{}, "id")
    encrypt = child(content, "encrypt")
    enc_p = encrypt |> child_content("enc_p")
    iv = encrypt |> child_content("enc_iv")

    with true <- is_binary(msg_id) and msg_id != "",
         true <- is_binary(enc_p) and byte_size(enc_p) >= @gcm_tag_size,
         true <- is_binary(iv) and byte_size(iv) == 12,
         {:ok, plaintext} <- decrypt_gcm(enc_p, retry_key(media_key), iv, msg_id),
         {:ok, decoded} <- decode_media_retry_notification(plaintext),
         :ok <- validate_stanza_id(decoded, msg_id) do
      case decoded do
        %{result: :success, direct_path: path} when is_binary(path) and path != "" ->
          {:ok, path}

        %{result: :success} ->
          {:error, :missing_direct_path}

        %{result: result} ->
          {:error, {:result, result}}
      end
    else
      false -> {:error, :malformed_notification}
      {:error, _} = error -> error
    end
  rescue
    _ -> {:error, :malformed_notification}
  end

  defp validate_stanza_id(%{stanza_id: nil}, _msg_id), do: :ok
  defp validate_stanza_id(%{stanza_id: msg_id}, msg_id), do: :ok
  defp validate_stanza_id(_decoded, _msg_id), do: {:error, :stanza_id_mismatch}

  defp decode_media_retry_notification(payload) do
    with {:ok, fields} <- decode_fields(payload, %{}) do
      {:ok,
       %{
         stanza_id: Map.get(fields, 1),
         direct_path: Map.get(fields, 2),
         result: integer_to_result(Map.get(fields, 3, 0)),
         message_secret: Map.get(fields, 4)
       }}
    end
  end

  defp encode_server_error_receipt(msg_id), do: encode_length_delimited(<<>>, 1, msg_id)

  defp maybe_put_participant(attrs, participant)
       when is_binary(participant) and participant != "",
       do: Map.put(attrs, "participant", participant)

  defp maybe_put_participant(attrs, _participant), do: attrs

  defp child(%Node{content: content}, tag), do: child(content, tag)

  defp child(content, tag) when is_list(content) do
    Enum.find(content, &match?(%Node{tag: ^tag}, &1))
  end

  defp child(_content, _tag), do: nil

  defp child_content(%Node{} = node, tag) do
    case child(node.content, tag) do
      %Node{content: content} -> Common.normalize_content(content)
      _ -> nil
    end
  end

  defp child_content(_node, _tag), do: nil

  defp encrypt_gcm(plaintext, key, iv, aad) do
    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, aad, @gcm_tag_size, true)

    ciphertext <> tag
  end

  defp decrypt_gcm(payload, key, iv, aad) when byte_size(payload) >= @gcm_tag_size do
    ciphertext_size = byte_size(payload) - @gcm_tag_size
    <<ciphertext::binary-size(^ciphertext_size), tag::binary-size(@gcm_tag_size)>> = payload

    case :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ciphertext, aad, tag, false) do
      :error -> {:error, :invalid_media_retry_auth}
      plaintext when is_binary(plaintext) -> {:ok, plaintext}
    end
  end

  defp decode_fields(<<>>, acc), do: {:ok, acc}

  defp decode_fields(payload, acc) do
    with {:ok, key, rest} <- decode_varint(payload),
         field_number = key >>> 3,
         wire_type = key &&& 0x07,
         {:ok, value, tail} <- decode_field(wire_type, rest) do
      decode_fields(tail, Map.put(acc, field_number, value))
    end
  end

  defp decode_field(0, payload), do: decode_varint(payload)

  defp decode_field(2, payload) do
    with {:ok, length, rest} <- decode_varint(payload),
         true <- length <= byte_size(rest) do
      <<value::binary-size(^length), tail::binary>> = rest
      {:ok, value, tail}
    else
      false -> {:error, :truncated_protobuf_field}
      {:error, _} = error -> error
    end
  end

  defp decode_field(1, <<value::binary-size(8), rest::binary>>), do: {:ok, value, rest}
  defp decode_field(5, <<value::binary-size(4), rest::binary>>), do: {:ok, value, rest}
  defp decode_field(wire_type, _payload), do: {:error, {:unsupported_wire_type, wire_type}}

  defp decode_varint(payload), do: decode_varint(payload, 0, 0)
  defp decode_varint(_payload, _acc, shift) when shift > 63, do: {:error, :invalid_varint}
  defp decode_varint(<<>>, _acc, _shift), do: {:error, :truncated_varint}

  defp decode_varint(<<byte, rest::binary>>, acc, shift) do
    value = acc ||| (byte &&& 0x7F) <<< shift

    if (byte &&& 0x80) == 0 do
      {:ok, value, rest}
    else
      decode_varint(rest, value, shift + 7)
    end
  end

  defp encode_length_delimited(acc, _field_number, nil), do: acc

  defp encode_length_delimited(acc, field_number, value) when is_binary(value) do
    acc <>
      encode_varint(field_number <<< 3 ||| 2) <>
      encode_varint(byte_size(value)) <>
      value
  end

  defp encode_varint_field(acc, field_number, value) when is_integer(value) and value >= 0 do
    acc <> encode_varint(field_number <<< 3) <> encode_varint(value)
  end

  defp encode_varint(value) when value < 0x80, do: <<value>>

  defp encode_varint(value) do
    <<(value &&& 0x7F) ||| 0x80>> <> encode_varint(value >>> 7)
  end

  defp result_to_integer(:general_error), do: 0
  defp result_to_integer(:success), do: 1
  defp result_to_integer(:not_found), do: 2
  defp result_to_integer(:decryption_error), do: 3
  defp result_to_integer(value) when is_integer(value) and value >= 0, do: value

  defp integer_to_result(0), do: :general_error
  defp integer_to_result(1), do: :success
  defp integer_to_result(2), do: :not_found
  defp integer_to_result(3), do: :decryption_error
  defp integer_to_result(value), do: value

  defp hkdf_sha256(ikm, salt, info, length) do
    prk = :crypto.mac(:hmac, :sha256, salt, ikm)
    blocks = div(length + 31, 32)

    {output, _previous} =
      Enum.reduce(1..blocks, {<<>>, <<>>}, fn index, {output, previous} ->
        next = :crypto.mac(:hmac, :sha256, prk, previous <> info <> <<index>>)
        {output <> next, next}
      end)

    binary_part(output, 0, length)
  end
end
