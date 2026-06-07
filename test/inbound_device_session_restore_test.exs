defmodule ExWapp.InboundDeviceSessionRestoreTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Binary.Node
  alias ExWapp.MessageHandler
  alias ExWapp.Signal.{Encryption, Keys, SessionStore}

  test "decrypts whisper via persisted device-specific session when inbound envelope omits device suffix" do
    alice_identity = Keys.generate_key_pair()
    bob_identity = Keys.generate_key_pair()

    signed_id = 610
    prekey_id = 611

    bob_signed_prekey = Keys.generate_signed_prekey(bob_identity, signed_id)
    bob_one_time_prekey = Keys.generate_prekey(prekey_id)

    sender_device_jid = "33625382846503:91@lid"
    sender_base_jid = "33625382846503@lid"
    sender_pn_jid = "12025550123@s.whatsapp.net"

    bob_store =
      ExWapp.Store.Memory.new(
        initial_data: %{
          signal: %{
            identity_key: bob_identity,
            registration_id: 9902,
            signed_prekeys: %{signed_id => bob_signed_prekey},
            prekeys: %{prekey_id => bob_one_time_prekey}
          },
          lid_mapping: %{
            {:pn_to_lid, sender_pn_jid} => sender_base_jid,
            {:lid_to_pn, sender_base_jid} => sender_pn_jid
          },
          chats: %{}
        }
      )

    bob_bundle = %{
      registration_id: 9902,
      identity_key: bob_identity.public,
      signed_prekey: %{
        id: signed_id,
        public: bob_signed_prekey.public,
        signature: bob_signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: bob_one_time_prekey.public}
    }

    {:ok, first_payload} =
      ExWapp.Messages.build_text_proto("establish session", [])
      |> ExWapp.Proto.Message.encode()

    {:ok, first_ciphertext, :prekey, alice_sessions} =
      SessionStore.encrypt_message(
        SessionStore.new(),
        sender_device_jid,
        Encryption.pad_message(first_payload),
        alice_identity,
        777,
        bob_bundle
      )

    bob_local_prekeys = %{
      signed_prekeys: %{signed_id => bob_signed_prekey},
      prekeys: %{prekey_id => bob_one_time_prekey}
    }

    {:ok, _first_plaintext, persisted_sessions} =
      SessionStore.decrypt_message(
        SessionStore.new(),
        sender_device_jid,
        first_ciphertext,
        true,
        bob_identity,
        bob_local_prekeys
      )

    refute SessionStore.has_session?(persisted_sessions, sender_base_jid)
    assert SessionStore.has_session?(persisted_sessions, sender_device_jid)

    {:ok, second_payload} =
      ExWapp.Messages.build_text_proto("device-specific session survived restart", [])
      |> ExWapp.Proto.Message.encode()

    {:ok, second_ciphertext, :whisper, _alice_sessions_2} =
      SessionStore.encrypt_message(
        alice_sessions,
        sender_device_jid,
        Encryption.pad_message(second_payload),
        alice_identity,
        777,
        %{}
      )

    node = %Node{
      tag: "message",
      attrs: %{
        "from" => sender_base_jid,
        "id" => "DEVICE_RESTORE_1",
        "type" => "text",
        "t" => "1730000200",
        "sender_pn" => sender_pn_jid
      },
      content: [
        %Node{
          tag: "enc",
          attrs: %{"type" => "msg", "v" => "2"},
          content: Binary.raw(second_ciphertext)
        }
      ]
    }

    initial_state = %{
      store: bob_store,
      signal_sessions: persisted_sessions,
      stats: %{messages_received: 0}
    }

    assert {:ok, updated_state, actions} =
             MessageHandler.handle_node(node, self(), initial_state)

    assert Enum.any?(actions, fn
             {:signal_sessions_updated, sessions} ->
               SessionStore.has_session?(sessions, sender_device_jid)

             _ ->
               false
           end)

    assert Enum.any?(actions, fn
             {:send_receipt, ^sender_base_jid, "DEVICE_RESTORE_1", _, _, _} -> true
             _ -> false
           end)

    refute Enum.any?(actions, fn
             {:send_retry_receipt, _, _, _, _, _, _, _} -> true
             _ -> false
           end)

    [message | _] = ExWapp.Chat.messages(bob_store, sender_base_jid, limit: 1)
    assert message.text == "device-specific session survived restart"
    assert SessionStore.has_session?(updated_state.signal_sessions, sender_device_jid)
  end
end
