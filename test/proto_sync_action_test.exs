defmodule ExWapp.Proto.SyncActionTest do
  use ExUnit.Case, async: true

  alias ExWapp.Proto.SyncAction

  alias ExWapp.Proto.SyncAction.{
    SyncdPatch,
    SyncdMutation,
    SyncdRecord,
    SyncActionData,
    SyncActionValue,
    ContactAction,
    MuteAction,
    PinAction,
    ArchiveChatAction,
    DeleteChatAction,
    MarkChatAsReadAction,
    ClearChatAction,
    PushNameSetting,
    SyncActionMessageRange
  }

  describe "SyncdPatch encode/decode round-trip" do
    test "minimal patch with one SET mutation" do
      key_id = :crypto.strong_rand_bytes(16)
      index_blob = "some_index_data"
      value_blob = :crypto.strong_rand_bytes(64)
      snapshot_mac = :crypto.strong_rand_bytes(32)
      patch_mac = :crypto.strong_rand_bytes(32)

      patch = %SyncdPatch{
        version: 5,
        mutations: [
          %SyncdMutation{
            operation: 0,
            record: %SyncdRecord{
              index: index_blob,
              value: value_blob,
              key_id: key_id
            }
          }
        ],
        snapshot_mac: snapshot_mac,
        patch_mac: patch_mac,
        key_id: key_id
      }

      encoded = SyncAction.encode_syncd_patch(patch)
      assert is_binary(encoded)

      {:ok, decoded} = SyncAction.decode_syncd_patch(encoded)
      assert decoded.version == 5
      assert length(decoded.mutations) == 1

      [mutation] = decoded.mutations
      assert mutation.operation == 0
      assert mutation.record.index == index_blob
      assert mutation.record.value == value_blob
      assert mutation.record.key_id == key_id
      assert decoded.snapshot_mac == snapshot_mac
      assert decoded.patch_mac == patch_mac
      assert decoded.key_id == key_id
    end

    test "patch with REMOVE mutation" do
      key_id = :crypto.strong_rand_bytes(16)

      patch = %SyncdPatch{
        version: 10,
        mutations: [
          %SyncdMutation{
            operation: 1,
            record: %SyncdRecord{
              index: "remove_index",
              value: <<>>,
              key_id: key_id
            }
          }
        ],
        snapshot_mac: :crypto.strong_rand_bytes(32),
        patch_mac: :crypto.strong_rand_bytes(32),
        key_id: key_id
      }

      encoded = SyncAction.encode_syncd_patch(patch)
      {:ok, decoded} = SyncAction.decode_syncd_patch(encoded)
      assert hd(decoded.mutations).operation == 1
    end

    test "patch with multiple mutations" do
      key_id = :crypto.strong_rand_bytes(16)

      patch = %SyncdPatch{
        version: 3,
        mutations: [
          %SyncdMutation{
            operation: 0,
            record: %SyncdRecord{index: "idx1", value: "val1", key_id: key_id}
          },
          %SyncdMutation{
            operation: 1,
            record: %SyncdRecord{index: "idx2", value: "val2", key_id: key_id}
          },
          %SyncdMutation{
            operation: 0,
            record: %SyncdRecord{index: "idx3", value: "val3", key_id: key_id}
          }
        ],
        snapshot_mac: :crypto.strong_rand_bytes(32),
        patch_mac: :crypto.strong_rand_bytes(32),
        key_id: key_id
      }

      encoded = SyncAction.encode_syncd_patch(patch)
      {:ok, decoded} = SyncAction.decode_syncd_patch(encoded)
      assert length(decoded.mutations) == 3
      assert Enum.map(decoded.mutations, & &1.operation) == [0, 1, 0]
      assert Enum.map(decoded.mutations, & &1.record.index) == ["idx1", "idx2", "idx3"]
    end
  end

  describe "SyncActionData encode/decode round-trip" do
    test "contact action" do
      data = %SyncActionData{
        index: Jason.encode!(["contact", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          contact_action: %ContactAction{
            full_name: "John Doe",
            first_name: "John"
          }
        },
        padding: :crypto.strong_rand_bytes(4),
        version: 2
      }

      encoded = SyncAction.encode_sync_action_data(data)
      {:ok, decoded} = SyncAction.decode_sync_action_data(encoded)

      assert decoded.index == data.index
      assert decoded.version == 2
      assert decoded.value.timestamp == 1_700_000_000
      assert decoded.value.contact_action.full_name == "John Doe"
      assert decoded.value.contact_action.first_name == "John"
    end

    test "contact action with all fields" do
      data = %SyncActionData{
        index: Jason.encode!(["contact", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          contact_action: %ContactAction{
            full_name: "John Doe",
            first_name: "John",
            lid_jid: "12345@lid",
            save_on_primary: true,
            pn_jid: "15550001111@s.whatsapp.net",
            username: "johndoe"
          }
        },
        version: 2
      }

      encoded = SyncAction.encode_sync_action_data(data)
      {:ok, decoded} = SyncAction.decode_sync_action_data(encoded)

      ca = decoded.value.contact_action
      assert ca.full_name == "John Doe"
      assert ca.first_name == "John"
      assert ca.lid_jid == "12345@lid"
      assert ca.save_on_primary == true
      assert ca.pn_jid == "15550001111@s.whatsapp.net"
      assert ca.username == "johndoe"
    end

    test "mute action" do
      data = %SyncActionData{
        index: Jason.encode!(["mute", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          mute_action: %MuteAction{
            muted: true,
            mute_end_timestamp: 1_700_086_400
          }
        },
        version: 2
      }

      encoded = SyncAction.encode_sync_action_data(data)
      {:ok, decoded} = SyncAction.decode_sync_action_data(encoded)

      assert decoded.value.mute_action.muted == true
      assert decoded.value.mute_action.mute_end_timestamp == 1_700_086_400
    end

    test "pin action" do
      data = %SyncActionData{
        index: Jason.encode!(["pin_v1", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          pin_action: %PinAction{pinned: true}
        },
        version: 5
      }

      encoded = SyncAction.encode_sync_action_data(data)
      {:ok, decoded} = SyncAction.decode_sync_action_data(encoded)

      assert decoded.value.pin_action.pinned == true
      assert decoded.version == 5
    end

    test "archive chat action with message range" do
      data = %SyncActionData{
        index: Jason.encode!(["archive", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          archive_chat_action: %ArchiveChatAction{
            archived: true,
            message_range: %SyncActionMessageRange{
              last_message_timestamp: 1_699_999_999
            }
          }
        },
        version: 3
      }

      encoded = SyncAction.encode_sync_action_data(data)
      {:ok, decoded} = SyncAction.decode_sync_action_data(encoded)

      assert decoded.value.archive_chat_action.archived == true

      assert decoded.value.archive_chat_action.message_range.last_message_timestamp ==
               1_699_999_999
    end

    test "delete chat action" do
      data = %SyncActionData{
        index: Jason.encode!(["deleteChat", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          delete_chat_action: %DeleteChatAction{
            message_range: %SyncActionMessageRange{
              last_message_timestamp: 1_699_999_999
            }
          }
        },
        version: 6
      }

      encoded = SyncAction.encode_sync_action_data(data)
      {:ok, decoded} = SyncAction.decode_sync_action_data(encoded)

      assert decoded.value.delete_chat_action.message_range.last_message_timestamp ==
               1_699_999_999
    end

    test "mark chat as read action" do
      data = %SyncActionData{
        index: Jason.encode!(["markChatAsRead", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          mark_chat_as_read_action: %MarkChatAsReadAction{
            read: true,
            message_range: %SyncActionMessageRange{
              last_message_timestamp: 1_699_999_999
            }
          }
        },
        version: 3
      }

      encoded = SyncAction.encode_sync_action_data(data)
      {:ok, decoded} = SyncAction.decode_sync_action_data(encoded)

      assert decoded.value.mark_chat_as_read_action.read == true
    end

    test "clear chat action" do
      data = %SyncActionData{
        index: Jason.encode!(["clearChat", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          clear_chat_action: %ClearChatAction{
            message_range: %SyncActionMessageRange{
              last_message_timestamp: 1_699_999_999
            }
          }
        },
        version: 7
      }

      encoded = SyncAction.encode_sync_action_data(data)
      {:ok, decoded} = SyncAction.decode_sync_action_data(encoded)

      assert decoded.value.clear_chat_action.message_range.last_message_timestamp == 1_699_999_999
    end

    test "push name setting" do
      data = %SyncActionData{
        index: Jason.encode!(["setting_pushName"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          push_name_setting: %PushNameSetting{name: "My Name"}
        },
        version: 1
      }

      encoded = SyncAction.encode_sync_action_data(data)
      # Field 7 (pushNameSetting) wire tag = 58 (0x3A)
      assert :binary.matches(encoded, [<<0x3A>>]) != []

      {:ok, decoded} = SyncAction.decode_sync_action_data(encoded)

      assert decoded.value.push_name_setting.name == "My Name"
    end

    test "nil value fields are omitted (no action)" do
      data = %SyncActionData{
        index: "test",
        value: %SyncActionValue{timestamp: 12_345},
        version: 1
      }

      encoded = SyncAction.encode_sync_action_data(data)
      {:ok, decoded} = SyncAction.decode_sync_action_data(encoded)

      assert decoded.value.timestamp == 12_345
      assert decoded.value.contact_action == nil
      assert decoded.value.mute_action == nil
      assert decoded.value.pin_action == nil
    end
  end

  describe "edge cases" do
    test "decode empty binary returns empty patch" do
      {:ok, decoded} = SyncAction.decode_syncd_patch(<<>>)
      assert decoded.version == nil
      assert decoded.mutations == []
    end

    test "decode empty binary returns empty snapshot" do
      {:ok, decoded} = SyncAction.decode_syncd_snapshot(<<>>)
      assert decoded.version == nil
      assert decoded.records == []
    end
  end
end
