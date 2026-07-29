defmodule ExWapp.NoiseTransportProtocolTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Bitwise

  alias ExWapp.Binary
  alias ExWapp.Binary.Node
  alias ExWapp.Noise
  alias ExWapp.Noise.Engine
  alias ExWapp.Transport.{Frame, WebSocket}
  alias ExWapp.Transport.WebSocket.State

  test "coalesced encrypted frames decrypt in order and advance RX once each" do
    {sender, receiver} = transport_pair()
    first = %Node{tag: "ack", attrs: %{"id" => "one"}}
    second = %Node{tag: "ack", attrs: %{"id" => "two"}}

    {:ok, first_ciphertext, sender} = Noise.encrypt(sender, Binary.encode!(first))
    {:ok, second_ciphertext, _sender} = Noise.encrypt(sender, Binary.encode!(second))

    bytes =
      Frame.header() <>
        Frame.encode(first_ciphertext) <>
        Frame.encode(second_ciphertext)

    assert {:ok, state, [{:node, ^first}, {:node, ^second}]} =
             WebSocket.receive_bytes(websocket_state(receiver), bytes)

    assert state.noise.rx_counter == 2
    assert read_counter(state.noise) == 2
  end

  test "one encrypted frame survives every split around header, length and tag" do
    expected = %Node{tag: "notification", attrs: %{"id" => "split"}}

    for split <- 0..70 do
      {sender, receiver} = transport_pair()
      {:ok, ciphertext, _sender} = Noise.encrypt(sender, Binary.encode!(expected))
      encoded = Frame.header() <> Frame.encode(ciphertext)
      split = min(split, byte_size(encoded))
      <<first_part::binary-size(^split), second_part::binary>> = encoded

      assert {:ok, state, first_events} =
               WebSocket.receive_bytes(websocket_state(receiver), first_part)

      assert {:ok, state, second_events} = WebSocket.receive_bytes(state, second_part)
      assert first_events ++ second_events == [{:node, expected}]
      assert state.buffer == <<>>
      assert state.noise.rx_counter == 1
    end
  end

  test "a complete frame followed by a partial frame keeps the next ciphertext buffered" do
    {sender, receiver} = transport_pair()
    first = %Node{tag: "ack", attrs: %{"id" => "first"}}
    second = %Node{tag: "ack", attrs: %{"id" => "second"}}

    {:ok, first_ciphertext, sender} = Noise.encrypt(sender, Binary.encode!(first))
    {:ok, second_ciphertext, _sender} = Noise.encrypt(sender, Binary.encode!(second))
    second_frame = Frame.encode(second_ciphertext)
    partial_size = 5
    <<second_prefix::binary-size(^partial_size), second_tail::binary>> = second_frame

    initial_bytes = Frame.header() <> Frame.encode(first_ciphertext) <> second_prefix

    assert {:ok, state, [{:node, ^first}]} =
             WebSocket.receive_bytes(websocket_state(receiver), initial_bytes)

    assert state.buffer == second_prefix
    assert state.noise.rx_counter == 1

    assert {:ok, state, [{:node, ^second}]} = WebSocket.receive_bytes(state, second_tail)
    assert state.buffer == <<>>
    assert state.noise.rx_counter == 2
  end

  test "a frame that fails authentication still consumes its nonce" do
    # The peer advances its write counter for every frame it sends, whether or
    # not we manage to read it. A receiver that keeps the old nonce after a bad
    # frame decrypts every later frame against the wrong counter — one
    # corrupted frame silently kills all inbound traffic on a connection that
    # still looks alive. Both whatsmeow and whatsapp-rust consume the counter
    # before attempting decryption.
    {sender, receiver} = transport_pair()
    {:ok, first_ciphertext, sender} = Noise.encrypt(sender, "first")
    {:ok, second_ciphertext, _sender} = Noise.encrypt(sender, "second")
    tampered = flip_last_byte(first_ciphertext)

    assert {:error, {:decrypt_failed, :decrypt_failed}, receiver} =
             Noise.decrypt(receiver, tampered)

    assert receiver.rx_counter == 1
    assert read_counter(receiver) == 1

    # "second" was written with counter 1; only a receiver that burned
    # counter 0 on the bad frame can still read it.
    assert {:ok, "second", receiver} = Noise.decrypt(receiver, second_ciphertext)
    assert receiver.rx_counter == 2
  end

  test "a too-short ciphertext consumes its nonce like any other frame" do
    {sender, receiver} = transport_pair()
    {:ok, _skipped, sender} = Noise.encrypt(sender, "lost to truncation")
    {:ok, next_ciphertext, _sender} = Noise.encrypt(sender, "next")

    assert {:error, {:decrypt_failed, :ciphertext_too_short}, receiver} =
             Noise.decrypt(receiver, <<1, 2>>)

    assert receiver.rx_counter == 1
    assert {:ok, "next", _receiver} = Noise.decrypt(receiver, next_ciphertext)
  end

  test "a bad frame in the middle of a batch does not take the rest of the batch with it" do
    # One websocket message can carry several noise frames. An error return
    # from the middle of the batch used to roll the whole transport state back
    # to before the message: nodes already decoded were dropped and the read
    # counter reverted, so every subsequent frame failed AEAD forever after.
    {sender, receiver} = transport_pair()
    first = %Node{tag: "ack", attrs: %{"id" => "before"}}
    third = %Node{tag: "ack", attrs: %{"id" => "after"}}

    {:ok, first_ciphertext, sender} = Noise.encrypt(sender, Binary.encode!(first))
    {:ok, second_ciphertext, sender} = Noise.encrypt(sender, Binary.encode!(%Node{tag: "iq"}))
    {:ok, third_ciphertext, _sender} = Noise.encrypt(sender, Binary.encode!(third))

    bytes =
      Frame.header() <>
        Frame.encode(first_ciphertext) <>
        Frame.encode(flip_last_byte(second_ciphertext)) <>
        Frame.encode(third_ciphertext)

    assert {:ok, state, events} = WebSocket.receive_bytes(websocket_state(receiver), bytes)

    assert [{:node, ^first}, {:error, {:decrypt_failed, :decrypt_failed}}, {:node, ^third}] =
             events

    assert state.noise.rx_counter == 3
    assert read_counter(state.noise) == 3
  end

  test "transport nonce encoding covers byte boundaries and rejects reuse after uint32 max" do
    for counter <- [0, 1, 255, 256, 0xFFFF_FFFF] do
      assert {:ok, nonce} = Engine.transport_nonce(counter)
      assert nonce == <<0::64, counter::unsigned-big-32>>
    end

    assert {:error, :counter_exhausted} = Engine.transport_nonce(0x1_0000_0000)

    {sender, _receiver} = transport_pair(write_counter: 0xFFFF_FFFF)
    assert {:ok, _ciphertext, exhausted} = Noise.encrypt(sender, "last nonce")
    assert exhausted.tx_counter == 0x1_0000_0000
    assert {:error, :counter_exhausted} = Noise.encrypt(exhausted, "must reconnect")
  end

  test "frame encoder rejects payloads that do not fit the 24-bit length" do
    assert Frame.max_payload_size() == 0xFF_FFFF
    oversized = :binary.copy(<<0>>, Frame.max_payload_size() + 1)

    assert_raise ArgumentError, ~r/exceeds 24-bit limit/, fn ->
      Frame.encode(oversized)
    end
  end

  defp transport_pair(opts \\ []) do
    key = :crypto.strong_rand_bytes(32)
    other_key = :crypto.strong_rand_bytes(32)
    hash = :crypto.strong_rand_bytes(32)
    write_counter = Keyword.get(opts, :write_counter, 0)

    sender = %Noise{
      phase: :transport,
      cipher_ref: {
        %{key: key, counter: write_counter},
        %{key: other_key, counter: 0},
        hash
      },
      tx_counter: write_counter,
      rx_counter: 0
    }

    receiver = %Noise{
      phase: :transport,
      cipher_ref: {
        %{key: other_key, counter: 0},
        %{key: key, counter: 0},
        hash
      },
      tx_counter: 0,
      rx_counter: 0
    }

    {sender, receiver}
  end

  defp websocket_state(noise) do
    client = ExWapp.new(store: ExWapp.Store.Memory, session_id: "noise-transport-test")
    %State{client: client, owner: self(), noise: noise}
  end

  defp read_counter(%Noise{cipher_ref: {_write, read, _hash}}), do: read.counter

  defp flip_last_byte(binary) do
    size = byte_size(binary) - 1
    <<prefix::binary-size(^size), last>> = binary
    prefix <> <<bxor(last, 1)>>
  end
end
