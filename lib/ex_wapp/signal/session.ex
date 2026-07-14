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

  # X3DH session bootstrap

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
    if Keys.verify(
         remote_identity,
         remote_signed_prekey,
         remote_bundle.signed_prekey.signature
       ) do
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
      shared_secret = :binary.copy(<<0xFF>>, 32) <> dh1 <> dh2 <> dh3 <> dh4
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

      Logger.debug("[SIGNAL] Session created with X3DH + initial ratchet")

      # Return ephemeral.public as base_key for PreKeySignalMessage
      {:ok, session, ephemeral.public}
    else
      Logger.error("[SIGNAL] Invalid signed prekey signature")
      {:error, :invalid_signature}
    end
  end

  # Encrypting outbound Signal messages

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

  # Decrypting inbound Signal messages

  @doc """
  Decrypts a regular Signal message.
  """
  @spec decrypt(session_state(), binary()) :: {:ok, binary(), session_state()} | {:error, term()}
  def decrypt(session, ciphertext) do
    case parse_signal_message(ciphertext) do
      {:ok, parsed} ->
        session = maybe_ratchet(session, parsed.ratchet_key)
        decrypt_inner_message(session, parsed)

      {:error, reason} ->
        Logger.warning("[SIGNAL] Failed to parse SignalMessage: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Decrypts a PreKeySignalMessage (initial message from a new sender).
  """
  @spec decrypt_prekey_message(binary(), map(), map()) ::
          {:ok, binary(), session_state()} | {:error, term()}
  def decrypt_prekey_message(message, local_identity, local_prekeys) do
    Logger.debug(
      "[SIGNAL] decrypt_prekey_message: msg_size=#{byte_size(message)} first_byte=0x#{Base.encode16(binary_part(message, 0, 1))}"
    )

    case parse_prekey_signal_message(message) do
      {:ok, reg_id, prekey_id, signed_prekey_id, base_key, remote_identity, inner_ciphertext} ->
        Logger.debug(
          "[SIGNAL] Parsed pkmsg: reg_id=#{reg_id} prekey_id=#{inspect(prekey_id)} " <>
            "signed_prekey_id=#{signed_prekey_id} base_key_size=#{byte_size(base_key)} " <>
            "inner_size=#{byte_size(inner_ciphertext)}"
        )

        resolve_prekeys_and_decrypt(
          local_identity,
          local_prekeys,
          prekey_id,
          signed_prekey_id,
          remote_identity,
          base_key,
          inner_ciphertext
        )

      {:error, reason} ->
        Logger.warning("[SIGNAL] Failed to parse PreKeySignalMessage: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Decrypts a PreKeySignalMessage using an already-established session.

  WhatsApp can keep wrapping sync traffic as `pkmsg` even when a session already exists.
  In that case, we must decrypt the inner SignalMessage with the current ratchet state
  instead of re-running X3DH and replacing the session.
  """
  @spec decrypt_prekey_message_with_session(session_state(), binary()) ::
          {:ok, binary(), session_state()} | {:error, term()}
  def decrypt_prekey_message_with_session(session, message) do
    with {:ok, _reg_id, _prekey_id, _signed_prekey_id, _base_key, remote_identity,
          inner_ciphertext} <-
           parse_prekey_signal_message(message),
         :ok <- verify_remote_identity(session.remote_identity_key, remote_identity) do
      decrypt(session, inner_ciphertext)
    end
  end

  defp resolve_prekeys_and_decrypt(
         local_identity,
         local_prekeys,
         prekey_id,
         signed_prekey_id,
         remote_identity,
         base_key,
         inner_ciphertext
       ) do
    signed_prekey = Map.get(local_prekeys.signed_prekeys, signed_prekey_id)
    one_time_prekey = if prekey_id, do: Map.get(local_prekeys.prekeys, prekey_id), else: nil

    cond do
      is_nil(signed_prekey) ->
        Logger.warning(
          "[SIGNAL] Unknown signed prekey #{signed_prekey_id}, available: #{inspect(Map.keys(local_prekeys.signed_prekeys))}"
        )

        {:error, :unknown_signed_prekey}

      is_integer(prekey_id) and prekey_id > 0 and is_nil(one_time_prekey) ->
        Logger.debug(
          "[SIGNAL] One-time prekey #{prekey_id} is unavailable (already consumed or unknown)"
        )

        {:error, :prekey_not_found}

      true ->
        x3dh_and_decrypt(
          local_identity,
          signed_prekey,
          one_time_prekey,
          remote_identity,
          base_key,
          inner_ciphertext
        )
    end
  end

  defp maybe_ratchet(session, ratchet_key) do
    if ratchet_key != session.remote_ratchet_key do
      Logger.debug("[SIGNAL] Performing DH ratchet step")
      perform_dh_ratchet(session, ratchet_key)
    else
      session
    end
  end

  defp decrypt_inner_message(session, parsed) do
    with {:ok, message_keys, updated_chain} <-
           get_or_derive_message_key(session.receiving_chain, parsed.counter) do
      mac_valid =
        WireFormat.valid_signal_mac?(
          parsed.mac,
          message_keys.mac_key,
          session.remote_identity_key,
          session.local_identity_key.public,
          parsed.version_and_proto
        )

      Logger.debug("[SIGNAL] MAC verification: #{mac_valid}")

      if mac_valid do
        case WireFormat.decrypt_aes_cbc(
               parsed.ciphertext,
               message_keys.cipher_key,
               message_keys.iv
             ) do
          {:ok, plaintext} ->
            {:ok, plaintext, %{session | receiving_chain: updated_chain}}

          {:error, reason} ->
            {:error, reason}
        end
      else
        {:error, :invalid_mac}
      end
    end
  end

  defp x3dh_and_decrypt(
         local_identity,
         signed_prekey,
         one_time_prekey,
         remote_identity,
         base_key,
         inner_ciphertext
       ) do
    # X3DH from recipient side
    dh1 = x25519_shared_secret(signed_prekey.private, remote_identity)
    dh2 = x25519_shared_secret(local_identity.private, base_key)
    dh3 = x25519_shared_secret(signed_prekey.private, base_key)

    dh4 =
      if one_time_prekey, do: x25519_shared_secret(one_time_prekey.private, base_key), else: <<>>

    case decrypt_prekey_inner_with_compat(
           local_identity,
           signed_prekey,
           remote_identity,
           base_key,
           inner_ciphertext,
           {dh1, dh2, dh3, dh4}
         ) do
      {:ok, plaintext, updated_session, variant} ->
        Logger.debug(
          "[SIGNAL] Inner decrypt succeeded with #{variant}, plaintext_size=#{byte_size(plaintext)}"
        )

        {:ok, plaintext, updated_session}

      {:error, reason} ->
        Logger.warning("[SIGNAL] Inner decrypt failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Double-ratchet state transitions

  defp decrypt_prekey_inner_with_compat(
         local_identity,
         signed_prekey,
         remote_identity,
         base_key,
         inner_ciphertext,
         dh_outputs
       ) do
    {dh1, dh2, dh3, dh4} = dh_outputs
    variants = x3dh_secret_variants(dh1, dh2, dh3, dh4)

    Enum.reduce_while(variants, {:error, :invalid_mac}, fn {variant, shared_secret}, _acc ->
      {root_key, chain_key} = hkdf_derive_initial(shared_secret)

      Logger.debug(
        "[SIGNAL] Trying #{variant}: root_key=#{Base.encode16(binary_part(root_key, 0, 4))}... " <>
          "chain_key=#{Base.encode16(binary_part(chain_key, 0, 4))}..."
      )

      session =
        build_prekey_initial_session(
          local_identity,
          signed_prekey,
          remote_identity,
          base_key,
          root_key,
          chain_key
        )

      case decrypt(session, inner_ciphertext) do
        {:ok, plaintext, updated_session} ->
          {:halt, {:ok, plaintext, updated_session, variant}}

        {:error, reason} ->
          {:cont, {:error, reason}}
      end
    end)
  end

  defp build_prekey_initial_session(
         local_identity,
         signed_prekey,
         remote_identity,
         _base_key,
         root_key,
         chain_key
       ) do
    # Match libsignal receiver bootstrap:
    # - X3DH chain key initializes our *sender* chain
    # - first inner SignalMessage ratchets into receiver chain
    sending_chain = %{
      key: chain_key,
      counter: 0,
      message_keys: %{}
    }

    %{
      remote_identity_key: remote_identity,
      local_identity_key: local_identity,
      root_key: root_key,
      sending_chain: sending_chain,
      receiving_chain: nil,
      previous_counter: 0,
      # Bob side starts from signed prekey as current ratchet private key.
      ratchet_key: %{public: signed_prekey.public, private: signed_prekey.private},
      # Force the first inner SignalMessage to perform a DH ratchet from root_key.
      # The sender's ratchet key comes from the inner SignalMessage, not PreKey base_key.
      remote_ratchet_key: nil
    }
  end

  # Compatibility fallback list for runtimes that produce slightly different
  # prekey shared-secret composition. We still require a valid Signal MAC.
  defp x3dh_secret_variants(dh1, dh2, dh3, dh4) do
    [
      {"ff:dh1,dh2,dh3,dh4", true, [dh1, dh2, dh3, dh4]},
      {"noff:dh1,dh2,dh3,dh4", false, [dh1, dh2, dh3, dh4]},
      {"ff:dh1,dh3,dh2,dh4", true, [dh1, dh3, dh2, dh4]},
      {"ff:dh2,dh1,dh3,dh4", true, [dh2, dh1, dh3, dh4]},
      {"ff:dh2,dh3,dh1,dh4", true, [dh2, dh3, dh1, dh4]},
      {"ff:dh3,dh1,dh2,dh4", true, [dh3, dh1, dh2, dh4]}
    ]
    |> Enum.map(fn {name, with_ff_prefix?, parts} ->
      secret = shared_secret_from_parts(parts, with_ff_prefix?)
      {name, secret}
    end)
  end

  defp shared_secret_from_parts(parts, with_ff_prefix?) when is_list(parts) do
    prefix = if with_ff_prefix?, do: :binary.copy(<<0xFF>>, 32), else: <<>>

    Enum.reduce(parts, prefix, fn
      <<>>, acc -> acc
      part, acc -> acc <> part
    end)
  end

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
    if target_counter > chain.counter + 1000 do
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
    {chain_key, message_key_seed} = hkdf_derive_chain(chain.key)
    message_keys = derive_message_keys_from_seed(message_key_seed)

    updated_chain = %{
      chain
      | key: chain_key,
        counter: chain.counter + 1,
        message_keys: Map.put(chain.message_keys, chain.counter, message_keys)
    }

    if chain.counter == target_counter do
      {:ok, message_keys,
       %{updated_chain | message_keys: Map.delete(updated_chain.message_keys, target_counter)}}
    else
      advance_chain_to_impl(updated_chain, target_counter)
    end
  end

  # Low-level cryptographic primitives

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
    message_keys = derive_message_keys_from_seed(message_key_seed)

    updated_chain = %{
      chain
      | key: new_chain_key,
        counter: chain.counter + 1
    }

    {message_keys, updated_chain}
  end

  defp derive_message_keys_from_seed(message_key_seed) do
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

    %{
      cipher_key: cipher_key,
      mac_key: mac_key,
      iv: iv
    }
  end

  # Signal message parsing and construction

  defp parse_signal_message(payload) do
    WireFormat.parse_signal_message(payload)
  end

  defp parse_prekey_signal_message(payload) do
    case WireFormat.parse_prekey_signal_message(payload) do
      {:ok, parsed} ->
        {:ok, parsed.registration_id, parsed.prekey_id, parsed.signed_prekey_id, parsed.base_key,
         parsed.identity_key, parsed.message}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp verify_remote_identity(expected, actual) when expected == actual, do: :ok
  defp verify_remote_identity(_expected, _actual), do: {:error, :remote_identity_mismatch}
end
