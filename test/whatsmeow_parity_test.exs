defmodule ExWapp.WhatsmeowParityTest do
  use ExUnit.Case, async: false

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

    sender_jid = "393519534944@s.whatsapp.net"

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

    sender_jid = "393519534944@s.whatsapp.net"

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

  test "history sync collections are reflected in chat list" do
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
          attrs: %{"name" => "regular_high"},
          content: [
            %Node{
              tag: "item",
              attrs: %{},
              content: [
                %Node{
                  tag: "chat",
                  attrs: %{"jid" => "111111111@s.whatsapp.net", "name" => "Alice"},
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
                  attrs: %{"jid" => "222222222@s.whatsapp.net", "name" => "Bob"},
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

    assert Enum.any?(chats, &(&1.jid == "111111111@s.whatsapp.net" and &1.name == "Alice"))
    assert Enum.any?(chats, &(&1.jid == "222222222@s.whatsapp.net" and &1.name == "Bob"))

    GenServer.stop(session)
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
