# WhatsApp Multi-Device Protocol Spec for ExWapp

> Derived from whatsmeow (Go), Baileys (TypeScript), and whatsapp-rust.
> Every rule below has been verified against at least two reference implementations.
> Line references are from the `/tmp/` copies of these libraries.

---

## 1. JID Types and Addressing

### 1.1 JID Formats

| Type | Server | Example | Usage |
|------|--------|---------|-------|
| **PN (Phone Number)** | `s.whatsapp.net` | `393519534944@s.whatsapp.net` | User-facing, server-facing (usync, prekey IQ, `<to>` attr) |
| **PN with Device** | `s.whatsapp.net` | `393519534944:2@s.whatsapp.net` | Device-specific targeting |
| **LID (Linked Identity)** | `lid` | `203139403767907@lid` | Signal session storage, encryption identity |
| **LID with Device** | `lid` | `203139403767907:2@lid` | Device-specific LID |
| **Group** | `g.us` | `120363043214477337@g.us` | Group chat addressing |
| **Server** | `s.whatsapp.net` | `s.whatsapp.net` | IQ target for server requests |

### 1.2 Wire Identity vs Encryption Identity

This is the most critical distinction. Getting it wrong causes silent message delivery failure.

- **Wire Identity (PN)**: Used in server-facing XML nodes (`<to jid="...">`, usync queries, prekey fetch IQ `<user jid="...">`).
- **Encryption Identity (LID)**: Used for Signal session lookup/storage and encryption cipher operations.

**Rule**: The `<to jid="...">` attribute in participant nodes MUST use the **wire identity** (PN).
The Signal session MUST be keyed by the **encryption identity** (LID if mapping exists).

> whatsmeow `send.go:1323-1343`: `encryptMessageForDeviceAndWrap` takes both `wireIdentity` and `encryptionIdentity`. The XML `<to jid>` uses wireIdentity; the cipher uses encryptionIdentity.

### 1.3 PN-to-LID Mapping

LID mappings come from:
- USync device discovery responses (primary source)
- Incoming messages (`sender_lid` / `participant_lid` attributes)
- History sync data

**Storage**: Bidirectional map. Given a PN, retrieve the LID. Given a LID, retrieve the PN.

### 1.4 Session Migration (PN → LID)

When a LID mapping is discovered for a PN that has an existing Signal session:

1. Copy the Signal session record from the PN address to the LID address
2. All future encryption uses the LID address
3. The PN session can be kept for backwards compatibility

> whatsmeow `message.go:291-296`: `migrateSessionStore` calls `Store.Sessions.MigratePNToLID(pn, lid)`.
> Called both during send (`send.go:1269`) and receive (`message.go:318`).

**ExWapp Note**: We do NOT currently implement session migration. Instead, we use
session-aware JID resolution: if a session exists under PN (from prekey fetch), use PN;
if a session exists under LID (migrated), use LID. This is a workaround — proper migration
would be more robust.

---

## 2. Device Discovery (USync)

### 2.1 USync IQ Request

```xml
<iq xmlns="usync" type="get" to="s.whatsapp.net">
  <usync mode="query" context="message" last="true" index="0" sid="...">
    <query>
      <devices version="2"/>
    </query>
    <list>
      <user jid="recipient@s.whatsapp.net"/>
      <user jid="own_jid@s.whatsapp.net"/>
    </list>
  </usync>
</iq>
```

### 2.2 Key Rules

- **Namespace**: `usync` (NOT `encrypt`)
- **Context**: `"message"` for message sending, `"interactive"` for user-initiated
- **Participants**: MUST include BOTH recipient AND sender's own JID
- **Version**: `"2"` for current protocol
- **Response** includes: device list per user, LID mappings, device hashes

### 2.3 Response Processing

The response contains `<device>` nodes for each user. Each device has:
- `jid`: The device JID (PN with device suffix, e.g., `393519534944:2@s.whatsapp.net`)
- `key-index`: Device key index

**ALL returned devices must be targeted** (except current device — see Section 5.3).

### 2.4 LID Mapping from USync

USync responses may include LID data. Store these mappings immediately:

> Baileys `messages-send.ts:298-313`: Stores LID→PN mappings from usync response before proceeding.

---

## 3. Prekey Fetch

### 3.1 Prekey IQ Request

