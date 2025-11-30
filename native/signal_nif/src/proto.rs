//! Signal Protocol message serialization
//! 
//! This implements the exact protobuf format used by Signal/WhatsApp.

use crate::crypto;

/// Signal Protocol version constants
const MESSAGE_VERSION: u8 = 3;
const CIPHERTEXT_MESSAGE_CURRENT_VERSION: u8 = 4;

/// Version byte format: (message_version << 4) | current_version
// WhatsApp uses message_version=3, current_version=4 (matching wacore)
const VERSION_BYTE: u8 = 0x34;

/// DJB key type prefix for Curve25519 keys
const DJB_TYPE: u8 = 0x05;

/// MAC length in bytes
const MAC_LENGTH: usize = 8;

/// Build a complete SignalMessage with proper protobuf encoding and MAC
pub fn build_signal_message(
    ratchet_key: &[u8; 32],
    counter: u32,
    previous_counter: u32,
    ciphertext: &[u8],
    mac_key: &[u8; 32],
    sender_identity: &[u8; 32],
    receiver_identity: &[u8; 32],
) -> Vec<u8> {
    // Serialize ratchet key with 0x05 prefix
    let mut serialized_ratchet = Vec::with_capacity(33);
    serialized_ratchet.push(DJB_TYPE);
    serialized_ratchet.extend_from_slice(ratchet_key);
    
    // Build protobuf message
    // SignalMessage protobuf fields:
    //   optional bytes  ratchetKey      = 1;
    //   optional uint32 counter         = 2;
    //   optional uint32 previousCounter = 3;
    //   optional bytes  ciphertext      = 4;
    let proto = encode_signal_message_proto(&serialized_ratchet, counter, previous_counter, ciphertext);
    
    // Version byte + protobuf
    let mut message = Vec::with_capacity(1 + proto.len() + MAC_LENGTH);
    message.push(VERSION_BYTE);
    message.extend_from_slice(&proto);
    
    // Calculate MAC
    let mac = crypto::calculate_mac(mac_key, sender_identity, receiver_identity, &message);
    
    // Append MAC
    message.extend_from_slice(&mac);
    
    message
}

/// Build a complete PreKeySignalMessage
pub fn build_prekey_signal_message(
    registration_id: u32,
    prekey_id: Option<u32>,
    signed_prekey_id: u32,
    base_key: &[u8; 32],
    identity_key: &[u8; 32],
    signal_message: &[u8],
) -> Vec<u8> {
    // Serialize keys with 0x05 prefix
    let mut serialized_base = Vec::with_capacity(33);
    serialized_base.push(DJB_TYPE);
    serialized_base.extend_from_slice(base_key);
    
    let mut serialized_identity = Vec::with_capacity(33);
    serialized_identity.push(DJB_TYPE);
    serialized_identity.extend_from_slice(identity_key);
    
    // Build protobuf message
    // PreKeySignalMessage protobuf fields:
    //   optional uint32 preKeyId       = 1;
    //   optional bytes  baseKey        = 2;
    //   optional bytes  identityKey    = 3;
    //   optional bytes  message        = 4;
    //   optional uint32 registrationId = 5;
    //   optional uint32 signedPreKeyId = 6;
    let proto = encode_prekey_signal_message_proto(
        prekey_id,
        &serialized_base,
        &serialized_identity,
        signal_message,
        registration_id,
        signed_prekey_id,
    );
    
    // Version byte + protobuf
    let mut message = Vec::with_capacity(1 + proto.len());
    message.push(VERSION_BYTE);
    message.extend_from_slice(&proto);
    
    message
}

/// Debug: parse and display PreKeySignalMessage structure
pub fn debug_prekey_message(message: &[u8]) -> String {
    if message.is_empty() {
        return "Empty message".to_string();
    }
    
    let version = message[0];
    let mut output = format!(
        "PreKeySignalMessage ({} bytes):\n  Version byte: 0x{:02X} (msg_ver={}, cur_ver={})\n",
        message.len(),
        version,
        version >> 4,
        version & 0x0F
    );
    
    // Parse protobuf fields
    let proto = &message[1..];
    let mut pos = 0;
    
    while pos < proto.len() {
        let tag_byte = proto[pos];
        let field_num = tag_byte >> 3;
        let wire_type = tag_byte & 0x07;
        pos += 1;
        
        match wire_type {
            0 => {
                // Varint
                let (value, bytes_read) = decode_varint(&proto[pos..]);
                pos += bytes_read;
                output.push_str(&format!("  Field {}: varint = {}\n", field_num, value));
            }
            2 => {
                // Length-delimited
                let (len, bytes_read) = decode_varint(&proto[pos..]);
                pos += bytes_read;
                let len = len as usize;
                if pos + len <= proto.len() {
                    let data = &proto[pos..pos + len];
                    pos += len;
                    
                    let field_name = match field_num {
                        1 => "preKeyId",
                        2 => "baseKey",
                        3 => "identityKey",
                        4 => "message (SignalMessage)",
                        5 => "registrationId",
                        6 => "signedPreKeyId",
                        _ => "unknown",
                    };
                    
                    if data.len() <= 64 {
                        output.push_str(&format!(
                            "  Field {} ({}): {} bytes = {}\n",
                            field_num, field_name, len, hex::encode(data)
                        ));
                    } else {
                        output.push_str(&format!(
                            "  Field {} ({}): {} bytes = {}...\n",
                            field_num, field_name, len, hex::encode(&data[..32])
                        ));
                    }
                } else {
                    output.push_str(&format!("  Field {}: truncated data\n", field_num));
                    break;
                }
            }
            _ => {
                output.push_str(&format!("  Field {}: unknown wire type {}\n", field_num, wire_type));
                break;
            }
        }
    }
    
    output
}

