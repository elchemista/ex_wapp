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

  test "canonicalizes every participant into a LID destination family" do
    recipient_pn = "15550001111@s.whatsapp.net"
    recipient_lid = "70000001111@lid"
    own_pn = "15550002222@s.whatsapp.net"
    own_lid = "70000002222@lid"

    resolution =
      Fanout.resolve(
        context(%{
          jid: recipient_lid,
          own_base_jid: own_pn,
          own_lid_jid: own_lid,
          lid_mapping: %{
            {:pn_to_lid, recipient_pn} => recipient_lid,
            {:lid_to_pn, recipient_lid} => recipient_pn,
            {:pn_to_lid, own_pn} => own_lid,
            {:lid_to_pn, own_lid} => own_pn
          },
          target_hints: %{
            recipient_devices: [
              recipient_pn,
              "#{recipient_pn |> String.split("@") |> hd()}:5@s.whatsapp.net"
            ],
            recipient_cached_devices: [],
            own_devices: ["15550002222:9@s.whatsapp.net"],
            own_cached_devices: [],
            own_identity_jid: own_lid,
            all_usync_devices: [
              "15550001111:5@s.whatsapp.net",
              "15550002222:9@s.whatsapp.net"
            ]
          }
        })
      )

    assert resolution.target_specs == [
             %{jid: recipient_lid, payload_kind: :recipient},
             %{jid: "70000001111:5@lid", payload_kind: :recipient},
             %{jid: "70000002222:9@lid", payload_kind: :own}
           ]

    assert Enum.all?(resolution.all_usync_devices, &String.ends_with?(&1, "@lid"))
    assert resolution.family_rejections == []
  end

  test "rejects an unresolved mixed-family target instead of poisoning the whole message" do
    resolution =
      Fanout.resolve(
        context(%{
          jid: "70000001111@lid",
          own_base_jid: "",
          own_lid_jid: "",
          target_hints: %{
            recipient_devices: ["70000001111@lid"],
            recipient_cached_devices: [],
            own_devices: ["15550002222:9@s.whatsapp.net"],
            own_cached_devices: [],
            own_identity_jid: "",
            all_usync_devices: []
          }
        })
      )

    assert resolution.target_specs == [
             %{jid: "70000001111@lid", payload_kind: :recipient}
           ]

    assert resolution.family_rejections == ["15550002222:9@s.whatsapp.net"]
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