```xml
<iq xmlns="encrypt" type="get" to="s.whatsapp.net">
  <key>
    <user jid="393519534944@s.whatsapp.net" reason="identity"/>
    <user jid="393519534944:2@s.whatsapp.net" reason="identity"/>
  </key>
</iq>
```

### 3.2 Key Rules

- **Namespace**: `encrypt` (NOT `usync`)
- **JIDs**: Use **wire JIDs (PN)**, NOT LID-mapped JIDs. The server expects PN JIDs.
- **Batch**: Multiple `<user>` nodes in a single IQ (efficient)
- **Only fetch for devices without existing sessions**: Check both PN and LID session stores before fetching

> whatsmeow `send.go:1279-1290`: Checks `existingSessions` map, only fetches for devices returning `false`.
> whatsmeow `prekeys.go:125-141`: Request uses `jid` from the encryption identity list.

### 3.3 Session After Prekey Fetch

After processing a prekey bundle, the Signal session is created under the JID used for the request.
If prekeys were fetched using PN JID → session exists under PN JID.
If session migration hasn't run → encryption MUST use PN JID (where the session actually is).

**Bug we hit**: Fetching prekeys with PN JID, then encrypting with LID JID → no session found → creates new session from bundle → wrong session state → message silently dropped by server.

---

## 4. Signal Encryption

### 4.1 Message Padding

Before encryption, plaintext is padded:

```
padded = plaintext + random_padding
```

Padding algorithm (PKCS7-like):
1. Calculate target length: round up to next multiple of 16 (minimum plaintext + 1)
2. Pad byte value = number of padding bytes
3. Append `pad_len` copies of the pad byte

> whatsmeow `send.go:padMessage()`: Uses random padding with byte value.

### 4.2 Encryption Types

| Type | Wire Value | When Used |
|------|-----------|-----------|
| **PreKeySignalMessage** | `"pkmsg"` | First message to a device (new session from prekey bundle) |
| **SignalMessage** | `"msg"` | Subsequent messages on established session |
| **SenderKeyMessage** | `"skmsg"` | Group messages (after SenderKey distribution) |

### 4.3 PreKey Message Structure

```
version_byte (0x33) || protobuf(PreKeySignalMessage)
```

PreKeySignalMessage protobuf contains:
- `registration_id`: Sender's Signal registration ID
- `prekey_id`: One-time prekey ID used (optional)
- `signed_prekey_id`: Signed prekey ID used
- `base_key`: Ephemeral public key (32 bytes)
- `identity_key`: Sender's identity public key (32 bytes)
- `message`: Inner SignalMessage (encrypted)

### 4.4 Signal Message Structure

```
version_byte (0x33) || protobuf(SignalMessage) || mac(8 bytes)
```

SignalMessage protobuf contains:
- `ratchet_key`: Current ratchet public key (32 bytes)
- `counter`: Message counter in current chain
- `previous_counter`: Counter of previous sending chain
- `ciphertext`: AES-256-CBC encrypted plaintext

MAC is 8 bytes of HMAC-SHA256 over: `sender_identity || receiver_identity || mac_key || version || protobuf`.

---

## 5. DM Message Sending Flow

### 5.1 Complete Step-by-Step

1. **Build protobuf message**: `Message { conversation: "text" }` → marshal to bytes → `plaintext`
2. **Build DSM-wrapped message**: `Message { deviceSentMessage: { destinationJid: recipient, message: original } }` → marshal → `dsmPlaintext`
3. **Discover devices**: USync query with `[recipient, ownJID]` → `allDevices` list
4. **Store LID mappings** from USync response
5. **Compute phash**: `participantListHashV2(allDevices)` — includes ALL devices, including current device
6. **Determine prekey needs**: For each device in `allDevices`, check if Signal session exists (under both PN and LID)
7. **Fetch prekeys** for devices without sessions (batch IQ, using PN JIDs)
8. **Create sessions** from prekey bundles
9. **Encrypt per device**:
   - Skip current device
   - Own devices (matching user part) → encrypt `dsmPlaintext`
   - Recipient devices → encrypt `plaintext`
   - Each encryption → pad → Signal encrypt → get ciphertext + type (pkmsg/msg)
10. **Build participant nodes**: `<to jid="wireJID"><enc v="2" type="pkmsg|msg">ciphertext</enc></to>`
11. **Build message node** with phash, participants, device-identity (if any pkmsg)
12. **Send** via WebSocket

### 5.2 DeviceSentMessage (DSM)

