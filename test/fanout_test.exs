defmodule ExWapp.Session.Outbound.FanoutTest do
  use ExUnit.Case, async: true

  alias ExWapp.Session.Outbound.Fanout
  alias ExWapp.Signal.SessionStore

  test "resolves recipient and linked-device payload kinds" do
    resolution =
      Fanout.resolve(
        context(%{
          target_hints: %{
            recipient_devices: [
              "15550001111@s.whatsapp.net",
              "15550001111:5@s.whatsapp.net"
            ],
            recipient_cached_devices: [],
            own_devices: [
              "15550002222@s.whatsapp.net",
              "15550002222:9@s.whatsapp.net"
            ],
            own_cached_devices: [],
            own_identity_jid: "15550002222@s.whatsapp.net",
            all_usync_devices: ["15550001111:5@s.whatsapp.net"]
          }
        })
      )

    assert resolution.recipient_targets == [
             "15550001111@s.whatsapp.net",
             "15550001111:5@s.whatsapp.net"
           ]

    assert resolution.own_targets == ["15550002222:9@s.whatsapp.net"]

    assert resolution.target_specs == [
             %{jid: "15550001111@s.whatsapp.net", payload_kind: :recipient},
             %{jid: "15550001111:5@s.whatsapp.net", payload_kind: :recipient},
             %{jid: "15550002222:9@s.whatsapp.net", payload_kind: :own}
           ]

    refute resolution.self_chat?
    assert resolution.cached_eviction_batches == []
    assert resolution.all_usync_devices == ["15550001111:5@s.whatsapp.net"]
  end

  test "uses DSM payloads for every non-current self-chat target" do
    resolution =
      Fanout.resolve(
        context(%{
          jid: "15550002222@s.whatsapp.net",
          target_hints: %{
            recipient_devices: [
              "15550002222@s.whatsapp.net",
              "15550002222:9@s.whatsapp.net"
            ],
            recipient_cached_devices: [],
            own_devices: [
              "15550002222@s.whatsapp.net",
              "15550002222:9@s.whatsapp.net",
              "15550002222:10@s.whatsapp.net"
            ],
            own_cached_devices: [],
            own_identity_jid: "15550002222@s.whatsapp.net",
            all_usync_devices: []
          }
        })
      )

    assert resolution.self_chat?
    assert resolution.recipient_targets == ["15550002222:9@s.whatsapp.net"]

    assert resolution.target_specs == [
             %{jid: "15550002222:9@s.whatsapp.net", payload_kind: :own},
             %{jid: "15550002222:10@s.whatsapp.net", payload_kind: :own}
           ]
  end

  test "returns unreachable cached targets for eviction" do
    reachable_cached = "15550001111:6@s.whatsapp.net"
    unreachable_cached = "15550001111:7@s.whatsapp.net"

    resolution =
      Fanout.resolve(
        context(%{
          signal_sessions: SessionStore.new(),
          prekey_bundles: %{reachable_cached => %{registration_id: 42}},
          target_hints: %{
            recipient_devices: ["15550001111:5@s.whatsapp.net"],
            recipient_cached_devices: [reachable_cached, unreachable_cached],
            own_devices: [],
            own_cached_devices: [],
            own_identity_jid: "15550002222@s.whatsapp.net",
            all_usync_devices: []
          }
        })
      )

    assert resolution.recipient_targets == [
             "15550001111:5@s.whatsapp.net",
             reachable_cached
           ]

    assert resolution.cached_eviction_batches == [[unreachable_cached]]
  end

  @spec context(map()) :: map()
  defp context(overrides) do
    Map.merge(
      %{
        signal_sessions: nil,
        jid: "15550001111@s.whatsapp.net",
        prekey_bundles: %{},
        target_hints: %{},
        own_base_jid: "15550002222@s.whatsapp.net",
        own_lid_jid: "77700002222@lid",
        own_device_id: 0,
        lid_mapping: %{},
        self_chat_mode: :dsm_all_non_current
      },
      overrides
    )
  end
end
