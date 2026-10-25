defmodule ExWapp.PairingADVTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Pairing.ADV
  alias ExWapp.Signal.Keys
  alias WAAdv.{ADVDeviceIdentity, ADVSignedDeviceIdentity, ADVSignedDeviceIdentityHMAC}

  @adv_prefix_account_signature <<6, 0>>
  @adv_prefix_device_signature_generate <<6, 1>>
  @adv_hosted_prefix_device_identity_account_signature <<6, 5>>

  test "E2EE ADV blob parses, verifies and produces device signature" do
    do_adv_roundtrip(:E2EE)
  end

  test "HOSTED ADV blob parses, verifies and produces device signature" do
    do_adv_roundtrip(:HOSTED)
  end

  test "direct signed identity fallback parses, verifies and produces device signature" do
    do_direct_adv_roundtrip(:E2EE)
    do_direct_adv_roundtrip(:HOSTED)
  end

  test "an explicit HMAC envelope stays authenticated with mismatched or future wire fields" do
    %{blob: blob, adv_secret: secret, identity: identity} = valid_adv_fixture(:E2EE)
    {:ok, container} = ADVSignedDeviceIdentityHMAC.decode(blob)
    {:ok, signed} = ADVSignedDeviceIdentity.decode(container.details)

    # Tag 3 / bytes is the direct identity signature; tag 99 is a future field.
    extra_fields = <<26, 64, signed.accountSignature::binary, 152, 6, 1>>
    assert {:ok, _} = ADV.parse_signed_device_identity(blob <> extra_fields, secret, identity)

    <<first, rest::binary>> = container."HMAC"

    tampered =
      container
      |> Map.put(:HMAC, <<Bitwise.bxor(first, 1), rest::binary>>)
      |> then(&encode_to_binary!(ADVSignedDeviceIdentityHMAC, &1))

    assert {:error, :adv_hmac_mismatch} =
             ADV.parse_signed_device_identity(tampered <> extra_fields, secret, identity)
  end

  test "a direct identity with an invalid signature is still rejected after wire detection" do
    %{blob: blob, adv_secret: secret, identity: identity} = valid_adv_fixture(:E2EE)
    {:ok, container} = ADVSignedDeviceIdentityHMAC.decode(blob)
    {:ok, signed} = ADVSignedDeviceIdentity.decode(container.details)

    tampered =
      %{signed | accountSignature: <<0::512>>}
      |> then(&encode_to_binary!(ADVSignedDeviceIdentity, &1))

    assert {:error, :adv_invalid_account_signature} =
             ADV.parse_signed_device_identity(tampered, secret, identity)
  end

  test "rejects pair-success identities without account signature" do
    %{private: identity_priv, public: identity_pub} = Keys.generate_key_pair()
    account_pub = Keys.generate_key_pair().public

    details_msg = %ADVDeviceIdentity{
      rawID: 1234,
      timestamp: 1_725_000_000,
      keyIndex: 7,
      accountType: :E2EE,
      deviceType: :E2EE
    }

    details_inner = encode_to_binary!(ADVDeviceIdentity, details_msg)

    signed =
      %ADVSignedDeviceIdentity{
        details: details_inner,
        accountSignatureKey: account_pub
      }
      |> then(&encode_to_binary!(ADVSignedDeviceIdentity, &1))

    adv_secret = :crypto.strong_rand_bytes(32)

    container =
      %ADVSignedDeviceIdentityHMAC{
        details: signed,
        HMAC: :crypto.mac(:hmac, :sha256, adv_secret, signed),
        accountType: :E2EE
      }
      |> then(&encode_to_binary!(ADVSignedDeviceIdentityHMAC, &1))

    assert {:error, :adv_invalid_account_signature_fields} =
             ADV.parse_signed_device_identity(container, adv_secret, %{
               public: identity_pub,
               private: identity_priv
             })
  end

  test "rejects pair-success identities with invalid account signature" do
    %{private: identity_priv, public: identity_pub} = Keys.generate_key_pair()
    %{private: account_priv, public: account_pub} = Keys.generate_key_pair()

    details_msg = %ADVDeviceIdentity{
      rawID: 1234,
      timestamp: 1_725_000_000,
      keyIndex: 7,
      accountType: :E2EE,
      deviceType: :E2EE
    }

    details_inner = encode_to_binary!(ADVDeviceIdentity, details_msg)
    wrong_identity_pub = Keys.generate_key_pair().public

    signed =
      %ADVSignedDeviceIdentity{
        details: details_inner,
        accountSignatureKey: account_pub,
        accountSignature:
          Keys.sign_message(account_priv, <<6, 0>> <> details_inner <> wrong_identity_pub)
      }
      |> then(&encode_to_binary!(ADVSignedDeviceIdentity, &1))

    adv_secret = :crypto.strong_rand_bytes(32)

    container =
      %ADVSignedDeviceIdentityHMAC{
        details: signed,
        HMAC: :crypto.mac(:hmac, :sha256, adv_secret, signed),
        accountType: :E2EE
      }
      |> then(&encode_to_binary!(ADVSignedDeviceIdentityHMAC, &1))

    assert {:error, :adv_invalid_account_signature} =
             ADV.parse_signed_device_identity(container, adv_secret, %{
               public: identity_pub,
               private: identity_priv
             })
  end

  test "rejects a tampered HMAC" do
    %{blob: blob, adv_secret: adv_secret, identity: identity} = valid_adv_fixture(:E2EE)
    {:ok, container} = ADVSignedDeviceIdentityHMAC.decode(blob)
    <<first, rest::binary>> = container."HMAC"

    tampered =
      container
      |> Map.put(:HMAC, <<Bitwise.bxor(first, 1), rest::binary>>)
      |> then(&encode_to_binary!(ADVSignedDeviceIdentityHMAC, &1))

    assert {:error, :adv_hmac_mismatch} =
             ADV.parse_signed_device_identity(tampered, adv_secret, identity)
  end

  test "rejects a truncated HMAC without falling back to a direct identity" do
    %{blob: blob, adv_secret: adv_secret, identity: identity} = valid_adv_fixture(:E2EE)
    {:ok, container} = ADVSignedDeviceIdentityHMAC.decode(blob)

    malformed =
      container
      |> Map.put(:HMAC, binary_part(container."HMAC", 0, 10))
      |> then(&encode_to_binary!(ADVSignedDeviceIdentityHMAC, &1))

    assert {:error, :adv_invalid_hmac} =
             ADV.parse_signed_device_identity(malformed, adv_secret, identity)
  end

  test "rejects an HMAC computed under another ADV secret" do
    %{blob: blob, identity: identity} = valid_adv_fixture(:E2EE)

    assert {:error, :adv_hmac_mismatch} =
             ADV.parse_signed_device_identity(blob, :crypto.strong_rand_bytes(32), identity)
  end

  test "signed identity encoding can retain or remove the account key" do
    %{blob: blob, adv_secret: adv_secret, identity: identity} = valid_adv_fixture(:E2EE)
    assert {:ok, parsed} = ADV.parse_signed_device_identity(blob, adv_secret, identity)

    assert {:ok, with_key} = ADV.encode_signed_device_identity(parsed.signed)
    assert {:ok, decoded_with_key} = ADVSignedDeviceIdentity.decode(with_key)
    assert decoded_with_key.accountSignatureKey == parsed.signed.accountSignatureKey

    assert {:ok, without_key} =
             ADV.encode_signed_device_identity(parsed.signed, include_signature_key: false)

    assert {:ok, decoded_without_key} = ADVSignedDeviceIdentity.decode(without_key)
    assert decoded_without_key.accountSignatureKey == nil
    assert decoded_without_key.details == parsed.signed.details
    assert decoded_without_key.accountSignature == parsed.signed.accountSignature
    assert decoded_without_key.deviceSignature == parsed.signed.deviceSignature
  end

  test "signed future or damaged details preserve a recoverable key index without skipping authentication" do
    identity = Keys.generate_key_pair()
    account = Keys.generate_key_pair()
    secret = :crypto.strong_rand_bytes(32)

    fixtures = [
      {<<8, 1, 24, 172, 2, 0>>, 300},
      {<<129, 1, 0::64, 24, 9, 0>>, 9},
      {<<133, 1, 0::32, 24, 9, 0>>, 9},
      {<<130, 1, 2, 1, 2, 24, 9, 0>>, 9},
      {<<129, 1, 0>>, nil},
      {<<133, 1, 0>>, nil},
      {<<130, 1, 255>>, nil},
      {<<128>>, nil},
      {:binary.copy(<<128>>, 12), nil},
      {<<8, 128>>, nil},
      {<<7>>, nil}
    ]

    for {details, index} <- fixtures do
      signed = %ADVSignedDeviceIdentity{
        details: details,
        accountSignatureKey: account.public,
        accountSignature:
          Keys.sign_message(account.private, <<6, 0>> <> details <> identity.public)
      }

      bytes = encode_to_binary!(ADVSignedDeviceIdentity, signed)

      blob =
        encode_to_binary!(ADVSignedDeviceIdentityHMAC, %ADVSignedDeviceIdentityHMAC{
          details: bytes,
          HMAC: :crypto.mac(:hmac, :sha256, secret, bytes)
        })

      assert {:ok, parsed} = ADV.parse_signed_device_identity(blob, secret, identity)
      assert parsed.details.keyIndex == index

      assert Keys.verify_message(
               identity.public,
               <<6, 1>> <> details <> identity.public <> account.public,
               parsed.device_signature
             )

      assert {:error, :adv_hmac_mismatch} =
               ADV.parse_signed_device_identity(blob, <<0::256>>, identity)
    end
  end

  test "invalid identity material and malformed containers return explicit errors" do
    fixture = valid_adv_fixture(:E2EE)

    assert {:ok, nil} =
             ADV.parse_signed_device_identity(nil, fixture.adv_secret, fixture.identity)

    assert {:error, :invalid_adv_payload} =
             ADV.parse_signed_device_identity(:invalid, fixture.adv_secret, fixture.identity)

    assert {:error, {:invalid_length, :adv_secret}} =
             ADV.parse_signed_device_identity(fixture.blob, <<1>>, fixture.identity)

    assert {:error, :invalid_identity_keypair} =
             ADV.parse_signed_device_identity(fixture.blob, fixture.adv_secret, %{
               public: <<1>>,
               private: <<2>>
             })

    assert {:error, :adv_missing_details} =
             ADV.parse_signed_device_identity(<<>>, fixture.adv_secret, fixture.identity)

    assert {:error, _} =
             ADV.parse_signed_device_identity(<<10, 255>>, fixture.adv_secret, fixture.identity)

    assert {:error, :invalid_signed_device_identity} = ADV.encode_signed_device_identity(%{})
    bytes = <<10, 255>>

    blob =
      encode_to_binary!(ADVSignedDeviceIdentityHMAC, %ADVSignedDeviceIdentityHMAC{
        details: bytes,
        HMAC: :crypto.mac(:hmac, :sha256, fixture.adv_secret, bytes)
      })

    assert {:error, {:adv_signed_identity_decode, _}} =
             ADV.parse_signed_device_identity(blob, fixture.adv_secret, fixture.identity)
  end

  defp do_adv_roundtrip(account_type) do
    # Identity keypair (Curve25519, same as runtime Signal identity)
    %{private: identity_priv, public: identity_pub} = Keys.generate_key_pair()

    # Account signing keypair is also a Curve25519/DJB key verified via XEdDSA.
    %{private: account_priv, public: account_pub} = Keys.generate_key_pair()

    # Device identity details
    details_msg = %ADVDeviceIdentity{
      rawID: 1234,
      timestamp: 1_725_000_000,
      keyIndex: 7,
      accountType: account_type,
      deviceType: account_type
    }

    details_inner = encode_to_binary!(ADVDeviceIdentity, details_msg)

    # Signed device identity (server-provided fields filled)
    signed0 = %ADVSignedDeviceIdentity{
      details: details_inner,
      accountSignatureKey: account_pub
    }

    # Account signature over inner details + identity pub with appropriate prefix
    acc_prefix =
      case account_type do
        :HOSTED -> @adv_hosted_prefix_device_identity_account_signature
        _ -> @adv_prefix_account_signature
      end

    account_message = acc_prefix <> details_inner <> identity_pub
    account_sig = Keys.sign_message(account_priv, account_message)

    signed = %ADVSignedDeviceIdentity{signed0 | accountSignature: account_sig}

    signed_bytes = encode_to_binary!(ADVSignedDeviceIdentity, signed)

    # Container HMAC over (maybe prefixed) SignedDeviceIdentity bytes
    adv_secret = :crypto.strong_rand_bytes(32)

    hmac_prefix =
      if account_type == :HOSTED,
        do: @adv_hosted_prefix_device_identity_account_signature,
        else: <<>>

    hmac = :crypto.mac(:hmac, :sha256, adv_secret, hmac_prefix <> signed_bytes)

    container = %ADVSignedDeviceIdentityHMAC{
      details: signed_bytes,
      HMAC: hmac,
      accountType: account_type
    }

    adv_blob = encode_to_binary!(ADVSignedDeviceIdentityHMAC, container)

    # Parse/verify/sign
    {:ok, parsed} =
      ADV.parse_signed_device_identity(adv_blob, adv_secret, %{
        public: identity_pub,
        private: identity_priv
      })

    assert parsed.hosted? == (account_type == :HOSTED)

    assert %ADVDeviceIdentity{} = parsed.details
    assert parsed.details.rawID == details_msg.rawID
    assert parsed.details.timestamp == details_msg.timestamp
    assert parsed.details.keyIndex == details_msg.keyIndex
    assert parsed.details.accountType == details_msg.accountType
    assert parsed.details.deviceType == details_msg.deviceType

    assert %ADVSignedDeviceIdentity{} = parsed.signed
    assert parsed.signed.accountSignatureKey == account_pub
    assert byte_size(parsed.device_signature) == 64

    # Verify device signature against expected message
    device_message =
      @adv_prefix_device_signature_generate <> details_inner <> identity_pub <> account_pub

    assert Keys.verify_message(identity_pub, device_message, parsed.device_signature)

    # self_signed blob should decode to a SignedDeviceIdentity missing the account key
    {:ok, self_signed} = ADVSignedDeviceIdentity.decode(parsed.self_signed)
    assert self_signed.accountSignatureKey == nil
    assert self_signed.details == details_inner
    assert self_signed.accountSignature == account_sig
    assert self_signed.deviceSignature == parsed.device_signature
  end

  defp valid_adv_fixture(account_type) do
    %{private: identity_priv, public: identity_pub} = Keys.generate_key_pair()
    %{private: account_priv, public: account_pub} = Keys.generate_key_pair()

    details =
      %ADVDeviceIdentity{
        rawID: 1234,
        timestamp: 1_725_000_000,
        keyIndex: 7,
        accountType: account_type,
        deviceType: account_type
      }
      |> then(&encode_to_binary!(ADVDeviceIdentity, &1))

    signature_prefix =
      if account_type == :HOSTED,
        do: @adv_hosted_prefix_device_identity_account_signature,
        else: @adv_prefix_account_signature

    signed =
      %ADVSignedDeviceIdentity{
        details: details,
        accountSignatureKey: account_pub,
        accountSignature:
          Keys.sign_message(account_priv, signature_prefix <> details <> identity_pub)
      }
      |> then(&encode_to_binary!(ADVSignedDeviceIdentity, &1))

    adv_secret = :crypto.strong_rand_bytes(32)

    hmac_prefix =
      if account_type == :HOSTED,
        do: @adv_hosted_prefix_device_identity_account_signature,
        else: <<>>

    blob =
      %ADVSignedDeviceIdentityHMAC{
        details: signed,
        HMAC: :crypto.mac(:hmac, :sha256, adv_secret, hmac_prefix <> signed),
        accountType: account_type
      }
      |> then(&encode_to_binary!(ADVSignedDeviceIdentityHMAC, &1))

    %{
      blob: blob,
      adv_secret: adv_secret,
      identity: %{public: identity_pub, private: identity_priv}
    }
  end

  defp do_direct_adv_roundtrip(account_type) do
    %{private: identity_priv, public: identity_pub} = Keys.generate_key_pair()
    %{private: account_priv, public: account_pub} = Keys.generate_key_pair()

    details_msg = %ADVDeviceIdentity{
      rawID: 5678,
      timestamp: 1_725_000_000,
      keyIndex: 9,
      accountType: account_type,
      deviceType: account_type
    }

    details_inner = encode_to_binary!(ADVDeviceIdentity, details_msg)

    acc_prefix =
      case account_type do
        :HOSTED -> @adv_hosted_prefix_device_identity_account_signature
        _ -> @adv_prefix_account_signature
      end

    account_sig = Keys.sign_message(account_priv, acc_prefix <> details_inner <> identity_pub)

    signed_bytes =
      %ADVSignedDeviceIdentity{
        details: details_inner,
        accountSignatureKey: account_pub,
        accountSignature: account_sig
      }
      |> then(&encode_to_binary!(ADVSignedDeviceIdentity, &1))

    {:ok, parsed} =
      ADV.parse_signed_device_identity(signed_bytes, :crypto.strong_rand_bytes(32), %{
        public: identity_pub,
        private: identity_priv
      })

    assert parsed.signed.accountSignatureKey == account_pub
    assert parsed.signed.accountSignature == account_sig
    assert byte_size(parsed.device_signature) == 64
  end

  defp encode_to_binary!(mod, struct) do
    {:ok, io, _size} = mod.encode(struct)
    IO.iodata_to_binary(io)
  end
end
