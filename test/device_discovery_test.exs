defmodule ExWapp.Session.Outbound.DeviceDiscoveryTest do
  use ExUnit.Case, async: true

  alias ExWapp.Session.Outbound.DeviceDiscovery

  test "builds one USync query across recipient, PN, and LID identities" do
    recipient = "15550001111@s.whatsapp.net"
    recipient_lid = "70000001111@lid"
    own = "15550002222@s.whatsapp.net"
    own_lid = "70000002222@lid"

    lid_mapping = %{
      {:pn_to_lid, recipient} => recipient_lid,
      {:lid_to_pn, recipient_lid} => recipient,
      {:pn_to_lid, own} => own_lid,
      {:lid_to_pn, own_lid} => own
    }

    assert DeviceDiscovery.query_jids(recipient, own, own, own_lid, lid_mapping) == [
             recipient,
             recipient_lid,
             own,
             own_lid
           ]
  end

  test "resolves live, cached, linked, and aggregate device sets" do
    recipient = "15550001111@s.whatsapp.net"
    recipient_device = "15550001111:5@s.whatsapp.net"
    cached_recipient_device = "15550001111:7@s.whatsapp.net"
    own = "15550002222@s.whatsapp.net"
    own_device = "15550002222:9@s.whatsapp.net"
    cached_own_device = "15550002222:10@s.whatsapp.net"

    resolution =
      DeviceDiscovery.resolve(%{
        device_map: %{
          recipient => [recipient, recipient_device],
          own => [own, own_device]
        },
        recipient_base_jid: recipient,
        recipient_cached_devices: [recipient_device, cached_recipient_device],
        own_sender_jid: own,
        own_base_jid: own,
        own_lid_jid: "70000002222@lid",
        own_cached_devices: [own, own_device, cached_own_device],
        own_device_id: 0,
        lid_mapping: %{}
      })

    assert resolution.recipient_devices == [recipient, recipient_device]
    assert resolution.recipient_cached_devices == [cached_recipient_device]
    assert resolution.own_devices == [own_device]
    assert resolution.own_cached_devices == [cached_own_device]

    assert resolution.all_usync_devices == [
             recipient,
             recipient_device,
             own,
             own_device
           ]

    assert resolution.all_device_jids == [
             recipient_device,
             cached_recipient_device,
             own_device,
             cached_own_device
           ]
  end

  test "maps LID-only linked devices into the preferred PN family" do
    own = "15550002222@s.whatsapp.net"
    own_lid = "70000002222@lid"
    own_lid_device = "70000002222:9@lid"

    resolution =
      DeviceDiscovery.resolve(%{
        device_map: %{own_lid => [own_lid_device]},
        recipient_base_jid: "15550001111@s.whatsapp.net",
        recipient_cached_devices: [],
        own_sender_jid: own,
        own_base_jid: own,
        own_lid_jid: own_lid,
        own_cached_devices: [],
        own_device_id: 0,
        lid_mapping: %{
          {:pn_to_lid, own} => own_lid,
          {:lid_to_pn, own_lid} => own
        }
      })

    assert resolution.own_devices == ["15550002222:9@s.whatsapp.net"]
  end

  test "maps own linked devices into LID for a LID-addressed destination" do
    own = "15550002222@s.whatsapp.net"
    own_lid = "70000002222@lid"
    own_pn_device = "15550002222:9@s.whatsapp.net"

    resolution =
      DeviceDiscovery.resolve(%{
        device_map: %{own => [own_pn_device]},
        recipient_base_jid: "70000001111@lid",
        recipient_cached_devices: [],
        own_sender_jid: own_lid,
        own_base_jid: own,
        own_lid_jid: own_lid,
        own_cached_devices: [],
        own_device_id: 0,
        lid_mapping: %{
          {:pn_to_lid, own} => own_lid,
          {:lid_to_pn, own_lid} => own
        }
      })

    assert resolution.own_devices == ["70000002222:9@lid"]
  end
end