Own devices receive a **different payload** than the recipient. The DSM wraps the original message:

```protobuf
Message {
  deviceSentMessage: DeviceSentMessage {
    destinationJid: "recipient@s.whatsapp.net"  // String, base JID (no device suffix)
    message: Message { ... }                     // Original message
    // phash: optional, for groups only
  }
  messageContextInfo: ...  // Preserved from original
}
```

> whatsmeow `send.go:1200-1225`: `marshalMessage()` creates both plaintext and dsmPlaintext.
> Baileys `messages-send.ts:640-646`: Same pattern.

**Rules**:
- DSM is ONLY for own devices, NEVER for recipient devices
- `destinationJid` is the **base JID** of the recipient (no device suffix)
- DSM is NOT created for group messages (groups use SenderKey, not per-device encryption)

### 5.3 Current Device Filtering

The sender's current device is EXCLUDED from encryption targets but INCLUDED in phash.

> whatsmeow `send.go:1296-1299`: `if jid == ownJID || jid == ownLID { continue }` — skip current device.
> whatsmeow `send.go:859`: `phash := participantListHashV2(allDevices)` — allDevices includes current device.

### 5.4 Self-Chat (Message to Self)

When sender == recipient:
- ALL devices get DSM-wrapped payload (there are no "recipient" devices, only "own" devices)
- Current device is still excluded
- Self-chat detection: compare **user parts only** (not full JID with server), because own JID may appear as both PN and LID

---

## 6. phash (Participant List Hash)

### 6.1 Algorithm

```
1. Collect ALL device JIDs from USync (including current device)
2. Convert each to string representation (with device suffix)
3. Sort strings lexicographically
4. Concatenate all strings (no separator)
5. SHA-256 hash the concatenated string
6. Take first 6 bytes of hash
7. Base64 encode with NO PADDING (RawStdEncoding)
8. Prefix with "2:"
```

**Result**: `"2:AB+Cd/EFgh"` (variable length, no `=` padding)

> whatsmeow `send.go:671-680`: `participantListHashV2()` uses `base64.RawStdEncoding` (no padding).
> Baileys `generics.ts:76-80`: `sha256Hash.slice(0, 6)` — BUT NOTE: Baileys takes 6 chars of base64, whatsmeow takes 6 bytes then base64-encodes. These produce different results. **Follow whatsmeow**.

### 6.2 Input JIDs

- **DM**: ALL usync devices (recipient + own, INCLUDING current device)
- **Group**: ALL group participant devices

### 6.3 Server Validation

The server compares the phash with its own computation. On mismatch:
- Server may return the expected phash
- Client should invalidate device cache and re-query on next send
- Some devices may not have received the message

> whatsmeow `send.go:444-460`: On mismatch, clears `userDevicesCache` for the recipient.

---

## 7. Message Node Structure

### 7.1 DM Message

```xml
<message id="3EB0..." type="text" to="recipient@s.whatsapp.net" phash="2:...">
  <participants>
    <to jid="recipient:0@s.whatsapp.net">
      <enc v="2" type="pkmsg">[ciphertext]</enc>
    </to>
    <to jid="recipient:2@s.whatsapp.net">
      <enc v="2" type="msg">[ciphertext]</enc>
    </to>
    <to jid="own:3@s.whatsapp.net">
      <enc v="2" type="pkmsg">[dsm_ciphertext]</enc>
    </to>
  </participants>
  <device-identity>[protobuf ADVSignedDeviceIdentity]</device-identity>
  <tctoken>[privacy token bytes]</tctoken>
</message>
```

### 7.2 Attributes

| Attribute | Required | Value |
|-----------|----------|-------|
| `id` | Yes | Message ID (generated, prefixed `3EB0`) |
| `type` | Yes | `"text"`, `"media"`, `"reaction"`, `"poll"` |
| `to` | Yes | Recipient **base JID** (no device suffix) |
| `phash` | Yes (if computed) | Participant list hash v2 |
| `addressing_mode` | Optional | `"LID"` or `"PN"` |

### 7.3 Children

| Child | When Included |
|-------|---------------|
| `<participants>` | Always (contains `<to>` nodes) |
| `<device-identity>` | When ANY participant gets `pkmsg` (prekey message) |
| `<tctoken>` | When privacy token available for recipient (DM only) |

### 7.4 Group Message

