defmodule ExWapp.Session.Outbound.PrekeysTest do
  use ExUnit.Case, async: true

  alias ExWapp.Session.Outbound.Prekeys
  alias ExWapp.Signal.SessionStore

  test "selects missing and forced-identity devices while keeping fresh sessions" do
    now_ms = 1_000_000
    fresh = "15550001111:5@s.whatsapp.net"
    missing = "15550001111:7@s.whatsapp.net"
    own = "15550002222:9@s.whatsapp.net"

    signal_sessions =
      SessionStore.new()
      |> Map.put(:sessions, %{fresh => %{}, own => %{}})
      |> Map.put(:session_touched_at_ms, %{fresh => now_ms, own => now_ms})

    assert Prekeys.devices_needing_prekeys(
             signal_sessions,
             [fresh, missing, own],
             [own],
             %{},
             60_000,
             now_ms
           ) == [missing, own]
  end

  test "expands a recipient prekey refresh to every known recipient device" do
    recipient = "15550001111@s.whatsapp.net"
    recipient_device = "15550001111:5@s.whatsapp.net"
    second_recipient_device = "15550001111:7@s.whatsapp.net"
    own_device = "15550002222:9@s.whatsapp.net"

    assert Prekeys.expand_recipient_identity_targets(
             [recipient_device, own_device],
             [recipient, recipient_device, second_recipient_device]
           ) == [
             recipient,
             recipient_device,
             second_recipient_device,
             own_device
           ]
  end

  test "reports only requested devices without returned bundles" do
    returned = "15550001111:5@s.whatsapp.net"
    missing = "15550001111:7@s.whatsapp.net"

    assert Prekeys.missing_bundle_targets(
             [returned, missing],
             %{returned => %{registration_id: 42}}
           ) == [missing]
  end

  test "preserves the empty bundle bootstrap error" do
    assert Prekeys.create_sessions_for_bundles(
             SessionStore.new(),
             "15550001111@s.whatsapp.net",
             [],
             :local_identity,
             42,
             %{}
           ) == {:error, :no_sessions_created}
  end
end
