defmodule ExWapp.ChatSyncRecoveryTest do
  use ExUnit.Case, async: true
  alias ExWapp.{Binary, Chat, JID, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.{Common, Notification}
  alias ExWapp.Session.{Account, DeviceCache}
  @jid "15550001111@s.whatsapp.net"
  @lid "70000001111@lid"

  test "legacy chat payloads migrate once while preserving metadata and newest edits" do
    legacy = %{
      jid: @jid,
      name: "Alice",
      unread_count: 3,
      messages: [
        %{id: "one", timestamp: "12", text: "old", from_me: false},
        %{id: "two", timestamp: 13, from_me: true},
        :invalid
      ]
    }

    store = Store.Memory.new(initial_data: %{chats: %{@jid => legacy}})
    assert {:ok, %{name: "Alice", unread_count: 3}} = Chat.get(store, elem(JID.parse(@jid), 1))
    assert length(Chat.messages(store, @jid)) == 2
    assert {:ok, %{jid: @jid}} = Chat.get(store, @jid)
    assert length(Chat.messages(store, @jid)) == 2
    refute Map.has_key?(Store.get(store, :chats)[@jid], :messages)

    assert :ok =
             Chat.merge_messages(store, @jid, [
               %{id: "one", timestamp: 14, text: "edited"},
               %{id: "three", timestamp: nil, from_me: true},
               %{text: "missing id"},
               :invalid
             ])

    assert Chat.find_message(store, @jid, "one").text == "edited"
    assert Chat.find_message(store, @jid, "three").status == :sent
    assert :ok = Chat.delete_messages(store, @jid, ["one"])
    assert nil == Chat.find_message(store, @jid, "one")
    assert :ok = Chat.merge_messages(store, @jid, nil)
  end

  test "local chat controls and incoming read state preserve unrelated metadata" do
    store = Store.Memory.new()
    assert :ok = Chat.merge_metadata(store, @jid, name: "Alice", unread_count: 4)
    assert :ok = Chat.archive(store, @jid)
    assert :ok = Chat.pin(store, @jid)
    assert :ok = Chat.update_muted(store, @jid, %{muted: true, muteEndTimestamp: 12345})

    assert {:ok, %Chat{archived: true, pinned: true, muted_until: 12345, unread_count: 4}} =
             Chat.get(store, @jid)

    assert :ok = Chat.mark_read_from_sync(store, @jid, %{markChatAsReadAction: %{read: false}})
    assert {:ok, %{unread_count: 4}} = Chat.get(store, @jid)
    assert :ok = Chat.mark_read_from_sync(store, @jid, %{markChatAsReadAction: %{read: true}})
    assert :ok = Chat.unarchive(store, @jid)
    assert :ok = Chat.unpin(store, @jid)
    assert :ok = Chat.update_muted(store, @jid, %{muted: false})

    assert {:ok,
            %Chat{
              name: "Alice",
              archived: false,
              pinned: false,
              muted_until: nil,
              unread_count: 0
            }} = Chat.get(store, @jid)
  end

  test "raw chat stanzas expose metadata without pretending encrypted payloads are text" do
    node = %Node{
      tag: "message",
      attrs: %{
        "from" => @jid,
        "id" => "one",
        "type" => "text",
        "t" => "123",
        "from_me" => "1",
        "participant" => "1555:2@s.whatsapp.net"
      },
      content: "hello"
    }

    assert {:ok, @jid,
            %{
              id: "one",
              text: "hello",
              timestamp: 123,
              from_me: true,
              participant: "1555:2@s.whatsapp.net"
            }} = Chat.parse_message_node(node)

    assert {:ok, @jid, %{text: "(encrypted)"}} =
             Chat.parse_message_node(%{
               node
               | content: [%Node{tag: "enc", content: Binary.raw("ciphertext")}]
             })

    assert {:ok, @jid, %{text: nil}} = Chat.parse_message_node(%{node | content: []})
    assert {:error, :invalid_message_node} = Chat.parse_message_node(%{node | attrs: %{}})
    assert {:error, :not_a_message} = Chat.parse_message_node(%Node{tag: "receipt"})
  end

  test "unknown stores return empty local views without crashing callers" do
    assert [] == Chat.messages(nil, @jid)
    assert [] == Enum.to_list(Chat.stream_messages(nil, @jid))
    assert nil == Chat.find_message(nil, @jid, "id")
    assert nil == Chat.find_message_by_id(nil, "id")
    assert :ok = Chat.merge_messages(nil, @jid, [%{id: "id"}])
    assert :ok = Chat.delete_messages(nil, @jid, ["id"])
    assert :ok = Chat.update_message_status(nil, @jid, "id", :read)
    assert :ok = Chat.update_message_status_by_id(nil, "id", :read)
    assert :ok = Chat.delete(nil, @jid)
    assert :ok = Chat.update_name(nil, @jid, "ignored")
  end

  test "server sync imports chat and group metadata and always returns a stanza acknowledgement" do
    store = Store.Memory.new()
    state = %{store: store}

    items = [
      %Node{
        tag: "item",
        content: [
          %Node{
            tag: "chat",
            attrs: %{
              "jid" => @jid,
              "name" => "Alice",
              "count" => "7",
              "t" => "123",
              "pin" => "true",
              "mute" => "0"
            }
          }
        ]
      },
      %Node{
        tag: "item",
        content: [
          %Node{
            tag: "group",
            attrs: %{"id" => "123@g.us", "subject" => "Project", "archive" => "1"}
          }
        ]
      },
      %Node{tag: "item"},
      %Node{tag: "other"}
    ]

    node = %Node{
      tag: "notification",
      attrs: %{"id" => "sync", "from" => "s.whatsapp.net", "type" => "server_sync"},
      content: [%Node{tag: "collection", content: items}, %Node{tag: "other"}]
    }

    assert {:ok, ^state, [{:send_node, %Node{tag: "ack", attrs: %{"id" => "sync"}}}]} =
             Notification.handle_notification(node, nil, state)

    assert {:ok, %Chat{name: "Alice", unread_count: 7, pinned: true, last_message_timestamp: 123}} =
             Chat.get(store, @jid)

    assert {:ok, %Chat{name: "Project", archived: true, is_group: true}} =
             Chat.get(store, "123@g.us")

    for type <- ["picture", "future-notification", "server_sync"] do
      assert {:ok, ^state, [_ack]} =
               Notification.handle_notification(
                 %{node | attrs: Map.put(node.attrs, "type", type), content: nil},
                 nil,
                 state
               )
    end
  end

  test "app-state notifications deduplicate collection names and target the supplied session" do
    state = %{store: Store.Memory.new(), session_pid: self()}
    collection = %Node{tag: "collection", attrs: %{"name" => "regular_low"}}

    node = %Node{
      tag: "notification",
      attrs: %{"type" => "w:sync:app:state", "id" => "sync", "from" => "s.whatsapp.net"},
      content: [
        %Node{
          tag: "sync",
          content: [
            collection,
            collection,
            %Node{tag: "collection", attrs: %{"name" => ""}},
            %Node{tag: "other"}
          ]
        }
      ]
    }

    assert {:ok, ^state, [_]} = Notification.handle_notification(node, nil, state)
    assert_receive {:app_state_sync_collections, ["regular_low"]}

    assert {:ok, ^state, [_]} =
             Notification.handle_notification(%{node | content: nil}, self(), state)

    refute_receive {:app_state_sync_collections, _}
  end

  test "device cache respects alias families, expiry, throttle and targeted eviction" do
    store =
      Store.Memory.new(
        initial_data: %{lid_mapping: %{{:lid_to_pn, @lid} => @jid, {:pn_to_lid, @jid} => @lid}}
      )

    assert :ok =
             DeviceCache.persist_usync_map(store, %{
               @jid => ["15550001111:1@s.whatsapp.net", "15550001111:2@s.whatsapp.net"]
             })

    assert Enum.sort(DeviceCache.resolve_recent_devices(store, @lid, %{})) == [
             "70000001111:1@lid",
             "70000001111:2@lid"
           ]

    before = Store.load_device_cache(store)
    assert :ok = DeviceCache.persist_observed_device(store, "15550001111:1@s.whatsapp.net")
    assert before == Store.load_device_cache(store)
    assert :ok = DeviceCache.evict_devices(store, ["70000001111:1@lid", "absent", ""])

    assert DeviceCache.resolve_recent_devices(store, @jid, %{}) == [
             "15550001111:2@s.whatsapp.net"
           ]

    assert :ok = DeviceCache.evict_devices(store, ["15550001111:2@s.whatsapp.net"])
    assert Store.load_device_cache(store) == %{}

    :ok =
      Store.persist_device_cache(store, %{
        @jid => %{
          devices: %{
            "15550001111:1@s.whatsapp.net" => 0,
            "15550001111:2@s.whatsapp.net" => :invalid
          }
        }
      })

    assert [] ==
             DeviceCache.resolve_recent_devices(store, @jid, %{
               signal: %{device_cache_max_age_ms: 1}
             })

    :ok = DeviceCache.invalidate_bases(store, [@lid])
    assert %{} == Store.load_device_cache(store)
  end

  test "account aliases and device identity fallbacks remain usable during store migrations" do
    store =
      Store.Memory.new(
        initial_data: %{
          client_info: %{
            jid: elem(JID.parse("15550001111:3@s.whatsapp.net"), 1),
            lid: "70000001111:3@lid"
          },
          pairing: %{adv: %{signed: :invalid}, device_identity: "legacy-identity"}
        }
      )

    assert Account.local_account_device_id(store) == 3
    assert Account.local_account_base_jid(store) == @jid
    assert Account.local_account_lid_jid(store) == @lid
    assert Account.local_account_chatstate_jid(store, "777@lid") == "70000001111:3@lid"
    assert Account.local_account_chatstate_jid(store, @jid) == "15550001111:3@s.whatsapp.net"
    assert Account.local_account_sender_identity_for_destination(store, "777@lid") == @lid

    assert {:ok, %Node{tag: "device-identity", content: %Binary.Raw{data: "legacy-identity"}}} =
             Account.get_device_identity_node(store)

    :ok = Store.put(store, :pairing, %{adv_device_identity: "alternate"})

    assert {:ok, %Node{content: %Binary.Raw{data: "alternate"}}} =
             Account.get_device_identity_node(store)

    :ok = Store.put(store, :client_info, %{lid: @lid})
    assert Account.local_account_sender_identity_for_destination(store, @jid) == @lid
    :ok = Store.put(store, :client_info, %{jid: @jid})
    assert Account.local_account_sender_identity_for_destination(store, "777@lid") == @jid
    :ok = Store.put(store, :client_info, %{})
    assert Account.local_account_sender_identity_for_destination(store, @jid) == ""
    assert Account.local_account_device_id(store) == 0
  end

  test "sync metadata ignores malformed values instead of erasing a known chat" do
    store = Store.Memory.new()

    :ok =
      Common.upsert_chat_from_sync_attrs(store, %{
        "jid" => @jid,
        "name" => "Alice",
        "count" => "3",
        "mute" => "-1"
      })

    :ok =
      Common.upsert_chat_from_sync_attrs(store, %{
        "jid" => @jid,
        "count" => "bad",
        "pinned" => "unknown",
        "name" => "",
        "archive" => "no"
      })

    assert {:ok, %Chat{name: "Alice", unread_count: 3, archived: false}} = Chat.get(store, @jid)
    assert :ok = Common.upsert_chat_from_sync_attrs(store, %{"jid" => ""})
    assert :ok = Common.upsert_chat_from_sync_attrs(store, nil, %{})
    assert [%Chat{}] = Chat.list(store)
  end
end
