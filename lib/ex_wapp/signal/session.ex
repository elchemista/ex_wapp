defmodule ExWapp.Signal.Session do
  @moduledoc """
  Signal Protocol session management for WhatsApp encryption.

  Implements:
  - X3DH (Extended Triple Diffie-Hellman) key agreement
  - Double Ratchet Algorithm for forward secrecy
  - AES-256-CBC + HMAC-SHA256 message encryption (proper Signal format)
  """

  alias ExWapp.Signal.Keys
  alias ExWapp.Signal.WireFormat

  require Logger

  # HKDF info strings used by Signal/WhatsApp
  # HKDF info strings - must match Signal protocol exactly!
  # For initial X3DH key derivation
  @hkdf_info_text "WhisperText"
  # For DH ratchet steps
  @hkdf_info_ratchet "WhisperRatchet"
  # For message key derivation
  @hkdf_info_message_keys "WhisperMessageKeys"

  @type session_state :: %{
          remote_identity_key: binary(),
          local_identity_key: %{public: binary(), private: binary()},
          root_key: binary(),
          sending_chain: chain_state() | nil,
          receiving_chain: chain_state() | nil,
          previous_counter: non_neg_integer(),
          ratchet_key: %{public: binary(), private: binary()} | nil,
          remote_ratchet_key: binary() | nil
        }

  @type chain_state :: %{
          key: binary(),
          counter: non_neg_integer(),
          message_keys: %{non_neg_integer() => binary()}
        }

  @type encrypted_message :: %{
          type: :prekey_message | :message,
          registration_id: non_neg_integer(),
          prekey_id: non_neg_integer() | nil,
          signed_prekey_id: non_neg_integer(),
          base_key: binary() | nil,
          identity_key: binary(),
          ciphertext: binary()
        }

  # ============================================================================
  # Session Creation (X3DH)
  # ============================================================================

  @doc """
  Creates a new session using X3DH key agreement.

  Uses the recipient's prekey bundle to establish a shared secret.
  """
  @spec create_session(map(), map()) :: {:ok, session_state(), binary()} | {:error, term()}
  def create_session(local_identity, remote_bundle) do
    # Generate ephemeral key pair for this session
    ephemeral = Keys.generate_key_pair()

    # Extract remote keys from bundle
    remote_identity = remote_bundle.identity_key
    remote_signed_prekey = remote_bundle.signed_prekey.public
    remote_one_time_prekey = get_in(remote_bundle, [:prekey, :public])

    # Verify signed prekey signature
    unless Keys.verify(
             remote_identity,
             remote_signed_prekey,
             remote_bundle.signed_prekey.signature
           ) do
      Logger.error("[SIGNAL] Invalid signed prekey signature")
      {:error, :invalid_signature}
    else
      # X3DH: Calculate shared secrets
      # DH1 = DH(IKa, SPKb) - our identity with their signed prekey
      dh1 = x25519_shared_secret(local_identity.private, remote_signed_prekey)

      # DH2 = DH(EKa, IKb) - our ephemeral with their identity
      dh2 = x25519_shared_secret(ephemeral.private, remote_identity)

      # DH3 = DH(EKa, SPKb) - our ephemeral with their signed prekey
      dh3 = x25519_shared_secret(ephemeral.private, remote_signed_prekey)

      # DH4 = DH(EKa, OPKb) - our ephemeral with their one-time prekey (optional)
      dh4 =
        if remote_one_time_prekey do
          x25519_shared_secret(ephemeral.private, remote_one_time_prekey)
        else
          <<>>
        end

      # Concatenate all DH outputs and derive root key
      # The 32-byte 0xFF prefix is required by Signal spec
      shared_secret = <<0xFF::size(256)>> <> dh1 <> dh2 <> dh3 <> dh4
      # Use "WhisperText" for initial X3DH derivation
      {root_key, chain_key} = hkdf_derive_initial(shared_secret)

      # Generate a NEW sending ratchet key (this is what Signal protocol requires!)
      sending_ratchet_key = Keys.generate_key_pair()

      # Do DH ratchet step to get actual sending chain
      # DH with their signed prekey (as ratchet key) and our new ratchet key
      dh_ratchet = x25519_shared_secret(sending_ratchet_key.private, remote_signed_prekey)
      # Use "WhisperRatchet" for DH ratchet steps
      {sending_root_key, sending_chain_key} = hkdf_derive_ratchet(dh_ratchet, root_key)

      # Initialize chains:
      # - Receiver chain uses the initial chain_key with their signed prekey as remote ratchet
      # - Sender chain uses the ratcheted chain_key
      receiving_chain = %{
        key: chain_key,
        counter: 0,
        message_keys: %{}
      }

      sending_chain = %{
        key: sending_chain_key,
        counter: 0,
        message_keys: %{}
      }

      session = %{
        remote_identity_key: remote_identity,
        local_identity_key: local_identity,
        root_key: sending_root_key,
        sending_chain: sending_chain,
        receiving_chain: receiving_chain,
        previous_counter: 0,
        # The NEW ratchet key, not ephemeral
        ratchet_key: sending_ratchet_key,
        remote_ratchet_key: remote_signed_prekey
      }

      Logger.info("[SIGNAL] Session created with X3DH + initial ratchet")

      # Return ephemeral.public as base_key for PreKeySignalMessage
      {:ok, session, ephemeral.public}
    end
  end

  # ============================================================================
  # Message Encryption
  # ============================================================================

  @doc """
  Encrypts a message using the session.

  Returns the encrypted ciphertext and updated session state.
  Uses proper Signal Protocol wire format with AES-CBC + HMAC.
  """
  @spec encrypt(session_state(), binary()) :: {:ok, binary(), session_state()} | {:error, term()}
  def encrypt(session, plaintext) do
    # Derive message keys (cipher_key, mac_key, iv)
    {message_keys, updated_chain} = derive_message_keys(session.sending_chain)

    %{cipher_key: cipher_key, mac_key: mac_key, iv: iv} = message_keys

    # Encrypt with AES-256-CBC (not AES-GCM!)
    ciphertext = WireFormat.encrypt_aes_cbc(plaintext, cipher_key, iv)

    # Get counter for this message
    counter = updated_chain.counter - 1

    # Serialize as proper SignalMessage with MAC
    serialized =
      WireFormat.serialize_signal_message(
        session.ratchet_key.public,
        counter,
        session.previous_counter,
        ciphertext,
        mac_key,
        session.local_identity_key.public,
        session.remote_identity_key
      )

    updated_session = %{session | sending_chain: updated_chain}

    {:ok, serialized, updated_session}
  end

  @doc """
  Encrypts a message and returns a PreKeySignalMessage for initial messages.
  Uses proper Signal Protocol wire format.
  """
  @spec encrypt_prekey_message(session_state(), binary(), map()) ::
          {:ok, binary(), session_state()} | {:error, term()}
  def encrypt_prekey_message(session, plaintext, bundle_info) do
    with {:ok, inner_signal_message, updated_session} <- encrypt(session, plaintext) do
      # Build PreKeySignalMessage with proper protobuf format
      # base_key is from our session creation (the ephemeral key we generated)
      base_key = Map.get(bundle_info, :base_key) || session.ratchet_key.public

      prekey_message =
        WireFormat.serialize_prekey_signal_message(
          bundle_info.registration_id,
          bundle_info.prekey_id,
          bundle_info.signed_prekey_id,
          base_key,
          session.local_identity_key.public,
          inner_signal_message
        )

      {:ok, prekey_message, updated_session}
    end
  end

  # ============================================================================
  # Message Decryption
  # ============================================================================

  @doc """
  Decrypts a regular Signal message.
  """
  @spec decrypt(session_state(), binary()) :: {:ok, binary(), session_state()} | {:error, term()}
  def decrypt(session, ciphertext) do
    # Parse the message
    case parse_signal_message(ciphertext) do
      {:ok, counter, _prev_counter, ratchet_key, iv, encrypted_data, tag} ->
        # Check if we need to ratchet
        session =
          if ratchet_key != session.remote_ratchet_key do
            perform_dh_ratchet(session, ratchet_key)
          else
            session
          end

        # Get or derive message key for this counter
        case get_or_derive_message_key(session.receiving_chain, counter) do
          {:ok, message_key, updated_chain} ->
            case aes_gcm_decrypt(message_key, iv, encrypted_data, tag) do
              {:ok, plaintext} ->
                {:ok, plaintext, %{session | receiving_chain: updated_chain}}

              :error ->
                {:error, :decryption_failed}
            end

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Decrypts a PreKeySignalMessage (initial message from a new sender).
  """
  @spec decrypt_prekey_message(binary(), map(), map()) ::
          {:ok, binary(), session_state()} | {:error, term()}
  def decrypt_prekey_message(message, local_identity, local_prekeys) do
    case parse_prekey_signal_message(message) do
      {:ok, _reg_id, prekey_id, signed_prekey_id, base_key, remote_identity, inner_ciphertext} ->
        # Look up our prekeys
        signed_prekey = Map.get(local_prekeys.signed_prekeys, signed_prekey_id)
        one_time_prekey = if prekey_id, do: Map.get(local_prekeys.prekeys, prekey_id), else: nil

        unless signed_prekey do
          {:error, :unknown_signed_prekey}
        else
          # X3DH from recipient side
          # DH1 = DH(SPKb, IKa)
          dh1 = x25519_shared_secret(signed_prekey.private, remote_identity)

          # DH2 = DH(IKb, EKa)
          dh2 = x25519_shared_secret(local_identity.private, base_key)

          # DH3 = DH(SPKb, EKa)
          dh3 = x25519_shared_secret(signed_prekey.private, base_key)

          # DH4 = DH(OPKb, EKa) if one-time prekey was used
          dh4 =
            if one_time_prekey do
              x25519_shared_secret(one_time_prekey.private, base_key)
            else
              <<>>
            end

          shared_secret = <<0xFF::size(256)>> <> dh1 <> dh2 <> dh3 <> dh4
          # Use "WhisperText" for initial X3DH derivation (Bob's side)
          {root_key, chain_key} = hkdf_derive_initial(shared_secret)

          # Initialize receiving chain
          receiving_chain = %{
            key: chain_key,
            counter: 0,
            message_keys: %{}
          }

          session = %{
            remote_identity_key: remote_identity,
            local_identity_key: local_identity,
            root_key: root_key,
            sending_chain: nil,
            receiving_chain: receiving_chain,
            previous_counter: 0,
            ratchet_key: nil,
            remote_ratchet_key: base_key
          }

          # Now decrypt the inner message
          decrypt(session, inner_ciphertext)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ============================================================================
  # Double Ratchet
  # ============================================================================

  defp perform_dh_ratchet(session, new_remote_ratchet_key) do
    # Save previous sending chain counter
    previous_counter =
      if session.sending_chain do
        session.sending_chain.counter
      else
        0
      end

    # Generate new ratchet key pair
    new_ratchet_key = Keys.generate_key_pair()

    # DH output for receiving
    dh_recv = x25519_shared_secret(session.ratchet_key.private, new_remote_ratchet_key)
    {root_key1, recv_chain_key} = hkdf_derive_ratchet(dh_recv, session.root_key)

    # DH output for sending
    dh_send = x25519_shared_secret(new_ratchet_key.private, new_remote_ratchet_key)
    {root_key2, send_chain_key} = hkdf_derive_ratchet(dh_send, root_key1)

    %{
      session
      | root_key: root_key2,
        sending_chain: %{key: send_chain_key, counter: 0, message_keys: %{}},
        receiving_chain: %{key: recv_chain_key, counter: 0, message_keys: %{}},
        previous_counter: previous_counter,
        ratchet_key: new_ratchet_key,
        remote_ratchet_key: new_remote_ratchet_key
    }
  end

  defp derive_message_key(chain) do
    # KDF chain step
    {chain_key, message_key} = hkdf_derive_chain(chain.key)

    updated_chain = %{
      chain
      | key: chain_key,
        counter: chain.counter + 1
    }

    {message_key, updated_chain}
  end

  defp get_or_derive_message_key(nil, _counter), do: {:error, :no_receiving_chain}

  defp get_or_derive_message_key(chain, counter) do
    cond do
      # Already have this message key cached
      Map.has_key?(chain.message_keys, counter) ->
        message_key = chain.message_keys[counter]
        updated_chain = %{chain | message_keys: Map.delete(chain.message_keys, counter)}
        {:ok, message_key, updated_chain}

      # Counter is in the future - need to advance chain
      counter >= chain.counter ->
        advance_chain_to(chain, counter)

      # Counter is in the past and we don't have it
      true ->
        {:error, :message_key_not_found}
    end
  end

  defp advance_chain_to(chain, target_counter) do
    if chain.counter > target_counter + 1000 do
      {:error, :too_many_skipped_messages}
    else
      advance_chain_to_impl(chain, target_counter)
    end
  end

  defp advance_chain_to_impl(chain, target_counter) when chain.counter > target_counter do
    message_key = chain.message_keys[target_counter]
    updated_chain = %{chain | message_keys: Map.delete(chain.message_keys, target_counter)}
    {:ok, message_key, updated_chain}
  end

  defp advance_chain_to_impl(chain, target_counter) do
    {chain_key, message_key} = hkdf_derive_chain(chain.key)

    updated_chain = %{
      chain
      | key: chain_key,
        counter: chain.counter + 1,
        message_keys: Map.put(chain.message_keys, chain.counter, message_key)
    }

    if chain.counter == target_counter do
      {:ok, message_key,
       %{updated_chain | message_keys: Map.delete(updated_chain.message_keys, target_counter)}}
    else
      advance_chain_to_impl(updated_chain, target_counter)
    end
  end

  # ============================================================================
  # Cryptographic Primitives
  # ============================================================================

  defp x25519_shared_secret(private_key, public_key) do
    :crypto.compute_key(:ecdh, public_key, private_key, :x25519)
  end

  # Initial X3DH key derivation - uses "WhisperText" info
  defp hkdf_derive_initial(input_key_material) do
    # For initial X3DH, salt is 32 zero bytes, info is "WhisperText"
    salt = :binary.copy(<<0>>, 32)
    hkdf_derive_with_info(input_key_material, salt, @hkdf_info_text)
  end

  # DH Ratchet key derivation - uses "WhisperRatchet" info
  defp hkdf_derive_ratchet(input_key_material, root_key) do
    # For ratchet, salt is the current root key, info is "WhisperRatchet"
    hkdf_derive_with_info(input_key_material, root_key, @hkdf_info_ratchet)
  end

  defp hkdf_derive_with_info(input_key_material, salt, info) do
    # Extract
    prk = :crypto.mac(:hmac, :sha256, salt, input_key_material)

    # Expand to 64 bytes for root_key (32) + chain_key (32)
    okm1 = :crypto.mac(:hmac, :sha256, prk, info <> <<1>>)
    okm2 = :crypto.mac(:hmac, :sha256, prk, okm1 <> info <> <<2>>)

    root_key = binary_part(okm1, 0, 32)
    chain_key = binary_part(okm2, 0, 32)

    {root_key, chain_key}
  end

  defp hkdf_derive_chain(chain_key) do
    # Chain key derivation - HMAC-based KDF
    # Signal Protocol constants (from libsignal-protocol-java):
    # MESSAGE_KEY_SEED = 0x01
    # CHAIN_KEY_SEED = 0x02
    message_key_seed = :crypto.mac(:hmac, :sha256, chain_key, <<0x01>>)
    new_chain_key = :crypto.mac(:hmac, :sha256, chain_key, <<0x02>>)

    {new_chain_key, message_key_seed}
  end

  # Derive message keys from the message key seed using HKDF
  # Returns: cipher_key (32 bytes), mac_key (32 bytes), iv (16 bytes)
  defp derive_message_keys(chain) do
    {new_chain_key, message_key_seed} = hkdf_derive_chain(chain.key)

    # Use HKDF to expand message_key_seed into cipher_key, mac_key, iv
    # Total: 32 + 32 + 16 = 80 bytes
    salt = :binary.copy(<<0>>, 32)
    prk = :crypto.mac(:hmac, :sha256, salt, message_key_seed)

    # Expand to 80 bytes
    okm1 = :crypto.mac(:hmac, :sha256, prk, @hkdf_info_message_keys <> <<1>>)
    okm2 = :crypto.mac(:hmac, :sha256, prk, okm1 <> @hkdf_info_message_keys <> <<2>>)
    okm3 = :crypto.mac(:hmac, :sha256, prk, okm2 <> @hkdf_info_message_keys <> <<3>>)

    expanded = okm1 <> okm2 <> okm3

    <<cipher_key::binary-size(32), mac_key::binary-size(32), iv::binary-size(16), _rest::binary>> =
      expanded

    message_keys = %{
      cipher_key: cipher_key,
      mac_key: mac_key,
      iv: iv
    }

    updated_chain = %{
      chain
      | key: new_chain_key,
        counter: chain.counter + 1
    }

    {message_keys, updated_chain}
  end

  # Keep old functions for backward compatibility / decryption
  defp aes_gcm_encrypt(key, iv, plaintext) do
    :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, <<>>, 16, true)
  end

  defp aes_gcm_decrypt(key, iv, ciphertext, tag) do
    case :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ciphertext, <<>>, tag, false) do
      :error -> :error
      plaintext -> {:ok, plaintext}
    end
  end

  # ============================================================================
  # Message Parsing/Building
  # ============================================================================

  defp parse_signal_message(<<
         counter::32,
         prev_counter::32,
         ratchet_key::binary-size(32),
         iv::binary-size(12),
         rest::binary
       >>) do
    # Last 16 bytes are the tag
    tag_size = 16
    ciphertext_size = byte_size(rest) - tag_size

    if ciphertext_size >= 0 do
      <<ciphertext::binary-size(ciphertext_size), tag::binary-size(16)>> = rest
      {:ok, counter, prev_counter, ratchet_key, iv, ciphertext, tag}
    else
      {:error, :invalid_message_format}
    end
  end

  defp parse_signal_message(_), do: {:error, :invalid_message_format}

  defp build_prekey_signal_message(
         reg_id,
         prekey_id,
         signed_prekey_id,
         base_key,
         identity_key,
         inner_ciphertext
       ) do
    # Simple binary format for PreKeySignalMessage
    # In real WhatsApp, this uses protobuf, but this is a simplified version
    prekey_id_bytes = if prekey_id, do: <<prekey_id::32>>, else: <<0xFFFFFFFF::32>>

    <<
      # Version
      3::8,
      # Registration ID
      reg_id::32,
      # PreKey ID (0xFFFFFFFF if not used)
      prekey_id_bytes::binary,
      # Signed PreKey ID
      signed_prekey_id::32,
      # Base key (ephemeral public key)
      base_key::binary-size(32),
      # Identity key
      identity_key::binary-size(32),
      # Inner ciphertext length and data
      byte_size(inner_ciphertext)::32,
      inner_ciphertext::binary
    >>
  end

  defp parse_prekey_signal_message(<<
         3::8,
         reg_id::32,
         prekey_id::32,
         signed_prekey_id::32,
         base_key::binary-size(32),
         identity_key::binary-size(32),
         inner_len::32,
         inner_ciphertext::binary-size(inner_len)
       >>) do
    prekey_id = if prekey_id == 0xFFFFFFFF, do: nil, else: prekey_id
    {:ok, reg_id, prekey_id, signed_prekey_id, base_key, identity_key, inner_ciphertext}
  end

  defp parse_prekey_signal_message(_), do: {:error, :invalid_prekey_message}
end
