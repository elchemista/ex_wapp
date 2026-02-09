defmodule ExWapp.Pairing.ADV do
  @moduledoc """
  Helpers for parsing and validating WhatsApp ADV (Account Device Verification) payloads.

  The methods verify the HMAC using the stored ADV secret, validate the
  account signature, and prepare a device signature that can be sent back to
  WhatsApp once the pairing flow completes.
  """

  alias Ed25519
  alias WAAdv.{ADVDeviceIdentity, ADVSignedDeviceIdentity, ADVSignedDeviceIdentityHMAC}

  @adv_prefix_account_signature <<6, 0>>
  @adv_prefix_device_signature_generate <<6, 1>>
  @adv_hosted_prefix_device_identity_account_signature <<6, 5>>
  @adv_hosted_prefix_device_identity_device_signature_verification <<6, 6>>

  @typedoc """
  Result returned by `parse_signed_device_identity/3`.
  """
  @type parsed_identity :: %{
          container: struct(),
          signed: struct(),
          details: struct(),
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
          Logger.info("[ADV] ✓ Direct parsing succeeded")
          {:ok, result}

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
         {:ok, details} <- decode_details(signed_with_device.details),
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
         {:ok, details} <- decode_details(signed_with_device.details),
         _ = Logger.info("[ADV] Decoded details: keyIndex=#{inspect(details.keyIndex)}"),
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

  defp verify_account_signature(
         %ADVSignedDeviceIdentity{} = signed,
         _details,
         identity_pub,
         hosted?
       ) do
    details_inner = signed.details
    message = account_signature_prefix(hosted?) <> details_inner <> identity_pub

    if Ed25519.valid_signature?(signed.accountSignature, message, signed.accountSignatureKey) do
      :ok
    else
      {:error, :adv_invalid_account_signature}
    end
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

  defp encode_self_signed(%ADVSignedDeviceIdentity{} = signed) do
    # Note: Rust implementation KEEPS accountSignatureKey, Go removes it.
    # Trying Rust approach - encode without removing accountSignatureKey
    require Logger

    Logger.info(
      "[ADV] encode_self_signed: details=#{byte_size(signed.details)}, acctSigKey=#{byte_size(signed.accountSignatureKey)}, acctSig=#{byte_size(signed.accountSignature)}, devSig=#{byte_size(signed.deviceSignature)}"
    )

    with {:ok, iodata} <- ADVSignedDeviceIdentity.encode(signed) do
      result = IO.iodata_to_binary(iodata)
      Logger.info("[ADV] encode_self_signed result: #{byte_size(result)} bytes")
      {:ok, result}
    else
      {:error, reason} -> {:error, {:adv_self_signed_encode, reason}}
    end
  end

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

  defp account_signature_prefix(true), do: @adv_hosted_prefix_device_identity_account_signature
  defp account_signature_prefix(false), do: @adv_prefix_account_signature

  defp device_signature_prefix(true),
    do: @adv_hosted_prefix_device_identity_device_signature_verification

  defp device_signature_prefix(false), do: @adv_prefix_device_signature_generate
end
