defmodule ExWapp.SignalPrekeyConsumptionTest do
  use ExUnit.Case, async: true

  alias ExWapp.Signal.{Encryption, Keys, SessionStore}
  alias ExWapp.Store
  alias ExWapp.Store.Memory

  test "successful prekey decrypt consumes the one-time prekey and rejects redelivery" do
    alice_identity = Keys.generate_key_pair()
    bob_identity = Keys.generate_key_pair()

    signed_prekey_id = 201
    prekey_id = 301

    bob_signed_prekey = Keys.generate_signed_prekey(bob_identity, signed_prekey_id)
    bob_one_time_prekey = Keys.generate_prekey(prekey_id)

    bob_bundle = %{
      registration_id: 4321,
      identity_key: bob_identity.public,
      signed_prekey: %{
        id: signed_prekey_id,
        public: bob_signed_prekey.public,
        signature: bob_signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: bob_one_time_prekey.public}
    }

    alice_jid = "444555666@s.whatsapp.net"
    bob_jid = "999888777@s.whatsapp.net"

    {:ok, ciphertext, :prekey, _alice_sessions} =
      SessionStore.encrypt_message(
        SessionStore.new(),
        bob_jid,
        "first",
        alice_identity,
        1001,
        bob_bundle
      )

    store =
      Memory.new(
        initial_data: %{
          signal: %{
            identity_key: bob_identity,
            signed_prekeys: %{signed_prekey_id => bob_signed_prekey},
            prekeys: %{prekey_id => bob_one_time_prekey},
            next_prekey_id: prekey_id + 1
          }
        }
      )

    on_exit(fn -> Memory.stop(store) end)

    assert {:ok, "first", bob_sessions} =
             Encryption.decrypt_from_sender_sync(
               store,
               SessionStore.new(),
               alice_jid,
               ciphertext,
               "pkmsg"
             )

    persisted = Store.load!(store)
    persisted_sessions = Store.load_signal_sessions(store)

    assert persisted.signal.identity_key == bob_identity
    assert SessionStore.has_session?(persisted_sessions, alice_jid)
    refute Map.has_key?(persisted.signal.prekeys, prekey_id)

    assert {:error, :message_key_not_found} =
             Encryption.decrypt_from_sender_sync(
               store,
               bob_sessions,
               alice_jid,
               ciphertext,
               "pkmsg"
             )
  end
end
