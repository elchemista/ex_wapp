defmodule ExWapp.DebugProtocolTest do
  use ExUnit.Case, async: true
  alias ExWapp.Debug.FullClient
  alias ExWapp.Noise.Handshake
  alias ExWapp.Signal.Keys
  alias ExWapp.Test.ProtocolPeer, as: Peer
  alias ExWapp.Transport.Frame
  alias WAWebProtobufsWa6.HandshakeMessage
  @moduletag capture_log: true

  test "diagnostic client builds a current signed registration payload and decrypts server response" do
    {state, peer, hello} = exchange()
    assert {:ok, state} = FullClient.handle_connect(nil, state)
    assert_receive :send_client_hello
    assert {:reply, {:binary, frame}, ^state} = FullClient.handle_info(:send_client_hello, state)
    assert frame == state.frame

    assert {:reply, {:binary, finish}, state} =
             FullClient.handle_frame({:binary, Frame.encode(hello)}, state)

    {keys, payload} = Peer.finish(peer, Peer.unframe(finish))
    version = ExWapp.Config.default_client_version()
    assert Map.take(payload.userAgent.appVersion, [:primary, :secondary, :tertiary]) == version
    pairing = payload.devicePairingData
    assert byte_size(pairing.eRegid) == 4
    assert Keys.verify(pairing.eIdent, pairing.eSkeyVal, pairing.eSkeySig)

    assert pairing.buildHash ==
             :crypto.hash(:md5, "#{version.primary}.#{version.secondary}.#{version.tertiary}")

    response = Peer.encrypt(keys.write, 0, "authenticated response") |> Frame.encode()
    assert {:close, ^state} = FullClient.handle_frame({:binary, response}, state)
    assert_receive {:result, {:ok, "authenticated response"}}
  end

  test "diagnostics reject malformed hellos and authenticated transport corruption" do
    {state, _, hello} = exchange()

    for payload <- [
          Peer.encode(%HandshakeMessage{
            clientHello: %HandshakeMessage.ClientHello{ephemeral: <<0::256>>}
          }),
          <<10, 255>>
        ] do
      assert {:close, _} =
               FullClient.handle_frame(
                 {:binary, Frame.encode(payload)},
                 Map.put(state, :phase, :waiting_server_hello)
               )

      assert_receive {:result, {:error, _}}
    end

    decoded = HandshakeMessage.decode!(hello)
    tampered = %{decoded | serverHello: %{decoded.serverHello | static: <<0::384>>}}

    assert {:close, _} =
             FullClient.handle_frame(
               {:binary, Frame.encode(Peer.encode(tampered))},
               Map.put(state, :phase, :waiting_server_hello)
             )

    assert_receive {:result, {:error, _}}
    state = %{phase: :waiting_response, read_key: <<0::256>>, rx_counter: 0, parent: self()}

    for bytes <- [<<1>>, <<0::256>>] do
      assert {:close, ^state} = FullClient.handle_frame({:binary, Frame.encode(bytes)}, state)
      assert_receive {:result, {:error, {:decrypt_failed, _}}}
    end

    assert {:ok, ^state} = FullClient.handle_frame({:text, "ignored"}, state)
    assert {:close, ^state} = FullClient.handle_cast(:stop, state)
    assert {:ok, ^state} = FullClient.handle_disconnect(:closed, state)
    assert_receive {:result, {:error, {:disconnected, :closed}}}
  end

  defp exchange do
    ephemeral = Keys.generate_key_pair()
    static = Keys.generate_key_pair()

    noise =
      Handshake.new("Noise_XX_25519_AESGCM_SHA256\0\0\0\0", Frame.header())
      |> Handshake.authenticate(ephemeral.public)

    hello =
      Peer.encode(%HandshakeMessage{
        clientHello: %HandshakeMessage.ClientHello{ephemeral: ephemeral.public}
      })

    {server_hello, peer} = Peer.hello(Peer.new(), hello)

    {%{
       parent: self(),
       e_kp: ephemeral,
       s_kp: static,
       noise: noise,
       frame: Frame.encode(hello, include_header: true)
     }, peer, server_hello}
  end
end
