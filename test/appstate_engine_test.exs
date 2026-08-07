defmodule ExWapp.AppState.EngineTest do
  use ExUnit.Case, async: true

  alias ExWapp.AppState.{CollectionLock, Crypto, Engine, LTHash}
  alias ExWapp.Session.AppStateSync

  alias WAWebProtobufsServerSync.{
    KeyId,
    SyncdIndex,
    SyncdMutation,
    SyncdPatch,
    SyncdRecord,
    SyncdValue
  }

  alias WAWebProtobufSyncAction.{
    ArchiveChatAction,
    CallLogAction,
    CallLogRecord,
    ContactAction,
    DeleteChatAction,
    DeleteIndividualCallLogAction,
    MuteAction,
    PinAction,
    SyncActionData,
    SyncActionValue
  }

  defmodule PaginationSession do
    use GenServer

    def start_link(parent, responses), do: GenServer.start_link(__MODULE__, {parent, responses})

    @impl true
    def init({parent, responses}), do: {:ok, %{parent: parent, responses: responses}}

    @impl true
    def handle_call({:send_iq, node, _message_id}, _from, %{responses: [response | rest]} = state) do
      send(state.parent, {:app_state_fetch_iq, node})
      {:reply, {:ok, response}, %{state | responses: rest}}
    end

    def handle_call({:send_iq, _node, _message_id}, _from, state) do
      {:reply, {:error, :no_response}, state}
    end
  end

  defmodule MutationSession do
    use GenServer

    def start_link(parent, opts \\ []), do: GenServer.start_link(__MODULE__, {parent, opts})

    @impl true
    def init({parent, opts}), do: {:ok, %{parent: parent, fail_fetch?: opts[:fail_fetch]}}

    @impl true
    def handle_call({:send_iq, node, _message_id}, _from, state) do
      collection = collection_node(node)
      kind = if collection.content in [nil, []], do: :fetch, else: :mutation
      send(state.parent, {:app_state_iq, kind, node})

      if kind == :fetch and state.fail_fetch? do
        {:reply, {:error, :sync_unavailable}, state}
      else
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
                  attrs: %{
                    "name" => collection.attrs["name"],
                    "has_more_patches" => "false"
                  },
                  content: []
                }
              ]
            }
          ]
        }

        {:reply, {:ok, response}, state}
      end
    end

    defp collection_node(%ExWapp.Binary.Node{
           content: [%ExWapp.Binary.Node{content: [%ExWapp.Binary.Node{} = collection]}]
         }),
         do: collection
  end

  # Contact mutation builders

  describe "build_contact/3" do
    test "builds a contact patch for critical_unblock_low" do
      patch = Engine.build_contact("1234@s.whatsapp.net", "John Doe", "John")

      assert patch.type == "critical_unblock_low"
      assert length(patch.mutations) == 1

      [mutation] = patch.mutations
      assert mutation.index == ["contact", "1234@s.whatsapp.net"]
      assert mutation.version == 2
      assert mutation.value.contactAction.fullName == "John Doe"
      assert mutation.value.contactAction.firstName == "John"
      assert mutation.value.contactAction.saveOnPrimaryAddressbook == true
    end

    test "defaults first_name to full_name when nil" do
      patch = Engine.build_contact("1234@s.whatsapp.net", "John Doe")
      [mutation] = patch.mutations
      assert mutation.value.contactAction.firstName == "John Doe"
    end

    test "normalizes contact jid by stripping + and normalizing domain" do
      patch = Engine.build_contact("+1234@whatsapp.net", "John Doe")
      [mutation] = patch.mutations
      assert mutation.index == ["contact", "1234@s.whatsapp.net"]
    end
  end

  describe "send_mutation/3 synchronization" do
    test "refreshes the contact collection before encoding and sending the patch" do
      store = app_state_store()
      {:ok, session} = MutationSession.start_link(self())
      patch = Engine.build_contact("1234@s.whatsapp.net", "John Doe")

      assert {:ok, %{version: 1}, mutation_macs} =
               Engine.send_mutation(session, patch, store)

      assert map_size(mutation_macs) == 1
      assert_receive {:app_state_iq, :fetch, fetch_node}
      assert_receive {:app_state_iq, :mutation, _mutation_node}

      assert collection_request_attrs(fetch_node) == %{
               "name" => "critical_unblock_low",
               "return_snapshot" => "true"
             }

      assert ExWapp.Contact.get(store, "1234@s.whatsapp.net").full_name == "John Doe"

      # A successful mutation also retains the existing asynchronous
      # post-write refresh, which must wait until the write lock is released.
      assert_receive {:app_state_iq, :fetch, _refresh_node}
    end

    test "does not send a contact patch when the pre-write sync fails" do
      store = app_state_store()
      {:ok, session} = MutationSession.start_link(self(), fail_fetch: true)
      patch = Engine.build_contact("1234@s.whatsapp.net", "John Doe")

      assert {:error, {:iq_failed, :sync_unavailable}} =
               Engine.send_mutation(session, patch, store)

      assert_receive {:app_state_iq, :fetch, _fetch_node}
      refute_receive {:app_state_iq, :mutation, _mutation_node}
      assert ExWapp.Contact.get(store, "1234@s.whatsapp.net") == nil
    end

    test "serializes concurrent operations for one contact collection" do
      store = app_state_store()
      collection = "critical_unblock_low"
      parent = self()

      operation = fn ->
        CollectionLock.with_lock(store, collection, fn ->
          send(parent, {:contact_collection_entered, self()})
          receive do: (:release_contact_collection -> :ok)
        end)
      end

      first = Task.async(operation)
      first_pid = first.pid
      assert_receive {:contact_collection_entered, ^first_pid}

      second = Task.async(operation)
      second_pid = second.pid
      refute_receive {:contact_collection_entered, ^second_pid}, 100

      send(first_pid, :release_contact_collection)
      assert :ok = Task.await(first)
      assert_receive {:contact_collection_entered, ^second_pid}

      send(second_pid, :release_contact_collection)
      assert :ok = Task.await(second)
    end

    test "concurrent contact writes advance one shared hash chain" do
      store = app_state_store()
      {:ok, session} = MutationSession.start_link(self())

      tasks =
        for {jid, name} <- [
              {"1001@s.whatsapp.net", "First Contact"},
              {"1002@s.whatsapp.net", "Second Contact"}
            ] do
          Task.async(fn ->
            Engine.send_mutation(session, Engine.build_contact(jid, name), store)
          end)
        end

      versions =
        tasks
        |> Enum.map(&Task.await/1)
        |> Enum.map(fn {:ok, %{version: version}, _mutation_macs} -> version end)
        |> Enum.sort()

      assert versions == [1, 2]
      assert ExWapp.Contact.get(store, "1001@s.whatsapp.net").full_name == "First Contact"
      assert ExWapp.Contact.get(store, "1002@s.whatsapp.net").full_name == "Second Contact"

      assert {:ok, %{version: 2}, mutation_macs} =
               Engine.get_collection_state(store, "critical_unblock_low")

      assert map_size(mutation_macs) == 2
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
      assert archive.value.archiveChatAction.archived == true
      assert unpin.index == ["pin_v1", "1234@s.whatsapp.net"]
      assert unpin.value.pinAction.pinned == false
    end

    test "builds unarchive patch without unpin" do
      patch = Engine.build_archive("1234@s.whatsapp.net", false)

      assert patch.type == "regular_low"
      assert length(patch.mutations) == 1

      [archive] = patch.mutations
      assert archive.value.archiveChatAction.archived == false
    end
  end

  describe "build_pin/2" do
    test "builds pin patch" do
      patch = Engine.build_pin("1234@s.whatsapp.net", true)

      assert patch.type == "regular_low"
      [mutation] = patch.mutations
      assert mutation.index == ["pin_v1", "1234@s.whatsapp.net"]
      assert mutation.version == 5
      assert mutation.value.pinAction.pinned == true
    end
  end

  describe "build_mute/3" do
    test "builds mute forever patch" do
      patch = Engine.build_mute("1234@s.whatsapp.net", true)

      assert patch.type == "regular_high"
      [mutation] = patch.mutations
      assert mutation.index == ["mute", "1234@s.whatsapp.net"]
      assert mutation.value.muteAction.muted == true
      assert mutation.value.muteAction.muteEndTimestamp == -1
    end

    test "builds mute with specific end timestamp" do
      ts = System.system_time(:millisecond) + 86_400_000
      patch = Engine.build_mute("1234@s.whatsapp.net", true, ts)

      [mutation] = patch.mutations
      assert mutation.value.muteAction.muteEndTimestamp == ts
    end

    test "builds unmute patch" do
      patch = Engine.build_mute("1234@s.whatsapp.net", false)

      [mutation] = patch.mutations
      assert mutation.value.muteAction.muted == false
      assert mutation.value.muteAction.muteEndTimestamp == nil
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
      assert mutation.value.markChatAsReadAction.read == true
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

  # Patch encoding

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
      {:ok, decoded_patch} = SyncdPatch.decode(encoded)

      assert decoded_patch.version == nil
      assert length(decoded_patch.mutations) == 1
      assert is_binary(decoded_patch.snapshotMAC)
      assert is_binary(decoded_patch.patchMAC)

      [mutation] = decoded_patch.mutations
      assert mutation.operation == :SET
      assert is_binary(mutation.record.index.blob)
      assert is_binary(mutation.record.value.blob)
      assert mutation.record.keyID."ID" == key_id

      # Decrypt the mutation
      key_store = %{
        Base.encode16(key_id, case: :lower) => %{data: key_data}
      }

      {:ok, decoded_mutations} = Engine.decode_mutations([mutation], key_store, true)

      assert length(decoded_mutations) == 1
      [dm] = decoded_mutations
      assert dm.index == ["pin_v1", "test@s.whatsapp.net"]
      assert dm.action.pinAction.pinned == true
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

      {:ok, decoded_patch} = SyncdPatch.decode(encoded)
      assert length(decoded_patch.mutations) == 2
    end
  end

  # Mutation decoding

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
          muteAction: %MuteAction{muted: true, muteEndTimestamp: -1},
          timestamp: System.system_time(:millisecond)
        },
        padding: <<>>,
        version: 2
      }

      content = action_data |> SyncActionData.encode!() |> IO.iodata_to_binary()
      {iv, ciphertext} = Crypto.encrypt_cbc(content, keys.value_encryption)
      encrypted_content = iv <> ciphertext

      value_mac =
        Crypto.compute_content_mac(0, encrypted_content, key_id, keys.value_mac)

      index_mac = Crypto.compute_index_mac(index_json, keys.index)

      mutation = %SyncdMutation{
        operation: :SET,
        record: %SyncdRecord{
          index: %SyncdIndex{blob: index_mac},
          value: %SyncdValue{blob: encrypted_content <> value_mac},
          keyID: %KeyId{ID: key_id}
        }
      }

      key_store = %{
        Base.encode16(key_id, case: :lower) => %{data: key_data}
      }

      assert {:ok, [decoded]} = Engine.decode_mutations([mutation], key_store, true)
      assert decoded.index == ["mute", "test@s.whatsapp.net"]
      assert decoded.operation == 0
      assert decoded.action.muteAction.muted == true
    end

    test "returns error for mismatching content MAC" do
      key_id = :crypto.strong_rand_bytes(16)
      key_data = :crypto.strong_rand_bytes(32)
      keys = Crypto.expand_keys(key_data)

      content =
        SyncActionData.encode!(%SyncActionData{
          index: "[]",
          value: %SyncActionValue{},
          padding: <<>>,
          version: 1
        })
        |> IO.iodata_to_binary()

      {iv, ciphertext} = Crypto.encrypt_cbc(content, keys.value_encryption)
      encrypted_content = iv <> ciphertext

      # Corrupt the MAC
      bad_mac = :crypto.strong_rand_bytes(32)
      index_mac = Crypto.compute_index_mac("[]", keys.index)

      mutation = %SyncdMutation{
        operation: :SET,
        record: %SyncdRecord{
          index: %SyncdIndex{blob: index_mac},
          value: %SyncdValue{blob: encrypted_content <> bad_mac},
          keyID: %KeyId{ID: key_id}
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
        SyncActionData.encode!(%SyncActionData{
          index: index_json,
          value: %SyncActionValue{
            contactAction: %ContactAction{fullName: "Test", firstName: "Test"}
          },
          padding: <<>>,
          version: 2
        })
        |> IO.iodata_to_binary()

      {iv, ciphertext} = Crypto.encrypt_cbc(content, keys.value_encryption)
      encrypted_content = iv <> ciphertext

      # Use a garbage MAC — should still work with validate=false
      fake_mac = :crypto.strong_rand_bytes(32)

      mutation = %SyncdMutation{
        operation: :SET,
        record: %SyncdRecord{
          index: %SyncdIndex{blob: :crypto.strong_rand_bytes(32)},
          value: %SyncdValue{blob: encrypted_content <> fake_mac},
          keyID: %KeyId{ID: key_id}
        }
      }

      key_store = %{
        Base.encode16(key_id, case: :lower) => %{data: key_data}
      }

      assert {:ok, [decoded]} = Engine.decode_mutations([mutation], key_store, false)
      assert decoded.index == ["contact", "test@s.whatsapp.net"]
      assert decoded.action.contactAction.fullName == "Test"
    end
  end

  # Collection state

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

  # Mutation dispatch

  describe "dispatch_mutation/3" do
    setup do
      store = ExWapp.Store.new(ExWapp.Store.Memory)
      %{store: store}
    end

    test "dispatches contact action", %{store: store} do
      action = %SyncActionValue{
        contactAction: %ContactAction{fullName: "Bob Smith", firstName: "Bob"}
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
        archiveChatAction: %ArchiveChatAction{archived: true}
      }

      assert :ok = Engine.dispatch_mutation(store, ["archive", "1234@s.whatsapp.net"], action)

      {:ok, chat} = ExWapp.Chat.get(store, "1234@s.whatsapp.net")
      assert chat.archived == true
    end

    test "dispatches pin action", %{store: store} do
      action = %SyncActionValue{
        pinAction: %PinAction{pinned: true}
      }

      assert :ok = Engine.dispatch_mutation(store, ["pin_v1", "1234@s.whatsapp.net"], action)

      {:ok, chat} = ExWapp.Chat.get(store, "1234@s.whatsapp.net")
      assert chat.pinned == true
    end

    test "dispatches mute action", %{store: store} do
      action = %SyncActionValue{
        muteAction: %MuteAction{muted: true, muteEndTimestamp: -1}
      }

      assert :ok = Engine.dispatch_mutation(store, ["mute", "1234@s.whatsapp.net"], action)

      {:ok, chat} = ExWapp.Chat.get(store, "1234@s.whatsapp.net")
      assert chat.muted_until == -1
    end

    test "dispatches call log action into the call log", %{store: store} do
      action = %SyncActionValue{
        callLogAction: %CallLogAction{
          callLogRecord: %CallLogRecord{
            callID: "SYNCCALL1",
            callResult: :MISSED,
            isIncoming: true,
            startTime: 1_754_000_000,
            duration: 0,
            callCreatorJID: "1234@s.whatsapp.net"
          }
        }
      }

      assert :ok = Engine.dispatch_mutation(store, ["call_log", "1234@s.whatsapp.net"], action)

      assert {:ok, call} = ExWapp.Call.get(store, "SYNCCALL1")
      assert call.status == :missed
      assert call.is_incoming == true
      assert call.chat_jid == "1234@s.whatsapp.net"
      assert call.source == :app_state
    end

    test "ignores call log actions without a record", %{store: store} do
      assert :ignored =
               Engine.dispatch_mutation(
                 store,
                 ["call_log", "1234@s.whatsapp.net"],
                 %SyncActionValue{}
               )
    end

    test "dispatches delete individual call log action", %{store: store} do
      action = %SyncActionValue{
        callLogAction: %CallLogAction{
          callLogRecord: %CallLogRecord{
            callID: "SYNCCALL2",
            callResult: :CONNECTED,
            isIncoming: true,
            callCreatorJID: "1234@s.whatsapp.net"
          }
        }
      }

      assert :ok = Engine.dispatch_mutation(store, ["call_log", "1234@s.whatsapp.net"], action)

      delete_action = %SyncActionValue{
        deleteIndividualCallLog: %DeleteIndividualCallLogAction{
          peerJID: "1234@s.whatsapp.net",
          isIncoming: true
        }
      }

      assert :ok =
               Engine.dispatch_mutation(
                 store,
                 ["delete_individual_call_log", "1234@s.whatsapp.net"],
                 delete_action
               )

      assert {:error, :not_found} = ExWapp.Call.get(store, "SYNCCALL2")
    end

    test "dispatches delete chat action", %{store: store} do
      # Create a chat first
      ExWapp.Chat.get_or_create(store, "1234@s.whatsapp.net")

      action = %SyncActionValue{
        deleteChatAction: %DeleteChatAction{}
      }

      Engine.dispatch_mutation(store, ["deleteChat", "1234@s.whatsapp.net"], action)

      assert {:error, :not_found} = ExWapp.Chat.get(store, "1234@s.whatsapp.net")
    end

    test "dispatches delete chat action with delete-media index", %{store: store} do
      ExWapp.Chat.get_or_create(store, "1234@s.whatsapp.net")

      action = %SyncActionValue{
        deleteChatAction: %DeleteChatAction{}
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

  describe "fetch_collection/3 pagination" do
    test "continues with the updated version until has_more_patches is false" do
      store = ExWapp.Store.new(ExWapp.Store.Memory)
      collection = "critical_unblock_low"
      key_id = :crypto.strong_rand_bytes(16)
      key_data = :crypto.strong_rand_bytes(32)
      key_hex = Base.encode16(key_id, case: :lower)

      :ok =
        ExWapp.Store.put(store, :app_state_keys, %{
          key_hex => %{data: key_data, timestamp: 1}
        })

      initial_state = %{version: 0, hash: LTHash.new()}

      {:ok, first_patch, first_state, first_macs} =
        Engine.encode_patch(
          Engine.build_contact("1001@s.whatsapp.net", "First Page"),
          key_id,
          key_data,
          initial_state,
          %{}
        )

      {:ok, second_patch, _second_state, _second_macs} =
        Engine.encode_patch(
          Engine.build_contact("1002@s.whatsapp.net", "Second Page"),
          key_id,
          key_data,
          first_state,
          first_macs
        )

      responses = [
        collection_response(collection, first_patch, true),
        collection_response(collection, second_patch, false)
      ]

      {:ok, session} = PaginationSession.start_link(self(), responses)

      assert :ok = Engine.fetch_collection(session, store, collection)

      assert_receive {:app_state_fetch_iq, first_request}

      assert collection_request_attrs(first_request) == %{
               "name" => collection,
               "return_snapshot" => "true"
             }

      assert_receive {:app_state_fetch_iq, second_request}

      assert collection_request_attrs(second_request) == %{
               "name" => collection,
               "return_snapshot" => "false",
               "version" => "1"
             }

      assert ExWapp.Contact.get(store, "1001@s.whatsapp.net").full_name == "First Page"
      assert ExWapp.Contact.get(store, "1002@s.whatsapp.net").full_name == "Second Page"
      assert {:ok, %{version: 2}, _macs} = Engine.get_collection_state(store, collection)
    end

    test "fails instead of looping when a paginated response makes no version progress" do
      store = ExWapp.Store.new(ExWapp.Store.Memory)
      collection = "regular"
      response = collection_response(collection, nil, true)
      {:ok, session} = PaginationSession.start_link(self(), [response])

      assert {:error, {:app_state_pagination_stalled, ^collection, 0, 0}} =
               Engine.fetch_collection(session, store, collection)
    end

    test "runtime call-log retention reaches paginated app-state dispatch" do
      store = ExWapp.Store.new(ExWapp.Store.Memory)
      collection = "regular"
      key_id = :crypto.strong_rand_bytes(16)
      key_data = :crypto.strong_rand_bytes(32)
      key_hex = Base.encode16(key_id, case: :lower)

      :ok =
        ExWapp.Store.put(store, :app_state_keys, %{
          key_hex => %{data: key_data, timestamp: 1}
        })

      {encoded_patches, _state, _macs} =
        Enum.reduce(1..3, {[], %{version: 0, hash: LTHash.new()}, %{}}, fn index,
                                                                           {patches, state, macs} ->
          patch_info = %{
            type: collection,
            timestamp: nil,
            mutations: [
              %{
                index: ["call_log", "1234@s.whatsapp.net"],
                version: 1,
                value: %SyncActionValue{
                  callLogAction: %CallLogAction{
                    callLogRecord: %CallLogRecord{
                      callID: "SYNCCALL#{index}",
                      callResult: :MISSED,
                      isIncoming: true,
                      startTime: index,
                      callCreatorJID: "1234@s.whatsapp.net"
                    }
                  }
                }
              }
            ]
          }

          {:ok, encoded, new_state, new_macs} =
            Engine.encode_patch(patch_info, key_id, key_data, state, macs)

          {[encoded | patches], new_state, new_macs}
        end)

      responses =
        encoded_patches
        |> Enum.reverse()
        |> Enum.with_index()
        |> Enum.map(fn {patch, index} -> collection_response(collection, patch, index < 2) end)

      {:ok, session} = PaginationSession.start_link(self(), responses)
      {:ok, task_supervisor} = Task.Supervisor.start_link()

      assert {:ok, task} =
               AppStateSync.refresh(
                 task_supervisor,
                 session,
                 store,
                 [collection],
                 :notification,
                 nil,
                 %{calls: %{max_records: 2}}
               )

      monitor = Process.monitor(task)
      assert_receive {:DOWN, ^monitor, :process, ^task, :normal}

      assert ["SYNCCALL3", "SYNCCALL2"] =
               store
               |> ExWapp.Call.list(order: :newest_first)
               |> Enum.map(& &1.id)
    end
  end

  defp collection_response(collection, patch, has_more?) do
    patch_content =
      if is_binary(patch) do
        [
          %ExWapp.Binary.Node{
            tag: "patches",
            attrs: %{},
            content: [
              %ExWapp.Binary.Node{
                tag: "patch",
                attrs: %{},
                content: ExWapp.Binary.raw(patch)
              }
            ]
          }
        ]
      else
        []
      end

    %ExWapp.Binary.Node{
      tag: "iq",
      attrs: %{"type" => "result"},
      content: [
        %ExWapp.Binary.Node{
          tag: "sync",
          attrs: %{},
          content: [
            %ExWapp.Binary.Node{
              tag: "collection",
              attrs: %{
                "name" => collection,
                "has_more_patches" => to_string(has_more?)
              },
              content: patch_content
            }
          ]
        }
      ]
    }
  end

  defp collection_request_attrs(%ExWapp.Binary.Node{
         content: [%ExWapp.Binary.Node{content: [%ExWapp.Binary.Node{attrs: attrs}]}]
       }),
       do: attrs

  defp app_state_store do
    key_id = :crypto.strong_rand_bytes(16)
    key_data = :crypto.strong_rand_bytes(32)
    key_hex = Base.encode16(key_id, case: :lower)

    ExWapp.Store.new(
      {ExWapp.Store.Memory,
       initial_data: %{
         app_state_keys: %{key_hex => %{data: key_data, timestamp: 1}}
       }}
    )
  end
end
