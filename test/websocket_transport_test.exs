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

  test "production websocket options verify the CA chain and hostname" do
    options = ExWapp.Transport.TLS.websockex_options("wss://web.whatsapp.com/ws/chat")
    ssl_options = Keyword.fetch!(options, :ssl_options)

    assert Keyword.fetch!(options, :insecure) == false
    assert [_first_ca | _rest] = Keyword.fetch!(options, :cacerts)
    assert Keyword.fetch!(ssl_options, :verify) == :verify_peer
    assert Keyword.fetch!(ssl_options, :server_name_indication) == ~c"web.whatsapp.com"
    assert [_first_ca | _rest] = Keyword.fetch!(ssl_options, :cacerts)

    assert is_function(
             ssl_options
             |> Keyword.fetch!(:customize_hostname_check)
             |> Keyword.fetch!(:match_fun)
           )
  end

  test "plaintext websocket URLs do not receive SSL options" do
    assert ExWapp.Transport.TLS.websockex_options("ws://localhost/socket") == []
  end
end
