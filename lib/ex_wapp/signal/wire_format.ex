defmodule ExWapp.Signal.WireFormat do
  @moduledoc """
  Signal Protocol wire format implementation.

  Based on the official Signal Protocol specification and libsignal-protocol-java.

  Wire format:
  - SignalMessage: version_byte || protobuf || mac(8 bytes)
  - PreKeySignalMessage: version_byte || protobuf

  Key format:
  - Public keys are serialized as: 0x05 || 32-byte-key (33 bytes total)

  Version byte format:
  - (current_version << 4) | current_version
  - For version 3: 0x33
  """

  require Logger
  import Bitwise

  # Current Signal protocol version (current_version=3) - matches Go whatsmeow
  @current_version 3
  @version_byte 0x33

  # Key type prefix for Curve25519 (DJB type)
  @djb_type 0x05

  # MAC length in bytes (first 8 bytes of HMAC-SHA256)
  @mac_length 8

  # ============================================================================
  # Public API
  # ============================================================================

  @doc """
  Serializes a SignalMessage (whisper message).

  Args:
    - ratchet_key: 32-byte sender's current ratchet public key
    - counter: message counter
    - previous_counter: previous chain's counter
    - ciphertext: AES-CBC encrypted message
    - mac_key: key for HMAC
    - sender_identity: sender's identity public key
    - receiver_identity: receiver's identity public key

  Returns the serialized message bytes.
  """
  def serialize_signal_message(
        ratchet_key,
        counter,
        previous_counter,
        ciphertext,
        mac_key,
        sender_identity,
        receiver_identity
      ) do
    # Serialize ratchet key with type prefix
    serialized_ratchet_key = serialize_public_key(ratchet_key)

    # Build protobuf message
    proto_message = %{
      ratchetKey: serialized_ratchet_key,
      counter: counter,
      previousCounter: previous_counter,
      ciphertext: ciphertext
    }

    proto_bytes = encode_signal_message_proto(proto_message)

    # Version + proto (without MAC yet)
    version_and_proto = <<@version_byte>> <> proto_bytes

    # Calculate MAC over: sender_identity || receiver_identity || version || proto
    mac =
      calculate_mac(
        mac_key,
        sender_identity,
        receiver_identity,
        version_and_proto
      )

    # Final message: version || proto || mac
    version_and_proto <> mac
  end

  @doc """
  Serializes a PreKeySignalMessage.

  Args:
    - registration_id: sender's registration ID
    - prekey_id: one-time prekey ID (optional)
    - signed_prekey_id: signed prekey ID
    - base_key: ephemeral public key from X3DH
    - identity_key: sender's identity public key
    - signal_message: already-serialized SignalMessage bytes

  Returns the serialized prekey message bytes.
  """
  def serialize_prekey_signal_message(
        registration_id,
        prekey_id,
        signed_prekey_id,
        base_key,
        identity_key,
        signal_message
      ) do
    # Serialize keys with type prefix
    serialized_base_key = serialize_public_key(base_key)
    serialized_identity_key = serialize_public_key(identity_key)

    # Build protobuf message
    proto_message = %{
      registrationId: registration_id,
      signedPreKeyId: signed_prekey_id,
      baseKey: serialized_base_key,
      identityKey: serialized_identity_key,
      message: signal_message
    }

    # Add optional prekey_id if present
    proto_message =
      if prekey_id && prekey_id > 0 do
        Map.put(proto_message, :preKeyId, prekey_id)
      else
        proto_message
      end

    proto_bytes = encode_prekey_signal_message_proto(proto_message)

    # Version + proto
    <<@version_byte>> <> proto_bytes
  end

  @doc """
  Encrypts plaintext using AES-256-CBC with PKCS7 padding.

  This is the encryption used inside Signal messages (not AES-GCM!).
  """
  def encrypt_aes_cbc(plaintext, cipher_key, iv) do
    # PKCS7 padding
    block_size = 16
    padding_len = block_size - rem(byte_size(plaintext), block_size)
    padded = plaintext <> :binary.copy(<<padding_len>>, padding_len)

    # AES-256-CBC encryption
    :crypto.crypto_one_time(:aes_256_cbc, cipher_key, iv, padded, true)
  end

  @doc """
  Decrypts ciphertext using AES-256-CBC with PKCS7 padding removal.
  """
  def decrypt_aes_cbc(ciphertext, cipher_key, iv) do
    # AES-256-CBC decryption
    padded = :crypto.crypto_one_time(:aes_256_cbc, cipher_key, iv, ciphertext, false)

    # Remove PKCS7 padding
    padding_len = :binary.last(padded)

    if padding_len > 0 and padding_len <= 16 do
      binary_part(padded, 0, byte_size(padded) - padding_len)
    else
      padded
    end
  end

  @doc """
  Serializes a public key with the DJB type prefix (0x05).
  """
  def serialize_public_key(key) when byte_size(key) == 32 do
    <<@djb_type, key::binary>>
  end

  def serialize_public_key(<<@djb_type, _rest::binary>> = key) when byte_size(key) == 33 do
    # Already serialized
    key
  end

  @doc """
  Deserializes a public key, removing the type prefix.
  """
  def deserialize_public_key(<<@djb_type, key::binary-size(32)>>) do
    {:ok, key}
  end

  def deserialize_public_key(key) when byte_size(key) == 32 do
    # No prefix, return as-is
    {:ok, key}
  end

  def deserialize_public_key(_), do: {:error, :invalid_key_format}

  # ============================================================================
  # Protobuf Encoding (manual implementation to avoid dependency issues)
  # ============================================================================

  # SignalMessage protobuf fields:
  #   optional bytes  ratchetKey      = 1;
  #   optional uint32 counter         = 2;
  #   optional uint32 previousCounter = 3;
  #   optional bytes  ciphertext      = 4;
  defp encode_signal_message_proto(msg) do
    [
      encode_field(1, :bytes, msg[:ratchetKey]),
      encode_field(2, :uint32, msg[:counter]),
      encode_field(3, :uint32, msg[:previousCounter]),
      encode_field(4, :bytes, msg[:ciphertext])
    ]
    |> IO.iodata_to_binary()
  end

  # PreKeySignalMessage protobuf fields:
  #   optional uint32 preKeyId       = 1;
  #   optional bytes  baseKey        = 2;
  #   optional bytes  identityKey    = 3;
  #   optional bytes  message        = 4;
  #   optional uint32 registrationId = 5;
  #   optional uint32 signedPreKeyId = 6;
  defp encode_prekey_signal_message_proto(msg) do
    [
      encode_field(1, :uint32, msg[:preKeyId]),
      encode_field(2, :bytes, msg[:baseKey]),
      encode_field(3, :bytes, msg[:identityKey]),
      encode_field(4, :bytes, msg[:message]),
      encode_field(5, :uint32, msg[:registrationId]),
      encode_field(6, :uint32, msg[:signedPreKeyId])
    ]
    |> IO.iodata_to_binary()
  end

  defp encode_field(_field_num, _type, nil), do: <<>>
  # Note: We now always encode uint32 fields, even if 0, to match Go whatsmeow
  # defp encode_field(_field_num, :uint32, 0), do: <<>>

  defp encode_field(field_num, :bytes, value) when is_binary(value) do
    # Wire type 2 = length-delimited: tag || length || value
    tag = bor(field_num <<< 3, 2)
    [encode_varint(tag), encode_varint(byte_size(value)), value]
  end

  defp encode_field(field_num, :uint32, value) when is_integer(value) do
    # Wire type 0 = varint: tag || value
    tag = bor(field_num <<< 3, 0)
    [encode_varint(tag), encode_varint(value)]
  end

  @doc """
  Encodes an unsigned integer as a varint.
  """
  def encode_varint(value) when value < 128, do: <<value>>

  def encode_varint(value) do
    <<1::1, value::7, encode_varint(value >>> 7)::binary>>
  end

  # ============================================================================
  # MAC Calculation
  # ============================================================================

  defp calculate_mac(mac_key, sender_identity, receiver_identity, data) do
    # MAC is HMAC-SHA256 over: sender_identity_key || receiver_identity_key || data
    # Then truncated to first 8 bytes
    serialized_sender = serialize_public_key(sender_identity)
    serialized_receiver = serialize_public_key(receiver_identity)

    full_mac =
      :crypto.mac(:hmac, :sha256, mac_key, [
        serialized_sender,
        serialized_receiver,
        data
      ])

    binary_part(full_mac, 0, @mac_length)
  end

  # ============================================================================
  # Message Type Detection
  # ============================================================================

  @doc """
  Returns the message type atom for the given serialized message.
  """
  def message_type(<<version_byte, _rest::binary>>) do
    version = version_byte >>> 4

    if version == @current_version do
      :signal_message
    else
      {:unknown_version, version}
    end
  end

  def message_type(_), do: :invalid

  @doc """
  Parses a serialized SignalMessage.

  Returns map keys:
  - `:version_byte`
  - `:version_and_proto` (used for MAC verification)
  - `:mac`
  - `:ratchet_key` (32 bytes)
  - `:counter`
  - `:previous_counter`
  - `:ciphertext`
  """
  @spec parse_signal_message(binary()) :: {:ok, map()} | {:error, term()}
  def parse_signal_message(<<version_byte, rest::binary>>) when byte_size(rest) > @mac_length do
    version = version_byte >>> 4

    if version != @current_version do
      {:error, {:unknown_version, version}}
    else
      proto_size = byte_size(rest) - @mac_length
      <<proto::binary-size(proto_size), mac::binary-size(@mac_length)>> = rest

      with {:ok, fields, <<>>} <- decode_fields(proto, %{}),
           {:ok, serialized_ratchet_key} <- fetch_required_bytes(fields, 1),
           {:ok, ratchet_key} <- deserialize_public_key(serialized_ratchet_key),
           {:ok, ciphertext} <- fetch_required_bytes(fields, 4),
           {:ok, counter} <- fetch_uint(fields, 2, 0),
           {:ok, previous_counter} <- fetch_uint(fields, 3, 0) do
        {:ok,
         %{
           version_byte: version_byte,
           version_and_proto: <<version_byte>> <> proto,
           mac: mac,
           ratchet_key: ratchet_key,
           counter: counter,
           previous_counter: previous_counter,
           ciphertext: ciphertext
         }}
      end
    end
  end

  def parse_signal_message(_), do: {:error, :invalid_signal_message}

  @doc """
  Parses a serialized PreKeySignalMessage.

  Returns map keys:
  - `:version_byte`
  - `:registration_id`
  - `:prekey_id`
  - `:signed_prekey_id`
  - `:base_key`
  - `:identity_key`
  - `:message` (inner SignalMessage bytes)
  """
  @spec parse_prekey_signal_message(binary()) :: {:ok, map()} | {:error, term()}
  def parse_prekey_signal_message(<<version_byte, proto::binary>>) do
    version = version_byte >>> 4

    if version != @current_version do
      {:error, {:unknown_version, version}}
    else
      with {:ok, fields, <<>>} <- decode_fields(proto, %{}),
           {:ok, serialized_base_key} <- fetch_required_bytes(fields, 2),
           {:ok, serialized_identity_key} <- fetch_required_bytes(fields, 3),
           {:ok, base_key} <- deserialize_public_key(serialized_base_key),
           {:ok, identity_key} <- deserialize_public_key(serialized_identity_key),
           {:ok, inner_message} <- fetch_required_bytes(fields, 4),
           {:ok, registration_id} <- fetch_uint(fields, 5, 0),
           {:ok, signed_prekey_id} <- fetch_uint(fields, 6, 0),
           {:ok, prekey_id} <- fetch_optional_uint(fields, 1) do
        {:ok,
         %{
           version_byte: version_byte,
           registration_id: registration_id,
           prekey_id: prekey_id,
           signed_prekey_id: signed_prekey_id,
           base_key: base_key,
           identity_key: identity_key,
           message: inner_message
         }}
      end
    end
  end

  def parse_prekey_signal_message(_), do: {:error, :invalid_prekey_signal_message}

  @doc """
  Verifies the Signal MAC over `version_and_proto`.
  """
  @spec valid_signal_mac?(binary(), binary(), binary(), binary(), binary()) :: boolean()
  def valid_signal_mac?(mac, mac_key, sender_identity, receiver_identity, version_and_proto)
      when is_binary(mac) and is_binary(mac_key) and is_binary(sender_identity) and
             is_binary(receiver_identity) and is_binary(version_and_proto) do
    match?(
      {:ok, _strategy},
      verify_signal_mac(
        mac,
        mac_key,
        sender_identity,
        receiver_identity,
        version_and_proto
      )
    )
  end

  def valid_signal_mac?(_, _, _, _, _), do: false

  @doc """
  Verifies a Signal MAC with compatibility fallbacks used by production WA clients.

  Returns `{:ok, strategy}` when a check matches, or `:error` otherwise.
  """
  @spec verify_signal_mac(binary(), binary(), binary(), binary(), binary()) ::
          {:ok, atom()} | :error
  def verify_signal_mac(mac, mac_key, sender_identity, receiver_identity, version_and_proto)
      when is_binary(mac) and is_binary(mac_key) and is_binary(sender_identity) and
             is_binary(receiver_identity) and is_binary(version_and_proto) do
    checks = [
      {:prefixed_sender_receiver, &serialized_identity_bytes/1, sender_identity,
       receiver_identity},
      {:prefixed_receiver_sender, &serialized_identity_bytes/1, receiver_identity,
       sender_identity},
      {:raw_sender_receiver, &raw_identity_bytes/1, sender_identity, receiver_identity},
      {:raw_receiver_sender, &raw_identity_bytes/1, receiver_identity, sender_identity}
    ]

    Enum.reduce_while(checks, :error, fn {strategy, decode_fun, lhs, rhs}, _acc ->
      with {:ok, lhs_bytes} <- decode_fun.(lhs),
           {:ok, rhs_bytes} <- decode_fun.(rhs) do
        expected = calculate_mac_bytes(mac_key, lhs_bytes, rhs_bytes, version_and_proto)

        if secure_compare(mac, expected) do
          {:halt, {:ok, strategy}}
        else
          {:cont, :error}
        end
      else
        _ -> {:cont, :error}
      end
    end)
  end

  def verify_signal_mac(_, _, _, _, _), do: :error

  # ============================================================================
  # Protobuf Decoding (minimal parser for required fields)
  # ============================================================================

  defp decode_fields(<<>>, acc), do: {:ok, acc, <<>>}

  defp decode_fields(binary, acc) when is_binary(binary) do
    with {:ok, tag, rest} <- decode_varint(binary) do
      field_num = tag >>> 3
      wire_type = tag &&& 0x07

      case wire_type do
        0 ->
          with {:ok, value, tail} <- decode_varint(rest) do
            decode_fields(tail, Map.put(acc, field_num, value))
          end

        2 ->
          with {:ok, len, tail} <- decode_varint(rest),
               true <- byte_size(tail) >= len do
            <<value::binary-size(len), next::binary>> = tail
            decode_fields(next, Map.put(acc, field_num, value))
          else
            false -> {:error, :invalid_length_delimited_field}
          end

        # fixed64
        1 when byte_size(rest) >= 8 ->
          <<_skip::binary-size(8), tail::binary>> = rest
          decode_fields(tail, acc)

        # fixed32
        5 when byte_size(rest) >= 4 ->
          <<_skip::binary-size(4), tail::binary>> = rest
          decode_fields(tail, acc)

        _ ->
          {:error, {:unsupported_wire_type, wire_type}}
      end
    end
  end

  defp decode_varint(binary), do: decode_varint(binary, 0, 0)

  defp decode_varint(_, _, shift) when shift > 63, do: {:error, :invalid_varint}
  defp decode_varint(<<>>, _, _), do: {:error, :invalid_varint}

  defp decode_varint(<<byte, rest::binary>>, acc, shift) do
    value = acc ||| (byte &&& 0x7F) <<< shift

    if (byte &&& 0x80) == 0 do
      {:ok, value, rest}
    else
      decode_varint(rest, value, shift + 7)
    end
  end

  defp fetch_required_bytes(fields, field_num) do
    case Map.get(fields, field_num) do
      value when is_binary(value) -> {:ok, value}
      nil -> {:error, {:missing_field, field_num}}
      _ -> {:error, {:invalid_field_type, field_num}}
    end
  end

  defp fetch_uint(fields, field_num, default) do
    case Map.get(fields, field_num, default) do
      value when is_integer(value) and value >= 0 -> {:ok, value}
      _ -> {:error, {:invalid_uint_field, field_num}}
    end
  end

  defp fetch_optional_uint(fields, field_num) do
    case Map.get(fields, field_num) do
      nil -> {:ok, nil}
      value when is_integer(value) and value >= 0 -> {:ok, value}
      _ -> {:error, {:invalid_uint_field, field_num}}
    end
  end

  defp serialized_identity_bytes(identity) do
    case identity do
      <<@djb_type, _::binary-size(32)>> = key -> {:ok, key}
      <<_::binary-size(32)>> = key -> {:ok, serialize_public_key(key)}
      _ -> {:error, :invalid_identity}
    end
  end

  defp raw_identity_bytes(identity) do
    case identity do
      <<@djb_type, raw::binary-size(32)>> -> {:ok, raw}
      <<_::binary-size(32)>> = raw -> {:ok, raw}
      _ -> {:error, :invalid_identity}
    end
  end

  defp calculate_mac_bytes(mac_key, sender_identity_bytes, receiver_identity_bytes, data) do
    full_mac =
      :crypto.mac(:hmac, :sha256, mac_key, [
        sender_identity_bytes,
        receiver_identity_bytes,
        data
      ])

    binary_part(full_mac, 0, @mac_length)
  end

  defp secure_compare(a, b) when is_binary(a) and is_binary(b) and byte_size(a) == byte_size(b) do
    a
    |> :crypto.exor(b)
    |> :binary.bin_to_list()
    |> Enum.reduce(0, fn byte, acc -> acc ||| byte end)
    |> Kernel.==(0)
  end

  defp secure_compare(_, _), do: false
end