```xml
<message id="..." type="text" to="group@g.us" phash="2:..." addressing_mode="lid">
  <enc v="2" type="skmsg">[group encrypted bytes]</enc>
  <participants>
    <!-- Only participants needing SenderKey distribution -->
    <to jid="member:0@lid">
      <enc v="2" type="pkmsg">[SKDM ciphertext]</enc>
    </to>
  </participants>
  <device-identity>[if pkmsg present]</device-identity>
</message>
```

---

## 8. device-identity Node

### 8.1 When to Include

Include `<device-identity>` when **any** participant receives a `pkmsg` (PreKeySignalMessage).
This is the `includeIdentity` flag.

> whatsmeow `send.go:1402`: `includeDeviceIdentity := encAttrs["type"] == "pkmsg"`.

### 8.2 Content

The device-identity is the protobuf-encoded `ADVSignedDeviceIdentity`:

```protobuf
ADVSignedDeviceIdentity {
  details: bytes           // ADVDeviceIdentity protobuf
  accountSignatureKey: bytes(32)  // MUST be included for messages
  accountSignature: bytes(64)
  deviceSignature: bytes(64)
}
```

### 8.3 accountSignatureKey Inclusion

**Critical rule**: For outgoing messages, `accountSignatureKey` MUST be included.
For pair-success ACK, it MUST be excluded (self-signed encoding).

> whatsmeow `send.go:1227-1236`: `makeDeviceIdentityNode()` marshals `cli.Store.Account` which includes accountSignatureKey.
> Baileys `validate-connection.ts:244-253`: `encodeSignedDeviceIdentity(account, true)` — `true` = include key.

**Bug we hit**: device-identity was encoded without accountSignatureKey → recipient couldn't verify sender identity → message silently dropped.

---

## 9. Message Receiving / Decryption

### 9.1 Incoming Message Structure

```xml
<message from="sender@s.whatsapp.net" id="..." type="text" t="1234567890"
         notify="Display Name" sender_lid="123456@lid">
  <enc v="2" type="pkmsg">[ciphertext]</enc>
</message>
```

For groups:
```xml
<message from="group@g.us" id="..." type="text" t="..."
         participant="sender:0@s.whatsapp.net" participant_lid="sender_lid:0@lid">
  <enc v="2" type="skmsg">[group ciphertext]</enc>
</message>
```

### 9.2 Sender Resolution

1. Extract `from`, `participant` (groups), `sender_lid`/`sender_pn` attributes
2. For DMs: sender = `from` attribute. Check `sender_lid` for LID mapping.
3. For groups: sender = `participant` attribute. Check `participant_lid` for LID mapping.
4. **Resolve encryption JID**: If sender is PN and LID mapping exists → use LID for session lookup
5. **Migrate session** if needed (PN → LID)

> whatsmeow `message.go:314-328`: Resolves sender to encryption identity, migrates session.

### 9.3 Decryption by Type

| enc type | Handler | Description |
|----------|---------|-------------|
| `pkmsg` | PreKey decrypt | New session from prekey bundle → X3DH → ratchet |
| `msg` | Normal decrypt | Existing session → advance ratchet |
| `skmsg` | SenderKey decrypt | Group message → SenderKey cipher |

### 9.4 Multiple Encryption Candidates

A message may contain multiple `<enc>` children (different encryption types or targets).
Try each candidate until one succeeds.

### 9.5 Post-Decryption

1. Unpad the decrypted plaintext
2. Unmarshal protobuf → `Message`
3. If `Message.senderKeyDistributionMessage` present → process SKDM (store group key)
4. If `Message.deviceSentMessage` present → unwrap to get inner message
5. If `Message.protocolMessage` present → handle protocol action (key rotation, etc.)
6. Otherwise → dispatch as chat message

---

## 10. Receipt and ACK Handling

### 10.1 Message ACK (Outgoing)

After receiving a message, send an ACK:

```xml
<ack class="message" id="MSG_ID" to="sender@s.whatsapp.net"/>
```

### 10.2 Notification ACK

Notifications MUST be ACKed with `class="notification"`:

```xml
<ack class="notification" id="NOTIF_ID" to="s.whatsapp.net" type="..."/>
```

Missing notification ACKs stall server sync and history delivery.

### 10.3 Delivery Receipt

After successful decryption, send a delivery receipt:

```xml
<receipt id="MSG_ID" to="sender@s.whatsapp.net"/>
```

