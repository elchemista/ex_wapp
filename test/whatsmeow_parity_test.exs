defmodule ExWapp.WhatsmeowParityTest do
  use ExUnit.Case, async: false
  import Bitwise

  alias ExWapp.Binary
  alias ExWapp.Binary.Node
  alias ExWapp.MessageHandler
  alias ExWapp.Signal.{Keys, SessionStore}

  test "message proto encode/decode via signal prekey+whisper through handler" do
    alice_identity = Keys.generate_key_pair()
    bob_identity = Keys.generate_key_pair()

    signed_id = 300
    prekey_id = 301

    bob_signed_prekey = Keys.generate_signed_prekey(bob_identity, signed_id)
    bob_one_time_prekey = Keys.generate_prekey(prekey_id)

    bob_store =
      ExWapp.Store.Memory.new(
        initial_data: %{
          signal: %{
            identity_key: bob_identity,
            registration_id: 901,
            signed_prekeys: %{signed_id => bob_signed_prekey},
            prekeys: %{prekey_id => bob_one_time_prekey}
          },
          chats: %{}
        }
      )

    bob_bundle = %{
      registration_id: 901,
      identity_key: bob_identity.public,
      signed_prekey: %{
        id: signed_id,
        public: bob_signed_prekey.public,
        signature: bob_signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: bob_one_time_prekey.public}
    }

    sender_jid = "15550001111@s.whatsapp.net"

    {:ok, first_payload} =
      ExWapp.Messages.build_text_proto("hello from parity test", [])
      |> ExWapp.Proto.Message.encode()

    {:ok, first_ciphertext, :prekey, alice_sessions} =
      SessionStore.encrypt_message(
        SessionStore.new(),
        sender_jid,
        ExWapp.Signal.Encryption.pad_message(first_payload),
        alice_identity,
        444,
        bob_bundle
      )

    first_node = %Node{
      tag: "message",
      attrs: %{
        "from" => sender_jid,
        "id" => "PARITY_1",
        "type" => "text",
        "t" => "1730000000"
      },
      content: [
        %Node{
          tag: "enc",
          attrs: %{"type" => "pkmsg", "v" => "2"},
          content: Binary.raw(first_ciphertext)
        }
      ]
    }

    initial_state = %{
      store: bob_store,
      signal_sessions: SessionStore.new(),
      stats: %{messages_received: 0}
    }

    assert {:ok, state_after_first, _actions} =
             MessageHandler.handle_node(first_node, self(), initial_state)

    [first_message | _] = ExWapp.Chat.messages(bob_store, sender_jid, limit: 5)
    assert first_message.text == "hello from parity test"
    assert SessionStore.has_session?(state_after_first.signal_sessions, sender_jid)

    {:ok, second_payload} =
      ExWapp.Messages.build_text_proto("second message", [])
      |> ExWapp.Proto.Message.encode()

    {:ok, second_ciphertext, :whisper, _alice_sessions_2} =
      SessionStore.encrypt_message(
        alice_sessions,
        sender_jid,
        ExWapp.Signal.Encryption.pad_message(second_payload),
        alice_identity,
        444,
        %{}
      )

    second_node = %Node{
      tag: "message",
      attrs: %{
        "from" => sender_jid,
        "id" => "PARITY_2",
        "type" => "text",
        "t" => "1730000001"
      },
      content: [
        %Node{
          tag: "enc",
          attrs: %{"type" => "msg", "v" => "2"},
          content: Binary.raw(second_ciphertext)
        }
      ]
    }

    assert {:ok, _state_after_second, _actions} =
             MessageHandler.handle_node(second_node, self(), state_after_first)

    [latest, previous | _] = ExWapp.Chat.messages(bob_store, sender_jid, limit: 5)
    assert latest.id == "PARITY_2"
    assert latest.text == "second message"
    assert previous.id == "PARITY_1"
  end

  test "handler tries multiple enc candidates and decrypts the first valid one" do
    alice_identity = Keys.generate_key_pair()
    bob_identity = Keys.generate_key_pair()

    signed_id = 450
    prekey_id = 451

    bob_signed_prekey = Keys.generate_signed_prekey(bob_identity, signed_id)
    bob_one_time_prekey = Keys.generate_prekey(prekey_id)

    bob_store =
      ExWapp.Store.Memory.new(
        initial_data: %{
          signal: %{
            identity_key: bob_identity,
            registration_id: 9901,
            signed_prekeys: %{signed_id => bob_signed_prekey},
            prekeys: %{prekey_id => bob_one_time_prekey}
          },
          chats: %{}
        }
      )

    bob_bundle = %{
      registration_id: 9901,
      identity_key: bob_identity.public,
      signed_prekey: %{
        id: signed_id,
        public: bob_signed_prekey.public,
        signature: bob_signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: bob_one_time_prekey.public}
    }

    sender_jid = "15550001111@s.whatsapp.net"

    {:ok, payload} =
      ExWapp.Messages.build_text_proto("second enc candidate works", [])
      |> ExWapp.Proto.Message.encode()

    {:ok, valid_ciphertext, :prekey, _alice_sessions} =
      SessionStore.encrypt_message(
        SessionStore.new(),
        sender_jid,
        ExWapp.Signal.Encryption.pad_message(payload),
        alice_identity,
        777,
        bob_bundle
      )

    node = %Node{
      tag: "message",
      attrs: %{
        "from" => sender_jid,
        "id" => "PARITY_MULTI_ENC",
        "type" => "text",
        "t" => "1730000100"
      },
      content: [
        %Node{
          tag: "participants",
          attrs: %{},
          content: [
            %Node{
              tag: "to",
              attrs: %{"jid" => "111222333:9@s.whatsapp.net"},
              content: [
                %Node{
                  tag: "enc",
                  attrs: %{"type" => "pkmsg", "v" => "2"},
                  content: Binary.raw(<<0, 1, 2, 3, 4>>)
                }
              ]
            },
            %Node{
              tag: "to",
              attrs: %{"jid" => "111222333:1@s.whatsapp.net"},
              content: [
                %Node{
                  tag: "enc",
                  attrs: %{"type" => "pkmsg", "v" => "2"},
                  content: Binary.raw(valid_ciphertext)
                }
              ]
            }
          ]
        }
      ]
    }

    initial_state = %{
      store: bob_store,
      signal_sessions: SessionStore.new(),
      stats: %{messages_received: 0}
    }

    assert {:ok, _state_after, _actions} = MessageHandler.handle_node(node, self(), initial_state)
    [message | _] = ExWapp.Chat.messages(bob_store, sender_jid, limit: 1)
    assert message.text == "second enc candidate works"
  end

  test "history sync collections are reflected in chat/group metadata" do
    {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)

    notification = %Node{
      tag: "notification",
      attrs: %{
        "id" => "SYNC_1",
        "type" => "account_sync",
        "from" => "s.whatsapp.net"
      },
      content: [
        %Node{
          tag: "collection",
          attrs: %{"name" => "regular_low"},
          content: [
            %Node{
              tag: "item",
              attrs: %{},
              content: [
                %Node{
                  tag: "chat",
                  attrs: %{
                    "jid" => "111111111@s.whatsapp.net",
                    "name" => "Alice",
                    "count" => "3",
                    "t" => "1730000001",
                    "pin" => "1",
                    "archive" => "0",
                    "mute" => "0"
                  },
                  content: nil
                }
              ]
            },
            %Node{
              tag: "item",
              attrs: %{},
              content: [
                %Node{
                  tag: "chat",
                  attrs: %{
                    "jid" => "123456789@g.us",
                    "subject" => "Team Ops",
                    "count" => "7",
                    "last" => "1730000009",
                    "pin" => "0",
                    "archived" => "1",
                    "mute_t" => "1730001234"
                  },
                  content: nil
                }
              ]
            }
          ]
        }
      ]
    }

    send(session, {:connection_event, {:connection_message, notification}})

    chats = wait_for_chats(session, 2)

    alice = Enum.find(chats, &(&1.jid == "111111111@s.whatsapp.net"))
    assert alice
    assert alice.name == "Alice"
    assert alice.unread_count == 3
    assert alice.last_message_timestamp == 1_730_000_001
    assert alice.pinned
    refute alice.archived
    assert is_nil(alice.muted_until)
    refute alice.is_group

    group = Enum.find(chats, &(&1.jid == "123456789@g.us"))
    assert group
    assert group.name == "Team Ops"
    assert group.unread_count == 7
    assert group.last_message_timestamp == 1_730_000_009
    refute group.pinned
    assert group.archived
    assert group.muted_until == 1_730_001_234
    assert group.is_group

    groups = ExWapp.list_groups(session)
    assert Enum.map(groups, & &1.jid) == ["123456789@g.us"]

    GenServer.stop(session)
  end

  test "group create notifications upsert group chats" do
    {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)

    notification = %Node{
      tag: "notification",
      attrs: %{
        "id" => "GROUP_CREATE_1",
        "type" => "w:gp2",
        "from" => "987654321@g.us"
      },
      content: [
        %Node{
          tag: "create",
          attrs: %{},
          content: [
            %Node{
              tag: "group",
              attrs: %{
                "id" => "987654321@g.us",
                "subject" => "Project Squad",
                "creation" => "1730000200"
              },
              content: nil
            }
          ]
        }
      ]
    }

    send(session, {:connection_event, {:connection_message, notification}})

    _chats = wait_for_chats(session, 1)
    groups = wait_for_groups(session, 1)

    assert length(groups) == 1
    group = hd(groups)
    assert group.jid == "987654321@g.us"
    assert group.name == "Project Squad"
    assert group.last_message_timestamp == 1_730_000_200
    assert group.is_group

    GenServer.stop(session)
  end

  test "protocol history sync inline payload populates chat and group metadata" do
    alice_identity = Keys.generate_key_pair()
    bob_identity = Keys.generate_key_pair()

    signed_id = 700
    prekey_id = 701

    bob_signed_prekey = Keys.generate_signed_prekey(bob_identity, signed_id)
    bob_one_time_prekey = Keys.generate_prekey(prekey_id)

    bob_store =
      ExWapp.Store.Memory.new(
        initial_data: %{
          signal: %{
            identity_key: bob_identity,
            registration_id: 11_901,
            signed_prekeys: %{signed_id => bob_signed_prekey},
            prekeys: %{prekey_id => bob_one_time_prekey}
          },
          chats: %{}
        }
      )

    bob_bundle = %{
      registration_id: 11_901,
      identity_key: bob_identity.public,
      signed_prekey: %{
        id: signed_id,
        public: bob_signed_prekey.public,
        signature: bob_signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: bob_one_time_prekey.public}
    }

    sender_jid = "15550001111@s.whatsapp.net"

    history_sync_payload =
      build_history_sync_protocol_message([
        %{
          jid: "111111111@s.whatsapp.net",
          name: "Alice",
          unread_count: 3,
          last_message_timestamp: 1_730_000_001,
          pinned: true,
          archived: false,
          muted_until: 0
        },
        %{
          jid: "123456789@g.us",
          name: "Team Ops",
          unread_count: 7,
          last_message_timestamp: 1_730_000_009,
          pinned: false,
          archived: true,
          muted_until: 1_730_001_234
        }
      ])

    {:ok, ciphertext, :prekey, _alice_sessions} =
      SessionStore.encrypt_message(
        SessionStore.new(),
        sender_jid,
        ExWapp.Signal.Encryption.pad_message(history_sync_payload),
        alice_identity,
        888,
        bob_bundle
      )

    node = %Node{
      tag: "message",
      attrs: %{
        "from" => sender_jid,
        "id" => "HISTORY_SYNC_INLINE_1",
        "type" => "text",
        "t" => "1730000300"
      },
      content: [
        %Node{
          tag: "enc",
          attrs: %{"type" => "pkmsg", "v" => "2"},
          content: Binary.raw(ciphertext)
        }
      ]
    }

    initial_state = %{
      store: bob_store,
      signal_sessions: SessionStore.new(),
      stats: %{messages_received: 0}
    }

    assert {:ok, _state_after, _actions} = MessageHandler.handle_node(node, self(), initial_state)

    chats = ExWapp.Chat.list(bob_store)
    assert length(chats) == 2

    alice = Enum.find(chats, &(&1.jid == "111111111@s.whatsapp.net"))
    assert alice
    assert alice.name == "Alice"
    assert alice.unread_count == 3
    assert alice.last_message_timestamp == 1_730_000_001
    assert alice.pinned
    refute alice.archived
    assert is_nil(alice.muted_until)
    refute alice.is_group

    group = Enum.find(chats, &(&1.jid == "123456789@g.us"))
    assert group
    assert group.name == "Team Ops"
    assert group.unread_count == 7
    assert group.last_message_timestamp == 1_730_000_009
    refute group.pinned
    assert group.archived
    assert group.muted_until == 1_730_001_234
    assert group.is_group

    groups = ExWapp.Chat.list_groups(bob_store)
    assert Enum.map(groups, & &1.jid) == ["123456789@g.us"]

    contact = ExWapp.Contact.get(bob_store, "111111111@s.whatsapp.net")
    assert contact
    assert contact.push_name == "Alice"
    assert ExWapp.Contact.get(bob_store, "123456789@g.us") == nil
  end

  test "protocol history sync inline payload ingests conversation messages" do
    alice_identity = Keys.generate_key_pair()
    bob_identity = Keys.generate_key_pair()

    signed_id = 705
    prekey_id = 706

    bob_signed_prekey = Keys.generate_signed_prekey(bob_identity, signed_id)
    bob_one_time_prekey = Keys.generate_prekey(prekey_id)

    bob_store =
      ExWapp.Store.Memory.new(
        initial_data: %{
          signal: %{
            identity_key: bob_identity,
            registration_id: 11_951,
            signed_prekeys: %{signed_id => bob_signed_prekey},
            prekeys: %{prekey_id => bob_one_time_prekey}
          },
          chats: %{}
        }
      )

    bob_bundle = %{
      registration_id: 11_951,
      identity_key: bob_identity.public,
      signed_prekey: %{
        id: signed_id,
        public: bob_signed_prekey.public,
        signature: bob_signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: bob_one_time_prekey.public}
    }

    sender_jid = "15550001111@s.whatsapp.net"
    chat_jid = "111111111@s.whatsapp.net"

    history_sync_payload =
      build_history_sync_protocol_message([
        %{
          jid: chat_jid,
          name: "Alice",
          unread_count: 0,
          last_message_timestamp: 1_730_010_003,
          pinned: false,
          archived: false,
          muted_until: 0,
          messages: [
            %{
              id: "HS_MSG_1",
              text: "first from history",
              timestamp: 1_730_010_001,
              order_id: 1
            },
            %{
              id: "HS_MSG_2",
              extended_text: "latest from history",
              timestamp: 1_730_010_003,
              order_id: 2
            },
            %{
              id: "HS_MSG_3",
              text: "from me history",
              from_me: true,
              timestamp: 1_730_010_002,
              order_id: 3
            }
          ]
        }
      ])

    {:ok, ciphertext, :prekey, _alice_sessions} =
      SessionStore.encrypt_message(
        SessionStore.new(),
        sender_jid,
        ExWapp.Signal.Encryption.pad_message(history_sync_payload),
        alice_identity,
        890,
        bob_bundle
      )

    node = %Node{
      tag: "message",
      attrs: %{
        "from" => sender_jid,
        "id" => "HISTORY_SYNC_MESSAGES_1",
        "type" => "text",
        "t" => "1730010200"
      },
      content: [
        %Node{
          tag: "enc",
          attrs: %{"type" => "pkmsg", "v" => "2"},
          content: Binary.raw(ciphertext)
        }
      ]
    }

    initial_state = %{
      store: bob_store,
      signal_sessions: SessionStore.new(),
      stats: %{messages_received: 0}
    }

    assert {:ok, _state_after, _actions} = MessageHandler.handle_node(node, self(), initial_state)

    messages = ExWapp.Chat.messages(bob_store, chat_jid, limit: 10)
    assert Enum.map(messages, & &1.id) == ["HS_MSG_2", "HS_MSG_3", "HS_MSG_1"]

    assert Enum.find(messages, &(&1.id == "HS_MSG_1")).text == "first from history"
    assert Enum.find(messages, &(&1.id == "HS_MSG_2")).text == "latest from history"
    assert Enum.find(messages, &(&1.id == "HS_MSG_3")).from_me

    {:ok, chat} = ExWapp.Chat.get(bob_store, chat_jid)
    assert chat.unread_count == 0
  end

  test "protocol history sync with only group conversations does not create contacts" do
    alice_identity = Keys.generate_key_pair()
    bob_identity = Keys.generate_key_pair()

    signed_id = 710
    prekey_id = 711

    bob_signed_prekey = Keys.generate_signed_prekey(bob_identity, signed_id)
    bob_one_time_prekey = Keys.generate_prekey(prekey_id)

    bob_store =
      ExWapp.Store.Memory.new(
        initial_data: %{
          signal: %{
            identity_key: bob_identity,
            registration_id: 12_001,
            signed_prekeys: %{signed_id => bob_signed_prekey},
            prekeys: %{prekey_id => bob_one_time_prekey}
          },
          chats: %{}
        }
      )

    bob_bundle = %{
      registration_id: 12_001,
      identity_key: bob_identity.public,
      signed_prekey: %{
        id: signed_id,
        public: bob_signed_prekey.public,
        signature: bob_signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: bob_one_time_prekey.public}
    }

    sender_jid = "15550001111@s.whatsapp.net"
    group_jid = "333333333@g.us"

    history_sync_payload =
      build_history_sync_protocol_message([
        %{
          jid: group_jid,
          name: "Infra Team",
          unread_count: 2,
          last_message_timestamp: 1_730_004_444,
          pinned: false,
          archived: false,
          muted_until: 0
        }
      ])

    {:ok, ciphertext, :prekey, _alice_sessions} =
      SessionStore.encrypt_message(
        SessionStore.new(),
        sender_jid,
        ExWapp.Signal.Encryption.pad_message(history_sync_payload),
        alice_identity,
        889,
        bob_bundle
      )

    node = %Node{
      tag: "message",
      attrs: %{
        "from" => sender_jid,
        "id" => "HISTORY_SYNC_GROUP_ONLY_1",
        "type" => "text",
        "t" => "1730000400"
      },
      content: [
        %Node{
          tag: "enc",
          attrs: %{"type" => "pkmsg", "v" => "2"},
          content: Binary.raw(ciphertext)
        }
      ]
    }

    initial_state = %{
      store: bob_store,
      signal_sessions: SessionStore.new(),
      stats: %{messages_received: 0}
    }

    assert {:ok, _state_after, _actions} = MessageHandler.handle_node(node, self(), initial_state)

    assert {:ok, group_chat} = ExWapp.Chat.get(bob_store, group_jid)
    assert group_chat.name == "Infra Team"
    assert group_chat.is_group
    assert ExWapp.Contact.get(bob_store, group_jid) == nil
  end

  defp build_history_sync_protocol_message(conversations) do
    history_sync =
      [
        encode_varint_field(1, 0),
        Enum.map(conversations, fn conversation ->
          encode_length_delimited_field(2, encode_history_sync_conversation(conversation))
        end)
      ]
      |> IO.iodata_to_binary()

    history_sync_notification =
      [
        encode_varint_field(6, 0),
        encode_length_delimited_field(11, :zlib.compress(history_sync))
      ]
      |> IO.iodata_to_binary()

    protocol_message =
      encode_length_delimited_field(6, history_sync_notification)
      |> IO.iodata_to_binary()

    encode_length_delimited_field(12, protocol_message)
    |> IO.iodata_to_binary()
  end

  defp encode_history_sync_conversation(conversation) do
    []
    |> maybe_append_length_delimited_field(1, Map.get(conversation, :jid))
    |> maybe_append_history_sync_messages(
      Map.get(conversation, :messages, []),
      Map.get(conversation, :jid)
    )
    |> maybe_append_length_delimited_field(13, Map.get(conversation, :name))
    |> maybe_append_varint_field(6, Map.get(conversation, :unread_count))
    |> maybe_append_varint_field(5, Map.get(conversation, :last_message_timestamp))
    |> maybe_append_varint_field(24, boolean_to_int(Map.get(conversation, :pinned)))
    |> maybe_append_varint_field(16, boolean_to_int(Map.get(conversation, :archived)))
    |> maybe_append_varint_field(25, Map.get(conversation, :muted_until))
    |> IO.iodata_to_binary()
  end

  defp maybe_append_length_delimited_field(acc, _field_num, value)
       when value in [nil, ""] do
    acc
  end

  defp maybe_append_length_delimited_field(acc, field_num, value) when is_binary(value) do
    [acc, encode_length_delimited_field(field_num, value)]
  end

  defp maybe_append_varint_field(acc, _field_num, nil), do: acc

  defp maybe_append_varint_field(acc, field_num, value)
       when is_integer(value) and value >= 0 do
    [acc, encode_varint_field(field_num, value)]
  end

  defp maybe_append_history_sync_messages(acc, messages, conversation_jid)
       when is_list(messages) do
    encoded_messages =
      Enum.map(messages, fn message ->
        encode_length_delimited_field(2, encode_history_sync_message(message, conversation_jid))
      end)

    [acc, encoded_messages]
  end

  defp maybe_append_history_sync_messages(acc, _messages, _conversation_jid), do: acc

  defp encode_history_sync_message(message, conversation_jid)
       when is_map(message) and is_binary(conversation_jid) do
    web_message_info = encode_web_message_info(message, conversation_jid)

    []
    |> maybe_append_length_delimited_field(1, web_message_info)
    |> maybe_append_varint_field(2, Map.get(message, :order_id))
    |> IO.iodata_to_binary()
  end

  defp encode_history_sync_message(_message, _conversation_jid), do: <<>>

  defp encode_web_message_info(message, conversation_jid) when is_map(message) do
    message_payload = encode_history_sync_message_payload(message)

    []
    |> maybe_append_length_delimited_field(
      1,
      encode_history_sync_message_key(message, conversation_jid)
    )
    |> maybe_append_length_delimited_field(2, message_payload)
    |> maybe_append_varint_field(3, Map.get(message, :timestamp))
    |> maybe_append_length_delimited_field(9, Map.get(message, :participant))
    |> IO.iodata_to_binary()
  end

  defp encode_history_sync_message_payload(message) when is_map(message) do
    cond do
      is_binary(Map.get(message, :extended_text)) and Map.get(message, :extended_text) != "" ->
        encode_length_delimited_field(
          6,
          encode_length_delimited_field(1, Map.get(message, :extended_text))
          |> IO.iodata_to_binary()
        )
        |> IO.iodata_to_binary()

      is_binary(Map.get(message, :text)) and Map.get(message, :text) != "" ->
        encode_length_delimited_field(1, Map.get(message, :text))
        |> IO.iodata_to_binary()

      true ->
        <<>>
    end
  end

  defp encode_history_sync_message_payload(_), do: <<>>

  defp encode_history_sync_message_key(message, conversation_jid) when is_map(message) do
    remote_jid =
      first_binary([
        Map.get(message, :remote_jid),
        Map.get(message, :jid),
        conversation_jid
      ])

    []
    |> maybe_append_length_delimited_field(1, remote_jid)
    |> maybe_append_varint_field(2, boolean_to_int(Map.get(message, :from_me, false)))
    |> maybe_append_length_delimited_field(3, Map.get(message, :id))
    |> maybe_append_length_delimited_field(4, Map.get(message, :participant))
    |> IO.iodata_to_binary()
  end

  defp first_binary(values) when is_list(values) do
    Enum.find(values, fn
      value when is_binary(value) and value != "" -> true
      _ -> false
    end)
  end

  defp encode_length_delimited_field(field_num, value) when is_binary(value) do
    [encode_varint(field_num <<< 3 ||| 2), encode_varint(byte_size(value)), value]
  end

  defp encode_varint_field(field_num, value) when is_integer(value) and value >= 0 do
    [encode_varint(field_num <<< 3), encode_varint(value)]
  end

  defp encode_varint(value) when is_integer(value) and value < 128, do: <<value::8>>

  defp encode_varint(value) when is_integer(value) and value >= 128 do
    <<(value &&& 0x7F) ||| 0x80::8, encode_varint(value >>> 7)::binary>>
  end

  defp boolean_to_int(true), do: 1
  defp boolean_to_int(false), do: 0
  defp boolean_to_int(_), do: nil

  defp wait_for_groups(session, expected_count, attempts \\ 20)

  defp wait_for_groups(session, _expected_count, 0), do: ExWapp.list_groups(session)

  defp wait_for_groups(session, expected_count, attempts) do
    groups = ExWapp.list_groups(session)

    if length(groups) >= expected_count do
      groups
    else
      Process.sleep(25)
      wait_for_groups(session, expected_count, attempts - 1)
    end
  end

  defp wait_for_chats(session, expected_count, attempts \\ 20)

  defp wait_for_chats(session, _expected_count, 0), do: ExWapp.list_chats(session)

  defp wait_for_chats(session, expected_count, attempts) do
    chats = ExWapp.list_chats(session)

    if length(chats) >= expected_count do
      chats
    else
      Process.sleep(25)
      wait_for_chats(session, expected_count, attempts - 1)
    end
  end
end
