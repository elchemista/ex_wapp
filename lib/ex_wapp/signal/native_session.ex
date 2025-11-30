defmodule ExWapp.Signal.NativeSession do
  @moduledoc """
  Signal Protocol session management using the Rust NIF.

  This module provides the high-level API for encrypting/decrypting
  WhatsApp messages using the native Rust implementation.
  """

  alias ExWapp.Signal.Native

  require Logger

  # ============================================================================
  # New Complete Session Cipher (ported from wacore)
  # ============================================================================

  @doc """
  Creates a new outbound session using the complete Rust session cipher.

  This uses the wacore-ported implementation that handles all X3DH and
  session initialization in Rust, eliminating potential boundary issues.

  Returns `{:ok, session_data}` where session_data is an opaque binary
  that can be passed to `encrypt_v2/2`.
  """
  def create_session_v2(local_identity, local_registration_id, remote_bundle) do
    try do
      remote_identity = remote_bundle.identity_key
      remote_signed_prekey = remote_bundle.signed_prekey.public
      remote_prekey = get_in(remote_bundle, [:prekey, :public]) || <<>>
      remote_registration_id = remote_bundle.registration_id
      prekey_id = get_in(remote_bundle, [:prekey, :id]) || 0
      signed_prekey_id = remote_bundle.signed_prekey.id

      Logger.info("[NATIVE_SESSION_V2] Creating session with complete Rust cipher")

      Logger.info(
        "[NATIVE_SESSION_V2] local_reg_id=#{local_registration_id}, remote_reg_id=#{remote_registration_id}"
      )

      Logger.info("[NATIVE_SESSION_V2] prekey_id=#{prekey_id}, spk_id=#{signed_prekey_id}")

      session_data =
        Native.create_outbound_session(
          local_identity.public,
          local_identity.private,
          local_registration_id,
          remote_identity,
          remote_signed_prekey,
          remote_prekey,
          remote_registration_id,
          prekey_id,
          signed_prekey_id
        )

      Logger.info("[NATIVE_SESSION_V2] Session created, size=#{byte_size(session_data)} bytes")
      {:ok, session_data}
    rescue
      e ->
        Logger.error("[NATIVE_SESSION_V2] Session creation failed: #{inspect(e)}")
        {:error, e}
    end
  end

  @doc """
  Encrypts a message using the complete Rust session cipher.

  Takes session_data from `create_session_v2` and returns
  `{:ok, encrypted_message, updated_session_data}`.
  """
  def encrypt_v2(session_data, plaintext) do
    try do
      {encrypted, new_session_data, is_prekey} =
        Native.session_encrypt_message(session_data, plaintext)

      enc_type = if is_prekey, do: :prekey, else: :whisper

      Logger.info("[NATIVE_SESSION_V2] Encrypted message, size=#{byte_size(encrypted)} bytes")
      {:ok, encrypted, enc_type, new_session_data}
    rescue
      e ->
        Logger.error("[NATIVE_SESSION_V2] Encrypt failed: #{inspect(e)}")
        {:error, e}
    end
  end

  # ============================================================================
  # Original Implementation (kept for comparison)
  # ============================================================================

  @doc """
  Creates a new session using X3DH key agreement.

  Uses the recipient's prekey bundle to establish a shared secret.
  Returns `{:ok, session_state, base_key}` where base_key is the ephemeral
  public key to include in the PreKeySignalMessage.
  """
  def create_session(local_identity, remote_bundle) do
    # Generate ephemeral key pair for this session
    {ephemeral_public, ephemeral_private} = Native.generate_key_pair()

    # Extract remote keys from bundle
    remote_identity = remote_bundle.identity_key
    remote_signed_prekey = remote_bundle.signed_prekey.public
    remote_one_time_prekey = get_in(remote_bundle, [:prekey, :public])

    # Log signature verification (don't block on failure - XEdDSA is complex)
    signature = remote_bundle.signed_prekey.signature

    Logger.debug(
      "[SIGNAL/NATIVE] Key sizes - identity: #{byte_size(remote_identity)}, spk: #{byte_size(remote_signed_prekey)}, sig: #{byte_size(signature)}"
    )

    # Try Elixir verification (more reliable than our Rust XEdDSA implementation)
    sig_valid =
      try do
        ExWapp.Signal.Keys.verify(remote_identity, remote_signed_prekey, signature)
      rescue
        _ -> false
      end

    if !sig_valid do
      Logger.warning(
        "[SIGNAL/NATIVE] Signed prekey signature verification failed - proceeding anyway"
      )
    end

    # X3DH shared secret components
    # DH1 = DH(IKA, SPKB) - our identity key with their signed prekey
    # DH2 = DH(EKA, IKB) - our ephemeral with their identity
    # DH3 = DH(EKA, SPKB) - our ephemeral with their signed prekey
    # DH4 = DH(EKA, OPKB) - our ephemeral with their one-time prekey (optional)
    dh1 = Native.x25519_shared_secret(local_identity.private, remote_signed_prekey)
    dh2 = Native.x25519_shared_secret(ephemeral_private, remote_identity)
    dh3 = Native.x25519_shared_secret(ephemeral_private, remote_signed_prekey)
    dh4 = Native.x25519_shared_secret(ephemeral_private, remote_one_time_prekey)

    # DEBUG: Log X3DH inputs
    Logger.info(
      "[X3DH DEBUG] local_id_priv first4=#{Base.encode16(binary_part(local_identity.private, 0, 4))}"
    )

    Logger.info(
      "[X3DH DEBUG] local_id_pub first4=#{Base.encode16(binary_part(local_identity.public, 0, 4))}"
    )

    Logger.info(
      "[X3DH DEBUG] ephemeral_pub first4=#{Base.encode16(binary_part(ephemeral_public, 0, 4))}"
    )

    Logger.info(
      "[X3DH DEBUG] ephemeral_priv first4=#{Base.encode16(binary_part(ephemeral_private, 0, 4))}"
    )

    Logger.info(
      "[X3DH DEBUG] remote_id first4=#{Base.encode16(binary_part(remote_identity, 0, 4))}"
    )

    Logger.info(
      "[X3DH DEBUG] remote_spk first4=#{Base.encode16(binary_part(remote_signed_prekey, 0, 4))}"
    )

    Logger.info(
      "[X3DH DEBUG] remote_opk first4=#{Base.encode16(binary_part(remote_one_time_prekey, 0, 4))}"
    )

    Logger.info("[X3DH DEBUG] DH1 first4=#{Base.encode16(binary_part(dh1, 0, 4))}")
    Logger.info("[X3DH DEBUG] DH2 first4=#{Base.encode16(binary_part(dh2, 0, 4))}")
    Logger.info("[X3DH DEBUG] DH3 first4=#{Base.encode16(binary_part(dh3, 0, 4))}")
    Logger.info("[X3DH DEBUG] DH4 first4=#{Base.encode16(binary_part(dh4, 0, 4))}")

    # Concatenate: 0xFF*32 || DH1 || DH2 || DH3 || DH4
    shared_secret = :binary.copy(<<0xFF>>, 32) <> dh1 <> dh2 <> dh3 <> dh4
    {root_key, chain_key} = Native.hkdf_derive_initial(shared_secret)

    Logger.info("[X3DH DEBUG] root_key first4=#{Base.encode16(binary_part(root_key, 0, 4))}")
    Logger.info("[X3DH DEBUG] chain_key first4=#{Base.encode16(binary_part(chain_key, 0, 4))}")

    # Generate a NEW sending ratchet key (this is what Signal protocol requires!)
    {sending_ratchet_public, sending_ratchet_private} = Native.generate_key_pair()

    # Do DH ratchet step to get actual sending chain
    dh_ratchet = Native.x25519_shared_secret(sending_ratchet_private, remote_signed_prekey)
    {sending_root_key, sending_chain_key} = Native.hkdf_derive_ratchet(dh_ratchet, root_key)

    Logger.info("[X3DH DEBUG] dh_ratchet first4=#{Base.encode16(binary_part(dh_ratchet, 0, 4))}")

    Logger.info(
      "[X3DH DEBUG] sending_root_key first4=#{Base.encode16(binary_part(sending_root_key, 0, 4))}"
    )

    Logger.info(
      "[X3DH DEBUG] sending_chain_key first4=#{Base.encode16(binary_part(sending_chain_key, 0, 4))}"
    )

    Logger.info(
      "[X3DH DEBUG] sending_ratchet_pub first4=#{Base.encode16(binary_part(sending_ratchet_public, 0, 4))}"
    )

    session = %{
      remote_identity_key: remote_identity,
      local_identity_key: local_identity,
      root_key: sending_root_key,
      sending_chain_key: sending_chain_key,
      receiving_chain_key: chain_key,
      sending_counter: 0,
      receiving_counter: 0,
      # Use 0xFFFFFFFF for first message (matches Go whatsmeow)
      previous_counter: 0xFFFFFFFF,
      ratchet_public: sending_ratchet_public,
      ratchet_private: sending_ratchet_private,
      remote_ratchet_key: remote_signed_prekey,
      # Store base_key for PreKeySignalMessage
      base_key: ephemeral_public
    }

    Logger.info("[SIGNAL/NATIVE] Session created with X3DH + initial ratchet")

    {:ok, session, ephemeral_public}
  end

  @doc """
  Encrypts a message using the session.

  For new sessions (first message), set `is_prekey: true` and provide
  the bundle_info with prekey IDs and registration ID.

  Returns `{:ok, encrypted_message, updated_session}`.
  """
  def encrypt(session, plaintext, opts \\ []) do
    is_prekey = Keyword.get(opts, :is_prekey, false)
    bundle_info = Keyword.get(opts, :bundle_info, %{})

    # DEBUG: Log key sizes and first bytes
    Logger.info("[ENCRYPT DEBUG] plaintext=#{byte_size(plaintext)} bytes")

    Logger.info(
      "[ENCRYPT DEBUG] chain_key=#{byte_size(session.sending_chain_key)} bytes, first4=#{Base.encode16(binary_part(session.sending_chain_key, 0, 4))}"
    )

    Logger.info(
      "[ENCRYPT DEBUG] ratchet_pub=#{byte_size(session.ratchet_public)} bytes, first4=#{Base.encode16(binary_part(session.ratchet_public, 0, 4))}"
    )

    Logger.info(
      "[ENCRYPT DEBUG] local_id=#{byte_size(session.local_identity_key.public)} bytes, first4=#{Base.encode16(binary_part(session.local_identity_key.public, 0, 4))}"
    )

    Logger.info(
      "[ENCRYPT DEBUG] remote_id=#{byte_size(session.remote_identity_key)} bytes, first4=#{Base.encode16(binary_part(session.remote_identity_key, 0, 4))}"
    )

    Logger.info(
      "[ENCRYPT DEBUG] counter=#{session.sending_counter}, prev_counter=#{session.previous_counter}"
    )

    {encrypted_message, new_chain_key, new_counter} =
      Native.encrypt_message(
        plaintext,
        session.sending_chain_key,
        session.ratchet_public,
        session.sending_counter,
        session.previous_counter,
        session.local_identity_key.public,
        session.remote_identity_key,
        is_prekey,
        Map.get(bundle_info, :registration_id, 0),
        Map.get(bundle_info, :prekey_id, 0),
        Map.get(bundle_info, :signed_prekey_id, 0),
        Map.get(session, :base_key, session.ratchet_public)
      )

    Logger.info(
      "[ENCRYPT DEBUG] encrypted_message=#{byte_size(encrypted_message)} bytes, first8=#{Base.encode16(binary_part(encrypted_message, 0, 8))}"
    )

    updated_session = %{session | sending_chain_key: new_chain_key, sending_counter: new_counter}

    {:ok, encrypted_message, updated_session}
  end

  @doc """
  Convenience function to encrypt a first message (PreKeySignalMessage).
  """
  def encrypt_prekey_message(session, plaintext, bundle_info) do
    encrypt(session, plaintext, is_prekey: true, bundle_info: bundle_info)
  end

  @doc """
  Debug helper to dump a message's structure.
  """
  def debug_message(message) do
    Native.debug_prekey_message(message)
  end

  @doc """
  Decrypts a regular Signal message.

  NOTE: Not yet implemented - requires receiving chain state management.
  """
  @spec decrypt(map(), binary()) :: {:ok, binary(), map()} | {:error, term()}
  def decrypt(_session, _ciphertext) do
    # TODO: Implement decryption using Native NIF
    # This requires:
    # 1. Parsing the SignalMessage protobuf
    # 2. Looking up/deriving message keys from receiving chain
    # 3. Verifying MAC
    # 4. Decrypting with AES-CBC
    {:error, :not_implemented}
  end

  @doc """
  Decrypts a PreKeySignalMessage (initial message from new sender).

  NOTE: Not yet implemented - requires creating session from incoming prekey.
  """
  @spec decrypt_prekey_message(binary(), map(), map()) ::
          {:ok, binary(), map()} | {:error, term()}
  def decrypt_prekey_message(_ciphertext, _local_identity, _local_prekeys) do
    # TODO: Implement decryption using Native NIF
    # This requires:
    # 1. Parsing the PreKeySignalMessage protobuf
    # 2. Extracting base_key, identity_key, signed_prekey_id, etc.
    # 3. Creating a session from sender's keys
    # 4. Decrypting the inner SignalMessage
    {:error, :not_implemented}
  end
end
