//! Signal Protocol NIF for Elixir
//!
//! This module provides Signal Protocol encryption/decryption for WhatsApp messages.
//! It implements the exact same format as the official Signal library.

pub mod crypto;
pub mod keys;
pub mod proto;
pub mod session;
pub mod session_cipher;

use rustler::{NifResult, Binary, Env, NewBinary};

rustler::init!("Elixir.ExWapp.Signal.Native");

/// Helper to convert a byte slice to a NewBinary
fn to_binary<'a>(env: Env<'a>, data: &[u8]) -> Binary<'a> {
    let mut binary = NewBinary::new(env, data.len());
    binary.as_mut_slice().copy_from_slice(data);
    binary.into()
}

/// Generate a new Curve25519 key pair
/// Returns {public_key, private_key} as binaries
#[rustler::nif]
fn generate_key_pair<'a>(env: Env<'a>) -> (Binary<'a>, Binary<'a>) {
    let (public, private) = keys::generate_key_pair();
    (to_binary(env, &public), to_binary(env, &private))
}

/// Generate a signed prekey pair
/// Returns {public_key, private_key, signature} where signature is XEdDSA
#[rustler::nif]
fn generate_signed_prekey<'a>(env: Env<'a>, identity_private: Binary<'a>) -> NifResult<(Binary<'a>, Binary<'a>, Binary<'a>)> {
    let priv_bytes: [u8; 32] = identity_private.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("identity_private must be 32 bytes")))?;
    
    let (public, private, signature) = keys::generate_signed_prekey(&priv_bytes);
    Ok((to_binary(env, &public), to_binary(env, &private), to_binary(env, &signature)))
}

/// Compute X25519 shared secret
#[rustler::nif]
fn x25519_shared_secret<'a>(env: Env<'a>, private_key: Binary<'a>, public_key: Binary<'a>) -> NifResult<Binary<'a>> {
    let priv_bytes: [u8; 32] = private_key.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("private_key must be 32 bytes")))?;
    let pub_bytes: [u8; 32] = public_key.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("public_key must be 32 bytes")))?;
    
    Ok(to_binary(env, &keys::x25519_shared_secret(&priv_bytes, &pub_bytes)))
}

/// Verify XEdDSA signature
#[rustler::nif]
fn verify_signature(public_key: Binary, message: Binary, signature: Binary) -> bool {
    if public_key.len() != 32 || signature.len() != 64 {
        return false;
    }
    
    let pub_bytes: [u8; 32] = public_key.as_slice().try_into().unwrap();
    let sig_bytes: [u8; 64] = signature.as_slice().try_into().unwrap();
    
    keys::verify_signature(&pub_bytes, message.as_slice(), &sig_bytes)
}

/// Derive initial keys from X3DH shared secret
/// Returns {root_key, chain_key} each 32 bytes
#[rustler::nif]
fn hkdf_derive_initial<'a>(env: Env<'a>, shared_secret: Binary<'a>) -> (Binary<'a>, Binary<'a>) {
    let (root_key, chain_key) = crypto::hkdf_derive_initial(shared_secret.as_slice());
    (to_binary(env, &root_key), to_binary(env, &chain_key))
}

/// Derive ratchet keys
/// Returns {new_root_key, chain_key} each 32 bytes
#[rustler::nif]
fn hkdf_derive_ratchet<'a>(env: Env<'a>, dh_output: Binary<'a>, root_key: Binary<'a>) -> NifResult<(Binary<'a>, Binary<'a>)> {
    let root: [u8; 32] = root_key.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("root_key must be 32 bytes")))?;
    
    let (new_root, chain) = crypto::hkdf_derive_ratchet(dh_output.as_slice(), &root);
    Ok((to_binary(env, &new_root), to_binary(env, &chain)))
}

