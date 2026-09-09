defmodule ExWapp.StoreAdapterFailureTest do
  use ExUnit.Case, async: true
  alias ExWapp.{Prekeys, Store}
  alias ExWapp.Signal.SessionStore
  alias ExWapp.Session.Worker.SignalSessions
  alias ExWapp.Test.{FaultStore, SignalDevice}
  @moduletag capture_log: true

  setup do
    local = SignalDevice.new()

    store =
      FaultStore.new(
        initial_data: %{
          signal:
            Map.merge(local.local_prekeys, %{registration_id: 42, identity_key: local.identity})
        }
      )

    %{store: store, local: local}
  end

  test "prekey reservation failures cannot publish unpersisted private keys", ctx do
    for action <- [
          {:return, {:error, :storage_down}},
          {:return, :invalid_reply},
          :raise,
          :throw,
          :exit
        ] do
      before = Store.load!(ctx.store)
      FaultStore.arm(ctx.store, :get_and_update, action)

      assert {:error, {:prekey_reservation_failed, _}} =
               Prekeys.build_prekey_upload(ctx.store, count: 2)

      assert Store.load!(ctx.store) == before
    end

    assert {:ok, _node, [one, two]} = Prekeys.build_prekey_upload(ctx.store, count: 2)
    assert one.key_id != two.key_id
    assert byte_size(Store.get(ctx.store, :signal).prekeys[one.key_id].private) == 32
  end

  test "failed acknowledgement bookkeeping can be retried without changing private keys", ctx do
    {:ok, _, keys} = Prekeys.build_prekey_upload(ctx.store, count: 2)
    before = Store.get(ctx.store, :signal)

    for action <- [{:return, {:error, :storage_down}}, :raise, :throw, :exit] do
      FaultStore.arm(ctx.store, :update, action)
      assert {:error, _} = Prekeys.mark_uploaded(ctx.store, keys)
      assert Store.get(ctx.store, :signal) == before
      FaultStore.arm(ctx.store, :get_and_update, action)
      assert {:error, _} = Prekeys.note_advertised_prekey_id(ctx.store, 777)
      assert Store.get(ctx.store, :signal) == before
    end

    FaultStore.arm(ctx.store, :get_and_update, {:return, :invalid_reply})

    assert {:error, {:prekey_watermark_update_failed, :invalid_reply}} =
             Prekeys.note_advertised_prekey_id(ctx.store, 777)

    assert :ok = Prekeys.mark_uploaded(ctx.store, keys)
    after_signal = Store.get(ctx.store, :signal)

    for key <- keys do
      assert after_signal.prekeys[key.key_id].uploaded
      assert after_signal.prekeys[key.key_id].private == before.prekeys[key.key_id].private
    end
  end

  test "Signal persistence degrades on adapter errors and a later save recovers the session",
       ctx do
    peer = SignalDevice.new()

    {:ok, _, _, sessions} =
      SessionStore.get_or_create_session(
        SessionStore.new(),
        "123@s.whatsapp.net",
        ctx.local.identity,
        peer.bundle,
        42
      )

    for action <- [{:return, {:error, :storage_down}}, :raise] do
      FaultStore.arm(ctx.store, :persist, action)
      assert :ok = SignalSessions.persist(ctx.store, sessions)
      assert SessionStore.list_sessions(SignalSessions.load(ctx.store)) == []
    end

    for action <- [{:return, {:error, :disk_full}}, :raise] do
      FaultStore.arm(ctx.store, :flush, action)
      assert :ok = SignalSessions.persist(ctx.store, sessions)
    end

    assert :ok = SignalSessions.persist(ctx.store, sessions)
    assert SessionStore.list_sessions(SignalSessions.load(ctx.store)) == ["123@s.whatsapp.net"]
    FaultStore.arm(ctx.store, :load, :raise)
    assert SignalSessions.load(ctx.store) == nil
    assert :ok = SignalSessions.persist(nil, sessions)
    assert SessionStore.list_sessions(SignalSessions.normalize(:invalid_old_snapshot)) == []
  end

  test "invalid identity refresh leaves the existing ratchet usable", ctx do
    state = %{store: ctx.store, signal_sessions: SessionStore.new_ets()}
    assert SignalSessions.install_refreshed_identity(state, "123@s.whatsapp.net", %{}) == state
    FaultStore.arm(ctx.store, :load, :raise)

    assert SignalSessions.install_refreshed_identity(
             state,
             "123@s.whatsapp.net",
             SignalDevice.new().bundle
           ) == state

    peer = SignalDevice.new()
    updated = SignalSessions.install_refreshed_identity(state, "123@s.whatsapp.net", peer.bundle)

    assert {:ok, ciphertext, :prekey, _} =
             SessionStore.encrypt_message(
               updated.signal_sessions,
               "123@s.whatsapp.net",
               "after outage",
               ctx.local.identity,
               42,
               %{}
             )

    assert {:ok, "after outage", _} =
             SessionStore.decrypt_message(
               SessionStore.new(),
               "456@s.whatsapp.net",
               ciphertext,
               true,
               peer.identity,
               peer.local_prekeys
             )

    assert SessionStore.list_sessions(
             SignalSessions.clear_for_jid(updated, "123@s.whatsapp.net").signal_sessions
           ) == []

    assert SignalSessions.refresh_on_connect(%{signal_sessions: nil}) == %{signal_sessions: nil}
  end

  test "external ID allocator failures abort before persisting new keys", ctx do
    before = Store.load!(ctx.store)

    for allocator <- [
          fn _, _ -> :invalid end,
          fn _, _ -> throw(:unavailable) end,
          fn _, _ -> exit(:unavailable) end
        ] do
      assert {:error, {:prekey_id_allocation_failed, _}} =
               Prekeys.build_prekey_upload(ctx.store,
                 count: 2,
                 runtime_cfg: %{prekeys: %{id_allocator: allocator}}
               )

      assert Store.load!(ctx.store) == before
    end

    assert {:error, {:invalid_prekey_id_allocator, :invalid}} =
             Prekeys.allocate_ids(%{prekeys: %{id_allocator: :invalid}}, %{}, 1)

    assert {:error, :invalid_prekey_count} = Prekeys.build_prekey_upload(ctx.store, count: -1)
    assert Prekeys.next_safe_id(%{next_prekey_id: :corrupt}, %{}) == 1
    assert Prekeys.advertise_ids(%{}, [nil, -1]) == %{}
    assert Prekeys.note_advertised_prekey_id(ctx.store, nil) == :ok
  end
end
