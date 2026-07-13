defmodule ExWapp.Media.Crypto do
  @moduledoc """
  WhatsApp media encryption and decryption helpers.

  This follows the same media-key expansion used by popular WhatsApp Web
  clients: HKDF-SHA256 expands the 32-byte media key into IV, cipher, MAC, and
  reference keys. The payload is then encrypted with AES-256-CBC and protected
  with the first 10 bytes of an HMAC-SHA256 digest over `IV || ciphertext`.
  """

  alias ExWapp.Media

  @hmac_len 10
  @keys_len 112

  @type media_keys :: %{iv: binary(), cipher_key: binary(), mac_key: binary(), ref_key: binary()}

  @doc """
  Derives WhatsApp media keys for the given media type.
  """
  @spec derive_keys(binary(), Media.media_type()) :: media_keys()
  def derive_keys(media_key, type) when byte_size(media_key) == 32 do
    expanded = hkdf_sha256(media_key, <<>>, media_info(type), @keys_len)

    %{
      iv: binary_part(expanded, 0, 16),
      cipher_key: binary_part(expanded, 16, 32),
      mac_key: binary_part(expanded, 48, 32),
      ref_key: binary_part(expanded, 80, 32)
    }
  end

  @doc """
  Encrypts plaintext media bytes and returns upload metadata plus encrypted body.
  """
  @spec encrypt_upload(binary(), Media.media_type()) :: {:ok, Media.Upload.t(), binary()}
  def encrypt_upload(plaintext, type) when is_binary(plaintext) do
    media_key = :crypto.strong_rand_bytes(32)
    keys = derive_keys(media_key, type)
    ciphertext = encrypt_cbc_pkcs7(plaintext, keys.cipher_key, keys.iv)

    # WhatsApp truncates the HMAC to the first 10 bytes before appending it.
    mac = :crypto.mac(:hmac, :sha256, keys.mac_key, keys.iv <> ciphertext) |> binary_part(0, 10)
    body = ciphertext <> mac

    upload = %Media.Upload{
      type: type,
      media_key: media_key,
      file_sha256: :crypto.hash(:sha256, plaintext),
      file_enc_sha256: :crypto.hash(:sha256, body),
      file_length: byte_size(plaintext),
      media_key_timestamp: System.system_time(:second)
    }

    {:ok, upload, body}
  end

  @doc """
  Decrypts an encrypted media body and validates all available integrity checks.
  """
  @spec decrypt_download(binary(), Media.Ref.t()) :: {:ok, binary()} | {:error, term()}
  def decrypt_download(body, %Media.Ref{} = ref) when is_binary(body) do
    with :ok <- validate_ref(ref),
         :ok <- validate_body_size(body),
         {:ok, ciphertext, mac} <- split_body(body),
         keys <- derive_keys(ref.media_key, ref.type),
         :ok <- validate_mac(keys.iv, ciphertext, keys.mac_key, mac),
         :ok <- validate_enc_hash(body, ref.file_enc_sha256),
         {:ok, plaintext} <- decrypt_cbc_pkcs7(ciphertext, keys.cipher_key, keys.iv),
         :ok <- validate_plain_hash(plaintext, ref.file_sha256),
         :ok <- validate_file_length(plaintext, ref.file_length) do
      {:ok, plaintext}
    end
  end

  @spec validate_ref(Media.Ref.t()) ::
          :ok | {:error, :missing_media_key | :invalid_media_key | :unsupported_media_type}
  defp validate_ref(%Media.Ref{media_key: nil}), do: {:error, :missing_media_key}

  defp validate_ref(%Media.Ref{media_key: key}) when not is_binary(key),
    do: {:error, :invalid_media_key}

  defp validate_ref(%Media.Ref{media_key: key}) when byte_size(key) != 32,
    do: {:error, :invalid_media_key}

  defp validate_ref(%Media.Ref{type: type}) when type in [:image, :audio, :document], do: :ok
  defp validate_ref(%Media.Ref{}), do: {:error, :unsupported_media_type}

  @doc """
  Returns the WhatsApp HKDF context string for a media type.
  """
  @spec media_info(Media.media_type()) :: binary()
  def media_info(:image), do: "WhatsApp Image Keys"
  def media_info(:audio), do: "WhatsApp Audio Keys"
  def media_info(:document), do: "WhatsApp Document Keys"

  @spec validate_body_size(binary()) :: :ok | {:error, :media_too_short}
  defp validate_body_size(body) do
    if byte_size(body) > @hmac_len, do: :ok, else: {:error, :media_too_short}
  end

  @spec split_body(binary()) :: {:ok, binary(), binary()}
  defp split_body(body) do
    ciphertext_len = byte_size(body) - @hmac_len
    <<ciphertext::binary-size(^ciphertext_len), mac::binary-size(@hmac_len)>> = body
    {:ok, ciphertext, mac}
  end

  @spec validate_mac(binary(), binary(), binary(), binary()) ::
          :ok | {:error, :invalid_media_hmac}
  defp validate_mac(iv, ciphertext, mac_key, mac) do
    expected =
      :crypto.mac(:hmac, :sha256, mac_key, iv <> ciphertext)
      |> binary_part(0, @hmac_len)

    if secure_compare(expected, mac), do: :ok, else: {:error, :invalid_media_hmac}
  end

  @spec secure_compare(binary(), binary()) :: boolean()
  defp secure_compare(left, right)
       when is_binary(left) and is_binary(right) and byte_size(left) == byte_size(right) do
    left
    |> :crypto.exor(right)
    |> :binary.bin_to_list()
    |> Enum.reduce(0, &Bitwise.bor/2) == 0
  end

  defp secure_compare(_left, _right), do: false

  @spec validate_enc_hash(binary(), binary() | nil) :: :ok | {:error, :invalid_media_enc_sha256}
  defp validate_enc_hash(_body, nil), do: :ok

  defp validate_enc_hash(body, hash) when is_binary(hash) do
    if :crypto.hash(:sha256, body) == hash, do: :ok, else: {:error, :invalid_media_enc_sha256}
  end

  @spec validate_plain_hash(binary(), binary() | nil) :: :ok | {:error, :invalid_media_sha256}
  defp validate_plain_hash(_plaintext, nil), do: :ok

  defp validate_plain_hash(plaintext, hash) when is_binary(hash) do
    if :crypto.hash(:sha256, plaintext) == hash,
      do: :ok,
      else: {:error, :invalid_media_sha256}
  end

  @spec validate_file_length(binary(), non_neg_integer() | nil) ::
          :ok | {:error, :media_length_mismatch}
  defp validate_file_length(_plaintext, nil), do: :ok

  defp validate_file_length(plaintext, length) when is_integer(length) do
    if byte_size(plaintext) == length, do: :ok, else: {:error, :media_length_mismatch}
  end

  @spec encrypt_cbc_pkcs7(binary(), binary(), binary()) :: binary()
  defp encrypt_cbc_pkcs7(plaintext, key, iv) do
    padded = pkcs7_pad(plaintext)
    :crypto.crypto_one_time(:aes_256_cbc, key, iv, padded, true)
  end

  @spec decrypt_cbc_pkcs7(binary(), binary(), binary()) ::
          {:ok, binary()} | {:error, :invalid_padding | :empty_data}
  defp decrypt_cbc_pkcs7(ciphertext, key, iv) do
    plaintext = :crypto.crypto_one_time(:aes_256_cbc, key, iv, ciphertext, false)
    pkcs7_unpad(plaintext)
  end

  @spec pkcs7_pad(binary()) :: binary()
  defp pkcs7_pad(data) do
    pad_len = 16 - rem(byte_size(data), 16)
    data <> :binary.copy(<<pad_len>>, pad_len)
  end

  @spec pkcs7_unpad(binary()) :: {:ok, binary()} | {:error, :invalid_padding | :empty_data}
  defp pkcs7_unpad(data) when byte_size(data) > 0 do
    pad_len = :binary.last(data)

    cond do
      pad_len == 0 or pad_len > 16 or pad_len > byte_size(data) ->
        {:error, :invalid_padding}

      binary_part(data, byte_size(data) - pad_len, pad_len) != :binary.copy(<<pad_len>>, pad_len) ->
        {:error, :invalid_padding}

      true ->
        {:ok, binary_part(data, 0, byte_size(data) - pad_len)}
    end
  end

  defp pkcs7_unpad(_), do: {:error, :empty_data}

  @spec hkdf_sha256(binary(), binary(), binary(), pos_integer()) :: binary()
  defp hkdf_sha256(ikm, <<>>, info, length),
    do: hkdf_sha256(ikm, :binary.copy(<<0>>, 32), info, length)

  defp hkdf_sha256(ikm, salt, info, length) do
    prk = :crypto.mac(:hmac, :sha256, salt, ikm)
    n = ceil(length / 32)

    {output, _} =
      Enum.reduce(1..n, {<<>>, <<>>}, fn i, {acc, prev} ->
        t = :crypto.mac(:hmac, :sha256, prk, prev <> info <> <<i>>)
        {acc <> t, t}
      end)

    binary_part(output, 0, length)
  end
end
