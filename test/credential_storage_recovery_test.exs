defmodule ExWapp.CredentialStorageRecoveryTest do
  use ExUnit.Case, async: true
  alias ExWapp.{Binary, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Signal.{Encryption, SessionStore}
  alias ExWapp.Session.Account
  alias ExWapp.Session.Worker.ReceiptBuilder
  alias ExWapp.Test.{FaultStore, SignalDevice}

  setup do
    local = SignalDevice.new()
    peer = SignalDevice.new()

    store =
      FaultStore.new(
        initial_data: %{
          pairing: %{device_identity: "legacy signed identity"},
          signal:
            Map.merge(local.local_prekeys, %{identity_key: local.identity, registration_id: 123})
        }
      )

    {:ok, ciphertext, :prekey, _} =
      SessionStore.encrypt_message(
        SessionStore.new(),
        "123@s.whatsapp.net",
        "recoverable plaintext",
        peer.identity,
        456,
        local.bundle
      )

    %{store: store, local: local, peer: peer, ciphertext: ciphertext}
  end

  test "failed session persistence retains the one-time key needed after a restart", ctx do
    before = Store.get(ctx.store, :signal)
    FaultStore.arm(ctx.store, :persist, {:return, {:error, :disk_full}})

    assert {:ok, "recoverable plaintext", _} =
             Encryption.decrypt_from_sender_sync(
               ctx.store,
               SessionStore.new(),
               "456@s.whatsapp.net",
               ctx.ciphertext,
               :pkmsg
             )

    assert Store.get(ctx.store, :signal) == before
    assert Store.get(ctx.store, :signal_sessions) == nil

    assert {:ok, "recoverable plaintext", _} =
             Encryption.decrypt_from_sender_sync(
               ctx.store,
               SessionStore.new(),
               "456@s.whatsapp.net",
               ctx.ciphertext,
               :prekey
             )

    refute Map.has_key?(Store.get(ctx.store, :signal).prekeys, ctx.local.prekey.id)
    assert Store.get(ctx.store, :signal_sessions) != nil
  end

  test "prekey deletion failures retain private material while preserving the advanced ratchet",
       ctx do
    for action <- [:raise, {:return, {:error, :disk_full}}] do
      FaultStore.arm(ctx.store, :get_and_update, action)

      assert {:ok, "recoverable plaintext", sessions} =
               Encryption.decrypt_from_sender_sync(
                 ctx.store,
                 SessionStore.new(),
                 "456@s.whatsapp.net",
                 ctx.ciphertext,
                 3
               )

      assert Map.has_key?(Store.get(ctx.store, :signal).prekeys, ctx.local.prekey.id)
      assert SessionStore.has_session?(sessions, "456@s.whatsapp.net")
      assert Store.get(ctx.store, :signal_sessions) != nil
    end
  end

  test "retry receipts do not advertise keys whose reservation or flush failed", ctx do
    receipt = %{to: "456@s.whatsapp.net", id: "retry", retry_count: 2, message_t: 1_700_000_000}

    for {callback, action} <- [
          {:get_and_update, {:return, {:error, :disk_full}}},
          {:get_and_update, {:return, :invalid_reply}},
          {:get_and_update, :raise},
          {:flush, {:return, {:error, :disk_full}}}
        ] do
      FaultStore.arm(ctx.store, callback, action)
      node = ReceiptBuilder.build_retry_receipt_ack(ctx.store, receipt)
      assert {:ok, decoded} = Binary.decode(Binary.encode!(node))
      assert Enum.map(decoded.content, & &1.tag) == ["retry", "registration"]
      assert hd(decoded.content).attrs["t"] == "1700000000"
    end

    node = ReceiptBuilder.build_retry_receipt_ack(ctx.store, receipt)
    assert %Node{tag: "keys", content: children} = List.last(node.content)
    key = Enum.find(children, &(&1.tag == "key"))
    <<id::24>> = hd(key.content).content.data
    assert Store.get(ctx.store, :signal).prekeys[id].public == List.last(key.content).content.data
  end

  test "missing and malformed credentials produce plain retries without a partial key bundle",
       ctx do
    for signal <- [
          %{},
          %{identity_key: ctx.local.identity},
          %{
            identity_key: ctx.local.identity,
            signed_prekeys: %{1 => %{public: <<1>>, signature: <<2>>}}
          }
        ] do
      Store.put(ctx.store, :signal, signal)

      node =
        ReceiptBuilder.build_retry_receipt_ack(ctx.store, %{
          to: "456@s.whatsapp.net",
          id: "retry",
          retry_count: 2
        })

      refute Enum.any?(node.content, &(&1.tag == "keys"))
    end

    node =
      ReceiptBuilder.build_retry_receipt_ack(nil, %{
        to: "456@s.whatsapp.net",
        id: "retry",
        retry_count: 2
      })

    assert [%Node{tag: "retry"}] = node.content

    assert {:error, :no_identity_key} =
             Encryption.encrypt_for_recipient_sync(
               Store.Memory.new(),
               nil,
               "456@s.whatsapp.net",
               "message"
             )
  end

  test "account lookups tolerate adapter failures without fabricating an identity", ctx do
    for {fun, args, expected} <- [
          {:local_registration_node, [], nil},
          {:load_lid_mapping, [], %{}},
          {:local_account_device_id, [], 0},
          {:local_account_lid_jid, [], ""},
          {:local_account_chatstate_jid, ["456@lid"], ""}
        ] do
      FaultStore.arm(ctx.store, :load, :raise)
      assert apply(Account, fun, [ctx.store | args]) == expected
    end

    FaultStore.arm(ctx.store, :load, :raise)
    assert Account.maybe_append_tctoken([], "456@s.whatsapp.net", ctx.store) == []
    Store.put(ctx.store, :pairing, %{adv_device_identity: "legacy identity"})

    assert {:ok, %Node{content: %Binary.Raw{data: "legacy identity"}}} =
             Account.get_device_identity_node(ctx.store)

    {:ok, jid} = ExWapp.JID.parse("123:7@s.whatsapp.net")
    Store.put(ctx.store, :client_info, %{jid: jid})
    assert Account.local_account_device_id(ctx.store) == 7
  end
end
