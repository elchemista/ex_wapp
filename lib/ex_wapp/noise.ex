defmodule ExWapp.Noise do
  @moduledoc """
  Implements the Noise_XX_25519_AESGCM_SHA256 handshake used by WhatsApp Web.

  The module exposes helpers to produce the client hello, process the server
  hello (including certificate verification) and to encrypt/decrypt transport
  payloads once the handshake completes.
  """

  alias ExWapp.Noise.ClientPayload
  alias ExWapp.Noise.Engine, as: NoiseEngine
  alias ExWapp.Noise.HandshakeSecrets, as: Secrets
  alias ExWapp.Store
  alias ExWapp.Transport.Frame
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
            cipher_ref: nil,
            handshake_header: Frame.header()

  @type certificate_verifier_fun :: (binary(), binary() -> :ok | {:error, term()})

  @type t :: %__MODULE__{
          phase: :handshake | :transport,
          handshake_ref: term() | nil,
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
          cipher_ref: term() | nil,
          handshake_header: binary()
        }

  @doc """
  Initialises a new Noise handshake state.

  Returns the binary client hello frame that must be sent immediately together
  with the updated state.
  """
  @spec init(keyword()) :: {:ok, binary(), t()} | {:error, term()}
  def init(opts) do
    case Keyword.fetch(opts, :store) do
      {:ok, store} ->
        client_payload_fun = Keyword.get(opts, :client_payload_fun, &ClientPayload.build/1)

        certificate_verifier =
          Keyword.get(opts, :certificate_verifier, &ExWapp.Noise.Certificate.verify/2)

        handshake_header = Keyword.get(opts, :handshake_header, Frame.header())

        static_key = load_static_key(store)

        base_state = %__MODULE__{
          store: store,
          static_key: static_key,
          client_payload_fun: client_payload_fun,
          certificate_verifier: certificate_verifier,
          handshake_header: handshake_header
        }

        Logger.debug("[NOISE] init: static_key_loaded=#{not is_nil(static_key)}")

        with {:ok, client_payload, pending_data} <- build_client_payload(base_state),
             {:ok, handshake_ref, client_hello, static_map} <-
               start_handshake(base_state, client_payload, static_key),
             _ = Logger.debug("[NOISE] static key ready"),
             :ok <- persist_static_key(store, static_map) do
          state =
            base_state
            |> Map.put(:handshake_ref, handshake_ref)
            |> Map.put(:static_key, static_map)
            |> Map.put(:pending_store_data, pending_data)

          Logger.debug(
            "Noise init: client hello #{byte_size(client_hello)} bytes, header=#{Base.encode16(handshake_header, case: :lower)}"
          )

          {:ok, client_hello, state}
        end

      :error ->
        {:error, :missing_store}
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
      case NoiseEngine.encrypt(cipher, plaintext, state.tx_counter) do
        {:ok, new_cipher, payload} ->
          new_state = %{state | cipher_ref: new_cipher, tx_counter: state.tx_counter + 1}
          {:ok, ensure_binary(payload), new_state}

        {:error, reason} ->
          {:error, reason}
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
      case NoiseEngine.decrypt(cipher, payload, state.rx_counter) do
        {:error, reason} ->
          {:error, {:decrypt_failed, reason}}

        {:ok, new_cipher, plaintext} when is_binary(plaintext) or is_list(plaintext) ->
          plaintext = ensure_binary(plaintext)

          new_state = %{state | cipher_ref: new_cipher, rx_counter: state.rx_counter + 1}
          {:ok, plaintext, new_state}
      end
    end
  end

  def decrypt(_state, _payload), do: {:error, :invalid_state}

  defp do_server_hello(%__MODULE__{} = state, payload) do
    with {:ok, handshake_ref, client_finish} <- build_client_finish(state, payload),
         {:ok, secrets} <- complete_handshake(state, handshake_ref),
         {:ok, cipher_ref} <- build_transport_cipher(state, secrets),
         :ok <- verify_certificate_callback(state, secrets),
         :ok <- persist_handshake_data(state, secrets),
         new_state <- promote_to_transport(state, secrets, cipher_ref),
         do: {:ok, new_state, client_finish}
  end

  defp build_client_finish(%__MODULE__{handshake_ref: handshake_ref}, payload)
       when not is_nil(handshake_ref) do
    case NoiseEngine.write_client_finish(handshake_ref, payload) do
      {:error, reason} -> {:error, {:handshake_client_finish, reason}}
      {:ok, new_handshake, bin} -> {:ok, new_handshake, ensure_binary(bin)}
    end
  end

  defp build_client_finish(_state, _payload), do: {:error, :invalid_state}

  defp complete_handshake(%__MODULE__{}, handshake_ref) do
    case NoiseEngine.complete_handshake(handshake_ref) do
      {:ok, %Secrets{} = secrets} -> {:ok, secrets}
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

  defp persist_handshake_data(%__MODULE__{store: nil}, %Secrets{}), do: :ok

  defp persist_handshake_data(
         %__MODULE__{store: store, pending_store_data: pending},
         %Secrets{} = secrets
       ) do
    Logger.debug("[NOISE] persist_handshake_data completed")

    case Store.transaction(store, fn current ->
           data = Map.merge(current, pending || %{})

           updated_noise =
             data
             |> Map.get(:noise, %{})
             |> Map.put(:handshake_hash, secrets.handshake_hash)
             |> Map.put(:handshake_salt, secrets.handshake_salt)
             |> Map.put(:server_static, secrets.server_static)
             |> Map.put(:server_certificate, secrets.server_certificate)

           Map.put(data, :noise, updated_noise)
         end) do
      :ok -> :ok
      {:error, _} = error -> error
    end
  end

  defp build_transport_cipher(%__MODULE__{}, %Secrets{} = secrets) do
    case NoiseEngine.setup_transport(secrets) do
      {:ok, cipher_ref} -> {:ok, cipher_ref}
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

  defp start_handshake(%__MODULE__{handshake_header: handshake_header}, payload, static_key) do
    case NoiseEngine.init_handshake(payload, static_key, handshake_header: handshake_header) do
      {:ok, handshake_ref, client_hello, static_map} ->
        {:ok, handshake_ref, ensure_binary(client_hello), normalize_static_key(static_map)}
    end
  end

  defp normalize_static_key(%{priv: priv, pub: pub}) do
    %{priv: ensure_binary(priv), pub: ensure_binary(pub)}
  end

  defp load_static_key(store) do
    case Store.get(store, :noise, %{}) do
      %{static_private: priv, static_public: pub} when is_binary(priv) and is_binary(pub) ->
        %{priv: priv, pub: pub}

      _ ->
        nil
    end
  end

  defp persist_static_key(store, %{priv: priv, pub: pub}) do
    Logger.debug("[NOISE] persisting static key material")

    case Store.update(store, :noise, %{}, fn noise ->
           noise
           |> Map.put(:static_private, priv)
           |> Map.put(:static_public, pub)
         end) do
      :ok -> :ok
      {:error, _reason} = error -> error
    end
  end

  defp ensure_binary(value) when is_binary(value), do: value
  defp ensure_binary(value) when is_list(value), do: :erlang.list_to_binary(value)
  defp ensure_binary(value), do: value

  @doc false
  def new, do: {:error, :deprecated_interface}

  @doc false
  def handle_incoming(_state, _payload), do: {:error, :deprecated_interface}

  @doc false
  def wrap_outgoing(_state, _payload), do: {:error, :deprecated_interface}
end
