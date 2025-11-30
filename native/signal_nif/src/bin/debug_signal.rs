//! Debug binary for Signal protocol encryption
//! Run with: RUST_LOG=debug cargo run --bin debug_signal

use signal_nif::session_cipher::{initialize_alice_session, session_encrypt};
use signal_nif::keys;

fn main() {
    env_logger::init();
    
    println!("=== Signal Protocol Debug Tool ===\n");
    
    // Test with fixed keys for reproducibility
    println!("--- Generating Keys ---");
    
    // Local identity (sender)
    let (local_identity_pub, local_identity_priv) = keys::generate_key_pair();
    println!("Local identity public:  {}", hex::encode(&local_identity_pub));
    println!("Local identity private: {}", hex::encode(&local_identity_priv));
    
    // Remote identity (recipient)
    let (remote_identity_pub, _remote_identity_priv) = keys::generate_key_pair();
    println!("Remote identity public: {}", hex::encode(&remote_identity_pub));
    
    // Signed prekey (from recipient's bundle)
    let (signed_prekey_pub, _signed_prekey_priv) = keys::generate_key_pair();
    println!("Signed prekey public:   {}", hex::encode(&signed_prekey_pub));
    
    // One-time prekey (from recipient's bundle)
    let (prekey_pub, _prekey_priv) = keys::generate_key_pair();
    println!("Prekey public:          {}", hex::encode(&prekey_pub));
    
    let local_reg_id = 12345u32;
    let remote_reg_id = 67890u32;
    let prekey_id = 100u32;
    let signed_prekey_id = 200u32;
    
    println!("\nLocal registration ID:  {}", local_reg_id);
    println!("Remote registration ID: {}", remote_reg_id);
    println!("Prekey ID:              {}", prekey_id);
    println!("Signed prekey ID:       {}", signed_prekey_id);
    
    println!("\n--- Creating Session (X3DH) ---");
    
    let session = initialize_alice_session(
        &local_identity_pub,
        &local_identity_priv,
        local_reg_id,
        &remote_identity_pub,
        &signed_prekey_pub,
        Some(&prekey_pub),
        remote_reg_id,
        Some(prekey_id),
        signed_prekey_id,
    );
    
    println!("Session created:");
    println!("  Version:              {}", session.session_version);
    println!("  Root key:             {}", hex::encode(&session.root_key));
    println!("  Sender chain key:     {}", hex::encode(&session.sender_chain_key));
    println!("  Sender chain index:   {}", session.sender_chain_index);
    println!("  Sender ratchet pub:   {}", hex::encode(&session.sender_ratchet_public));
    println!("  Previous counter:     0x{:08X}", session.previous_counter);
    
    if let Some(ref pending) = session.pending_prekey {
        println!("  Pending prekey:");
        println!("    prekey_id:          {:?}", pending.prekey_id);
        println!("    signed_prekey_id:   {}", pending.signed_prekey_id);
        println!("    base_key:           {}", hex::encode(&pending.base_key));
    }
    
    println!("\n--- Encrypting Message ---");
    
    let plaintext = b"Hello, World!";
    let padded = pad_message(plaintext);
    
    println!("Plaintext ({} bytes):    {:?}", plaintext.len(), String::from_utf8_lossy(plaintext));
    println!("Padded ({} bytes):       {}", padded.len(), hex::encode(&padded));
    
    let (encrypted, new_session, is_prekey) = session_encrypt(&session, &padded);
    
    println!("\n--- Encrypted Message ---");
    println!("Total size: {} bytes", encrypted.len());
    println!("Type: {}", if is_prekey { "prekey" } else { "whisper" });
    println!("Hex dump:");
    hex_dump(&encrypted);
    
    println!("\n--- Parsing Encrypted Message ---");
    parse_prekey_signal_message(&encrypted);
    
    println!("\n--- Session After Encrypt ---");
    println!("  Sender chain key:     {}", hex::encode(&new_session.sender_chain_key));
    println!("  Sender chain index:   {}", new_session.sender_chain_index);
    
    println!("\n=== Done ===");
}

fn pad_message(msg: &[u8]) -> Vec<u8> {
    // Same padding as in WhatsApp/Signal
    let pad_len = 16 - (msg.len() % 16);
    let mut padded = msg.to_vec();
    padded.resize(msg.len() + pad_len, pad_len as u8);
    padded
}

