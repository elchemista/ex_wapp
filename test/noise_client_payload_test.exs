defmodule ExWapp.Noise.ClientPayloadTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Noise
  alias ExWapp.Noise.ClientPayload, as: NoiseClientPayload
  alias ExWapp.Store
  alias WAWebProtobufsWa6.ClientPayload, as: ClientPayloadProto
  alias WAWebProtobufsWa6.ClientPayload.DevicePairingRegistrationData

  @version_hash :crypto.hash(:md5, "2.3000.1029948479")
  # DeviceProps with historySyncConfig matching Firefox/Linux identity
  @device_props <<
    0x0A,
    0x07,
    "Firefox"::binary,
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
      assert pairing.deviceProps == @device_props

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
