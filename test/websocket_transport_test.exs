defmodule ExWapp.WebSocketTransportTest do
  use ExUnit.Case, async: true

  alias ExWapp.Transport.{Frame, WebSocket}

  test "connect/1 builds an initial websocket payload with WA header" do
    client = ExWapp.new(store: ExWapp.Store.Memory, session_id: "ws")
    state = WebSocket.new(client, owner: self())

    assert {:ok, connected_state, payload} = WebSocket.connect(state)
    assert connected_state.header_sent?
    assert connected_state.noise.phase == :handshake
    assert <<?W, ?A, 0x06, 0x03, _rest::binary>> = payload
    assert_receive {:ex_wapp_transport, {:handshake, :started}}
  end

  test "receive_bytes/2 buffers incomplete frame data after the WA header" do
    client = ExWapp.new(store: ExWapp.Store.Memory, session_id: "ws")
    state = WebSocket.new(client, owner: self())
    encoded = Frame.header() <> <<5::unsigned-big-size(24), "ab">>

    assert {:ok, next_state, []} = WebSocket.receive_bytes(state, encoded)
    assert next_state.header_seen?
    assert next_state.buffer == <<5::unsigned-big-size(24), "ab">>
  end
end
