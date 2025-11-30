//! Cryptographic primitives for Signal Protocol
//! Copied from wacore-libsignal for exact compatibility

use aes::Aes256;
use aes::cipher::block_padding::Pkcs7;
use aes::cipher::{BlockDecryptMut, BlockEncryptMut, KeyIvInit};
use hmac::{Hmac, Mac};
use hkdf::Hkdf;
use sha2::Sha256;

// HKDF info strings - must match Signal protocol exactly!
const HKDF_INFO_TEXT: &[u8] = b"WhisperText";
const HKDF_INFO_RATCHET: &[u8] = b"WhisperRatchet";
const HKDF_INFO_MESSAGE_KEYS: &[u8] = b"WhisperMessageKeys";

/// Initial X3DH key derivation (from wacore-libsignal ratchet.rs)
/// Input: concatenated DH outputs (with 32-byte 0xFF prefix)
/// Output: (root_key, chain_key) each 32 bytes
/// 
/// CRITICAL: Uses None for salt, not Some(&[0u8; 32])!
pub fn hkdf_derive_initial(shared_secret: &[u8]) -> ([u8; 32], [u8; 32]) {
    // From wacore-libsignal: hkdf::Hkdf::new(None, secret_input)
    let hk = Hkdf::<Sha256>::new(None, shared_secret);
    let mut okm = [0u8; 64];
    hk.expand(HKDF_INFO_TEXT, &mut okm).expect("HKDF expand failed");
    
    let mut root_key = [0u8; 32];
    let mut chain_key = [0u8; 32];
    root_key.copy_from_slice(&okm[..32]);
    chain_key.copy_from_slice(&okm[32..64]);
    
    (root_key, chain_key)
}

/// DH Ratchet key derivation (from wacore-libsignal RootKey::create_chain)
/// Input: DH output, current root key
/// Output: (new_root_key, chain_key) each 32 bytes
pub fn hkdf_derive_ratchet(dh_output: &[u8], root_key: &[u8; 32]) -> ([u8; 32], [u8; 32]) {
    // From wacore-libsignal: hkdf::Hkdf::new(Some(&self.key), &shared_secret)
    let hk = Hkdf::<Sha256>::new(Some(root_key), dh_output);
    let mut okm = [0u8; 64];
    hk.expand(HKDF_INFO_RATCHET, &mut okm).expect("HKDF expand failed");
    
    let mut new_root = [0u8; 32];
    let mut chain = [0u8; 32];
    new_root.copy_from_slice(&okm[..32]);
    chain.copy_from_slice(&okm[32..64]);
    
    (new_root, chain)
}

/// Derive message keys from chain key (from wacore-libsignal ChainKey + MessageKeys)
/// Signal Protocol constants:
/// - MESSAGE_KEY_SEED = 0x01
/// - CHAIN_KEY_SEED = 0x02
/// Output: (new_chain_key, cipher_key, mac_key, iv)
pub fn derive_message_keys(chain_key: &[u8; 32]) -> ([u8; 32], [u8; 32], [u8; 32], [u8; 16]) {
    // Step 1: Derive message_key_seed using HMAC (ChainKey::message_keys)
    let message_key_seed = hmac_sha256(chain_key, &[0x01]);
    // Step 2: Derive new chain key using HMAC (ChainKey::next_chain_key)  
    let new_chain_key_bytes = hmac_sha256(chain_key, &[0x02]);
    
    let mut new_chain_key = [0u8; 32];
    new_chain_key.copy_from_slice(&new_chain_key_bytes);
    
    // Step 3: Use HKDF to expand message_key_seed (MessageKeys::derive_keys)
    // CRITICAL: Uses None for salt!
    let hk = Hkdf::<Sha256>::new(None, &message_key_seed);
    let mut okm = [0u8; 80];
    hk.expand(HKDF_INFO_MESSAGE_KEYS, &mut okm).expect("HKDF expand failed");
    
    let mut cipher_key = [0u8; 32];
    let mut mac_key = [0u8; 32];
    let mut iv = [0u8; 16];
    
    cipher_key.copy_from_slice(&okm[..32]);
    mac_key.copy_from_slice(&okm[32..64]);
    iv.copy_from_slice(&okm[64..80]);
    
    (new_chain_key, cipher_key, mac_key, iv)
}

/// Public HMAC-SHA256 (from wacore-libsignal protocol/crypto.rs)
pub fn hmac_sha256(key: &[u8], data: &[u8]) -> [u8; 32] {
    let mut mac = Hmac::<Sha256>::new_from_slice(key)
        .expect("HMAC-SHA256 should accept any size key");
    mac.update(data);
    mac.finalize().into_bytes().into()
}

/// Encrypt with AES-256-CBC + PKCS7 padding (from wacore-libsignal aes_cbc.rs)
pub fn encrypt_aes_cbc(plaintext: &[u8], key: &[u8; 32], iv: &[u8; 16]) -> Vec<u8> {
    // Exact copy of wacore-libsignal aes_256_cbc_encrypt
    cbc::Encryptor::<Aes256>::new_from_slices(key, iv)
        .expect("valid key/iv")
        .encrypt_padded_vec_mut::<Pkcs7>(plaintext)
}

/// Decrypt with AES-256-CBC + PKCS7 padding (from wacore-libsignal aes_cbc.rs)
pub fn decrypt_aes_cbc(ciphertext: &[u8], key: &[u8; 32], iv: &[u8; 16]) -> Result<Vec<u8>, String> {
    if ciphertext.is_empty() || ciphertext.len() % 16 != 0 {
        return Err("ciphertext length must be a non-zero multiple of 16".to_string());
    }
    
    cbc::Decryptor::<Aes256>::new_from_slices(key, iv)
        .map_err(|_| "bad key or iv".to_string())?
        .decrypt_padded_vec_mut::<Pkcs7>(ciphertext)
        .map_err(|_| "failed to decrypt".to_string())
}

/// Calculate MAC for SignalMessage (8 bytes, truncated HMAC-SHA256)
/// MAC is over: sender_identity_key || receiver_identity_key || message_data
pub fn calculate_mac(
    mac_key: &[u8; 32],
    sender_identity: &[u8; 32],
    receiver_identity: &[u8; 32],
    data: &[u8],
) -> [u8; 8] {
    let mut mac = Hmac::<Sha256>::new_from_slice(mac_key)
        .expect("HMAC can take any size key");
    
    // Serialize keys with 0x05 prefix (Curve25519 type)
    mac.update(&[0x05]);
    mac.update(sender_identity);
    mac.update(&[0x05]);
    mac.update(receiver_identity);
    mac.update(data);
    
    let result = mac.finalize();
    let mut output = [0u8; 8];
    output.copy_from_slice(&result.into_bytes()[..8]);
    output
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_aes_cbc_roundtrip() {
        let key = [0u8; 32];
        let iv = [0u8; 16];
        let plaintext = b"Hello, Signal!";
        
        let ciphertext = encrypt_aes_cbc(plaintext, &key, &iv);
        let decrypted = decrypt_aes_cbc(&ciphertext, &key, &iv).unwrap();
        
        assert_eq!(plaintext.as_slice(), decrypted.as_slice());
    }
    
    #[test]
    fn test_message_key_derivation() {
        let chain_key = [0u8; 32];
        let (new_chain, cipher, mac, iv) = derive_message_keys(&chain_key);
        
        assert_eq!(new_chain.len(), 32);
        assert_eq!(cipher.len(), 32);
        assert_eq!(mac.len(), 32);
        assert_eq!(iv.len(), 16);
        
        // Derived keys should be different from input
        assert_ne!(new_chain, chain_key);
    }
}
