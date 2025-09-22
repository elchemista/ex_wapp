defmodule ExWapp.Noise do
  @moduledoc """
  Implements the Noise_XX_25519_AESGCM_SHA256 handshake used by WhatsApp Web.

  The module exposes helpers to produce the client hello, process the server
  hello (including certificate verification) and to encrypt/decrypt transport
  payloads once the handshake completes.
  """

  alias ExWapp.Noise.{ClientPayload, Handshake}
  alias ExWapp.Store
  alias ExWapp.Transport.Frame

  alias WAWebProtobufsWa6.HandshakeMessage

  defstruct handshake: nil,
            phase: :handshake,
            eph_priv: nil,
            eph_pub: nil,
            static_key: nil,
            tx_key: nil,
            rx_key: nil,
            tx_counter: 0,
            rx_counter: 0,
            store: nil,
            client_payload_fun: nil

  @type t :: %__MODULE__{
          handshake: Handshake.t() | nil,
          phase: :handshake | :transport,
          eph_priv: binary() | nil,
          eph_pub: binary() | nil,
          static_key: %{priv: binary(), pub: binary()} | nil,
          tx_key: binary() | nil,
          rx_key: binary() | nil,
          tx_counter: non_neg_integer(),
          rx_counter: non_neg_integer(),
          store: Store.t() | nil,
          client_payload_fun:
            nil
            | (t() ->
                 binary() | {:ok, binary()} | {:error, term()} | {:ok, binary(), Store.data()})
        }

  @noise_pattern "Noise_XX_25519_AESGCM_SHA256\x00\x00\x00\x00"

  @doc """
  Initialises a new Noise handshake state.

  Returns the binary client hello frame that must be sent immediately together
  with the updated state.
  """
  @spec init(keyword()) :: {:ok, binary(), t()} | {:error, term()}
  def init(opts) do
    with {:ok, store} <- Keyword.fetch(opts, :store) do
      header = Keyword.get(opts, :header, Frame.header())
      client_payload_fun = Keyword.get(opts, :client_payload_fun, &ClientPayload.build/1)

      {:ok, static_key} = ensure_static_key(store)

      {eph_pub, eph_priv} = :crypto.generate_key(:ecdh, :x25519)

      handshake =
        Handshake.new(@noise_pattern, header)
        |> Handshake.authenticate(eph_pub)

      message = %HandshakeMessage{
        clientHello: %HandshakeMessage.ClientHello{
          ephemeral: eph_pub
        }
      }

      case HandshakeMessage.encode(message) do
        {:ok, iodata} ->
          payload = IO.iodata_to_binary(iodata)

          state = %__MODULE__{
            handshake: handshake,
            eph_priv: eph_priv,
            eph_pub: eph_pub,
            static_key: static_key,
            store: store,
            client_payload_fun: client_payload_fun
          }

          {:ok, payload, state}

        {:error, reason} ->
          {:error, {:encode_client_hello, reason}}
      end
    else
      :error -> {:error, :missing_store}
    end
  end

  @doc """
  Processes the server hello frame and returns the client finish frame together
  with the updated Noise state (now ready for transport encryption/decryption).
  """
  @spec handle_server_hello(t(), binary()) :: {:ok, binary(), t()} | {:error, term()}
  def handle_server_hello(%__MODULE__{phase: :handshake} = state, payload)
      when is_binary(payload) do
    with {:ok, message} <- HandshakeMessage.decode(payload),
         %HandshakeMessage{serverHello: server_hello} when not is_nil(server_hello) <- message,
         {:ok, new_state, client_finish} <- do_server_hello(state, server_hello) do
      {:ok, client_finish, new_state}
    else
      %HandshakeMessage{serverHello: nil} -> {:error, :missing_server_hello}
      {:error, _} = error -> error
      other -> {:error, {:unexpected_message, other}}
    end
  end

  def handle_server_hello(_state, _payload), do: {:error, :invalid_state}

  @doc """
  Encrypts a transport payload once the handshake has completed.
  """
  @spec encrypt(t(), binary()) :: {:ok, binary(), t()} | {:error, term()}
  def encrypt(%__MODULE__{phase: :transport, tx_key: key} = state, plaintext)
      when is_binary(plaintext) do
    iv = build_nonce(state.tx_counter)

    {ciphertext, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, <<>>, true)

    new_state = %{state | tx_counter: state.tx_counter + 1}
    {:ok, ciphertext <> tag, new_state}
  end

  def encrypt(_state, _plaintext), do: {:error, :invalid_state}

  @doc """
  Decrypts a transport payload once the handshake has completed.
  """
  @spec decrypt(t(), binary()) :: {:ok, binary(), t()} | {:error, term()}
  def decrypt(%__MODULE__{phase: :transport, rx_key: key} = state, payload)
      when is_binary(payload) do
    case split_cipher_and_tag(payload) do
      {:ok, cipher, tag} ->
        iv = build_nonce(state.rx_counter)

        case :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, cipher, <<>>, tag, false) do
          plaintext when is_binary(plaintext) ->
            new_state = %{state | rx_counter: state.rx_counter + 1}
            {:ok, plaintext, new_state}

          :error ->
            {:error, :decrypt_failed}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def decrypt(_state, _payload), do: {:error, :invalid_state}

  defp do_server_hello(state, server_hello) do
    with {:ok, handshake, server_ephemeral} <-
           read_server_ephemeral(state.handshake, server_hello.ephemeral),
         {:ok, handshake, server_static} <-
           decrypt_static(handshake, state.eph_priv, server_ephemeral, server_hello.static),
         {:ok, handshake} <- verify_certificate(handshake, server_static, server_hello.payload),
         {:ok, handshake, encrypted_static} <- encrypt_static(handshake, state.static_key.pub),
         {:ok, handshake} <-
           Handshake.mix_shared_secret(handshake, state.static_key.priv, server_ephemeral),
         {:ok, payload} <- build_client_payload(state),
         {handshake, encrypted_payload} <- Handshake.encrypt(handshake, payload),
         {:ok, client_finish} <- encode_client_finish(encrypted_static, encrypted_payload),
         {tx_key, rx_key} <- Handshake.derive_transport_keys(handshake) do
      new_state =
        %{
          state
          | phase: :transport,
            handshake: nil,
            eph_priv: nil,
            eph_pub: nil,
            tx_key: tx_key,
            rx_key: rx_key,
            tx_counter: 0,
            rx_counter: 0
        }

      {:ok, new_state, client_finish}
    end
  end

  defp read_server_ephemeral(handshake, server_ephemeral)
       when byte_size(server_ephemeral) == 32 do
    handshake = Handshake.authenticate(handshake, server_ephemeral)
    {:ok, handshake, server_ephemeral}
  end

  defp read_server_ephemeral(_handshake, _), do: {:error, :invalid_server_ephemeral}

  defp decrypt_static(handshake, eph_priv, server_ephemeral, static_cipher) do
    with {:ok, handshake} <- Handshake.mix_shared_secret(handshake, eph_priv, server_ephemeral),
         {:ok, handshake, static_plain} <- Handshake.decrypt(handshake, static_cipher),
         true <- byte_size(static_plain) == 32 || {:error, :invalid_static_key},
         {:ok, handshake} <- Handshake.mix_shared_secret(handshake, eph_priv, static_plain) do
      {:ok, handshake, static_plain}
    end
  end

  defp verify_certificate(handshake, static_plain, payload_cipher) do
    with {:ok, handshake, cert_bytes} <- Handshake.decrypt(handshake, payload_cipher),
         :ok <- ExWapp.Noise.Certificate.verify(cert_bytes, static_plain) do
      {:ok, handshake}
    end
  end

  defp encrypt_static(handshake, static_pub) do
    {handshake, ciphertext} = Handshake.encrypt(handshake, static_pub)
    {:ok, handshake, ciphertext}
  end

  defp encode_client_finish(encrypted_static, encrypted_payload) do
    message = %HandshakeMessage{
      clientFinish: %HandshakeMessage.ClientFinish{
        static: encrypted_static,
        payload: encrypted_payload
      }
    }

    with {:ok, iodata} <- HandshakeMessage.encode(message) do
      {:ok, IO.iodata_to_binary(iodata)}
    end
  end

  defp build_client_payload(%__MODULE__{client_payload_fun: fun} = state)
       when is_function(fun, 1) do
    case fun.(state) do
      {:ok, payload} when is_binary(payload) ->
        {:ok, payload}

      {:ok, payload, data} when is_binary(payload) ->
        maybe_persist(state.store, data)
        {:ok, payload}

      {:error, _} = error ->
        error

      payload when is_binary(payload) ->
        {:ok, payload}

      other ->
        {:error, {:invalid_payload, other}}
    end
  end

  defp build_client_payload(%__MODULE__{}), do: {:ok, <<>>}

  defp ensure_static_key(store) do
    data = Store.load!(store)

    case data[:noise] do
      %{static_private: priv, static_public: pub} when is_binary(priv) and is_binary(pub) ->
        {:ok, %{priv: priv, pub: pub}}

      _ ->
        {pub, priv} = :crypto.generate_key(:ecdh, :x25519)
        noise_map = %{static_private: priv, static_public: pub}
        :ok = Store.persist(store, Map.put(data, :noise, noise_map))
        {:ok, %{priv: priv, pub: pub}}
    end
  end

  defp maybe_persist(store, data) when is_map(data), do: Store.persist(store, data)
  defp maybe_persist(_store, _data), do: :ok

  defp build_nonce(counter), do: <<0::unsigned-size(64), counter::unsigned-size(32)>>

  defp split_cipher_and_tag(payload) when byte_size(payload) >= 16 do
    tag_size = 16
    cipher_size = byte_size(payload) - tag_size
    <<cipher::binary-size(cipher_size), tag::binary-size(tag_size)>> = payload
    {:ok, cipher, tag}
  end

  defp split_cipher_and_tag(_payload), do: {:error, :ciphertext_too_short}
  @doc false
  def new, do: {:error, :deprecated_interface}

  @doc false
  def handle_incoming(_state, _payload), do: {:error, :deprecated_interface}

  @doc false
  def wrap_outgoing(_state, _payload), do: {:error, :deprecated_interface}
end
