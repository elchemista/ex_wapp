defmodule ExWapp.StatelessPrekeyTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.Inbound.Decryptor
  alias ExWapp.Message.Handler.Wire
  alias ExWapp.Signal.{Encryption, Keys, SessionStore, WireFormat}
  alias ExWapp.Store
  alias ExWapp.Store.Memory

  @alice "15550001111:2@s.whatsapp.net"
  @bob "15550002222:3@s.whatsapp.net"
  @alias "90000000001:2@lid"

  setup do
    alice_identity = Keys.generate_key_pair()
    bob_identity = Keys.generate_key_pair()
    signed = Keys.generate_signed_prekey(bob_identity, 201)
    prekey = Keys.generate_prekey(301)

    bundle = %{
      registration_id: 4321,
      identity_key: bob_identity.public,
      signed_prekey: %{id: 201, public: signed.public, signature: signed.signature},
      prekey: %{id: 301, public: prekey.public}
    }

    store =
      Memory.new(
        initial_data: %{
          signal: %{
            identity_key: bob_identity,
            signed_prekeys: %{201 => signed},
            prekeys: %{301 => prekey}
          }
        }
      )

    on_exit(fn -> Memory.stop(store) end)
    %{identity: alice_identity, bundle: bundle, store: store}
  end

  for backend <- [:map, :ets] do
    @backend backend

    test "#{backend}: a stateless prekey decrypts and consumes its key without creating a session",
         ctx do
      sessions = new_sessions(@backend)
      {ciphertext, _alice_sessions} = encrypt(ctx, SessionStore.new(), ctx.bundle)

      assert {:ok, result, updated_state} = decrypt(ctx.store, sessions, ciphertext, "false")
      assert result.plaintext == <<10, 5, "hello">>
      assert updated_state.signal_sessions == sessions
      assert SessionStore.snapshot(sessions) == SessionStore.new()
      refute Map.has_key?(Store.load!(ctx.store).signal.prekeys, 301)
      refute SessionStore.has_session?(Store.load_signal_sessions(ctx.store), @alice)
    end

    test "#{backend}: stateless decrypt preserves an established session and pending aliases",
         ctx do
      {alice_sessions, sessions} = establish(ctx, @backend)
      before = SessionStore.snapshot(sessions)
      persisted_before = Store.load_signal_sessions(ctx.store)
      {ciphertext, _temporary_alice} = encrypt(ctx, SessionStore.new(), ctx.bundle)

      assert {:ok, _result, updated_state} = decrypt(ctx.store, sessions, ciphertext, "false")
      assert updated_state.signal_sessions == sessions
      assert SessionStore.snapshot(sessions) == before
      assert Store.load_signal_sessions(ctx.store) == persisted_before
      refute Map.has_key?(Store.load!(ctx.store).signal.prekeys, 301)

      {next_ciphertext, _alice_sessions} = encrypt(ctx, alice_sessions, %{})
      assert {:ok, result, _state} = decrypt(ctx.store, sessions, next_ciphertext, nil)
      assert result.plaintext == <<10, 5, "hello">>
    end

    test "#{backend}: a stateless prekey using the current session does not advance its ratchet",
         ctx do
      {alice_sessions, sessions} = establish(ctx, @backend)
      before = SessionStore.snapshot(sessions)
      {ciphertext, _alice_sessions} = encrypt(ctx, alice_sessions, %{})

      assert {:ok, _result, _state} = decrypt(ctx.store, sessions, ciphertext, "false")
      assert SessionStore.snapshot(sessions) == before

      # The same ciphertext still decrypts normally because the temporary
      # decrypt did not consume the established session's receiving-chain key.
      assert {:ok, _result, state} = decrypt(ctx.store, sessions, ciphertext, "true")
      refute SessionStore.snapshot(state.signal_sessions) == before
    end

    test "#{backend}: failed stateless authentication keeps sessions and one-time prekeys", ctx do
      {_alice_sessions, sessions} = establish(ctx, @backend)
      before = SessionStore.snapshot(sessions)
      persisted_before = Store.load!(ctx.store)
      {ciphertext, _temporary_alice} = encrypt(ctx, SessionStore.new(), ctx.bundle)
      corrupted = corrupt(ciphertext)

      assert {:error, message, state} = decrypt(ctx.store, sessions, corrupted, "false")

      assert {:error,
              {:decrypt_failed_for_payload, "pkmsg",
               {:decrypt_failed_for_candidate, @alice, :invalid_mac}}} = message.decrypt_status

      assert state.signal_sessions == sessions
      assert SessionStore.snapshot(sessions) == before
      assert Store.load!(ctx.store) == persisted_before
    end
  end

  test "state=false is scoped to each encrypted payload candidate", ctx do
    {ciphertext, _alice_sessions} = encrypt(ctx, SessionStore.new(), ctx.bundle)

    content = [
      %Node{tag: "enc", attrs: %{"type" => "pkmsg", "state" => "false"}, content: <<0>>},
      %Node{tag: "enc", attrs: %{"type" => "pkmsg", "v" => "2"}, content: ciphertext}
    ]

    message = Wire.extract_message_content(content, "text")
    state = %{store: ctx.store, signal_sessions: SessionStore.new()}

    assert {:ok, _result, state} = Decryptor.decrypt(message, state, @alice, nil, %{})
    assert SessionStore.has_session?(state.signal_sessions, @alice)
    assert SessionStore.has_session?(Store.load_signal_sessions(ctx.store), @alice)
  end

  test "a regular Signal message still advances its session with state=false", ctx do
    {alice_sessions, sessions} = establish(ctx, :ets)
    before = SessionStore.snapshot(sessions)
    {:ok, alice_session} = SessionStore.get_session(alice_sessions, @bob)
    {:ok, ciphertext, _alice_session} = ExWapp.Signal.Session.encrypt(alice_session, "regular")

    assert {:ok, "regular", ^sessions} =
             Encryption.decrypt_from_sender_sync(ctx.store, sessions, @alice, ciphertext, "msg",
               state: "false"
             )

    refute SessionStore.snapshot(sessions) == before
  end

  defp establish(ctx, backend) do
    {ciphertext, alice_sessions} =
      encrypt(ctx, SessionStore.new(), Map.delete(ctx.bundle, :prekey))

    {:ok, _plaintext, sessions} =
      Encryption.decrypt_from_sender_sync(
        ctx.store,
        new_sessions(backend),
        @alice,
        ciphertext,
        "pkmsg"
      )

    {:ok, session} = SessionStore.get_session(sessions, @alice)
    pending = %{base_key: session.initiator_base_key, signed_prekey_id: 201}

    sessions =
      sessions
      |> SessionStore.put_session(@alias, session)
      |> SessionStore.put_pending_prekey(@alice, pending)
      |> SessionStore.put_pending_prekey(@alias, pending)

    :ok = Store.persist_signal_sessions(ctx.store, sessions)
    {alice_sessions, sessions}
  end

  defp encrypt(ctx, sessions, bundle) do
    {:ok, ciphertext, :prekey, sessions} =
      SessionStore.encrypt_message(
        sessions,
        @bob,
        Encryption.pad_message(<<10, 5, "hello">>),
        ctx.identity,
        1001,
        bundle
      )

    {ciphertext, sessions}
  end

  defp decrypt(store, sessions, ciphertext, enc_state) do
    attrs = %{"type" => "pkmsg", "v" => "2", "state" => enc_state}
    content = [%Node{tag: "enc", attrs: attrs, content: ciphertext}]
    message = Wire.extract_message_content(content, "text")
    Decryptor.decrypt(message, %{store: store, signal_sessions: sessions}, @alice, nil, %{})
  end

  defp new_sessions(:map), do: SessionStore.new()
  defp new_sessions(:ets), do: SessionStore.new_ets()

  defp corrupt(ciphertext) do
    {:ok, parsed} = WireFormat.parse_prekey_signal_message(ciphertext)
    size = byte_size(parsed.message) - 1
    <<prefix::binary-size(^size), byte>> = parsed.message
    corrupted_message = prefix <> <<Bitwise.bxor(byte, 1)>>

    WireFormat.serialize_prekey_signal_message(
      parsed.registration_id,
      parsed.prekey_id,
      parsed.signed_prekey_id,
      parsed.base_key,
      parsed.identity_key,
      corrupted_message
    )
  end
end
