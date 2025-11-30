defmodule ExWapp.Noise.Handshake do
  @moduledoc """
  Implements the Noise_XX handshake primitives used by WhatsApp Web.

  The state mirrors the Go implementation bundled with whatsmeow. It keeps
  track of the running hash, the current AEAD key and the handshake counters.
  """

  @enforce_keys [:hash, :salt, :key, :counter]
  defstruct hash: nil, salt: nil, key: nil, counter: 0

  @type t :: %__MODULE__{
          hash: binary(),
          salt: binary(),
          key: binary(),
          counter: non_neg_integer()
        }

  # Must be exactly 32 bytes to match Go implementation (used directly, not hashed)
  @pattern "Noise_XX_25519_AESGCM_SHA256\x00\x00\x00\x00"
  @iv_size 12
  @tag_size 16

  @spec new(binary(), binary()) :: t()
  def new(pattern \\ @pattern, header \\ <<>>) do
    hash =
      if byte_size(pattern) == 32 do
        pattern
      else
        sha256(pattern)
      end

    %__MODULE__{hash: hash, salt: hash, key: hash, counter: 0}
    |> authenticate(header)
  end

  @spec authenticate(t(), binary()) :: t()
  def authenticate(%__MODULE__{} = state, data) when is_binary(data) do
    %{state | hash: sha256(state.hash <> data)}
  end

  @spec encrypt(t(), binary()) :: {t(), binary()}
  def encrypt(%__MODULE__{} = state, plaintext) when is_binary(plaintext) do
    iv = generate_iv(state.counter)

    {cipher, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, state.key, iv, plaintext, state.hash, true)

    payload = cipher <> tag
    new_hash = sha256(state.hash <> payload)
    {%{state | hash: new_hash, counter: state.counter + 1}, payload}
  end

  @spec decrypt(t(), binary()) :: {:ok, t(), binary()} | {:error, term()}
  def decrypt(%__MODULE__{} = state, ciphertext) when is_binary(ciphertext) do
    total = byte_size(ciphertext)

    if total < @tag_size do
      {:error, :ciphertext_too_short}
    else
      <<body::binary-size(total - @tag_size), tag::binary-size(@tag_size)>> = ciphertext
      iv = generate_iv(state.counter)

      case :crypto.crypto_one_time_aead(:aes_256_gcm, state.key, iv, body, state.hash, tag, false) do
        :error ->
          {:error, :decrypt_failed}

        plaintext ->
          new_hash = sha256(state.hash <> ciphertext)
          new_state = %{state | hash: new_hash, counter: state.counter + 1}
          {:ok, new_state, plaintext}
      end
    end
  end

  @spec mix_shared_secret(t(), binary(), binary()) :: {:ok, t()} | {:error, term()}
  def mix_shared_secret(%__MODULE__{} = state, private_key, public_key)
      when byte_size(private_key) == 32 and byte_size(public_key) == 32 do
    try do
      secret = :crypto.compute_key(:ecdh, public_key, private_key, :x25519)
      {:ok, mix_into_key(state, secret)}
    rescue
      e -> {:error, e}
    end
  end

  @spec mix_into_key(t(), binary()) :: t()
  def mix_into_key(%__MODULE__{} = state, data) when is_binary(data) do
    <<write::binary-size(32), read::binary-size(32)>> = hkdf(state.salt, data)
    %{state | salt: write, key: read, counter: 0}
  end

  @spec derive_transport_keys(t()) :: {binary(), binary()}
  def derive_transport_keys(%__MODULE__{} = state) do
    <<write::binary-size(32), read::binary-size(32)>> = hkdf(state.salt, <<>>)
    {write, read}
  end

  defp generate_iv(counter) do
    <<0::size((@iv_size - 4) * 8), counter::32>>
  end

  defp sha256(data), do: :crypto.hash(:sha256, data)

  defp hkdf(salt, key_material) do
    prk = :crypto.mac(:hmac, :sha256, salt, key_material)

    t1 = :crypto.mac(:hmac, :sha256, prk, <<1>>)
    t2 = :crypto.mac(:hmac, :sha256, prk, t1 <> <<2>>)

    <<t1::binary-size(32), t2::binary-size(32)>>
  end
end
