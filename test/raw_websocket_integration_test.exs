defmodule ExWapp.RawWebSocketIntegrationTest do
  use ExUnit.Case, async: true
  alias ExWapp.{Binary, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Test.ProtocolPeer, as: Peer
  alias ExWapp.Transport.{Frame, WebSocket}

  for adapter <- [ExWapp.Client.Transport.RawWebSocket, ExWapp.Client.Transport.WebSocket] do
    @adapter adapter
    test "#{adapter} performs a real WebSocket handshake and closes its socket on disconnect" do
      peer = Peer.new()
      {url, server} = serve(peer)
      client = ExWapp.new(store: Store.Memory)

      client = %{
        client
        | metadata: %{websocket: [url: url, noise: [certificate_verifier: Peer.verifier(peer)]]}
      }

      assert {:ok, connected} = apply(@adapter, :connect, [client])
      pid = connected.metadata.transport_pid
      on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid, :normal) end)
      assert_receive {:ex_wapp_transport, {:handshake, :completed}}, 2000
      assert_receive {:socket_authenticated, ^server, payload}, 1000

      assert payload.userAgent.appVersion.tertiary ==
               ExWapp.Config.default_client_version().tertiary

      assert_receive {:ex_wapp_transport, {:node, %Node{tag: "ack", attrs: %{"id" => "first"}}}},
                     1000

      assert_receive {:ex_wapp_transport, {:error, _}}, 1000

      assert_receive {:ex_wapp_transport,
                      {:node, %Node{tag: "ack", attrs: %{"id" => "after-corruption"}}}},
                     1000

      assert :ok =
               WebSocket.send_node(pid, %Node{tag: "presence", attrs: %{"type" => "available"}})

      assert_receive {:socket_payload, ^server, bytes}, 1000
      assert {:ok, %Node{tag: "presence"}} = Binary.decode(bytes)
      assert :ok = WebSocket.send_payload(pid, "raw transport payload")
      assert_receive {:socket_payload, ^server, "raw transport payload"}, 1000

      assert {:error, :raw_websocket_cannot_send_high_level_messages} =
               apply(@adapter, :send_message, [
                 connected,
                 ExWapp.Message.text("123@s.whatsapp.net", "requires session")
               ])

      monitor = Process.monitor(pid)
      assert {:ok, disconnected} = apply(@adapter, :disconnect, [connected])
      refute Map.has_key?(disconnected.metadata, :transport_pid)
      assert_receive {:DOWN, ^monitor, :process, ^pid, _}, 1000
      assert {:ok, ^disconnected} = apply(@adapter, :disconnect, [disconnected])
    end
  end

  test "a refused WebSocket connection returns an adapter error" do
    {:ok, listener} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
    {:ok, {_, port}} = :inet.sockname(listener)
    :gen_tcp.close(listener)
    client = ExWapp.new(store: Store.Memory)
    client = %{client | metadata: %{websocket: [url: "ws://127.0.0.1:#{port}/ws"]}}
    assert {:error, _} = ExWapp.Client.Transport.RawWebSocket.connect(client)
  end

  defp serve(peer) do
    {:ok, listener} =
      :gen_tcp.listen(0, [:binary, active: false, packet: :http_bin, ip: {127, 0, 0, 1}])

    {:ok, {_, port}} = :inet.sockname(listener)
    owner = self()
    supervisor = start_supervised!(Task.Supervisor)

    {:ok, server} =
      Task.Supervisor.start_child(supervisor, fn ->
        {:ok, socket} = :gen_tcp.accept(listener, 10_000)
        {:ok, {:http_request, :GET, _, _}} = :gen_tcp.recv(socket, 0, 5000)
        headers = read_headers(socket, %{})

        accept =
          :crypto.hash(
            :sha,
            headers["sec-websocket-key"] <> "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
          )
          |> Base.encode64()

        :ok =
          :gen_tcp.send(
            socket,
            "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: #{accept}\r\n\r\n"
          )

        :inet.setopts(socket, packet: :raw)
        {:ok, 2, hello} = receive_frame(socket)
        {hello, peer} = Peer.hello(peer, Peer.unframe(hello))
        send_frame(socket, Frame.encode(hello, include_header: true))
        {:ok, 2, finish} = receive_frame(socket)
        {keys, payload} = Peer.finish(peer, Peer.unframe(finish))
        send(owner, {:socket_authenticated, self(), payload})

        frames =
          Frame.encode(
            Peer.encrypt(
              keys.write,
              0,
              Binary.encode!(%Node{tag: "ack", attrs: %{"id" => "first"}})
            )
          ) <>
            Frame.encode(<<0, 1>>) <>
            Frame.encode(
              Peer.encrypt(
                keys.write,
                2,
                Binary.encode!(%Node{tag: "ack", attrs: %{"id" => "after-corruption"}})
              )
            )

        send_frame(socket, frames)
        receive_payloads(socket, keys.read, 0, owner)
      end)

    on_exit(fn -> :gen_tcp.close(listener) end)
    {"ws://127.0.0.1:#{port}/ws", server}
  end

  defp receive_payloads(socket, key, counter, owner) do
    case receive_frame(socket) do
      {:ok, 2, frame} ->
        send(owner, {:socket_payload, self(), Peer.decrypt(key, counter, Peer.unframe(frame))})
        receive_payloads(socket, key, counter + 1, owner)

      {:ok, 8, _} ->
        :gen_tcp.send(socket, <<136, 0>>)
        :gen_tcp.close(socket)

      {:error, :closed} ->
        :ok
    end
  end

  defp receive_frame(socket) do
    with {:ok, <<1::1, 0::3, opcode::4, 1::1, size::7>>} <- :gen_tcp.recv(socket, 2, 5000) do
      size =
        case size do
          126 ->
            {:ok, <<size::16>>} = :gen_tcp.recv(socket, 2, 5000)
            size

          127 ->
            {:ok, <<size::64>>} = :gen_tcp.recv(socket, 8, 5000)
            size

          size ->
            size
        end

      {:ok, mask} = :gen_tcp.recv(socket, 4, 5000)
      data = if size == 0, do: <<>>, else: elem(:gen_tcp.recv(socket, size, 5000), 1)

      payload =
        for {byte, index} <- Enum.with_index(:binary.bin_to_list(data)),
            into: <<>>,
            do: <<Bitwise.bxor(byte, :binary.at(mask, rem(index, 4)))>>

      {:ok, opcode, payload}
    end
  end

  defp send_frame(socket, payload) do
    size = byte_size(payload)
    header = if size < 126, do: <<130, size>>, else: <<130, 126, size::16>>
    :gen_tcp.send(socket, [header, payload])
  end

  defp read_headers(socket, acc) do
    case :gen_tcp.recv(socket, 0, 5000) do
      {:ok, {:http_header, _, key, _, value}} ->
        read_headers(socket, Map.put(acc, String.downcase(to_string(key)), value))

      {:ok, :http_eoh} ->
        acc
    end
  end
end
