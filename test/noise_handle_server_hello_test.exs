defmodule ExWapp.NoiseHandleServerHelloTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias ExWapp.Noise
  alias ExWapp.Noise.Handshake
  alias ExWapp.Store
  alias ExWapp.Transport.Frame

  alias WAWebProtobufsWa6.HandshakeMessage

  @noise_pattern "Noise_XX_25519_AESGCM_SHA256\x00\x00\x00\x00"

  describe "handle_server_hello/2" do
    test "completes the handshake and derives usable transport keys" do
      parent = self()
      certificate_plain = "test-cert"

      verifier = fn cert_bytes, static_plain ->
        send(parent, {:cert_verified, cert_bytes, static_plain})
        :ok
      end

      store = store_fixture()

      {:ok, _hello, noise} =
        Noise.init(
          store: store,
          certificate_verifier: verifier
        )

      server = build_server_hello(noise, certificate_plain)

      assert {:ok, client_finish, new_noise} = Noise.handle_server_hello(noise, server.payload)
      assert byte_size(client_finish) > 300

      static_pub = server.static_pub
      assert_receive {:cert_verified, ^certificate_plain, ^static_pub}

      assert new_noise.phase == :transport
      assert new_noise.tx_counter == 0
      assert new_noise.rx_counter == 0
      assert byte_size(new_noise.tx_key) == 32
      assert byte_size(new_noise.rx_key) == 32

      {:ok, server_keys} = process_client_finish(server, client_finish)
      assert new_noise.tx_key == server_keys.read_key
      assert new_noise.rx_key == server_keys.write_key

      assert_encryption_round_trip(new_noise, server_keys)
    end
  end

  defp build_server_hello(%Noise{eph_pub: client_ephemeral}, certificate_plain) do
    {server_ephemeral_pub, server_ephemeral_priv} = :crypto.generate_key(:ecdh, :x25519)
    {server_static_pub, server_static_priv} = :crypto.generate_key(:ecdh, :x25519)

    handshake =
      Handshake.new(@noise_pattern, Frame.header())
      |> Handshake.authenticate(client_ephemeral)
      |> Handshake.authenticate(server_ephemeral_pub)

    {:ok, handshake} =
      Handshake.mix_shared_secret(handshake, server_ephemeral_priv, client_ephemeral)

    {handshake, static_cipher} = Handshake.encrypt(handshake, server_static_pub)

    {:ok, handshake} =
      Handshake.mix_shared_secret(handshake, server_static_priv, client_ephemeral)

    {handshake, payload_cipher} = Handshake.encrypt(handshake, certificate_plain)

    server_hello = %HandshakeMessage.ServerHello{
      ephemeral: server_ephemeral_pub,
      static: static_cipher,
      payload: payload_cipher
    }

    {:ok, message_io} = HandshakeMessage.encode(%HandshakeMessage{serverHello: server_hello})

    %{
      payload: IO.iodata_to_binary(message_io),
      handshake: handshake,
      eph_priv: server_ephemeral_priv,
      static_priv: server_static_priv,
      static_pub: server_static_pub,
      certificate: certificate_plain
    }
  end

  defp process_client_finish(server, client_finish_payload) do
    {:ok, %HandshakeMessage{clientFinish: client_finish}} =
      HandshakeMessage.decode(client_finish_payload)

    with {:ok, handshake, client_static_pub} <-
           Handshake.decrypt(server.handshake, client_finish.static),
         {:ok, handshake} <-
           Handshake.mix_shared_secret(handshake, server.eph_priv, client_static_pub),
         {:ok, handshake, _payload_plain} <-
           Handshake.decrypt(handshake, client_finish.payload) do
      {write_key, read_key} = Handshake.derive_transport_keys(handshake)

      {:ok, %{write_key: write_key, read_key: read_key}}
    end
  end

  defp assert_encryption_round_trip(noise, %{write_key: server_write, read_key: server_read}) do
    plaintext = "hello"

    assert {:ok, ciphertext, noise_after_tx} = Noise.encrypt(noise, plaintext)

    assert decrypt_with_key(server_read, 0, ciphertext) == plaintext

    reply = "world"

    {server_cipher, server_tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, server_write, nonce(0), reply, <<>>, true)

    server_payload = server_cipher <> server_tag

    assert {:ok, reply_plain, noise_after_rx} = Noise.decrypt(noise_after_tx, server_payload)

    assert reply_plain == reply
    assert noise_after_tx.tx_counter == 1
    assert noise_after_rx.rx_counter == 1
  end

  defp decrypt_with_key(key, counter, payload) do
    <<cipher::binary-size(byte_size(payload) - 16), tag::binary-size(16)>> = payload

    case :crypto.crypto_one_time_aead(:aes_256_gcm, key, nonce(counter), cipher, <<>>, tag, false) do
      :error -> flunk("failed to decrypt test payload")
      plaintext -> plaintext
    end
  end

  defp nonce(counter), do: <<0::unsigned-size(64), counter::unsigned-size(32)>>

  defp store_fixture do
    tmp_dir = Path.join(System.tmp_dir!(), "ex_wapp_tests")
    :ok = File.mkdir_p(tmp_dir)
    path = Path.join(tmp_dir, "store_#{System.unique_integer([:positive])}.etf")

    store = Store.ETS.new(path: path)

    on_exit(fn -> File.rm(path) end)

    store
  end
end
