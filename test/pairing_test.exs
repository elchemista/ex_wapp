defmodule ExWapp.PairingTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.{Binary, Pairing, Store}
  alias ExWapp.Pairing.ADV
  alias ExWapp.Signal.Keys
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

    expected_key_index = parsed_adv.details.keyIndex

    assert [%Binary.Node{tag: "pair-device-sign", content: [identity_node]}] = ack_node.content

    assert identity_node.tag == "device-identity"
    assert identity_node.attrs["key-index"] == Integer.to_string(expected_key_index)

    assert %Binary.Raw{data: self_signed_payload} = identity_node.content
    {:ok, self_signed} = ADVSignedDeviceIdentity.decode(self_signed_payload)

    assert self_signed.accountSignatureKey == nil
    assert self_signed.details == parsed_adv.signed.details
    assert self_signed.accountSignature == parsed_adv.signed.accountSignature
    assert byte_size(self_signed.deviceSignature) == 64

    device_message =
      <<6, 1>> <>
        parsed_adv.signed.details <> identity.public <> parsed_adv.signed.accountSignatureKey

    assert Keys.verify_message(identity.public, device_message, self_signed.deviceSignature)

    assert Enum.any?(actions, &(&1 == {:status, :success}))
  end

  test "legacy identity fallback remains authenticated when acknowledgement addressing is absent" do
    store = store_fixture()
    {identity, secret} = identity_fixture()
    Store.persist(store, %{identity: identity, signal: %{}, adv_secret: secret})
    {blob, _} = adv_identity_fixture(identity, secret)
    node = %{build_pair_success_node(blob) | attrs: %{}}
    {paired, actions} = Pairing.apply_node(Pairing.new(store), node)
    assert paired.status == :paired
    assert actions == [{:status, :success}]
    assert Store.get(store, :signal).identity_key == identity

    assert {:ok, signed} =
             ADVSignedDeviceIdentity.decode(Store.get(store, :pairing).adv_self_signed)

    assert byte_size(signed.deviceSignature) == 64
  end

  test "empty and extended QR reference lists preserve registration credentials" do
    store = store_fixture()
    {identity, secret} = identity_fixture()
    noise = Keys.generate_key_pair()
    original = %{identity: identity, adv_secret: secret, noise: %{static_public: noise.public}}
    Store.persist(store, original)
    original = Store.load!(store)
    state = Pairing.new(store)

    for content <- [nil, [], [%Binary.Node{tag: "extension"}]] do
      {waiting, actions} =
        Pairing.apply_node(state, %Binary.Node{
          tag: "iq",
          attrs: %{"id" => "qr", "from" => "s.whatsapp.net"},
          content: [%Binary.Node{tag: "pair-device", content: content}]
        })

      assert waiting.ref == nil
      assert [{:send_node, _}] = actions
      assert Store.load!(store) == original
    end

    node = %Binary.Node{
      tag: "iq",
      attrs: %{"id" => "qr", "from" => "s.whatsapp.net"},
      content: [
        %Binary.Node{
          tag: "pair-device",
          content: [
            %Binary.Node{tag: "extension"},
            %Binary.Node{tag: "ref", content: "2@existing-prefix"}
          ]
        }
      ]
    }

    {_, actions} = Pairing.apply_node(state, node)
    assert {:qr, value} = Enum.find(actions, &match?({:qr, _}, &1))

    assert String.split(value, ",") == [
             "2@existing-prefix",
             Base.encode64(noise.public),
             Base.encode64(identity.public),
             Base.encode64(secret)
           ]

    assert Store.load!(store) == original
    assert Pairing.apply_node(state, %Binary.Node{tag: "ignored"}) == {state, []}
    assert Pairing.apply_node(state, %Binary.Node{tag: "iq"}) == {state, []}
  end

  test "pair-device emits only first qr ref" do
    store = store_fixture()
    :ok = Store.persist(store, %{noise: %{static_public: :crypto.strong_rand_bytes(32)}})

    state = Pairing.new(store)

    node = %Binary.Node{
      tag: "iq",
      attrs: %{"from" => "s.whatsapp.net", "id" => "pair-1"},
      content: [
        %Binary.Node{
          tag: "pair-device",
          attrs: %{},
          content: [
            %Binary.Node{tag: "ref", attrs: %{}, content: Binary.raw("REF_ONE")},
            %Binary.Node{tag: "ref", attrs: %{}, content: Binary.raw("REF_TWO")}
          ]
        }
      ]
    }

    {_new_state, actions} = Pairing.apply_node(state, node)

    qr_actions = Enum.filter(actions, &match?({:qr, _}, &1))
    assert length(qr_actions) == 1

    assert [{:qr, qr_code}] = qr_actions
    [ref_prefix | _rest] = String.split(qr_code, ",")
    assert ref_prefix == "2@REF_ONE"
  end

  test "pair-success without account signature does not report success" do
    store = store_fixture()

    {identity, adv_secret} = identity_fixture()
    :ok = Store.persist(store, %{identity: identity, adv_secret: adv_secret})

    device_identity_bytes = invalid_adv_identity_fixture(identity, adv_secret)
    pair_success = build_pair_success_node(device_identity_bytes)

    state = Pairing.new(store)
    {_, actions} = Pairing.apply_node(state, pair_success)

    refute Enum.any?(actions, &(&1 == {:status, :success}))

    assert {:send_node,
            %Binary.Node{
              tag: "iq",
              attrs: %{"type" => "error"},
              content: [
                %Binary.Node{
                  tag: "error",
                  attrs: %{"code" => "401", "text" => "signature-mismatch"}
                }
              ]
            }} =
             Enum.find(actions, &match?({:send_node, _}, &1))

    assert Enum.any?(actions, &match?({:error, :adv_invalid_account_signature_fields}, &1))
  end

  test "malformed pair-success cannot overwrite existing account data" do
    {identity, secret} = identity_fixture()
    {blob, _} = adv_identity_fixture(identity, secret)
    valid = build_pair_success_node(blob)

    for initial <- [
          %{identity: identity},
          %{identity: identity, adv_secret: <<1>>},
          %{adv_secret: secret},
          %{identity: %{public: <<1>>, private: <<2>>}},
          %{identity: identity, adv_secret: secret}
        ] do
      store = Store.Memory.new(initial_data: Map.put(initial, :marker, "retain"))

      node =
        if initial == %{identity: identity, adv_secret: secret},
          do: %{
            valid
            | content: [
                %Binary.Node{
                  tag: "pair-success",
                  content: [
                    %Binary.Node{tag: "device", attrs: %{"jid" => "1555:1@s.whatsapp.net"}}
                  ]
                }
              ]
          },
          else: valid

      state = Pairing.new(store)
      assert {^state, actions} = Pairing.apply_node(state, node)
      assert Enum.any?(actions, &match?({:error, _}, &1))
      refute {:status, :success} in actions
      assert Store.load!(store) == Map.put(initial, :marker, "retain")
    end
  end

  test "pair-success with authenticated identity but no device never reports success" do
    {identity, secret} = identity_fixture()
    {blob, _} = adv_identity_fixture(identity, secret)
    store = Store.Memory.new(initial_data: %{identity: identity, adv_secret: secret})

    node = %Binary.Node{
      tag: "iq",
      attrs: %{},
      content: [
        %Binary.Node{
          tag: "pair-success",
          content: [%Binary.Node{tag: "device-identity", content: blob}]
        }
      ]
    }

    state = Pairing.new(store)
    assert {^state, [{:error, {:missing_child, "device"}}]} = Pairing.apply_node(state, node)
    refute Map.has_key?(Store.load!(store), :pairing)
  end

  defp identity_fixture do
    %{private: priv, public: pub} = Keys.generate_key_pair()
    {%{public: pub, private: priv}, :crypto.strong_rand_bytes(32)}
  end

  defp adv_identity_fixture(identity, adv_secret) do
    identity_pub = identity.public

    %{private: account_priv, public: account_pub} = Keys.generate_key_pair()

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
    account_sig = Keys.sign_message(account_priv, account_message)
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

  defp invalid_adv_identity_fixture(_identity, adv_secret) do
    account_pub = Keys.generate_key_pair().public

    details =
      %ADVDeviceIdentity{
        rawID: 1234,
        timestamp: 1_725_000_000,
        keyIndex: 42,
        accountType: :E2EE,
        deviceType: :E2EE
      }
      |> then(&encode!(ADVDeviceIdentity, &1))

    signed =
      %ADVSignedDeviceIdentity{
        details: details,
        accountSignatureKey: account_pub
      }
      |> then(&encode!(ADVSignedDeviceIdentity, &1))

    container_bytes =
      %ADVSignedDeviceIdentityHMAC{
        details: signed,
        HMAC: :crypto.mac(:hmac, :sha256, adv_secret, signed),
        accountType: :E2EE
      }
      |> then(&encode!(ADVSignedDeviceIdentityHMAC, &1))

    container_bytes
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

    store = Store.Ets.new(path: path)

    on_exit(fn -> File.rm(path) end)

    store
  end

  defp encode!(module, struct) do
    {:ok, io, _size} = module.encode(struct)
    IO.iodata_to_binary(io)
  end
end
