defmodule ExWapp.Signal.SenderKey do
  @moduledoc """
  Group sender-key support for WhatsApp `skmsg` payloads.

  Handles:
  - processing sender key distribution messages from decrypted WA message payloads
  - decrypting sender-key group messages (`enc type="skmsg"`)
  """

  import Bitwise

  require Logger

  alias ExWapp.{JID, Store}
  alias ExWapp.Signal.{Keys, WireFormat}

  @current_version 3
  @max_future_messages 2000
  @max_cached_message_keys 2000
  @max_state_ids 5
  @hkdf_info "WhisperGroup"

  @type sender_key_message_keys :: %{
          iv: binary(),
          cipher_key: binary()
        }

  @type sender_key_state :: %{
          id: non_neg_integer(),
          iteration: non_neg_integer(),
          chain_key: binary(),
          signing_key: binary(),
          signing_private: binary() | nil,
          message_keys: %{optional(non_neg_integer()) => sender_key_message_keys()}
        }

  @doc """
  Parses and persists any sender key distribution payloads found inside a decrypted
  WhatsApp message protobuf.

  Returns `{:ok, processed_count}`.
  """
  @spec process_distributions_from_plaintext(Store.t() | nil, term(), term(), binary()) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def process_distributions_from_plaintext(nil, _group_jid_hint, _sender_jid, _plaintext),
    do: {:error, :missing_store}

  def process_distributions_from_plaintext(store, group_jid_hint, sender_jid, plaintext)
      when is_binary(plaintext) do
    normalized_sender = normalize_jid(sender_jid)
    normalized_group_hint = normalize_jid(group_jid_hint)

    if normalized_sender == "" do
      {:error, :invalid_sender_jid}
    else
      distributions = parse_sender_key_distributions(plaintext)

      processed_count =
        Enum.reduce(distributions, 0, fn distribution, acc ->
          group_jid = normalize_group_jid(distribution.group_jid, normalized_group_hint)
          acc + process_single_distribution(store, distribution, group_jid, normalized_sender)
        end)

      {:ok, processed_count}
    end
  end

  def process_distributions_from_plaintext(_store, _group_jid_hint, _sender_jid, _plaintext),
    do: {:error, :invalid_plaintext}

  defp process_single_distribution(_store, _distribution, "", _sender), do: 0

  defp process_single_distribution(store, distribution, group_jid, sender) do
    case parse_axolotl_distribution_message(distribution.axolotl_distribution) do
      {:ok, parsed} ->
        store_parsed_distribution(store, parsed, group_jid, sender, distribution.source_field)

      {:error, reason} ->
        Logger.warning(
          "[SENDER_KEY] Failed to parse axolotl sender key distribution for sender=#{sender}: #{inspect(reason)}"
        )

        0
    end
  end

  defp store_parsed_distribution(store, parsed, group_jid, sender, source_field) do
    case WireFormat.deserialize_public_key(parsed.signing_key) do
      {:ok, signing_key} ->
        :ok =
          put_sender_key_state(store, group_jid, sender, parsed.id, %{
            id: parsed.id,
            iteration: parsed.iteration,
            chain_key: parsed.chain_key,
            signing_key: signing_key,
            message_keys: %{}
          })

        Logger.info(
          "[SENDER_KEY] Stored distribution: group=#{group_jid} sender=#{sender} id=#{parsed.id} iteration=#{parsed.iteration} source_field=#{source_field}"
        )

        1

      {:error, reason} ->
        Logger.warning(
          "[SENDER_KEY] Invalid signing key in distribution (group=#{group_jid} sender=#{sender}): #{inspect(reason)}"
        )

        0
    end
  end

  @doc """
  Decrypts a group sender-key message (`skmsg`) for a specific group and sender.
  """
  @spec decrypt_group_message(Store.t(), term(), term(), binary()) ::
          {:ok, binary()} | {:error, term()}
  def decrypt_group_message(store, group_jid, sender_jid, ciphertext)
      when is_binary(ciphertext) do
    normalized_group = normalize_jid(group_jid)
    normalized_sender = normalize_jid(sender_jid)

    with true <- normalized_group != "" or {:error, :invalid_group_jid},
         true <- normalized_sender != "" or {:error, :invalid_sender_jid},
         {:ok, parsed_message} <- parse_sender_key_message(ciphertext),
         {:ok, record, sender_state} <-
           get_sender_key_state(store, normalized_group, normalized_sender, parsed_message.id),
         :ok <- verify_sender_key_signature(parsed_message, sender_state.signing_key),
         {:ok, message_keys, updated_state} <-
           message_keys_for_iteration(sender_state, parsed_message.iteration),
         plaintext <-
           WireFormat.decrypt_aes_cbc(
             parsed_message.ciphertext,
             message_keys.cipher_key,
             message_keys.iv
           ),
         :ok <-
           put_sender_key_state(
             store,
             normalized_group,
             normalized_sender,
             parsed_message.id,
             updated_state,
             record
           ) do
      {:ok, plaintext}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def decrypt_group_message(_store, _group_jid, _sender_jid, _ciphertext),
    do: {:error, :invalid_ciphertext}

  @doc """
  Creates (or reuses) the local outbound sender-key state and returns a WA message
  payload containing `senderKeyDistributionMessage` (field 2).
  """
  @spec create_outbound_distribution_message(Store.t(), term(), term()) ::
          {:ok, binary()} | {:error, term()}
  def create_outbound_distribution_message(store, group_jid, sender_jid) do
    with {:ok, normalized_group, normalized_sender} <-
           normalize_outbound_sender_key_ids(group_jid, sender_jid),
         {:ok, _record, sender_state} <-
           ensure_outbound_sender_state(store, normalized_group, normalized_sender) do
      axolotl_distribution = encode_axolotl_distribution_message(sender_state)
      {:ok, encode_wa_sender_key_distribution_message(normalized_group, axolotl_distribution)}
    end
  end

  @doc """
  Encrypts plaintext for outbound group send as a sender-key message (`skmsg`).
  """
  @spec encrypt_outbound_group_message(Store.t(), term(), term(), binary()) ::
          {:ok, binary()} | {:error, term()}
  def encrypt_outbound_group_message(store, group_jid, sender_jid, plaintext)
      when is_binary(plaintext) do
    with {:ok, normalized_group, normalized_sender} <-
           normalize_outbound_sender_key_ids(group_jid, sender_jid),
         {:ok, record, sender_state} <-
           ensure_outbound_sender_state(store, normalized_group, normalized_sender),
         true <- is_binary(sender_state.signing_private) or {:error, :missing_signing_private_key} do
      {message_keys, updated_state} = derive_current_message_key(sender_state)
      ciphertext = WireFormat.encrypt_aes_cbc(plaintext, message_keys.cipher_key, message_keys.iv)

      version_and_proto =
        encode_sender_key_message(updated_state.id, sender_state.iteration, ciphertext)

      signature = Keys.sign_message(updated_state.signing_private, version_and_proto)

      :ok =
        put_sender_key_state(
          store,
          normalized_group,
          normalized_sender,
          updated_state.id,
          updated_state,
          record
        )

      {:ok, version_and_proto <> signature}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def encrypt_outbound_group_message(_store, _group_jid, _sender_jid, _plaintext),
    do: {:error, :invalid_plaintext}

  # ============================================================================
  # Sender key record persistence
  # ============================================================================

  defp get_sender_key_state(store, group_jid, sender_jid, key_id) do
    {record, sender_state} =
      store
      |> get_sender_key_record(group_jid, sender_jid)
      |> then(fn record ->
        {record, get_in(record, [:states, key_id])}
      end)

    if sender_state do
      {:ok, record, normalize_sender_state(sender_state, key_id)}
    else
      {:error, {:unknown_sender_key_id, key_id}}
    end
  end

  defp put_sender_key_state(
         store,
         group_jid,
         sender_jid,
         key_id,
         sender_state,
         existing_record \\ nil
       ) do
    {data, signal, sender_keys} = load_sender_key_maps(store)
    key = {group_jid, sender_jid}
    record = normalize_sender_key_record(existing_record || Map.get(sender_keys, key))

    state_ids =
      [key_id | Enum.reject(Map.get(record, :state_ids, []), &(&1 == key_id))]
      |> Enum.take(@max_state_ids)

    states =
      record
      |> Map.get(:states, %{})
      |> Map.put(key_id, sender_state)
      |> Map.take(state_ids)

    updated_record = %{
      current_id: key_id,
      state_ids: state_ids,
      states: states
    }

    updated_sender_keys = Map.put(sender_keys, key, updated_record)
    updated_signal = Map.put(signal, :sender_keys, updated_sender_keys)
    :ok = Store.persist(store, Map.put(data, :signal, updated_signal))
  end

  defp get_sender_key_record(store, group_jid, sender_jid) do
    {_data, _signal, sender_keys} = load_sender_key_maps(store)
    key = {group_jid, sender_jid}
    normalize_sender_key_record(Map.get(sender_keys, key))
  end

  defp normalize_sender_key_record(nil), do: %{current_id: nil, state_ids: [], states: %{}}

  # Backward compatibility with a single-state shape.
  defp normalize_sender_key_record(%{id: id} = state) when is_integer(id) do
    normalized_state = normalize_sender_state(state, id)

    %{
      current_id: id,
      state_ids: [id],
      states: %{id => normalized_state}
    }
  end

  defp normalize_sender_key_record(%{states: states} = record) when is_map(states) do
    state_ids =
      record
      |> Map.get(:state_ids, Map.keys(states))
      |> Enum.filter(&is_integer/1)
      |> Enum.uniq()
      |> Enum.take(@max_state_ids)

    normalized_states =
      states
      |> Enum.reduce(%{}, fn
        {id, state}, acc when is_integer(id) ->
          Map.put(acc, id, normalize_sender_state(state, id))

        _, acc ->
          acc
      end)
      |> Map.take(state_ids)

    current_id =
      case Map.get(record, :current_id) do
        id when is_integer(id) ->
          if Map.has_key?(normalized_states, id), do: id, else: List.first(state_ids)

        _ ->
          List.first(state_ids)
      end

    %{
      current_id: current_id,
      state_ids: state_ids,
      states: normalized_states
    }
  end

  defp normalize_sender_key_record(_), do: %{current_id: nil, state_ids: [], states: %{}}

  defp normalize_sender_state(state, key_id) when is_map(state) do
    %{
      id: Map.get(state, :id, key_id),
      iteration: Map.get(state, :iteration, 0),
      chain_key: Map.get(state, :chain_key, <<>>),
      signing_key: Map.get(state, :signing_key, <<>>),
      signing_private: normalize_optional_private_key(Map.get(state, :signing_private)),
      message_keys: normalize_message_key_cache(Map.get(state, :message_keys, %{}))
    }
  end

  defp normalize_optional_private_key(value) when is_binary(value) and byte_size(value) == 32,
    do: value

  defp normalize_optional_private_key(_), do: nil

  defp normalize_message_key_cache(cache) when is_map(cache) do
    cache
    |> Enum.reduce(%{}, fn
      {iteration, %{iv: iv, cipher_key: cipher_key}}, acc
      when is_integer(iteration) and is_binary(iv) and is_binary(cipher_key) ->
        Map.put(acc, iteration, %{iv: iv, cipher_key: cipher_key})

      _, acc ->
        acc
    end)
    |> trim_message_key_cache()
  end

  defp normalize_message_key_cache(_), do: %{}

  defp load_sender_key_maps(store) do
    data = Store.load!(store)
    signal = Map.get(data, :signal, %{})
    sender_keys = Map.get(signal, :sender_keys, %{})
    {data, signal, sender_keys}
  end

  # ============================================================================
  # Sender key message decrypt
  # ============================================================================

  defp normalize_outbound_sender_key_ids(group_jid, sender_jid) do
    normalized_group = normalize_jid(group_jid)
    normalized_sender = normalize_jid(sender_jid)

    cond do
      normalized_group == "" -> {:error, :invalid_group_jid}
      normalized_sender == "" -> {:error, :invalid_sender_jid}
      true -> {:ok, normalized_group, normalized_sender}
    end
  end

  defp ensure_outbound_sender_state(store, group_jid, sender_jid) do
    record = get_sender_key_record(store, group_jid, sender_jid)
    current_id = Map.get(record, :current_id)

    current_state =
      if is_integer(current_id), do: get_in(record, [:states, current_id]), else: nil

    normalized_state = normalize_sender_state(current_state || %{}, current_id || 0)

    if valid_outbound_sender_state?(normalized_state, current_id) do
      {:ok, record, normalized_state}
    else
      signing = Keys.generate_key_pair()
      new_id = generate_sender_key_id()

      new_state = %{
        id: new_id,
        iteration: 0,
        chain_key: :crypto.strong_rand_bytes(32),
        signing_key: signing.public,
        signing_private: signing.private,
        message_keys: %{}
      }

      :ok = put_sender_key_state(store, group_jid, sender_jid, new_id, new_state, record)
      {:ok, get_sender_key_record(store, group_jid, sender_jid), new_state}
    end
  end

  defp valid_outbound_sender_state?(state, current_id) do
    valid_sender_key_id?(current_id, state.id) and
      valid_sender_key_iteration?(state.iteration) and
      binary_of_size?(state.chain_key, 32) and
      binary_of_size?(state.signing_key, 32) and
      binary_of_size?(state.signing_private, 32)
  end

  defp valid_sender_key_id?(current_id, state_id),
    do: is_integer(current_id) and current_id >= 0 and state_id == current_id

  defp valid_sender_key_iteration?(iteration),
    do: is_integer(iteration) and iteration >= 0

  defp binary_of_size?(value, size),
    do: is_binary(value) and byte_size(value) == size

  defp generate_sender_key_id do
    <<value::32>> = :crypto.strong_rand_bytes(4)
    value &&& 0x7FFFFFFF
  end

  defp encode_axolotl_distribution_message(sender_state) do
    signing_key = WireFormat.serialize_public_key(sender_state.signing_key)

    <<sender_key_version_byte()>> <>
      encode_uint_field(1, sender_state.id) <>
      encode_uint_field(2, sender_state.iteration) <>
      encode_bytes_field(3, sender_state.chain_key) <>
      encode_bytes_field(4, signing_key)
  end

  defp encode_wa_sender_key_distribution_message(group_jid, axolotl_distribution) do
    distribution =
      encode_bytes_field(1, group_jid) <>
        encode_bytes_field(2, axolotl_distribution)

    # WA E2E Message field 2: senderKeyDistributionMessage
    encode_bytes_field(2, distribution)
  end

  defp encode_sender_key_message(id, iteration, ciphertext) do
    <<sender_key_version_byte()>> <>
      encode_uint_field(1, id) <>
      encode_uint_field(2, iteration) <>
      encode_bytes_field(3, ciphertext)
  end

  defp sender_key_version_byte do
    (@current_version <<< 4 ||| @current_version) &&& 0xFF
  end

  defp verify_sender_key_signature(parsed_message, signing_key) do
    if Keys.verify_message(
         signing_key,
         parsed_message.version_and_proto,
         parsed_message.signature
       ) do
      :ok
    else
      {:error, :invalid_sender_key_signature}
    end
  end

  defp message_keys_for_iteration(sender_state, iteration)
       when is_integer(iteration) and iteration >= 0 do
    cond do
      sender_state.iteration > iteration ->
        case Map.pop(sender_state.message_keys, iteration) do
          {nil, _} ->
            {:error, :old_sender_key_iteration}

          {cached_keys, updated_cache} ->
            {:ok, cached_keys, %{sender_state | message_keys: updated_cache}}
        end

      iteration - sender_state.iteration > @max_future_messages ->
        {:error, :sender_key_iteration_too_far_into_future}

      true ->
        sender_state_at_target = cache_message_keys_until_iteration(sender_state, iteration)
        {keys, next_state} = derive_current_message_key(sender_state_at_target)
        {:ok, keys, %{next_state | message_keys: trim_message_key_cache(next_state.message_keys)}}
    end
  end

  defp message_keys_for_iteration(_sender_state, _iteration),
    do: {:error, :invalid_sender_key_iteration}

  defp cache_message_keys_until_iteration(sender_state, target_iteration)
       when sender_state.iteration >= target_iteration do
    sender_state
  end

  defp cache_message_keys_until_iteration(sender_state, target_iteration) do
    {keys, next_state} = derive_current_message_key(sender_state)

    cache =
      Map.put(sender_state.message_keys, sender_state.iteration, keys) |> trim_message_key_cache()

    cache_message_keys_until_iteration(%{next_state | message_keys: cache}, target_iteration)
  end

  defp derive_current_message_key(sender_state) do
    seed = :crypto.mac(:hmac, :sha256, sender_state.chain_key, <<0x01>>)
    next_chain_key = :crypto.mac(:hmac, :sha256, sender_state.chain_key, <<0x02>>)
    keys = derive_sender_message_keys(seed)

    next_state = %{
      sender_state
      | chain_key: next_chain_key,
        iteration: sender_state.iteration + 1
    }

    {keys, next_state}
  end

  defp derive_sender_message_keys(seed) do
    prk = :crypto.mac(:hmac, :sha256, :binary.copy(<<0>>, 32), seed)
    t1 = :crypto.mac(:hmac, :sha256, prk, @hkdf_info <> <<1>>)
    t2 = :crypto.mac(:hmac, :sha256, prk, t1 <> @hkdf_info <> <<2>>)

    <<iv::binary-size(16), cipher_key::binary-size(32), _rest::binary>> = t1 <> t2

    %{
      iv: iv,
      cipher_key: cipher_key
    }
  end

  defp trim_message_key_cache(cache) when map_size(cache) <= @max_cached_message_keys, do: cache

  defp trim_message_key_cache(cache) do
    drop_count = map_size(cache) - @max_cached_message_keys
    to_drop = cache |> Map.keys() |> Enum.sort() |> Enum.take(drop_count)
    Enum.reduce(to_drop, cache, &Map.delete(&2, &1))
  end

  # ============================================================================
  # Sender key distribution parsing
  # ============================================================================

  defp parse_sender_key_distributions(payload) do
    case collect_length_delimited_fields(payload, [2, 15]) do
      {:ok, fields} -> Enum.flat_map(fields, &parse_distribution_field/1)
      {:error, _reason} -> []
    end
  end

  defp parse_distribution_field({field_num, raw_distribution}) do
    case parse_wa_sender_key_distribution(raw_distribution) do
      {:ok, parsed} ->
        [
          %{
            source_field: field_num,
            group_jid: parsed.group_jid,
            axolotl_distribution: parsed.axolotl_distribution
          }
        ]

      {:error, _reason} ->
        []
    end
  end

  defp parse_wa_sender_key_distribution(binary) when is_binary(binary) do
    with {:ok, fields, <<>>} <- decode_fields(binary, %{}),
         {:ok, group_jid} <- fetch_required_bytes(fields, 1),
         {:ok, axolotl_distribution} <- fetch_required_bytes(fields, 2) do
      {:ok, %{group_jid: group_jid, axolotl_distribution: axolotl_distribution}}
    end
  end

  defp parse_wa_sender_key_distribution(_), do: {:error, :invalid_distribution_message}

  defp parse_axolotl_distribution_message(<<version_byte, proto::binary>>) do
    version = version_byte >>> 4

    if version != @current_version do
      {:error, {:unsupported_sender_key_distribution_version, version}}
    else
      with {:ok, fields, <<>>} <- decode_fields(proto, %{}),
           {:ok, id} <- fetch_uint(fields, 1),
           {:ok, iteration} <- fetch_uint(fields, 2),
           {:ok, chain_key} <- fetch_required_bytes(fields, 3),
           {:ok, signing_key} <- fetch_required_bytes(fields, 4) do
        {:ok,
         %{
           id: id,
           iteration: iteration,
           chain_key: chain_key,
           signing_key: signing_key
         }}
      end
    end
  end

  defp parse_axolotl_distribution_message(_), do: {:error, :invalid_axolotl_distribution_message}

  defp parse_sender_key_message(binary) when is_binary(binary) and byte_size(binary) > 65 do
    payload_size = byte_size(binary) - 64
    <<version_and_proto::binary-size(payload_size), signature::binary-size(64)>> = binary
    <<version_byte, proto::binary>> = version_and_proto

    version = version_byte >>> 4

    if version != @current_version do
      {:error, {:unsupported_sender_key_message_version, version}}
    else
      with {:ok, fields, <<>>} <- decode_fields(proto, %{}),
           {:ok, id} <- fetch_uint(fields, 1),
           {:ok, iteration} <- fetch_uint(fields, 2),
           {:ok, ciphertext} <- fetch_required_bytes(fields, 3) do
        {:ok,
         %{
           id: id,
           iteration: iteration,
           ciphertext: ciphertext,
           signature: signature,
           version_and_proto: version_and_proto
         }}
      end
    end
  end

  defp parse_sender_key_message(_), do: {:error, :invalid_sender_key_message}

  # ============================================================================
  # Minimal protobuf decode helpers
  # ============================================================================

  defp collect_length_delimited_fields(<<>>, _field_nums), do: {:ok, []}

  defp collect_length_delimited_fields(binary, field_nums)
       when is_binary(binary) and is_list(field_nums) do
    do_collect_length_delimited_fields(binary, field_nums, [])
  end

  defp do_collect_length_delimited_fields(<<>>, _field_nums, acc), do: {:ok, Enum.reverse(acc)}

  defp do_collect_length_delimited_fields(binary, field_nums, acc) do
    with {:ok, tag, rest} <- decode_varint(binary) do
      field_num = tag >>> 3
      wire_type = tag &&& 0x07
      collect_wire_field(wire_type, field_num, rest, field_nums, acc)
    end
  end

  defp collect_wire_field(0, _field_num, rest, field_nums, acc) do
    with {:ok, _value, tail} <- decode_varint(rest) do
      do_collect_length_delimited_fields(tail, field_nums, acc)
    end
  end

  defp collect_wire_field(
         1,
         _field_num,
         <<_skip::binary-size(8), tail::binary>>,
         field_nums,
         acc
       ),
       do: do_collect_length_delimited_fields(tail, field_nums, acc)

  defp collect_wire_field(2, field_num, rest, field_nums, acc) do
    with {:ok, len, tail} <- decode_varint(rest),
         true <- byte_size(tail) >= len do
      <<value::binary-size(len), next::binary>> = tail
      next_acc = if field_num in field_nums, do: [{field_num, value} | acc], else: acc
      do_collect_length_delimited_fields(next, field_nums, next_acc)
    else
      false -> {:error, :invalid_length_delimited_field}
    end
  end

  defp collect_wire_field(
         5,
         _field_num,
         <<_skip::binary-size(4), tail::binary>>,
         field_nums,
         acc
       ),
       do: do_collect_length_delimited_fields(tail, field_nums, acc)

  defp collect_wire_field(wire_type, _field_num, _rest, _field_nums, _acc),
    do: {:error, {:unsupported_wire_type, wire_type}}

  defp decode_fields(<<>>, acc), do: {:ok, acc, <<>>}

  defp decode_fields(binary, acc) when is_binary(binary) do
    with {:ok, tag, rest} <- decode_varint(binary) do
      field_num = tag >>> 3
      wire_type = tag &&& 0x07
      decode_wire_field(wire_type, field_num, rest, acc)
    end
  end

  defp decode_wire_field(0, field_num, rest, acc) do
    with {:ok, value, tail} <- decode_varint(rest) do
      decode_fields(tail, Map.put(acc, field_num, value))
    end
  end

  defp decode_wire_field(1, _field_num, <<_skip::binary-size(8), tail::binary>>, acc),
    do: decode_fields(tail, acc)

  defp decode_wire_field(2, field_num, rest, acc) do
    with {:ok, len, tail} <- decode_varint(rest),
         true <- byte_size(tail) >= len do
      <<value::binary-size(len), next::binary>> = tail
      decode_fields(next, Map.put(acc, field_num, value))
    else
      false -> {:error, :invalid_length_delimited_field}
    end
  end

  defp decode_wire_field(5, _field_num, <<_skip::binary-size(4), tail::binary>>, acc),
    do: decode_fields(tail, acc)

  defp decode_wire_field(wire_type, _field_num, _rest, _acc),
    do: {:error, {:unsupported_wire_type, wire_type}}

  defp decode_varint(binary), do: decode_varint(binary, 0, 0)
  defp decode_varint(_, _, shift) when shift > 63, do: {:error, :invalid_varint}
  defp decode_varint(<<>>, _, _), do: {:error, :invalid_varint}

  defp decode_varint(<<byte, rest::binary>>, acc, shift) do
    value = bor(acc, bsl(band(byte, 0x7F), shift))

    if band(byte, 0x80) == 0 do
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

  defp fetch_uint(fields, field_num) do
    case Map.get(fields, field_num) do
      value when is_integer(value) and value >= 0 -> {:ok, value}
      nil -> {:error, {:missing_field, field_num}}
      _ -> {:error, {:invalid_uint_field, field_num}}
    end
  end

  defp encode_bytes_field(field_num, value) when is_integer(field_num) and is_binary(value) do
    tag = field_num <<< 3 ||| 2
    encode_varint(tag) <> encode_varint(byte_size(value)) <> value
  end

  defp encode_uint_field(field_num, value)
       when is_integer(field_num) and is_integer(value) and value >= 0 do
    tag = field_num <<< 3
    encode_varint(tag) <> encode_varint(value)
  end

  defp encode_varint(value) when is_integer(value) and value >= 0 and value < 128, do: <<value>>

  defp encode_varint(value) when is_integer(value) and value >= 128 do
    <<(value &&& 0x7F) ||| 0x80, encode_varint(value >>> 7)::binary>>
  end

  # ============================================================================
  # JID normalization
  # ============================================================================

  defp normalize_group_jid(group_jid_from_msg, fallback_group_jid) do
    normalized = normalize_jid(group_jid_from_msg)
    if normalized == "", do: fallback_group_jid, else: normalized
  end

  defp normalize_jid(%JID{} = jid), do: normalize_jid(JID.to_string(jid))
  defp normalize_jid(nil), do: ""

  defp normalize_jid(jid) when is_binary(jid) do
    trimmed =
      if String.valid?(jid) do
        String.trim(jid)
      else
        ""
      end

    if trimmed == "" do
      ""
    else
      String.replace(trimmed, "@whatsapp.net", "@s.whatsapp.net")
    end
  end

  defp normalize_jid(_), do: ""
end
