defmodule ExWapp.ConnectionPeerTest do
  use ExUnit.Case, async: true
  alias ExWapp.{Binary, Conn, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Test.ProtocolPeer, as: Peer
  alias ExWapp.Transport.{Frame, WebSocket}

  test "Conn completes a signed Noise exchange and exchanges independently encrypted nodes" do
    {state, keys} = conn_pair()
    assert Store.load!(state.store).noise.server_static != nil

    nodes = [
      %Node{tag: "iq", attrs: %{"type" => "result", "to" => "s.whatsapp.net"}},
      %Node{tag: "message", attrs: %{"id" => "raw"}, content: Binary.raw(<<0, 255>>)},
      %Node{tag: "message", attrs: %{"id" => "text"}, content: "text"},
      %Node{
        tag: "list",
        content: for(n <- 1..21, do: %Node{tag: "item", attrs: %{"id" => to_string(n)}})
      },
      %Node{tag: "iq", attrs: %{"id" => "nested"}, content: [%Node{tag: "ping", content: []}]}
    ]

    final =
      Enum.with_index(nodes)
      |> Enum.reduce(state, fn {node, counter}, state ->
        assert {:reply, {:binary, frame}, state} = Conn.handle_cast({:send_node, node}, state)
        plain = Peer.decrypt(keys.read, counter, Peer.unframe(frame))
        assert Binary.decode!(plain) == normalize_node(node)
        encrypted = Peer.encrypt(keys.write, counter, Binary.encode!(node))
        assert {:ok, state} = Conn.handle_frame({:binary, Frame.encode(encrypted)}, state)
        expected = normalize_node(node)
        assert_receive {:connection_event, {:connection_message, ^expected}}
        state
      end)

    assert final.noise.tx_counter == length(nodes)
    assert final.noise.rx_counter == length(nodes)
  end

  test "Conn preserves incomplete input and recovers after corrupt ciphertext" do
    {state, keys} = conn_pair()
    node = %Node{tag: "ack", attrs: %{"id" => "after-corruption"}}
    invalid = Frame.encode(<<0, 1>>)
    good = Frame.encode(Peer.encrypt(keys.write, 1, Binary.encode!(node)))
    <<prefix::binary-size(2), rest::binary>> = invalid <> good
    assert {:ok, buffered} = Conn.handle_frame({:binary, prefix}, state)
    assert buffered.buffer == prefix
    assert {:ok, recovered} = Conn.handle_frame({:binary, rest}, buffered)
    assert recovered.buffer == <<>>
    assert recovered.noise.rx_counter == 2
    assert_receive {:connection_event, {:error, {:decrypt_failed, _, _}}}
    assert_receive {:connection_event, {:connection_message, ^node}}
  end

  test "Conn surfaces empty and undecodable authenticated payloads without losing nonce state" do
    {state, keys} = conn_pair()

    Enum.with_index([<<>>, <<255, 1, 2>>])
    |> Enum.reduce(state, fn {plain, n}, state ->
      assert {:ok, next} =
               Conn.handle_frame(
                 {:binary, Frame.encode(Peer.encrypt(keys.write, n, plain))},
                 state
               )

      next
    end)

    assert_receive {:connection_event, {:connection_message, :empty}}
    assert_receive {:connection_event, {:connection_binary, <<255, 1, 2>>}}
    assert {:ok, ^state} = Conn.handle_frame({:text, "not binary"}, state)
    assert {:ok, ^state} = Conn.handle_disconnect(:closed, state)
    assert_receive {:connection_event, {:transport, {:closed, :closed}}}
  end

  test "Conn rejects a signed handshake from an untrusted root" do
    peer = Peer.new()
    state = %Conn.State{session: self(), store: Store.Memory.new()}
    assert {:ok, state} = Conn.handle_connect(nil, state)
    assert_receive {:send_raw_frame, {:binary, frame}}
    {hello, _} = Peer.hello(peer, Peer.unframe(frame))

    assert {:close, rejected} =
             Conn.handle_frame({:binary, Frame.encode(hello, include_header: true)}, state)

    assert rejected.noise.phase == :handshake
    assert_receive {:connection_event, {:error, _}}
    refute_receive {:connection_event, {:noise, :handshake_completed}}
  end

  test "connection initialization reports payload construction errors and exceptions" do
    for {builder, expected} <- [
          {fn _ -> {:error, :missing_keys} end, :missing_keys},
          {fn _ -> raise "payload failure" end, :crash}
        ] do
      state = %Conn.State{
        session: self(),
        store: Store.Memory.new(),
        noise_opts: [client_payload_fun: builder]
      }

      assert {:close, _} = Conn.handle_connect(nil, state)
      assert_receive {:connection_event, {:error, reason}}

      if expected == :crash,
        do: assert(match?({:crash, %RuntimeError{}}, reason)),
        else: assert(reason == expected)
    end
  end

  test "WebSocket callbacks complete signed Noise and preserve owner events and counters" do
    peer = Peer.new()
    client = ExWapp.new(store: Store.Memory)
    initial = WebSocket.new(client, noise: [certificate_verifier: Peer.verifier(peer)])
    assert {:ok, state} = WebSocket.handle_connect(nil, initial)
    assert_receive {:send_raw_frame, hello}
    assert_receive {:ex_wapp_transport, {:connected, _}}
    {hello, peer} = Peer.hello(peer, Peer.unframe(hello))

    assert {:reply, {:binary, finish}, state} =
             WebSocket.handle_frame({:binary, Frame.encode(hello, include_header: true)}, state)

    {keys, payload} = Peer.finish(peer, Peer.unframe(finish))

    assert payload.userAgent.appVersion.tertiary ==
             ExWapp.Config.default_client_version().tertiary

    assert_receive {:ex_wapp_transport, {:handshake, :completed}}

    node = %Node{tag: "ack", attrs: %{"id" => "ack"}}
    assert {:reply, {:binary, outbound}, state} = WebSocket.handle_cast({:send_node, node}, state)
    assert Binary.decode!(Peer.decrypt(keys.read, 0, Peer.unframe(outbound))) == node

    assert {:reply, {:binary, outbound}, state} =
             WebSocket.handle_cast({:send_payload, "payload"}, state)

    assert Peer.decrypt(keys.read, 1, Peer.unframe(outbound)) == "payload"
    incoming = Peer.encrypt(keys.write, 0, Binary.encode!(node)) |> Frame.encode()
    assert {:ok, state} = WebSocket.handle_frame({:binary, incoming}, state)
    assert_receive {:ex_wapp_transport, {:node, ^node}}
    assert {:ok, ^state} = WebSocket.handle_frame({:text, "ignored"}, state)
    assert {:ok, ^state} = WebSocket.handle_info(:ignored, state)

    assert {:reply, {:binary, "raw"}, ^state} =
             WebSocket.handle_info({:send_raw_frame, "raw"}, state)

    assert {:ok, ^state} = WebSocket.handle_disconnect(:closed, state)
    assert_receive {:ex_wapp_transport, {:disconnected, :closed}}
  end

  test "WebSocket reports attempts to send and receive before a handshake" do
    state = WebSocket.new(ExWapp.new(store: Store.Memory))
    assert {:ok, ^state} = WebSocket.handle_cast({:send_node, %Node{tag: "iq"}}, state)
    assert_receive {:ex_wapp_transport, {:error, :not_connected}}
    assert {:ok, ^state} = WebSocket.handle_cast({:send_payload, "hello"}, state)
    assert_receive {:ex_wapp_transport, {:error, :not_connected}}

    assert {:ok, ^state} =
             WebSocket.handle_frame(
               {:binary, Frame.encode("no handshake", include_header: true)},
               state
             )

    assert_receive {:ex_wapp_transport, {:error, :not_connected}}

    assert {:close, _} =
             Conn.handle_frame(
               {:binary, Frame.encode("no handshake", include_header: true)},
               %Conn.State{session: self()}
             )
  end

  defp conn_pair do
    peer = Peer.new()

    initial = %Conn.State{
      session: self(),
      store: Store.Memory.new(),
      noise_opts: [certificate_verifier: Peer.verifier(peer)]
    }

    {:ok, state} = Conn.handle_connect(nil, initial)
    assert_receive {:send_raw_frame, {:binary, client_hello} = raw}
    assert {:reply, ^raw, ^state} = Conn.handle_info({:send_raw_frame, raw}, state)
    {hello, peer} = Peer.hello(peer, Peer.unframe(client_hello))
    bytes = Frame.encode(hello, include_header: true)
    <<prefix::binary-size(2), rest::binary>> = bytes
    assert {:ok, partial} = Conn.handle_frame({:binary, prefix}, state)
    assert {:ok, state} = Conn.handle_frame({:binary, rest}, partial)
    assert_receive {:send_client_finish, {:binary, client_finish} = raw}
    assert {:reply, ^raw, state} = Conn.handle_info({:send_client_finish, raw}, state)
    {keys, payload} = Peer.finish(peer, Peer.unframe(client_finish))

    assert payload.userAgent.appVersion.tertiary ==
             ExWapp.Config.default_client_version().tertiary

    {state, keys}
  end

  defp normalize_node(node), do: node |> Binary.encode!() |> Binary.decode!()
end
