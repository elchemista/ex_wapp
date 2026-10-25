defmodule ExWapp.Proto.SyncActionTest do
  use ExUnit.Case, async: true

  alias WAWebProtobufsServerSync.{
    KeyId,
    SyncdIndex,
    SyncdMutation,
    SyncdPatch,
    SyncdRecord,
    SyncdSnapshot,
    SyncdValue,
    SyncdVersion
  }

  alias WAWebProtobufSyncAction.{
    ArchiveChatAction,
    ClearChatAction,
    ContactAction,
    DeleteChatAction,
    MarkChatAsReadAction,
    MuteAction,
    PinAction,
    PushNameSetting,
    SyncActionData,
    SyncActionMessageRange,
    SyncActionValue
  }

  defp round_trip(module, struct) do
    encoded = struct |> module.encode!() |> elem(0) |> IO.iodata_to_binary()
    assert is_binary(encoded)
    {:ok, decoded} = module.decode(encoded)
    {encoded, decoded}
  end

  describe "SyncdPatch encode/decode round-trip" do
    test "minimal patch with one SET mutation" do
      key_id = :crypto.strong_rand_bytes(16)
      index_blob = "some_index_data"
      value_blob = :crypto.strong_rand_bytes(64)
      snapshot_mac = :crypto.strong_rand_bytes(32)
      patch_mac = :crypto.strong_rand_bytes(32)

      patch = %SyncdPatch{
        version: %SyncdVersion{version: 5},
        mutations: [
          %SyncdMutation{
            operation: :SET,
            record: %SyncdRecord{
              index: %SyncdIndex{blob: index_blob},
              value: %SyncdValue{blob: value_blob},
              keyID: %KeyId{ID: key_id}
            }
          }
        ],
        snapshotMAC: snapshot_mac,
        patchMAC: patch_mac,
        keyID: %KeyId{ID: key_id}
      }

      {_encoded, decoded} = round_trip(SyncdPatch, patch)

      assert decoded.version.version == 5
      assert [mutation] = decoded.mutations
      assert mutation.operation == :SET
      assert mutation.record.index.blob == index_blob
      assert mutation.record.value.blob == value_blob
      assert mutation.record.keyID."ID" == key_id
      assert decoded.snapshotMAC == snapshot_mac
      assert decoded.patchMAC == patch_mac
      assert decoded.keyID."ID" == key_id
    end

    test "patch with REMOVE mutation" do
      key_id = :crypto.strong_rand_bytes(16)

      patch = %SyncdPatch{
        version: %SyncdVersion{version: 10},
        mutations: [
          %SyncdMutation{
            operation: :REMOVE,
            record: %SyncdRecord{
              index: %SyncdIndex{blob: "remove_index"},
              value: %SyncdValue{blob: <<>>},
              keyID: %KeyId{ID: key_id}
            }
          }
        ],
        snapshotMAC: :crypto.strong_rand_bytes(32),
        patchMAC: :crypto.strong_rand_bytes(32),
        keyID: %KeyId{ID: key_id}
      }

      {_encoded, decoded} = round_trip(SyncdPatch, patch)
      assert hd(decoded.mutations).operation == :REMOVE
    end

    test "patch with multiple mutations" do
      key_id = :crypto.strong_rand_bytes(16)

      record = fn index, value ->
        %SyncdRecord{
          index: %SyncdIndex{blob: index},
          value: %SyncdValue{blob: value},
          keyID: %KeyId{ID: key_id}
        }
      end

      patch = %SyncdPatch{
        version: %SyncdVersion{version: 3},
        mutations: [
          %SyncdMutation{operation: :SET, record: record.("idx1", "val1")},
          %SyncdMutation{operation: :REMOVE, record: record.("idx2", "val2")},
          %SyncdMutation{operation: :SET, record: record.("idx3", "val3")}
        ],
        snapshotMAC: :crypto.strong_rand_bytes(32),
        patchMAC: :crypto.strong_rand_bytes(32),
        keyID: %KeyId{ID: key_id}
      }

      {_encoded, decoded} = round_trip(SyncdPatch, patch)
      assert length(decoded.mutations) == 3
      assert Enum.map(decoded.mutations, & &1.operation) == [:SET, :REMOVE, :SET]
      assert Enum.map(decoded.mutations, & &1.record.index.blob) == ["idx1", "idx2", "idx3"]
    end
  end

  describe "SyncActionData encode/decode round-trip" do
    test "contact action" do
      data = %SyncActionData{
        index: ExWapp.JSON.encode!(["contact", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          contactAction: %ContactAction{
            fullName: "John Doe",
            firstName: "John"
          }
        },
        padding: :crypto.strong_rand_bytes(4),
        version: 2
      }

      {_encoded, decoded} = round_trip(SyncActionData, data)

      assert decoded.index == data.index
      assert decoded.version == 2
      assert decoded.value.timestamp == 1_700_000_000
      assert decoded.value.contactAction.fullName == "John Doe"
      assert decoded.value.contactAction.firstName == "John"
    end

    test "contact action with all fields" do
      data = %SyncActionData{
        index: ExWapp.JSON.encode!(["contact", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          contactAction: %ContactAction{
            fullName: "John Doe",
            firstName: "John",
            lidJID: "12345@lid",
            saveOnPrimaryAddressbook: true,
            pnJID: "15550001111@s.whatsapp.net",
            username: "johndoe"
          }
        },
        version: 2
      }

      {_encoded, decoded} = round_trip(SyncActionData, data)

      ca = decoded.value.contactAction
      assert ca.fullName == "John Doe"
      assert ca.firstName == "John"
      assert ca.lidJID == "12345@lid"
      assert ca.saveOnPrimaryAddressbook == true
      assert ca.pnJID == "15550001111@s.whatsapp.net"
      assert ca.username == "johndoe"
    end

    test "mute action" do
      data = %SyncActionData{
        index: ExWapp.JSON.encode!(["mute", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          muteAction: %MuteAction{
            muted: true,
            muteEndTimestamp: 1_700_086_400
          }
        },
        version: 2
      }

      {_encoded, decoded} = round_trip(SyncActionData, data)

      assert decoded.value.muteAction.muted == true
      assert decoded.value.muteAction.muteEndTimestamp == 1_700_086_400
    end

    test "pin action" do
      data = %SyncActionData{
        index: ExWapp.JSON.encode!(["pin_v1", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          pinAction: %PinAction{pinned: true}
        },
        version: 5
      }

      {_encoded, decoded} = round_trip(SyncActionData, data)

      assert decoded.value.pinAction.pinned == true
      assert decoded.version == 5
    end

    test "archive chat action with message range" do
      data = %SyncActionData{
        index: ExWapp.JSON.encode!(["archive", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          archiveChatAction: %ArchiveChatAction{
            archived: true,
            messageRange: %SyncActionMessageRange{
              lastMessageTimestamp: 1_699_999_999
            }
          }
        },
        version: 3
      }

      {_encoded, decoded} = round_trip(SyncActionData, data)

      assert decoded.value.archiveChatAction.archived == true

      assert decoded.value.archiveChatAction.messageRange.lastMessageTimestamp ==
               1_699_999_999
    end

    test "delete chat action" do
      data = %SyncActionData{
        index: ExWapp.JSON.encode!(["deleteChat", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          deleteChatAction: %DeleteChatAction{
            messageRange: %SyncActionMessageRange{
              lastMessageTimestamp: 1_699_999_999
            }
          }
        },
        version: 6
      }

      {_encoded, decoded} = round_trip(SyncActionData, data)

      assert decoded.value.deleteChatAction.messageRange.lastMessageTimestamp ==
               1_699_999_999
    end

    test "mark chat as read action" do
      data = %SyncActionData{
        index: ExWapp.JSON.encode!(["markChatAsRead", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          markChatAsReadAction: %MarkChatAsReadAction{
            read: true,
            messageRange: %SyncActionMessageRange{
              lastMessageTimestamp: 1_699_999_999
            }
          }
        },
        version: 3
      }

      {_encoded, decoded} = round_trip(SyncActionData, data)

      assert decoded.value.markChatAsReadAction.read == true
    end

    test "clear chat action" do
      data = %SyncActionData{
        index: ExWapp.JSON.encode!(["clearChat", "15550001111@s.whatsapp.net"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          clearChatAction: %ClearChatAction{
            messageRange: %SyncActionMessageRange{
              lastMessageTimestamp: 1_699_999_999
            }
          }
        },
        version: 7
      }

      {_encoded, decoded} = round_trip(SyncActionData, data)

      assert decoded.value.clearChatAction.messageRange.lastMessageTimestamp == 1_699_999_999
    end

    test "push name setting keeps its wire tag" do
      data = %SyncActionData{
        index: ExWapp.JSON.encode!(["setting_pushName"]),
        value: %SyncActionValue{
          timestamp: 1_700_000_000,
          pushNameSetting: %PushNameSetting{name: "My Name"}
        },
        version: 1
      }

      {encoded, decoded} = round_trip(SyncActionData, data)

      # Field 7 (pushNameSetting) wire tag = 58 (0x3A)
      assert :binary.matches(encoded, [<<0x3A>>]) != []
      assert decoded.value.pushNameSetting.name == "My Name"
    end

    test "nil value fields are omitted (no action)" do
      data = %SyncActionData{
        index: "test",
        value: %SyncActionValue{timestamp: 12_345},
        version: 1
      }

      {_encoded, decoded} = round_trip(SyncActionData, data)

      assert decoded.value.timestamp == 12_345
      assert decoded.value.contactAction == nil
      assert decoded.value.muteAction == nil
      assert decoded.value.pinAction == nil
    end
  end

  describe "edge cases" do
    test "decode empty binary returns empty patch" do
      {:ok, decoded} = SyncdPatch.decode(<<>>)
      assert decoded.version == nil
      assert decoded.mutations == []
    end

    test "decode empty binary returns empty snapshot" do
      {:ok, decoded} = SyncdSnapshot.decode(<<>>)
      assert decoded.version == nil
      assert decoded.records == []
    end
  end
end
