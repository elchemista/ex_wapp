defmodule ExWapp.AppState.CryptoTest do
  use ExUnit.Case, async: true

  alias ExWapp.AppState.Crypto

  describe "expand_keys/1" do
    test "produces 5 distinct 32-byte keys from 32-byte input" do
      key_data = :crypto.strong_rand_bytes(32)
      keys = Crypto.expand_keys(key_data)

      assert byte_size(keys.index) == 32
      assert byte_size(keys.value_encryption) == 32
      assert byte_size(keys.value_mac) == 32
      assert byte_size(keys.snapshot_mac) == 32
      assert byte_size(keys.patch_mac) == 32

      # All keys should be different
      all_keys = [
        keys.index,
        keys.value_encryption,
        keys.value_mac,
        keys.snapshot_mac,
        keys.patch_mac
      ]

      assert length(Enum.uniq(all_keys)) == 5
    end

    test "deterministic: same input produces same output" do
      key_data = :crypto.strong_rand_bytes(32)
      assert Crypto.expand_keys(key_data) == Crypto.expand_keys(key_data)
    end
  end

  describe "encrypt_cbc/decrypt_cbc round-trip" do
    test "encrypt then decrypt returns original plaintext" do
      key = :crypto.strong_rand_bytes(32)
      plaintext = "Hello, WhatsApp App State Sync!"

      {iv, ciphertext} = Crypto.encrypt_cbc(plaintext, key)
      assert byte_size(iv) == 16
      assert ciphertext != plaintext

      assert {:ok, ^plaintext} = Crypto.decrypt_cbc(ciphertext, key, iv)
    end

    test "encrypt with explicit IV" do
      key = :crypto.strong_rand_bytes(32)
      iv = :binary.copy(<<0>>, 16)
      plaintext = "test data"

      {^iv, ciphertext} = Crypto.encrypt_cbc(plaintext, key, iv)
      assert {:ok, ^plaintext} = Crypto.decrypt_cbc(ciphertext, key, iv)
    end

    test "handles empty string" do
      key = :crypto.strong_rand_bytes(32)
      {iv, ciphertext} = Crypto.encrypt_cbc("", key)
      assert {:ok, ""} = Crypto.decrypt_cbc(ciphertext, key, iv)
    end

    test "handles multi-block plaintext" do
      key = :crypto.strong_rand_bytes(32)
      plaintext = :crypto.strong_rand_bytes(256)
      {iv, ciphertext} = Crypto.encrypt_cbc(plaintext, key)
      assert {:ok, ^plaintext} = Crypto.decrypt_cbc(ciphertext, key, iv)
    end
  end

  describe "compute_index_mac/2" do
    test "produces 32-byte HMAC-SHA256" do
      index_key = :crypto.strong_rand_bytes(32)
      index_json = ~s(["mute","15550001111@s.whatsapp.net"])

      mac = Crypto.compute_index_mac(index_json, index_key)
      assert byte_size(mac) == 32
    end

    test "deterministic" do
      key = :crypto.strong_rand_bytes(32)
      data = "test"
      assert Crypto.compute_index_mac(data, key) == Crypto.compute_index_mac(data, key)
    end
  end

  describe "compute_content_mac/4" do
    test "produces 32-byte MAC (first 32 bytes of HMAC-SHA512)" do
      mac_key = :crypto.strong_rand_bytes(32)
      key_id = :crypto.strong_rand_bytes(16)
      content = :crypto.strong_rand_bytes(64)

      # SET operation = 0
      mac = Crypto.compute_content_mac(0, content, key_id, mac_key)
      assert byte_size(mac) == 32

      # REMOVE operation = 1
      mac2 = Crypto.compute_content_mac(1, content, key_id, mac_key)
      assert byte_size(mac2) == 32
      assert mac != mac2
    end
  end

  describe "compute_snapshot_mac/4" do
    test "produces 32-byte HMAC-SHA256" do
      hash_state = :binary.copy(<<0>>, 128)
      key = :crypto.strong_rand_bytes(32)

      mac = Crypto.compute_snapshot_mac(hash_state, 42, "regular_low", key)
      assert byte_size(mac) == 32
    end
  end

  describe "compute_patch_mac/5" do
    test "produces 32-byte HMAC-SHA256" do
      snapshot_mac = :crypto.strong_rand_bytes(32)
      value_macs = [:crypto.strong_rand_bytes(32), :crypto.strong_rand_bytes(32)]
      key = :crypto.strong_rand_bytes(32)

      mac = Crypto.compute_patch_mac(snapshot_mac, value_macs, 42, "regular_low", key)
      assert byte_size(mac) == 32
    end
  end
  describe "reference compatibility" do
    test "key expansion matches the HKDF slices directly" do
      key_data = :crypto.hash(:sha256, "app-state-key")
      expanded = hkdf_160(key_data)
      keys = Crypto.expand_keys(key_data)

      assert keys.index == binary_part(expanded, 0, 32)
      assert keys.value_encryption == binary_part(expanded, 32, 32)
      assert keys.value_mac == binary_part(expanded, 64, 32)
      assert keys.snapshot_mac == binary_part(expanded, 96, 32)
      assert keys.patch_mac == binary_part(expanded, 128, 32)
    end

    test "content MAC matches the WhatsApp field ordering" do
      mac_key = :crypto.hash(:sha256, "content-mac-key")
      key_id = <<1, 2, 3, 4>>
      encrypted = "encrypted mutation"
      key_data_length = <<byte_size(key_id) + 1::big-unsigned-64>>

      expected =
        :crypto.mac(
          :hmac,
          :sha512,
          mac_key,
          [<<1>>, key_id, encrypted, key_data_length]
        )
        |> binary_part(0, 32)

      assert Crypto.compute_content_mac(0, encrypted, key_id, mac_key) == expected
    end

    test "snapshot MAC matches the explicit HMAC input" do
      hash_state = :binary.copy(<<0xA5>>, 128)
      key = :crypto.hash(:sha256, "snapshot-key")
      version = 0x0102_0304
      collection = "regular_low"

      expected =
        :crypto.mac(
          :hmac,
          :sha256,
          key,
          [hash_state, <<version::big-unsigned-64>>, collection]
        )

      assert Crypto.compute_snapshot_mac(hash_state, version, collection, key) == expected
    end

    test "patch MAC preserves value-MAC ordering" do
      snapshot = :crypto.hash(:sha256, "snapshot")
      value_macs = [
        :crypto.hash(:sha256, "first"),
        :crypto.hash(:sha256, "second")
      ]

      key = :crypto.hash(:sha256, "patch-key")
      version = 7
      collection = "regular"

      expected =
        :crypto.mac(
          :hmac,
          :sha256,
          key,
          [snapshot | value_macs] ++ [<<version::big-unsigned-64>>, collection]
        )

      assert Crypto.compute_patch_mac(snapshot, value_macs, version, collection, key) == expected

      refute Crypto.compute_patch_mac(
               snapshot,
               Enum.reverse(value_macs),
               version,
               collection,
               key
             ) == expected
    end
  end

  describe "PKCS7 validation" do
    test "rejects padding whose bytes do not match its length" do
      key = :crypto.hash(:sha256, "cbc-key")
      iv = :binary.copy(<<0>>, 16)
      invalid_plaintext = :binary.copy(<<0x41>>, 14) <> <<1, 2>>
      ciphertext = :crypto.crypto_one_time(:aes_256_cbc, key, iv, invalid_plaintext, true)

      assert {:error, :invalid_padding} = Crypto.decrypt_cbc(ciphertext, key, iv)
    end

    test "rejects padding longer than one AES block" do
      key = :crypto.hash(:sha256, "cbc-key")
      iv = :binary.copy(<<0>>, 16)
      invalid_plaintext = :binary.copy(<<0x41>>, 15) <> :binary.copy(<<17>>, 17)
      ciphertext = :crypto.crypto_one_time(:aes_256_cbc, key, iv, invalid_plaintext, true)

      assert {:error, :invalid_padding} = Crypto.decrypt_cbc(ciphertext, key, iv)
    end
  end

  defp hkdf_160(key_data) do
    salt = :binary.copy(<<0>>, 32)
    prk = :crypto.mac(:hmac, :sha256, salt, key_data)

    {output, _previous} =
      Enum.reduce(1..5, {<<>>, <<>>}, fn index, {acc, previous} ->
        block =
          :crypto.mac(
            :hmac,
            :sha256,
            prk,
            previous <> "WhatsApp Mutation Keys" <> <<index>>
          )

        {acc <> block, block}
      end)

    output
  end

end
