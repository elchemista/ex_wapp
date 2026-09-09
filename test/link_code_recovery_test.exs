defmodule ExWapp.LinkCodeRecoveryTest do
  use ExUnit.Case, async: true
  alias ExWapp.{Store, Binary}
  alias ExWapp.Binary.Node
  alias ExWapp.Pairing.LinkCode
  alias ExWapp.Signal.Keys
  alias ExWapp.Test.FaultStore

  setup do
    identity = Keys.generate_key_pair()
    noise = Keys.generate_key_pair()

    store =
      FaultStore.new(
        initial_data: %{
          signal: %{identity_key: identity},
          noise: %{static_public: noise.public, static_private: noise.private}
        }
      )

    %{store: store, identity: identity}
  end

  test "platform profiles are encoded in a decryptable companion hello", ctx do
    for {name, mode, expected} <- [
          {"Chrome", :web, "1"},
          {"Edge", :web, "2"},
          {"IE", :web, "4"},
          {"Opera", :web, "5"},
          {"Safari", :web, "6"},
          {"phone", :android, "9"}
        ] do
      runtime = %{
        protocol: %{client_mode: mode, user_agent: %{device_name: name, os_version: "Linux"}}
      }

      assert {:ok, request} =
               LinkCode.request(ctx.store, "15550001111", [custom_code: "ABCD2345"], runtime)

      assert {:ok, %Node{content: [registration]}} = Binary.decode(Binary.encode!(request.node))

      assert Enum.find(registration.content, &(&1.tag == "companion_platform_id")).content.data ==
               expected

      wrapped =
        Enum.find(
          registration.content,
          &(&1.tag == "link_code_pairing_wrapped_companion_ephemeral_pub")
        ).content.data

      <<salt::binary-32, iv::binary-16, encrypted::binary>> = wrapped
      key = LinkCode.derive_pairing_code_key(request.code, salt)

      assert :crypto.crypto_one_time(:aes_256_ctr, key, iv, encrypted, false) ==
               Store.get(ctx.store, :link_code_pairing).ephemeral_key.public
    end
  end

  test "incomplete credentials and failing storage never leave a pending pairing", ctx do
    for {data, reason} <- [
          {%{}, :missing_identity_keypair},
          {%{identity: ctx.identity}, :missing_noise_static_key}
        ] do
      store = FaultStore.new(initial_data: data)
      assert {:error, ^reason} = LinkCode.request(store, "15550001111")
      assert Store.get(store, :link_code_pairing) == nil
    end

    FaultStore.arm(ctx.store, :load, :raise)

    assert {:error, {:link_code_request_failed, %RuntimeError{}}} =
             LinkCode.request(ctx.store, "15550001111")

    assert Store.get(ctx.store, :link_code_pairing) == nil
    assert {:error, :invalid_link_code_request} = LinkCode.request(ctx.store, nil)
    assert LinkCode.crockford_encode(<<0>>) == "11"
  end

  test "incomplete phone notifications leave the pending request and ADV credentials intact",
       ctx do
    assert {:ok, _} = LinkCode.request(ctx.store, "15550001111")
    before = Store.load!(ctx.store)

    for node <- [
          %Node{tag: "notification"},
          %Node{tag: "link_code_companion_reg"},
          %Node{
            tag: "link_code_companion_reg",
            content: [%Node{tag: "link_code_pairing_ref", content: "reference"}]
          }
        ] do
      assert {:error, _} = LinkCode.finish(ctx.store, node)
      assert Store.load!(ctx.store) == before
    end

    notification = %Node{
      tag: "link_code_companion_reg",
      content: [
        %Node{tag: "link_code_pairing_ref", content: "reference"},
        %Node{tag: "primary_identity_pub", content: ctx.identity.public},
        %Node{tag: "link_code_pairing_wrapped_primary_ephemeral_pub", content: <<0::640>>}
      ]
    }

    FaultStore.arm(ctx.store, :load, :raise)

    assert {:error, {:link_code_finish_failed, %RuntimeError{}}} =
             LinkCode.finish(ctx.store, notification)

    assert {:error, :invalid_link_code_notification} = LinkCode.finish(ctx.store, nil)
    assert {:error, :link_code_not_pending} = LinkCode.finish(Store.Memory.new(), notification)
  end
end
