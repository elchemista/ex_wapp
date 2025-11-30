defmodule ExWapp.PairingADVTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Pairing.ADV
  alias WAAdv.{ADVDeviceIdentity, ADVSignedDeviceIdentity, ADVSignedDeviceIdentityHMAC}

  @adv_prefix_account_signature <<6, 0>>
  @adv_prefix_device_signature_generate <<6, 1>>
  @adv_hosted_prefix_device_identity_account_signature <<6, 5>>
  @adv_hosted_prefix_device_identity_device_signature_verification <<6, 6>>

  test "E2EE ADV blob parses, verifies and produces device signature" do
    do_adv_roundtrip(:E2EE)
  end

  test "HOSTED ADV blob parses, verifies and produces device signature" do
    do_adv_roundtrip(:HOSTED)
  end

  defp do_adv_roundtrip(account_type) do
    # Identity keypair (Ed25519)
    identity_priv = :crypto.strong_rand_bytes(32)
    identity_pub = Ed25519.derive_public_key(identity_priv)

    # Account signing keypair (Ed25519)
    account_priv = :crypto.strong_rand_bytes(32)
    account_pub = Ed25519.derive_public_key(account_priv)

    # Device identity details
    details_msg = %ADVDeviceIdentity{
      rawID: 1234,
      timestamp: 1_725_000_000,
      keyIndex: 7,
      accountType: account_type,
      deviceType: :E2EE
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
    account_sig = Ed25519.signature(account_message, account_priv)

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
    dev_prefix =
      if account_type == :HOSTED do
        @adv_hosted_prefix_device_identity_device_signature_verification
      else
        @adv_prefix_device_signature_generate
      end

    device_message = dev_prefix <> details_inner <> identity_pub <> account_pub
    assert Ed25519.valid_signature?(parsed.device_signature, device_message, identity_pub)

    # self_signed blob should decode to a SignedDeviceIdentity missing the account key
    {:ok, self_signed} = ADVSignedDeviceIdentity.decode(parsed.self_signed)
    assert self_signed.accountSignatureKey == nil
    assert self_signed.details == details_inner
    assert self_signed.accountSignature == account_sig
    assert self_signed.deviceSignature == parsed.device_signature
  end

  defp encode_to_binary!(mod, struct) do
    {:ok, io} = mod.encode(struct)
    IO.iodata_to_binary(io)
  end
end
