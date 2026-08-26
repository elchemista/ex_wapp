defmodule ExWapp.AppState.Engine.Codec do
  @moduledoc """
  Encoding and decoding helpers for app-state patches.

  This module owns the cryptographic transformation layer: it turns high-level
  patch descriptions into protobuf payloads for WhatsApp and validates incoming
  patch payloads back into decoded mutations that the local store can apply.
  """

  alias ExWapp.AppState.{Crypto, LTHash}
  alias ExWapp.JSON
  alias WAWebProtobufSyncAction.{SyncActionData, SyncActionValue}

  alias WAWebProtobufsServerSync.{
    KeyId,
    SyncdIndex,
    SyncdMutation,
    SyncdPatch,
    SyncdRecord,
    SyncdValue,
    SyncdVersion
  }

  alias ExWapp.Store

  @type mutation_info :: %{
          required(:index) => [String.t()],
          required(:version) => integer(),
          required(:value) => SyncActionValue.t(),
          optional(:operation) => :remove
        }

  @type patch_info :: %{
          type: String.t(),
          mutations: [mutation_info()],
          timestamp: integer() | nil
        }

  @type hash_state :: %{
          version: non_neg_integer(),
          hash: binary()
        }

  @type action_value :: SyncActionValue.t() | nil

  @type decoded_mutation :: %{
          operation: non_neg_integer(),
          action: action_value(),
          version: integer() | nil,
          index: [String.t()],
          index_mac: binary(),
          value_mac: binary()
        }

  @type syncd_mutation :: SyncdMutation.t()
  @type syncd_patch :: SyncdPatch.t()

  @doc """
  Encodes a high-level patch description into a `SyncdPatch` protobuf payload.

  The returned binary is ready to be embedded in the app-state IQ request, and
  the hash state / mutation MAC map are advanced to reflect the encoded patch.
  """
  @spec encode_patch(patch_info(), binary(), binary(), hash_state(), map()) ::
          {:ok, binary(), hash_state(), map()} | {:error, term()}
  def encode_patch(patch_info, key_id, key_data, hash_state, mutation_macs \\ %{}) do
    keys = Crypto.expand_keys(key_data)
    timestamp = patch_info[:timestamp] || System.system_time(:millisecond)
    collection_name = patch_info.type

    {mutations, value_macs, updated_macs} =
      encode_all_mutations(patch_info.mutations, keys, key_id, timestamp, mutation_macs)

    new_hash = compute_lthash_update(hash_state.hash, value_macs)
    new_version = hash_state.version + 1

    encoded =
      finalize_patch(mutations, value_macs, new_hash, new_version, collection_name, keys, key_id)

    new_hash_state = %{version: new_version, hash: new_hash}
    {:ok, encoded, new_hash_state, updated_macs}
  rescue
    error ->
      {:error, {:encode_patch_failed, error}}
  end

  @doc """
  Decodes a list of `SyncdMutation` records and optionally validates their MACs.
  """
  @spec decode_mutations([syncd_mutation()], map(), boolean()) ::
          {:ok, [decoded_mutation()]} | {:error, term()}
  def decode_mutations(mutations, key_store, validate_macs \\ true) do
    mutations
    |> Enum.reduce_while({:ok, []}, fn mutation, {:ok, acc} ->
      case decode_single_mutation(mutation, key_store, validate_macs) do
        {:ok, decoded} -> {:cont, {:ok, [decoded | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, reversed} -> {:ok, Enum.reverse(reversed)}
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Decodes a complete incoming patch and validates its hash-chain transition.

  Besides decoding each mutation, this verifies snapshot and patch MACs and
  returns the updated hash state plus the refreshed mutation-MAC map.
  """
  @spec decode_patch(syncd_patch(), String.t(), hash_state(), map(), map(), boolean()) ::
          {:ok, [decoded_mutation()], hash_state(), map()} | {:error, term()}
  def decode_patch(
        %SyncdPatch{} = patch,
        collection_name,
        hash_state,
        mutation_macs,
        key_store,
        validate_macs \\ true
      ) do
    with {:ok, patch_version} <- normalize_patch_version(patch.version, hash_state.version),
         {:ok, key_data} <- get_patch_key_data(patch, key_store),
         keys <- Crypto.expand_keys(key_data),
         {:ok, decoded_mutations} <- decode_mutations(patch.mutations, key_store, validate_macs),
         {:ok, new_hash} <-
           update_hash_for_patch(decoded_mutations, hash_state.hash, mutation_macs),
         :ok <-
           validate_snapshot_mac(
             patch,
             validate_macs,
             new_hash,
             patch_version,
             collection_name,
             keys
           ),
         :ok <-
           validate_patch_mac(
             patch,
             validate_macs,
             patch_version,
             collection_name,
             decoded_mutations,
             keys
           ),
         {:ok, updated_mutation_macs} <- update_mutation_macs(decoded_mutations, mutation_macs) do
      {:ok, decoded_mutations, %{version: patch_version, hash: new_hash}, updated_mutation_macs}
    end
  end

  @doc false
  @spec decode_snapshot_mutations(map(), map()) ::
          {:ok, [decoded_mutation()]} | {:error, term()}
  def decode_snapshot_mutations(snapshot, key_store) do
    with {:ok, mutations} <- build_snapshot_mutations(snapshot) do
      decode_mutations(mutations, key_store, true)
    end
  end

  @doc false
  @spec verify_snapshot(map(), [decoded_mutation()], integer(), String.t(), map()) ::
          {:ok, binary(), map()} | {:error, term()}
  def verify_snapshot(snapshot, decoded_mutations, version, collection_name, key_store) do
    with {:ok, key_data} <- get_snapshot_key_data(snapshot, key_store),
         keys <- Crypto.expand_keys(key_data),
         new_hash <- LTHash.add(LTHash.new(), Enum.map(decoded_mutations, & &1.value_mac)),
         :ok <-
           validate_snapshot_hash(
             snapshot.mac,
             keys.snapshot_mac,
             new_hash,
             version,
             collection_name
           ),
         {:ok, macs} <- update_mutation_macs(decoded_mutations, %{}) do
      {:ok, new_hash, macs}
    end
  end

  @doc false
  @spec normalize_patch_version(integer() | term()) :: {:ok, non_neg_integer()} | {:error, term()}
  def normalize_patch_version(%SyncdVersion{version: version}),
    do: normalize_patch_version(version)

  def normalize_patch_version(version) when is_integer(version) and version >= 0 do
    {:ok, version}
  end

  def normalize_patch_version(_version), do: {:error, :invalid_patch_version}

  @doc false
  @spec latest_app_state_key(struct()) :: {:ok, binary(), binary()} | {:error, term()}
  def latest_app_state_key(store) do
    data = Store.load!(store)
    app_state_keys = Map.get(data, :app_state_keys, %{})

    if map_size(app_state_keys) == 0 do
      {:error, :no_app_state_keys}
    else
      {key_id_hex, key_entry} =
        Enum.max_by(app_state_keys, fn {_id, entry} -> Map.get(entry, :timestamp, 0) end)

      case Base.decode16(key_id_hex, case: :mixed) do
        {:ok, key_id_binary} ->
          {:ok, key_id_binary, key_entry.data}

        :error ->
          {:error, {:invalid_key_id_hex, key_id_hex}}
      end
    end
  end

  defp encode_all_mutations(raw_mutations, keys, key_id, timestamp, mutation_macs) do
    Enum.reduce(raw_mutations, {[], [], mutation_macs}, fn mut, {muts, vmacs, mmacs} ->
      {mutation, value_mac, old_mac, operation, mmacs} =
        encode_single_mutation(mut, keys, key_id, timestamp, mmacs)

      {muts ++ [mutation], vmacs ++ [{value_mac, old_mac, operation}], mmacs}
    end)
  end

  defp encode_single_mutation(mut, keys, key_id, timestamp, mmacs) do
    operation = if Map.get(mut, :operation) == :remove, do: 1, else: 0
    value = %{mut.value | timestamp: timestamp}
    index_json = JSON.encode!(mut.index)

    content =
      %SyncActionData{
        index: index_json,
        value: value,
        padding: <<>>,
        version: mut.version
      }
      |> SyncActionData.encode!()
      |> IO.iodata_to_binary()

    {iv, ciphertext} = Crypto.encrypt_cbc(content, keys.value_encryption)
    encrypted = iv <> ciphertext

    value_mac =
      Crypto.compute_content_mac(operation, encrypted, key_id, keys.value_mac)

    index_mac = Crypto.compute_index_mac(index_json, keys.index)
    index_hex = Base.encode16(index_mac, case: :lower)
    old_mac = Map.get(mmacs, index_hex)

    updated_mmacs =
      if operation == 0,
        do: Map.put(mmacs, index_hex, value_mac),
        else: Map.delete(mmacs, index_hex)

    mutation = %SyncdMutation{
      operation: operation_enum(operation),
      record: %SyncdRecord{
        index: %SyncdIndex{blob: index_mac},
        value: %SyncdValue{blob: encrypted <> value_mac},
        keyID: %KeyId{ID: key_id}
      }
    }

    {mutation, value_mac, old_mac, operation, updated_mmacs}
  end

  defp compute_lthash_update(hash, value_macs) do
    subtract =
      value_macs
      |> Enum.map(fn {_new, old, _op} -> old end)
      |> Enum.reject(&is_nil/1)

    add =
      value_macs
      |> Enum.filter(fn {_new, _old, op} -> op == 0 end)
      |> Enum.map(fn {new_mac, _old, _op} -> new_mac end)

    LTHash.subtract_then_add(hash, subtract, add)
  end

  defp finalize_patch(mutations, value_macs, hash, version, collection, keys, key_id) do
    snapshot_mac =
      Crypto.compute_snapshot_mac(hash, version, collection, keys.snapshot_mac)

    all_value_macs =
      Enum.map(value_macs, fn {new_mac, _old, _op} -> new_mac end)

    patch_mac =
      Crypto.compute_patch_mac(
        snapshot_mac,
        all_value_macs,
        version,
        collection,
        keys.patch_mac
      )

    %SyncdPatch{
      # WhatsApp Web omits the patch version on outgoing mutations.
      mutations: mutations,
      snapshotMAC: snapshot_mac,
      patchMAC: patch_mac,
      keyID: %KeyId{ID: key_id}
    }
    |> SyncdPatch.encode!()
    |> IO.iodata_to_binary()
  end

  defp decode_single_mutation(%SyncdMutation{} = mutation, key_store, validate_macs) do
    record = mutation.record
    operation = operation_int(mutation.operation)
    index_mac = record_index_blob(record)

    with {:ok, keys, key_id} <- resolve_mutation_keys(record, key_store),
         {:ok, encrypted_content, value_mac} <- split_record_value(record_value_blob(record)),
         :ok <-
           verify_content_mac(
             operation,
             encrypted_content,
             key_id,
             keys,
             validate_macs,
             value_mac
           ),
         {:ok, plaintext} <- decrypt_content(encrypted_content, keys),
         {:ok, sync_data} <- decode_action_data(plaintext),
         :ok <- verify_index_mac(sync_data.index, index_mac, keys, validate_macs) do
      {:ok, build_decoded_mutation(operation, sync_data, index_mac, value_mac)}
    end
  end

  defp operation_enum(1), do: :REMOVE
  defp operation_enum(_operation), do: :SET

  defp operation_int(:REMOVE), do: 1
  defp operation_int(operation) when is_integer(operation), do: operation
  defp operation_int(_operation), do: 0

  defp record_index_blob(%SyncdRecord{index: %SyncdIndex{blob: blob}}), do: blob
  defp record_index_blob(_record), do: nil

  defp record_value_blob(%SyncdRecord{value: %SyncdValue{blob: blob}}), do: blob
  defp record_value_blob(_record), do: nil

  defp record_key_id(%SyncdRecord{keyID: %KeyId{ID: key_id}}), do: key_id
  defp record_key_id(_record), do: nil

  defp resolve_mutation_keys(record, key_store) do
    key_id = record_key_id(record)

    key_id_hex =
      if is_binary(key_id),
        do: Base.encode16(key_id, case: :lower),
        else: nil

    with {:ok, key_data} <- get_key_data(key_store, key_id_hex) do
      {:ok, Crypto.expand_keys(key_data), key_id}
    end
  end

  defp split_record_value(content)
       when is_binary(content) and byte_size(content) > 32 do
    content_len = byte_size(content) - 32

    {:ok, binary_part(content, 0, content_len), binary_part(content, content_len, 32)}
  end

  defp split_record_value(_content), do: {:error, :invalid_record_value}

  defp verify_content_mac(_op, _enc, _key_id, _keys, false, _mac), do: :ok

  defp verify_content_mac(op, encrypted, key_id, keys, true, value_mac) do
    expected =
      Crypto.compute_content_mac(op, encrypted, key_id, keys.value_mac)

    if Crypto.secure_compare(expected, value_mac),
      do: :ok,
      else: {:error, :mismatching_content_mac}
  end

  defp decrypt_content(encrypted, _keys) when byte_size(encrypted) < 16 do
    {:error, :encrypted_content_too_short}
  end

  defp decrypt_content(encrypted, keys) do
    iv = binary_part(encrypted, 0, 16)
    ct = binary_part(encrypted, 16, byte_size(encrypted) - 16)

    case Crypto.decrypt_cbc(ct, keys.value_encryption, iv) do
      {:ok, _plaintext} = ok -> ok
      {:error, reason} -> {:error, {:decrypt_failed, reason}}
    end
  end

  defp decode_action_data(plaintext) do
    case SyncActionData.decode(plaintext) do
      {:ok, _data} = ok -> ok
      {:error, reason} -> {:error, {:decode_sync_action_data_failed, reason}}
    end
  end

  defp verify_index_mac(_index_blob, _index_mac, _keys, false), do: :ok

  defp verify_index_mac(index_blob, index_mac, keys, true) when is_binary(index_blob) do
    expected = Crypto.compute_index_mac(index_blob, keys.index)

    if Crypto.secure_compare(expected, index_mac),
      do: :ok,
      else: {:error, :mismatching_index_mac}
  end

  defp verify_index_mac(_index_blob, _index_mac, _keys, _validate), do: :ok

  defp build_decoded_mutation(operation, sync_data, index_mac, value_mac) do
    index =
      case JSON.decode(sync_data.index || "[]") do
        {:ok, parsed} when is_list(parsed) -> parsed
        _ -> []
      end

    %{
      operation: operation,
      action: sync_data.value,
      version: sync_data.version,
      index: index,
      index_mac: index_mac,
      value_mac: value_mac
    }
  end

  defp build_snapshot_mutations(snapshot) do
    snapshot_key_id = snapshot.keyID

    mutations =
      Enum.map(snapshot.records, fn record ->
        record =
          if is_binary(record_key_id(record)),
            do: record,
            else: %{record | keyID: snapshot_key_id}

        %SyncdMutation{operation: :SET, record: record}
      end)

    {:ok, mutations}
  end

  defp get_snapshot_key_data(snapshot, key_store) do
    key_id = key_id_binary(snapshot.keyID) || snapshot_key_id_from_records(snapshot.records)

    if is_binary(key_id) do
      key_id_hex = Base.encode16(key_id, case: :lower)
      get_key_data(key_store, key_id_hex)
    else
      {:error, :missing_snapshot_key_id}
    end
  end

  defp key_id_binary(%KeyId{ID: key_id}) when is_binary(key_id), do: key_id
  defp key_id_binary(_key_id), do: nil

  defp snapshot_key_id_from_records(records) do
    Enum.find_value(records, &record_key_id/1)
  end

  defp normalize_patch_version(%SyncdVersion{version: version}, current_version),
    do: normalize_patch_version(version, current_version)

  defp normalize_patch_version(version, _current_version)
       when is_integer(version) and version >= 0 do
    {:ok, version}
  end

  defp normalize_patch_version(nil, current_version)
       when is_integer(current_version) and current_version >= 0 do
    {:ok, current_version + 1}
  end

  defp normalize_patch_version(_version, _current_version), do: {:error, :invalid_patch_version}

  defp get_patch_key_data(%SyncdPatch{keyID: %KeyId{ID: key_id}}, key_store)
       when is_binary(key_id) do
    key_id_hex = Base.encode16(key_id, case: :lower)
    get_key_data(key_store, key_id_hex)
  end

  defp get_patch_key_data(_patch, _key_store), do: {:error, :missing_patch_key_id}

  defp update_hash_for_patch(decoded_mutations, hash, mutation_macs) do
    {new_hash, _} =
      Enum.reduce(decoded_mutations, {hash, mutation_macs}, fn mutation, {acc_hash, acc_macs} ->
        index_hex = index_mac_hex(mutation.index_mac)
        old_mac = Map.get(acc_macs, index_hex)
        subtract_macs = if is_binary(old_mac), do: [old_mac], else: []
        add_macs = if mutation.operation == 0, do: [mutation.value_mac], else: []

        next_hash = LTHash.subtract_then_add(acc_hash, subtract_macs, add_macs)
        next_macs = put_mutation_mac(acc_macs, mutation)
        {next_hash, next_macs}
      end)

    {:ok, new_hash}
  rescue
    error ->
      {:error, {:hash_update_failed, error}}
  end

  defp validate_snapshot_mac(_patch, false, _hash, _version, _collection, _keys), do: :ok

  defp validate_snapshot_mac(%{snapshotMAC: nil}, true, _hash, _version, _collection, _keys),
    do: {:error, :invalid_snapshot_mac}

  defp validate_snapshot_mac(patch, true, hash, version, collection, keys) do
    expected =
      Crypto.compute_snapshot_mac(hash, version, collection, keys.snapshot_mac)

    compare_mac(expected, patch.snapshotMAC, :mismatching_snapshot_mac)
  end

  defp validate_patch_mac(_patch, false, _version, _collection, _mutations, _keys), do: :ok

  defp validate_patch_mac(%{snapshotMAC: s, patchMAC: p}, true, _v, _c, _m, _k)
       when not is_binary(s) or not is_binary(p),
       do: {:error, :invalid_patch_mac}

  defp validate_patch_mac(patch, true, version, collection, decoded_mutations, keys) do
    value_macs = Enum.map(decoded_mutations, & &1.value_mac)

    expected =
      Crypto.compute_patch_mac(
        patch.snapshotMAC,
        value_macs,
        version,
        collection,
        keys.patch_mac
      )

    compare_mac(expected, patch.patchMAC, :mismatching_patch_mac)
  end

  defp validate_snapshot_hash(mac, mac_key, hash, version, collection) do
    expected =
      Crypto.compute_snapshot_mac(hash, version, collection, mac_key)

    compare_mac(expected, mac, :mismatching_snapshot_mac)
  end

  defp compare_mac(expected, actual, error) do
    if Crypto.secure_compare(expected, actual), do: :ok, else: {:error, error}
  end

  defp update_mutation_macs(decoded_mutations, mutation_macs) when is_map(mutation_macs) do
    updated =
      Enum.reduce(decoded_mutations, mutation_macs, fn mutation, acc ->
        put_mutation_mac(acc, mutation)
      end)

    {:ok, updated}
  end

  defp update_mutation_macs(_decoded_mutations, _mutation_macs) do
    {:error, :invalid_mutation_macs}
  end

  defp put_mutation_mac(macs, mutation) do
    index_hex = index_mac_hex(mutation.index_mac)

    case mutation.operation do
      0 -> Map.put(macs, index_hex, mutation.value_mac)
      1 -> Map.delete(macs, index_hex)
      _ -> macs
    end
  end

  defp index_mac_hex(index_mac) when is_binary(index_mac) do
    Base.encode16(index_mac, case: :lower)
  end

  defp get_key_data(key_store, key_id_hex) when is_map(key_store) and is_binary(key_id_hex) do
    case Map.get(key_store, key_id_hex) do
      %{data: data} when is_binary(data) and byte_size(data) == 32 -> {:ok, data}
      nil -> {:error, {:key_not_found, key_id_hex}}
      other -> {:error, {:invalid_key_entry, other}}
    end
  end

  defp get_key_data(_, _), do: {:error, :invalid_key_store_or_id}
end