/// Derive message keys from chain key
/// Returns {new_chain_key, cipher_key, mac_key, iv} (32, 32, 32, 16 bytes)
#[rustler::nif]
fn derive_message_keys<'a>(env: Env<'a>, chain_key: Binary<'a>) -> NifResult<(Binary<'a>, Binary<'a>, Binary<'a>, Binary<'a>)> {
    let chain: [u8; 32] = chain_key.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("chain_key must be 32 bytes")))?;
    
    let (new_chain_key, cipher_key, mac_key, iv) = crypto::derive_message_keys(&chain);
    Ok((to_binary(env, &new_chain_key), to_binary(env, &cipher_key), to_binary(env, &mac_key), to_binary(env, &iv)))
}

/// Encrypt plaintext with AES-256-CBC + PKCS7 padding
#[rustler::nif]
fn encrypt_aes_cbc<'a>(env: Env<'a>, plaintext: Binary<'a>, cipher_key: Binary<'a>, iv: Binary<'a>) -> NifResult<Binary<'a>> {
    let key: [u8; 32] = cipher_key.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("cipher_key must be 32 bytes")))?;
    let iv_bytes: [u8; 16] = iv.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("iv must be 16 bytes")))?;
    
    Ok(to_binary(env, &crypto::encrypt_aes_cbc(plaintext.as_slice(), &key, &iv_bytes)))
}

/// Decrypt ciphertext with AES-256-CBC + PKCS7 padding removal
#[rustler::nif]
fn decrypt_aes_cbc<'a>(env: Env<'a>, ciphertext: Binary<'a>, cipher_key: Binary<'a>, iv: Binary<'a>) -> NifResult<Binary<'a>> {
    let key: [u8; 32] = cipher_key.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("cipher_key must be 32 bytes")))?;
    let iv_bytes: [u8; 16] = iv.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("iv must be 16 bytes")))?;
    
    crypto::decrypt_aes_cbc(ciphertext.as_slice(), &key, &iv_bytes)
        .map(|data| to_binary(env, &data))
        .map_err(|e| rustler::Error::Term(Box::new(e)))
}

/// Build a complete SignalMessage with proper protobuf encoding and MAC
/// 
/// Args:
///   - ratchet_key: 32-byte sender's current ratchet public key
///   - counter: message counter
///   - previous_counter: previous chain's counter  
///   - ciphertext: AES-CBC encrypted message content
///   - mac_key: 32-byte key for HMAC
///   - sender_identity: 32-byte sender's identity public key
///   - receiver_identity: 32-byte receiver's identity public key
///
/// Returns the complete serialized SignalMessage (version || protobuf || mac)
#[rustler::nif]
fn build_signal_message<'a>(
    env: Env<'a>,
    ratchet_key: Binary<'a>,
    counter: u32,
    previous_counter: u32,
    ciphertext: Binary<'a>,
    mac_key: Binary<'a>,
    sender_identity: Binary<'a>,
    receiver_identity: Binary<'a>,
) -> NifResult<Binary<'a>> {
    let ratchet: [u8; 32] = ratchet_key.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("ratchet_key must be 32 bytes")))?;
    let mac: [u8; 32] = mac_key.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("mac_key must be 32 bytes")))?;
    let sender: [u8; 32] = sender_identity.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("sender_identity must be 32 bytes")))?;
    let receiver: [u8; 32] = receiver_identity.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("receiver_identity must be 32 bytes")))?;
    
    Ok(to_binary(env, &proto::build_signal_message(
        &ratchet,
        counter,
        previous_counter,
        ciphertext.as_slice(),
        &mac,
        &sender,
        &receiver,
    )))
}

