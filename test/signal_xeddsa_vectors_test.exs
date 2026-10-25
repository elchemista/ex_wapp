defmodule ExWapp.Signal.XEdDSAVectorsTest do
  use ExUnit.Case, async: true

  import Bitwise

  alias ExWapp.Noise.Certificate
  alias ExWapp.Signal.Keys

  @field_prime (1 <<< 255) - 19
  @group_order (1 <<< 252) + 27_742_317_777_372_353_535_851_937_790_883_648_493

  # Vectors generated with libsignal's Curve25519 signing implementation.
  # They protect the wire-level XEdDSA compatibility required by WhatsApp.
  @libsignal_vectors [
    %{
      priv: "60744d79d0f7e9a4fe5785f86fcb4d2dba2efb02d1895109d155b4bfd2a3105e",
      pub: "b35f8730e1e9d732735f252dc03b8b6284fbd37c4be8bea0edcd7d9154975568",
      msg: "",
      sig:
        "e7eb907e63dfa6b46f005446dbde023d476dc617b37c044f0185842b162140273c746291eaa230c3cd84cddae3d2064875e8dc155c539026f799b633ac61c101"
    },
    %{
      priv: "288405eeb18182cca8791289c1c1d0040b87c5213e39c20ee9a280e7643dda56",
      pub: "bb08464f618221120437768c1cbe33d56584ff6bf7f51cbd6848f96be97c6c35",
      msg: "61",
      sig:
        "edf8ba99b833f02d3ae81d88a09da9343f97588712b1025ed157512fe42a7bff0f9afe949312daf58b0bcfff4b295b71de864451132533918f0b73dd87ccfe8b"
    },
    %{
      priv: "f0d33fbdfe48694443395d978fd2942eb30d2cbe4d649f2bdf868ee0ae8c2276",
      pub: "05b7499eb0c1183101f7e5ecca3e3e96f0faaf954633762276d06b5387953002",
      msg: "68656c6c6f2077686174736170702070616972696e67",
      sig:
        "cc0472160060e3c02d6167b3ffd2bed2f4bf48d7906cab2318f224d718d33106a3f5831b07adf930f39fefe6938c173d4eb863d3ca0c7e1dae4a920d0614ed8c"
    },
    %{
      priv: "409cd5989634bdea177d9a05501dff5176765c2a3f97bbc3739dd535cd1ee674",
      pub: "05ee915a7680739e6145b41231541892e33e4e14bd7be51650b4d2463506dc1e",
      msg:
        "1a0913f0ee88d07b3969a9f4d30c20e31c0ac3986159f00509b4c29c3d6fc84deb542bb80c0d8d73c5db52d289f1a9a31a777dda73ff7106e2c1af9ae3360344c88351fd57f218ebada03915cb1eff9430c7e60902a81127b84a97acae8044a1d8b45c51",
      sig:
        "248b50672c0aef1f498238c26542d83bff1dc06dbdff70c186d20b0394d7bd5692c8bf2730d70b32608d289ae037e436bf48d9d4c47d9299974eb9b73d80fb80"
    }
  ]

  defp decode(vector) do
    Map.new(vector, fn {key, value} ->
      {key, Base.decode16!(value, case: :lower)}
    end)
  end

  describe "verify_message/3 interoperability" do
    test "accepts signatures produced by libsignal" do
      for vector <- @libsignal_vectors do
        %{pub: public, msg: message, sig: signature} = decode(vector)
        assert Keys.verify_message(public, message, signature)
      end
    end

    test "rejects tampered messages" do
      for vector <- @libsignal_vectors do
        %{pub: public, msg: message, sig: signature} = decode(vector)
        refute Keys.verify_message(public, message <> <<0>>, signature)
      end
    end

    test "rejects tampered signatures" do
      %{pub: public, msg: message, sig: signature} = decode(hd(@libsignal_vectors))
      <<first, rest::binary>> = signature
      changed = Bitwise.bxor(first, 1)

      refute Keys.verify_message(public, message, <<changed, rest::binary>>)
    end

    test "rejects malformed inputs instead of raising" do
      %{pub: public, msg: message, sig: signature} = decode(hd(@libsignal_vectors))

      refute Keys.verify_message(:invalid, message, signature)
      refute Keys.verify_message(:binary.copy(<<0>>, 31), message, signature)
      refute Keys.verify_message(public, message, :binary.copy(<<0>>, 63))
      refute Keys.verify(:invalid, :binary.copy(<<0>>, 32), signature)
    end
  end

  describe "Ed25519 library versus OTP verification" do
    test "libsignal signatures agree after conversion for both XEdDSA sign bits" do
      sign_bits =
        for vector <- @libsignal_vectors do
          %{pub: public, msg: message, sig: signature} = decode(vector)
          {ed_public, ed_signature} = ed25519_inputs(public, signature)

          # Check the test conversion against the dependency's reverse mapping.
          assert Ed25519.to_curve25519(ed_public, :public) == public
          assert Ed25519.valid_signature?(ed_signature, message, ed_public)
          assert :crypto.verify(:eddsa, :none, message, ed_signature, [ed_public, :ed25519])
          assert Keys.verify_message(public, message, signature)
          assert Certificate.verify_signature(public, message, signature)

          # The WhatsApp wire key/signature cannot be passed to Ed25519 as-is.
          refute :crypto.verify(:eddsa, :none, message, signature, [public, :ed25519])
          band(:binary.last(signature), 0x80)
        end

      assert Enum.sort(Enum.uniq(sign_bits)) == [0, 0x80]
    end

    test "both backends reject changed messages, scalar bytes and valid but wrong keys" do
      for vector <- @libsignal_vectors do
        %{pub: public, msg: message, sig: signature} = decode(vector)
        {ed_public, ed_signature} = ed25519_inputs(public, signature)
        <<r::binary-size(32), first_s, rest_s::binary>> = ed_signature
        changed_signature = r <> <<bxor(first_s, 1)>> <> rest_s
        {wrong_public, _private} = :crypto.generate_key(:eddsa, :ed25519)

        for {key, msg, sig} <- [
              {ed_public, message <> <<0>>, ed_signature},
              {ed_public, message, changed_signature},
              {wrong_public, message, ed_signature}
            ] do
          refute Ed25519.valid_signature?(sig, msg, key)
          refute :crypto.verify(:eddsa, :none, msg, sig, [key, :ed25519])
        end
      end
    end

    test "noncanonical S plus the group order is accepted by the library but rejected by OTP" do
      # This is a deliberate compatibility difference, not an equivalence claim.
      # RFC 8032 section 5.1.7 requires S < L; ed25519 1.5.2 reduces S modulo L.
      # https://www.rfc-editor.org/rfc/rfc8032#section-5.1.7
      for vector <- @libsignal_vectors do
        %{pub: public, msg: message, sig: signature} = decode(vector)

        {ed_public, <<r::binary-size(32), s::little-size(256)>>} =
          ed25519_inputs(public, signature)

        assert s < @group_order
        noncanonical = <<r::binary, s + @group_order::little-size(256)>>
        assert Ed25519.valid_signature?(noncanonical, message, ed_public)
        refute :crypto.verify(:eddsa, :none, message, noncanonical, [ed_public, :ed25519])

        <<head::binary-size(63), last>> = noncanonical
        sign_bit = band(:binary.last(signature), 0x80)
        wire_signature = head <> <<bor(last, sign_bit)>>
        assert Keys.verify_message(public, message, wire_signature)
        assert Certificate.verify_signature(public, message, wire_signature)
      end
    end

    test "invalid points and short keys have different raw error contracts" do
      %{pub: public, msg: message, sig: signature} = decode(hd(@libsignal_vectors))

      {ed_public, <<_r::binary-size(32), s::binary-size(32)>>} =
        ed25519_inputs(public, signature)

      invalid_point_signature = <<0::256, s::binary>>

      assert_raise RuntimeError, fn ->
        Ed25519.valid_signature?(invalid_point_signature, message, ed_public)
      end

      refute :crypto.verify(:eddsa, :none, message, invalid_point_signature, [ed_public, :ed25519])

      refute Keys.verify_message(public, message, invalid_point_signature)

      short_key = binary_part(ed_public, 0, 31)
      refute Ed25519.valid_signature?(signature, message, short_key)

      assert_raise ErlangError, fn ->
        :crypto.verify(:eddsa, :none, message, signature, [short_key, :ed25519])
      end
    end
  end

  describe "sign_message/2 interoperability" do
    test "signatures verify against the libsignal vector public keys" do
      for vector <- @libsignal_vectors do
        %{priv: private, pub: public, msg: message} = decode(vector)
        signature = Keys.sign_message(private, message)

        assert byte_size(signature) == 64
        assert Keys.verify_message(public, message, signature)
        assert_otp_signature(public, message, signature)
      end
    end

    test "round-trips fresh X25519 key pairs and varied payload sizes" do
      messages = [
        <<>>,
        <<0>>,
        "signed pre-key payload",
        :binary.copy(<<0xA5>>, 255)
      ]

      for message <- messages do
        key_pair = Keys.generate_key_pair()
        signature = Keys.sign_message(key_pair.private, message)

        assert Keys.verify_message(key_pair.public, message, signature)
        refute Keys.verify_message(key_pair.public, message <> <<1>>, signature)
        assert_otp_signature(key_pair.public, message, signature)
      end
    end

    test "signed pre-keys use the same compatible signature boundary" do
      identity = Keys.generate_key_pair()
      signed_prekey = Keys.generate_signed_prekey(identity, 42)

      assert Keys.verify(identity.public, signed_prekey.public, signed_prekey.signature)
      refute Keys.verify(identity.public, <<0::256>>, signed_prekey.signature)

      assert_otp_signature(
        identity.public,
        <<5, signed_prekey.public::binary>>,
        signed_prekey.signature
      )
    end
  end

  defp assert_otp_signature(public, message, signature) do
    {ed_public, ed_signature} = ed25519_inputs(public, signature)
    assert :crypto.verify(:eddsa, :none, message, ed_signature, [ed_public, :ed25519])
  end

  # Test-only bridge: y = (u - 1)/(u + 1), then move the XEdDSA sign bit
  # from the signature's final byte to the Edwards public key.
  defp ed25519_inputs(public, <<head::binary-size(63), last>>) do
    u = :binary.decode_unsigned(public, :little)

    inverse =
      :crypto.mod_pow(u + 1, @field_prime - 2, @field_prime)
      |> :binary.decode_unsigned()

    y = Integer.mod((u - 1) * inverse, @field_prime)
    encoded_public = bor(y, band(last, 0x80) <<< 248)
    {<<encoded_public::little-size(256)>>, head <> <<band(last, 0x7F)>>}
  end
end