fn hex_dump(data: &[u8]) {
    for (i, chunk) in data.chunks(16).enumerate() {
        print!("{:04X}: ", i * 16);
        for b in chunk {
            print!("{:02X} ", b);
        }
        // Pad if last chunk is short
        for _ in chunk.len()..16 {
            print!("   ");
        }
        print!(" |");
        for b in chunk {
            if *b >= 0x20 && *b < 0x7F {
                print!("{}", *b as char);
            } else {
                print!(".");
            }
        }
        println!("|");
    }
}

fn parse_prekey_signal_message(data: &[u8]) {
    if data.is_empty() {
        println!("ERROR: Empty message");
        return;
    }
    
    let version = data[0];
    println!("Version byte: 0x{:02X} (message_ver={}, current_ver={})", 
             version, version >> 4, version & 0x0F);
    
    if version != 0x34 {
        println!("WARNING: Expected version 0x34!");
    }
    
    // Parse protobuf fields
    let mut pos = 1;
    while pos < data.len() {
        if pos >= data.len() {
            break;
        }
        
        let tag_byte = data[pos];
        let field_num = tag_byte >> 3;
        let wire_type = tag_byte & 0x07;
        
        pos += 1;
        
        match wire_type {
            0 => {
                // Varint
                let (value, new_pos) = decode_varint(&data[pos..]);
                pos += new_pos;
                println!("Field {}: varint = {} (0x{:X})", field_num, value, value);
            }
            2 => {
                // Length-delimited
                let (length, new_pos) = decode_varint(&data[pos..]);
                pos += new_pos;
                let length = length as usize;
                
                if pos + length > data.len() {
                    println!("Field {}: length-delimited, {} bytes (TRUNCATED!)", field_num, length);
                    break;
                }
                
                let field_data = &data[pos..pos + length];
                pos += length;
                
                if length == 33 && field_data[0] == 0x05 {
                    println!("Field {}: key (33 bytes) = 05{}", field_num, hex::encode(&field_data[1..]));
                } else if field_num == 4 {
                    // Inner SignalMessage
                    println!("Field {}: SignalMessage ({} bytes)", field_num, length);
                    parse_signal_message(field_data);
                } else {
                    println!("Field {}: bytes ({} bytes) = {}", field_num, length, 
                             if length <= 32 { hex::encode(field_data) } else { format!("{}...", hex::encode(&field_data[..32])) });
                }
            }
            _ => {
                println!("Field {}: unknown wire type {}", field_num, wire_type);
                break;
            }
        }
    }
}

fn parse_signal_message(data: &[u8]) {
    if data.is_empty() {
        println!("  ERROR: Empty SignalMessage");
        return;
    }
    
    let version = data[0];
    println!("  Version byte: 0x{:02X}", version);
    
    // Last 8 bytes are MAC
    if data.len() < 9 {
        println!("  ERROR: SignalMessage too short");
        return;
    }
    
    let mac = &data[data.len() - 8..];
    println!("  MAC (8 bytes): {}", hex::encode(mac));
    
    // Parse protobuf (between version and MAC)
    let proto_data = &data[1..data.len() - 8];
    let mut pos = 0;
    
    while pos < proto_data.len() {
        let tag_byte = proto_data[pos];
        let field_num = tag_byte >> 3;
        let wire_type = tag_byte & 0x07;
        pos += 1;
        
        match wire_type {
            0 => {
                let (value, new_pos) = decode_varint(&proto_data[pos..]);
                pos += new_pos;
                println!("  Field {}: varint = {} (0x{:X})", field_num, value, value);
            }
            2 => {
                let (length, new_pos) = decode_varint(&proto_data[pos..]);
                pos += new_pos;
                let length = length as usize;
                
                if pos + length > proto_data.len() {
                    println!("  Field {}: length-delimited, {} bytes (TRUNCATED!)", field_num, length);
                    break;
                }
                
                let field_data = &proto_data[pos..pos + length];
                pos += length;
                
                if length == 33 && field_data[0] == 0x05 {
                    println!("  Field {}: key (33 bytes) = 05{}", field_num, hex::encode(&field_data[1..]));
                } else {
                    println!("  Field {}: bytes ({} bytes) = {}", field_num, length,
                             if length <= 32 { hex::encode(field_data) } else { format!("{}...", hex::encode(&field_data[..32])) });
                }
            }
            _ => {
                println!("  Field {}: unknown wire type {}", field_num, wire_type);
                break;
            }
        }
    }
}

fn decode_varint(data: &[u8]) -> (u64, usize) {
    let mut result: u64 = 0;
    let mut shift = 0;
    let mut pos = 0;
    
    for &byte in data {
        result |= ((byte & 0x7F) as u64) << shift;
        pos += 1;
        if byte & 0x80 == 0 {
            break;
        }
        shift += 7;
    }
    
    (result, pos)
}
