defmodule ExWapp.SignalSessionStoreTest do
  use ExUnit.Case, async: true

  alias ExWapp.Signal.{Keys, SessionStore}

  test "encrypt_message wraps as prekey when base_key is provided for an already-created session" do
    local_identity = Keys.generate_key_pair()
    remote_identity = Keys.generate_key_pair()

    signed_id = 51
    prekey_id = 77

    signed_prekey = Keys.generate_signed_prekey(remote_identity, signed_id)
    one_time_prekey = Keys.generate_prekey(prekey_id)

    bundle = %{
      registration_id: 1234,
      identity_key: remote_identity.public,
      signed_prekey: %{
        id: signed_id,
        public: signed_prekey.public,
        signature: signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: one_time_prekey.public}
    }

    jid = "111222333@s.whatsapp.net"

    {:ok, _session, base_key, store_after_create} =
      SessionStore.get_or_create_session(SessionStore.new(), jid, local_identity, bundle, 99)

    assert is_binary(base_key)
    assert byte_size(base_key) == 32

    {:ok, _ciphertext, type, _store_after_encrypt} =
      SessionStore.encrypt_message(
        store_after_create,
        jid,
        "hello",
        local_identity,
        99,
        Map.put(bundle, :base_key, base_key)
      )

    assert type == :prekey
  end

  test "get_or_create_session with force recreates an existing session and returns a new base key" do
    local_identity = Keys.generate_key_pair()
    remote_identity = Keys.generate_key_pair()

    signed_id = 52
    prekey_id = 78

    signed_prekey = Keys.generate_signed_prekey(remote_identity, signed_id)
    one_time_prekey = Keys.generate_prekey(prekey_id)

    bundle = %{
      registration_id: 1235,
      identity_key: remote_identity.public,
      signed_prekey: %{
        id: signed_id,
        public: signed_prekey.public,
        signature: signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: one_time_prekey.public}
    }

    jid = "111222334@s.whatsapp.net"

    {:ok, first_session, first_base_key, store_after_first} =
      SessionStore.get_or_create_session(SessionStore.new(), jid, local_identity, bundle, 99)

    assert is_binary(first_base_key)

    {:ok, reused_session, nil, _store_after_reuse} =
      SessionStore.get_or_create_session(store_after_first, jid, local_identity, bundle, 99)

    assert reused_session == first_session

    {:ok, forced_session, forced_base_key, _store_after_force} =
      SessionStore.get_or_create_session(
        store_after_first,
        jid,
        local_identity,
        bundle,
        99,
        force: true
      )

    assert is_binary(forced_base_key)
    assert byte_size(forced_base_key) == 32
    refute forced_session == first_session
    refute forced_base_key == first_base_key
  end

  test "prekey message decrypts and follow-up whisper decrypts" do
    alice_identity = Keys.generate_key_pair()
    bob_identity = Keys.generate_key_pair()

    signed_id = 90
    prekey_id = 120

    bob_signed_prekey = Keys.generate_signed_prekey(bob_identity, signed_id)
    bob_one_time_prekey = Keys.generate_prekey(prekey_id)

    bob_bundle = %{
      registration_id: 4321,
      identity_key: bob_identity.public,
      signed_prekey: %{
        id: signed_id,
        public: bob_signed_prekey.public,
        signature: bob_signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: bob_one_time_prekey.public}
    }

    alice_store0 = SessionStore.new()
    bob_store0 = SessionStore.new()

    bob_jid = "999888777@s.whatsapp.net"
    alice_jid = "444555666@s.whatsapp.net"

    {:ok, first_ciphertext, :prekey, alice_store1} =
      SessionStore.encrypt_message(
        alice_store0,
        bob_jid,
        "first",
        alice_identity,
        1001,
        bob_bundle
      )

    bob_local_prekeys = %{
      signed_prekeys: %{signed_id => bob_signed_prekey},
      prekeys: %{prekey_id => bob_one_time_prekey}
    }

    {:ok, "first", bob_store1} =
      SessionStore.decrypt_message(
        bob_store0,
        alice_jid,
        first_ciphertext,
        true,
        bob_identity,
        bob_local_prekeys
      )

    {:ok, second_ciphertext, :whisper, _alice_store2} =
      SessionStore.encrypt_message(alice_store1, bob_jid, "second", alice_identity, 1001, %{})

    {:ok, "second", _bob_store2} =
      SessionStore.decrypt_message(
        bob_store1,
        alice_jid,
        second_ciphertext,
        false,
        bob_identity,
        bob_local_prekeys
      )
  end

  test "stores sessions per device JID without collapsing device suffixes" do
    store =
      SessionStore.new()
      |> SessionStore.put_session("111222333:1@s.whatsapp.net", %{id: 1})
      |> SessionStore.put_session("111222333:2@s.whatsapp.net", %{id: 2})

    assert SessionStore.has_session?(store, "111222333:1@s.whatsapp.net")
    assert SessionStore.has_session?(store, "111222333:2@s.whatsapp.net")
    refute SessionStore.has_session?(store, "111222333:3@s.whatsapp.net")

    assert {:ok, %{id: 1}} = SessionStore.get_session(store, "111222333:1@s.whatsapp.net")
    assert {:ok, %{id: 2}} = SessionStore.get_session(store, "111222333:2@s.whatsapp.net")
  end

  test "repeated prekey wrappers reuse existing session and keep reply decryptable" do
    alice_identity = Keys.generate_key_pair()
    bob_identity = Keys.generate_key_pair()

    signed_id = 91
    prekey_id = 121

    bob_signed_prekey = Keys.generate_signed_prekey(bob_identity, signed_id)
    bob_one_time_prekey = Keys.generate_prekey(prekey_id)

    bob_bundle = %{
      registration_id: 4322,
      identity_key: bob_identity.public,
      signed_prekey: %{
        id: signed_id,
        public: bob_signed_prekey.public,
        signature: bob_signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: bob_one_time_prekey.public}
    }

    alice_jid = "444555667@s.whatsapp.net"
    bob_jid = "999888778@s.whatsapp.net"

    bob_local_prekeys = %{
      signed_prekeys: %{signed_id => bob_signed_prekey},
      prekeys: %{prekey_id => bob_one_time_prekey}
    }

    {:ok, _alice_session, base_key, alice_store0} =
      SessionStore.get_or_create_session(
        SessionStore.new(),
        bob_jid,
        alice_identity,
        bob_bundle,
        1002
      )

    bundle_with_base = Map.put(bob_bundle, :base_key, base_key)

    {:ok, first_ciphertext, :prekey, alice_store1} =
      SessionStore.encrypt_message(
        alice_store0,
        bob_jid,
        "first-prekey",
        alice_identity,
        1002,
        bundle_with_base
      )

    {:ok, second_ciphertext, :prekey, alice_store2} =
      SessionStore.encrypt_message(
        alice_store1,
        bob_jid,
        "second-prekey",
        alice_identity,
        1002,
        bundle_with_base
      )

    {:ok, third_ciphertext, :prekey, alice_store3} =
      SessionStore.encrypt_message(
        alice_store2,
        bob_jid,
        "third-prekey",
        alice_identity,
        1002,
        bundle_with_base
      )

    {:ok, "first-prekey", bob_store1} =
      SessionStore.decrypt_message(
        SessionStore.new(),
        alice_jid,
        first_ciphertext,
        true,
        bob_identity,
        bob_local_prekeys
      )

    {:ok, "second-prekey", bob_store2} =
      SessionStore.decrypt_message(
        bob_store1,
        alice_jid,
        second_ciphertext,
        true,
        bob_identity,
        bob_local_prekeys
      )

    {:ok, "third-prekey", bob_store3} =
      SessionStore.decrypt_message(
        bob_store2,
        alice_jid,
        third_ciphertext,
        true,
        bob_identity,
        bob_local_prekeys
      )

    {:ok, reply_ciphertext, :whisper, _bob_store4} =
      SessionStore.encrypt_message(
        bob_store3,
        alice_jid,
        "reply-whisper",
        bob_identity,
        2003,
        %{}
      )

    {:ok, "reply-whisper", _alice_store4} =
      SessionStore.decrypt_message(
        alice_store3,
        bob_jid,
        reply_ciphertext,
        false,
        alice_identity,
        %{signed_prekeys: %{}, prekeys: %{}}
      )
  end
end
