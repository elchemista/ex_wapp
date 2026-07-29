defmodule ExWapp.SignalSenderKeyTest do
  use ExUnit.Case, async: true

  import Bitwise

  alias ExWapp.Binary
  alias ExWapp.Binary.Node
  alias ExWapp.MessageHandler
  alias ExWapp.Signal.{Encryption, Keys, SenderKey, SessionStore, WireFormat}

  test "processes sender key distribution and decrypts skmsg" do
    store = ExWapp.Store.Memory.new(initial_data: %{signal: %{}})

    sender_signing = Keys.generate_key_pair()
    group_jid = "120363043214477337@g.us"
    sender_jid = "199316597694686@lid"
    sender_key_id = 77
    chain_key = :crypto.strong_rand_bytes(32)

    distribution_payload =
      build_sender_key_distribution_message_payload(
        group_jid,
        sender_key_id,
        0,
        chain_key,
        sender_signing.public
      )

    assert {:ok, 1} =
             SenderKey.process_distributions_from_plaintext(
               store,
               group_jid,
               sender_jid,
               distribution_payload
             )

    first_plaintext = "first group message"

    first_skmsg =
      build_sender_key_message(
        sender_key_id,
        0,
        chain_key,
        sender_signing.private,
        first_plaintext
      )

    assert {:ok, ^first_plaintext} =
             SenderKey.decrypt_group_message(store, group_jid, sender_jid, first_skmsg)

    second_plaintext = "second group message"

    second_skmsg =
      build_sender_key_message(
        sender_key_id,
        1,
        chain_key,
        sender_signing.private,
        second_plaintext
      )

    assert {:ok, ^second_plaintext} =
             SenderKey.decrypt_group_message(store, group_jid, sender_jid, second_skmsg)
  end

  test "creates outbound sender key distribution and encrypts skmsg" do
    sender_store = ExWapp.Store.Memory.new(initial_data: %{signal: %{}})
    receiver_store = ExWapp.Store.Memory.new(initial_data: %{signal: %{}})

    group_jid = "120363043214477337@g.us"
    sender_jid = "199316597694686@lid"

    assert {:ok, distribution_payload} =
             SenderKey.create_outbound_distribution_message(sender_store, group_jid, sender_jid)

    assert {:ok, 1} =
             SenderKey.process_distributions_from_plaintext(
               receiver_store,
               group_jid,
               sender_jid,
               distribution_payload
             )

    first_plaintext = "outbound sender key message"

    assert {:ok, first_skmsg} =
             SenderKey.encrypt_outbound_group_message(
               sender_store,
               group_jid,
               sender_jid,
               first_plaintext
             )

    assert {:ok, ^first_plaintext} =
             SenderKey.decrypt_group_message(receiver_store, group_jid, sender_jid, first_skmsg)

    second_plaintext = "outbound sender key message 2"

    assert {:ok, second_skmsg} =
             SenderKey.encrypt_outbound_group_message(
               sender_store,
               group_jid,
               sender_jid,
               second_plaintext
             )

    assert {:ok, ^second_plaintext} =
             SenderKey.decrypt_group_message(receiver_store, group_jid, sender_jid, second_skmsg)
  end

  test "a distribution from the account's own primary device does not rotate the outbound key" do
    # The local outbound record is keyed by the device-stripped account JID,
    # and the primary phone is device 0 — whose JID renders with no device
    # suffix, i.e. the exact same key. Its sender-key distribution (and the
    # decrypt write-backs that follow) must coexist with our outbound state
    # rather than steal the record's current pointer: losing the pointer
    # orphans our signing key and forces a full sender-key rotation on every
    # group send that follows a phone message.
    store = ExWapp.Store.Memory.new(initial_data: %{signal: %{}})
    group_jid = "120363043214477337@g.us"
    local_jid = "199316597694686@lid"

    assert {:ok, distribution_before} =
             SenderKey.create_outbound_distribution_message(store, group_jid, local_jid)

    phone_signing = Keys.generate_key_pair()
    phone_chain_key = :crypto.strong_rand_bytes(32)

    phone_payload =
      build_sender_key_distribution_message_payload(
        group_jid,
        91,
        0,
        phone_chain_key,
        phone_signing.public
      )

    assert {:ok, 1} =
             SenderKey.process_distributions_from_plaintext(
               store,
               group_jid,
               local_jid,
               phone_payload
             )

    # The phone's own messages decrypt through the shared record...
    phone_skmsg =
      build_sender_key_message(91, 0, phone_chain_key, phone_signing.private, "from the phone")

    assert {:ok, "from the phone"} =
             SenderKey.decrypt_group_message(store, group_jid, local_jid, phone_skmsg)

    # ...and our outbound key survives both writes unchanged.
    assert {:ok, distribution_after} =
             SenderKey.create_outbound_distribution_message(store, group_jid, local_jid)

    assert distribution_after == distribution_before
  end

  test "serializes concurrent outbound sender-key encryption" do
    sender_store = ExWapp.Store.Memory.new(initial_data: %{signal: %{}})
    receiver_store = ExWapp.Store.Memory.new(initial_data: %{signal: %{}})
    group_jid = "120363043214477338@g.us"
    sender_jid = "199316597694687@lid"
    message_count = 48

    assert {:ok, distribution_payload} =
             SenderKey.create_outbound_distribution_message(sender_store, group_jid, sender_jid)

    assert {:ok, 1} =
             SenderKey.process_distributions_from_plaintext(
               receiver_store,
               group_jid,
               sender_jid,
               distribution_payload
             )

    results =
      1..message_count
      |> Enum.map(fn index ->
        fn ->
          plaintext = "concurrent-group-#{index}"

          {:ok, ciphertext} =
            SenderKey.encrypt_outbound_group_message(
              sender_store,
              group_jid,
              sender_jid,
              plaintext
            )

          {plaintext, ciphertext}
        end
      end)
      |> run_concurrently()

    sender_data = ExWapp.Store.load!(sender_store)
    sender_record = get_in(sender_data, [:signal, :sender_keys, {group_jid, sender_jid}])
    sender_state = get_in(sender_record, [:states, sender_record.current_id])
    assert sender_state.iteration == message_count

    Enum.each(results, fn {plaintext, ciphertext} ->
      assert {:ok, ^plaintext} =
               SenderKey.decrypt_group_message(
                 receiver_store,
                 group_jid,
                 sender_jid,
                 ciphertext
               )
    end)
  end

  test "simulated outbound chain yields pkmsg distribution and signed skmsg" do
    sender_identity = Keys.generate_key_pair()
    receiver_identity = Keys.generate_key_pair()

    signed_id = 880
    prekey_id = 881

    receiver_signed_prekey = Keys.generate_signed_prekey(receiver_identity, signed_id)
    receiver_one_time_prekey = Keys.generate_prekey(prekey_id)

    receiver_bundle = %{
      registration_id: 5544,
      identity_key: receiver_identity.public,
      signed_prekey: %{
        id: signed_id,
        public: receiver_signed_prekey.public,
        signature: receiver_signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: receiver_one_time_prekey.public}
    }

    receiver_local_prekeys = %{
      signed_prekeys: %{signed_id => receiver_signed_prekey},
      prekeys: %{prekey_id => receiver_one_time_prekey}
    }

    sender_store = ExWapp.Store.Memory.new(initial_data: %{signal: %{}})
    receiver_store = ExWapp.Store.Memory.new(initial_data: %{signal: %{}})

    group_jid = "120363043214477337@g.us"
    sender_jid = "199316597694686@lid"
    receiver_jid = "19995550202@lid"

    assert {:ok, distribution_payload} =
             SenderKey.create_outbound_distribution_message(sender_store, group_jid, sender_jid)

    assert {:ok, distribution_pkmsg, :prekey, sender_signal_sessions} =
             SessionStore.encrypt_message(
               SessionStore.new(),
               receiver_jid,
               Encryption.pad_message(distribution_payload),
               sender_identity,
               4433,
               receiver_bundle
             )

    assert {:ok, parsed_pkmsg} = WireFormat.parse_prekey_signal_message(distribution_pkmsg)
    assert parsed_pkmsg.prekey_id == prekey_id
    assert parsed_pkmsg.signed_prekey_id == signed_id
    assert is_binary(parsed_pkmsg.message) and byte_size(parsed_pkmsg.message) > 0
    assert parsed_pkmsg.identity_key == sender_identity.public

    assert {:ok, decrypted_distribution_padded, receiver_signal_sessions} =
             SessionStore.decrypt_message(
               SessionStore.new(),
               sender_jid,
               distribution_pkmsg,
               true,
               receiver_identity,
               receiver_local_prekeys
             )

    assert Encryption.unpad_message(decrypted_distribution_padded) == distribution_payload

    assert {:ok, 1} =
             SenderKey.process_distributions_from_plaintext(
               receiver_store,
               group_jid,
               sender_jid,
               distribution_payload
             )

    assert SessionStore.has_session?(sender_signal_sessions, receiver_jid)
    assert SessionStore.has_session?(receiver_signal_sessions, sender_jid)

    group_plaintext = "chain check group payload"

    assert {:ok, skmsg_ciphertext} =
             SenderKey.encrypt_outbound_group_message(
               sender_store,
               group_jid,
               sender_jid,
               group_plaintext
             )

    <<skmsg_version, _::binary>> = skmsg_ciphertext
    assert skmsg_version >>> 4 == 3

    assert {:ok, ^group_plaintext} =
             SenderKey.decrypt_group_message(
               receiver_store,
               group_jid,
               sender_jid,
               skmsg_ciphertext
             )

    sig_size = byte_size(skmsg_ciphertext) - 1
    <<sig_prefix::binary-size(^sig_size), sig_last::unsigned-integer-size(8)>> = skmsg_ciphertext
    tampered_signature = sig_prefix <> <<bxor(sig_last, 0x01)>>

    assert {:error, :invalid_sender_key_signature} =
             SenderKey.decrypt_group_message(
               receiver_store,
               group_jid,
               sender_jid,
               tampered_signature
             )
  end

  test "message handler uses sender key from pkmsg distribution to decrypt group skmsg" do
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
            registration_id: 9900,
            signed_prekeys: %{signed_id => bob_signed_prekey},
            prekeys: %{prekey_id => bob_one_time_prekey}
          },
          chats: %{}
        }
      )

    bob_bundle = %{
      registration_id: 9900,
      identity_key: bob_identity.public,
      signed_prekey: %{
        id: signed_id,
        public: bob_signed_prekey.public,
        signature: bob_signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: bob_one_time_prekey.public}
    }

    group_jid = "120363043214477337@g.us"
    sender_jid = "199316597694686@lid"

    sender_signing = Keys.generate_key_pair()
    sender_key_id = 15
    sender_chain_key = :crypto.strong_rand_bytes(32)

    distribution_payload =
      build_sender_key_distribution_message_payload(
        group_jid,
        sender_key_id,
        0,
        sender_chain_key,
        sender_signing.public
      )

    {:ok, distribution_ciphertext, :prekey, _alice_sessions} =
      SessionStore.encrypt_message(
        SessionStore.new(),
        sender_jid,
        Encryption.pad_message(distribution_payload),
        alice_identity,
        3344,
        bob_bundle
      )

    distribution_node = %Node{
      tag: "message",
      attrs: %{
        "from" => group_jid,
        "participant" => sender_jid,
        "id" => "SKDM_1",
        "type" => "text",
        "t" => "1730000200"
      },
      content: [
        %Node{
          tag: "enc",
          attrs: %{"type" => "pkmsg", "v" => "2"},
          content: Binary.raw(distribution_ciphertext)
        }
      ]
    }

    initial_state = %{
      store: bob_store,
      signal_sessions: SessionStore.new(),
      stats: %{messages_received: 0}
    }

    assert {:ok, state_after_distribution, distribution_actions} =
             MessageHandler.handle_node(distribution_node, self(), initial_state)

    assert [] == ExWapp.Chat.messages(bob_store, group_jid, limit: 1)

    assert Enum.any?(distribution_actions, fn {action, _, _, _, _, _} ->
             action == :send_receipt
           end)

    text_payload =
      ExWapp.Messages.build_text_proto("group message works", [])
      |> WAWebProtobufsE2E.Message.encode!()
      |> IO.iodata_to_binary()

    skmsg_ciphertext =
      build_sender_key_message(
        sender_key_id,
        0,
        sender_chain_key,
        sender_signing.private,
        Encryption.pad_message(text_payload)
      )

    skmsg_node = %Node{
      tag: "message",
      attrs: %{
        "from" => group_jid,
        "participant" => sender_jid,
        "id" => "SKMSG_1",
        "type" => "text",
        "t" => "1730000201"
      },
      content: [
        %Node{
          tag: "enc",
          attrs: %{"type" => "skmsg", "v" => "2"},
          content: Binary.raw(skmsg_ciphertext)
        }
      ]
    }

    assert {:ok, _state_after_skmsg, skmsg_actions} =
             MessageHandler.handle_node(skmsg_node, self(), state_after_distribution)

    [message | _] = ExWapp.Chat.messages(bob_store, group_jid, limit: 1)
    assert message.id == "SKMSG_1"
    assert message.text == "group message works"

    refute Enum.any?(skmsg_actions, fn
             {:send_retry_receipt, _, _, _, _, _, _, _} -> true
             _ -> false
           end)
  end

  test "decrypts out-of-order messages once and rejects a replay" do
    fixture = receiver_with_distribution(301)

    messages =
      for {iteration, plaintext} <- [{0, "zero"}, {1, "one"}, {2, "two"}], into: %{} do
        ciphertext =
          build_sender_key_message(
            fixture.key_id,
            iteration,
            fixture.chain_key,
            fixture.signing.private,
            plaintext
          )

        {iteration, {plaintext, ciphertext}}
      end

    {plaintext_2, ciphertext_2} = messages[2]
    {plaintext_0, ciphertext_0} = messages[0]
    {plaintext_1, ciphertext_1} = messages[1]

    assert {:ok, ^plaintext_2} =
             SenderKey.decrypt_group_message(
               fixture.store,
               fixture.group_jid,
               fixture.sender_jid,
               ciphertext_2
             )

    assert {:ok, ^plaintext_0} =
             SenderKey.decrypt_group_message(
               fixture.store,
               fixture.group_jid,
               fixture.sender_jid,
               ciphertext_0
             )

    assert {:ok, ^plaintext_1} =
             SenderKey.decrypt_group_message(
               fixture.store,
               fixture.group_jid,
               fixture.sender_jid,
               ciphertext_1
             )

    assert {:error, :old_sender_key_iteration} =
             SenderKey.decrypt_group_message(
               fixture.store,
               fixture.group_jid,
               fixture.sender_jid,
               ciphertext_0
             )
  end

  test "rejects sender-key iterations too far into the future" do
    fixture = receiver_with_distribution(302)

    ciphertext =
      build_sender_key_message(
        fixture.key_id,
        2_001,
        fixture.chain_key,
        fixture.signing.private,
        "too far"
      )

    assert {:error, :sender_key_iteration_too_far_into_future} =
             SenderKey.decrypt_group_message(
               fixture.store,
               fixture.group_jid,
               fixture.sender_jid,
               ciphertext
             )
  end

  test "reports an unknown sender-key id without mutating the active state" do
    fixture = receiver_with_distribution(303)

    ciphertext =
      build_sender_key_message(
        fixture.key_id + 1,
        0,
        fixture.chain_key,
        fixture.signing.private,
        "wrong id"
      )

    assert {:error, {:unknown_sender_key_id, 304}} =
             SenderKey.decrypt_group_message(
               fixture.store,
               fixture.group_jid,
               fixture.sender_jid,
               ciphertext
             )

    data = ExWapp.Store.load!(fixture.store)

    assert get_in(data, [
             :signal,
             :sender_keys,
             {fixture.group_jid, fixture.sender_jid},
             :current_id
           ]) == fixture.key_id
  end

  test "distinguishes malformed and unsupported sender-key messages" do
    fixture = receiver_with_distribution(305)

    assert {:error, :invalid_sender_key_message} =
             SenderKey.decrypt_group_message(
               fixture.store,
               fixture.group_jid,
               fixture.sender_jid,
               <<1, 2, 3>>
             )

    valid =
      build_sender_key_message(
        fixture.key_id,
        0,
        fixture.chain_key,
        fixture.signing.private,
        "version"
      )

    <<_version, rest::binary>> = valid
    unsupported = <<0x23, rest::binary>>

    assert {:error, {:unsupported_sender_key_message_version, 2}} =
             SenderKey.decrypt_group_message(
               fixture.store,
               fixture.group_jid,
               fixture.sender_jid,
               unsupported
             )
  end

  test "retains only the five newest sender-key states" do
    store = ExWapp.Store.Memory.new(initial_data: %{signal: %{}})
    signing = Keys.generate_key_pair()
    group_jid = "120363043214477337@g.us"
    sender_jid = "199316597694686@lid"

    for key_id <- 1..6 do
      payload =
        build_sender_key_distribution_message_payload(
          group_jid,
          key_id,
          0,
          :crypto.hash(:sha256, <<key_id>>),
          signing.public
        )

      assert {:ok, 1} =
               SenderKey.process_distributions_from_plaintext(
                 store,
                 group_jid,
                 sender_jid,
                 payload
               )
    end

    data = ExWapp.Store.load!(store)
    record = get_in(data, [:signal, :sender_keys, {group_jid, sender_jid}])

    assert record.current_id == 6
    assert record.state_ids == [6, 5, 4, 3, 2]
    assert record.states |> Map.keys() |> Enum.sort() == [2, 3, 4, 5, 6]
  end

  defp receiver_with_distribution(key_id) do
    store = ExWapp.Store.Memory.new(initial_data: %{signal: %{}})
    signing = Keys.generate_key_pair()
    group_jid = "120363043214477337@g.us"
    sender_jid = "199316597694686@lid"
    chain_key = :crypto.strong_rand_bytes(32)

    payload =
      build_sender_key_distribution_message_payload(
        group_jid,
        key_id,
        0,
        chain_key,
        signing.public
      )

    {:ok, 1} =
      SenderKey.process_distributions_from_plaintext(
        store,
        group_jid,
        sender_jid,
        payload
      )

    %{
      store: store,
      signing: signing,
      group_jid: group_jid,
      sender_jid: sender_jid,
      key_id: key_id,
      chain_key: chain_key
    }
  end

  defp build_sender_key_distribution_message_payload(
         group_jid,
         sender_key_id,
         iteration,
         chain_key,
         signing_public
       ) do
    signing_key = WireFormat.serialize_public_key(signing_public)

    axolotl_distribution =
      <<0x33>> <>
        encode_uint_field(1, sender_key_id) <>
        encode_uint_field(2, iteration) <>
        encode_bytes_field(3, chain_key) <>
        encode_bytes_field(4, signing_key)

    sender_key_distribution =
      encode_bytes_field(1, group_jid) <>
        encode_bytes_field(2, axolotl_distribution)

    # WA E2E Message field 2: senderKeyDistributionMessage
    encode_bytes_field(2, sender_key_distribution)
  end

  defp build_sender_key_message(sender_key_id, iteration, chain_key, signing_private, plaintext) do
    message_keys = derive_sender_message_keys(chain_key, iteration)
    ciphertext = WireFormat.encrypt_aes_cbc(plaintext, message_keys.cipher_key, message_keys.iv)

    version_and_proto =
      <<0x33>> <>
        encode_uint_field(1, sender_key_id) <>
        encode_uint_field(2, iteration) <>
        encode_bytes_field(3, ciphertext)

    signature = Keys.sign_message(signing_private, version_and_proto)
    version_and_proto <> signature
  end

  defp derive_sender_message_keys(chain_key, iteration) do
    chain_key = advance_sender_chain_key(chain_key, iteration)
    seed = :crypto.mac(:hmac, :sha256, chain_key, <<0x01>>)

    prk = :crypto.mac(:hmac, :sha256, :binary.copy(<<0>>, 32), seed)
    t1 = :crypto.mac(:hmac, :sha256, prk, "WhisperGroup" <> <<1>>)
    t2 = :crypto.mac(:hmac, :sha256, prk, t1 <> "WhisperGroup" <> <<2>>)

    <<iv::binary-size(16), cipher_key::binary-size(32), _::binary>> = t1 <> t2

    %{
      iv: iv,
      cipher_key: cipher_key
    }
  end

  defp advance_sender_chain_key(chain_key, 0), do: chain_key

  defp advance_sender_chain_key(chain_key, iteration)
       when is_integer(iteration) and iteration > 0 do
    next_chain_key = :crypto.mac(:hmac, :sha256, chain_key, <<0x02>>)
    advance_sender_chain_key(next_chain_key, iteration - 1)
  end

  defp encode_uint_field(field_num, value) when is_integer(value) and value >= 0 do
    tag = bor(field_num <<< 3, 0)
    WireFormat.encode_varint(tag) <> WireFormat.encode_varint(value)
  end

  defp encode_bytes_field(field_num, value) when is_binary(value) do
    tag = bor(field_num <<< 3, 2)
    WireFormat.encode_varint(tag) <> WireFormat.encode_varint(byte_size(value)) <> value
  end

  defp run_concurrently(functions) do
    owner = self()
    gate = make_ref()

    tasks =
      Enum.map(functions, fn fun ->
        Task.async(fn ->
          send(owner, {:sender_key_test_ready, gate, self()})

          receive do
            {:sender_key_test_go, ^gate} -> fun.()
          end
        end)
      end)

    task_pids =
      Enum.map(tasks, fn _task ->
        receive do
          {:sender_key_test_ready, ^gate, task_pid} -> task_pid
        end
      end)

    Enum.each(task_pids, &send(&1, {:sender_key_test_go, gate}))
    Task.await_many(tasks, 30_000)
  end
end
