defmodule ExWapp.Noise.Certificate do
  @moduledoc false

  import Bitwise

  alias Ed25519
  alias WACert.CertChain
  alias WACert.CertChain.NoiseCertificate
  alias WACert.CertChain.NoiseCertificate.Details

  @wa_cert_pub_key <<0x14, 0x23, 0x75, 0x57, 0x4D, 0x0A, 0x58, 0x71, 0x66, 0xAA, 0xE7, 0x1E, 0xBE,
                     0x51, 0x64, 0x37, 0xC4, 0xA2, 0x8B, 0x73, 0xE3, 0x69, 0x5C, 0x6C, 0xE1, 0xF7,
                     0xF9, 0x54, 0x5D, 0xA8, 0xEE, 0x6B>>
  @issuer_serial 0
  @curve25519_prime (1 <<< 255) - 19

  @spec verify(binary(), binary()) :: :ok | {:error, term()}
  def verify(cert_bytes, static_key) when is_binary(cert_bytes) and is_binary(static_key) do
    with {:ok, %CertChain{} = chain} <- CertChain.decode(cert_bytes),
         %NoiseCertificate{details: int_details_raw, signature: int_signature} = _intermediate
         when is_binary(int_details_raw) and is_binary(int_signature) <- chain.intermediate,
         true <-
           byte_size(int_signature) == 64 || {:error, :invalid_intermediate_signature_length},
         true <-
           verify_signature(@wa_cert_pub_key, int_details_raw, int_signature) ||
             {:error, :invalid_intermediate_signature},
         {:ok, %Details{} = intermediate_details} <- Details.decode(int_details_raw),
         true <-
           intermediate_details.issuerSerial == @issuer_serial ||
             {:error, :invalid_intermediate_issuer},
         true <- byte_size(intermediate_details.key) == 32 || {:error, :invalid_intermediate_key},
         %NoiseCertificate{details: leaf_details_raw, signature: leaf_signature} = _leaf
         when is_binary(leaf_details_raw) and is_binary(leaf_signature) <- chain.leaf,
         true <- byte_size(leaf_signature) == 64 || {:error, :invalid_leaf_signature_length},
         true <-
           verify_signature(intermediate_details.key, leaf_details_raw, leaf_signature) ||
             {:error, :invalid_leaf_signature},
         {:ok, %Details{} = leaf_details} <- Details.decode(leaf_details_raw),
         true <-
           leaf_details.issuerSerial == intermediate_details.serial ||
             {:error, :unexpected_leaf_issuer},
         true <- leaf_details.key == static_key || {:error, :static_mismatch} do
      :ok
    else
      nil -> {:error, :missing_certificate_parts}
      {:error, _} = error -> error
      false -> {:error, :invalid_signature}
      other -> {:error, other}
    end
  end

  def verify(_cert_bytes, _static_key), do: {:error, :invalid_certificate}

  @spec verify_signature(binary(), binary(), binary()) :: boolean()
  def verify_signature(public_key, message, signature)
      when is_binary(public_key) and byte_size(public_key) == 32 and is_binary(signature) and
             byte_size(signature) == 64 and is_binary(message) do
    mont_pub = zero_high_bit(public_key)

    with {:ok, ed_pub} <- montgomery_to_edwards(mont_pub, signature),
         {:ok, stripped_sig} <- strip_signature(signature) do
      Ed25519.valid_signature?(stripped_sig, message, ed_pub)
    else
      _ -> false
    end
  end

  def verify_signature(_pub, _msg, _sig), do: false

  defp montgomery_to_edwards(pub, signature) do
    p = @curve25519_prime
    mont_x = :binary.decode_unsigned(pub, :little)

    mont_x_minus_one = rem(mont_x + p - 1, p)
    mont_x_plus_one = rem(mont_x + 1, p)

    if mont_x_plus_one == 0 do
      {:error, :invalid_public_key}
    else
      inv = :crypto.mod_pow(encode_be(mont_x_plus_one), encode_be(p - 2), encode_be(p))
      inv_int = :binary.decode_unsigned(inv, :big)
      ed_y = rem(mont_x_minus_one * inv_int, p)

      ed_pub = encode_le(ed_y, 32)
      <<_::binary-size(63), sig_last>> = signature
      sign_bit = sig_last &&& 0x80

      <<ed_prefix::binary-size(31), ed_last>> = ed_pub
      ed_pub = ed_prefix <> <<(ed_last &&& 0x7F) ||| sign_bit>>

      {:ok, ed_pub}
    end
  end

  defp strip_signature(signature) do
    <<sig_head::binary-size(63), sig_last>> = signature
    {:ok, sig_head <> <<sig_last &&& 0x7F>>}
  end

  defp zero_high_bit(pub) do
    <<prefix::binary-size(31), last>> = pub
    prefix <> <<last &&& 0x7F>>
  end

  defp encode_be(int) do
    :binary.encode_unsigned(int, :big)
  end

  defp encode_le(int, size) do
    bin = :binary.encode_unsigned(int, :little)
    padding = size - byte_size(bin)

    cond do
      padding > 0 -> bin <> :binary.copy(<<0>>, padding)
      padding == 0 -> bin
      true -> binary_part(bin, 0, size)
    end
  end
end
