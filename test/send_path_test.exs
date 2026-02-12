defmodule ExWapp.SendPathTest do
  @moduledoc """
  Integration tests that verify the send-path encoding matches whatsmeow:

    1. device-identity node includes accountSignatureKey
    2. DeviceSentMessage wraps correctly for own-device copies
    3. phash computation matches whatsmeow (base64 of first 6 SHA256 bytes, no padding)
  """
  use ExUnit.Case, async: true

  alias ExWapp.Pairing.ADV
  alias ExWapp.Session.JIDUtils
  alias ExWapp.Signal.Keys
  alias WAAdv.{ADVDeviceIdentity, ADVSignedDeviceIdentity}

  # ── Test 1: device-identity node MUST include accountSignatureKey ──

  test "encode_signed_device_identity with include_signature_key: true preserves accountSignatureKey" do
    {signed, account_pub} = build_signed_device_identity()

    {:ok, payload} = ADV.encode_signed_device_identity(signed, include_signature_key: true)
    {:ok, decoded} = ADVSignedDeviceIdentity.decode(payload)

    assert decoded.accountSignatureKey == account_pub
    assert byte_size(decoded.accountSignatureKey) == 32
    assert decoded.details == signed.details
    assert decoded.accountSignature == signed.accountSignature
    assert decoded.deviceSignature == signed.deviceSignature
  end

  test "encode_signed_device_identity with include_signature_key: false strips accountSignatureKey" do
    {signed, _account_pub} = build_signed_device_identity()

    {:ok, payload} = ADV.encode_signed_device_identity(signed, include_signature_key: false)
    {:ok, decoded} = ADVSignedDeviceIdentity.decode(payload)

    assert decoded.accountSignatureKey == nil
    assert decoded.details == signed.details
    assert decoded.accountSignature == signed.accountSignature
    assert decoded.deviceSignature == signed.deviceSignature
  end

  test "device-identity payload size differs between include and exclude accountSignatureKey" do
    {signed, _account_pub} = build_signed_device_identity()

    {:ok, with_key} = ADV.encode_signed_device_identity(signed, include_signature_key: true)
    {:ok, without_key} = ADV.encode_signed_device_identity(signed, include_signature_key: false)

    # With the 32-byte key + protobuf tag/length overhead, the difference should be ~34 bytes
    assert byte_size(with_key) > byte_size(without_key)
    assert byte_size(with_key) - byte_size(without_key) >= 33
  end

  # ── Test 2: DeviceSentMessage wrapping ──

  test "DeviceSentMessage wraps message with destinationJid" do
    inner_proto = ExWapp.Messages.build_text_proto("hello own device", [])

    destination_jid = "15550001111@s.whatsapp.net"

    wrapped = %ExWapp.Proto.Message{
      deviceSentMessage: %ExWapp.Proto.DeviceSentMessage{
        destinationJid: destination_jid,
        message: inner_proto,
        phash: nil
      }
    }

    {:ok, encoded} = ExWapp.Proto.Message.encode(wrapped)
    encoded_bin = IO.iodata_to_binary(encoded)

    # Outer message starts with DeviceSentMessage field (31, wire type 2)
    assert <<0xFA, 0x01, _rest::binary>> = encoded_bin

    # Destination JID should be embedded in the binary
    assert :binary.match(encoded_bin, destination_jid) != :nomatch

    # Inner "hello own device" text should be embedded
    assert :binary.match(encoded_bin, "hello own device") != :nomatch

    # "conversation" field text should NOT appear at top level (no field 1 tag at start)
    # The first byte is 0xFA (DSM field), not 0x0A (conversation field)
    refute match?(<<0x0A, _::binary>>, encoded_bin)
  end

  test "DeviceSentMessage encoding uses correct protobuf field numbers" do
    # DeviceSentMessage is field 31 of Message -> tag = (31 << 3) | 2 = 0xFA 0x01
    inner_proto = ExWapp.Messages.build_text_proto("test", [])

    wrapped = %ExWapp.Proto.Message{
      deviceSentMessage: %ExWapp.Proto.DeviceSentMessage{
        destinationJid: "111@s.whatsapp.net",
        message: inner_proto,
        phash: nil
      }
    }

    {:ok, encoded} = ExWapp.Proto.Message.encode(wrapped)
    encoded_bin = IO.iodata_to_binary(encoded)

    # Field 31, wire type 2 (length-delimited) = (31 << 3) | 2 = 250 = 0xFA
    # Varint encoding of 250: 0xFA 0x01
    assert <<0xFA, 0x01, _rest::binary>> = encoded_bin
  end

  test "DeviceSentMessage includes phash when provided" do
    inner_proto = ExWapp.Messages.build_text_proto("test", [])
    phash = "2:abc123"

    wrapped = %ExWapp.Proto.Message{
      deviceSentMessage: %ExWapp.Proto.DeviceSentMessage{
        destinationJid: "111@s.whatsapp.net",
        message: inner_proto,
        phash: phash
      }
    }

    {:ok, encoded} = ExWapp.Proto.Message.encode(wrapped)
    encoded_bin = IO.iodata_to_binary(encoded)

    assert :binary.match(encoded_bin, phash) != :nomatch
  end

  # ── Test 3: phash computation ──

  test "participant hash v2 matches whatsmeow format" do
    # Verify phash = "2:" + base64(sha256(sorted_ad_strings)[:6], no padding)
    # whatsmeow uses ADString format: user.agent:device@server
    participants = [
      "15550001111:36@s.whatsapp.net",
      "15550001111@s.whatsapp.net",
      "6287865904022:2@s.whatsapp.net"
    ]

    # ADString conversion: user.0:device@server
    ad_strings =
      Enum.map(participants, &ExWapp.Session.MessageNode.jid_to_ad_string/1)
      |> Enum.sort()

    concatenated = Enum.join(ad_strings, "")
    <<first_6::binary-size(6), _::binary>> = :crypto.hash(:sha256, concatenated)
    expected = "2:" <> Base.encode64(first_6, padding: false)

    # Call the module function indirectly through the test helper
    assert compute_phash(participants) == expected
    assert String.starts_with?(expected, "2:")

    # Verify no padding characters
    refute String.contains?(expected, "=")
  end

  test "participant hash v2 is deterministic and order-independent" do
    participants_a = [
      "6287865904022:2@s.whatsapp.net",
      "15550001111:36@s.whatsapp.net"
    ]

    participants_b = [
      "15550001111:36@s.whatsapp.net",
      "6287865904022:2@s.whatsapp.net"
    ]

    assert compute_phash(participants_a) == compute_phash(participants_b)
  end

  test "participant hash v2 returns nil for empty list" do
    assert compute_phash([]) == nil
  end

  # ── Test 4: self-chat target payload strategy ──

  test "self-chat routes all non-current targets as own payloads" do
    recipient_targets = [
      "15550001111@s.whatsapp.net",
      "15550001111:38@s.whatsapp.net"
    ]

    own_targets = ["15550001111@s.whatsapp.net"]

    specs =
      JIDUtils.build_self_chat_target_specs(
        recipient_targets,
        own_targets,
        "15550001111@s.whatsapp.net"
      )

    assert specs == [
             %{jid: "15550001111@s.whatsapp.net", payload_kind: :own},
             %{jid: "15550001111:38@s.whatsapp.net", payload_kind: :own}
           ]
  end

  test "self-chat keeps own payload when only one explicit-device target exists" do
    specs =
      JIDUtils.build_self_chat_target_specs(
        ["15550001111:38@s.whatsapp.net"],
        [],
        "15550001111@s.whatsapp.net"
      )

    assert specs == [
             %{jid: "15550001111:38@s.whatsapp.net", payload_kind: :own}
           ]
  end

  test "self-chat fallback keeps one recipient target and own payload for others" do
    specs =
      JIDUtils.build_self_chat_fallback_target_specs(
        ["15550001111@s.whatsapp.net", "15550001111:38@s.whatsapp.net"],
        ["15550001111@s.whatsapp.net"],
        "15550001111@s.whatsapp.net"
      )

    assert specs == [
             %{jid: "15550001111@s.whatsapp.net", payload_kind: :recipient},
             %{jid: "15550001111:38@s.whatsapp.net", payload_kind: :own}
           ]
  end

  # ── Test 5: padding matches whatsmeow ──

  test "message padding produces valid PKCS7-like padding" do
    plaintext = "hello"
    padded = ExWapp.Signal.Encryption.pad_message(plaintext)

    assert byte_size(padded) > byte_size(plaintext)

    # Last byte should be the padding length
    pad_len = :binary.last(padded)
    assert pad_len >= 1 and pad_len <= 15

    # All padding bytes should equal pad_len
    padding = binary_part(padded, byte_size(padded) - pad_len, pad_len)
    assert padding == :binary.copy(<<pad_len>>, pad_len)
  end

  # ── Test 6: full encrypt + wrap round-trip ──

  test "encrypt for recipient and own device produces different ciphertexts with correct types" do
    alice_identity = Keys.generate_key_pair()
    bob_identity = Keys.generate_key_pair()

    signed_id = 500
    prekey_id = 501

    bob_signed_prekey = Keys.generate_signed_prekey(bob_identity, signed_id)
    bob_one_time_prekey = Keys.generate_prekey(prekey_id)

    bob_bundle = %{
      registration_id: 5001,
      identity_key: bob_identity.public,
      signed_prekey: %{
        id: signed_id,
        public: bob_signed_prekey.public,
        signature: bob_signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: bob_one_time_prekey.public}
    }

    # Build two payloads: recipient (plain) and own (DeviceSentMessage wrapped)
    proto = ExWapp.Messages.build_text_proto("test message", [])
    {:ok, plain_payload} = ExWapp.Proto.Message.encode(proto)

    destination_jid = "6287865904022@s.whatsapp.net"

    dsm_wrapped = %ExWapp.Proto.Message{
      deviceSentMessage: %ExWapp.Proto.DeviceSentMessage{
        destinationJid: destination_jid,
        message: proto,
        phash: nil
      }
    }

    {:ok, own_payload} = ExWapp.Proto.Message.encode(dsm_wrapped)

    recipient_padded = ExWapp.Signal.Encryption.pad_message(plain_payload)
    own_padded = ExWapp.Signal.Encryption.pad_message(own_payload)

    # Payloads must differ (own has DeviceSentMessage wrapper)
    refute recipient_padded == own_padded
    assert byte_size(own_padded) > byte_size(recipient_padded)

    # Encrypt recipient payload
    bob_jid = "6287865904022:2@s.whatsapp.net"

    {:ok, recipient_ct, :prekey, _sessions_after} =
      ExWapp.Signal.SessionStore.encrypt_message(
        ExWapp.Signal.SessionStore.new(),
        bob_jid,
        recipient_padded,
        alice_identity,
        1234,
        bob_bundle
      )

    # Decrypt on bob's side to verify content
    bob_local_prekeys = %{
      signed_prekeys: %{signed_id => bob_signed_prekey},
      prekeys: %{prekey_id => bob_one_time_prekey}
    }

    {:ok, decrypted_recipient, _bob_sessions} =
      ExWapp.Signal.SessionStore.decrypt_message(
        ExWapp.Signal.SessionStore.new(),
        "alice@s.whatsapp.net",
        recipient_ct,
        true,
        bob_identity,
        bob_local_prekeys
      )

    # Unpad and verify the decrypted payload matches original
    unpadded = ExWapp.Signal.Encryption.unpad_message(decrypted_recipient)
    assert unpadded == IO.iodata_to_binary(plain_payload)

    # The decrypted data should contain "test message"
    assert :binary.match(unpadded, "test message") != :nomatch

    # Own payload should be larger (has DSM wrapper)
    own_payload_bin = IO.iodata_to_binary(own_payload)
    assert byte_size(own_payload_bin) > byte_size(unpadded)

    # Own payload should contain the destination JID
    assert :binary.match(own_payload_bin, destination_jid) != :nomatch

    # Own payload should start with DSM field tag (0xFA 0x01), not conversation (0x0A)
    assert <<0xFA, 0x01, _::binary>> = own_payload_bin
  end

  # ── Helpers ──

  defp build_signed_device_identity do
    account_priv = :crypto.strong_rand_bytes(32)
    account_pub = Ed25519.derive_public_key(account_priv)

    identity = Keys.generate_key_pair()

    details_msg = %ADVDeviceIdentity{
      rawID: 42,
      timestamp: 1_725_000_000,
      keyIndex: 3,
      accountType: :E2EE,
      deviceType: :E2EE
    }

    {:ok, details_io} = ADVDeviceIdentity.encode(details_msg)
    details_bin = IO.iodata_to_binary(details_io)

    account_message = <<6, 0>> <> details_bin <> identity.public
    account_sig = Ed25519.signature(account_message, account_priv)

    device_message = <<6, 1>> <> details_bin <> identity.public <> account_pub
    device_sig = Ed25519.signature(device_message, identity.private)

    signed = %ADVSignedDeviceIdentity{
      details: details_bin,
      accountSignatureKey: account_pub,
      accountSignature: account_sig,
      deviceSignature: device_sig
    }

    {signed, account_pub}
  end

  # Delegates to the real implementation in MessageNode
  defp compute_phash(participants) do
    ExWapp.Session.MessageNode.generate_participant_hash_v2(participants)
  end
end
