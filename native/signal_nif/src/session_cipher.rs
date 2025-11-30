//! Session cipher implementation ported from wacore/libsignal
//! This replicates the exact encryption flow from whatsapp-rust

use crate::crypto::{self, derive_message_keys};
use crate::keys;
use crate::proto;

/// Session state for Signal protocol
/// Matches wacore's SessionState structure
#[derive(Clone, Debug)]
pub struct SessionState {
    // Session version (always 3 for current protocol)
    pub session_version: u8,
    
    // Local identity
    pub local_identity_public: [u8; 32],
    pub local_identity_private: [u8; 32],
    pub local_registration_id: u32,
    
    // Remote identity
    pub remote_identity_public: [u8; 32],
    pub remote_registration_id: u32,
    
    // Root key for deriving new chains
    pub root_key: [u8; 32],
    
    // Sender chain
    pub sender_chain_key: [u8; 32],
    pub sender_chain_index: u32,
    pub sender_ratchet_public: [u8; 32],
    pub sender_ratchet_private: [u8; 32],
    
    // Previous counter (for detecting out-of-order messages)
    pub previous_counter: u32,
    
    // Unacknowledged prekey info (for first message)
    pub pending_prekey: Option<PendingPreKey>,
}

#[derive(Clone, Debug)]
pub struct PendingPreKey {
    pub prekey_id: Option<u32>,
    pub signed_prekey_id: u32,
    pub base_key: [u8; 32],
}

/// Initialize a new session as Alice (initiator)
/// This is the X3DH + initial ratchet step
pub fn initialize_alice_session(
    // Our keys
    local_identity_public: &[u8; 32],
    local_identity_private: &[u8; 32],
    local_registration_id: u32,
    // Their bundle
    remote_identity: &[u8; 32],
    remote_signed_prekey: &[u8; 32],
    remote_prekey: Option<&[u8; 32]>,
    remote_registration_id: u32,
    // Prekey IDs for the PreKeySignalMessage
    prekey_id: Option<u32>,
    signed_prekey_id: u32,
) -> SessionState {
    // Generate ephemeral key pair (base_key in PreKeySignalMessage)
    let (base_key_public, base_key_private) = keys::generate_key_pair();
    
    // X3DH shared secret computation
    // DH1 = DH(IKA, SPKB) - our identity with their signed prekey
    let dh1 = keys::x25519_shared_secret(local_identity_private, remote_signed_prekey);
    // DH2 = DH(EKA, IKB) - our ephemeral with their identity
    let dh2 = keys::x25519_shared_secret(&base_key_private, remote_identity);
    // DH3 = DH(EKA, SPKB) - our ephemeral with their signed prekey
    let dh3 = keys::x25519_shared_secret(&base_key_private, remote_signed_prekey);
    
    // Concatenate: 0xFF*32 || DH1 || DH2 || DH3 || DH4 (if prekey exists)
    let mut shared_secret = Vec::with_capacity(32 * 5);
    shared_secret.extend_from_slice(&[0xFFu8; 32]); // Discontinuity bytes
    shared_secret.extend_from_slice(&dh1);
    shared_secret.extend_from_slice(&dh2);
    shared_secret.extend_from_slice(&dh3);
    
    if let Some(prekey) = remote_prekey {
        let dh4 = keys::x25519_shared_secret(&base_key_private, prekey);
        shared_secret.extend_from_slice(&dh4);
    }
    
    // Derive root_key and initial chain_key from X3DH
    let (root_key, _chain_key) = crypto::hkdf_derive_initial(&shared_secret);
    
    // Generate a new sending ratchet key pair
    let (sender_ratchet_public, sender_ratchet_private) = keys::generate_key_pair();
    
    // Perform DH ratchet step to get actual sending chain
    // DH with our new ratchet key and their signed prekey (which is their ratchet key for initial message)
    let dh_ratchet = keys::x25519_shared_secret(&sender_ratchet_private, remote_signed_prekey);
    let (new_root_key, sender_chain_key) = crypto::hkdf_derive_ratchet(&dh_ratchet, &root_key);
    
    SessionState {
        session_version: 3,
        local_identity_public: *local_identity_public,
        local_identity_private: *local_identity_private,
        local_registration_id,
        remote_identity_public: *remote_identity,
        remote_registration_id,
        root_key: new_root_key,
        sender_chain_key,
        sender_chain_index: 0,
        sender_ratchet_public,
        sender_ratchet_private,
        previous_counter: 0xFFFFFFFF, // Max value for first message (no previous chain)
        pending_prekey: Some(PendingPreKey {
            prekey_id,
            signed_prekey_id,
            base_key: base_key_public,
        }),
    }
}

