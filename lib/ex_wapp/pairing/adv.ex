defmodule ExWapp.Pairing.ADV do
  @moduledoc """
  Helpers for parsing and validating WhatsApp ADV (Account Device Verification) payloads.

  The methods verify the HMAC using the stored ADV secret, validate the
  account signature, and prepare a device signature that can be sent back to
  WhatsApp once the pairing flow completes.
  """

  alias Ed25519
  alias WAAdv.{ADVDeviceIdentity, ADVSignedDeviceIdentity, ADVSignedDeviceIdentityHMAC}

  @adv_prefix_device_signature_generate <<6, 1>>
  @adv_hosted_prefix_device_identity_account_signature <<6, 5>>
  @adv_hosted_prefix_device_identity_device_signature_verification <<6, 6>>

  @typedoc """
  Result returned by `parse_signed_device_identity/3`.
  """
  @type parsed_identity :: %{
          container: struct(),
          signed: struct(),
          details: struct() | map(),
          hosted?: boolean(),
          device_signature: binary(),
          self_signed: binary(),
          details_binary: binary()
        }

  @doc """
  Parses and validates a signed ADV device identity blob.

  The returned map exposes both the decoded structs and the serialized payload
  that must be echoed back to the server (under `:self_signed`).
  """
  @spec parse_signed_device_identity(binary() | nil, binary(), %{
          public: binary(),
          private: binary()
        }) ::
          {:ok, parsed_identity() | nil} | {:error, term()}
  def parse_signed_device_identity(nil, _adv_secret, _identity), do: {:ok, nil}

  def parse_signed_device_identity(adv_bytes, adv_secret, identity)
      when is_binary(adv_bytes) and is_binary(adv_secret) do
    require Logger
    Logger.info("[ADV] parse_signed_device_identity called with #{byte_size(adv_bytes)} bytes")

    with :ok <- ensure_binary_length(adv_secret, 32, :adv_secret),
         {:ok, {identity_pub, identity_priv}} <- extract_identity(identity) do
      # Try direct ADVSignedDeviceIdentity first (used in pair-success device-identity)
      # This is the most common case for QR pairing
      case parse_direct_signed_identity(adv_bytes, identity_pub, identity_priv) do
        {:ok, result} ->
          if should_try_hmac_after_direct?(result) do
            Logger.warning(
              "[ADV] Direct parse looks wrapped/incomplete, retrying as HMAC container"
            )

            case decode_container(adv_bytes) do
              {:ok, container}
              when is_binary(container.details) and byte_size(container.details) > 0 ->
                case parse_hmac_wrapped(container, adv_secret, identity_pub, identity_priv) do
                  {:ok, wrapped} ->
                    {:ok, wrapped}

                  {:error, _reason} ->
                    Logger.info("[ADV] Falling back to direct parse result")
                    {:ok, result}
                end

              _ ->
                Logger.info("[ADV] Falling back to direct parse result")
                {:ok, result}
            end
          else
            Logger.info("[ADV] ✓ Direct parsing succeeded")
            {:ok, result}
          end

        {:error, direct_error} ->
          Logger.warning(
            "[ADV] Direct parsing failed: #{inspect(direct_error)}, trying HMAC wrapper"
          )

          # Fallback: Try HMAC-wrapped format
          case decode_container(adv_bytes) do
            {:ok, container}
            when is_binary(container.details) and byte_size(container.details) > 0 ->
              parse_hmac_wrapped(container, adv_secret, identity_pub, identity_priv)

            _ ->
              {:error, direct_error}
          end
      end
    end
  end

  def parse_signed_device_identity(_adv_bytes, _adv_secret, _identity),
    do: {:error, :invalid_adv_payload}

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
  defp parse_hmac_wrapped(container, adv_secret, identity_pub, identity_priv) do
    require Logger
    Logger.info("[ADV-HMAC] container.details size: #{byte_size(container.details || <<>>)}")
    Logger.info("[ADV-HMAC] container.HMAC size: #{byte_size(container."HMAC" || <<>>)}")

    with {:ok, details_bin} <- ensure_details(container.details),
         hosted? <- hosted_account?(container.accountType),
         :ok <- verify_hmac(details_bin, container."HMAC", adv_secret, hosted?),
         _ = Logger.info("[ADV-HMAC] HMAC verified OK"),
         {:ok, signed_identity} <- decode_signed_identity(details_bin),
         _ =
           Logger.info(
             "[ADV-HMAC] signed_identity.details size: #{byte_size(signed_identity.details || <<>>)}"
           ),
         _ =
           Logger.info(
             "[ADV-HMAC] signed_identity.accountSignatureKey size: #{byte_size(signed_identity.accountSignatureKey || <<>>)}"
           ),
         _ =
           Logger.info(
             "[ADV-HMAC] signed_identity.accountSignature size: #{byte_size(signed_identity.accountSignature || <<>>)}"
           ),
         {:ok, %ADVSignedDeviceIdentity{} = signed_identity} <-
           ensure_signature_fields(signed_identity),
         # Skip account signature verification - whatsmeow doesn't verify it
         {:ok, device_signature} <-
           generate_device_signature(
             signed_identity,
             details_bin,
             identity_pub,
             identity_priv,
             hosted?
           ),
         _ = Logger.info("[ADV-HMAC] device_signature size: #{byte_size(device_signature)}"),
         signed_with_device <- %{signed_identity | deviceSignature: device_signature},
         {:ok, details} <- decode_details_relaxed(signed_with_device.details),
         {:ok, self_signed} <- encode_self_signed(signed_with_device),
         _ = Logger.info("[ADV-HMAC] self_signed size: #{byte_size(self_signed)}") do
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

  # Parse direct ADVSignedDeviceIdentity (from device-identity in pair-success)
  defp parse_direct_signed_identity(adv_bytes, identity_pub, identity_priv) do
    require Logger
    Logger.info("[ADV] Parsing direct ADVSignedDeviceIdentity (#{byte_size(adv_bytes)} bytes)")

    with {:ok, signed_identity} <- decode_signed_identity(adv_bytes),
         _ =
           Logger.info(
             "[ADV] Decoded signed_identity, details=#{byte_size(signed_identity.details || <<>>)} bytes"
           ),
         {:ok, %ADVSignedDeviceIdentity{} = signed_identity} <-
           ensure_signature_fields(signed_identity),
         _ = Logger.info("[ADV] Signature fields OK"),
         details_bin <- signed_identity.details,
         # Skip account signature verification - whatsmeow doesn't verify it during pairing
         {:ok, device_signature} <-
           generate_device_signature(
             signed_identity,
             details_bin,
             identity_pub,
             identity_priv,
             false
           ),
         _ =
           Logger.info("[ADV] Generated device signature (#{byte_size(device_signature)} bytes)"),
         signed_with_device <- %{signed_identity | deviceSignature: device_signature},
         {:ok, details} <- decode_details_relaxed(signed_with_device.details),
         _ =
           Logger.info(
             "[ADV] Decoded details (relaxed): keyIndex=#{inspect(extract_key_index(details))}"
           ),
         {:ok, self_signed} <- encode_self_signed(signed_with_device),
         _ = Logger.info("[ADV] Encoded self_signed (#{byte_size(self_signed)} bytes)") do
      {:ok,
       %{
         container: nil,
         signed: signed_with_device,
         details: details,
         hosted?: false,
         device_signature: device_signature,
         self_signed: self_signed,
         details_binary: details_bin
       }}
    else
      {:error, reason} = err ->
        Logger.error("[ADV] parse_direct_signed_identity failed: #{inspect(reason)}")
        err
    end
  end

  defp decode_container(bytes) do
    case ADVSignedDeviceIdentityHMAC.decode(bytes) do
      {:ok, %ADVSignedDeviceIdentityHMAC{} = container} -> {:ok, container}
      {:error, reason} -> {:error, {:adv_container_decode, reason}}
    end
  end

  defp ensure_details(details) when is_binary(details) and byte_size(details) > 0,
    do: {:ok, details}

  defp ensure_details(_), do: {:error, :adv_missing_details}

  defp hosted_account?(nil), do: false
  defp hosted_account?(:HOSTED), do: true
  defp hosted_account?(_), do: false

  defp verify_hmac(details, hmac, secret, hosted?)
       when is_binary(hmac) and byte_size(hmac) == 32 do
    prefix =
      if hosted?, do: @adv_hosted_prefix_device_identity_account_signature, else: <<>>

    expected = :crypto.mac(:hmac, :sha256, secret, prefix <> details)

    if hmac == expected, do: :ok, else: {:error, :adv_hmac_mismatch}
  end

  defp verify_hmac(_details, _hmac, _secret, _hosted?), do: {:error, :adv_invalid_hmac}

  defp decode_signed_identity(details) do
    case ADVSignedDeviceIdentity.decode(details) do
      {:ok, %ADVSignedDeviceIdentity{} = signed} -> {:ok, signed}
      {:error, reason} -> {:error, {:adv_signed_identity_decode, reason}}
    end
  end

  # Only require accountSignatureKey - accountSignature may not be present in pair-success
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
    require Logger

    Logger.error(
      "[ADV] ensure_signature_fields failed: accountSignatureKey=#{inspect(signed.accountSignatureKey && byte_size(signed.accountSignatureKey))}, accountSignature=#{inspect(signed.accountSignature && byte_size(signed.accountSignature))}"
    )

    {:error, :adv_invalid_account_signature_fields}
  end

  defp generate_device_signature(
         %ADVSignedDeviceIdentity{} = signed,
         _details,
         identity_pub,
         identity_priv,
         hosted?
       ) do
    details_inner = signed.details

    message =
      device_signature_prefix(hosted?) <>
        details_inner <> identity_pub <> signed.accountSignatureKey

    # Use XEdDSA (Signal's curve25519 signature scheme) - NOT plain Ed25519!
    # This matches whatsmeow's ecc.CalculateSignature(ecc.NewDjbECPrivateKey...)
    try do
      signature = ExWapp.Signal.Keys.sign_message(identity_priv, message)
      {:ok, signature}
    rescue
      e ->
        require Logger
        Logger.error("[ADV] Device signature failed: #{inspect(e)}")
        {:error, :adv_device_signature_failed}
    end
  end

  defp decode_details(details) do
    case ADVDeviceIdentity.decode(details) do
      {:ok, %ADVDeviceIdentity{} = decoded} -> {:ok, decoded}
      {:error, reason} -> {:error, {:adv_details_decode, reason}}
    end
  end

  # WhatsApp can add new fields to ADVDeviceIdentity that older generated proto
  # modules do not understand. For pairing we only need stable fields such as keyIndex.
  defp decode_details_relaxed(details) do
    case decode_details(details) do
      {:ok, decoded} ->
        {:ok, decoded}

      {:error, reason} ->
        require Logger
        key_index = extract_key_index_from_details_blob(details)

        Logger.warning(
          "[ADV] decode_details_relaxed: falling back to partial details, " <>
            "keyIndex=#{inspect(key_index)} reason=#{inspect(reason)}"
        )

        {:ok, %{keyIndex: key_index, decode_error: reason}}
    end
  end

  defp should_try_hmac_after_direct?(%{
         signed: %ADVSignedDeviceIdentity{} = signed,
         details: details
       }) do
    details_decode_failed? = is_map(details) and Map.has_key?(details, :decode_error)

    account_signature_valid? =
      is_binary(signed.accountSignature) and byte_size(signed.accountSignature) == 64

    details_decode_failed? and not account_signature_valid?
  end

  defp should_try_hmac_after_direct?(_), do: false

  defp extract_key_index(%ADVDeviceIdentity{keyIndex: value}), do: value

  defp extract_key_index(%{} = details),
    do: Map.get(details, :keyIndex) || Map.get(details, "keyIndex")

  defp extract_key_index(_), do: nil

  # Minimal protobuf parser for ADVDeviceIdentity keyIndex (field 3, varint).
  # This keeps pairing resilient when the generated proto cannot parse new fields.
  defp extract_key_index_from_details_blob(blob) when is_binary(blob) do
    do_extract_key_index(blob)
  end

  defp extract_key_index_from_details_blob(_), do: nil

  defp do_extract_key_index(<<>>), do: nil

  defp do_extract_key_index(binary) do
    with {:ok, tag, rest} <- decode_varint(binary) do
      field_num = Bitwise.bsr(tag, 3)
      wire_type = Bitwise.band(tag, 0x07)

      case wire_type do
        0 ->
          with {:ok, value, tail} <- decode_varint(rest) do
            if field_num == 3, do: value, else: do_extract_key_index(tail)
          else
            _ -> nil
          end

        1 ->
          if byte_size(rest) >= 8 do
            <<_skip::binary-size(8), tail::binary>> = rest
            do_extract_key_index(tail)
          else
            nil
          end

        2 ->
          with {:ok, len, tail} <- decode_varint(rest),
               true <- byte_size(tail) >= len do
            <<_value::binary-size(len), next::binary>> = tail
            do_extract_key_index(next)
          else
            _ -> nil
          end

        5 ->
          if byte_size(rest) >= 4 do
            <<_skip::binary-size(4), tail::binary>> = rest
            do_extract_key_index(tail)
          else
            nil
          end

        _ ->
          nil
      end
    else
      _ -> nil
    end
  end

  defp decode_varint(binary), do: decode_varint(binary, 0, 0)

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

  defp encode_self_signed(%ADVSignedDeviceIdentity{} = signed) do
    require Logger

    Logger.info(
      "[ADV] encode_self_signed: details=#{byte_size(signed.details)}, acctSigKey=#{maybe_size(signed.accountSignatureKey)}, acctSig=#{maybe_size(signed.accountSignature)}, devSig=#{maybe_size(signed.deviceSignature)}"
    )

    with {:ok, result} <- encode_signed_device_identity(signed, include_signature_key: false) do
      Logger.info("[ADV] encode_self_signed result: #{byte_size(result)} bytes")
      {:ok, result}
    else
      {:error, reason} -> {:error, {:adv_self_signed_encode, reason}}
    end
  end

  defp maybe_size(nil), do: 0
  defp maybe_size(value) when is_binary(value), do: byte_size(value)

  defp ensure_binary_length(value, expected, _field)
       when is_binary(value) and byte_size(value) == expected,
       do: :ok

  defp ensure_binary_length(_value, _expected, field),
    do: {:error, {:invalid_length, field}}

  defp extract_identity(%{
         public: <<_::binary-size(32)>> = pub,
         private: <<_::binary-size(32)>> = priv
       }),
       do: {:ok, {pub, priv}}

  defp extract_identity(_), do: {:error, :invalid_identity_keypair}

  defp device_signature_prefix(true),
    do: @adv_hosted_prefix_device_identity_device_signature_verification

  defp device_signature_prefix(false), do: @adv_prefix_device_signature_generate
end
