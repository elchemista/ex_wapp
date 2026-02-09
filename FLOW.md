# WhatsApp Web Socket Connection Flow

> STATUS (Feb 9, 2026): The runtime is now pure Elixir (no Rust Signal path).
> QR pairing/connect/disconnect/send/receive flows are kept, with a cleaned
> reconnect lifecycle for transport drops. Delivery reliability still depends on
> protocol compatibility and remains a work in progress.

This document describes the complete flow for establishing a WhatsApp Web socket connection, based on reverse-engineering the Go `whatsmeow` library and implementing it in Elixir.

## 2026 Refactor Plan (Implemented)

1. Keep only one Signal path (pure Elixir) to remove split debugging paths.
2. Treat transport disconnect as a first-class session event and trigger reconnect.
3. Keep minimal capabilities in the main flow:
   - QR pairing
   - connect/disconnect/reconnect
   - receive nodes/messages
   - send encrypted messages
4. Trim helper surface (`ExWapp.Example`) to a minimal debug entrypoint.
5. Keep protocol-touch points concentrated in:
   - `lib/ex_wapp/conn.ex`
   - `lib/ex_wapp/session.ex`
   - `lib/ex_wapp/noise/*`
   - `lib/ex_wapp/pairing.ex`
   - `lib/ex_wapp/signal/*`

## Table of Contents

