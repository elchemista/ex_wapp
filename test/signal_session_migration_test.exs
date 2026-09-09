defmodule ExWapp.SignalSessionMigrationTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias ExWapp.Signal.{Keys, SessionStore, WireFormat}
  alias ExWapp.Test.SignalDevice
  @alice "100:1@s.whatsapp.net"
  @bob "200:2@s.whatsapp.net"
  @moduletag capture_log: true

  setup do
    level = Logger.level()
    Logger.configure(level: :debug)
    on_exit(fn -> Logger.configure(level: level) end)
    alice = Keys.generate_key_pair()
    bob = SignalDevice.new()

    {:ok, first, :prekey, sender} =
      SessionStore.encrypt_message(SessionStore.new(), @bob, "first", alice, 123, bob.bundle)

    {:ok, "first", receiver} =
      SessionStore.decrypt_message(
        SessionStore.new(),
        @alice,
        first,
        true,
        bob.identity,
        bob.local_prekeys
      )

    %{alice: alice, bob: bob, sender: sender, receiver: receiver}
  end

  for location <- [:current, :previous] do
    @location location
    test "restores a legacy #{@location} session from an authenticated prekey message", ctx do
      {:ok, second, :prekey, _} =
        SessionStore.encrypt_message(ctx.sender, @bob, "legacy continuation", ctx.alice, 123, %{})

      {:ok, old} = SessionStore.get_session(ctx.receiver, @alice)
      legacy = Map.delete(old, :initiator_base_key)

      receiver =
        if @location == :current do
          SessionStore.put_session(ctx.receiver, @alice, legacy)
        else
          # A persisted refresh raced with the peer's still-active session.
          {:ok, refreshed, _, _} =
            SessionStore.get_or_create_session(
              ctx.receiver,
              @alice,
              ctx.bob.identity,
              SignalDevice.new().bundle,
              456,
              force: true
            )

          SessionStore.put_session(
            ctx.receiver,
            @alice,
            Map.put(refreshed, :previous_sessions, [legacy])
          )
        end

      log =
        capture_log(fn ->
          assert {:ok, "legacy continuation", repaired} =
                   SessionStore.decrypt_message(
                     receiver,
                     @alice,
                     second,
                     true,
                     ctx.bob.identity,
                     %{prekeys: %{}, signed_prekey: ctx.bob.signed}
                   )

          {:ok, parsed} = WireFormat.parse_prekey_signal_message(second)
          assert {:ok, session} = SessionStore.get_session(repaired, @alice)
          assert session.initiator_base_key == parsed.base_key

          assert {:error, :message_key_not_found} =
                   SessionStore.decrypt_message(
                     repaired,
                     @alice,
                     second,
                     true,
                     ctx.bob.identity,
                     ctx.bob.local_prekeys
                   )
        end)

      assert log =~ "legacy"
      refute log =~ "legacy continuation"
      refute log =~ Base.encode64(ctx.alice.private)
    end
  end

  test "damaged legacy envelopes cannot consume the saved receiving chain", ctx do
    {:ok, second, :prekey, _} =
      SessionStore.encrypt_message(ctx.sender, @bob, "recoverable", ctx.alice, 123, %{})

    {:ok, old} = SessionStore.get_session(ctx.receiver, @alice)

    receiver =
      SessionStore.new_ets(
        SessionStore.put_session(ctx.receiver, @alice, Map.delete(old, :initiator_base_key))
      )

    before = SessionStore.snapshot(receiver)
    {:ok, envelope} = WireFormat.parse_prekey_signal_message(second)
    inner = envelope.message
    size = byte_size(inner) - 1
    <<prefix::binary-size(^size), last>> = inner

    damaged =
      WireFormat.serialize_prekey_signal_message(
        envelope.registration_id,
        envelope.prekey_id,
        envelope.signed_prekey_id,
        envelope.base_key,
        envelope.identity_key,
        prefix <> <<Bitwise.bxor(last, 1)>>
      )

    assert {:error, _} =
             SessionStore.decrypt_message(
               receiver,
               @alice,
               damaged,
               true,
               ctx.bob.identity,
               ctx.bob.local_prekeys
             )

    assert SessionStore.snapshot(receiver) == before

    assert {:ok, "recoverable", ^receiver} =
             SessionStore.decrypt_message(
               receiver,
               @alice,
               second,
               true,
               ctx.bob.identity,
               ctx.bob.local_prekeys
             )
  end

  test "old outbound snapshots restore prekey metadata without changing their keys", ctx do
    {:ok, session} = SessionStore.get_session(ctx.sender, @bob)

    for source <- [:pending, :bundle] do
      legacy =
        SessionStore.put_session(ctx.sender, @bob, Map.delete(session, :initiator_base_key))

      {legacy, bundle} =
        case source do
          :pending ->
            {legacy, %{}}

          :bundle ->
            {SessionStore.delete_pending_prekey(legacy, @bob),
             Map.put(ctx.bob.bundle, :base_key, session.initiator_base_key)}
        end

      assert {:ok, encrypted, :prekey, restored} =
               SessionStore.encrypt_message(legacy, @bob, "after upgrade", ctx.alice, 123, bundle)

      assert {:ok, "after upgrade", _} =
               SessionStore.decrypt_message(
                 ctx.receiver,
                 @alice,
                 encrypted,
                 true,
                 ctx.bob.identity,
                 ctx.bob.local_prekeys
               )

      assert {:ok, recovered} = SessionStore.get_session(restored, @bob)
      assert recovered.initiator_base_key == session.initiator_base_key
    end
  end

  test "late whisper replies decrypt against a retained session and reject duplicates", ctx do
    {:ok, reply, :whisper, _} =
      SessionStore.encrypt_message(ctx.receiver, @alice, "late reply", ctx.bob.identity, 456, %{})

    {:ok, current, _, refreshed} =
      SessionStore.get_or_create_session(ctx.sender, @bob, ctx.alice, ctx.bob.bundle, 123,
        force: true
      )

    assert length(current.previous_sessions) == 1

    assert {:ok, "late reply", updated} =
             SessionStore.decrypt_message(refreshed, @bob, reply, false, ctx.alice, %{})

    assert {:error, :message_key_not_found} =
             SessionStore.decrypt_message(updated, @bob, reply, false, ctx.alice, %{})

    assert {:ok, retained} = SessionStore.get_session(updated, @bob)
    assert retained.initiator_base_key == current.initiator_base_key
    assert length(retained.previous_sessions) == 1
  end

  test "identity replacement drops old ratchets and snapshot reset removes aliases", ctx do
    replacement = SignalDevice.new()

    {:ok, changed, _, sender} =
      SessionStore.get_or_create_session(ctx.sender, @bob, ctx.alice, replacement.bundle, 123,
        force: true
      )

    assert Map.get(changed, :previous_sessions, []) == []
    assert SessionStore.copy_session(sender, @bob, @bob) == sender
    assert SessionStore.copy_session(sender, "missing@s.whatsapp.net", @bob) == sender

    sender =
      sender
      |> SessionStore.copy_session(@bob, "200@lid")
      |> SessionStore.delete_pending_prekey(@bob)
      |> SessionStore.copy_session(@bob, "200@lid")

    assert SessionStore.get_pending_prekey(sender, "200@lid") == :not_found
    ref = SessionStore.new_ets(sender)
    assert SessionStore.replace(ref, SessionStore.new_ets()) == ref
    assert SessionStore.snapshot(ref) == SessionStore.new()
    assert SessionStore.replace(ref, nil) == ref
    assert SessionStore.snapshot(nil) == nil
  end
end
