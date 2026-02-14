# credo:disable-for-this-file
defmodule ExWapp.Proto.SyncAction do
  @moduledoc """
  Protobuf encode/decode for WhatsApp App State Sync messages.

  Covers:
  - SyncdPatch / SyncdMutation / SyncdRecord / SyncdSnapshot
  - SyncActionData / SyncActionValue
  - Individual action types (Contact, Archive, Delete, Pin, Mute, etc.)
  - AppStateSyncKeyShare / AppStateSyncKeyData (for key ingestion)

  Field numbers match whatsmeow `waServerSync` and `waSyncAction` proto definitions.
  """

  import Bitwise

  # ── SyncdPatch ──────────────────────────────────────────────
  # waServerSync.SyncdPatch
  # Field 1: version (SyncdVersion, submessage)
  # Field 2: mutations (repeated SyncdMutation)
  # Field 3: externalMutations (ExternalBlobReference) — skipped for now
  # Field 4: snapshotMAC (bytes)
  # Field 5: patchMAC (bytes)
  # Field 6: keyID (KeyId, submessage)

  defmodule SyncdPatch do
    @moduledoc false
    defstruct version: nil, mutations: [], snapshot_mac: nil, patch_mac: nil, key_id: nil
  end

  defmodule SyncdMutation do
    @moduledoc false
    # operation: 0 = SET, 1 = REMOVE
    defstruct operation: 0, record: nil
  end

  defmodule SyncdRecord do
    @moduledoc false
    defstruct index: nil, value: nil, key_id: nil
  end

  defmodule SyncdSnapshot do
    @moduledoc false
    defstruct version: nil, records: [], mac: nil, key_id: nil
  end

  defmodule SyncActionData do
    @moduledoc false
    defstruct index: nil, value: nil, padding: nil, version: nil
  end

  defmodule SyncActionValue do
    @moduledoc false
    defstruct timestamp: nil,
              star_action: nil,
              contact_action: nil,
              mute_action: nil,
              pin_action: nil,
              archive_chat_action: nil,
              delete_message_for_me_action: nil,
              mark_chat_as_read_action: nil,
              clear_chat_action: nil,
              delete_chat_action: nil,
              push_name_setting: nil,
              lid_contact_action: nil
  end

  defmodule ContactAction do
    @moduledoc false
    defstruct full_name: nil,
              first_name: nil,
              lid_jid: nil,
              save_on_primary: nil,
              pn_jid: nil,
              username: nil
  end

  defmodule MuteAction do
    @moduledoc false
    defstruct muted: nil, mute_end_timestamp: nil, auto_muted: nil
  end

  defmodule PinAction do
    @moduledoc false
    defstruct pinned: nil
  end

  defmodule ArchiveChatAction do
    @moduledoc false
    defstruct archived: nil, message_range: nil
  end

  defmodule DeleteChatAction do
    @moduledoc false
    defstruct message_range: nil
  end

  defmodule MarkChatAsReadAction do
    @moduledoc false
    defstruct read: nil, message_range: nil
  end

  defmodule ClearChatAction do
    @moduledoc false
    defstruct message_range: nil
  end

  defmodule SyncActionMessageRange do
    @moduledoc false
    defstruct last_message_timestamp: nil, messages: []
  end

  defmodule SyncActionMessage do
    @moduledoc false
    defstruct key: nil, timestamp: nil
  end

  defmodule PushNameSetting do
    @moduledoc false
    defstruct name: nil
  end

  defmodule AppStateSyncKeyShare do
    @moduledoc false
    defstruct keys: []
  end

  defmodule AppStateSyncKey do
    @moduledoc false
    defstruct key_id: nil, key_data: nil
  end

  defmodule AppStateSyncKeyData do
    @moduledoc false
    defstruct key_data: nil, fingerprint: nil, timestamp: nil
  end

  # ══════════════════════════════════════════════════════════════
  # ENCODING
  # ══════════════════════════════════════════════════════════════

  @doc "Encode a SyncdPatch to binary protobuf."
  def encode_syncd_patch(%SyncdPatch{} = patch) do
    []
    |> encode_submessage(1, encode_syncd_version(patch.version))
    |> encode_repeated_submessage(2, patch.mutations, &encode_syncd_mutation/1)
    |> encode_bytes(4, patch.snapshot_mac)
    |> encode_bytes(5, patch.patch_mac)
    |> encode_submessage(6, encode_key_id(patch.key_id))
    |> IO.iodata_to_binary()
  end

  @doc "Encode a SyncActionData to binary protobuf."
  def encode_sync_action_data(%SyncActionData{} = data) do
    []
    |> encode_bytes(1, data.index)
    |> encode_submessage(2, encode_sync_action_value(data.value))
    |> encode_bytes(3, data.padding)
    |> encode_varint_field(4, data.version)
    |> IO.iodata_to_binary()
  end

  # ── Individual encoders ──

  defp encode_syncd_version(nil), do: nil

  defp encode_syncd_version(version) when is_integer(version) do
    encode_varint_field([], 1, version) |> IO.iodata_to_binary()
  end

  defp encode_syncd_mutation(%SyncdMutation{} = m) do
    []
    |> encode_varint_field(1, m.operation)
    |> encode_submessage(2, encode_syncd_record(m.record))
    |> IO.iodata_to_binary()
  end

  defp encode_syncd_record(nil), do: nil

  defp encode_syncd_record(%SyncdRecord{} = r) do
    []
    |> encode_submessage(1, encode_syncd_index(r.index))
    |> encode_submessage(2, encode_syncd_value(r.value))
    |> encode_submessage(3, encode_key_id(r.key_id))
    |> IO.iodata_to_binary()
  end

  defp encode_syncd_index(nil), do: nil

  defp encode_syncd_index(blob) when is_binary(blob),
    do: encode_bytes([], 1, blob) |> IO.iodata_to_binary()

  defp encode_syncd_value(nil), do: nil

  defp encode_syncd_value(blob) when is_binary(blob),
    do: encode_bytes([], 1, blob) |> IO.iodata_to_binary()

  defp encode_key_id(nil), do: nil
  defp encode_key_id(id) when is_binary(id), do: encode_bytes([], 1, id) |> IO.iodata_to_binary()

  defp encode_sync_action_value(nil), do: nil

  defp encode_sync_action_value(%SyncActionValue{} = v) do
    []
    |> encode_varint_field(1, v.timestamp)
    |> encode_submessage(3, encode_contact_action(v.contact_action))
    |> encode_submessage(4, encode_mute_action(v.mute_action))
    |> encode_submessage(5, encode_pin_action(v.pin_action))
    |> encode_submessage(17, encode_archive_chat_action(v.archive_chat_action))
    |> encode_submessage(20, encode_mark_chat_as_read_action(v.mark_chat_as_read_action))
    |> encode_submessage(21, encode_clear_chat_action(v.clear_chat_action))
    |> encode_submessage(22, encode_delete_chat_action(v.delete_chat_action))
    |> encode_submessage(25, encode_push_name_setting(v.push_name_setting))
    |> IO.iodata_to_binary()
  end

  defp encode_contact_action(nil), do: nil

  defp encode_contact_action(%ContactAction{} = a) do
    []
    |> encode_string(1, a.full_name)
    |> encode_string(2, a.first_name)
    |> encode_string(3, a.lid_jid)
    |> encode_bool(4, a.save_on_primary)
    |> encode_string(5, a.pn_jid)
    |> encode_string(6, a.username)
    |> IO.iodata_to_binary()
  end

  defp encode_mute_action(nil), do: nil

  defp encode_mute_action(%MuteAction{} = a) do
    []
    |> encode_bool(1, a.muted)
    |> encode_varint_field(2, a.mute_end_timestamp)
    |> encode_bool(3, a.auto_muted)
    |> IO.iodata_to_binary()
  end

  defp encode_pin_action(nil), do: nil

  defp encode_pin_action(%PinAction{} = a) do
    encode_bool([], 1, a.pinned) |> IO.iodata_to_binary()
  end

  defp encode_archive_chat_action(nil), do: nil

  defp encode_archive_chat_action(%ArchiveChatAction{} = a) do
    []
    |> encode_bool(1, a.archived)
    |> encode_submessage(2, encode_message_range(a.message_range))
    |> IO.iodata_to_binary()
  end

  defp encode_delete_chat_action(nil), do: nil

  defp encode_delete_chat_action(%DeleteChatAction{} = a) do
    encode_submessage([], 1, encode_message_range(a.message_range)) |> IO.iodata_to_binary()
  end

  defp encode_mark_chat_as_read_action(nil), do: nil

  defp encode_mark_chat_as_read_action(%MarkChatAsReadAction{} = a) do
    []
    |> encode_bool(1, a.read)
    |> encode_submessage(2, encode_message_range(a.message_range))
    |> IO.iodata_to_binary()
  end

  defp encode_clear_chat_action(nil), do: nil

  defp encode_clear_chat_action(%ClearChatAction{} = a) do
    encode_submessage([], 1, encode_message_range(a.message_range)) |> IO.iodata_to_binary()
  end

  defp encode_push_name_setting(nil), do: nil

  defp encode_push_name_setting(%PushNameSetting{} = s) do
    encode_string([], 1, s.name) |> IO.iodata_to_binary()
  end

  defp encode_message_range(nil), do: nil

  defp encode_message_range(%SyncActionMessageRange{} = r) do
    []
    |> encode_varint_field(1, r.last_message_timestamp)
    |> encode_repeated_submessage(2, r.messages, &encode_sync_action_message/1)
    |> IO.iodata_to_binary()
  end

  defp encode_sync_action_message(%SyncActionMessage{} = m) do
    []
    |> encode_submessage(1, encode_message_key(m.key))
    |> encode_varint_field(2, m.timestamp)
    |> IO.iodata_to_binary()
  end

  defp encode_message_key(nil), do: nil

  defp encode_message_key(key) when is_map(key) do
    []
    |> encode_string(1, Map.get(key, :remote_jid) || Map.get(key, "remoteJid"))
    |> encode_bool(2, Map.get(key, :from_me) || Map.get(key, "fromMe"))
    |> encode_string(3, Map.get(key, :id) || Map.get(key, "id"))
    |> encode_string(4, Map.get(key, :participant) || Map.get(key, "participant"))
    |> IO.iodata_to_binary()
  end

  # ══════════════════════════════════════════════════════════════
  # DECODING
  # ══════════════════════════════════════════════════════════════

  @doc "Decode a SyncdPatch from binary protobuf."
  @spec decode_syncd_patch(binary()) :: {:ok, %SyncdPatch{}} | {:error, term()}
  def decode_syncd_patch(data) when is_binary(data) do
    with {:ok, fields} <- decode_wire_fields(data) do
      mutations =
        fields
        |> all_fields(2, 2)
        |> Enum.map(&decode_syncd_mutation_fields/1)

      {:ok,
       %SyncdPatch{
         version: decode_version_field(first_field(fields, 1, 2)),
         mutations: mutations,
         snapshot_mac: first_field(fields, 4, 2),
         patch_mac: first_field(fields, 5, 2),
         key_id: decode_key_id_field(first_field(fields, 6, 2))
       }}
    end
  end

  @doc "Decode a SyncdSnapshot from binary protobuf."
  @spec decode_syncd_snapshot(binary()) :: {:ok, %SyncdSnapshot{}} | {:error, term()}
  def decode_syncd_snapshot(data) when is_binary(data) do
    with {:ok, fields} <- decode_wire_fields(data) do
      records =
        fields
        |> all_fields(2, 2)
        |> Enum.map(&decode_syncd_record_fields/1)

      {:ok,
       %SyncdSnapshot{
         version: decode_version_field(first_field(fields, 1, 2)),
         records: records,
         mac: first_field(fields, 3, 2),
         key_id: decode_key_id_field(first_field(fields, 4, 2))
       }}
    end
  end

  @doc "Decode SyncActionData from binary protobuf."
  @spec decode_sync_action_data(binary()) :: {:ok, %SyncActionData{}} | {:error, term()}
  def decode_sync_action_data(data) when is_binary(data) do
    with {:ok, fields} <- decode_wire_fields(data) do
      value_bin = first_field(fields, 2, 2)

      value =
        if value_bin do
          case decode_sync_action_value(value_bin) do
            {:ok, v} -> v
            _ -> nil
          end
        end

      {:ok,
       %SyncActionData{
         index: first_field(fields, 1, 2),
         value: value,
         padding: first_field(fields, 3, 2),
         version: first_field(fields, 4, 0)
       }}
    end
  end

  @doc "Decode SyncActionValue from binary protobuf."
  @spec decode_sync_action_value(binary()) :: {:ok, %SyncActionValue{}} | {:error, term()}
  def decode_sync_action_value(data) when is_binary(data) do
    with {:ok, fields} <- decode_wire_fields(data) do
      {:ok,
       %SyncActionValue{
         timestamp: first_field(fields, 1, 0),
         contact_action: decode_sub(fields, 3, &decode_contact_action/1),
         mute_action: decode_sub(fields, 4, &decode_mute_action/1),
         pin_action: decode_sub(fields, 5, &decode_pin_action/1),
         archive_chat_action: decode_sub(fields, 17, &decode_archive_chat_action/1),
         mark_chat_as_read_action: decode_sub(fields, 20, &decode_mark_chat_as_read_action/1),
         clear_chat_action: decode_sub(fields, 21, &decode_clear_chat_action/1),
         delete_chat_action: decode_sub(fields, 22, &decode_delete_chat_action/1),
         push_name_setting: decode_sub(fields, 25, &decode_push_name_setting/1)
       }}
    end
  end

  @doc "Decode AppStateSyncKeyShare from binary protobuf (ProtocolMessage field 7)."
  @spec decode_app_state_sync_key_share(binary()) ::
          {:ok, %AppStateSyncKeyShare{}} | {:error, term()}
  def decode_app_state_sync_key_share(data) when is_binary(data) do
    with {:ok, fields} <- decode_wire_fields(data) do
      keys =
        fields
        |> all_fields(1, 2)
        |> Enum.map(&decode_app_state_sync_key/1)
        |> Enum.reject(&is_nil/1)

      {:ok, %AppStateSyncKeyShare{keys: keys}}
    end
  end

  # ── Individual decoders ──

  defp decode_syncd_mutation_fields(data) when is_binary(data) do
    case decode_wire_fields(data) do
      {:ok, fields} ->
        %SyncdMutation{
          operation: first_field(fields, 1, 0) || 0,
          record: decode_syncd_record_fields(first_field(fields, 2, 2))
        }

      _ ->
        %SyncdMutation{}
    end
  end

  defp decode_syncd_record_fields(nil), do: nil

  defp decode_syncd_record_fields(data) when is_binary(data) do
    case decode_wire_fields(data) do
      {:ok, fields} ->
        %SyncdRecord{
          index: decode_blob_field(first_field(fields, 1, 2)),
          value: decode_blob_field(first_field(fields, 2, 2)),
          key_id: decode_key_id_field(first_field(fields, 3, 2))
        }

      _ ->
        nil
    end
  end

  defp decode_version_field(nil), do: nil

  defp decode_version_field(data) when is_binary(data) do
    case decode_wire_fields(data) do
      {:ok, fields} -> first_field(fields, 1, 0)
      _ -> nil
    end
  end

  defp decode_key_id_field(nil), do: nil

  defp decode_key_id_field(data) when is_binary(data) do
    case decode_wire_fields(data) do
      {:ok, fields} -> first_field(fields, 1, 2)
      _ -> nil
    end
  end

  defp decode_blob_field(nil), do: nil

  defp decode_blob_field(data) when is_binary(data) do
    case decode_wire_fields(data) do
      {:ok, fields} -> first_field(fields, 1, 2)
      _ -> data
    end
  end

  defp decode_contact_action(data) do
    with {:ok, fields} <- decode_wire_fields(data) do
      {:ok,
       %ContactAction{
         full_name: first_field(fields, 1, 2),
         first_name: first_field(fields, 2, 2),
         lid_jid: first_field(fields, 3, 2),
         save_on_primary: decode_bool_field(first_field(fields, 4, 0)),
         pn_jid: first_field(fields, 5, 2),
         username: first_field(fields, 6, 2)
       }}
    end
  end

  defp decode_mute_action(data) do
    with {:ok, fields} <- decode_wire_fields(data) do
      {:ok,
       %MuteAction{
         muted: decode_bool_field(first_field(fields, 1, 0)),
         mute_end_timestamp: first_field(fields, 2, 0),
         auto_muted: decode_bool_field(first_field(fields, 3, 0))
       }}
    end
  end

  defp decode_pin_action(data) do
    with {:ok, fields} <- decode_wire_fields(data) do
      {:ok, %PinAction{pinned: decode_bool_field(first_field(fields, 1, 0))}}
    end
  end

  defp decode_archive_chat_action(data) do
    with {:ok, fields} <- decode_wire_fields(data) do
      {:ok,
       %ArchiveChatAction{
         archived: decode_bool_field(first_field(fields, 1, 0)),
         message_range: decode_sub(fields, 2, &decode_message_range/1)
       }}
    end
  end

  defp decode_delete_chat_action(data) do
    with {:ok, fields} <- decode_wire_fields(data) do
      {:ok, %DeleteChatAction{message_range: decode_sub(fields, 1, &decode_message_range/1)}}
    end
  end

  defp decode_mark_chat_as_read_action(data) do
    with {:ok, fields} <- decode_wire_fields(data) do
      {:ok,
       %MarkChatAsReadAction{
         read: decode_bool_field(first_field(fields, 1, 0)),
         message_range: decode_sub(fields, 2, &decode_message_range/1)
       }}
    end
  end

  defp decode_clear_chat_action(data) do
    with {:ok, fields} <- decode_wire_fields(data) do
      {:ok, %ClearChatAction{message_range: decode_sub(fields, 1, &decode_message_range/1)}}
    end
  end

  defp decode_push_name_setting(data) do
    with {:ok, fields} <- decode_wire_fields(data) do
      {:ok, %PushNameSetting{name: first_field(fields, 1, 2)}}
    end
  end

  defp decode_message_range(data) do
    with {:ok, fields} <- decode_wire_fields(data) do
      {:ok,
       %SyncActionMessageRange{
         last_message_timestamp: first_field(fields, 1, 0),
         messages: []
       }}
    end
  end

  defp decode_app_state_sync_key(data) when is_binary(data) do
    case decode_wire_fields(data) do
      {:ok, fields} ->
        key_id_bin = first_field(fields, 1, 2)
        key_data_bin = first_field(fields, 2, 2)

        key_id =
          if key_id_bin do
            case decode_wire_fields(key_id_bin) do
              {:ok, kf} -> first_field(kf, 1, 2)
              _ -> nil
            end
          end

        key_data =
          if key_data_bin do
            case decode_wire_fields(key_data_bin) do
              {:ok, kf} ->
                %AppStateSyncKeyData{
                  key_data: first_field(kf, 1, 2),
                  fingerprint: first_field(kf, 2, 2),
                  timestamp: first_field(kf, 3, 0)
                }

              _ ->
                nil
            end
          end

        if key_id && key_data do
          %AppStateSyncKey{key_id: key_id, key_data: key_data}
        end

      _ ->
        nil
    end
  end

  defp decode_app_state_sync_key(_), do: nil

  # ══════════════════════════════════════════════════════════════
  # ENCODING HELPERS
  # ══════════════════════════════════════════════════════════════

  defp encode_varint_field(acc, _field_num, nil), do: acc

  defp encode_varint_field(acc, field_num, value) when is_integer(value) do
    tag = bsl(field_num, 3) ||| 0
    # Handle negative values as unsigned 64-bit
    unsigned_value = if value < 0, do: value + bsl(1, 64), else: value
    [acc, encode_varint(tag), encode_varint(unsigned_value)]
  end

  defp encode_bytes(acc, _field_num, nil), do: acc

  defp encode_bytes(acc, field_num, value) when is_binary(value) do
    tag = bsl(field_num, 3) ||| 2
    [acc, encode_varint(tag), encode_varint(byte_size(value)), value]
  end

  defp encode_string(acc, _field_num, nil), do: acc

  defp encode_string(acc, field_num, value) when is_binary(value),
    do: encode_bytes(acc, field_num, value)

  defp encode_bool(acc, _field_num, nil), do: acc
  defp encode_bool(acc, field_num, true), do: encode_varint_field(acc, field_num, 1)
  defp encode_bool(acc, field_num, false), do: encode_varint_field(acc, field_num, 0)

  defp encode_submessage(acc, _field_num, nil), do: acc

  defp encode_submessage(acc, field_num, encoded)
       when is_binary(encoded) and byte_size(encoded) > 0 do
    encode_bytes(acc, field_num, encoded)
  end

  defp encode_submessage(acc, _field_num, _), do: acc

  defp encode_repeated_submessage(acc, _field_num, [], _encoder), do: acc

  defp encode_repeated_submessage(acc, field_num, items, encoder) do
    Enum.reduce(items, acc, fn item, a ->
      encoded = encoder.(item)
      encode_submessage(a, field_num, encoded)
    end)
  end

  defp encode_varint(n) when n < 128, do: <<n::8>>

  defp encode_varint(n) do
    <<1::1, band(n, 0x7F)::7, encode_varint(bsr(n, 7))::binary>>
  end

  # ══════════════════════════════════════════════════════════════
  # DECODING HELPERS
  # ══════════════════════════════════════════════════════════════

  defp decode_sub(fields, field_num, decoder) do
    case first_field(fields, field_num, 2) do
      nil ->
        nil

      data ->
        case decoder.(data) do
          {:ok, result} -> result
          _ -> nil
        end
    end
  end

  defp decode_bool_field(nil), do: nil
  defp decode_bool_field(0), do: false
  defp decode_bool_field(v) when is_integer(v) and v > 0, do: true
  defp decode_bool_field(_), do: nil

  defp first_field(fields, field_num, wire_type) do
    Enum.find_value(fields, fn
      {^field_num, ^wire_type, value} -> value
      _ -> nil
    end)
  end

  defp all_fields(fields, field_num, wire_type) do
    fields
    |> Enum.reduce([], fn
      {^field_num, ^wire_type, value}, acc -> [value | acc]
      _, acc -> acc
    end)
    |> Enum.reverse()
  end

  defp decode_wire_fields(binary), do: decode_wire_fields(binary, [])
  defp decode_wire_fields(<<>>, acc), do: {:ok, Enum.reverse(acc)}

  defp decode_wire_fields(binary, acc) when is_binary(binary) do
    with {:ok, tag, rest} <- decode_varint_bin(binary),
         wire_type <- band(tag, 0x07),
         field_num <- bsr(tag, 3) do
      case wire_type do
        0 ->
          with {:ok, value, tail} <- decode_varint_bin(rest) do
            decode_wire_fields(tail, [{field_num, 0, value} | acc])
          end

        1 ->
          if byte_size(rest) >= 8 do
            <<_skip::binary-size(8), tail::binary>> = rest
            decode_wire_fields(tail, [{field_num, 1, :fixed64} | acc])
          else
            {:error, :invalid_fixed64}
          end

        2 ->
          with {:ok, len, tail} <- decode_varint_bin(rest),
               true <- byte_size(tail) >= len do
            <<value::binary-size(len), next::binary>> = tail
            decode_wire_fields(next, [{field_num, 2, value} | acc])
          else
            false -> {:error, :invalid_length_delimited_field}
          end

        5 ->
          if byte_size(rest) >= 4 do
            <<_skip::binary-size(4), tail::binary>> = rest
            decode_wire_fields(tail, [{field_num, 5, :fixed32} | acc])
          else
            {:error, :invalid_fixed32}
          end

        _ ->
          {:error, {:unsupported_wire_type, wire_type}}
      end
    end
  end

  defp decode_varint_bin(binary), do: decode_varint_bin(binary, 0, 0)
  defp decode_varint_bin(_, _, shift) when shift > 63, do: {:error, :invalid_varint}
  defp decode_varint_bin(<<>>, _, _), do: {:error, :invalid_varint}

  defp decode_varint_bin(<<byte, rest::binary>>, acc, shift) do
    value = bor(acc, bsl(band(byte, 0x7F), shift))

    if band(byte, 0x80) == 0 do
      {:ok, value, rest}
    else
      decode_varint_bin(rest, value, shift + 7)
    end
  end
end
