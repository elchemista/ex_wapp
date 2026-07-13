defmodule ExWapp.Noise.Engine do
  @moduledoc """
  Pure Elixir implementation of the Noise handshake engine.
  """

  alias ExWapp.Noise.Handshake
  alias ExWapp.Noise.HandshakeSecrets
  alias ExWapp.Transport.Frame
  alias WAWebProtobufsWa6.HandshakeMessage
  alias WAWebProtobufsWa6.HandshakeMessage.ClientFinish
  alias WAWebProtobufsWa6.HandshakeMessage.ClientHello
  alias WAWebProtobufsWa6.HandshakeMessage.ServerHello

  require Logger

  @prologue "Noise_XX_25519_AESGCM_SHA256\x00\x00\x00\x00"

  defmodule State do
    @moduledoc """
    Mutable state passed between Noise XX handshake steps.

    It keeps ephemeral and static key pairs, the transcript state, and the server
    identity material required to derive transport keys.
    """
    defstruct [
      :noise,
      :e_kp,
      :s_kp,
      :payload,
      :server_static,
      :server_cert
    ]
  end

  def init_handshake(payload, static_key, opts) do
    s_kp = ensure_keypair(static_key)
    e_kp = ExWapp.Signal.Keys.generate_key_pair()

    wa_header = Keyword.get(opts, :handshake_header, Frame.header())

    noise = Handshake.new(@prologue, wa_header)
    noise = Handshake.authenticate(noise, e_kp.public)

    Logger.debug(
      "[NOISE] engine init: header=#{Base.encode16(wa_header, case: :lower)} eph_pub=#{Base.encode16(e_kp.public, case: :lower)} payload_len=#{byte_size(payload)}"
    )

    state = %State{
      noise: noise,
      e_kp: e_kp,
      s_kp: s_kp,
      payload: payload
    }

    client_hello = build_client_hello(e_kp.public)

    {:ok, state, client_hello, %{priv: s_kp.private, pub: s_kp.public}}
  end

  def write_client_finish(%State{} = state, server_hello_payload) do
    with {:ok, server_hello} <- decode_server_hello(server_hello_payload) do
      process_server_hello(state, server_hello)
    end
  end

  def complete_handshake(%State{} = state) do
    {write_key, read_key} = Handshake.derive_transport_keys(state.noise)

    secrets = %HandshakeSecrets{
      write_key: write_key,
      read_key: read_key,
      handshake_hash: state.noise.hash,
      handshake_salt: state.noise.salt,
      server_static: state.server_static,
      server_certificate: state.server_cert
    }

    {:ok, secrets}
  end

  def setup_transport(%HandshakeSecrets{} = secrets) do
    write_cipher = %{key: secrets.write_key, counter: 0}
    read_cipher = %{key: secrets.read_key, counter: 0}

    {:ok, {write_cipher, read_cipher, secrets.handshake_hash}}
  end

  def encrypt({write_cipher, read_cipher, hash}, plaintext, _counter) do
    {ciphertext, new_write_cipher} = encrypt_payload(write_cipher, hash, plaintext)
    {:ok, {new_write_cipher, read_cipher, hash}, ciphertext}
  end

  def decrypt({write_cipher, read_cipher, hash}, ciphertext, _counter) do
    with {:ok, plaintext, new_read_cipher} <- decrypt_payload(read_cipher, hash, ciphertext) do
      {:ok, {write_cipher, new_read_cipher, hash}, plaintext}
    end
  end

  defp ensure_keypair(%{priv: priv, pub: pub}), do: %{private: priv, public: pub}
  defp ensure_keypair(_), do: ExWapp.Signal.Keys.generate_key_pair()

  defp build_client_hello(ephemeral_public) do
    msg = %HandshakeMessage{
      clientHello: %ClientHello{
        ephemeral: ephemeral_public
      }
    }

    HandshakeMessage.encode!(msg) |> IO.iodata_to_binary()
  end

  defp decode_server_hello(payload) do
    case HandshakeMessage.decode(payload) do
      {:ok, %HandshakeMessage{serverHello: %ServerHello{} = hello}} -> {:ok, hello}
      {:ok, _} -> {:error, :missing_server_hello}
      {:error, _} = err -> err
    end
  end

  defp process_server_hello(state, %ServerHello{ephemeral: re, static: rs_ct, payload: cert_ct}) do
    Logger.debug(
      "process_server_hello: got server hello eph_len=#{byte_size(re)} static_len=#{byte_size(rs_ct)} cert_len=#{byte_size(cert_ct)}"
    )

    Logger.debug("server ephemeral: #{Base.encode16(re, case: :lower)}")
    Logger.debug("our ephemeral private: #{Base.encode16(state.e_kp.private, case: :lower)}")
    Logger.debug("our static public: #{Base.encode16(state.s_kp.public, case: :lower)}")

    noise = Handshake.authenticate(state.noise, re)

    with {:ok, noise} <- Handshake.mix_shared_secret(noise, state.e_kp.private, re),
         {:ok, noise, rs} <- Handshake.decrypt(noise, rs_ct),
         {:ok, noise} <- Handshake.mix_shared_secret(noise, state.e_kp.private, rs),
         {:ok, noise, cert} <- Handshake.decrypt(noise, cert_ct),
         {noise, s_pub_ct} <- Handshake.encrypt(noise, state.s_kp.public),
         {:ok, noise} <- Handshake.mix_shared_secret(noise, state.s_kp.private, re),
         {noise, payload_ct} <- Handshake.encrypt(noise, state.payload) do
      client_finish = build_client_finish(s_pub_ct, payload_ct)

      new_state = %{state | noise: noise, server_static: rs, server_cert: cert}

      Logger.debug(
        "process_server_hello: decrypted static=#{Base.encode16(rs, case: :lower)} cert_len=#{byte_size(cert)} client_finish_len=#{byte_size(client_finish)}"
      )

      Logger.debug(
        "encrypted static (s_pub_ct) len=#{byte_size(s_pub_ct)}: #{Base.encode16(s_pub_ct, case: :lower)}"
      )

      Logger.debug("encrypted payload len=#{byte_size(payload_ct)}")
      Logger.debug("payload plaintext len=#{byte_size(state.payload)}")
      Logger.debug("client_finish total len=#{byte_size(client_finish)}")

      Logger.debug(
        "client_finish hex (first 100): #{Base.encode16(client_finish, case: :lower) |> String.slice(0, 100)}..."
      )

      {:ok, new_state, client_finish}
    else
      {:error, reason} ->
        Logger.error("process_server_hello failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp build_client_finish(static_ct, payload_ct) do
    msg = %HandshakeMessage{
      clientFinish: %ClientFinish{
        static: static_ct,
        payload: payload_ct
      }
    }

    HandshakeMessage.encode!(msg) |> IO.iodata_to_binary()
  end

  defp encrypt_payload(%{key: key, counter: counter} = cipher, _hash, plaintext) do
    iv = generate_iv(counter)

    {cipher_body, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, <<>>, true)

    payload = cipher_body <> tag
    {payload, %{cipher | counter: counter + 1}}
  end

  defp decrypt_payload(%{key: key, counter: counter} = cipher, _hash, ciphertext) do
    tag_len = 16

    if byte_size(ciphertext) < tag_len do
      {:error, :decrypt_failed}
    else
      body_len = byte_size(ciphertext) - tag_len
      <<body::binary-size(^body_len), tag::binary-size(^tag_len)>> = ciphertext

      iv = generate_iv(counter)

      case :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, body, <<>>, tag, false) do
        plaintext when is_binary(plaintext) ->
          {:ok, plaintext, %{cipher | counter: counter + 1}}

        :error ->
          {:error, :decrypt_failed}
      end
    end
  end

  defp generate_iv(counter) do
    <<0::size(64), counter::big-unsigned-32>>
  end
end
