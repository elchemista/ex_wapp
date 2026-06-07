defmodule ExWapp.Pairing.ADV do
  @moduledoc """
  Helpers for parsing and validating WhatsApp ADV (Account Device Verification) payloads.

  Pair-success `device-identity` arrives as an `ADVSignedDeviceIdentityHMAC`
  container in both Baileys and whatsmeow. The inner payload is an
  `ADVSignedDeviceIdentity`.

  Outbound message `device-identity` nodes and pair-success ACK payloads use the
  direct `ADVSignedDeviceIdentity` bytes instead.

  The methods below verify the pair-success HMAC using the stored ADV secret,
  validate the server account signature, and prepare the client device
  signature that must be echoed back to WhatsApp once pairing completes.
  """

  require Logger

  alias ExWapp.Signal.Keys, as: SignalKeys
  alias WAAdv.{ADVDeviceIdentity, ADVSignedDeviceIdentity, ADVSignedDeviceIdentityHMAC}

  @adv_prefix_account_signature <<6, 0>>
  @adv_prefix_device_signature_generate <<6, 1>>
  @adv_hosted_prefix_device_identity_account_signature <<6, 5>>

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
      # Upstream clients parse pair-success as an HMAC-wrapped ADV container
      # first. Keep a direct fallback for self-signed/raw blobs used in other
      # contexts and for debugging malformed fixtures.
      case parse_hmac_container(adv_bytes, adv_secret, identity_pub, identity_priv) do
        {:ok, parsed} ->
          {:ok, parsed}

        {:error, {:adv_container_decode, container_error}} ->
          Logger.warning(
            "[ADV] HMAC container decode failed: #{inspect(container_error)}, trying direct signed identity"
          )

          parse_direct_signed_identity(adv_bytes, identity_pub, identity_priv)

        {:error, :adv_invalid_hmac} ->
          Logger.warning("[ADV] HMAC wrapper missing/invalid, trying direct signed identity")

          parse_direct_signed_identity(adv_bytes, identity_pub, identity_priv)

        {:error, :adv_missing_details} ->
          Logger.warning("[ADV] HMAC wrapper missing details, trying direct signed identity")

          parse_direct_signed_identity(adv_bytes, identity_pub, identity_priv)

        {:error, reason} ->
          {:error, reason}
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

  # Parse HMAC-wrapped ADV (from pair-success device-identity)
  @spec parse_hmac_container(binary(), binary(), binary(), binary()) :: adv_result()
  defp parse_hmac_container(adv_bytes, adv_secret, identity_pub, identity_priv) do
    case decode_container(adv_bytes) do
      {:ok, %ADVSignedDeviceIdentityHMAC{} = container} ->
        parse_hmac_wrapped(container, adv_secret, identity_pub, identity_priv)

      {:error, container_error} ->
        Logger.error("[ADV] HMAC container decode failed: #{inspect(container_error)}")
        {:error, container_error}
    end
  end

  @spec parse_hmac_wrapped(struct(), binary(), binary(), binary()) :: adv_result()
  defp parse_hmac_wrapped(container, adv_secret, identity_pub, identity_priv) do
    hosted? = container.accountType == :HOSTED

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
         :ok <- verify_account_signature(signed_identity, identity_pub),
         {:ok, device_signature} <-
           generate_device_signature(signed_identity, identity_pub, identity_priv) do
      signed_with_device = %{signed_identity | deviceSignature: device_signature}
      build_parsed_identity(signed_with_device, container, details_bin, hosted?, device_signature)
    end
  end

  # Parse direct ADVSignedDeviceIdentity.
  #
  # This is not the normal pair-success wire shape, but it is the raw shape used
  # for pair-device-sign ACKs and outbound message device identities. Keeping a
  # fallback here makes the parser more robust to legacy fixtures and local
  # debugging helpers.
  @spec parse_direct_signed_identity(binary(), binary(), binary()) :: adv_result()
  defp parse_direct_signed_identity(adv_bytes, identity_pub, identity_priv) do
    with {:ok, signed_identity} <- decode_signed_identity(adv_bytes),
         {:ok, %ADVSignedDeviceIdentity{} = signed_identity} <-
           ensure_signature_fields(signed_identity),
         :ok <- verify_account_signature(signed_identity, identity_pub),
         {:ok, device_signature} <-
           generate_device_signature(signed_identity, identity_pub, identity_priv) do
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

  @spec verify_account_signature(struct(), binary()) ::
          :ok | {:error, :adv_invalid_account_signature}
  defp verify_account_signature(
         %ADVSignedDeviceIdentity{
           details: details,
           accountSignatureKey: account_signature_key,
           accountSignature: account_signature
         },
         identity_pub
       )
       when is_binary(details) and is_binary(account_signature_key) and
              is_binary(account_signature) and is_binary(identity_pub) do
    # The server proves ownership of accountSignatureKey by signing
    # prefix <> ADVDeviceIdentity.details <> linked-device identity public key.
    # The prefix follows the inner ADVDeviceIdentity.deviceType in upstream
    # clients, while the outer HMAC prefix follows the container accountType.
    message = account_signature_prefix_from_details(details) <> details <> identity_pub

    # WhatsApp signs ADV account signatures with a Curve25519/DJB key and the
    # Signal/XEdDSA scheme, not a plain Ed25519 public key. Real pair-success
    # payloads can therefore raise curve/subgroup errors if we route them
    # through Ed25519 verification.
    try do
      if SignalKeys.verify_message(account_signature_key, message, account_signature) do
        :ok
      else
        Logger.error("[ADV] account signature verification failed")
        {:error, :adv_invalid_account_signature}
      end
    rescue
      exception ->
        Logger.error(
          "[ADV] account signature verification raised: #{Exception.message(exception)}"
        )

        {:error, :adv_invalid_account_signature}
    end
  end

  defp verify_account_signature(_signed, _identity_pub),
    do: {:error, :adv_invalid_account_signature}

  @spec decode_signed_identity(binary()) ::
          {:ok, struct()} | {:error, {:adv_signed_identity_decode, term()}}
  defp decode_signed_identity(details) do
    case ADVSignedDeviceIdentity.decode(details) do
      {:ok, %ADVSignedDeviceIdentity{} = signed} -> {:ok, signed}
      {:error, reason} -> {:error, {:adv_signed_identity_decode, reason}}
    end
  end

  # Pair-success must include both the account signature key and signature.
  # Being permissive here can allow an invalid linked device to survive pairing
  # and then get removed by the server on the first reconnect.
  @spec ensure_signature_fields(struct()) ::
          {:ok, struct()} | {:error, :adv_invalid_account_signature_fields}
  defp ensure_signature_fields(
         %ADVSignedDeviceIdentity{
           accountSignatureKey: <<_::binary-size(32)>>,
           accountSignature: <<_::binary-size(64)>>
         } = signed
       ),
       do: {:ok, signed}

  defp ensure_signature_fields(signed) do
    Logger.error(
      "[ADV] ensure_signature_fields failed: accountSignatureKey=#{inspect(signed.accountSignatureKey && byte_size(signed.accountSignatureKey))}, accountSignature=#{inspect(signed.accountSignature && byte_size(signed.accountSignature))}"
    )

    {:error, :adv_invalid_account_signature_fields}
  end

  @spec account_signature_prefix(atom()) :: binary()
  defp account_signature_prefix(:HOSTED), do: @adv_hosted_prefix_device_identity_account_signature
  defp account_signature_prefix(_), do: @adv_prefix_account_signature

  @spec account_signature_prefix_from_details(binary()) :: binary()
  defp account_signature_prefix_from_details(details) when is_binary(details) do
    case decode_details(details) do
      {:ok, %ADVDeviceIdentity{deviceType: device_type}} ->
        account_signature_prefix(device_type)

      _ ->
        @adv_prefix_account_signature
    end
  end

  @spec generate_device_signature(struct(), binary(), binary()) ::
          {:ok, binary()} | {:error, :adv_device_signature_failed}
  defp generate_device_signature(
         %ADVSignedDeviceIdentity{} = signed,
         identity_pub,
         identity_priv
       ) do
    message =
      @adv_prefix_device_signature_generate <>
        signed.details <> identity_pub <> signed.accountSignatureKey

    # Baileys and whatsmeow both use the normal 0x06 0x01 device-signature
    # prefix here, even for hosted device identities. Only the HMAC/account
    # signature prefixes switch to the hosted variant.
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
      <<_value::binary-size(^len), next::binary>> = tail
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