For messages from self (own device): `type="sender"`.

---

## 11. Retry Mechanism

### 11.1 When We Send Retry Receipt

If decryption fails, send a retry receipt to ask sender to re-encrypt:

```xml
<receipt id="MSG_ID" to="sender@s.whatsapp.net" type="retry">
  <retry count="1" id="MSG_ID" t="TIMESTAMP" v="1"/>
  <registration>[4-byte big-endian registration ID]</registration>
  <!-- On retry count > 1: include prekey bundle -->
  <keys>
    <type>[key type byte]</type>
    <identity>[identity public key]</identity>
    <key>...</key>         <!-- one-time prekey -->
    <skey>...</skey>       <!-- signed prekey -->
    <device-identity>[protobuf]</device-identity>
  </keys>
</receipt>
```

### 11.2 When We Handle Retry Receipt

When server forwards a retry receipt for our message:

1. Look up original message from cache
2. If group: recreate SenderKey distribution message
3. If own device: wrap in DeviceSentMessage
4. If retry includes prekey bundle: use it
5. Else if retry count >= 2 AND >1 hour since last recreation: fetch fresh prekeys
6. Re-encrypt and send as new message node with retry count attribute

> whatsmeow `retry.go:128-324`: Full retry handling.

### 11.3 Retry Limits

- Max 5 retry receipts sent per message ID
- Max 10 incoming retry requests handled per (sender, messageID) pair
- Session recreation cooldown: 1 hour

---

## 12. Group Message Sending

### 12.1 SenderKey Flow

Groups use SenderKey encryption (one encrypt, multiple recipients):

1. **Create/load SenderKey session** for the group
2. **Encrypt message** with SenderKey cipher → `skmsg` ciphertext
3. **Distribute SenderKey** to new participants via individual Signal encryption:
   - Build `SenderKeyDistributionMessage` protobuf
   - Encrypt per-device using normal Signal session (pkmsg/msg)
   - Only send to devices that don't have the current SenderKey

### 12.2 Group Message Node

```xml
<message id="..." type="text" to="group@g.us" phash="2:..." addressing_mode="lid">
  <enc v="2" type="skmsg">[group encrypted]</enc>
  <participants>
    <!-- Only new participants needing SKDM -->
    <to jid="new_member:0@lid">
      <enc v="2" type="pkmsg">[SKDM encrypted]</enc>
    </to>
  </participants>
</message>
```

### 12.3 Key Differences from DM

- No DeviceSentMessage wrapping
- Single `<enc type="skmsg">` for the group payload (outside `<participants>`)
- `<participants>` only contains SKDM distribution nodes (not all members)
- `addressing_mode` typically `"lid"` for groups

---

## 13. Error Handling

### 13.1 Server Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| 401 | Unauthorized / device removed | Stop, delete store, re-pair |
| 403 | Forbidden (blocked, deleted account) | Stop sending to this JID |
| 500 | Server error | Retry after backoff |

### 13.2 phash Mismatch

Server returns different phash → some devices may not have received:
- Clear device cache for this JID
- Re-query devices on next send

### 13.3 Decryption Failures

| Error | Action |
|-------|--------|
| `invalid_mac` | Session corrupted. Send retry receipt. |
| `unknown_version` | Bad ciphertext format. Skip this candidate. |
| `no_session` | No Signal session. Send retry receipt with prekey. |
| `untrusted_identity` | Identity key changed. Clear identity + session, retry. |
| `no_sender_key` | Missing group SenderKey. Mark as unavailable, request from phone. |
| `old_counter` | Message ratchet already advanced past this. Skip silently. |

---

## 14. Critical Invariants (Checklist)

These MUST ALL hold for messages to be delivered successfully:

### Identity & Keys
- [ ] Same Signal identity key used across pairing, registration, and all encrypt/decrypt
- [ ] `accountSignatureKey` included in device-identity for outgoing messages
- [ ] `accountSignatureKey` excluded from device-identity for pair-success ACK

### Device Discovery
- [ ] USync query includes BOTH recipient AND sender JIDs
- [ ] ALL returned devices are targeted (except current device)
- [ ] LID mappings stored from USync response

### Prekey Fetch
- [ ] Prekey IQ uses `xmlns="encrypt"` (not `usync`)
- [ ] Prekey IQ identity strategy is explicit and consistent:
  - PN-first (whatsmeow-style with PN wire devices), OR
  - LID-preferred when PN→LID mapping exists (Baileys-style assertSessions)
