defmodule ExWapp.ConnRestartStreamTest do
  @moduledoc """
  Coverage for the `:restart_stream` cast in `ExWapp.Conn`.

  WebSockex accepts `{:ok, state}` or `{:reply, frame, state}` from
  `handle_cast/2` — a `{:noreply, state}` is a badreply that terminates the
  connection process, and a *list* of frames dies inside `Frame.encode_frame`
  and closes the socket. This handler used to return one or the other on every
  path, so any stream restart killed the connection it was trying to revive.
  """

  use ExUnit.Case, async: true

  alias ExWapp.Conn
  alias ExWapp.Conn.State
  alias ExWapp.Noise
  alias ExWapp.Store

  test "a restart in transport phase replies with exactly one frame tuple" do
    state = %State{
      session: self(),
      store: Store.new(Store.Memory),
      noise: transport_noise(),
      header_sent?: true,
      stream_started?: true
    }

    assert {:reply, {:binary, frame}, new_state} = Conn.handle_cast(:restart_stream, state)
    assert is_binary(frame)
    assert new_state.stream_started?
  end

  test "a restart before the handshake completes is acknowledged without a reply" do
    state = %State{session: self(), store: Store.new(Store.Memory), noise: nil}

    assert {:ok, new_state} = Conn.handle_cast(:restart_stream, state)
    refute new_state.stream_started?
  end

  test "stream restart preserves the configured resource on the wire" do
    for {info, resource} <- [
          {%{stream_resource: "custom", device_name: "fallback"}, "custom"},
          {%{device_name: "desktop", phone_id: "fallback"}, "desktop"},
          {%{phone_id: "phone"}, "phone"}
        ] do
      store = Store.Memory.new(initial_data: %{client_info: info})
      on_exit(fn -> Store.Memory.stop(store) end)
      noise = transport_noise()
      {write, _read, _hash} = noise.cipher_ref
      state = %State{session: self(), store: store, noise: noise, header_sent?: true}

      assert {:reply, {:binary, frame}, updated} = Conn.handle_cast(:restart_stream, state)

      plain =
        ExWapp.Test.ProtocolPeer.decrypt(write.key, 0, ExWapp.Test.ProtocolPeer.unframe(frame))

      assert %{tag: "xmlstreamstart", attrs: attrs} = ExWapp.Binary.decode!(plain)
      assert attrs["resource"] == resource
      assert updated.noise.tx_counter == 1
    end
  end

  test "an exhausted nonce cannot emit a message or restart frame" do
    store = Store.Memory.new()
    on_exit(fn -> Store.Memory.stop(store) end)
    noise = transport_noise()
    {write, read, hash} = noise.cipher_ref

    noise = %{
      noise
      | tx_counter: 0x1_0000_0000,
        cipher_ref: {%{write | counter: 0x1_0000_0000}, read, hash}
    }

    state = %State{session: self(), store: store, noise: noise}
    node = %ExWapp.Binary.Node{tag: "presence", attrs: %{"type" => "available"}}

    assert {:ok, ^state} = Conn.handle_cast({:send_node, node}, state)
    assert_receive {:connection_event, {:error, :counter_exhausted}}
    assert {:ok, updated} = Conn.handle_cast(:restart_stream, state)
    refute updated.stream_started?
    assert updated.noise == noise
  end

  test "bad authenticated frames do not rewind the connection nonce or hide later messages" do
    alias ExWapp.Test.ProtocolPeer
    alias ExWapp.Transport.Frame
    noise = transport_noise()
    {_write, read, _hash} = noise.cipher_ref
    state = %State{session: self(), noise: noise}
    node = %ExWapp.Binary.Node{tag: "ack", attrs: %{"id" => "after-corruption"}}
    good = ProtocolPeer.encrypt(read.key, 1, ExWapp.Binary.encode!(node))

    # No WA header: an already established transport can begin directly with frames.
    assert {:ok, updated} =
             Conn.handle_frame({:binary, Frame.encode(<<1, 2>>) <> Frame.encode(good)}, state)

    assert_receive {:connection_event, {:error, {:decrypt_failed, _, <<1, 2>>}}}
    assert_receive {:connection_event, {:connection_message, ^node}}
    assert updated.noise.rx_counter == 2
    assert updated.buffer == <<>>
  end

  test "pre-handshake sends and unrelated callbacks leave connection state intact" do
    state = %State{session: self(), noise: %Noise{}}

    assert {:ok, ^state} =
             Conn.handle_cast({:send_node, %ExWapp.Binary.Node{tag: "message"}}, state)

    assert {:ok, ^state} = Conn.handle_info({:unrelated, "private"}, state)
    assert {:ok, ^state} = Conn.handle_frame({:text, "private"}, state)
    refute_received {:connection_event, _}
  end

  test "a transport without usable ciphers reports decryption failure to its session" do
    noise = %Noise{phase: :transport}
    state = %State{session: self(), noise: noise, header_seen?: true}

    assert {:ok, ^state} =
             Conn.handle_frame({:binary, ExWapp.Transport.Frame.encode(<<1, 2>>)}, state)

    assert_receive {:connection_event, {:error, {:decrypt_failed, :invalid_state, <<1, 2>>}}}
  end

  defp transport_noise do
    %Noise{
      phase: :transport,
      cipher_ref: {
        %{key: :crypto.strong_rand_bytes(32), counter: 0},
        %{key: :crypto.strong_rand_bytes(32), counter: 0},
        :crypto.strong_rand_bytes(32)
      },
      tx_counter: 0,
      rx_counter: 0
    }
  end
end
