defmodule ExWapp.Pairing.ADV do
  @moduledoc """
  Helpers for parsing and validating WhatsApp ADV (Account Device Verification) payloads.

  The methods verify the HMAC using the stored ADV secret, validate the
  account signature, and prepare a device signature that can be sent back to
  WhatsApp once the pairing flow completes.
  """

  require Logger

  alias ExWapp.Signal.Keys, as: SignalKeys
  alias WAAdv.{ADVDeviceIdentity, ADVSignedDeviceIdentity, ADVSignedDeviceIdentityHMAC}

  @adv_prefix_device_signature_generate <<6, 1>>
  @adv_hosted_prefix_device_identity_account_signature <<6, 5>>
  @adv_hosted_prefix_device_identity_device_signature_verification <<6, 6>>

  @typedoc """
  Result returned by `parse_signed_device_identity/3`.
  """
  @type parsed_identity :: %{
          container: struct() | nil,
          signed: struct(),
          details: struct() | map(),
          hosted?: boolean(),
          device_signature: binary(),
          self_signed: binary(),
          details_binary: binary()
        }

  @typep identity_keypair :: {binary(), binary()}
  @typep identity_input :: %{public: binary(), private: binary()}
  @typep adv_result :: {:ok, parsed_identity()} | {:error, term()}
  @typep hmac_retry_decision :: :try_hmac | :skip
  @typep key_index :: non_neg_integer() | nil
  @typep relaxed_details :: struct() | %{keyIndex: key_index(), decode_error: term()}
  @typep varint_decode_result :: {:ok, non_neg_integer(), binary()} | {:error, :invalid_varint}

  @doc """
  Parses and validates a signed ADV device identity blob.

  The returned map exposes both the decoded structs and the serialized payload
  that must be echoed back to the server (under `:self_signed`).
  """
  @spec parse_signed_device_identity(binary() | nil, binary(), identity_input()) ::
          {:ok, parsed_identity() | nil} | {:error, term()}
  def parse_signed_device_identity(nil, _adv_secret, _identity), do: {:ok, nil}

  def parse_signed_device_identity(adv_bytes, adv_secret, identity)
      when is_binary(adv_bytes) and is_binary(adv_secret) do
    with :ok <- ensure_binary_length(adv_secret, 32, :adv_secret),
         {:ok, {identity_pub, identity_priv}} <- extract_identity(identity) do
      # Try direct ADVSignedDeviceIdentity first (most common for QR pairing)
      case parse_direct_signed_identity(adv_bytes, identity_pub, identity_priv) do
        {:ok, result} ->
          maybe_retry_as_hmac(result, adv_bytes, adv_secret, identity_pub, identity_priv)

        {:error, direct_error} ->
          fallback_to_hmac(direct_error, adv_bytes, adv_secret, identity_pub, identity_priv)
      end
    end
  end

  def parse_signed_device_identity(_adv_bytes, _adv_secret, _identity),
    do: {:error, :invalid_adv_payload}

  @spec maybe_retry_as_hmac(parsed_identity(), binary(), binary(), binary(), binary()) ::
          adv_result()
  defp maybe_retry_as_hmac(result, adv_bytes, adv_secret, identity_pub, identity_priv) do
    case should_try_hmac_after_direct(result) do
      :try_hmac ->
        Logger.warning("[ADV] Direct parse looks wrapped/incomplete, retrying as HMAC container")
        try_hmac_or_fallback(result, adv_bytes, adv_secret, identity_pub, identity_priv)

      :skip ->
        {:ok, result}
    end
  end

  @spec try_hmac_or_fallback(parsed_identity(), binary(), binary(), binary(), binary()) ::
          {:ok, parsed_identity()}
  defp try_hmac_or_fallback(direct_result, adv_bytes, adv_secret, identity_pub, identity_priv) do
    with {:ok, container} <- decode_container(adv_bytes),
         {:ok, _details} <- ensure_details(container.details),
         {:ok, wrapped} <- parse_hmac_wrapped(container, adv_secret, identity_pub, identity_priv) do
      {:ok, wrapped}
    else
      _ ->
        Logger.warning("[ADV] Falling back to direct parse result")
        {:ok, direct_result}
    end
  end

  @spec fallback_to_hmac(term(), binary(), binary(), binary(), binary()) :: adv_result()
  defp fallback_to_hmac(direct_error, adv_bytes, adv_secret, identity_pub, identity_priv) do
    Logger.warning("[ADV] Direct parsing failed: #{inspect(direct_error)}, trying HMAC wrapper")

    case decode_container(adv_bytes) do
      {:ok, container}
      when is_binary(container.details) and byte_size(container.details) > 0 ->
        parse_hmac_wrapped(container, adv_secret, identity_pub, identity_priv)

      _ ->
        {:error, direct_error}
    end
  end

  @doc """
  Encodes an `ADVSignedDeviceIdentity` payload.

  By default it includes `accountSignatureKey` (required for outgoing messages).
  Pass `include_signature_key: false` for pair-device-sign payloads.
  """
  def encode_signed_device_identity(signed, opts \\ [])

  @spec encode_signed_device_identity(struct(), keyword()) ::
          {:ok, binary()} | {:error, term()}
  def encode_signed_device_identity(%ADVSignedDeviceIdentity{} = signed, opts) do
    include_signature_key? = Keyword.get(opts, :include_signature_key, true)

    payload =
      if include_signature_key? do
        signed
      else
        %{signed | accountSignatureKey: nil}
      end

    case ADVSignedDeviceIdentity.encode(payload) do
      {:ok, iodata} -> {:ok, IO.iodata_to_binary(iodata)}
      {:error, reason} -> {:error, {:adv_signed_identity_encode, reason}}
    end
  end

  def encode_signed_device_identity(_, _opts), do: {:error, :invalid_signed_device_identity}

  # Parse HMAC-wrapped ADV (from adv-device-identity node)
  @spec parse_hmac_wrapped(struct(), binary(), binary(), binary()) :: adv_result()
  defp parse_hmac_wrapped(container, adv_secret, identity_pub, identity_priv) do
    hosted? = container.accountType == :HOSTED

    signature_prefix =
      case container.accountType do
        :HOSTED -> @adv_hosted_prefix_device_identity_device_signature_verification
        _ -> @adv_prefix_device_signature_generate
      end

    hmac_prefix =
      case container.accountType do
        :HOSTED -> @adv_hosted_prefix_device_identity_account_signature
        _ -> <<>>
      end

    with {:ok, details_bin} <- ensure_details(container.details),
         :ok <- verify_hmac(details_bin, container."HMAC", adv_secret, hmac_prefix),
         {:ok, signed_identity} <- decode_signed_identity(details_bin),
         {:ok, %ADVSignedDeviceIdentity{} = signed_identity} <-
           ensure_signature_fields(signed_identity),
         {:ok, device_signature} <-
           generate_device_signature(
             signed_identity,
             details_bin,
             identity_pub,
             identity_priv,
             signature_prefix
           ) do
      signed_with_device = %{signed_identity | deviceSignature: device_signature}
      build_parsed_identity(signed_with_device, container, details_bin, hosted?, device_signature)
    end
  end

  # Parse direct ADVSignedDeviceIdentity (from device-identity in pair-success)
  @spec parse_direct_signed_identity(binary(), binary(), binary()) :: adv_result()
  defp parse_direct_signed_identity(adv_bytes, identity_pub, identity_priv) do
    with {:ok, signed_identity} <- decode_signed_identity(adv_bytes),
         {:ok, %ADVSignedDeviceIdentity{} = signed_identity} <-
           ensure_signature_fields(signed_identity),
         {:ok, device_signature} <-
           generate_device_signature(
             signed_identity,
             signed_identity.details,
             identity_pub,
             identity_priv,
             @adv_prefix_device_signature_generate
           ) do
      signed_with_device = %{signed_identity | deviceSignature: device_signature}

      build_parsed_identity(
        signed_with_device,
        nil,
        signed_identity.details,
        false,
        device_signature
      )
    else
      {:error, reason} = err ->
        Logger.error("[ADV] parse_direct_signed_identity failed: #{inspect(reason)}")
        err
    end
  end

  @spec build_parsed_identity(struct(), struct() | nil, binary(), boolean(), binary()) ::
          adv_result()
  defp build_parsed_identity(
         signed_with_device,
         container,
         details_bin,
         hosted?,
         device_signature
       ) do
    with {:ok, details} <- decode_details_relaxed(signed_with_device.details),
         {:ok, self_signed} <- encode_self_signed(signed_with_device) do
      {:ok,
       %{
         container: container,
         signed: signed_with_device,
         details: details,
         hosted?: hosted?,
         device_signature: device_signature,
         self_signed: self_signed,
         details_binary: details_bin
       }}
    end
  end

  @spec decode_container(binary()) :: {:ok, struct()} | {:error, {:adv_container_decode, term()}}
  defp decode_container(bytes) do
    case ADVSignedDeviceIdentityHMAC.decode(bytes) do
      {:ok, %ADVSignedDeviceIdentityHMAC{} = container} -> {:ok, container}
      {:error, reason} -> {:error, {:adv_container_decode, reason}}
    end
  end

  @spec ensure_details(term()) :: {:ok, binary()} | {:error, :adv_missing_details}
  defp ensure_details(details) when is_binary(details) and byte_size(details) > 0,
    do: {:ok, details}

  defp ensure_details(_), do: {:error, :adv_missing_details}

  @spec verify_hmac(binary(), binary(), binary(), binary()) ::
          :ok | {:error, :adv_hmac_mismatch | :adv_invalid_hmac}
  defp verify_hmac(details, hmac, secret, prefix)
       when is_binary(hmac) and byte_size(hmac) == 32 do
    expected = :crypto.mac(:hmac, :sha256, secret, prefix <> details)

    if hmac == expected, do: :ok, else: {:error, :adv_hmac_mismatch}
  end

  defp verify_hmac(_details, _hmac, _secret, _prefix), do: {:error, :adv_invalid_hmac}

  @spec decode_signed_identity(binary()) ::
          {:ok, struct()} | {:error, {:adv_signed_identity_decode, term()}}
  defp decode_signed_identity(details) do
    case ADVSignedDeviceIdentity.decode(details) do
      {:ok, %ADVSignedDeviceIdentity{} = signed} -> {:ok, signed}
      {:error, reason} -> {:error, {:adv_signed_identity_decode, reason}}
    end
  end

  # Only require accountSignatureKey - accountSignature may not be present in pair-success
  @spec ensure_signature_fields(struct()) ::
          {:ok, struct()} | {:error, :adv_invalid_account_signature_fields}
  defp ensure_signature_fields(
         %ADVSignedDeviceIdentity{
           accountSignatureKey: <<_::binary-size(32)>>,
           accountSignature: <<_::binary-size(64)>>
         } = signed
       ),
       do: {:ok, signed}

  # Also accept if only accountSignatureKey is present (common in pair-success)
  defp ensure_signature_fields(
         %ADVSignedDeviceIdentity{
           accountSignatureKey: <<_::binary-size(32)>>
         } = signed
       ),
       do: {:ok, signed}

  defp ensure_signature_fields(signed) do
    Logger.error(
      "[ADV] ensure_signature_fields failed: accountSignatureKey=#{inspect(signed.accountSignatureKey && byte_size(signed.accountSignatureKey))}, accountSignature=#{inspect(signed.accountSignature && byte_size(signed.accountSignature))}"
    )

    {:error, :adv_invalid_account_signature_fields}
  end

  @spec generate_device_signature(struct(), binary(), binary(), binary(), binary()) ::
          {:ok, binary()} | {:error, :adv_device_signature_failed}
  defp generate_device_signature(
         %ADVSignedDeviceIdentity{} = signed,
         _details,
         identity_pub,
         identity_priv,
         signature_prefix
       ) do
    details_inner = signed.details

    message = signature_prefix <> details_inner <> identity_pub <> signed.accountSignatureKey

    # Use XEdDSA (Signal's curve25519 signature scheme) - NOT plain Ed25519!
    # This matches whatsmeow's ecc.CalculateSignature(ecc.NewDjbECPrivateKey...)
    try do
      signature = SignalKeys.sign_message(identity_priv, message)
      {:ok, signature}
    rescue
      e ->
        Logger.error("[ADV] Device signature failed: #{inspect(e)}")
        {:error, :adv_device_signature_failed}
    end
  end

  @spec decode_details(binary()) :: {:ok, struct()} | {:error, {:adv_details_decode, term()}}
  defp decode_details(details) do
    case ADVDeviceIdentity.decode(details) do
      {:ok, %ADVDeviceIdentity{} = decoded} -> {:ok, decoded}
      {:error, reason} -> {:error, {:adv_details_decode, reason}}
    end
  end

  # WhatsApp can add new fields to ADVDeviceIdentity that older generated proto
  # modules do not understand. For pairing we only need stable fields such as keyIndex.
  @spec decode_details_relaxed(binary()) :: {:ok, relaxed_details()}
  defp decode_details_relaxed(details) do
    with {:error, reason} <- decode_details(details) do
      key_index = extract_key_index_from_details_blob(details)

      Logger.warning(
        "[ADV] decode_details_relaxed: falling back to partial details, " <>
          "keyIndex=#{inspect(key_index)} reason=#{inspect(reason)}"
      )

      {:ok, %{keyIndex: key_index, decode_error: reason}}
    end
  end

  @spec should_try_hmac_after_direct(map()) :: hmac_retry_decision()
  defp should_try_hmac_after_direct(%{
         signed: %ADVSignedDeviceIdentity{} = signed,
         details: details
       }) do
    details_decode_failed? = Map.has_key?(details, :decode_error)

    account_signature_valid? =
      is_binary(signed.accountSignature) and byte_size(signed.accountSignature) == 64

    if details_decode_failed? and not account_signature_valid?,
      do: :try_hmac,
      else: :skip
  end

  defp should_try_hmac_after_direct(_), do: :skip

  # Minimal protobuf parser for ADVDeviceIdentity keyIndex (field 3, varint).
  # This keeps pairing resilient when the generated proto cannot parse new fields.
  @spec extract_key_index_from_details_blob(binary()) :: key_index()
  defp extract_key_index_from_details_blob(blob) when is_binary(blob) do
    do_extract_key_index(blob)
  end

  @spec do_extract_key_index(binary()) :: key_index()
  defp do_extract_key_index(<<>>), do: nil

  defp do_extract_key_index(binary) do
    case decode_varint(binary) do
      {:ok, tag, rest} ->
        extract_key_index_field(Bitwise.band(tag, 0x07), Bitwise.bsr(tag, 3), rest)

      _ ->
        nil
    end
  end

  @spec extract_key_index_field(non_neg_integer(), non_neg_integer(), binary()) :: key_index()
  defp extract_key_index_field(0, field_num, rest) do
    case decode_varint(rest) do
      {:ok, value, tail} ->
        if field_num == 3, do: value, else: do_extract_key_index(tail)

      _ ->
        nil
    end
  end

  defp extract_key_index_field(1, _field_num, <<_skip::binary-size(8), tail::binary>>),
    do: do_extract_key_index(tail)

  defp extract_key_index_field(1, _field_num, _rest), do: nil

  defp extract_key_index_field(2, _field_num, rest) do
    with {:ok, len, tail} <- decode_varint(rest),
         true <- byte_size(tail) >= len do
      <<_value::binary-size(len), next::binary>> = tail
      do_extract_key_index(next)
    else
      _ -> nil
    end
  end

  defp extract_key_index_field(5, _field_num, <<_skip::binary-size(4), tail::binary>>),
    do: do_extract_key_index(tail)

  defp extract_key_index_field(5, _field_num, _rest), do: nil
  defp extract_key_index_field(_wire_type, _field_num, _rest), do: nil

  @spec decode_varint(binary()) :: varint_decode_result()
  defp decode_varint(binary), do: decode_varint(binary, 0, 0)

  @spec decode_varint(binary(), non_neg_integer(), non_neg_integer()) :: varint_decode_result()
  defp decode_varint(_, _, shift) when shift > 63, do: {:error, :invalid_varint}
  defp decode_varint(<<>>, _, _), do: {:error, :invalid_varint}

  defp decode_varint(<<byte, rest::binary>>, acc, shift) do
    value = Bitwise.bor(acc, Bitwise.bsl(Bitwise.band(byte, 0x7F), shift))

    if Bitwise.band(byte, 0x80) == 0 do
      {:ok, value, rest}
    else
      decode_varint(rest, value, shift + 7)
    end
  end

  @spec encode_self_signed(struct()) ::
          {:ok, binary()} | {:error, {:adv_self_signed_encode, term()}}
  defp encode_self_signed(%ADVSignedDeviceIdentity{} = signed) do
    case encode_signed_device_identity(signed, include_signature_key: false) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, {:adv_self_signed_encode, reason}}
    end
  end

  @spec ensure_binary_length(term(), pos_integer(), atom()) ::
          :ok | {:error, {:invalid_length, atom()}}
  defp ensure_binary_length(value, expected, _field)
       when is_binary(value) and byte_size(value) == expected,
       do: :ok

  defp ensure_binary_length(_value, _expected, field),
    do: {:error, {:invalid_length, field}}

  @spec extract_identity(map()) :: {:ok, identity_keypair()} | {:error, :invalid_identity_keypair}
  defp extract_identity(%{
         public: <<_::binary-size(32)>> = pub,
         private: <<_::binary-size(32)>> = priv
       }),
       do: {:ok, {pub, priv}}

  defp extract_identity(_), do: {:error, :invalid_identity_keypair}
end