- [ ] Only fetch for devices without existing sessions (check both PN and LID)

### Session Management
- [ ] Signal session keyed by encryption identity (LID if available, else PN)
- [ ] No session created under LID if prekey was fetched under PN (unless migrated)
- [ ] Session preference: use whichever JID the session actually exists under

### Encryption
- [ ] Recipient devices get plain message protobuf
- [ ] Own devices get DeviceSentMessage-wrapped protobuf
- [ ] Current device is EXCLUDED from encryption targets
- [ ] First message to a device uses pkmsg; subsequent use msg
- [ ] Plaintext is padded before encryption

### Message Node
- [ ] `<to jid>` uses wire identity (PN)
- [ ] `phash` computed from ALL usync devices (INCLUDING current device)
- [ ] `phash` uses base64 with NO PADDING
- [ ] `<device-identity>` included when ANY target gets pkmsg
- [ ] Message `to` attribute is base JID (no device suffix)
- [ ] Message `type` is `"text"` (or media type)

### Receiving
- [ ] Sender resolved to encryption identity (LID if mapping exists)
- [ ] Multiple enc candidates tried until one succeeds
- [ ] Notifications ACKed with `class="notification"`
- [ ] Delivery receipts sent after successful decrypt

---

## 15. Reference Implementation Locations

### whatsmeow (Go) — `/tmp/whatsmeow/`
| Function | File | Lines | Purpose |
|----------|------|-------|---------|
| `sendDM` | send.go | 836-881 | DM entry point |
| `marshalMessage` | send.go | 1200-1225 | Build plaintext + DSM |
| `prepareMessageNode` | send.go | 1133-1198 | Device discovery + node |
| `encryptMessageForDevices` | send.go | 1238-1321 | Per-device encryption loop |
| `encryptMessageForDeviceAndWrap` | send.go | 1323-1343 | Wire XML wrapping |
| `encryptMessageForDevice` | send.go | 1351-1408 | Signal cipher encrypt |
| `participantListHashV2` | send.go | 671-680 | phash algorithm |
| `makeDeviceIdentityNode` | send.go | 1227-1236 | device-identity encoding |
| `migrateSessionStore` | message.go | 291-296 | PN→LID session copy |
| `handleEncryptedMessage` | message.go | 43-67 | Receive entry point |
| `decryptDM` | message.go | 539-587 | DM decryption |
| `decryptGroupMsg` | message.go | 589-613 | Group decryption |
| `sendRetryReceipt` | retry.go | 389-462 | Send retry on failure |
| `handleRetryReceipt` | retry.go | 128-324 | Handle incoming retry |
| `GetUserDevices` | user.go | 441-497 | USync device query |
| `fetchPreKeys` | prekeys.go | 124-158 | Prekey IQ |

### Baileys (TypeScript) — `/tmp/Baileys/`
| Function | File | Lines | Purpose |
|----------|------|-------|---------|
| `relayMessage` | messages-send.ts | 603-1044 | Main send path |
| `getUSyncDevices` | messages-send.ts | 214-385 | Device discovery |
| `assertSessions` | messages-send.ts | 417-486 | Prekey fetch |
| `createParticipantNodes` | messages-send.ts | 522-601 | Per-device encrypt |
| `generateParticipantHashV2` | generics.ts | 76-80 | phash |
| `encodeSignedDeviceIdentity` | validate-connection.ts | 244-253 | device-identity |
| `storeLIDPNMappings` | lid-mapping.ts | 30-106 | LID mapping storage |

---

## 16. Debug Log Checklist

For troubleshooting message delivery, ensure logs show:

1. **USync response**: All discovered devices (recipient + own)
2. **LID mappings**: Any PN→LID mappings received
3. **Prekey fetch**: Which devices needed prekeys, what JIDs used
4. **Session state**: For each device — session exists? Under which JID?
5. **Encryption targets**: Each target JID, payload kind (recipient/own), enc type (pkmsg/msg)
6. **Signal JID used**: Wire JID vs encryption JID for each target
7. **phash**: Computed value and input JID list
8. **device-identity**: Whether included (any pkmsg?)
9. **Message node**: Final XML structure sent
10. **Server response**: ACK, error code, phash mismatch

---

## 17. Current Failure Profile (2026-02-12)

