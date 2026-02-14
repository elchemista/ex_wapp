# credo:disable-for-this-file
defmodule ExWapp.AppState.Crypto do
  @moduledoc """
  Cryptographic primitives for WhatsApp App State Sync.

  Implements key expansion, AES-256-CBC encrypt/decrypt, and MAC computation
  matching whatsmeow's `appstate/keys.go` and `appstate/hash.go`.
  """

  @hkdf_info "WhatsApp Mutation Keys"

  @type expanded_keys :: %{
          index: binary(),
          value_encryption: binary(),
          value_mac: binary(),
          snapshot_mac: binary(),
          patch_mac: binary()
        }

  @doc """
  Expand a 32-byte app state key into 5 sub-keys (160 bytes total) via HKDF-SHA256.

  Matches whatsmeow `expandAppStateKeys()` in `appstate/keys.go:81-84`.
  """
  @spec expand_keys(binary()) :: expanded_keys()
  def expand_keys(key_data) when byte_size(key_data) == 32 do
    expanded = hkdf_sha256(key_data, <<>>, @hkdf_info, 160)

    %{
      index: binary_part(expanded, 0, 32),
      value_encryption: binary_part(expanded, 32, 32),
      value_mac: binary_part(expanded, 64, 32),
      snapshot_mac: binary_part(expanded, 96, 32),
      patch_mac: binary_part(expanded, 128, 32)
    }
  end

  @doc """
  Encrypt plaintext with AES-256-CBC + PKCS7 padding.

  When `iv` is nil, generates a random 16-byte IV.
  Returns `{iv, ciphertext}`.

  Matches whatsmeow `cbcutil.Encrypt()`.
  """
  @spec encrypt_cbc(binary(), binary(), binary() | nil) :: {binary(), binary()}
  def encrypt_cbc(plaintext, key, iv \\ nil) when byte_size(key) == 32 do
    iv = iv || :crypto.strong_rand_bytes(16)
    padded = pkcs7_pad(plaintext)
    ciphertext = :crypto.crypto_one_time(:aes_256_cbc, key, iv, padded, true)
    {iv, ciphertext}
  end

  @doc """
  Decrypt AES-256-CBC ciphertext and remove PKCS7 padding.

  Matches whatsmeow `cbcutil.Decrypt()`.
  """
  @spec decrypt_cbc(binary(), binary(), binary()) :: {:ok, binary()} | {:error, term()}
  def decrypt_cbc(ciphertext, key, iv) when byte_size(key) == 32 and byte_size(iv) == 16 do
    plaintext = :crypto.crypto_one_time(:aes_256_cbc, key, iv, ciphertext, false)
    pkcs7_unpad(plaintext)
  end

  @doc """
  Compute index MAC: HMAC-SHA256(index_key, index_json).

  Matches whatsmeow `concatAndHMAC(sha256.New, keys.Index, indexBytes)` in `encode.go:300`.
  """
  @spec compute_index_mac(binary(), binary()) :: binary()
  def compute_index_mac(index_json, index_key) when is_binary(index_json) and byte_size(index_key) == 32 do
    :crypto.mac(:hmac, :sha256, index_key, index_json)
  end

  @doc """
  Compute content/value MAC: first 32 bytes of HMAC-SHA512.

  Data = operation_byte || key_id || encrypted_content || big_endian_u64(len(key_id)+1)

  Operation byte = SyncdOperation value + 1 (SET=0 → byte 1, REMOVE=1 → byte 2).

  Matches whatsmeow `generateContentMAC()` in `hash.go:94-98`.
  """
  @spec compute_content_mac(non_neg_integer(), binary(), binary(), binary()) :: binary()
  def compute_content_mac(operation, encrypted_content, key_id, mac_key)
      when is_integer(operation) and is_binary(encrypted_content) and is_binary(key_id) and byte_size(mac_key) == 32 do
    operation_byte = <<operation + 1>>
    key_data_length = <<byte_size(key_id) + 1::big-unsigned-64>>

    full_mac =
      :crypto.mac(:hmac, :sha512, mac_key, [
        operation_byte,
        key_id,
        encrypted_content,
        key_data_length
      ])

    binary_part(full_mac, 0, 32)
  end

  @doc """
  Compute snapshot MAC: HMAC-SHA256(snapshot_mac_key, hash_state || version_u64 || collection_name).

  Matches whatsmeow `HashState.generateSnapshotMAC()` in `hash.go:78-80`.
  """
  @spec compute_snapshot_mac(binary(), non_neg_integer(), binary(), binary()) :: binary()
  def compute_snapshot_mac(hash_state, version, collection_name, snapshot_mac_key)
      when byte_size(hash_state) == 128 and is_integer(version) and is_binary(collection_name) and byte_size(snapshot_mac_key) == 32 do
    :crypto.mac(:hmac, :sha256, snapshot_mac_key, [
      hash_state,
      <<version::big-unsigned-64>>,
      collection_name
    ])
  end

  @doc """
  Compute patch MAC: HMAC-SHA256(patch_mac_key, snapshot_mac || value_macs... || version_u64 || collection_name).

  Matches whatsmeow `generatePatchMAC()` in `hash.go:82-92`.
  """
  @spec compute_patch_mac(binary(), [binary()], non_neg_integer(), binary(), binary()) :: binary()
  def compute_patch_mac(snapshot_mac, value_macs, version, collection_name, patch_mac_key)
      when is_binary(snapshot_mac) and is_list(value_macs) and is_integer(version) and is_binary(collection_name) and
             byte_size(patch_mac_key) == 32 do
    data = [snapshot_mac | value_macs] ++ [<<version::big-unsigned-64>>, collection_name]
    :crypto.mac(:hmac, :sha256, patch_mac_key, data)
  end

  # HKDF-SHA256 extract-then-expand
  defp hkdf_sha256(ikm, salt, info, length) do
    salt = if salt == <<>> or salt == nil, do: :binary.copy(<<0>>, 32), else: salt
    prk = :crypto.mac(:hmac, :sha256, salt, ikm)
    hkdf_expand(prk, info, length)
  end

  defp hkdf_expand(prk, info, length) do
    n = ceil(length / 32)

    {output, _} =
      Enum.reduce(1..n, {<<>>, <<>>}, fn i, {acc, prev} ->
        t = :crypto.mac(:hmac, :sha256, prk, prev <> info <> <<i::8>>)
        {acc <> t, t}
      end)

    binary_part(output, 0, length)
  end

  defp pkcs7_pad(data) do
    block_size = 16
    pad_len = block_size - rem(byte_size(data), block_size)
    data <> :binary.copy(<<pad_len::8>>, pad_len)
  end

  defp pkcs7_unpad(data) when byte_size(data) > 0 do
    pad_len = :binary.last(data)

    cond do
      pad_len == 0 or pad_len > byte_size(data) ->
        {:error, :invalid_padding}

      true ->
        {:ok, binary_part(data, 0, byte_size(data) - pad_len)}
    end
  end

  defp pkcs7_unpad(_), do: {:error, :empty_data}
end