/// Encrypt a message using the session
/// Returns (ciphertext, updated_session)
pub fn session_encrypt(
    session: &SessionState,
    plaintext: &[u8],
) -> (Vec<u8>, SessionState, bool) {
    // Derive message keys from current chain key
    let (new_chain_key, cipher_key, mac_key, iv) = derive_message_keys(&session.sender_chain_key);
    let is_prekey = session.pending_prekey.is_some();

    // Encrypt with AES-256-CBC
    let ciphertext = crypto::encrypt_aes_cbc(plaintext, &cipher_key, &iv);
    
    // Build SignalMessage
    let signal_message = proto::build_signal_message(
        &session.sender_ratchet_public,
        session.sender_chain_index,
        session.previous_counter,
        &ciphertext,
        &mac_key,
        &session.local_identity_public,
        &session.remote_identity_public,
    );
    
    // Check if we need to wrap in PreKeySignalMessage
    let final_message = if let Some(ref pending) = session.pending_prekey {
        proto::build_prekey_signal_message(
            session.local_registration_id,
            pending.prekey_id,
            pending.signed_prekey_id,
            &pending.base_key,
            &session.local_identity_public,
            &signal_message,
        )
    } else {
        signal_message
    };
    
    // Update session state
    let mut new_session = session.clone();
    new_session.sender_chain_key = new_chain_key;
    new_session.sender_chain_index = session.sender_chain_index + 1;
    // Clear pending prekey after first message is sent
    // (In practice, we keep it until we receive a message back)
    new_session.pending_prekey = None;
    
    (final_message, new_session, is_prekey)
}

/// Check if this is the first message (needs PreKeySignalMessage wrapping)
pub fn needs_prekey_message(session: &SessionState) -> bool {
    session.pending_prekey.is_some()
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_session_creation() {
        let (local_pub, local_priv) = keys::generate_key_pair();
        let (remote_pub, _remote_priv) = keys::generate_key_pair();
        let (spk_pub, _spk_priv) = keys::generate_key_pair();
        let (opk_pub, _opk_priv) = keys::generate_key_pair();
        
        let session = initialize_alice_session(
            &local_pub,
            &local_priv,
            12345,
            &remote_pub,
            &spk_pub,
            Some(&opk_pub),
            67890,
            Some(1),
            2,
        );
        
        assert_eq!(session.session_version, 3);
        assert_eq!(session.local_registration_id, 12345);
        assert_eq!(session.remote_registration_id, 67890);
        assert_eq!(session.sender_chain_index, 0);
        assert_eq!(session.previous_counter, 0xFFFFFFFF);
        assert!(session.pending_prekey.is_some());
    }
    
    #[test]
    fn test_encrypt_produces_prekey_message() {
        let (local_pub, local_priv) = keys::generate_key_pair();
        let (remote_pub, _) = keys::generate_key_pair();
        let (spk_pub, _) = keys::generate_key_pair();
        let (opk_pub, _) = keys::generate_key_pair();
        
        let session = initialize_alice_session(
            &local_pub,
            &local_priv,
            12345,
            &remote_pub,
            &spk_pub,
            Some(&opk_pub),
            67890,
            Some(1),
            2,
        );
        
        let plaintext = b"Hello, World!";
        let (message, new_session) = session_encrypt(&session, plaintext);
        
        // First byte should be version (0x33)
        assert_eq!(message[0], 0x33);
        // Counter should increment
        assert_eq!(new_session.sender_chain_index, 1);
    }
}
