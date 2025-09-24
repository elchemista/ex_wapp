use aes_gcm::aead::{Aead, KeyInit, Payload};
use aes_gcm::Aes256Gcm;
use hkdf::Hkdf;
use prost::Message;
use rand::{rng, RngCore};
use rustler::{types::binary::Binary, Env, Error as NifError, NifResult, ResourceArc, Term};
use sha2::{Digest, Sha256 as Sha256Digest};
use std::sync::Mutex;
use thiserror::Error;
use waproto::whatsapp as wa;
use waproto::whatsapp::{CertChain, HandshakeMessage};
use x25519_dalek::{PublicKey, StaticSecret};

const NOISE_PROLOGUE: &str = "Noise_XX_25519_AESGCM_SHA256\x00\x00\x00\x00";
const WA_MAGIC_VALUE: u8 = 6;
const DICT_VERSION: u8 = 4;
const WA_CONN_HEADER: [u8; 4] = [b'W', b'A', WA_MAGIC_VALUE, DICT_VERSION];

// Known issuer serial for WA's Noise certificate root
const WA_CERT_ISSUER_SERIAL: i64 = 0;

#[derive(Debug, Error)]
enum HsError {
    #[error("protobuf encode: {0}")]
    ProtoEncode(#[from] prost::EncodeError),
    #[error("protobuf decode: {0}")]
    ProtoDecode(#[from] prost::DecodeError),
    #[error("handshake response missing required parts")]
    IncompleteResponse,
    #[error("crypto: {0}")]
    Crypto(String),
    #[error("cert verification: {0}")]
    CertVerification(String),
    #[error("invalid length for {name}: expected {expected}, got {got}")]
    InvalidLength {
        name: &'static str,
        expected: usize,
        got: usize,
    },
    #[error("mutex poisoned")]
    MutexPoisoned,
    #[error("handshake already finished")]
    AlreadyFinished,
    #[error("invalid handshake state: {0}")]
    State(&'static str),
}

impl From<HsError> for NifError {
    fn from(e: HsError) -> Self {
        NifError::Term(Box::new(e.to_string()))
    }
}

#[derive(Copy, Clone)]
struct KeyPair {
    private: [u8; 32],
    public: [u8; 32],
}

impl KeyPair {
    fn generate() -> Self {
        let mut private = [0u8; 32];
        rng().fill_bytes(&mut private);
        // clamp for X25519
        private[0] &= 248;
        private[31] &= 127;
        private[31] |= 64;
        let secret = StaticSecret::from(private);
        let public = PublicKey::from(&secret);
        Self {
            private,
            public: public.to_bytes(),
        }
    }

    fn from_private(mut private: [u8; 32]) -> Self {
        private[0] &= 248;
        private[31] &= 127;
        private[31] |= 64;
        let secret = StaticSecret::from(private);
        let public = PublicKey::from(&secret);
        Self {
            private,
            public: public.to_bytes(),
        }
    }

    #[inline]
    fn public_bytes(&self) -> [u8; 32] {
        self.public
    }

    #[inline]
    fn private_bytes(&self) -> [u8; 32] {
        self.private
    }

    fn dh(private: &[u8; 32], public: &[u8; 32]) -> [u8; 32] {
        let sk = StaticSecret::from(*private);
        let pk = PublicKey::from(*public);
        sk.diffie_hellman(&pk).to_bytes()
    }
}

#[derive(Clone)]
struct CipherState {
    key: Aes256Gcm,
    ctr: u32,
}

impl CipherState {
    fn new(key_bytes: &[u8; 32]) -> Result<Self, HsError> {
        let key = Aes256Gcm::new_from_slice(key_bytes)
            .map_err(|_| HsError::Crypto("invalid AES-256 key".into()))?;
        Ok(Self { key, ctr: 0 })
    }

    fn next_iv(&mut self) -> [u8; 12] {
        let mut iv = [0u8; 12];
        iv[8..].copy_from_slice(&self.ctr.to_be_bytes());
        self.ctr = self.ctr.wrapping_add(1);
        iv
    }

    fn encrypt_aad(&mut self, aad: &[u8], plaintext: &[u8]) -> Result<Vec<u8>, HsError> {
        let iv = self.next_iv();
        let payload = Payload {
            msg: plaintext,
            aad,
        };
        self.key
            .encrypt(iv.as_ref().into(), payload)
            .map_err(|e| HsError::Crypto(e.to_string()))
    }

    fn decrypt_aad(&mut self, aad: &[u8], ciphertext: &[u8]) -> Result<Vec<u8>, HsError> {
        let iv = self.next_iv();
        let payload = Payload {
            msg: ciphertext,
            aad,
        };
        self.key
            .decrypt(iv.as_ref().into(), payload)
            .map_err(|e| HsError::Crypto(e.to_string()))
    }
}

struct NoiseState {
    // running handshake hash ("h")
    h: [u8; 32],
    // chaining key ("ck" / salt)
    ck: [u8; 32],
    // current handshake cipher state (used for both encrypt/decrypt during handshake)
    cipher: CipherState,
}

impl NoiseState {
    fn new(prologue: &str, first_auth: &[u8]) -> Result<Self, HsError> {
        // h0 = SHA256(prologue)
        let mut h = [0u8; 32];
        if prologue.as_bytes().len() == 32 {
            h.copy_from_slice(prologue.as_bytes());
        } else {
            let mut hasher = <Sha256Digest as Digest>::new();
            hasher.update(prologue.as_bytes());
            h.copy_from_slice(&hasher.finalize());
        }

        // ck starts as h
        let ck = h;

        // Initial symmetric key: WhatsApp uses AES-GCM with AAD = running h.
        let cipher = CipherState::new(&h)?;

        let mut this = Self { h, ck, cipher };
        this.mix_hash(first_auth);
        Ok(this)
    }

    #[inline]
    fn mix_hash(&mut self, data: &[u8]) {
        let mut hasher = <Sha256Digest as Digest>::new();
        hasher.update(&self.h);
        hasher.update(data);
        self.h.copy_from_slice(&hasher.finalize());
    }

    fn kdf_2(&self, input: Option<&[u8]>) -> Result<([u8; 32], [u8; 32]), HsError> {
        let hk = Hkdf::<sha2::Sha256>::new(Some(&self.ck), input.unwrap_or(&[]));
        let mut okm = [0u8; 64];
        hk.expand(&[], &mut okm)
            .map_err(|_| HsError::Crypto("HKDF expand failed".into()))?;
        let mut out1 = [0u8; 32];
        let mut out2 = [0u8; 32];
        out1.copy_from_slice(&okm[..32]);
        out2.copy_from_slice(&okm[32..]);
        Ok((out1, out2))
    }

    /// Mix a DH shared secret, reset counters, set new handshake key, and update ck.
    fn mix_dh(&mut self, dh: &[u8; 32]) -> Result<(), HsError> {
        // WhatsApp convention: first half becomes next chaining key, second half the active cipher key.
        let (next_ck, cipher_key) = self.kdf_2(Some(dh))?;
        self.ck = next_ck;
        self.cipher = CipherState::new(&cipher_key)?;
        Ok(())
    }

    fn finish_split(&self) -> Result<([u8; 32], [u8; 32]), HsError> {
        // final split: derive transport write/read keys from current ck
        self.kdf_2(None)
    }
}

struct HandshakeState {
    noise: NoiseState,
    e_kp: KeyPair,                   // our ephemeral
    s_kp: KeyPair,                   // our static
    payload: Vec<u8>,                // client payload to send in ClientFinish
    server_static: Option<[u8; 32]>, // server static key for caller verification
    server_cert: Option<Vec<u8>>,    // decrypted certificate chain
}

impl HandshakeState {
    fn new(static_kp: KeyPair, payload: Vec<u8>) -> Result<Self, HsError> {
        let e_kp = KeyPair::generate();
        let mut noise = NoiseState::new(NOISE_PROLOGUE, &WA_CONN_HEADER)?;
        noise.mix_hash(&e_kp.public_bytes());
        Ok(Self {
            noise,
            e_kp,
            s_kp: static_kp,
            payload,
            server_static: None,
            server_cert: None,
        })
    }

    fn build_client_hello(&self) -> Result<Vec<u8>, HsError> {
        let msg = HandshakeMessage {
            client_hello: Some(wa::handshake_message::ClientHello {
                ephemeral: Some(self.e_kp.public_bytes().to_vec()),
                ..Default::default()
            }),
            ..Default::default()
        };
        let mut buf = Vec::new();
        msg.encode(&mut buf)?;
        Ok(buf)
    }

    fn parse_server_hello(bytes: &[u8]) -> Result<([u8; 32], Vec<u8>, Vec<u8>), HsError> {
        let resp = HandshakeMessage::decode(bytes)?;
        let sh = resp.server_hello.ok_or(HsError::IncompleteResponse)?;
        let re = sh.ephemeral.ok_or(HsError::IncompleteResponse)?;
        let rs_ct = sh.r#static.ok_or(HsError::IncompleteResponse)?;
        let cert_ct = sh.payload.ok_or(HsError::IncompleteResponse)?;

        if re.len() != 32 {
            return Err(HsError::InvalidLength {
                name: "server ephemeral",
                expected: 32,
                got: re.len(),
            });
        }
        let mut re_bytes = [0u8; 32];
        re_bytes.copy_from_slice(&re);
        Ok((re_bytes, rs_ct, cert_ct))
    }

    fn verify_server_cert(cert_decrypted: &[u8], rs: &[u8; 32]) -> Result<(), HsError> {
        let chain = CertChain::decode(cert_decrypted)?;
        let intermediate = chain
            .intermediate
            .ok_or_else(|| HsError::CertVerification("missing intermediate cert".into()))?;
        let leaf = chain
            .leaf
            .ok_or_else(|| HsError::CertVerification("missing leaf cert".into()))?;

        let inter_details_bytes = intermediate
            .details
            .ok_or_else(|| HsError::CertVerification("missing intermediate details".into()))?;
        let inter_details =
            wa::cert_chain::noise_certificate::Details::decode(inter_details_bytes.as_slice())?;
        if i64::from(inter_details.issuer_serial()) != WA_CERT_ISSUER_SERIAL {
            return Err(HsError::CertVerification(format!(
                "unexpected intermediate issuer serial {}, expected {}",
                inter_details.issuer_serial(),
                WA_CERT_ISSUER_SERIAL
            )));
        }
        if inter_details.key().len() != 32 {
            return Err(HsError::CertVerification(
                "intermediate key len != 32".into(),
            ));
        }

        let leaf_details_bytes = leaf
            .details
            .ok_or_else(|| HsError::CertVerification("missing leaf details".into()))?;
        let leaf_details =
            wa::cert_chain::noise_certificate::Details::decode(leaf_details_bytes.as_slice())?;
        if leaf_details.issuer_serial() != inter_details.serial() {
            return Err(HsError::CertVerification(
                "leaf issuer serial mismatch".into(),
            ));
        }
        if leaf_details.key() != rs {
            return Err(HsError::CertVerification(
                "leaf key doesn't match server static key".into(),
            ));
        }
        // Root signature verification intentionally omitted (as in public implementations).
        Ok(())
    }

    /// Process ServerHello and build ClientFinish
    fn read_server_hello_and_build_client_finish(
        &mut self,
        server_hello_bytes: &[u8],
    ) -> Result<Vec<u8>, HsError> {
        let (re, rs_ct, cert_ct) = Self::parse_server_hello(server_hello_bytes)?;

        // h = SHA256(h || re)
        self.noise.mix_hash(&re);

        // mix DH(e, re): server will send first ciphertexts using the read key
        let dh1 = KeyPair::dh(&self.e_kp.private_bytes(), &re);
        self.noise.mix_dh(&dh1)?;

        // decrypt server static key (use READ cipher)
        let rs = self.noise.decrypt(&rs_ct)?;
        if rs.len() != 32 {
            return Err(HsError::InvalidLength {
                name: "server static key",
                expected: 32,
                got: rs.len(),
            });
        }
        let mut rs_bytes = [0u8; 32];
        rs_bytes.copy_from_slice(&rs);

        // mix DH(e, rs)
        let dh2 = KeyPair::dh(&self.e_kp.private_bytes(), &rs_bytes);
        self.noise.mix_dh(&dh2)?;

        // decrypt certificate (still using READ cipher after re-key)
        let cert_plain = self.noise.decrypt(&cert_ct)?;
        Self::verify_server_cert(&cert_plain, &rs_bytes)?;
        self.server_static = Some(rs_bytes);
        self.server_cert = Some(cert_plain);

        // Now we send our static public under the WRITE cipher
        let s_pub = self.s_kp.public_bytes();
        let s_pub_ct = self.noise.encrypt(&s_pub)?;

        // mix DH(s, re)
        let dh3 = KeyPair::dh(&self.s_kp.private_bytes(), &re);
        self.noise.mix_dh(&dh3)?;

        // encrypt payload with WRITE cipher
        let payload_ct = self.noise.encrypt(&self.payload)?;

        // Build ClientFinish
        let msg = HandshakeMessage {
            client_finish: Some(wa::handshake_message::ClientFinish {
                r#static: Some(s_pub_ct),
                payload: Some(payload_ct),
            }),
            ..Default::default()
        };
        let mut out = Vec::new();
        msg.encode(&mut out)?;
        Ok(out)
    }

    fn finish(self) -> Result<HandshakeSecrets, HsError> {
        let (write_key, read_key) = self.noise.finish_split()?;
        let server_static = self
            .server_static
            .ok_or(HsError::State("server static key missing"))?;
        let server_certificate = self
            .server_cert
            .ok_or(HsError::State("server certificate missing"))?;

        Ok(HandshakeSecrets {
            write_key,
            read_key,
            handshake_hash: self.noise.h,
            handshake_ck: self.noise.ck,
            server_static,
            server_certificate,
        })
    }
}

struct HandshakeSecrets {
    write_key: [u8; 32],
    read_key: [u8; 32],
    handshake_hash: [u8; 32],
    handshake_ck: [u8; 32],
    server_static: [u8; 32],
    server_certificate: Vec<u8>,
}

#[derive(rustler::NifStruct)]
#[module = "ExWappNif.HandshakeSecrets"]
struct NifHandshakeSecrets {
    write_key: Vec<u8>,
    read_key: Vec<u8>,
    handshake_hash: Vec<u8>,
    handshake_ck: Vec<u8>,
    server_static: Vec<u8>,
    server_certificate: Vec<u8>,
}

impl From<HandshakeSecrets> for NifHandshakeSecrets {
    fn from(s: HandshakeSecrets) -> Self {
        Self {
            write_key: s.write_key.to_vec(),
            read_key: s.read_key.to_vec(),
            handshake_hash: s.handshake_hash.to_vec(),
            handshake_ck: s.handshake_ck.to_vec(),
            server_static: s.server_static.to_vec(),
            server_certificate: s.server_certificate,
        }
    }
}

struct HsResource(Mutex<Option<HandshakeState>>);

fn pack_frame_inner(payload: &[u8], include_header: bool) -> Result<Vec<u8>, HsError> {
    let header_len = if include_header {
        WA_CONN_HEADER.len()
    } else {
        0
    };
    if payload.len() >= 0xFFFFFF {
        return Err(HsError::Crypto("payload too large".into()));
    }
    let mut out = Vec::with_capacity(header_len + 3 + payload.len());
    if include_header {
        out.extend_from_slice(&WA_CONN_HEADER);
    }
    let len = payload.len() as u32;
    let be = len.to_be_bytes(); // 4 bytes; take last 3
    out.extend_from_slice(&be[1..]);
    out.extend_from_slice(payload);
    Ok(out)
}

fn unpack_frame_inner(frame: &[u8], expect_header: bool) -> Result<Vec<u8>, HsError> {
    let mut idx = 0usize;
    if expect_header {
        if frame.len() < 4 {
            return Err(HsError::Crypto("short frame".into()));
        }
        if frame[0..4] != WA_CONN_HEADER {
            return Err(HsError::Crypto("bad WA header".into()));
        }
        idx = 4;
    }
    if frame.len() < idx + 3 {
        return Err(HsError::Crypto("short frame length".into()));
    }
    let len = ((frame[idx] as usize) << 16)
        | ((frame[idx + 1] as usize) << 8)
        | (frame[idx + 2] as usize);
    idx += 3;
    if frame.len() < idx + len {
        return Err(HsError::Crypto("truncated frame".into()));
    }
    Ok(frame[idx..idx + len].to_vec())
}

// ===== NIF glue =====

#[allow(non_local_definitions)]
fn load(env: Env<'_>, _: Term<'_>) -> bool {
    let _ = rustler::resource!(HsResource, env);
    let _ = rustler::resource!(CipherResource, env);
    true
}

#[rustler::nif]
fn generate_noise_keypair() -> (Vec<u8>, Vec<u8>) {
    let kp = KeyPair::generate();
    (kp.private_bytes().to_vec(), kp.public_bytes().to_vec())
}

#[rustler::nif]
fn handshake_new(
    payload: Binary<'_>,
    static_private: Option<Binary<'_>>,
) -> NifResult<(ResourceArc<HsResource>, Vec<u8>, Vec<u8>, Vec<u8>)> {
    let payload_vec = payload.as_slice().to_vec();
    let s_kp = match static_private {
        Some(bin) => {
            if bin.len() != 32 {
                return Err(HsError::InvalidLength {
                    name: "static private key",
                    expected: 32,
                    got: bin.len(),
                }
                .into());
            }
            let mut sk = [0u8; 32];
            sk.copy_from_slice(bin.as_slice());
            KeyPair::from_private(sk)
        }
        None => KeyPair::generate(),
    };

    let state = HandshakeState::new(s_kp, payload_vec)?;
    let client_hello = state.build_client_hello()?;
    let res = ResourceArc::new(HsResource(Mutex::new(Some(state))));

    Ok((
        res,
        client_hello,
        s_kp.public_bytes().to_vec(),
        s_kp.private_bytes().to_vec(),
    ))
}

#[rustler::nif]
fn handshake_client_finish(
    state: ResourceArc<HsResource>,
    server_hello_payload: Binary<'_>,
) -> NifResult<Vec<u8>> {
    let mut guard = state.0.lock().map_err(|_| HsError::MutexPoisoned)?;
    let st = guard.as_mut().ok_or(HsError::AlreadyFinished)?;
    let out = st.read_server_hello_and_build_client_finish(server_hello_payload.as_slice())?;
    Ok(out)
}

#[rustler::nif]
fn handshake_finish(state: ResourceArc<HsResource>) -> NifResult<NifHandshakeSecrets> {
    let mut guard = state.0.lock().map_err(|_| HsError::MutexPoisoned)?;
    let st = guard.take().ok_or(HsError::AlreadyFinished)?;
    Ok(st.finish()?.into())
}

// --- Frame helpers ---

#[rustler::nif]
fn pack_frame(payload: Binary<'_>, include_header: bool) -> NifResult<Vec<u8>> {
    Ok(pack_frame_inner(payload.as_slice(), include_header)?)
}

#[rustler::nif]
fn unpack_frame(frame: Binary<'_>, expect_header: bool) -> NifResult<Vec<u8>> {
    Ok(unpack_frame_inner(frame.as_slice(), expect_header)?)
}

// --- Transport cipher (post-handshake) ---

#[derive(rustler::NifStruct)]
#[module = "ExWappNif.NoiseKeys"]
struct NoiseKeys {
    write_key: Vec<u8>,
    read_key: Vec<u8>,
}

struct CipherResource(Mutex<(CipherState, CipherState, [u8; 32])>); // (write, read, aad hash snapshot)

#[rustler::nif]
fn noise_cipher_new(
    keys: NoiseKeys,
    handshake_hash: Binary<'_>,
) -> NifResult<ResourceArc<CipherResource>> {
    if keys.write_key.len() != 32 || keys.read_key.len() != 32 || handshake_hash.len() != 32 {
        return Err(NifError::Term(Box::new("keys and hash must be 32 bytes")));
    }
    let mut w = [0u8; 32];
    w.copy_from_slice(&keys.write_key);
    let mut r = [0u8; 32];
    r.copy_from_slice(&keys.read_key);
    let mut h = [0u8; 32];
    h.copy_from_slice(handshake_hash.as_slice());

    let write = CipherState::new(&w)?;
    let read = CipherState::new(&r)?;
    Ok(ResourceArc::new(CipherResource(Mutex::new((
        write, read, h,
    )))))
}

#[rustler::nif]
fn noise_encrypt(state: ResourceArc<CipherResource>, plaintext: Binary<'_>) -> NifResult<Vec<u8>> {
    let mut guard = state.0.lock().map_err(|_| HsError::MutexPoisoned)?;
    let (write, _read, h) = &mut *guard;
    let ct = write.encrypt_aad(h, plaintext.as_slice())?;
    Ok(ct)
}

#[rustler::nif]
fn noise_decrypt(state: ResourceArc<CipherResource>, ciphertext: Binary<'_>) -> NifResult<Vec<u8>> {
    let mut guard = state.0.lock().map_err(|_| HsError::MutexPoisoned)?;
    let (_write, read, h) = &mut *guard;
    let pt = read.decrypt_aad(h, ciphertext.as_slice())?;
    Ok(pt)
}

rustler::init!("Elixir.ExWapp.Nif", load = load);
