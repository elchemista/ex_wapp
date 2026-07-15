defmodule ExWapp.SignalCryptoFixtureTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Signal.Crypto

  @vectors Path.expand("fixtures/protocol/signal_crypto_vectors.fixture", __DIR__)
           |> Code.eval_file()
           |> elem(0)

  test "HKDF-SHA256 matches libsignal for one through three chunks" do
    for vector <- @vectors.derive do
      expected = Enum.map(vector.output, &hex!/1)

      assert Crypto.derive_secrets(
               hex!(vector.input),
               hex!(vector.salt),
               hex!(vector.info),
               length(expected)
             ) == expected
    end
  end

  test "HMAC-SHA256 matches libsignal" do
    vector = @vectors.mac
    assert Crypto.hmac_sha256(hex!(vector.key), hex!(vector.data)) == hex!(vector.output)
  end

  test "AES-CBC with PKCS7 padding matches libsignal" do
    vector = @vectors.cbc
    key = hex!(vector.key)
    iv = hex!(vector.iv)
    plaintext = hex!(vector.plaintext)

    assert Crypto.aes_cbc_encrypt(key, plaintext, iv) == hex!(vector.ciphertext)
    assert Crypto.aes_cbc_decrypt(key, hex!(vector.ciphertext), iv) == {:ok, plaintext}
  end

  defp hex!(value), do: Base.decode16!(value, case: :lower)
end
