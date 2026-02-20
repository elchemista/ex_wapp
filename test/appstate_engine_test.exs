defmodule ExWapp.AppState.EngineTest do
  use ExUnit.Case, async: true

  alias ExWapp.AppState.{Engine, Crypto, LTHash}

  alias ExWapp.Proto.SyncAction

  alias ExWapp.Proto.SyncAction.{
    SyncdMutation,
    SyncdRecord,
    SyncActionData,
    SyncActionValue,
    ContactAction,
    MuteAction,
    PinAction,
    ArchiveChatAction,
    DeleteChatAction
  }

  # ============================================================================
  # Mutation Builders
  # ============================================================================

  describe "build_contact/3" do
    test "builds a contact patch for critical_unblock_low" do
      patch = Engine.build_contact("1234@s.whatsapp.net", "John Doe", "John")

      assert patch.type == "critical_unblock_low"
      assert length(patch.mutations) == 1

      [mutation] = patch.mutations
      assert mutation.index == ["contact", "1234@s.whatsapp.net"]
      assert mutation.version == 2
      assert mutation.value.contact_action.full_name == "John Doe"
      assert mutation.value.contact_action.first_name == "John"
    end

    test "defaults first_name to full_name when nil" do
      patch = Engine.build_contact("1234@s.whatsapp.net", "John Doe")
      [mutation] = patch.mutations
      assert mutation.value.contact_action.first_name == "John Doe"
    end

    test "normalizes contact jid by stripping + and normalizing domain" do
      patch = Engine.build_contact("+1234@whatsapp.net", "John Doe")
      [mutation] = patch.mutations
      assert mutation.index == ["contact", "1234@s.whatsapp.net"]
    end
  end

  describe "build_delete_contact/1" do
    test "builds a remove-operation contact patch" do
      patch = Engine.build_delete_contact("1234@s.whatsapp.net")

      assert patch.type == "critical_unblock_low"
      [mutation] = patch.mutations
      assert mutation.index == ["contact", "1234@s.whatsapp.net"]
      assert mutation.operation == :remove
    end

    test "normalizes contact jid before delete mutation" do
      patch = Engine.build_delete_contact("+1234@whatsapp.net")
      [mutation] = patch.mutations
      assert mutation.index == ["contact", "1234@s.whatsapp.net"]
    end
  end

  describe "build_archive/3" do
    test "builds archive patch with unpin" do
      patch = Engine.build_archive("1234@s.whatsapp.net", true)

      assert patch.type == "regular_low"
      assert length(patch.mutations) == 2

      [archive, unpin] = patch.mutations
      assert archive.index == ["archive", "1234@s.whatsapp.net"]
      assert archive.value.archive_chat_action.archived == true
      assert unpin.index == ["pin_v1", "1234@s.whatsapp.net"]
      assert unpin.value.pin_action.pinned == false
    end

    test "builds unarchive patch without unpin" do
      patch = Engine.build_archive("1234@s.whatsapp.net", false)

      assert patch.type == "regular_low"
      assert length(patch.mutations) == 1

      [archive] = patch.mutations
      assert archive.value.archive_chat_action.archived == false
    end
  end

  describe "build_pin/2" do
    test "builds pin patch" do
      patch = Engine.build_pin("1234@s.whatsapp.net", true)

      assert patch.type == "regular_low"
      [mutation] = patch.mutations
      assert mutation.index == ["pin_v1", "1234@s.whatsapp.net"]
      assert mutation.version == 5
      assert mutation.value.pin_action.pinned == true
    end
  end

  describe "build_mute/3" do
    test "builds mute forever patch" do
      patch = Engine.build_mute("1234@s.whatsapp.net", true)

      assert patch.type == "regular_high"
      [mutation] = patch.mutations
      assert mutation.index == ["mute", "1234@s.whatsapp.net"]
      assert mutation.value.mute_action.muted == true
      assert mutation.value.mute_action.mute_end_timestamp == -1
    end

    test "builds mute with specific end timestamp" do
      ts = System.system_time(:millisecond) + 86_400_000
      patch = Engine.build_mute("1234@s.whatsapp.net", true, ts)

      [mutation] = patch.mutations
      assert mutation.value.mute_action.mute_end_timestamp == ts
    end

    test "builds unmute patch" do
      patch = Engine.build_mute("1234@s.whatsapp.net", false)

      [mutation] = patch.mutations
      assert mutation.value.mute_action.muted == false
      assert mutation.value.mute_action.mute_end_timestamp == nil
    end
  end

  describe "build_delete_chat/2" do
    test "builds delete chat patch" do
      patch = Engine.build_delete_chat("1234@s.whatsapp.net")

      assert patch.type == "regular_high"
      [mutation] = patch.mutations
      assert mutation.index == ["deleteChat", "1234@s.whatsapp.net", "0"]
      assert mutation.version == 6
    end
  end

  describe "build_mark_read/3" do
    test "builds mark read patch" do
      patch = Engine.build_mark_read("1234@s.whatsapp.net", true)

      assert patch.type == "regular_low"
      [mutation] = patch.mutations
      assert mutation.index == ["markChatAsRead", "1234@s.whatsapp.net"]
      assert mutation.value.mark_chat_as_read_action.read == true
    end
  end

  describe "build_clear_chat/2" do
    test "builds clear chat patch" do
      patch = Engine.build_clear_chat("1234@s.whatsapp.net")

      assert patch.type == "regular_high"
      [mutation] = patch.mutations
      assert mutation.index == ["clearChat", "1234@s.whatsapp.net", "1", "0"]
      assert mutation.version == 6
    end
  end

  # ============================================================================
  # Encode Patch
  # ============================================================================

  describe "encode_patch/5" do
    test "encodes a contact patch into valid protobuf" do
      key_id = :crypto.strong_rand_bytes(16)
      key_data = :crypto.strong_rand_bytes(32)
      hash_state = %{version: 0, hash: LTHash.new()}

      patch_info = Engine.build_contact("1234@s.whatsapp.net", "Test User")

      assert {:ok, encoded, new_hash_state, new_mutation_macs} =
               Engine.encode_patch(patch_info, key_id, key_data, hash_state)

      assert is_binary(encoded)
      assert byte_size(encoded) > 0
      assert new_hash_state.version == 1
      assert byte_size(new_hash_state.hash) == 128
      assert map_size(new_mutation_macs) == 1
    end

    test "encode then decode round-trip preserves mutation content" do
      key_id = :crypto.strong_rand_bytes(16)
      key_data = :crypto.strong_rand_bytes(32)
      hash_state = %{version: 5, hash: LTHash.new()}

      patch_info = Engine.build_pin("test@s.whatsapp.net", true)

      {:ok, encoded, _new_hash_state, _new_mutation_macs} =
        Engine.encode_patch(patch_info, key_id, key_data, hash_state)

      # Decode the protobuf back
      {:ok, decoded_patch} = SyncAction.decode_syncd_patch(encoded)

      assert decoded_patch.version == nil
      assert length(decoded_patch.mutations) == 1
      assert is_binary(decoded_patch.snapshot_mac)
      assert is_binary(decoded_patch.patch_mac)

      [mutation] = decoded_patch.mutations
      assert mutation.operation == 0
      assert is_binary(mutation.record.index)
      assert is_binary(mutation.record.value)
      assert mutation.record.key_id == key_id

      # Decrypt the mutation
      key_store = %{
        Base.encode16(key_id, case: :lower) => %{data: key_data}
      }

      {:ok, decoded_mutations} = Engine.decode_mutations([mutation], key_store, true)

      assert length(decoded_mutations) == 1
      [dm] = decoded_mutations
      assert dm.index == ["pin_v1", "test@s.whatsapp.net"]
      assert dm.action.pin_action.pinned == true
    end

    test "multiple mutations in a single patch" do
      key_id = :crypto.strong_rand_bytes(16)
      key_data = :crypto.strong_rand_bytes(32)
      hash_state = %{version: 0, hash: LTHash.new()}

      patch_info = Engine.build_archive("test@s.whatsapp.net", true)

      {:ok, encoded, new_hash_state, new_mutation_macs} =
        Engine.encode_patch(patch_info, key_id, key_data, hash_state)

      assert is_binary(encoded)
      assert new_hash_state.version == 1
      # archive + unpin = 2 mutations
      assert map_size(new_mutation_macs) == 2

      {:ok, decoded_patch} = SyncAction.decode_syncd_patch(encoded)
      assert length(decoded_patch.mutations) == 2
    end
  end

  # ============================================================================
  # Decode Mutations
  # ============================================================================

  describe "decode_mutations/3" do
    test "decodes encrypted mutations correctly" do
      key_id = :crypto.strong_rand_bytes(16)
      key_data = :crypto.strong_rand_bytes(32)
      keys = Crypto.expand_keys(key_data)

      # Build a mutation manually
      index_json = Jason.encode!(["mute", "test@s.whatsapp.net"])

      action_data = %SyncActionData{
        index: index_json,
        value: %SyncActionValue{
          mute_action: %MuteAction{muted: true, mute_end_timestamp: -1},
          timestamp: System.system_time(:millisecond)
        },
        padding: <<>>,
        version: 2
      }

      content = SyncAction.encode_sync_action_data(action_data)
      {iv, ciphertext} = Crypto.encrypt_cbc(content, keys.value_encryption)
      encrypted_content = iv <> ciphertext

      value_mac =
        Crypto.compute_content_mac(0, encrypted_content, key_id, keys.value_mac)

      index_mac = Crypto.compute_index_mac(index_json, keys.index)

      mutation = %SyncdMutation{
        operation: 0,
        record: %SyncdRecord{
          index: index_mac,
          value: encrypted_content <> value_mac,
          key_id: key_id
        }
      }

      key_store = %{
        Base.encode16(key_id, case: :lower) => %{data: key_data}
      }

      assert {:ok, [decoded]} = Engine.decode_mutations([mutation], key_store, true)
      assert decoded.index == ["mute", "test@s.whatsapp.net"]
      assert decoded.operation == 0
      assert decoded.action.mute_action.muted == true
    end

    test "returns error for mismatching content MAC" do
      key_id = :crypto.strong_rand_bytes(16)
      key_data = :crypto.strong_rand_bytes(32)
      keys = Crypto.expand_keys(key_data)

      content =
        SyncAction.encode_sync_action_data(%SyncActionData{
          index: "[]",
          value: %SyncActionValue{},
          padding: <<>>,
          version: 1
        })

      {iv, ciphertext} = Crypto.encrypt_cbc(content, keys.value_encryption)
      encrypted_content = iv <> ciphertext

      # Corrupt the MAC
      bad_mac = :crypto.strong_rand_bytes(32)
      index_mac = Crypto.compute_index_mac("[]", keys.index)

      mutation = %SyncdMutation{
        operation: 0,
        record: %SyncdRecord{
          index: index_mac,
          value: encrypted_content <> bad_mac,
          key_id: key_id
        }
      }

      key_store = %{
        Base.encode16(key_id, case: :lower) => %{data: key_data}
      }

      assert {:error, :mismatching_content_mac} =
               Engine.decode_mutations([mutation], key_store, true)
    end

    test "skips MAC validation when validate_macs is false" do
      key_id = :crypto.strong_rand_bytes(16)
      key_data = :crypto.strong_rand_bytes(32)
      keys = Crypto.expand_keys(key_data)

      index_json = Jason.encode!(["contact", "test@s.whatsapp.net"])

      content =
        SyncAction.encode_sync_action_data(%SyncActionData{
          index: index_json,
          value: %SyncActionValue{
            contact_action: %ContactAction{full_name: "Test", first_name: "Test"}
          },
          padding: <<>>,
          version: 2
        })

      {iv, ciphertext} = Crypto.encrypt_cbc(content, keys.value_encryption)
      encrypted_content = iv <> ciphertext

      # Use a garbage MAC — should still work with validate=false
      fake_mac = :crypto.strong_rand_bytes(32)

      mutation = %SyncdMutation{
        operation: 0,
        record: %SyncdRecord{
          index: :crypto.strong_rand_bytes(32),
          value: encrypted_content <> fake_mac,
          key_id: key_id
        }
      }

      key_store = %{
        Base.encode16(key_id, case: :lower) => %{data: key_data}
      }

      assert {:ok, [decoded]} = Engine.decode_mutations([mutation], key_store, false)
      assert decoded.index == ["contact", "test@s.whatsapp.net"]
      assert decoded.action.contact_action.full_name == "Test"
    end
  end

  # ============================================================================
  # Collection State
  # ============================================================================

  describe "all_collections/0" do
    test "returns all five collection names" do
      collections = Engine.all_collections()
      assert length(collections) == 5
      assert "critical_block" in collections
      assert "critical_unblock_low" in collections
      assert "regular_high" in collections
      assert "regular_low" in collections
      assert "regular" in collections
    end
  end

  # ============================================================================
  # Dispatch Mutations
  # ============================================================================

  describe "dispatch_mutation/3" do
    setup do
      store = ExWapp.Store.new(ExWapp.Store.Memory)
      %{store: store}
    end

    test "dispatches contact action", %{store: store} do
      action = %SyncActionValue{
        contact_action: %ContactAction{full_name: "Bob Smith", first_name: "Bob"}
      }

      assert :ok = Engine.dispatch_mutation(store, ["contact", "1234@s.whatsapp.net"], action)

      contact = ExWapp.Contact.get(store, "1234@s.whatsapp.net")
      assert contact != nil
      assert contact.full_name == "Bob Smith"
    end

    test "dispatches contact remove operation", %{store: store} do
      ExWapp.Contact.put(store, "1234@s.whatsapp.net", %ExWapp.Contact{
        jid: "1234@s.whatsapp.net",
        full_name: "To Delete"
      })

      assert ExWapp.Contact.get(store, "1234@s.whatsapp.net") != nil

      assert :ok =
               Engine.dispatch_mutation(
                 store,
                 1,
                 ["contact", "1234@s.whatsapp.net"],
                 %SyncActionValue{}
               )

      assert ExWapp.Contact.get(store, "1234@s.whatsapp.net") == nil
    end

    test "dispatches archive action", %{store: store} do
      action = %SyncActionValue{
        archive_chat_action: %ArchiveChatAction{archived: true}
      }

      assert :ok = Engine.dispatch_mutation(store, ["archive", "1234@s.whatsapp.net"], action)

      {:ok, chat} = ExWapp.Chat.get(store, "1234@s.whatsapp.net")
      assert chat.archived == true
    end

    test "dispatches pin action", %{store: store} do
      action = %SyncActionValue{
        pin_action: %PinAction{pinned: true}
      }

      assert :ok = Engine.dispatch_mutation(store, ["pin_v1", "1234@s.whatsapp.net"], action)

      {:ok, chat} = ExWapp.Chat.get(store, "1234@s.whatsapp.net")
      assert chat.pinned == true
    end

    test "dispatches mute action", %{store: store} do
      action = %SyncActionValue{
        mute_action: %MuteAction{muted: true, mute_end_timestamp: -1}
      }

      assert :ok = Engine.dispatch_mutation(store, ["mute", "1234@s.whatsapp.net"], action)

      {:ok, chat} = ExWapp.Chat.get(store, "1234@s.whatsapp.net")
      assert chat.muted_until == -1
    end

    test "dispatches delete chat action", %{store: store} do
      # Create a chat first
      ExWapp.Chat.get_or_create(store, "1234@s.whatsapp.net")

      action = %SyncActionValue{
        delete_chat_action: %DeleteChatAction{}
      }

      Engine.dispatch_mutation(store, ["deleteChat", "1234@s.whatsapp.net"], action)

      assert {:error, :not_found} = ExWapp.Chat.get(store, "1234@s.whatsapp.net")
    end

    test "dispatches delete chat action with delete-media index", %{store: store} do
      ExWapp.Chat.get_or_create(store, "1234@s.whatsapp.net")

      action = %SyncActionValue{
        delete_chat_action: %DeleteChatAction{}
      }

      Engine.dispatch_mutation(store, ["deleteChat", "1234@s.whatsapp.net", "1"], action)

      assert {:error, :not_found} = ExWapp.Chat.get(store, "1234@s.whatsapp.net")
    end

    test "returns :ignored for unknown index" do
      store = ExWapp.Store.new(ExWapp.Store.Memory)

      assert :ignored =
               Engine.dispatch_mutation(store, ["unknown_action", "jid"], %SyncActionValue{})
    end
  end

  describe "apply_collection_response/3" do
    test "applies patch payloads wrapped in Binary.Raw" do
      store = ExWapp.Store.new(ExWapp.Store.Memory)
      key_id = :crypto.strong_rand_bytes(16)
      key_data = :crypto.strong_rand_bytes(32)
      key_hex = Base.encode16(key_id, case: :lower)

      data = ExWapp.Store.load!(store)

      ExWapp.Store.persist(
        store,
        Map.put(data, :app_state_keys, %{key_hex => %{data: key_data, timestamp: 1}})
      )

      patch_info = Engine.build_contact("1234@s.whatsapp.net", "Alice Example")

      {:ok, encoded_patch, _new_hash_state, _new_mutation_macs} =
        Engine.encode_patch(
          patch_info,
          key_id,
          key_data,
          %{version: 0, hash: LTHash.new()},
          %{}
        )

      response = %ExWapp.Binary.Node{
        tag: "iq",
        attrs: %{"type" => "result"},
        content: [
          %ExWapp.Binary.Node{
            tag: "sync",
            attrs: %{},
            content: [
              %ExWapp.Binary.Node{
                tag: "collection",
                attrs: %{"name" => "critical_unblock_low", "version" => "0"},
                content: [
                  %ExWapp.Binary.Node{
                    tag: "patches",
                    attrs: %{},
                    content: [
                      %ExWapp.Binary.Node{
                        tag: "patch",
                        attrs: %{},
                        content: ExWapp.Binary.raw(encoded_patch)
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }

      assert {:ok, 1} = Engine.apply_collection_response(store, "critical_unblock_low", response)

      contact = ExWapp.Contact.get(store, "1234@s.whatsapp.net")
      assert contact != nil
      assert contact.full_name == "Alice Example"
    end
  end
end