1. [Overview](#overview)
2. [WebSocket Connection](#websocket-connection)
3. [Noise Protocol Handshake](#noise-protocol-handshake)
4. [Client Payload Structure](#client-payload-structure)
5. [Frame Encoding](#frame-encoding)
6. [Fixes Applied](#fixes-applied)
7. [Current State](#current-state)
8. [Next Steps](#next-steps)

---

## Overview

WhatsApp Web uses a custom protocol layered on top of WebSocket:

```
┌─────────────────────────────────────┐
│         Application Layer           │
│   (Binary XML nodes, Protobufs)     │
├─────────────────────────────────────┤
│         Noise Protocol              │
│  (Noise_XX_25519_AESGCM_SHA256)     │
├─────────────────────────────────────┤
│         WhatsApp Framing            │
│    (WA Header + Length Prefix)      │
├─────────────────────────────────────┤
│           WebSocket                 │
│     (Binary frames over TLS)        │
└─────────────────────────────────────┘
```

---

## WebSocket Connection

### Endpoint
```
URL: wss://web.whatsapp.com/ws/chat
```

### Required Headers

The Go client sets **only** the `Origin` header explicitly. Other WebSocket headers (`Connection`, `Upgrade`, `Sec-WebSocket-Version`, `Sec-WebSocket-Key`) are handled automatically by the WebSocket library.

```elixir
headers = [
  {"Origin", "https://web.whatsapp.com"}
]
```

**Critical**: Do NOT manually set `Connection`, `Upgrade`, or `Sec-WebSocket-Version` headers - the WebSocket library adds these automatically. Setting them manually causes duplicate headers.

### Connection Response

A successful connection returns:
```
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: <calculated-accept-key>
```

---

## Noise Protocol Handshake

WhatsApp uses the **Noise_XX_25519_AESGCM_SHA256** handshake pattern.

### Constants

```elixir
# Must be exactly 32 bytes (used directly as initial hash, not SHA256'd)
@noise_pattern "Noise_XX_25519_AESGCM_SHA256\x00\x00\x00\x00"

# WA connection header (4 bytes)
@wa_header <<0x57, 0x41, 0x06, 0x03>>  # "WA" + magic(6) + dict_version(3)
```

### Handshake Flow

```
┌──────────┐                              ┌──────────┐
│  Client  │                              │  Server  │
└────┬─────┘                              └────┬─────┘
     │                                         │
     │  1. ClientHello (ephemeral public key)  │
     │ ─────────────────────────────────────── │
     │                                         │
     │  2. ServerHello (eph + encrypted static │
     │     + encrypted certificate)            │
     │ ◄────────────────────────────────────── │
     │                                         │
     │  3. ClientFinish (encrypted static +    │
     │     encrypted ClientPayload)            │
     │ ─────────────────────────────────────── │
     │                                         │
     │  4. Transport mode (encrypted frames)   │
     │ ◄──────────────────────────────────────►│
     │                                         │
```

### Step 1: Client Hello

```elixir
# Generate ephemeral key pair
e_kp = generate_curve25519_keypair()

# Initialize noise state
noise = Handshake.new(@noise_pattern, @wa_header)
noise = Handshake.authenticate(noise, e_kp.public)

# Build ClientHello protobuf
client_hello = %HandshakeMessage{
  clientHello: %ClientHello{
    ephemeral: e_kp.public  # 32-byte Curve25519 public key
  }
}

# Encode and frame
frame = wa_header <> <<length::24>> <> protobuf_encode(client_hello)
```

**Frame structure (43 bytes total)**:
- 4 bytes: WA header (`57 41 06 03`)
- 3 bytes: Length prefix (big-endian, = 36)
- 36 bytes: Protobuf (HandshakeMessage with clientHello)

### Step 2: Process Server Hello

The server responds with:
- `ephemeral`: Server's ephemeral public key (32 bytes)
- `static`: Encrypted server static key (48 bytes = 32 + 16 tag)
- `payload`: Encrypted certificate (variable, ~257 bytes)

**Processing steps**:

```elixir
# 1. Authenticate server ephemeral
noise = Handshake.authenticate(noise, server_ephemeral)

# 2. Mix DH(client_ephemeral_private, server_ephemeral)
{:ok, noise} = Handshake.mix_shared_secret(noise, e_kp.private, server_ephemeral)

# 3. Decrypt server static key
{:ok, noise, server_static} = Handshake.decrypt(noise, server_static_ciphertext)

# 4. Mix DH(client_ephemeral_private, server_static)
{:ok, noise} = Handshake.mix_shared_secret(noise, e_kp.private, server_static)

# 5. Decrypt certificate
{:ok, noise, certificate} = Handshake.decrypt(noise, certificate_ciphertext)
```

### Step 3: Client Finish

```elixir
# 6. Encrypt client static public key
{noise, static_ciphertext} = Handshake.encrypt(noise, s_kp.public)

# 7. Mix DH(client_static_private, server_ephemeral)
{:ok, noise} = Handshake.mix_shared_secret(noise, s_kp.private, server_ephemeral)

# 8. Encrypt ClientPayload
{noise, payload_ciphertext} = Handshake.encrypt(noise, client_payload_bytes)

# Build ClientFinish protobuf
client_finish = %HandshakeMessage{
  clientFinish: %ClientFinish{
    static: static_ciphertext,    # 48 bytes (32 + 16 tag)
    payload: payload_ciphertext   # variable (~300+ bytes)
  }
}
```

### Step 4: Derive Transport Keys

After sending ClientFinish:

```elixir
# HKDF-SHA256 key derivation
{write_key, read_key} = Handshake.derive_transport_keys(noise)

# write_key: 32 bytes for client → server encryption
# read_key: 32 bytes for server → client decryption
```

### AEAD Encryption Details

- **Algorithm**: AES-256-GCM
- **Key**: 32 bytes (from HKDF)
- **IV/Nonce**: 12 bytes = 8 zero bytes + 4-byte counter (big-endian)
- **Tag**: 16 bytes (appended to ciphertext)
- **AAD**: Hash state during handshake, empty (`<<>>`) during transport

```elixir
def generate_iv(counter) do
  <<0::64, counter::big-32>>  # 12 bytes total
end
```

---

## Client Payload Structure

### For New Device (Registration)

```elixir
%ClientPayload{
  passive: false,
  pull: false,
  userAgent: %UserAgent{
    platform: :WEB,
    appVersion: %AppVersion{
      primary: 2,
      secondary: 3000,
      tertiary: 1029948479
    },
    mcc: "000",
    mnc: "000",
    osVersion: "0.1",          # NOT "0.1.0"
    manufacturer: "",
    device: "Desktop",
    osBuildNumber: "0.1",      # NOT "0.1.0"
    releaseChannel: :RELEASE,
    localeLanguageIso6391: "en",
    localeCountryIso31661Alpha2: "US"
    # NOTE: Do NOT set phoneID, deviceType, deviceModelType
  },
  webInfo: %WebInfo{
    webSubPlatform: :WEB_BROWSER
    # NOTE: Do NOT set version field
  },
  connectType: :WIFI_UNKNOWN,
  connectReason: :USER_ACTIVATED,
  devicePairingData: %DevicePairingRegistrationData{
    eRegid: <<reg_id::big-32>>,           # 4 bytes
    eKeytype: <<0x05>>,                    # 1 byte (DJB type)
    eIdent: identity_public_key,           # 32 bytes
    eSkeyID: <<prekey_id::big-24>>,        # 3 bytes (last 3 of 4-byte BE)
    eSkeyVal: signed_prekey_public,        # 32 bytes
    eSkeySig: signature,                   # 64 bytes (XEdDSA)
    buildHash: :crypto.hash(:md5, version_string),  # 16 bytes
    deviceProps: encoded_device_props      # ~50 bytes
  }
}
```

### DeviceProps Structure

```elixir
%DeviceProps{
  os: "whatsmeow",
  version: %AppVersion{primary: 0, secondary: 1, tertiary: 0},
  platformType: :UNKNOWN,       # enum value 0
  requireFullSync: false,
  historySyncConfig: %HistorySyncConfig{
    storageQuotaMb: 10240,
    inlineInitialPayloadInE2EeMsg: true,
    supportCallLogHistory: false,
    supportBotUserAgentChatHistory: true,
    supportCagReactionsAndPolls: true,
    supportBizHostedMsg: true,
    supportRecentSyncChunkMessageCountTuning: true,
    supportHostedGroupMsg: true,
    supportFbidBotChatHistory: true,
    supportMessageAssociation: true,
    supportGroupHistory: false
  }
}
```

### Protobuf Field Tags (Important!)

```
ClientPayload:
  - username: 1
  - passive: 3        # NOT 2!
  - userAgent: 5
  - webInfo: 6
  - pushName: 7
  - connectType: 12
  - connectReason: 13
  - devicePairingData: 19
  - pull: 33          # NOT 4!
```

---

## Frame Encoding

### WA Frame Structure

```
┌────────────┬───────────────┬─────────────────┐
│  WA Header │ Length Prefix │     Payload     │
│  (4 bytes) │   (3 bytes)   │   (variable)    │
└────────────┴───────────────┴─────────────────┘
```

- **WA Header**: Only in first frame (`57 41 06 03`)
- **Length Prefix**: 3 bytes, big-endian
- **Payload**: Protobuf during handshake, encrypted binary during transport

```elixir
def encode_frame(payload, include_header: include_header) do
  header = if include_header, do: <<0x57, 0x41, 0x06, 0x03>>, else: <<>>
  length = byte_size(payload)
  <<header::binary, length::big-24, payload::binary>>
end
```

---

## Fixes Applied

### 1. WebSocket Headers (conn.ex)

**Problem**: Elixir code was manually setting `Connection`, `Upgrade`, `Sec-WebSocket-Version` headers that WebSockex adds automatically.

**Solution**: Only set `Origin` header.

```elixir
# Before (WRONG)
headers = [
  {"Origin", @origin},
  {"Connection", "Upgrade"},
  {"Upgrade", "websocket"},
  {"Sec-WebSocket-Version", "13"}
]

# After (CORRECT)
headers = [
  {"Origin", @origin}
]
```

### 2. Noise Pattern (handshake.ex)

**Problem**: Pattern was 28 bytes, causing it to be SHA256 hashed instead of used directly.

**Solution**: Pad to exactly 32 bytes with null bytes.

```elixir
# Before (WRONG - 28 bytes, gets hashed)
@pattern "Noise_XX_25519_AESGCM_SHA256"

# After (CORRECT - 32 bytes, used directly)
@pattern "Noise_XX_25519_AESGCM_SHA256\x00\x00\x00\x00"
```

### 3. ETS Table Access (store_ets.ex)

**Problem**: ETS tables loaded from file retained `:protected` access, but the WebSocket runs in a different process than the Session.

**Solution**: Always create new `:public` tables and copy data.

```elixir
# Before (WRONG)
table = case :ets.file2tab(path) do
  {:ok, tab} -> tab  # Inherits original access rights
  {:error, _} -> :ets.new(:store, [:set, :public])
end

# After (CORRECT)
table = :ets.new(:store, [:set, :public])  # Always public
case :ets.file2tab(path) do
  {:ok, temp_tab} ->
    # Copy data from temp to public table
    case :ets.lookup(temp_tab, :data) do
      [{:data, data}] -> :ets.insert(table, {:data, data})
      [] -> :ets.insert(table, {:data, %{}})
    end
    :ets.delete(temp_tab)
  {:error, _} ->
    :ets.insert(table, {:data, %{}})
end
```

### 4. ClientPayload Fields (client_payload.ex)

**Problem**: Extra fields that Go doesn't set were causing server rejection.

**Solution**: Match Go's structure exactly.

```elixir
# Removed fields:
# - pushName (not set for registration)
# - phoneID (in UserAgent)
# - deviceType (in UserAgent)
# - deviceModelType (in UserAgent)
# - version (in WebInfo)

# Fixed format:
# - osVersion: "0.1" not "0.1.0"
# - osBuildNumber: "0.1" not "0.1.0"
```

### 5. DeviceProps Encoding (client_payload.ex)

**Problem**: Hardcoded bytes were incomplete/malformed.

**Solution**: Proper protobuf structure with HistorySyncConfig.

### 6. Frame Sending Timing (conn.ex)

**Problem**: Sending frame from `handle_connect` callback caused issues.

**Solution**: Use `handle_info` to send asynchronously after connection.

```elixir
def handle_connect(_conn, state) do
  send(self(), {:send_raw_frame, frame})
  {:ok, state}
end

def handle_info({:send_raw_frame, frame}, state) do
  {:reply, frame, state}
end
```

---

## Current State (Updated Nov 30, 2025)

### What Works ✅

1. **WebSocket Connection**: Connects successfully to `wss://web.whatsapp.com/ws/chat`
2. **Client Hello**: Sent correctly (43 bytes with proper framing)
3. **Server Hello**: Received and parsed (350 bytes)
4. **Noise Decryption**: Server static key and certificate decrypted successfully
5. **Client Finish**: Encrypted and sent correctly
6. **Transport Keys**: Derived correctly
7. **QR Code**: Successfully displayed for pairing 🎉
8. **QR Scan Pairing**: Successfully receives `pair-success` with device JID ✅
9. **Credentials Storage**: JID, noise keys, signal keys persisted to ETS store ✅
10. **Ping/Pong Handling**: Responds to server keepalive pings ✅
11. **Binary Encoding**: Fixed with leading 0 byte (matching Go implementation) ✅
12. **Login Reconnection**: Works after 515 stream restart ✅
13. **Prekey Upload**: Uploads 812 prekeys on initial login ✅
14. **Session Invalidation**: Detects 401 errors, clears session, prevents reconnect loops ✅
15. **Signal Session Creation**: X3DH key exchange with recipient prekeys ✅
16. **Prekey Fetching**: Fetches recipient's prekey bundle from server ✅
17. **Message Encryption**: AES-GCM encryption with Double Ratchet keys ✅

### What's NOT Working ❌

**Message Delivery** (as of Nov 30, 2025 01:58):
- Messages are encrypted and sent with correct `type="pkmsg"` for new sessions
- PreKeySignalMessage wrapper is now properly applied ✅
- Protobuf encoding with varints and 0x05 key prefixes ✅
- BUT recipients still don't receive messages

### Progress on Signal Message Format

**FIXED - Wire Format Implementation** (`lib/ex_wapp/signal/wire_format.ex`):
- Created proper protobuf encoder for Signal messages
- Added version byte (0x33) ✅
- Added 0x05 key prefix for Curve25519 keys ✅
- Implemented varint encoding ✅
- PreKeySignalMessage structure verified correct ✅

**Current message structure** (verified from logs):
```
PreKeySignalMessage (164 bytes):
- 0x33 (version)
- Field 1: preKeyId = 261069 (varint) ✅
- Field 2: baseKey = 33 bytes (0x05 + 32-byte key) ✅  
- Field 3: identityKey = 33 bytes (0x05 + 32-byte key) ✅
- Field 4: message = SignalMessage (78 bytes)
- Field 5: registrationId = 22551 ✅
- Field 6: signedPreKeyId = 8645082 ✅
```

### Remaining Issues to Debug

**Possible causes for messages not being delivered**:

1. **Inner SignalMessage encryption** - We use AES-256-CBC but:
   - Is the IV correct? (should be 16 bytes for CBC)
   - Is the key derivation (HKDF) producing correct cipher_key, mac_key, iv?

2. **MAC calculation** - Signal uses HMAC-SHA256 truncated to 8 bytes:
   - MAC is over: sender_identity || receiver_identity || version || protobuf
   - Are we using correct identity keys?

3. **Ciphertext format** - The inner message contains:
   - ratchetKey (should be sender's current ratchet public key)
   - counter (message number in chain)
   - previousCounter
   - ciphertext (AES-CBC encrypted plaintext)

4. **Identity key mismatch** - WhatsApp might expect the phone's identity key, not the linked device's

### Files Modified This Session

- `lib/ex_wapp/signal/wire_format.ex` - NEW: Proper Signal protocol serialization
- `lib/ex_wapp/signal/session.ex` - Updated encrypt() to use WireFormat + AES-CBC
- `lib/ex_wapp/session.ex` - Fixed to wrap SignalMessage in PreKeySignalMessage for new sessions

### Key Fixes Applied This Session

1. **Binary Encoder** (`lib/ex_wapp/binary.ex`):
   ```elixir
   # Must start with a 0 byte, matching Go implementation
   def new, do: %__MODULE__{data: [<<0>>]}
   ```

2. **Removed xmlstreamstart** - WhatsApp server doesn't expect this node

3. **Login vs Registration Payload** (`lib/ex_wapp/noise/client_payload.ex`):
   - Registration: Uses `devicePairingData`, `passive: false`, `pull: false`
   - Login: Uses `username`, `device`, `passive: true`, `pull: true`, `lidDbMigrated: true`

4. **Ping Handling** (`lib/ex_wapp/session.ex`):
   ```elixir
   # Handle ping requests with xmlns "urn:xmpp:ping"
   xmlns == "urn:xmpp:ping" and iq_type == "get" ->
     pong = build_iq_result(attrs)
     {state, [{:send_node, pong}]}
   ```

---

## Next Steps

### 1. ✅ COMPLETED: QR Code Pairing
- Noise handshake works
- QR code displayed
- User can scan with phone
- `pair-success` received and processed

### 2. ✅ COMPLETED: Login Reconnection
- Server sends 515 stream restart after pairing
- Reconnection with login payload works
- Prekey upload (812 keys) on initial login

### 3. ✅ COMPLETED: Signal Session Infrastructure
- X3DH key exchange implemented
- Prekey fetching from server works
- Session creation with recipient's prekey bundle
- Double Ratchet key derivation

### 4. ✅ COMPLETED: Single Pure Elixir Signal Path

- Removed the runtime split between native and Elixir Signal implementations.
- Kept only `lib/ex_wapp/signal/*` pure Elixir code paths active.
- Kept adapter compatibility helpers, but native mode now resolves to Elixir.

### 5. ✅ COMPLETED: Transport Disconnect Recovery

- `ExWapp.Conn` now closes its process on websocket disconnect.
- `ExWapp.Session` handles `{:transport, {:closed, reason}}` as a reconnect trigger.
- Pending IQ waits and worker waits are cleared on disconnect to avoid stale state.

### 6. TODO: Message Decryption
- Decrypt incoming encrypted messages
- Handle both PreKeySignalMessage and SignalMessage
- Implement message padding removal

### 7. TODO: Chat History Sync
- Handle history sync blobs from server
- Requires Signal decryption to read message content
- Parse protobuf message structures

---

## Reference: Go Source Files

The old in-repo `whatsmeow/` clone was removed during cleanup.
Use upstream sources directly for protocol comparison:

- https://github.com/tulir/whatsmeow
- https://github.com/tulir/libsignal-protocol-go

Useful files in `whatsmeow`:

| File | Purpose |
|------|---------|
| `socket/constants.go` | Constants (Origin, URL, WAHeader, DictVersion) |
| `send.go` | Message encryption and sending (lines 1343-1400 key!) |

### libsignal Reference (go.mau.fi/libsignal)

| File | Purpose |
|------|---------|
| `protocol/SignalMessage.go` | SignalMessage serialization format |
| `protocol/PreKeySignalMessage.go` | PreKeySignalMessage format |
| `protocol/CiphertextMessage.go` | Base message interface |
| `session/SessionCipher.go` | Encrypt/decrypt with Double Ratchet |
| `ecc/DjbECPublicKey.go` | Key serialization with 0x05 prefix |

### Key Code Snippets from libsignal

**Key serialization** (ecc/DjbECPublicKey.go):
```go
const DjbType = 0x05

func (d *DjbECPublicKey) Serialize() []byte {
    return append([]byte{DjbType}, d.publicKey[:]...)
}
```

**SignalMessage format** (protocol/SignalMessage.go):
```go
const CurrentVersion = 3
const MessageVersion = (CurrentVersion << 4) | CurrentVersion  // 0x33

func (s *SignalMessage) Serialize() []byte {
    version := []byte{MessageVersion}
    return append(version, s.serialized...)  // serialized = protobuf
}
```

**PreKeySignalMessage format** (protocol/PreKeySignalMessage.go):
```go
func NewPreKeySignalMessage(
    messageVersion int,
    registrationID uint32,
    preKeyID *optional.Uint32,
    signedPreKeyID uint32,
    baseKey ecc.ECPublicKeyable,
    identityKey *identity.Key,
    message *SignalMessage,
) *PreKeySignalMessage {
    // Serializes all fields to protobuf
}
```

### Other whatsmeow Files

| File | Purpose |
|------|---------|
| `socket/framesocket.go` | WebSocket framing |
| `socket/noisehandshake.go` | Noise protocol implementation |
| `socket/noisesocket.go` | Encrypted transport |
| `store/clientpayload.go` | ClientPayload construction |
| `handshake.go` | High-level handshake flow |
| `client.go` | Client lifecycle |

---

## Appendix: Hex Dumps

### Successful Client Hello (43 bytes)
```
5741 0603 0000 24 12 22 0a 20
[WA HDR ] [LEN] [protobuf: field 2, len 34, field 1, len 32]
<32-byte ephemeral public key>
```

### Server Hello (350 bytes)
```
0001 5b [length: 347]
1a d8 02 [field 3, len 344]
  0a 20 <32-byte server ephemeral>
  12 30 <48-byte encrypted static>
  1a 8102 <257-byte encrypted certificate>
```

### Client Finish (variable, ~360-430 bytes)
```
0001 xx [length]
22 xx [field 4, len xx]
  0a 30 <48-byte encrypted client static>
  12 xx <encrypted ClientPayload>
```
