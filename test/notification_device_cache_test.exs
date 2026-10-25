defmodule ExWapp.NotificationDeviceCacheTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Binary, JID, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.Inbound
  alias ExWapp.Session.DeviceCache

  setup do
    pn = "15550001111@s.whatsapp.net"
    lid = "70000001111@lid"

    store =
      Store.Memory.new(
        initial_data: %{
          lid_mapping: %{{:pn_to_lid, pn} => lid, {:lid_to_pn, lid} => pn}
        }
      )

    on_exit(fn -> Store.Memory.stop(store) end)
    %{store: store, pn: pn, lid: lid}
  end

  test "nested notifications cache device JIDs in both address families", ctx do
    nodes = [
      %Node{
        tag: "devices",
        content: [
          %Node{
            tag: "device",
            attrs: %{
              "jid" => JID.new("15550001111", "s.whatsapp.net") |> JID.with_device(7),
              "count" => "2"
            }
          },
          %Node{tag: "device", attrs: %{"jid" => "70000001111:8@lid"}},
          %Node{tag: "device", attrs: %{"jid" => "15550001111:7@s.whatsapp.net"}},
          %Node{tag: "metadata", attrs: nil, content: Binary.raw("opaque")},
          :unknown
        ]
      }
    ]

    assert :ok = Inbound.persist_notification_devices(%{store: ctx.store}, nodes)

    assert DeviceCache.resolve_recent_devices(ctx.store, ctx.pn, %{}) |> Enum.sort() ==
             ["15550001111:7@s.whatsapp.net", "15550001111:8@s.whatsapp.net"]

    assert DeviceCache.resolve_recent_devices(ctx.store, ctx.lid, %{}) |> Enum.sort() ==
             ["70000001111:7@lid", "70000001111:8@lid"]

    cache = Store.load_device_cache(ctx.store)
    assert :ok = Inbound.persist_notification_devices(%{store: ctx.store}, nodes)
    assert Store.load_device_cache(ctx.store) == cache
    assert :ok = DeviceCache.evict_devices(ctx.store, ["70000001111:7@lid"])

    assert DeviceCache.resolve_recent_devices(ctx.store, ctx.pn, %{}) == [
             "15550001111:8@s.whatsapp.net"
           ]
  end

  test "empty notifications and absent stores do not invent device targets", ctx do
    for content <- [nil, Binary.raw("opaque"), [], [:unknown], [%Node{tag: "devices"}]] do
      assert :ok = Inbound.persist_notification_devices(%{store: ctx.store}, content)
      assert :ok = Inbound.persist_notification_devices(%{}, content)
    end

    assert Store.load_device_cache(ctx.store) == %{}
    assert :ok = DeviceCache.persist_observed_device(ctx.store, nil)
    assert :ok = DeviceCache.evict_devices(ctx.store, [nil, ""])
    assert DeviceCache.resolve_recent_devices(ctx.store, ctx.pn, %{}) == []
  end
end
