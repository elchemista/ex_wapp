defmodule ExWapp.EncryptionAliasIntegrationTest do
  use ExUnit.Case, async: true
  alias ExWapp.{Store, JID}
  alias ExWapp.Session.Outbound.Encryptor
  alias ExWapp.Signal.{Adapter, Keys, SessionStore}
  alias ExWapp.Test.SignalDevice
  @pn "123:2@s.whatsapp.net"
  @lid "999:2@lid"

  setup do
    local = SignalDevice.new()
    peer = SignalDevice.new()

    mapping = %{
      {:pn_to_lid, "123@s.whatsapp.net"} => "999@lid",
      {:lid_to_pn, "999@lid"} => "123@s.whatsapp.net"
    }

    store =
      Store.Memory.new(
        initial_data: %{
          signal: %{identity_key: local.identity, registration_id: 42},
          lid_mapping: mapping
        }
      )

    %{store: store, local: local, peer: peer}
  end

  test "an existing PN ratchet migrates to LID without losing the recipient's ability to decrypt",
       ctx do
    {:ok, _, _, sessions} =
      SessionStore.get_or_create_session(
        SessionStore.new(),
        @pn,
        ctx.local.identity,
        ctx.peer.bundle,
        42
      )

    assert {:ok, [node], sessions, true} =
             Encryptor.encrypt_for_targets(
               ctx.store,
               sessions,
               [%{jid: @pn, payload_kind: :recipient}],
               %{recipient: "first alias payload"},
               %{}
             )

    assert node.attrs["jid"] == @pn
    assert SessionStore.has_session?(sessions, @lid)
    [enc] = node.content

    assert {:ok, "first alias payload", receiver} =
             SessionStore.decrypt_message(
               SessionStore.new(),
               "456@s.whatsapp.net",
               enc.content.data,
               true,
               ctx.peer.identity,
               ctx.peer.local_prekeys
             )

    assert {:ok, [node], sessions, true} =
             Encryptor.encrypt_for_targets(
               ctx.store,
               sessions,
               [%{jid: @pn, payload_kind: :recipient}],
               %{recipient: "second alias payload"},
               %{}
             )

    [enc] = node.content

    assert {:ok, "second alias payload", _} =
             SessionStore.decrypt_message(
               receiver,
               "456@s.whatsapp.net",
               enc.content.data,
               true,
               ctx.peer.identity,
               ctx.peer.local_prekeys
             )

    assert SessionStore.get_session(sessions, @pn) == SessionStore.get_session(sessions, @lid)
  end

  test "missing payloads and unavailable aliases return errors with the affected target", ctx do
    specs = [%{jid: @pn, payload_kind: :recipient}]

    assert {:error, {:no_encrypted_targets, [{@pn, :missing_payload}]}} =
             Encryptor.encrypt_for_targets(ctx.store, SessionStore.new(), specs, %{}, %{})

    assert {:error, {:no_encrypted_targets, [{@pn, :missing_bundle}]}} =
             Encryptor.encrypt_for_targets(
               ctx.store,
               SessionStore.new(),
               specs,
               %{recipient: "cannot encrypt"},
               %{}
             )

    assert Encryptor.missing_expected_targets(specs, []) == specs
  end

  test "retry invalidation clears PN and LID ratchets for string and parsed JID targets", ctx do
    {:ok, _, _, sessions} =
      SessionStore.get_or_create_session(
        SessionStore.new(),
        @pn,
        ctx.local.identity,
        ctx.peer.bundle,
        42
      )

    sessions = SessionStore.copy_session(sessions, @pn, @lid)
    {:ok, jid} = JID.parse(@pn)

    for target <- [@pn, jid, %{jid: jid}] do
      cleared = Encryptor.clear_sessions_for_targets(sessions, [nil, target], ctx.store)
      refute SessionStore.has_session?(cleared, @pn)
      refute SessionStore.has_session?(cleared, @lid)
    end

    assert Encryptor.clear_sessions_for_targets(nil, [@pn], ctx.store) == nil
  end

  test "legacy adapter key helpers produce verifiable signatures and interoperable prekey messages",
       ctx do
    {public, private} = Adapter.generate_key_pair()
    {signed_public, signed_private, signature} = Adapter.generate_signed_prekey(private)
    assert byte_size(signed_private) == 32
    assert Adapter.verify_signature(public, signed_public, signature)
    refute Adapter.verify_signature(public, Keys.generate_key_pair().public, signature)
    assert {:ok, session, base_key} = Adapter.create_session(ctx.local.identity, ctx.peer.bundle)

    bundle = %{
      registration_id: 42,
      prekey_id: ctx.peer.prekey.id,
      signed_prekey_id: ctx.peer.signed.id,
      base_key: base_key
    }

    assert {:ok, ciphertext, _} =
             Adapter.encrypt_prekey_message(session, "adapter message", bundle)

    assert {:ok, "adapter message", _} =
             Adapter.decrypt_prekey_message(ciphertext, ctx.peer.identity, ctx.peer.local_prekeys)

    assert Adapter.debug_message(ciphertext) == "Signal message bytes=#{byte_size(ciphertext)}"
    refute Adapter.debug_message(ciphertext) =~ "adapter message"
    assert :ok = Adapter.set_impl(:native)
    assert :ok = Adapter.set_impl(:elixir)
    assert Adapter.info().module == Adapter.impl_module()
    assert Adapter.get_impl() == :elixir
  end
end
