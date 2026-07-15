defmodule ExWapp.NoiseCertificateTest do
  use ExUnit.Case, async: true

  alias ExWapp.Noise.Certificate
  alias ExWapp.Signal.Keys
  alias WACert.CertChain
  alias WACert.CertChain.NoiseCertificate
  alias WACert.CertChain.NoiseCertificate.Details

  @pub Base.decode16!("0537C2BB45CAC4CF3DDD0D41FD6B6F1733F9D182031E4AE98EF3477B680993BA57",
         case: :mixed
       )
       |> binary_part(1, 32)
  @sig Base.decode16!(
         "B97322CE463FF331C58AFD9713B5275F0C2CB66D341BCE8EA45A4362EC11A64A8FE010BBD2C5A28A72615EDA0A16ED85CC6298717E1F42AD8DB33DF846359505",
         case: :mixed
       )
  @msg "hello noise"

  test "curve25519 signatures verify" do
    assert Certificate.verify_signature(@pub, @msg, @sig)
  end

  test "curve25519 signature fails with wrong message" do
    refute Certificate.verify_signature(@pub, "hello", @sig)
  end

  test "validates a complete generated certificate chain" do
    fixture = certificate_fixture()

    assert :ok =
             Certificate.verify(fixture.encoded, fixture.static_key,
               root_key: fixture.root.public
             )
  end

  test "rejects missing parts, invalid root and both signature length failures" do
    fixture = certificate_fixture()

    assert {:error, :invalid_root_key} =
             Certificate.verify(fixture.encoded, fixture.static_key, root_key: <<1>>)

    missing = encode_chain(%CertChain{})

    assert {:error, :missing_certificate_parts} =
             Certificate.verify(missing, fixture.static_key, root_key: fixture.root.public)

    short_intermediate =
      fixture.chain
      |> put_in([Access.key!(:intermediate), Access.key!(:signature)], <<1>>)
      |> encode_chain()

    assert {:error, :invalid_intermediate_signature_length} =
             Certificate.verify(short_intermediate, fixture.static_key,
               root_key: fixture.root.public
             )

    short_leaf =
      fixture.chain
      |> put_in([Access.key!(:leaf), Access.key!(:signature)], <<1>>)
      |> encode_chain()

    assert {:error, :invalid_leaf_signature_length} =
             Certificate.verify(short_leaf, fixture.static_key, root_key: fixture.root.public)
  end

  test "rejects tampered intermediate and leaf signatures" do
    fixture = certificate_fixture()

    tampered_intermediate =
      fixture.chain
      |> update_in([Access.key!(:intermediate), Access.key!(:signature)], &flip_last_byte/1)
      |> encode_chain()

    assert {:error, :invalid_intermediate_signature} =
             Certificate.verify(tampered_intermediate, fixture.static_key,
               root_key: fixture.root.public
             )

    tampered_leaf =
      fixture.chain
      |> update_in([Access.key!(:leaf), Access.key!(:signature)], &flip_last_byte/1)
      |> encode_chain()

    assert {:error, :invalid_leaf_signature} =
             Certificate.verify(tampered_leaf, fixture.static_key, root_key: fixture.root.public)
  end

  test "rejects intermediate issuer/key, leaf issuer and static-key mismatches" do
    fixture = certificate_fixture()

    invalid_intermediate_issuer = certificate_fixture(intermediate_issuer: 9)

    assert {:error, :invalid_intermediate_issuer} =
             Certificate.verify(
               invalid_intermediate_issuer.encoded,
               invalid_intermediate_issuer.static_key,
               root_key: invalid_intermediate_issuer.root.public
             )

    invalid_intermediate_key = certificate_fixture(intermediate_cert_key: <<1, 2, 3>>)

    assert {:error, :invalid_intermediate_key} =
             Certificate.verify(
               invalid_intermediate_key.encoded,
               invalid_intermediate_key.static_key,
               root_key: invalid_intermediate_key.root.public
             )

    invalid_leaf_issuer = certificate_fixture(leaf_issuer: 999)

    assert {:error, :unexpected_leaf_issuer} =
             Certificate.verify(
               invalid_leaf_issuer.encoded,
               invalid_leaf_issuer.static_key,
               root_key: invalid_leaf_issuer.root.public
             )

    assert {:error, :static_mismatch} =
             Certificate.verify(fixture.encoded, :crypto.strong_rand_bytes(32),
               root_key: fixture.root.public
             )
  end

  defp certificate_fixture(opts \\ []) do
    root = Keys.generate_key_pair()
    intermediate = Keys.generate_key_pair()
    static_key = :crypto.strong_rand_bytes(32)
    intermediate_serial = 42

    intermediate_details = %Details{
      serial: intermediate_serial,
      issuerSerial: Keyword.get(opts, :intermediate_issuer, 0),
      key: Keyword.get(opts, :intermediate_cert_key, intermediate.public)
    }

    intermediate_details_raw = encode_message(intermediate_details)

    intermediate_certificate = %NoiseCertificate{
      details: intermediate_details_raw,
      signature: Keys.sign_message(root.private, intermediate_details_raw)
    }

    leaf_details = %Details{
      serial: 43,
      issuerSerial: Keyword.get(opts, :leaf_issuer, intermediate_serial),
      key: static_key
    }

    leaf_details_raw = encode_message(leaf_details)

    leaf_certificate = %NoiseCertificate{
      details: leaf_details_raw,
      signature: Keys.sign_message(intermediate.private, leaf_details_raw)
    }

    chain = %CertChain{leaf: leaf_certificate, intermediate: intermediate_certificate}

    %{
      root: root,
      intermediate: intermediate,
      static_key: static_key,
      chain: chain,
      encoded: encode_chain(chain)
    }
  end

  defp encode_chain(chain), do: chain |> CertChain.encode!() |> IO.iodata_to_binary()
  defp encode_message(message), do: message.__struct__.encode!(message) |> IO.iodata_to_binary()

  defp flip_last_byte(binary) do
    size = byte_size(binary) - 1
    <<prefix::binary-size(^size), last>> = binary
    prefix <> <<Bitwise.bxor(last, 1)>>
  end
end
