defmodule ExWapp.Signal.Encryption do
  @moduledoc """
  High-level Signal encryption/decryption for WhatsApp messages.

  Handles the full flow of:
  1. Fetching prekeys for new recipients
  2. Creating/using Signal sessions
  3. Encrypting outgoing messages
  4. Decrypting incoming messages
  """

  alias ExWapp.Log
  alias ExWapp.Signal.{PrekeyFetcher, SessionStore, WireFormat}

  require Logger

  @doc """
  Encrypts a message for a recipient (synchronous version - no GenServer calls).

  This avoids deadlock when called from within a GenServer handle_call.
  """
  @spec encrypt_for_recipient_sync(any(), any(), String.t(), binary(), map()) ::
          {:ok, binary(), :prekey | :whisper, any()} | {:error, term()}
  def encrypt_for_recipient_sync(store, signal_sessions, jid, plaintext, remote_bundle \\ %{}) do
    Logger.debug("[ENCRYPTION] Attempting to encrypt message for #{Log.reference(jid)} (sync)")

    # Load data from store
    data = ExWapp.Store.load!(store)
    signal_data = Map.get(data, :signal, %{})

    Logger.debug("[ENCRYPTION] Store keys: #{inspect(Map.keys(data))}")
    Logger.debug("[ENCRYPTION] Signal data keys: #{inspect(Map.keys(signal_data))}")

    identity = Map.get(signal_data, :identity_key)

    if identity do
      Logger.debug("[ENCRYPTION] Found identity key")

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
          Logger.debug("[ENCRYPTION] Encrypted! type=#{type}, size=#{byte_size(ciphertext)}")
          {:ok, ciphertext, type, updated_store}

        {:error, reason} ->
          Logger.error("[ENCRYPTION] Encrypt failed: #{Log.reason(reason)}")
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
    Logger.debug("[ENCRYPTION] Attempting to encrypt message for #{Log.reference(jid)}")

    # Get local identity and signal sessions from session
    case get_local_keys(session) do
      {:ok, local_identity, _local_prekeys} ->
        Logger.debug("[ENCRYPTION] Got local identity key")

        with {:ok, signal_store} <- get_or_init_session_store(session),
             {:ok, remote_bundle} <- ensure_remote_bundle(session, signal_store, jid) do
          Logger.debug("[ENCRYPTION] Got remote bundle, encrypting...")

          do_encrypt_for_recipient(
            session,
            jid,
            plaintext,
            local_identity,
            signal_store,
            remote_bundle
          )
        else
          {:error, reason} ->
            Logger.error("[ENCRYPTION] Failed to get remote bundle: #{Log.reason(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("[ENCRYPTION] Failed to get local keys: #{Log.reason(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Decrypts an incoming message.
  """
  @spec decrypt_from_sender(pid(), String.t(), binary(), atom()) ::
          {:ok, binary()} | {:error, term()}
  def decrypt_from_sender(session, jid, ciphertext, enc_type) do
    store = GenServer.call(session, :get_store)
    signal_store = GenServer.call(session, :get_signal_sessions)

    case decrypt_from_sender_sync(store, signal_store, jid, ciphertext, enc_type) do
      {:ok, plaintext, updated_store} ->
        GenServer.call(session, {:update_signal_sessions, updated_store})
        Logger.debug("[ENCRYPTION] Decrypted message from #{Log.reference(jid)}")
        {:ok, plaintext}

      {:error, reason} ->
        Logger.error(
          "[ENCRYPTION] Failed to decrypt from #{Log.reference(jid)}: #{Log.reason(reason)}"
        )

        {:error, reason}
    end
  end

  @doc """
  Decrypts an incoming message without GenServer calls (safe inside Session handlers).
  """
  @spec decrypt_from_sender_sync(any(), any(), String.t(), binary(), atom() | String.t()) ::
          {:ok, binary(), any()} | {:error, term()}
  def decrypt_from_sender_sync(store, signal_sessions, jid, ciphertext, enc_type) do
    is_prekey = prekey_message?(enc_type)

    Logger.debug(
      "[ENCRYPTION] decrypt_from_sender_sync: jid=#{Log.reference(jid)} enc_type=#{inspect(enc_type)} is_prekey=#{is_prekey} ct_size=#{byte_size(ciphertext)}"
    )

    case get_local_keys_from_store(store) do
      {:ok, local_identity, local_prekeys} ->
        signal_store = signal_sessions || SessionStore.new()

        Logger.debug(
          "[ENCRYPTION] Have identity, signed_prekeys=#{map_size(local_prekeys.signed_prekeys)} prekeys=#{map_size(local_prekeys.prekeys)}"
        )

        case SessionStore.decrypt_message(
               signal_store,
               jid,
               ciphertext,
               is_prekey,
               local_identity,
               local_prekeys
             ) do
          {:ok, plaintext, updated_store} ->
            :ok = consume_one_time_prekey(store, ciphertext, is_prekey, updated_store)
            Logger.debug("[ENCRYPTION] Decrypt succeeded, plaintext_size=#{byte_size(plaintext)}")
            {:ok, plaintext, updated_store}

          {:error, reason} ->
            Logger.error("[ENCRYPTION] Decrypt failed: #{Log.reason(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("[ENCRYPTION] get_local_keys failed: #{Log.reason(reason)}")
        {:error, reason}
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
  def unpad_message(padded), do: unpad_message(padded, nil)

  @spec unpad_message(binary(), integer() | String.t() | nil) :: binary()
  def unpad_message(padded, version) when byte_size(padded) > 0 do
    # Whatsmeow parity: v=3 payloads are not WA-padded.
    if parse_enc_version(version) == 3 do
      padded
    else
      # WhatsApp padding: last byte indicates padding length
      strip_wa_padding(padded)
    end
  end

  def unpad_message(data, _version), do: data

  defp valid_padding?(padding, pad_len) when is_binary(padding) do
    expected = :binary.copy(<<pad_len>>, byte_size(padding))
    padding == expected
  end

  defp parse_enc_version(version) when is_integer(version), do: version

  defp parse_enc_version(version) when is_binary(version) do
    case Integer.parse(version) do
      {value, ""} -> value
      _ -> nil
    end
  end

  defp parse_enc_version(_), do: nil

  # Encryption internals

  defp do_encrypt_for_recipient(
         session,
         jid,
         plaintext,
         local_identity,
         signal_store,
         remote_bundle
       ) do
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
        GenServer.call(session, {:update_signal_sessions, updated_store})

        Logger.debug(
          "[ENCRYPTION] Encrypted message for #{Log.reference(jid)}, type=#{type}, size=#{byte_size(ciphertext)}"
        )

        {:ok, ciphertext, type}

      {:error, reason} ->
        Logger.error("[ENCRYPTION] SessionStore.encrypt_message failed: #{Log.reason(reason)}")
        {:error, reason}
    end
  end

  defp strip_wa_padding(padded) do
    pad_len = :binary.last(padded)

    if pad_len > 0 and pad_len <= 16 and pad_len <= byte_size(padded) do
      payload_len = byte_size(padded) - pad_len
      <<payload::binary-size(^payload_len), padding::binary-size(^pad_len)>> = padded
      if valid_padding?(padding, pad_len), do: payload, else: padded
    else
      padded
    end
  end

  defp get_local_keys(session) do
    store = GenServer.call(session, :get_store)
    get_local_keys_from_store(store)
  end

  defp get_local_keys_from_store(store) do
    data = ExWapp.Store.load!(store)

    # Debug: show what keys are in the store
    Logger.debug("[ENCRYPTION] Store keys: #{inspect(Map.keys(data))}")

    signal_data = Map.get(data, :signal, %{})
    Logger.debug("[ENCRYPTION] Signal data keys: #{inspect(Map.keys(signal_data))}")

    identity = Map.get(signal_data, :identity_key)

    if identity do
      Logger.debug(
        "[ENCRYPTION] Found identity key: public=#{byte_size(identity.public || <<>>)} bytes"
      )

      prekeys = %{
        signed_prekeys: Map.get(signal_data, :signed_prekeys, %{}),
        prekeys: Map.get(signal_data, :prekeys, %{})
      }

      {:ok, identity, prekeys}
    else
      Logger.error(
        "[ENCRYPTION] No identity key found in store; signal_keys=#{inspect(Map.keys(signal_data))}"
      )

      {:error, :no_identity_key}
    end
  end

  @spec consume_one_time_prekey(term(), binary(), boolean(), SessionStore.t()) :: :ok
  defp consume_one_time_prekey(_store, _ciphertext, false, _sessions), do: :ok

  defp consume_one_time_prekey(store, ciphertext, true, sessions) do
    with {:ok, %{prekey_id: prekey_id}}
         when is_integer(prekey_id) and prekey_id > 0 <-
           WireFormat.parse_prekey_signal_message(ciphertext),
         :ok <- persist_session_before_prekey_delete(store, sessions, prekey_id) do
      store
      |> ExWapp.Store.get_and_update(:signal, %{}, &delete_prekey(&1, prekey_id))
      |> log_prekey_consumption(prekey_id)
    else
      _ -> :ok
    end
  rescue
    error ->
      Logger.warning("[SIGNAL] Failed consuming one-time prekey: #{Log.reason(error)}")
      :ok
  end

  defp delete_prekey(signal, prekey_id) do
    prekeys = Map.get(signal, :prekeys, %{})

    if Map.has_key?(prekeys, prekey_id) do
      {:consumed, Map.put(signal, :prekeys, Map.delete(prekeys, prekey_id))}
    else
      {:missing, signal}
    end
  end

  defp log_prekey_consumption(:consumed, prekey_id) do
    Logger.debug("[SIGNAL] Consumed one-time prekey #{prekey_id}")
    :ok
  end

  defp log_prekey_consumption(:missing, _prekey_id), do: :ok

  defp log_prekey_consumption({:error, reason}, prekey_id) do
    Logger.warning(
      "[SIGNAL] Failed persisting consumed one-time prekey #{prekey_id}: #{Log.reason(reason)}"
    )

    :ok
  end

  @spec persist_session_before_prekey_delete(term(), SessionStore.t(), pos_integer()) ::
          :ok | {:error, term()}
  defp persist_session_before_prekey_delete(store, sessions, prekey_id) do
    case ExWapp.Store.persist_signal_sessions(store, sessions) do
      :ok ->
        :ok

      {:error, reason} = error ->
        Logger.warning(
          "[SIGNAL] Keeping one-time prekey #{prekey_id} because session persistence failed: #{Log.reason(reason)}"
        )

        error
    end
  end

  defp prekey_message?(enc_type) when enc_type in [:pkmsg, :prekey, 3], do: true
  defp prekey_message?(enc_type) when enc_type in ["pkmsg", "prekey", "3"], do: true
  defp prekey_message?(_), do: false

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
      Logger.debug("[ENCRYPTION] Fetching prekeys for #{Log.reference(jid)}")
      PrekeyFetcher.fetch_prekeys(session, jid)
    end
  end
end
