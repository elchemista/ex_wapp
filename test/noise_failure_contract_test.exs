defmodule ExWapp.NoiseFailureContractTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Noise, Store}
  alias ExWapp.Test.{FaultStore, ProtocolPeer}
  alias WAWebProtobufsWa6.HandshakeMessage

  setup do
    store = FaultStore.new()
    on_exit(fn -> Store.Memory.stop(store.inner) end)
    %{store: store}
  end

  test "missing stores and invalid custom payloads fail before persisting keys", ctx do
    assert {:error, :missing_store} = Noise.init([])

    for {result, expected} <- [
          {{:error, :payload_unavailable}, {:error, :payload_unavailable}},
          {:invalid, {:error, {:invalid_payload, :invalid}}}
        ] do
      assert Noise.init(store: ctx.store, client_payload_fun: fn _ -> result end) == expected
      assert Store.load!(ctx.store) == %{}
    end
  end

  test "custom binary payload and disabled payload callback are accepted", ctx do
    for callback <- [fn _ -> <<1, 2, 3>> end, nil] do
      assert {:ok, hello, noise} = Noise.init(store: ctx.store, client_payload_fun: callback)

      assert %HandshakeMessage{clientHello: %{ephemeral: ephemeral}} =
               HandshakeMessage.decode!(hello)

      assert byte_size(ephemeral) == 32
      assert noise.phase == :handshake
      assert noise.pending_store_data == nil
    end
  end

  test "a static-key persistence failure aborts initialization and can be retried", ctx do
    FaultStore.arm(ctx.store, :update, {:return, {:error, :disk_full}})
    opts = [store: ctx.store, client_payload_fun: fn _ -> <<>> end]
    assert {:error, :disk_full} = Noise.init(opts)
    assert Store.load!(ctx.store) == %{}
    assert {:ok, _, _} = Noise.init(opts)
    assert %{noise: %{static_private: key}} = Store.load!(ctx.store)
    assert byte_size(key) == 32
  end

  test "a failed final handshake write does not commit pending registration data", ctx do
    peer = ProtocolPeer.new()

    assert {:ok, hello, noise} =
             Noise.init(
               store: ctx.store,
               client_payload_fun: fn _ -> {:ok, <<>>, %{registration_marker: :pending}} end,
               certificate_verifier: ProtocolPeer.verifier(peer)
             )

    before = Store.load!(ctx.store)
    {server_hello, _peer} = ProtocolPeer.hello(peer, hello)
    FaultStore.arm(ctx.store, :transaction, {:return, {:error, :disk_full}})
    assert {:error, :disk_full} = Noise.handle_server_hello(noise, server_hello)
    assert Store.load!(ctx.store) == before
    refute Map.has_key?(before, :registration_marker)
    assert {:ok, _, %{phase: :transport}} = Noise.handle_server_hello(noise, server_hello)
    assert Store.get(ctx.store, :registration_marker) == :pending
  end

  test "invalid certificate verifiers cannot promote a handshake to transport", ctx do
    peer = ProtocolPeer.new()

    for {verifier, expected} <- [
          {nil, :invalid_certificate_verifier},
          {fn _, _ -> :accepted end, {:invalid_certificate_verifier_result, :accepted}},
          {fn _, _ -> {:error, :untrusted_peer} end, :untrusted_peer}
        ] do
      {:ok, hello, noise} = Noise.init(store: ctx.store, certificate_verifier: verifier)
      {server_hello, _peer} = ProtocolPeer.hello(peer, hello)
      before = Store.load!(ctx.store)
      assert {:error, ^expected} = Noise.handle_server_hello(noise, server_hello)
      assert Store.load!(ctx.store) == before
      assert noise.phase == :handshake
    end
  end

  test "out-of-order handshake and transport calls return structured errors", ctx do
    {:ok, _hello, noise} = Noise.init(store: ctx.store)

    unexpected =
      ProtocolPeer.encode(%HandshakeMessage{clientHello: %HandshakeMessage.ClientHello{}})

    assert {:error, {:unexpected_message, _}} = Noise.handle_server_hello(noise, unexpected)
    assert {:error, :invalid_state} = Noise.handle_server_hello(%Noise{}, <<>>)
    assert {:error, :invalid_state} = Noise.encrypt(noise, "too soon")
    assert {:error, :invalid_state} = Noise.decrypt(noise, <<>>)
    assert {:error, :invalid_state} = Noise.encrypt(%Noise{phase: :transport}, "missing cipher")
    assert {:error, :invalid_state} = Noise.decrypt(%Noise{phase: :transport}, <<>>)
  end

  test "an exhausted receive nonce requires a reconnect without wrapping the counter" do
    cipher = %{key: <<1::256>>, counter: 0x1_0000_0000}

    noise = %Noise{
      phase: :transport,
      cipher_ref: {cipher, cipher, <<0::256>>},
      rx_counter: cipher.counter
    }

    assert {:error, {:decrypt_failed, :counter_exhausted}} = Noise.decrypt(noise, <<0::256>>)
  end
end
