defmodule ExWapp.Noise.Certificate do
  @moduledoc """
  Validates the WhatsApp Noise certificate chain presented during handshake.

  Verification anchors the intermediate certificate to WhatsApp's public key and
  checks that the leaf certificate binds the expected server static key.
  """

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
    verify(cert_bytes, static_key, [])
  end

  def verify(_cert_bytes, _static_key), do: {:error, :invalid_certificate}

  @doc false
  @spec verify(binary(), binary(), keyword()) :: :ok | {:error, term()}
  def verify(cert_bytes, static_key, opts)
      when is_binary(cert_bytes) and is_binary(static_key) and is_list(opts) do
    root_key = Keyword.get(opts, :root_key, @wa_cert_pub_key)

    with {:ok, %CertChain{} = chain} <- CertChain.decode(cert_bytes),
         :ok <- validate_root_key(root_key),
         {:ok, intermediate_details} <-
           verify_intermediate_certificate(chain.intermediate, root_key) do
      verify_leaf_certificate(chain.leaf, intermediate_details, static_key)
    end
  end

  def verify(_cert_bytes, _static_key, _opts), do: {:error, :invalid_certificate}

  defp verify_intermediate_certificate(
         %NoiseCertificate{
           details: int_details_raw,
           signature: int_signature
         },
         root_key
       )
       when is_binary(int_details_raw) and is_binary(int_signature) do
    with :ok <- validate_signature_length(int_signature, :intermediate),
         :ok <-
           validate_signature(root_key, int_details_raw, int_signature, :intermediate),
         {:ok, %Details{} = intermediate_details} <- Details.decode(int_details_raw),
         :ok <- validate_intermediate_details(intermediate_details) do
      {:ok, intermediate_details}
    end
  end

  defp verify_intermediate_certificate(_, _root_key), do: {:error, :missing_certificate_parts}

  defp validate_root_key(key) when is_binary(key) and byte_size(key) == 32, do: :ok
  defp validate_root_key(_key), do: {:error, :invalid_root_key}

  defp verify_leaf_certificate(
         %NoiseCertificate{details: leaf_details_raw, signature: leaf_signature},
         %Details{} = intermediate_details,
         static_key
       )
       when is_binary(leaf_details_raw) and is_binary(leaf_signature) and is_binary(static_key) do
    with :ok <- validate_signature_length(leaf_signature, :leaf),
         :ok <-
           validate_signature(
             intermediate_details.key,
             leaf_details_raw,
             leaf_signature,
             :leaf
           ),
         {:ok, %Details{} = leaf_details} <- Details.decode(leaf_details_raw) do
      validate_leaf_details(leaf_details, intermediate_details, static_key)
    end
  end

  defp verify_leaf_certificate(_leaf, _intermediate_details, _static_key),
    do: {:error, :missing_certificate_parts}

  defp validate_signature_length(signature, :intermediate) when byte_size(signature) == 64,
    do: :ok

  defp validate_signature_length(_signature, :intermediate),
    do: {:error, :invalid_intermediate_signature_length}

  defp validate_signature_length(signature, :leaf) when byte_size(signature) == 64, do: :ok
  defp validate_signature_length(_signature, :leaf), do: {:error, :invalid_leaf_signature_length}

  defp validate_signature(public_key, details_raw, signature, :intermediate) do
    if verify_signature(public_key, details_raw, signature),
      do: :ok,
      else: {:error, :invalid_intermediate_signature}
  end

  defp validate_signature(public_key, details_raw, signature, :leaf) do
    if verify_signature(public_key, details_raw, signature),
      do: :ok,
      else: {:error, :invalid_leaf_signature}
  end

  defp validate_intermediate_details(%Details{} = intermediate_details) do
    cond do
      intermediate_details.issuerSerial != @issuer_serial ->
        {:error, :invalid_intermediate_issuer}

      byte_size(intermediate_details.key) != 32 ->
        {:error, :invalid_intermediate_key}

      true ->
        :ok
    end
  end

  defp validate_leaf_details(
         %Details{} = leaf_details,
         %Details{} = intermediate_details,
         static_key
       ) do
    cond do
      leaf_details.issuerSerial != intermediate_details.serial ->
        {:error, :unexpected_leaf_issuer}

      leaf_details.key != static_key ->
        {:error, :static_mismatch}

      true ->
        :ok
    end
  end

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