Observed pattern from latest run:
- USync succeeds and device list is returned
- Prekey fetch succeeds
- Session creation succeeds
- Message is sent and server returns ACK (`class=message`)
- Message does **not** render on phone/linked device

### 17.1 Why ACK Is Not Enough

Server ACK only confirms stanza acceptance, not successful end-device decryption/rendering.
If the recipient device fails Signal/identity validation or cannot decrypt payload, the message can be silently dropped from UI.

### 17.2 Most Likely Fault Domains

1. **Signal wire compatibility mismatch**
   - PreKeySignalMessage or SignalMessage produced by our Elixir implementation may not be byte-compatible with device libsignal expectations.
2. **Session lifecycle mismatch**
   - Session recreated too often (or recreated under wrong identity) causing perpetual `pkmsg` and unstable ratchet.
3. **Identity/address mismatch**
   - Wire identity and encryption identity diverge without deterministic migration/alias policy.
4. **Self-chat fanout semantics**
   - Self-chat must encrypt only for non-sender own devices with DSM payload; any targeting drift breaks sync copy visibility.

---

## 18. Implementation Program (Mandatory)

This section is normative for ExWapp until outbound sync is proven stable.

### 18.1 Phase A: Deterministic Session Behavior

Requirements:
1. Session reuse must be default for all devices (recipient + own devices).
2. Prekey fetch only when session is absent under both candidate identities.
3. Session key-space policy must be explicit:
   - `wire_jid` and `encryption_jid` must be logged per target.
   - if mapping exists, migration/alias must be deterministic (never random fallback).
4. `pkmsg` should only occur on true bootstrap/retry paths; steady-state must converge to `msg`.

Acceptance:
- For two consecutive sends in same DM, second send emits `msg` for already-established device sessions.

### 18.2 Phase B: Signal Wire Conformance Harness

Requirements:
1. Add golden-vector tests for:
   - `serialize_prekey_signal_message`
   - `parse_prekey_signal_message`
   - `serialize_signal_message`/MAC verification
2. Add cross-implementation harness:
   - ExWapp-generated ciphertext must be decryptable by a libsignal-backed reference path.
   - Reference-generated ciphertext must be decryptable by ExWapp.
3. Include message kinds:
   - bootstrap `pkmsg`
   - follow-up `msg`
   - self-chat DSM payload

Acceptance:
- Test suite fails on any byte-level incompatibility in wire format or MAC validation.

### 18.3 Phase C: Self-Chat and Own-Device Sync Contract

Requirements:
1. Self-chat detection is by own user identity (PN/LID user equivalence).
2. Exact sender device must be excluded from encryption targets.
3. All other own devices must receive DSM payload.
4. `destinationJid` in DSM must match conversation destination JID semantics.
5. `participants` list and `phash` input must remain coherent (current device included in phash list, excluded from encrypted targets).

Acceptance:
- Live test: sending to own JID appears on phone within one sync cycle.

### 18.4 Phase D: Delivery Observability

Requirements:
1. Add explicit outcome logs after send:
   - transport ACK received
   - retry receipt received (if any)
   - downstream decrypt/receipt signals (if observable)
2. On ACK-without-render pattern, log a structured warning with:
   - message id
   - target list
   - enc types per target
   - wire/encryption identity map

Acceptance:
- Every failed user-visible delivery has enough telemetry to classify into one of Section 17.2 domains.

---

## 19. Source-Backed Rules To Follow

1. **Session reuse before prekey fetch**  
   - whatsmeow `send.go` (`existingSessions` / `retryDevices`)  
   - Baileys `messages-send.ts` (`assertSessions`)
2. **Wire JID vs encryption identity split**  
   - whatsmeow `encryptMessageForDeviceAndWrap` (`wireIdentity` + `encryptionIdentity`)
3. **Self-device DSM behavior**  
   - Baileys `createParticipantNodes` + `relayMessage` own-recipient branch
4. **phash v2 algorithm**  
   - whatsmeow `participantListHashV2` (first 6 hash bytes, RawStd base64, `2:` prefix)
5. **Device identity inclusion rule**  
   - include when any target uses `pkmsg`

Web references:
- https://github.com/tulir/whatsmeow/blob/main/send.go
- https://github.com/WhiskeySockets/Baileys/blob/master/src/Socket/messages-send.ts
- https://github.com/WhiskeySockets/Baileys/issues/2106