/// Build a complete PreKeySignalMessage
///
/// Args:
///   - registration_id: sender's registration ID
///   - prekey_id: optional one-time prekey ID (0 if not used)
///   - signed_prekey_id: signed prekey ID
///   - base_key: 32-byte ephemeral public key from X3DH
///   - identity_key: 32-byte sender's identity public key
///   - signal_message: already-serialized SignalMessage bytes
///
/// Returns the complete serialized PreKeySignalMessage
#[rustler::nif]
fn build_prekey_signal_message<'a>(
    env: Env<'a>,
    registration_id: u32,
    prekey_id: u32,
    signed_prekey_id: u32,
    base_key: Binary<'a>,
    identity_key: Binary<'a>,
    signal_message: Binary<'a>,
) -> NifResult<Binary<'a>> {
    let base: [u8; 32] = base_key.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("base_key must be 32 bytes")))?;
    let identity: [u8; 32] = identity_key.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("identity_key must be 32 bytes")))?;
    
    Ok(to_binary(env, &proto::build_prekey_signal_message(
        registration_id,
        if prekey_id == 0 { None } else { Some(prekey_id) },
        signed_prekey_id,
        &base,
        &identity,
        signal_message.as_slice(),
    )))
}

/// Full message encryption for WhatsApp
/// This does everything: derives keys, encrypts, builds SignalMessage, optionally wraps in PreKeySignalMessage
///
/// Args:
///   - plaintext: message to encrypt
///   - chain_key: current sending chain key (32 bytes)
///   - ratchet_private: our ratchet private key (32 bytes)
///   - ratchet_public: our ratchet public key (32 bytes)
///   - counter: current message counter
///   - previous_counter: previous chain counter
///   - sender_identity: our identity public key (32 bytes)
///   - receiver_identity: their identity public key (32 bytes)
///   - is_prekey: whether to wrap in PreKeySignalMessage
///   - registration_id: our registration ID (only needed if is_prekey)
///   - prekey_id: one-time prekey ID (only needed if is_prekey, 0 if not used)
///   - signed_prekey_id: signed prekey ID (only needed if is_prekey)
///   - base_key: ephemeral key from X3DH (only needed if is_prekey, 32 bytes)
///
/// Returns {encrypted_message, new_chain_key, new_counter}
#[rustler::nif]
fn encrypt_message<'a>(
    env: Env<'a>,
    plaintext: Binary<'a>,
    chain_key: Binary<'a>,
    ratchet_public: Binary<'a>,
    counter: u32,
    previous_counter: u32,
    sender_identity: Binary<'a>,
    receiver_identity: Binary<'a>,
    is_prekey: bool,
    registration_id: u32,
    prekey_id: u32,
    signed_prekey_id: u32,
    base_key: Binary<'a>,
) -> NifResult<(Binary<'a>, Binary<'a>, u32)> {
    let chain: [u8; 32] = chain_key.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("chain_key must be 32 bytes")))?;
    let ratchet: [u8; 32] = ratchet_public.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("ratchet_public must be 32 bytes")))?;
    let sender: [u8; 32] = sender_identity.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("sender_identity must be 32 bytes")))?;
    let receiver: [u8; 32] = receiver_identity.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("receiver_identity must be 32 bytes")))?;
    
    // Derive message keys
    let (new_chain_key, cipher_key, mac_key, iv) = crypto::derive_message_keys(&chain);
    
    // Encrypt with AES-CBC
    let ciphertext = crypto::encrypt_aes_cbc(plaintext.as_slice(), &cipher_key, &iv);
    
    // Build SignalMessage
    let signal_message = proto::build_signal_message(
        &ratchet,
        counter,
        previous_counter,
        &ciphertext,
        &mac_key,
        &sender,
        &receiver,
    );
    
    // Optionally wrap in PreKeySignalMessage
    let final_message = if is_prekey {
        let base: [u8; 32] = base_key.as_slice()
            .try_into()
            .map_err(|_| rustler::Error::Term(Box::new("base_key must be 32 bytes")))?;
        
        proto::build_prekey_signal_message(
            registration_id,
            if prekey_id == 0 { None } else { Some(prekey_id) },
            signed_prekey_id,
            &base,
            &sender,
            &signal_message,
        )
    } else {
        signal_message
    };
    
    Ok((to_binary(env, &final_message), to_binary(env, &new_chain_key), counter + 1))
}

