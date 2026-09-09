defmodule ExWapp.JIDTargetContractTest do
  use ExUnit.Case, async: true
  alias ExWapp.JID
  alias ExWapp.Session.JIDUtils

  test "overlapping recipient and own-device lists emit one correct payload per device" do
    one = "123:1@s.whatsapp.net"
    two = "123:2@s.whatsapp.net"
    three = "456:3@s.whatsapp.net"

    assert JIDUtils.build_dm_target_specs([one, one, two], [two, two, three]) == [
             %{jid: one, payload_kind: :recipient},
             %{jid: two, payload_kind: :own},
             %{jid: three, payload_kind: :own}
           ]

    assert JIDUtils.build_self_chat_fallback_target_specs(
             [one, two],
             [three],
             "unknown@s.whatsapp.net"
           ) == [
             %{jid: one, payload_kind: :recipient},
             %{jid: two, payload_kind: :own},
             %{jid: three, payload_kind: :own}
           ]

    assert JIDUtils.build_self_chat_fallback_target_specs([], [two, three], nil) == [
             %{jid: two, payload_kind: :recipient},
             %{jid: three, payload_kind: :own}
           ]

    assert JIDUtils.build_self_chat_fallback_target_specs([], [], nil) == []
  end

  test "parsed devices retain identity while invalid references cannot become destinations" do
    {:ok, jid} = JID.parse("123:7@s.whatsapp.net")
    assert JIDUtils.strip_device(jid) == "123@s.whatsapp.net"
    assert JIDUtils.device_id(jid) == 7
    assert JIDUtils.current_device_target?(jid, 7)
    refute JIDUtils.current_device_target?(jid, :invalid)
    assert JIDUtils.map_to_preferred_family(jid, nil, %{}) == "123:7@s.whatsapp.net"

    assert JIDUtils.normalize_target_list([nil, jid, " 123:7@whatsapp.net "]) == [
             "123:7@s.whatsapp.net"
           ]

    for value <- [nil, 42, %{}] do
      assert JIDUtils.strip_device(value) == ""
      assert JIDUtils.user_part(value) == ""
      assert JIDUtils.device_id(value) == nil
      refute JIDUtils.has_explicit_device?(value)
      refute JIDUtils.lid_jid?(value)
      assert JIDUtils.resolve_signal_encryption_jid(value, %{}) == ""
      assert JIDUtils.map_to_preferred_family(value, "123@lid", %{}) == ""
      assert JIDUtils.normalize_target_list(value) == []
    end

    refute JIDUtils.has_explicit_device?("missing-server")
  end
end
