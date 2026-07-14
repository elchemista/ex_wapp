defmodule ExWapp.Signal.WireFormatTest do
  use ExUnit.Case, async: true

  alias ExWapp.Signal.WireFormat

  describe "public keys and varints" do
    test "serializes and deserializes Curve25519 public keys" do
      key = :crypto.hash(:sha256, "curve key")
      serialized = <<5, key::binary>>

      assert WireFormat.serialize_public_key(key) == serialized
      assert WireFormat.serialize_public_key(serialized) == serialized
      assert {:ok, ^key} = WireFormat.deserialize_public_key(serialized)
      assert {:ok, ^key} = WireFormat.deserialize_public_key(key)
      assert {:error, :invalid_key_format} =
               WireFormat.deserialize_public_key(<<4, key::binary>>)

      assert {:error, :invalid_key_format} =
               WireFormat.deserialize_public_key(:binary.copy(<<0>>, 31))
    end

    test "encodes protobuf varint boundaries" do
      assert WireFormat.encode_varint(0) == <<0>>
      assert WireFormat.encode_varint(1) == <<1>>
      assert WireFormat.encode_varint(127) == <<0x7F>>
      assert WireFormat.encode_varint(128) == <<0x80, 0x01>>
      assert WireFormat.encode_varint(300) == <<0xAC, 0x02>>
      assert WireFormat.encode_varint(16_384) == <<0x80, 0x80, 0x01>>
      assert WireFormat.encode_varint(0xFFFF_FFFF) == <<0xFF, 0xFF, 0xFF, 0xFF, 0x0F>>
    end
  end

  describe "SignalMessage" do
    test "serialize/parse preserves protocol fields and produces a valid MAC" do
      fixture = signal_fixture()
      assert {:ok, parsed} = WireFormat.parse_signal_message(fixture.serialized)

      assert parsed.version_byte == 0x33
      assert parsed.ratchet_key == fixture.ratchet_key
      assert parsed.counter == 300
      assert parsed.previous_counter == 7
      assert parsed.ciphertext == fixture.ciphertext
      assert byte_size(parsed.mac) == 8

      assert WireFormat.valid_signal_mac?(
               parsed.mac,
               fixture.mac_key,
               fixture.sender_identity,
               fixture.receiver_identity,
               parsed.version_and_proto
             )
    end

    test "MAC verification rejects tampering and malformed identities" do
      fixture = signal_fixture()
      {:ok, parsed} = WireFormat.parse_signal_message(fixture.serialized)
      <<first, rest::binary>> = parsed.mac
      tampered_mac = <<Bitwise.bxor(first, 1), rest::binary>>

      refute WireFormat.valid_signal_mac?(
               tampered_mac,
               fixture.mac_key,
               fixture.sender_identity,
               fixture.receiver_identity,
               parsed.version_and_proto
             )

      refute WireFormat.valid_signal_mac?(
               parsed.mac,
               fixture.mac_key,
               :binary.copy(<<0>>, 31),
               fixture.receiver_identity,
               parsed.version_and_proto
             )
    end
  end

  describe "PreKeySignalMessage" do
    test "serialize/parse preserves a one-time prekey id" do
      base_key = :crypto.hash(:sha256, "base")
      identity_key = :crypto.hash(:sha256, "identity")
      inner_message = "serialized SignalMessage"

      serialized =
        WireFormat.serialize_prekey_signal_message(
          4_294_967_295,
          300,
          16_384,
          base_key,
          identity_key,
          inner_message
        )

      assert {:ok, parsed} = WireFormat.parse_prekey_signal_message(serialized)
      assert parsed.version_byte == 0x33
      assert parsed.registration_id == 4_294_967_295
      assert parsed.prekey_id == 300
      assert parsed.signed_prekey_id == 16_384
      assert parsed.base_key == base_key
      assert parsed.identity_key == identity_key
      assert parsed.message == inner_message
    end

    test "omits an absent or zero one-time prekey id" do
      base_key = :crypto.hash(:sha256, "base")
      identity_key = :crypto.hash(:sha256, "identity")

      for prekey_id <- [nil, 0] do
        serialized =
          WireFormat.serialize_prekey_signal_message(
            0,
            prekey_id,
            0,
            base_key,
            identity_key,
            "inner"
          )

        assert {:ok, %{prekey_id: nil, registration_id: 0, signed_prekey_id: 0}} =
                 WireFormat.parse_prekey_signal_message(serialized)
      end
    end
  end

  describe "version and parser failures" do
    test "classifies current, unknown and invalid messages" do
      assert WireFormat.message_type(<<0x33>>) == :signal_message
      assert WireFormat.message_type(<<0x23>>) == {:unknown_version, 2}
      assert WireFormat.message_type(<<>>) == :invalid
    end

    test "returns explicit errors for short, unknown-version and malformed payloads" do
      assert {:error, :invalid_signal_message} = WireFormat.parse_signal_message(<<>>)

      assert {:error, :invalid_signal_message} =
               WireFormat.parse_signal_message(<<0x33>> <> :binary.copy(<<0>>, 8))

      assert {:error, {:unknown_version, 2}} =
               WireFormat.parse_signal_message(<<0x23>> <> :binary.copy(<<0>>, 9))

      assert {:error, :invalid_prekey_signal_message} =
               WireFormat.parse_prekey_signal_message(<<>>)

      assert {:error, {:unknown_version, 2}} =
               WireFormat.parse_prekey_signal_message(<<0x23>>)

      assert {:error, _reason} = WireFormat.parse_prekey_signal_message(<<0x33, 0x80>>)
    end
  end

  describe "AES-CBC payloads" do
    test "round-trips empty, block-boundary and multi-block plaintext" do
      key = :crypto.hash(:sha256, "cipher key")
      iv = binary_part(:crypto.hash(:sha256, "iv"), 0, 16)

      for plaintext <- [
            <<>>,
            <<1>>,
            :binary.copy(<<0xA5>>, 15),
            :binary.copy(<<0xA5>>, 16),
            :binary.copy(<<0xA5>>, 17),
            :binary.copy(<<0xA5>>, 256)
          ] do
        ciphertext = WireFormat.encrypt_aes_cbc(plaintext, key, iv)
        assert rem(byte_size(ciphertext), 16) == 0
        assert {:ok, ^plaintext} = WireFormat.decrypt_aes_cbc(ciphertext, key, iv)
      end
    end

    test "rejects inconsistent or oversized PKCS7 padding" do
      key = :crypto.hash(:sha256, "cipher key")
      iv = binary_part(:crypto.hash(:sha256, "iv"), 0, 16)

      inconsistent = :binary.copy(<<0x41>>, 14) <> <<1, 2>>
      inconsistent_cipher = :crypto.crypto_one_time(:aes_256_cbc, key, iv, inconsistent, true)

      assert {:error, :invalid_padding} =
               WireFormat.decrypt_aes_cbc(inconsistent_cipher, key, iv)

      oversized = :binary.copy(<<0x41>>, 15) <> :binary.copy(<<17>>, 17)
      oversized_cipher = :crypto.crypto_one_time(:aes_256_cbc, key, iv, oversized, true)

      assert {:error, :invalid_padding} =
               WireFormat.decrypt_aes_cbc(oversized_cipher, key, iv)
    end

    test "rejects empty, non-block-aligned and wrongly-sized parameters" do
      key = :crypto.hash(:sha256, "cipher key")
      iv = binary_part(:crypto.hash(:sha256, "iv"), 0, 16)

      assert {:error, :invalid_ciphertext} = WireFormat.decrypt_aes_cbc(<<>>, key, iv)

      assert {:error, :invalid_ciphertext} =
               WireFormat.decrypt_aes_cbc(:binary.copy(<<0>>, 15), key, iv)

      assert {:error, :invalid_ciphertext} =
               WireFormat.decrypt_aes_cbc(:binary.copy(<<0>>, 16), <<0>>, iv)

      assert {:error, :invalid_ciphertext} =
               WireFormat.decrypt_aes_cbc(:binary.copy(<<0>>, 16), key, <<0>>)
    end
  end

  defp signal_fixture do
    ratchet_key = :crypto.hash(:sha256, "ratchet")
    mac_key = :crypto.hash(:sha256, "mac")
    sender_identity = :crypto.hash(:sha256, "sender")
    receiver_identity = :crypto.hash(:sha256, "receiver")
    ciphertext = :crypto.hash(:sha256, "ciphertext")

    serialized =
      WireFormat.serialize_signal_message(
        ratchet_key,
        300,
        7,
        ciphertext,
        mac_key,
        sender_identity,
        receiver_identity
      )

    %{
      serialized: serialized,
      ratchet_key: ratchet_key,
      mac_key: mac_key,
      sender_identity: sender_identity,
      receiver_identity: receiver_identity,
      ciphertext: ciphertext
    }
  end
end