/// Debug: dump the hex of a PreKeySignalMessage with field breakdown
#[rustler::nif]
fn debug_prekey_message(message: Binary) -> String {
    proto::debug_prekey_message(message.as_slice())
}

// ============================================================================
// Complete Session Cipher Functions (ported from wacore)
// ============================================================================

/// Create a new Signal session as the initiator (Alice)
/// This performs X3DH key agreement and initializes the session state
/// 
/// Returns a serialized session state that can be passed to session_encrypt
#[rustler::nif]
fn create_outbound_session<'a>(
    env: Env<'a>,
    local_identity_public: Binary<'a>,
    local_identity_private: Binary<'a>,
    local_registration_id: u32,
    remote_identity: Binary<'a>,
    remote_signed_prekey: Binary<'a>,
    remote_prekey: Binary<'a>,  // Empty if no one-time prekey
    remote_registration_id: u32,
    prekey_id: u32,  // 0 if no prekey
    signed_prekey_id: u32,
) -> NifResult<Binary<'a>> {
    let local_pub: [u8; 32] = local_identity_public.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("local_identity_public must be 32 bytes")))?;
    let local_priv: [u8; 32] = local_identity_private.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("local_identity_private must be 32 bytes")))?;
    let remote_id: [u8; 32] = remote_identity.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("remote_identity must be 32 bytes")))?;
    let remote_spk: [u8; 32] = remote_signed_prekey.as_slice()
        .try_into()
        .map_err(|_| rustler::Error::Term(Box::new("remote_signed_prekey must be 32 bytes")))?;
    
    let remote_opk: Option<[u8; 32]> = if remote_prekey.as_slice().len() == 32 {
        Some(remote_prekey.as_slice().try_into().unwrap())
    } else {
        None
    };
    
    let prekey = if prekey_id == 0 { None } else { Some(prekey_id) };
    
    let session = session_cipher::initialize_alice_session(
        &local_pub,
        &local_priv,
        local_registration_id,
        &remote_id,
        &remote_spk,
        remote_opk.as_ref(),
        remote_registration_id,
        prekey,
        signed_prekey_id,
    );
    
    // Serialize session state to binary
    let serialized = serialize_session(&session);
    Ok(to_binary(env, &serialized))
}

/// Encrypt a message using a session
/// Takes serialized session state and returns (encrypted_message, updated_session)
#[rustler::nif]
fn session_encrypt_message<'a>(
    env: Env<'a>,
    session_data: Binary<'a>,
    plaintext: Binary<'a>,
) -> NifResult<(Binary<'a>, Binary<'a>, bool)> {
    let session = deserialize_session(session_data.as_slice())
        .map_err(|e| rustler::Error::Term(Box::new(e)))?;
    
    let (message, new_session, is_prekey) =
        session_cipher::session_encrypt(&session, plaintext.as_slice());
    
    let new_session_data = serialize_session(&new_session);
    Ok((to_binary(env, &message), to_binary(env, &new_session_data), is_prekey))
}

// Session serialization helpers
fn serialize_session(session: &session_cipher::SessionState) -> Vec<u8> {
    let mut data = Vec::with_capacity(512);
    
    // Version byte
    data.push(session.session_version);
    
    // Local identity
    data.extend_from_slice(&session.local_identity_public);
    data.extend_from_slice(&session.local_identity_private);
    data.extend_from_slice(&session.local_registration_id.to_le_bytes());
    
    // Remote identity
    data.extend_from_slice(&session.remote_identity_public);
    data.extend_from_slice(&session.remote_registration_id.to_le_bytes());
    
    // Root key
    data.extend_from_slice(&session.root_key);
    
    // Sender chain
    data.extend_from_slice(&session.sender_chain_key);
    data.extend_from_slice(&session.sender_chain_index.to_le_bytes());
    data.extend_from_slice(&session.sender_ratchet_public);
    data.extend_from_slice(&session.sender_ratchet_private);
    
    // Previous counter
    data.extend_from_slice(&session.previous_counter.to_le_bytes());
    
    // Pending prekey (optional)
    match &session.pending_prekey {
        Some(pk) => {
            data.push(1); // Has pending prekey
            data.push(if pk.prekey_id.is_some() { 1 } else { 0 });
            if let Some(id) = pk.prekey_id {
                data.extend_from_slice(&id.to_le_bytes());
            } else {
                data.extend_from_slice(&0u32.to_le_bytes());
            }
            data.extend_from_slice(&pk.signed_prekey_id.to_le_bytes());
            data.extend_from_slice(&pk.base_key);
        }
        None => {
            data.push(0); // No pending prekey
        }
    }
    
    data
}

