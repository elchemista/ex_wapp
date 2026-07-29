defmodule ExWapp.Noise.ClientPayloadTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Config
  alias ExWapp.Noise
  alias ExWapp.Noise.ClientPayload, as: NoiseClientPayload
  alias ExWapp.Proto.CompanionReg.DeviceProps
  alias ExWapp.Store
  alias WAWebProtobufsWa6.ClientPayload, as: ClientPayloadProto
  alias WAWebProtobufsWa6.ClientPayload.DevicePairingRegistrationData

  # Derived from the configured default so this test tracks version bumps
  # instead of failing on them; what it protects is hash = md5 of the exact
  # dotted version string the payload reports.
  @version_hash (
                  v = ExWapp.Config.default_client_version()
                  :crypto.hash(:md5, "#{v.primary}.#{v.secondary}.#{v.tertiary}")
                )
  @firefox_device_props <<
    0x0A,
    0x05,
    "Linux"::binary,
    0x12,
    0x06,
    0x08,
    0x00,
    0x10,
    0x01,
    0x18,
    0x00,
    0x18,
    0x02,
    0x20,
    0x00,
    0x2A,
    0x17,
    0x18,
    0x80,
    0x50,
    0x20,
    0x01,
    0x30,
    0x00,
    0x38,
    0x01,
    0x40,
    0x01,
    0x48,
    0x01,
    0x50,
    0x01,
    0x58,
    0x01,
    0x60,
    0x01,
    0x70,
    0x01,
    0x78,
    0x00
  >>

  describe "build/1" do
    test "includes the device registration bundle" do
      store = store_fixture()
      noise = %Noise{store: store}

      assert {:ok, payload, data} = NoiseClientPayload.build(noise)
      assert {:ok, decoded} = ClientPayloadProto.decode(payload)
      assert %DevicePairingRegistrationData{} = pairing = decoded.devicePairingData

      assert byte_size(pairing.eRegid) == 4
      assert pairing.eKeytype == <<5>>
      assert byte_size(pairing.eIdent) == 32
      assert byte_size(pairing.eSkeyID) == 3
      assert byte_size(pairing.eSkeyVal) == 32
      assert byte_size(pairing.eSkeySig) == 64
      assert pairing.buildHash == @version_hash

      # Asserted against the configured defaults rather than a captured byte
      # string: the property worth protecting is that the identity we configure
      # is the identity we encode. Pinning the bytes only detects change, and
      # change here is sometimes the fix.
      configured = Config.defaults().protocol.pairing_device_props

      assert %DeviceProps{} = device_props = DeviceProps.decode!(pairing.deviceProps)
      assert device_props.os == configured.os
      assert device_props.platform_type == configured.platform_type
      assert device_props.require_full_sync == configured.require_full_sync

      # `platform_type: 0` is the UNKNOWN enum, which makes WhatsApp render `os`
      # verbatim as the device label in the user's linked-devices list. Shipping
      # that by default put a library name on every paired device.
      refute device_props.platform_type == 0
      assert device_props.version.primary == 0
      assert device_props.version.secondary == 1
      assert device_props.version.tertiary == 0
      assert device_props.history_sync_config.storage_quota_mb == 10_240
      assert device_props.history_sync_config.inline_initial_payload_in_e2ee_msg == true
      assert device_props.history_sync_config.support_message_association == true
      assert device_props.history_sync_config.support_group_history == false

      assert %{registration_id: reg_id} = data[:signal]
      assert reg_id in 1..65_535
    end

    test "reuses the stored signal bundle" do
      store = store_fixture()
      noise = %Noise{store: store}

      assert {:ok, payload1, data1} = NoiseClientPayload.build(noise)
      assert :ok = Store.persist(store, data1)

      assert {:ok, payload2, data2} = NoiseClientPayload.build(noise)

      pairing1 = decode_pairing(payload1)
      pairing2 = decode_pairing(payload2)

      assert pairing1.eRegid == pairing2.eRegid
      assert pairing1.eIdent == pairing2.eIdent
      assert pairing1.eSkeyVal == pairing2.eSkeyVal
      assert pairing1.eSkeySig == pairing2.eSkeySig
      assert pairing1.eSkeyID == pairing2.eSkeyID
      assert Map.drop(data1[:signal], [:updated_at]) == Map.drop(data2[:signal], [:updated_at])
    end

    test "supports runtime user-agent defaults for Firefox/Linux profile" do
      store = store_fixture()
      noise = %Noise{store: store}

      runtime_cfg =
        Config.defaults()
        |> put_in([:protocol, :user_agent, :os_version], "Linux 6.8")
        |> put_in([:protocol, :user_agent, :manufacturer], "Mozilla")
        |> put_in([:protocol, :user_agent, :device_name], "Firefox")
        |> put_in([:protocol, :user_agent, :os_build], "x86_64")

      assert {:ok, payload, data} = NoiseClientPayload.build(noise, runtime_cfg)
      assert {:ok, decoded} = ClientPayloadProto.decode(payload)

      assert decoded.userAgent.osVersion == "Linux 6.8"
      assert decoded.userAgent.manufacturer == "Mozilla"
      assert decoded.userAgent.device == "Firefox"
      assert decoded.userAgent.osBuildNumber == "x86_64"

      assert get_in(data, [:client_info, :os_version]) == "Linux 6.8"
      assert get_in(data, [:client_info, :manufacturer]) == "Mozilla"
      assert get_in(data, [:client_info, :device_name]) == "Firefox"
      assert get_in(data, [:client_info, :os_build]) == "x86_64"
    end

    test "builds a native Android registration payload without WebInfo" do
      store = store_fixture()
      noise = %Noise{store: store}

      runtime_cfg = put_in(Config.defaults(), [:protocol, :client_mode], :android)

      assert {:ok, payload, _data} = NoiseClientPayload.build(noise, runtime_cfg)
      assert {:ok, decoded} = ClientPayloadProto.decode(payload)
      assert decoded.userAgent.platform == :ANDROID
      assert decoded.webInfo == nil

      assert %DeviceProps{} =
               device_props = DeviceProps.decode!(decoded.devicePairingData.deviceProps)

      assert device_props.platform_type == 16
    end

    test "builds a native Android login payload without WebInfo" do
      store = store_fixture()
      noise = %Noise{store: store}

      :ok =
        Store.persist(store, %{
          pairing: %{device: %{jid: %ExWapp.JID{user: "15550001111", device: 40}}},
          client_info: %{}
        })

      runtime_cfg = put_in(Config.defaults(), [:protocol, :client_mode], :android)

      assert {:ok, payload, _data} = NoiseClientPayload.build(noise, runtime_cfg)
      assert {:ok, decoded} = ClientPayloadProto.decode(payload)
      assert decoded.userAgent.platform == :ANDROID
      assert decoded.webInfo == nil
      assert decoded.passive
    end

    test "supports runtime pairing device props overrides" do
      store = store_fixture()
      noise = %Noise{store: store}

      runtime_cfg =
        Config.defaults()
        |> put_in([:protocol, :pairing_device_props, :os], "Linux")
        |> put_in([:protocol, :pairing_device_props, :platform_type], 2)

      assert {:ok, payload, _data} = NoiseClientPayload.build(noise, runtime_cfg)
      assert {:ok, decoded} = ClientPayloadProto.decode(payload)
      assert decoded.devicePairingData.deviceProps == @firefox_device_props

      assert %DeviceProps{} =
               device_props = DeviceProps.decode!(decoded.devicePairingData.deviceProps)

      assert device_props.os == "Linux"
      assert device_props.platform_type == 2
    end

    test "supports structured pairing device props overrides" do
      store = store_fixture()
      noise = %Noise{store: store}

      runtime_cfg =
        Config.defaults()
        |> put_in([:protocol, :pairing_device_props, :os], "Mac OS")
        |> put_in([:protocol, :pairing_device_props, :platform_type], 1)
        |> put_in([:protocol, :pairing_device_props, :version], %{
          primary: 10,
          secondary: 15,
          tertiary: 7
        })
        |> put_in(
          [:protocol, :pairing_device_props, :history_sync_config, :storage_quota_mb],
          2048
        )
        |> put_in(
          [:protocol, :pairing_device_props, :history_sync_config, :support_group_history],
          true
        )

      assert {:ok, payload, _data} = NoiseClientPayload.build(noise, runtime_cfg)
      assert {:ok, decoded} = ClientPayloadProto.decode(payload)

      assert %DeviceProps{} =
               device_props = DeviceProps.decode!(decoded.devicePairingData.deviceProps)

      assert device_props.os == "Mac OS"
      assert device_props.platform_type == 1
      assert device_props.version.primary == 10
      assert device_props.version.secondary == 15
      assert device_props.version.tertiary == 7
      assert device_props.history_sync_config.storage_quota_mb == 2048
      assert device_props.history_sync_config.support_group_history == true
    end

    test "normalizes client_info for login payloads" do
      store = store_fixture()
      noise = %Noise{store: store}

      :ok =
        Store.persist(store, %{
          pairing: %{device: %{jid: %ExWapp.JID{user: "15550001111", device: 40}}},
          client_info: %{}
        })

      runtime_cfg =
        Config.defaults()
        |> put_in([:protocol, :user_agent, :os_version], "Linux")
        |> put_in([:protocol, :user_agent, :manufacturer], "Mozilla")
        |> put_in([:protocol, :user_agent, :device_name], "Firefox")
        |> put_in([:protocol, :user_agent, :os_build], "Linux")

      assert {:ok, payload, data} = NoiseClientPayload.build(noise, runtime_cfg)
      assert {:ok, decoded} = ClientPayloadProto.decode(payload)

      assert decoded.userAgent.osVersion == "Linux"
      assert decoded.userAgent.manufacturer == "Mozilla"
      assert decoded.userAgent.device == "Firefox"
      assert decoded.userAgent.osBuildNumber == "Linux"
      assert decoded.lidDbMigrated == true
      assert decoded.lc == 1

      assert get_in(data, [:client_info, :os_version]) == "Linux"
      assert get_in(data, [:client_info, :manufacturer]) == "Mozilla"
      assert get_in(data, [:client_info, :device_name]) == "Firefox"
      assert get_in(data, [:client_info, :os_build]) == "Linux"
    end

    test "builds login payload from client_info jid when pairing data is missing" do
      store = store_fixture()
      noise = %Noise{store: store}

      :ok =
        Store.persist(store, %{
          client_info: %{jid: "15550001111@s.whatsapp.net"},
          signal: %{device_id: 40}
        })

      assert {:ok, payload, data} = NoiseClientPayload.build(noise)
      assert {:ok, decoded} = ClientPayloadProto.decode(payload)

      assert decoded.passive
      assert decoded.pull
      assert decoded.lidDbMigrated == true
      assert decoded.lc == 1
      assert decoded.username == 15_550_001_111
      assert decoded.device == 40
      assert data[:client_info][:jid] == %ExWapp.JID{user: "15550001111", device: 40}
      assert is_nil(decoded.devicePairingData)
    end
  end

  defp decode_pairing(payload) do
    {:ok, decoded} = ClientPayloadProto.decode(payload)
    decoded.devicePairingData
  end

  defp store_fixture do
    tmp_dir = Path.join(System.tmp_dir!(), "ex_wapp_tests")
    :ok = File.mkdir_p(tmp_dir)
    path = Path.join(tmp_dir, "store_#{System.unique_integer([:positive])}.etf")

    store = Store.Ets.new(path: path)

    on_exit(fn -> File.rm(path) end)

    store
  end
end
