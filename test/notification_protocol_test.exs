defmodule ExWapp.NotificationProtocolTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Binary.Node
  alias ExWapp.MessageHandler
  alias ExWapp.Session.DeviceCache
  alias ExWapp.Signal.SessionStore
  alias ExWapp.Store

  test "peer identity notification deletes every device session and requests a fresh bundle" do
    sessions =
      SessionStore.new()
      |> SessionStore.put_session("15550001111@s.whatsapp.net", %{remote_identity_key: <<1>>})
      |> SessionStore.put_session("15550001111:7@s.whatsapp.net", %{remote_identity_key: <<1>>})
      |> SessionStore.put_session("15550002222@s.whatsapp.net", %{remote_identity_key: <<2>>})

    notification = notification("encrypt", "IDENTITY-1", "15550001111@s.whatsapp.net", [])

    assert {:ok, next_state, actions} =
             MessageHandler.handle_node(notification, self(), %{signal_sessions: sessions})

    refute SessionStore.has_session?(next_state.signal_sessions, "15550001111@s.whatsapp.net")
    refute SessionStore.has_session?(next_state.signal_sessions, "15550001111:7@s.whatsapp.net")
    assert SessionStore.has_session?(next_state.signal_sessions, "15550002222@s.whatsapp.net")

    assert [
             {:send_node, %Node{tag: "ack"}},
             {:signal_sessions_updated, updated},
             {:refresh_identity_session, "15550001111@s.whatsapp.net"}
           ] = actions

    assert updated == next_state.signal_sessions
  end

  test "offline identity notifications and unknown peers do not destroy sessions" do
    sessions =
      SessionStore.new()
      |> SessionStore.put_session("15550001111@s.whatsapp.net", %{remote_identity_key: <<1>>})

    offline =
      notification("encrypt", "IDENTITY-2", "15550001111@s.whatsapp.net", [])
      |> put_in([Access.key!(:attrs), "offline"], "1")

    assert {:ok, %{signal_sessions: ^sessions}, [{:send_node, %Node{tag: "ack"}}]} =
             MessageHandler.handle_node(offline, self(), %{signal_sessions: sessions})

    unknown = notification("encrypt", "IDENTITY-3", "15550009999@s.whatsapp.net", [])

    assert {:ok, %{signal_sessions: ^sessions}, [{:send_node, %Node{tag: "ack"}}]} =
             MessageHandler.handle_node(unknown, self(), %{signal_sessions: sessions})
  end

  test "server encrypt inventory schedules only a low-water refill" do
    low =
      notification("encrypt", "KEYS-1", "s.whatsapp.net", [
        %Node{tag: "count", attrs: %{"value" => "5"}, content: nil}
      ])

    assert {:ok, _state, [{:send_node, %Node{tag: "ack"}}, {:refill_prekeys, 5}]} =
             MessageHandler.handle_node(low, self(), %{
               runtime_cfg: %{prekeys: %{min_threshold: 5}}
             })

    healthy =
      notification("encrypt", "KEYS-2", "s.whatsapp.net", [
        %Node{tag: "count", attrs: %{"value" => "6"}, content: nil}
      ])

    assert {:ok, _state, [{:send_node, %Node{tag: "ack"}}]} =
             MessageHandler.handle_node(healthy, self(), %{
               runtime_cfg: %{prekeys: %{min_threshold: 5}}
             })
  end

  test "device deltas invalidate the authoritative cache for PN and LID aliases" do
    store =
      Store.Memory.new(
        initial_data: %{
          lid_mapping: %{
            {:pn_to_lid, "15550001111@s.whatsapp.net"} => "999999@lid",
            {:lid_to_pn, "999999@lid"} => "15550001111@s.whatsapp.net"
          }
        }
      )

    :ok = DeviceCache.persist_observed_device(store, "15550001111:2@s.whatsapp.net")
    :ok = DeviceCache.persist_observed_device(store, "999999:3@lid")
    assert map_size(Store.load_device_cache(store)) == 2

    devices =
      notification("devices", "DEVICES-1", "s.whatsapp.net", [
        %Node{
          tag: "remove",
          attrs: %{},
          content: [
            %Node{
              tag: "device",
              attrs: %{"jid" => "15550001111:2@s.whatsapp.net"},
              content: nil
            }
          ]
        }
      ])

    assert {:ok, _state, [{:send_node, %Node{tag: "ack"}}]} =
             MessageHandler.handle_node(devices, self(), %{store: store})

    assert Store.load_device_cache(store) == %{}
  end

  test "account_sync own-device changes invalidate local PN and LID lists" do
    store =
      Store.Memory.new(
        initial_data: %{
          client_info: %{jid: "15550002222:4@s.whatsapp.net", lid: "888888@lid"},
          lid_mapping: %{
            {:pn_to_lid, "15550002222@s.whatsapp.net"} => "888888@lid",
            {:lid_to_pn, "888888@lid"} => "15550002222@s.whatsapp.net"
          }
        }
      )

    :ok = DeviceCache.persist_observed_device(store, "15550002222:7@s.whatsapp.net")
    :ok = DeviceCache.persist_observed_device(store, "888888:8@lid")

    own_devices =
      notification("account_sync", "OWN-1", "s.whatsapp.net", [
        %Node{tag: "devices", attrs: %{}, content: []}
      ])

    assert {:ok, _state, [{:send_node, %Node{tag: "ack"}}]} =
             MessageHandler.handle_node(own_devices, self(), %{store: store})

    assert Store.load_device_cache(store) == %{}
  end

  test "privacy tokens are stored under both PN and LID aliases" do
    pn = "15550003333@s.whatsapp.net"
    lid = "77777733333@lid"
    token = <<1, 2, 3, 4>>

    store =
      Store.Memory.new(
        initial_data: %{
          lid_mapping: %{
            {:pn_to_lid, pn} => lid,
            {:lid_to_pn, lid} => pn
          }
        }
      )

    privacy_token =
      notification("privacy_token", "TOKEN-1", pn, [
        %Node{
          tag: "tokens",
          attrs: %{},
          content: [
            %Node{
              tag: "token",
              attrs: %{"type" => "trusted_contact", "t" => "123"},
              content: Binary.raw(token)
            }
          ]
        }
      ])
      |> put_in([Access.key!(:attrs), "sender_lid"], lid)

    assert {:ok, _state, [{:send_node, %Node{tag: "ack"}}]} =
             MessageHandler.handle_node(privacy_token, self(), %{store: store})

    tctokens = store |> Store.load!() |> Map.fetch!(:tctokens)
    assert tctokens[pn] == %{token: token, timestamp: "123"}
    assert tctokens[lid] == %{token: token, timestamp: "123"}
  end

  defp notification(type, id, from, content) do
    %Node{
      tag: "notification",
      attrs: %{"type" => type, "id" => id, "from" => from},
      content: content
    }
  end
end