fn deserialize_session(data: &[u8]) -> Result<session_cipher::SessionState, &'static str> {
    if data.len() < 200 {
        return Err("session data too short");
    }
    
    let mut pos = 0;
    
    // Version byte
    let session_version = data[pos];
    pos += 1;
    
    // Local identity
    let mut local_identity_public = [0u8; 32];
    local_identity_public.copy_from_slice(&data[pos..pos+32]);
    pos += 32;
    
    let mut local_identity_private = [0u8; 32];
    local_identity_private.copy_from_slice(&data[pos..pos+32]);
    pos += 32;
    
    let local_registration_id = u32::from_le_bytes(data[pos..pos+4].try_into().unwrap());
    pos += 4;
    
    // Remote identity
    let mut remote_identity_public = [0u8; 32];
    remote_identity_public.copy_from_slice(&data[pos..pos+32]);
    pos += 32;
    
    let remote_registration_id = u32::from_le_bytes(data[pos..pos+4].try_into().unwrap());
    pos += 4;
    
    // Root key
    let mut root_key = [0u8; 32];
    root_key.copy_from_slice(&data[pos..pos+32]);
    pos += 32;
    
    // Sender chain
    let mut sender_chain_key = [0u8; 32];
    sender_chain_key.copy_from_slice(&data[pos..pos+32]);
    pos += 32;
    
    let sender_chain_index = u32::from_le_bytes(data[pos..pos+4].try_into().unwrap());
    pos += 4;
    
    let mut sender_ratchet_public = [0u8; 32];
    sender_ratchet_public.copy_from_slice(&data[pos..pos+32]);
    pos += 32;
    
    let mut sender_ratchet_private = [0u8; 32];
    sender_ratchet_private.copy_from_slice(&data[pos..pos+32]);
    pos += 32;
    
    // Previous counter
    let previous_counter = u32::from_le_bytes(data[pos..pos+4].try_into().unwrap());
    pos += 4;
    
    // Pending prekey
    let has_pending = data[pos] == 1;
    pos += 1;
    
    let pending_prekey = if has_pending {
        let has_prekey_id = data[pos] == 1;
        pos += 1;
        
        let prekey_id_val = u32::from_le_bytes(data[pos..pos+4].try_into().unwrap());
        pos += 4;
        let prekey_id = if has_prekey_id { Some(prekey_id_val) } else { None };
        
        let signed_prekey_id = u32::from_le_bytes(data[pos..pos+4].try_into().unwrap());
        pos += 4;
        
        let mut base_key = [0u8; 32];
        base_key.copy_from_slice(&data[pos..pos+32]);
        
        Some(session_cipher::PendingPreKey {
            prekey_id,
            signed_prekey_id,
            base_key,
        })
    } else {
        None
    };
    
    Ok(session_cipher::SessionState {
        session_version,
        local_identity_public,
        local_identity_private,
        local_registration_id,
        remote_identity_public,
        remote_registration_id,
        root_key,
        sender_chain_key,
        sender_chain_index,
        sender_ratchet_public,
        sender_ratchet_private,
        previous_counter,
        pending_prekey,
    })
}
