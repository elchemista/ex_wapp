//! Key generation and management for Signal Protocol
//! Matches wacore-libsignal implementation

use x25519_dalek::{PublicKey as X25519PublicKey, StaticSecret};
use curve25519_dalek::constants::ED25519_BASEPOINT_TABLE;
use curve25519_dalek::edwards::EdwardsPoint;
use curve25519_dalek::montgomery::MontgomeryPoint;
use curve25519_dalek::scalar::Scalar;
use rand::rngs::OsRng;
use rand::{Rng, RngCore};
use sha2::{Sha512, Digest};
use subtle::ConstantTimeEq;

/// Generate a new Curve25519 key pair for X25519 key exchange
/// Returns (public_key, private_key) each as 32 bytes
pub fn generate_key_pair() -> ([u8; 32], [u8; 32]) {
    let private = StaticSecret::random_from_rng(OsRng);
    let public = X25519PublicKey::from(&private);
    
    (public.to_bytes(), private.to_bytes())
}

/// Generate a signed prekey with XEdDSA signature
/// Returns (public_key, private_key, signature)
pub fn generate_signed_prekey(identity_private: &[u8; 32]) -> ([u8; 32], [u8; 32], [u8; 64]) {
    let (public, private) = generate_key_pair();
    
    // XEdDSA signature of the public key using identity key
    let signature = xeddsa_sign(identity_private, &public);
    
    (public, private, signature)
}

/// Compute X25519 shared secret
pub fn x25519_shared_secret(private_key: &[u8; 32], public_key: &[u8; 32]) -> [u8; 32] {
    let private = StaticSecret::from(*private_key);
    let public = X25519PublicKey::from(*public_key);
    
    let shared = private.diffie_hellman(&public);
    shared.to_bytes()
}

/// XEdDSA signing (from wacore-libsignal PrivateKey::calculate_signature)
pub fn xeddsa_sign(private_key: &[u8; 32], message: &[u8]) -> [u8; 64] {
    let mut csprng = OsRng;
    let mut random_bytes = [0u8; 64];
    csprng.fill_bytes(&mut random_bytes);

    // Use the private key bytes directly (clamping is handled by scalar conversion)
    let key_data = *private_key;
    
    // Manually clamp for Scalar conversion to match X25519 behavior
    let mut clamped = key_data;
    clamped[0] &= 248;
    clamped[31] &= 127;
    clamped[31] |= 64;
    
    let a = Scalar::from_bytes_mod_order(clamped);
    let ed_public_key_point = &a * ED25519_BASEPOINT_TABLE;
    let ed_public_key = ed_public_key_point.compress();
    let sign_bit = ed_public_key.as_bytes()[31] & 0b1000_0000_u8;

    let mut hash1 = Sha512::new();
    // 32 bytes of 0xFF is the prefix wacore uses?
    // Wait, wacore uses: 0xFE then 31 0xFFs?
    // wacore code:
    // 0xFE, 0xFF... (32 bytes total)
    let mut hash_prefix = [0xFFu8; 32];
    hash_prefix[0] = 0xFE;
    
    hash1.update(&hash_prefix[..]);
    hash1.update(&key_data[..]);
    hash1.update(message);
    hash1.update(&random_bytes[..]);

    let r = Scalar::from_hash(hash1);
    let cap_r = (&r * ED25519_BASEPOINT_TABLE).compress();

    let mut hash = Sha512::new();
    hash.update(cap_r.as_bytes());
    hash.update(ed_public_key.as_bytes());
    hash.update(message);

    let h = Scalar::from_hash(hash);
    let s = (h * a) + r;

    let mut result = [0u8; 64];
    result[..32].copy_from_slice(cap_r.as_bytes());
    result[32..].copy_from_slice(s.as_bytes());
    // Set the sign bit of the public key in the last byte of the signature
    result[63] &= 0b0111_1111_u8;
    result[63] |= sign_bit;
    
    result
}

/// Verify XEdDSA signature (from wacore-libsignal PrivateKey::verify_signature)
pub fn verify_signature(public_key: &[u8; 32], message: &[u8], signature: &[u8; 64]) -> bool {
    let mont_point = MontgomeryPoint(*public_key);
    
    // Extract sign bit from signature
    let sign_bit = (signature[63] & 0b1000_0000_u8) >> 7;
    
    let ed_pub_key_point = match mont_point.to_edwards(sign_bit) {
        Some(x) => x,
        None => return false,
    };
    
    let cap_a = ed_pub_key_point.compress();
    let mut cap_r = [0u8; 32];
    cap_r.copy_from_slice(&signature[..32]);
    
    let mut s = [0u8; 32];
    s.copy_from_slice(&signature[32..]);
    // Clear the sign bit from s
    s[31] &= 0b0111_1111_u8;
    
    // Check if s is too large (unlikely if valid)
    if (s[31] & 0b1110_0000_u8) != 0 {
        return false;
    }
    
    let minus_cap_a = -ed_pub_key_point;

    let mut hash = Sha512::new();
    hash.update(&cap_r[..]);
    hash.update(cap_a.as_bytes());
    hash.update(message);
    
    let h = Scalar::from_hash(hash);

    // R' = s*B - h*A
    let cap_r_check_point = EdwardsPoint::vartime_double_scalar_mul_basepoint(
        &h,
        &minus_cap_a,
        &Scalar::from_bytes_mod_order(s),
    );
    let cap_r_check = cap_r_check_point.compress();

    // Check R' == R
    cap_r_check.as_bytes().ct_eq(&cap_r).into()
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_key_generation() {
        let (public, private) = generate_key_pair();
        assert_eq!(public.len(), 32);
        assert_eq!(private.len(), 32);
    }
    
    #[test]
    fn test_x25519_shared_secret() {
        let (pub_a, priv_a) = generate_key_pair();
        let (pub_b, priv_b) = generate_key_pair();
        
        let secret_a = x25519_shared_secret(&priv_a, &pub_b);
        let secret_b = x25519_shared_secret(&priv_b, &pub_a);
        
        assert_eq!(secret_a, secret_b);
    }
    
    #[test]
    fn test_signing_roundtrip() {
        let (pub_id, priv_id) = generate_key_pair();
        let message = b"Test message for signing";
        
        let signature = xeddsa_sign(&priv_id, message);
        let valid = verify_signature(&pub_id, message, &signature);
        
        assert!(valid, "Signature verification failed");
        
        let invalid_msg = b"Tampered message";
        let valid_tampered = verify_signature(&pub_id, invalid_msg, &signature);
        assert!(!valid_tampered, "Verification succeeded for tampered message");
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_key_generation() {
        let (public, private) = generate_key_pair();
        assert_eq!(public.len(), 32);
        assert_eq!(private.len(), 32);
    }
    
    #[test]
    fn test_x25519_shared_secret() {
        let (pub_a, priv_a) = generate_key_pair();
        let (pub_b, priv_b) = generate_key_pair();
        
        let secret_a = x25519_shared_secret(&priv_a, &pub_b);
        let secret_b = x25519_shared_secret(&priv_b, &pub_a);
        
        assert_eq!(secret_a, secret_b);
    }
}
