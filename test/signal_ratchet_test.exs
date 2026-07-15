defmodule ExWapp.SignalRatchetTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Signal.Keys
  alias ExWapp.Signal.Session
  alias ExWapp.Signal.SessionStore

  test "decrypts out-of-order messages once and rejects a replay" do
    %{alice: alice, bob: bob} = open_pair("opening")

    {:ok, message_one, alice} = Session.encrypt(alice, "one")
    {:ok, message_two, _alice} = Session.encrypt(alice, "two")

    assert {:ok, "two", bob} = Session.decrypt(bob, message_two)
    assert {:ok, "one", bob} = Session.decrypt(bob, message_one)
    assert {:error, :message_key_not_found} = Session.decrypt(bob, message_one)
  end

  test "decrypts a delayed message from the receiving chain before a DH ratchet" do
    %{alice: alice, bob: bob} = open_pair("opening")

    {:ok, delayed_old_chain, alice} = Session.encrypt(alice, "delayed-old-chain")
    {:ok, bob_reply, bob} = Session.encrypt(bob, "bob-ratchets")
    assert {:ok, "bob-ratchets", alice} = Session.decrypt(alice, bob_reply)

    {:ok, new_chain_message, _alice} = Session.encrypt(alice, "new-chain")
    assert {:ok, "new-chain", bob} = Session.decrypt(bob, new_chain_message)

    assert {:ok, "delayed-old-chain", bob} = Session.decrypt(bob, delayed_old_chain)
    assert bob.receiving_chains == %{}
  end

  test "retains a previous base-key session for delayed whisper messages" do
    alice_identity = Keys.generate_key_pair()
    bob_identity = Keys.generate_key_pair()
    signed_prekey = Keys.generate_signed_prekey(bob_identity, 71)
    prekey_one = Keys.generate_prekey(81)
    prekey_two = Keys.generate_prekey(82)

    bundle_one = bundle(bob_identity, signed_prekey, prekey_one)
    bundle_two = bundle(bob_identity, signed_prekey, prekey_two)
    local_prekeys = local_prekeys(signed_prekey, [prekey_one, prekey_two])

    {:ok, old_alice, old_base_key} = Session.create_session(alice_identity, bundle_one)

    {:ok, opening_old, old_alice} =
      Session.encrypt_prekey_message(
        old_alice,
        "old-opening",
        prekey_bundle_info(bundle_one, old_base_key)
      )

    {:ok, delayed_old, _old_alice} = Session.encrypt(old_alice, "old-delayed")

    bob_store = SessionStore.new()
    alice_jid = "15550000001@s.whatsapp.net"

    assert {:ok, "old-opening", bob_store} =
             SessionStore.decrypt_message(
               bob_store,
               alice_jid,
               opening_old,
               true,
               bob_identity,
               local_prekeys
             )

    {:ok, new_alice, new_base_key} = Session.create_session(alice_identity, bundle_two)

    {:ok, opening_new, _new_alice} =
      Session.encrypt_prekey_message(
        new_alice,
        "new-opening",
        prekey_bundle_info(bundle_two, new_base_key)
      )

    assert {:ok, "new-opening", bob_store} =
             SessionStore.decrypt_message(
               bob_store,
               alice_jid,
               opening_new,
               true,
               bob_identity,
               local_prekeys
             )

    assert {:ok, current_session} = SessionStore.get_session(bob_store, alice_jid)
    assert length(current_session.previous_sessions) == 1

    assert {:ok, "old-delayed", _bob_store} =
             SessionStore.decrypt_message(
               bob_store,
               alice_jid,
               delayed_old,
               false,
               bob_identity,
               local_prekeys
             )
  end

  test "accepts 2,000 skipped messages and rejects 2,001" do
    %{alice: alice, bob: bob} = open_pair("opening")

    {message_2001, message_2002, _alice} =
      Enum.reduce(1..2002, {nil, nil, alice}, fn counter, {at_2001, at_2002, session} ->
        {:ok, ciphertext, session} = Session.encrypt(session, Integer.to_string(counter))

        {
          if(counter == 2001, do: ciphertext, else: at_2001),
          if(counter == 2002, do: ciphertext, else: at_2002),
          session
        }
      end)

    assert {:ok, "2001", _bob} = Session.decrypt(bob, message_2001)
    assert {:error, :too_many_skipped_messages} = Session.decrypt(bob, message_2002)
  end

  defp open_pair(opening_plaintext) do
    alice_identity = Keys.generate_key_pair()
    bob_identity = Keys.generate_key_pair()
    signed_prekey = Keys.generate_signed_prekey(bob_identity, 31)
    one_time_prekey = Keys.generate_prekey(41)
    bundle = bundle(bob_identity, signed_prekey, one_time_prekey)

    {:ok, alice, base_key} = Session.create_session(alice_identity, bundle)

    {:ok, opening, alice} =
      Session.encrypt_prekey_message(
        alice,
        opening_plaintext,
        prekey_bundle_info(bundle, base_key)
      )

    {:ok, ^opening_plaintext, bob} =
      Session.decrypt_prekey_message(
        opening,
        bob_identity,
        local_prekeys(signed_prekey, [one_time_prekey])
      )

    %{alice: alice, bob: bob}
  end

  defp bundle(identity, signed_prekey, one_time_prekey) do
    %{
      registration_id: 12_345,
      identity_key: identity.public,
      signed_prekey: %{
        id: signed_prekey.id,
        public: signed_prekey.public,
        signature: signed_prekey.signature
      },
      prekey: %{id: one_time_prekey.id, public: one_time_prekey.public}
    }
  end

  defp local_prekeys(signed_prekey, one_time_prekeys) do
    %{
      signed_prekeys: %{signed_prekey.id => signed_prekey},
      prekeys: Map.new(one_time_prekeys, &{&1.id, &1})
    }
  end

  defp prekey_bundle_info(bundle, base_key) do
    %{
      registration_id: bundle.registration_id,
      prekey_id: bundle.prekey.id,
      signed_prekey_id: bundle.signed_prekey.id,
      base_key: base_key
    }
  end
end
