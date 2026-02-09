defmodule ExWapp.Signal.Encryption do
  @moduledoc """
  High-level Signal encryption/decryption for WhatsApp messages.

  Handles the full flow of:
  1. Fetching prekeys for new recipients
  2. Creating/using Signal sessions
  3. Encrypting outgoing messages
  4. Decrypting incoming messages
  """

  alias ExWapp.Signal.{SessionStore, PrekeyFetcher}

  require Logger

  @doc """
  Encrypts a message for a recipient (synchronous version - no GenServer calls).

  This avoids deadlock when called from within a GenServer handle_call.
  """
  @spec encrypt_for_recipient_sync(any(), any(), String.t(), binary(), map()) ::
          {:ok, binary(), :prekey | :whisper, any()} | {:error, term()}
  def encrypt_for_recipient_sync(store, signal_sessions, jid, plaintext, remote_bundle \\ %{}) do
    Logger.info("[ENCRYPTION] Attempting to encrypt message for #{jid} (sync)")

    # Load data from store
    data = ExWapp.Store.load!(store)
    signal_data = Map.get(data, :signal, %{})

    Logger.info("[ENCRYPTION] Store keys: #{inspect(Map.keys(data))}")
    Logger.info("[ENCRYPTION] Signal data keys: #{inspect(Map.keys(signal_data))}")

    identity = Map.get(signal_data, :identity_key)

    if identity do
      Logger.info("[ENCRYPTION] Found identity key")

      signal_store = signal_sessions || SessionStore.new()
      registration_id = Map.get(signal_data, :registration_id, 0)

      case SessionStore.encrypt_message(
             signal_store,
             jid,
             plaintext,
             identity,
             registration_id,
             remote_bundle || %{}
           ) do
        {:ok, ciphertext, type, updated_store} ->
          Logger.info("[ENCRYPTION] Encrypted! type=#{type}, size=#{byte_size(ciphertext)}")
          {:ok, ciphertext, type, updated_store}

        {:error, reason} ->
          Logger.error("[ENCRYPTION] Encrypt failed: #{inspect(reason)}")
          {:error, reason}
      end
    else
      Logger.error("[ENCRYPTION] No identity key in store")
      {:error, :no_identity_key}
    end
  end

  @doc """
  Encrypts a message for a recipient.

  Will fetch prekeys and create a session if needed.
  Returns the encrypted payload and whether it's a prekey message.
  """
  @spec encrypt_for_recipient(pid(), String.t(), binary()) ::
          {:ok, binary(), :prekey | :whisper} | {:error, term()}
  def encrypt_for_recipient(session, jid, plaintext) do
    Logger.info("[ENCRYPTION] Attempting to encrypt message for #{jid}")

    # Get local identity and signal sessions from session
    case get_local_keys(session) do
      {:ok, local_identity, _local_prekeys} ->
        Logger.info("[ENCRYPTION] Got local identity key")

        with {:ok, signal_store} <- get_or_init_session_store(session),
             {:ok, remote_bundle} <- ensure_remote_bundle(session, signal_store, jid) do
          Logger.info("[ENCRYPTION] Got remote bundle, encrypting...")

          local_reg_id =
            session
            |> GenServer.call(:get_store)
            |> ExWapp.Store.load!()
            |> then(fn data -> get_in(data, [:signal, :registration_id]) || 0 end)

          case SessionStore.encrypt_message(
                 signal_store,
                 jid,
                 plaintext,
                 local_identity,
                 local_reg_id,
                 remote_bundle
               ) do
            {:ok, ciphertext, type, updated_store} ->
              # Save updated session store
              GenServer.call(session, {:update_signal_sessions, updated_store})

              Logger.info(
                "[ENCRYPTION] Encrypted message for #{jid}, type=#{type}, size=#{byte_size(ciphertext)}"
              )

              {:ok, ciphertext, type}

            {:error, reason} ->
              Logger.error("[ENCRYPTION] SessionStore.encrypt_message failed: #{inspect(reason)}")

              {:error, reason}
          end
        else
          {:error, reason} ->
            Logger.error("[ENCRYPTION] Failed to get remote bundle: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("[ENCRYPTION] Failed to get local keys: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Decrypts an incoming message.
  """
  @spec decrypt_from_sender(pid(), String.t(), binary(), atom()) ::
          {:ok, binary()} | {:error, term()}
  def decrypt_from_sender(session, jid, ciphertext, enc_type) do
    with {:ok, local_identity, local_prekeys} <- get_local_keys(session),
         {:ok, signal_store} <- get_or_init_session_store(session) do
      is_prekey = enc_type in [:pkmsg, :prekey, 3]

      case SessionStore.decrypt_message(
             signal_store,
             jid,
             ciphertext,
             is_prekey,
             local_identity,
             local_prekeys
           ) do
        {:ok, plaintext, updated_store} ->
          GenServer.call(session, {:update_signal_sessions, updated_store})
          Logger.info("[ENCRYPTION] Decrypted message from #{jid}")
          {:ok, plaintext}

        {:error, reason} ->
          Logger.error("[ENCRYPTION] Failed to decrypt from #{jid}: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  @doc """
  Pads plaintext according to WhatsApp's padding scheme.

  WhatsApp uses PKCS7-like padding with random suffix to obscure message length.
  """
  @spec pad_message(binary()) :: binary()
  def pad_message(plaintext) do
    # WhatsApp/Signal padding v2:
    # Generate random padding length 1-15 (pad_val = random & 0x0F, if 0 then 15)
    # Extend with pad_len bytes, each byte being pad_len value (PKCS7-like)
    <<rand_byte>> = :crypto.strong_rand_bytes(1)
    pad_len = Bitwise.band(rand_byte, 0x0F)
    pad_len = if pad_len == 0, do: 0x0F, else: pad_len

    # Create padding: pad_len bytes, each with value pad_len
    padding = :binary.copy(<<pad_len>>, pad_len)
    plaintext <> padding
  end

  @doc """
  Unpads a decrypted message.
  """
  @spec unpad_message(binary()) :: binary()
  def unpad_message(padded) when byte_size(padded) > 0 do
    # WhatsApp padding: last byte indicates padding length
    pad_len = :binary.last(padded)

    if pad_len > 0 and pad_len <= 16 and pad_len <= byte_size(padded) do
      binary_part(padded, 0, byte_size(padded) - pad_len)
    else
      padded
    end
  end

  def unpad_message(data), do: data

  # ============================================================================
  # Private Helpers
  # ============================================================================

  defp get_local_keys(session) do
    store = GenServer.call(session, :get_store)
    data = ExWapp.Store.load!(store)

    # Debug: show what keys are in the store
    Logger.info("[ENCRYPTION] Store keys: #{inspect(Map.keys(data))}")

    signal_data = Map.get(data, :signal, %{})
    Logger.info("[ENCRYPTION] Signal data keys: #{inspect(Map.keys(signal_data))}")

    identity = Map.get(signal_data, :identity_key)

    if identity do
      Logger.info(
        "[ENCRYPTION] Found identity key: public=#{byte_size(identity.public || <<>>)} bytes"
      )

      prekeys = %{
        signed_prekeys: Map.get(signal_data, :signed_prekeys, %{}),
        prekeys: Map.get(signal_data, :prekeys, %{})
      }

      {:ok, identity, prekeys}
    else
      Logger.error(
        "[ENCRYPTION] No identity key found in store. Signal data: #{inspect(signal_data)}"
      )

      {:error, :no_identity_key}
    end
  end

  defp get_or_init_session_store(session) do
    case GenServer.call(session, :get_signal_sessions) do
      nil -> {:ok, SessionStore.new()}
      store -> {:ok, store}
    end
  end

  defp ensure_remote_bundle(session, signal_store, jid) do
    if SessionStore.has_session?(signal_store, jid) do
      # We have a session, create a dummy bundle (won't be used for existing sessions)
      {:ok, %{}}
    else
      # Need to fetch prekeys
      Logger.info("[ENCRYPTION] Fetching prekeys for #{jid}")
      PrekeyFetcher.fetch_prekeys(session, jid)
    end
  end
end
