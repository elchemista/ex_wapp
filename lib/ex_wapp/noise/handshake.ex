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

  @doc """
  Initializes a Noise handshake state with the provided protocol pattern and header.
  """
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

  @doc """
  Mixes additional authenticated data into the running handshake hash.
  """
  @spec authenticate(t(), binary()) :: t()
  def authenticate(%__MODULE__{} = state, data) when is_binary(data) do
    %{state | hash: sha256(state.hash <> data)}
  end

  @doc """
  Encrypts a handshake payload using the current key and updates hash/counter.
  """
  @spec encrypt(t(), binary()) :: {t(), binary()}
  def encrypt(%__MODULE__{} = state, plaintext) when is_binary(plaintext) do
    iv = generate_iv(state.counter)

    {cipher, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, state.key, iv, plaintext, state.hash, true)

    payload = cipher <> tag
    new_hash = sha256(state.hash <> payload)
    {%{state | hash: new_hash, counter: state.counter + 1}, payload}
  end

  @doc """
  Decrypts a handshake payload and updates hash/counter on success.
  """
  @spec decrypt(t(), binary()) :: {:ok, t(), binary()} | {:error, term()}
  def decrypt(%__MODULE__{} = _state, ciphertext)
      when is_binary(ciphertext) and byte_size(ciphertext) < @tag_size,
      do: {:error, :ciphertext_too_short}

  def decrypt(%__MODULE__{} = state, ciphertext) when is_binary(ciphertext) do
    total = byte_size(ciphertext)
    body_size = total - @tag_size
    <<body::binary-size(^body_size), tag::binary-size(@tag_size)>> = ciphertext
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

  @doc """
  Mixes a Curve25519 shared secret into the handshake key schedule.
  """
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

  @doc """
  Derives a new handshake key/salt pair from input key material.
  """
  @spec mix_into_key(t(), binary()) :: t()
  def mix_into_key(%__MODULE__{} = state, data) when is_binary(data) do
    <<write::binary-size(32), read::binary-size(32)>> = hkdf(state.salt, data)
    %{state | salt: write, key: read, counter: 0}
  end

  @doc """
  Derives transport write/read keys from the current handshake salt.
  """
  @spec derive_transport_keys(t()) :: {binary(), binary()}
  def derive_transport_keys(%__MODULE__{} = state) do
    <<write::binary-size(32), read::binary-size(32)>> = hkdf(state.salt, <<>>)
    {write, read}
  end

  @spec generate_iv(non_neg_integer()) :: binary()
  defp generate_iv(counter) do
    <<0::size((@iv_size - 4) * 8), counter::32>>
  end

  @spec sha256(binary()) :: binary()
  defp sha256(data), do: :crypto.hash(:sha256, data)

  @spec hkdf(binary(), binary()) :: binary()
  defp hkdf(salt, key_material) do
    prk = :crypto.mac(:hmac, :sha256, salt, key_material)

    t1 = :crypto.mac(:hmac, :sha256, prk, <<1>>)
    t2 = :crypto.mac(:hmac, :sha256, prk, t1 <> <<2>>)

    <<t1::binary-size(32), t2::binary-size(32)>>
  end
end
