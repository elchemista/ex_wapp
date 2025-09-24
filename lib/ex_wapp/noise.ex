defmodule ExWapp.Noise do
  @moduledoc """
  Implements the Noise_XX_25519_AESGCM_SHA256 handshake used by WhatsApp Web.

  The module exposes helpers to produce the client hello, process the server
  hello (including certificate verification) and to encrypt/decrypt transport
  payloads once the handshake completes.
  """

  alias ExWapp.Nif
  alias ExWapp.Nif.Secrets
  alias ExWappNif.NoiseKeys
  alias ExWapp.Noise.ClientPayload
  alias ExWapp.Store
  alias WAWebProtobufsWa6.HandshakeMessage
  require Logger

  defstruct phase: :handshake,
            handshake_ref: nil,
            static_key: nil,
            tx_key: nil,
            rx_key: nil,
            tx_counter: 0,
            rx_counter: 0,
            store: nil,
            client_payload_fun: nil,
            certificate_verifier: nil,
            pending_store_data: nil,
            handshake_hash: nil,
            handshake_salt: nil,
            cipher_ref: nil

  @type certificate_verifier_fun :: (binary(), binary() -> :ok | {:error, term()})

  @type t :: %__MODULE__{
          phase: :handshake | :transport,
          handshake_ref: reference() | nil,
          static_key: %{priv: binary(), pub: binary()} | nil,
          tx_key: binary() | nil,
          rx_key: binary() | nil,
          tx_counter: non_neg_integer(),
          rx_counter: non_neg_integer(),
          store: Store.t() | nil,
          client_payload_fun:
            nil
            | (t() ->
                 binary()
                 | {:ok, binary()}
                 | {:error, term()}
                 | {:ok, binary(), Store.data()}),
          certificate_verifier: certificate_verifier_fun() | nil,
          pending_store_data: Store.data() | nil,
          handshake_hash: binary() | nil,
          handshake_salt: binary() | nil,
          cipher_ref: reference() | nil
        }

  @doc """
  Initialises a new Noise handshake state.

  Returns the binary client hello frame that must be sent immediately together
  with the updated state.
  """
  @spec init(keyword()) :: {:ok, binary(), t()} | {:error, term()}
  def init(opts) do
    with {:ok, store} <- Keyword.fetch(opts, :store) do
      client_payload_fun = Keyword.get(opts, :client_payload_fun, &ClientPayload.build/1)

      certificate_verifier =
        Keyword.get(opts, :certificate_verifier, &ExWapp.Noise.Certificate.verify/2)

      static_key = load_static_key(store)

      base_state = %__MODULE__{
        store: store,
        static_key: static_key,
        client_payload_fun: client_payload_fun,
        certificate_verifier: certificate_verifier
      }

      with {:ok, client_payload, pending_data} <- build_client_payload(base_state),
           {:ok, handshake_ref, client_hello, static_map} <-
             start_handshake(client_payload, static_key),
           :ok <- persist_static_key(store, static_map) do
        state =
          base_state
          |> Map.put(:handshake_ref, handshake_ref)
          |> Map.put(:static_key, static_map)
          |> Map.put(:pending_store_data, pending_data)

        Logger.debug(
          "Handshake client hello (#{byte_size(client_hello)} bytes): #{hex(client_hello)}"
        )

        {:ok, client_hello, state}
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
  def handle_server_hello(%__MODULE__{phase: :handshake, handshake_ref: ref} = state, payload)
      when is_binary(payload) and not is_nil(ref) do
    with {:ok, %HandshakeMessage{serverHello: %HandshakeMessage.ServerHello{}}} <-
           HandshakeMessage.decode(payload),
         {:ok, new_state, client_finish} <- do_server_hello(state, payload) do
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
  def encrypt(%__MODULE__{phase: :transport, cipher_ref: cipher} = state, plaintext)
      when is_binary(plaintext) do
    if is_nil(cipher) do
      {:error, :invalid_state}
    else
      Logger.debug(
        "Noise plaintext (counter=#{state.tx_counter}, #{byte_size(plaintext)} bytes): #{hex(plaintext)}"
      )

      case Nif.noise_encrypt(cipher, plaintext) do
        {:error, reason} ->
          {:error, {:encrypt_failed, reason}}

        payload when is_binary(payload) or is_list(payload) ->
          payload = ensure_binary(payload)

          Logger.debug(
            "Noise ciphertext (counter=#{state.tx_counter}, #{byte_size(payload)} bytes): #{hex(payload)}"
          )

          new_state = %{state | tx_counter: state.tx_counter + 1}
          {:ok, payload, new_state}
      end
    end
  end

  def encrypt(_state, _plaintext), do: {:error, :invalid_state}

  @doc """
  Decrypts a transport payload once the handshake has completed.
  """
  @spec decrypt(t(), binary()) :: {:ok, binary(), t()} | {:error, term()}
  def decrypt(%__MODULE__{phase: :transport, cipher_ref: cipher} = state, payload)
      when is_binary(payload) do
    if is_nil(cipher) do
      {:error, :invalid_state}
    else
      Logger.debug(
        "Noise ciphertext (counter=#{state.rx_counter}, #{byte_size(payload)} bytes): #{hex(payload)}"
      )

      case Nif.noise_decrypt(cipher, payload) do
        {:error, reason} ->
          {:error, {:decrypt_failed, reason}}

        plaintext when is_binary(plaintext) or is_list(plaintext) ->
          plaintext = ensure_binary(plaintext)

          Logger.debug(
            "Noise plaintext (counter=#{state.rx_counter}, #{byte_size(plaintext)} bytes): #{hex(plaintext)}"
          )

          new_state = %{state | rx_counter: state.rx_counter + 1}
          {:ok, plaintext, new_state}
      end
    end
  end

  def decrypt(_state, _payload), do: {:error, :invalid_state}

  defp do_server_hello(%__MODULE__{} = state, payload) do
    with {:ok, client_finish} <- build_client_finish(state.handshake_ref, payload),
         {:ok, secrets} <- complete_handshake(state.handshake_ref),
         {:ok, cipher_ref} <- build_transport_cipher(secrets),
         :ok <- verify_certificate_callback(state, secrets),
         :ok <- persist_pending_data(state),
         new_state <- promote_to_transport(state, secrets, cipher_ref) do
      Logger.debug(
        "Handshake client finish (#{byte_size(client_finish)} bytes): #{hex(client_finish)}"
      )

      {:ok, new_state, client_finish}
    end
  end

  defp build_client_finish(handshake_ref, payload) do
    case Nif.handshake_client_finish(handshake_ref, payload) do
      {:error, reason} -> {:error, {:handshake_client_finish, reason}}
      bin when is_binary(bin) -> {:ok, bin}
      list when is_list(list) -> {:ok, ensure_binary(list)}
    end
  end

  defp complete_handshake(handshake_ref) do
    case Nif.handshake_finish(handshake_ref) do
      {:error, reason} -> {:error, {:handshake_finish, reason}}
      %ExWappNif.HandshakeSecrets{} = secrets -> {:ok, Nif.to_secrets(secrets)}
    end
  end

  defp verify_certificate_callback(
         %__MODULE__{certificate_verifier: verifier},
         %Secrets{server_certificate: cert, server_static: static}
       )
       when is_function(verifier, 2) do
    case verifier.(cert, static) do
      :ok -> :ok
      {:error, _} = error -> error
      other -> {:error, {:invalid_certificate_verifier_result, other}}
    end
  end

  defp verify_certificate_callback(_state, _secrets), do: {:error, :invalid_certificate_verifier}

  defp persist_pending_data(%__MODULE__{store: store, pending_store_data: data}) do
    maybe_persist(store, data)
  end

  defp build_transport_cipher(%Secrets{} = secrets) do
    keys = %NoiseKeys{
      write_key: ensure_binary(secrets.write_key),
      read_key: ensure_binary(secrets.read_key)
    }

    case Nif.noise_cipher_new(keys, ensure_binary(secrets.handshake_hash)) do
      {:error, reason} -> {:error, {:noise_cipher_new, reason}}
      cipher_ref -> {:ok, cipher_ref}
    end
  end

  defp promote_to_transport(state, %Secrets{} = secrets, cipher_ref) do
    state
    |> Map.put(:phase, :transport)
    |> Map.put(:handshake_ref, nil)
    |> Map.put(:tx_key, secrets.write_key)
    |> Map.put(:rx_key, secrets.read_key)
    |> Map.put(:tx_counter, 0)
    |> Map.put(:rx_counter, 0)
    |> Map.put(:pending_store_data, nil)
    |> Map.put(:handshake_hash, secrets.handshake_hash)
    |> Map.put(:handshake_salt, secrets.handshake_salt)
    |> Map.put(:cipher_ref, cipher_ref)
  end

  defp build_client_payload(%__MODULE__{client_payload_fun: fun} = state)
       when is_function(fun, 1) do
    case fun.(state) do
      {:ok, payload} when is_binary(payload) ->
        {:ok, payload, nil}

      {:ok, payload, data} when is_binary(payload) ->
        {:ok, payload, data}

      {:error, _} = error ->
        error

      payload when is_binary(payload) ->
        {:ok, payload, nil}

      other ->
        {:error, {:invalid_payload, other}}
    end
  end

  defp build_client_payload(%__MODULE__{}), do: {:ok, <<>>, nil}

  defp start_handshake(payload, static_key) do
    maybe_priv =
      case static_key do
        %{priv: priv} when is_binary(priv) -> priv
        _ -> nil
      end

    case Nif.handshake_new(payload, maybe_priv) do
      {:error, reason} ->
        {:error, {:handshake_new, reason}}

      {handshake_ref, client_hello, static_pub, static_priv} ->
        {:ok, handshake_ref, ensure_binary(client_hello),
         %{priv: ensure_binary(static_priv), pub: ensure_binary(static_pub)}}
    end
  end

  defp load_static_key(store) do
    data = Store.load!(store)

    case data[:noise] do
      %{static_private: priv, static_public: pub} when is_binary(priv) and is_binary(pub) ->
        %{priv: priv, pub: pub}

      _ ->
        nil
    end
  end

  defp persist_static_key(_store, nil), do: :ok

  defp persist_static_key(store, %{priv: priv, pub: pub}) do
    data = Store.load!(store)
    noise = Map.get(data, :noise, %{})

    current_priv = Map.get(noise, :static_private)
    current_pub = Map.get(noise, :static_public)

    if current_priv == priv and current_pub == pub do
      :ok
    else
      updated_noise =
        noise
        |> Map.put(:static_private, priv)
        |> Map.put(:static_public, pub)

      :ok = Store.persist(store, Map.put(data, :noise, updated_noise))
    end
  end

  defp ensure_binary(value) when is_binary(value), do: value
  defp ensure_binary(value) when is_list(value), do: :erlang.list_to_binary(value)
  defp ensure_binary(value), do: value

  defp maybe_persist(store, data) when is_map(data), do: Store.persist(store, data)
  defp maybe_persist(_store, _data), do: :ok

  defp hex(data) do
    Base.encode16(data, case: :lower)
  end

  @doc false
  def new, do: {:error, :deprecated_interface}

  @doc false
  def handle_incoming(_state, _payload), do: {:error, :deprecated_interface}

  @doc false
  def wrap_outgoing(_state, _payload), do: {:error, :deprecated_interface}
end
