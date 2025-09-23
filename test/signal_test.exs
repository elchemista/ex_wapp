defmodule ExWapp.SignalTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Signal
  alias ExWapp.Signal.Keys

  test "bootstrap generates fresh signal bundle and state" do
    {:ok, info, state} = Signal.bootstrap(%{device_attrs: %{"device-id" => "5"}})

    assert info.registration_id in 1..65_535
    assert info.device_id == 5
    assert byte_size(info.identity_key) == 32

    assert %{id: signed_id, public: signed_pub, signature: signature} = info.signed_prekey
    assert signed_id > 0
    assert byte_size(signed_pub) == 32
    assert byte_size(signature) == 64
    assert Keys.verify(info.identity_key, signed_pub, signature)

    assert %{id: prekey_id, public: prekey_pub} = info.prekey
    assert prekey_id > 0
    assert byte_size(prekey_pub) == 32

    assert info.bundle == %{
             registration_id: info.registration_id,
             device_id: 5,
             identity_key: info.identity_key,
             signed_prekey: info.signed_prekey,
             prekey: info.prekey,
             type: :curve25519
           }

    assert state.identity_key.public == info.identity_key
    assert state.registration_id == info.registration_id
    assert state.device_id == 5
    assert state.sessions == %{}
    assert state.prekeys[prekey_id].public == prekey_pub
    assert state.signed_prekeys[signed_id].public == signed_pub
    assert state.next_prekey_id == prekey_id + 1
  end

  test "bootstrap reuses existing signal state" do
    {:ok, info1, state1} = Signal.bootstrap(%{})

    {:ok, info2, state2} =
      Signal.bootstrap(%{current_signal: state1, device_attrs: %{"device-id" => "9"}})

    assert info1.identity_key == info2.identity_key
    assert state2.identity_key == state1.identity_key
    assert state2.registration_id == state1.registration_id
    assert state2.prekeys == state1.prekeys
    assert state2.signed_prekeys == state1.signed_prekeys
    assert state2.sessions == state1.sessions
    assert info2.device_id == 9
  end

  test "bootstrap preserves existing session map" do
    sessions = %{"alice" => %{ratchet: %{}}}

    {:ok, _info, state} = Signal.bootstrap(%{current_signal: %{sessions: sessions}})

    assert state.sessions == sessions
  end
end
