defmodule ExWapp.PairingTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.{Binary, Pairing, Store}
  alias ExWapp.Pairing.ADV
  alias Ed25519
  alias WAAdv.{ADVDeviceIdentity, ADVSignedDeviceIdentity, ADVSignedDeviceIdentityHMAC}

  test "pair-success ack uses pair-device-sign payload" do
    store = store_fixture()

    {identity, adv_secret} = identity_fixture()
    :ok = Store.persist(store, %{identity: identity, adv_secret: adv_secret})

    {container_bytes, parsed_adv} = adv_identity_fixture(identity, adv_secret)

    pair_success = build_pair_success_node(container_bytes)

    state = Pairing.new(store)

    {_, actions} = Pairing.apply_node(state, pair_success)

    assert {:send_node, %Binary.Node{} = ack_node} =
             Enum.find(actions, &match?({:send_node, _}, &1))

    assert ack_node.tag == "iq"
    assert ack_node.attrs["to"] == "s.whatsapp.net"
    assert ack_node.attrs["type"] == "result"
    assert ack_node.attrs["id"] == "req-123"

    assert [
             %Binary.Node{
               tag: "pair-device-sign",
               content: [
                 %Binary.Node{
                   tag: "device-identity",
                   attrs: %{"key-index" => Integer.to_string(parsed_adv.details.keyIndex)},
                   content: %Binary.Raw{data: parsed_adv.self_signed}
                 }
               ]
             }
           ] = ack_node.content

    assert Enum.any?(actions, &(&1 == {:status, :success}))
  end

  defp identity_fixture do
    {priv, pub} = Ed25519.generate_key_pair()
    {%{public: pub, private: priv}, :crypto.strong_rand_bytes(32)}
  end

  defp adv_identity_fixture(identity, adv_secret) do
    identity_pub = identity.public

    account_priv = :crypto.strong_rand_bytes(32)
    account_pub = Ed25519.derive_public_key(account_priv)

    details = %ADVDeviceIdentity{
      rawID: 1234,
      timestamp: 1_725_000_000,
      keyIndex: 42,
      accountType: :E2EE,
      deviceType: :E2EE
    }

    details_inner = encode!(ADVDeviceIdentity, details)

    signed = %ADVSignedDeviceIdentity{
      details: details_inner,
      accountSignatureKey: account_pub
    }

    account_message = <<6, 0>> <> details_inner <> identity_pub
    account_sig = Ed25519.signature(account_message, account_priv)
    signed = %ADVSignedDeviceIdentity{signed | accountSignature: account_sig}

    signed_bytes = encode!(ADVSignedDeviceIdentity, signed)

    hmac = :crypto.mac(:hmac, :sha256, adv_secret, signed_bytes)

    container = %ADVSignedDeviceIdentityHMAC{
      details: signed_bytes,
      HMAC: hmac,
      accountType: :E2EE
    }

    container_bytes = encode!(ADVSignedDeviceIdentityHMAC, container)

    {:ok, parsed} =
      ADV.parse_signed_device_identity(container_bytes, adv_secret, identity)

    {container_bytes, parsed}
  end

  defp build_pair_success_node(device_identity_bytes) do
    pair_success = %Binary.Node{
      tag: "pair-success",
      attrs: %{},
      content: [
        %Binary.Node{
          tag: "device-identity",
          attrs: %{},
          content: Binary.raw(device_identity_bytes)
        },
        %Binary.Node{
          tag: "adv-device-identity",
          attrs: %{},
          content: Binary.raw(device_identity_bytes)
        },
        %Binary.Node{
          tag: "device",
          attrs: %{
            "jid" => "123@s.whatsapp.net",
            "lid" => "123@lid.whatsapp.net",
            "device-id" => "1"
          },
          content: nil
        },
        %Binary.Node{tag: "biz", attrs: %{"name" => "Test"}, content: nil},
        %Binary.Node{tag: "platform", attrs: %{"name" => "DESKTOP"}, content: nil}
      ]
    }

    %Binary.Node{
      tag: "iq",
      attrs: %{"from" => "s.whatsapp.net", "id" => "req-123"},
      content: [pair_success]
    }
  end

  defp store_fixture do
    tmp_dir = Path.join(System.tmp_dir!(), "ex_wapp_pairing_test")
    :ok = File.mkdir_p(tmp_dir)
    path = Path.join(tmp_dir, "store_#{System.unique_integer([:positive])}.etf")

    store = Store.ETS.new(path: path)

    on_exit(fn -> File.rm(path) end)

    store
  end

  defp encode!(module, struct) do
    {:ok, io} = module.encode(struct)
    IO.iodata_to_binary(io)
  end
end