// ============================================================================
// Protobuf encoding helpers
// ============================================================================

fn encode_signal_message_proto(
    ratchet_key: &[u8],
    counter: u32,
    previous_counter: u32,
    ciphertext: &[u8],
) -> Vec<u8> {
    let mut proto = Vec::new();
    
    // Field 1: ratchetKey (bytes)
    encode_bytes_field(&mut proto, 1, ratchet_key);
    
    // Field 2: counter (uint32) - ALWAYS encode, even if 0 (matches Go whatsmeow)
    encode_varint_field(&mut proto, 2, counter as u64);
    
    // Field 3: previousCounter (uint32) - ALWAYS encode (Go uses 0xFFFFFFFF for first message)
    encode_varint_field(&mut proto, 3, previous_counter as u64);
    
    // Field 4: ciphertext (bytes)
    encode_bytes_field(&mut proto, 4, ciphertext);
    
    proto
}

fn encode_prekey_signal_message_proto(
    prekey_id: Option<u32>,
    base_key: &[u8],
    identity_key: &[u8],
    message: &[u8],
    registration_id: u32,
    signed_prekey_id: u32,
) -> Vec<u8> {
    let mut proto = Vec::new();
    
    // Field 1: preKeyId (uint32) - optional
    if let Some(id) = prekey_id {
        encode_varint_field(&mut proto, 1, id as u64);
    }
    
    // Field 2: baseKey (bytes)
    encode_bytes_field(&mut proto, 2, base_key);
    
    // Field 3: identityKey (bytes)
    encode_bytes_field(&mut proto, 3, identity_key);
    
    // Field 4: message (bytes) - the inner SignalMessage
    encode_bytes_field(&mut proto, 4, message);
    
    // Field 5: registrationId (uint32)
    encode_varint_field(&mut proto, 5, registration_id as u64);
    
    // Field 6: signedPreKeyId (uint32)
    encode_varint_field(&mut proto, 6, signed_prekey_id as u64);
    
    proto
}

fn encode_varint_field(buf: &mut Vec<u8>, field_num: u8, value: u64) {
    // Tag: (field_num << 3) | wire_type (0 for varint)
    let tag = (field_num << 3) | 0;
    buf.push(tag);
    encode_varint(buf, value);
}

fn encode_bytes_field(buf: &mut Vec<u8>, field_num: u8, data: &[u8]) {
    // Tag: (field_num << 3) | wire_type (2 for length-delimited)
    let tag = (field_num << 3) | 2;
    buf.push(tag);
    encode_varint(buf, data.len() as u64);
    buf.extend_from_slice(data);
}

fn encode_varint(buf: &mut Vec<u8>, mut value: u64) {
    loop {
        let mut byte = (value & 0x7F) as u8;
        value >>= 7;
        if value != 0 {
            byte |= 0x80;
        }
        buf.push(byte);
        if value == 0 {
            break;
        }
    }
}

fn decode_varint(data: &[u8]) -> (u64, usize) {
    let mut value: u64 = 0;
    let mut shift = 0;
    let mut bytes_read = 0;
    
    for &byte in data {
        bytes_read += 1;
        value |= ((byte & 0x7F) as u64) << shift;
        if byte & 0x80 == 0 {
            break;
        }
        shift += 7;
    }
    
    (value, bytes_read)
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_varint_encoding() {
        let mut buf = Vec::new();
        encode_varint(&mut buf, 150);
        assert_eq!(buf, vec![0x96, 0x01]);
        
        let mut buf = Vec::new();
        encode_varint(&mut buf, 1);
        assert_eq!(buf, vec![0x01]);
        
        let mut buf = Vec::new();
        encode_varint(&mut buf, 127);
        assert_eq!(buf, vec![0x7F]);
        
        let mut buf = Vec::new();
        encode_varint(&mut buf, 128);
        assert_eq!(buf, vec![0x80, 0x01]);
    }
    
    #[test]
    fn test_signal_message_version_byte() {
        assert_eq!(VERSION_BYTE, 0x34);
    }
}
