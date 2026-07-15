defmodule ExWapp.Signal.Crypto do
  @moduledoc false

  alias ExWapp.Signal.WireFormat

  @hash_size 32

  @spec derive_secrets(binary(), binary(), binary(), pos_integer()) :: [binary()]
  def derive_secrets(input_key_material, salt, info, chunks)
      when is_binary(input_key_material) and is_binary(salt) and is_binary(info) and
             is_integer(chunks) and chunks in 1..255 do
    salt = if salt == <<>>, do: :binary.copy(<<0>>, @hash_size), else: salt
    pseudo_random_key = hmac_sha256(salt, input_key_material)

    1..chunks
    |> Enum.reduce({[], <<>>}, fn index, {output, previous} ->
      block = hmac_sha256(pseudo_random_key, previous <> info <> <<index>>)
      {[block | output], block}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  @spec hmac_sha256(binary(), iodata()) :: binary()
  def hmac_sha256(key, data) when is_binary(key),
    do: :crypto.mac(:hmac, :sha256, key, data)

  @spec aes_cbc_encrypt(binary(), binary(), binary()) :: binary()
  def aes_cbc_encrypt(key, plaintext, iv),
    do: WireFormat.encrypt_aes_cbc(plaintext, key, iv)

  @spec aes_cbc_decrypt(binary(), binary(), binary()) ::
          {:ok, binary()} | {:error, term()}
  def aes_cbc_decrypt(key, ciphertext, iv),
    do: WireFormat.decrypt_aes_cbc(ciphertext, key, iv)
end
