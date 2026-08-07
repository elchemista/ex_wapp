# WhatsApp Multi-Device Protocol Spec for ExWapp

> Derived from whatsmeow (Go), Baileys (TypeScript), whatsapp-rust, and reconciled
> with ExWapp implementation/history and production logs through Jul 31, 2026.
> When reference behavior and current ExWapp behavior differ, this document calls it out.

---

## 1. JID Types and Addressing

### 1.1 JID Formats

| Type | Server | Example | Usage |
|------|--------|---------|-------|
| **PN (Phone Number)** | `s.whatsapp.net` | `15550001111@s.whatsapp.net` | User-facing, usync/prekey IQ, PN-addressed message fanout |
| **PN with Device** | `s.whatsapp.net` | `15550001111:2@s.whatsapp.net` | Device-specific targeting |
| **LID (Linked Identity)** | `lid` | `203139403767907@lid` | Signal session storage, encryption identity, LID-addressed message fanout |
| **LID with Device** | `lid` | `203139403767907:2@lid` | Device-specific LID |
| **Group** | `g.us` | `120363043214477337@g.us` | Group chat addressing |
| **Server** | `s.whatsapp.net` | `s.whatsapp.net` | IQ target for server requests |

### 1.2 Wire Identity vs Encryption Identity

This is the most critical distinction. Getting it wrong causes silent message delivery failure.

- **Wire Identity**: Used in server-facing XML nodes. USync and prekey-fetch IQs
  use PN identities, while a DM participant `<to jid="...">` must use the same
  PN/LID family as the outer chat destination.
- **Encryption Identity (LID)**: Used for Signal session lookup/storage and encryption cipher operations.

**Rule**: A single DM stanza MUST NOT mix PN and LID participant JIDs. For a
PN destination all participant JIDs, including own linked devices, use PN; for
a LID destination they all use LID. The Signal session can still be resolved
through the mapped encryption identity.

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

**ExWapp Note**: ExWapp now applies deterministic wire/signal session aliasing during
prekey processing and encrypt path resolution. It still keeps compatibility behavior:
if state exists only under one keyspace (wire or mapped signal JID), that keyspace is used.

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

The response contains `<device>` nodes for each user. Device JIDs are reconstructed from:
- parent `<user jid="base@server">`
- `<device id="N">` (`0` => base jid, `N>0` => `base:N@server`)

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
    <user jid="15550001111@s.whatsapp.net" reason="identity"/>
    <user jid="15550001111:2@s.whatsapp.net" reason="identity"/>
  </key>
</iq>
```

### 3.2 Key Rules

- **Namespace**: `encrypt` (NOT `usync`)
- **JIDs**: Use **wire JIDs (PN)**, NOT LID-mapped JIDs. The server expects PN JIDs.
- **Batch**: Multiple `<user>` nodes in a single IQ (efficient)
- **Default fetch policy**: fetch only for devices without existing sessions (check PN + mapped signal JID)
- **ExWapp exceptions**:
  - self-chat: the direct send path reuses existing own-device sessions
    (`:reuse_self_chat_sessions`); clearing first is kept only for the repair
    paths that genuinely need a fresh session
  - group own-target sync: own targets may be force-refreshed defensively

> whatsmeow `send.go:1279-1290`: Checks `existingSessions` map, only fetches for devices returning `false`.

### 3.3 Session After Prekey Fetch

After processing a prekey bundle, the Signal session is created under the JID used for the request.
If prekeys were fetched using PN JID → session exists under PN JID.
If session migration hasn't run → encryption MUST use PN JID (where the session actually is).

**Bug we hit**: Fetching prekeys with PN JID, then encrypting with LID JID → no session found → creates new session from bundle → wrong session state → message silently dropped by server.

### 3.4 Local Prekey Upload Durability

Uploading local one-time prekeys is a two-phase operation:

1. Atomically generate/reserve the private and public halves in the store,
   advance `next_prekey_id`, and **flush the store**. The upload is refused if
   the flush fails: an adapter that persists asynchronously must never put
   public halves in front of the server while their private halves are only in
   memory. A thinner pool on the server recovers on the next connect; an id
   space two devices disagree about never does.
2. Only then build and enqueue the upload IQ.
3. On an IQ `result`, mark the reserved IDs as `uploaded: true`.
4. On timeout, disconnect, or IQ error, keep `uploaded: false` key material and
   reuse the same IDs on the next upload attempt.

Transient request tracking may be reset on reconnect; private key material
must never depend on receiving the upload result.

### 3.5 Prekey ID Ceiling (Never Reissue a Served ID)

WhatsApp keeps serving a one-time prekey this device advertised even after the
local store loses it. Reissuing that ID with different key material locks the
holder out permanently: every inbound `pkmsg` naming it fails with
`prekey_not_found`, and every outbound message to the same peer comes back 463.

ExWapp keeps `:max_advertised_prekey_id` in the signal state — a ceiling that
never travels backwards. It is raised by every upload, every retry-receipt key,
and every inbound `pkmsg` naming an id this store cannot produce (the server
telling us what it still serves). New ids are minted above it, so a store
restored from an older snapshot cannot reissue a live id.

- Hosts with durable state that cannot roll back can supply
  `prekeys: [id_allocator: fn local_floor, count -> {:ok, first_id} end]`.
- `{:ex_wapp_session, :key_material_advertised, meta}` is published after an
  accepted prekey upload and after a retry receipt mints a key, so a host that
  archives the session file knows the moment its archive is behind.
- Decrypt failures caused by lost key material get the key bundle on the
  **first** retry receipt rather than the second: a byte-identical resend
  against unproducible key material fails identically, so only a fresh bundle
  moves the peer onto a session this device can open.

---

## 4. Signal Encryption

### 4.1 Message Padding

Before encryption, plaintext is padded:

```
padded = plaintext + random_padding
```

Padding algorithm (PKCS7-like):
1. Pick `pad_len` from 1..15 (ExWapp currently uses `random_byte & 0x0F`, with 0 mapped to 15)
2. Pad byte value = `pad_len`
3. Append `pad_len` copies of that byte

> whatsmeow `send.go:padMessage()`: Uses random padding with byte value.
> ExWapp: `ExWapp.Signal.Encryption.pad_message/1`.

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

MAC is first 8 bytes of HMAC-SHA256 with:
- Key: `mac_key`
- Data: `serialize(sender_identity) || serialize(receiver_identity) || version || protobuf`

---

## 5. DM Message Sending Flow

### 5.1 Complete Step-by-Step

1. **Build protobuf message**: `Message { conversation: "text" }` → marshal to bytes → `plaintext`
2. **Build DSM-wrapped message**: `Message { deviceSentMessage: { destinationJid: recipient, message: original } }` → marshal → `dsmPlaintext`
3. **Discover devices**: USync query with recipient + own sender identity (when different) → `recipient_devices`, `own_devices`, `all_usync_devices`
4. **Store LID mappings** from USync response
5. **Exclude current device from encryption targets** (self-chat requires filtering recipient path too)
6. **Self-chat special case**: compare user parts only; the direct send path
   reuses existing own-device sessions so the conversation advances instead of
   opening a fresh `pkmsg` per send
7. **Determine prekey needs**: for each target, check session presence under both wire JID and mapped signal JID
8. **Fetch prekeys** for missing targets (batch first, individual retry for missing bundles), always using wire PN JIDs in IQ
9. **Create sessions** from bundles with forced rebuild (`force: true`), aliasing wire/signal JID keys
10. **Encrypt per device**:
   - Skip current device
   - Own devices (matching user part) → encrypt `dsmPlaintext`
   - Recipient devices → encrypt `plaintext`
   - Each encryption → pad → Signal encrypt → get ciphertext + type (pkmsg/msg)
11. **Canonicalize fanout family** to match the outer destination; reject any
    target that cannot be mapped, then build participant nodes:
    `<to jid="wireJID"><enc v="2" type="pkmsg|msg">ciphertext</enc></to>`
12. **Build DM message node**: participants + optional device-identity + optional tctoken (`phash` not emitted in DM attrs)
13. **Send** over transport (Binary encode → Noise encrypt → WA frame)

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
- ExWapp rule: the direct send path **reuses** existing self-chat sessions
  (`:reuse_self_chat_sessions`). Clearing every own-device session per send made
  linked devices see a stream of `pkmsg` openings for a conversation that never
  advanced; clearing is kept only for repair paths that need a fresh session

---

## 6. phash (Participant List Hash)

### 6.1 Algorithm

```
1. Collect ALL device JIDs from USync (including current device)
2. Convert each JID to ADString format: `user.agent:device@server`
   - `15550001111@s.whatsapp.net` → `15550001111.0:0@s.whatsapp.net`
   - `15550001111:37@s.whatsapp.net` → `15550001111.0:37@s.whatsapp.net`
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

- **DM**: computed for diagnostics/parity only; ExWapp does NOT put `phash` in DM `<message>` attrs
- **Group**: computed from participant target JIDs used for distribution/topology checks

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
<message id="3EB0..." type="text" to="recipient@s.whatsapp.net">
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

The example is PN-addressed. If the outer `to` is `recipient@lid`, every
participant `jid` in that stanza must also be in the LID family. ExWapp validates
this invariant again immediately before transport send.

### 7.2 Message ID Format

ExWapp uses the same ID pattern as whatsmeow/Baileys/whatsapp-rust:

```
"3EB0" + UPPER_HEX( SHA256( timestamp_8bytes || own_user@c.us || random_16bytes )[0..8] )
```

- Total length: 22 chars
- Prefix: always `3EB0`

### 7.3 Attributes

| Attribute | Required | Value |
|-----------|----------|-------|
| `id` | Yes | Message ID in `3EB0` SHA256-derived format |
| `type` | Yes | `"text"`, `"media"`, `"reaction"`, `"poll"` |
| `to` | Yes | Recipient **base JID** (no device suffix) |
| `phash` | Group only | Participant list hash v2 |
| `addressing_mode` | Group only | `"lid"` or `"pn"` |

### 7.4 Children

| Child | When Included |
|-------|---------------|
| `<participants>` | Always (contains `<to>` nodes) |
| `<device-identity>` | When ANY participant gets `pkmsg` (prekey message) |
| `<tctoken>` | When privacy token available for recipient (DM only) |

Privacy-token rules (`ExWapp.PrivacyToken`): WhatsApp accepts the current
7-day bucket plus the previous three, so expired tokens are dropped rather than
attached. Tokens are ingested from notifications and from history-sync
`tcToken` fields, keyed under both addressing families (PN and LID), and merges
are newest-wins. Direct message nodes do not carry a `peer_recipient_pn`
attribute.

### 7.5 Group Message

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

Group addressing invariants:
- pick one identity family per participant based on `addressing_mode` (no mixed PN+LID duplicates)
- drop target JIDs that do not match the selected `addressing_mode`

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

1. Extract sender candidates from envelope attrs:
   `participant`, `from`, `sender_lid`, `sender_pn`, `participant_lid`, `participant_pn`
2. Add both with-device and stripped-device variants
3. Expand candidates through PN↔LID mapping table
4. Try decryption against candidates in order until one succeeds

> whatsmeow `message.go:314-328`: Resolves sender to encryption identity, migrates session.

### 9.3 Decryption by Type

| enc type | Handler | Description |
|----------|---------|-------------|
| `pkmsg` | PreKey decrypt | Route by the envelope base key across current/retained sessions; fallback to fresh X3DH only when no stored session matches |
| `msg` | Normal decrypt | Existing session → advance ratchet |
| `skmsg` | SenderKey decrypt | Group message → SenderKey cipher |

### 9.4 Multiple Encryption Candidates

A message may contain multiple `<enc>` candidates (`<message><enc>...` and/or `<participants><to><enc>...`).
Try payload candidates in order; for each payload, try sender candidates until one succeeds.

### 9.5 Post-Decryption

1. Unpad the decrypted plaintext (`enc v=3` is treated as unpadded/raw)
2. Unmarshal protobuf → `Message`
3. If `Message.senderKeyDistributionMessage` present → process SKDM (store group key)
4. If `Message.deviceSentMessage` present → unwrap to get inner message
5. If `Message.protocolMessage` present → handle protocol action (key rotation, etc.)
6. If payload is protocol/internal (history sync/SKDM-only), do not emit chat text
7. Otherwise → dispatch as chat message

After a successful fresh `pkmsg` decrypt, persist the advanced Signal session
before deleting the one-time prekey. Retain a small bounded set of prior
sessions, keyed by the incoming initiator base key, so delayed stanzas can be
routed to the ratchet that actually consumed them.

When a **retained** session decrypts a peer message, promote it back to current
and demote the session it replaces into the slot it vacated. Keeping the stale
session current means every reply is encrypted against a session the peer moved
off — the server answers with 463 while the peer keeps re-initiating, and the
mismatch never heals.

---

## 10. Receipt and ACK Handling

### 10.1 Server ACK for an Outgoing Message

For outbound sends, server returns ACK:

```xml
<ack class="message" id="MSG_ID" to="sender@s.whatsapp.net"/>
```

An ACK containing a three-digit `error` attribute is a failed send and the
numeric code must remain visible in sanitized logs.

The server acks what it accepts and stays silent for what it drops, so the
socket write is not delivery. ExWapp broadcasts the verdict on
`"ex_wapp:delivery:<session_id>"` and exposes `ExWapp.send_message_await/4`,
separating accepted / rejected / no-answer. `ExWapp.Error.Ack` classifies the
error codes so callers can tell a retriable blip from a policy refusal; unknown
codes are non-retriable.

`error="463"` means the peer could not decrypt what this session encrypted;
resending the same bytes reproduces it exactly. The rejection goes back to the
session process, which drops the peer's sessions and re-encrypts the retained
payload under a fresh one, **reusing the message ID** so the peer still
deduplicates. The budget is two attempts with `send.session_repair_backoff_ms`
between them (in live captures, a repair refused once went through seconds
later). The delivery event is withheld until the repaired attempt is answered;
every path where the repair cannot run reports the rejection itself.

If an ack returns under a different addressing family than the chat is keyed by
(e.g. a LID send acked against the peer's phone JID), fall back to an ID-wide
status update — otherwise the message stays `:pending` forever.

### 10.2 Immediate ACK for an Inbound Stanza

Inbound `message` and `call` stanzas MUST be ACKed at the connection boundary,
before routing, decryption, persistence, or subscriber publication:

```xml
<ack class="message" id="MSG_ID" to="sender:device@s.whatsapp.net"/>
<ack class="call" id="CALL_ID" to="sender@s.whatsapp.net" type="offer"/>
```

- Copy `participant` and `recipient` when present.
- For calls, derive `type` from the first child tag (`offer`, etc.) when it is
  absent on the outer node.
- The protocol ACK uses a priority transport queue and is independent of the
  later delivery receipt.
- A stream error containing `<ack class="call" .../>` means this ACK was
  missing or delayed; reconnecting alone cannot correct it.

### 10.3 Notification ACK

Notifications MUST be ACKed with `class="notification"`:

```xml
<ack class="notification" id="NOTIF_ID" to="s.whatsapp.net" type="..."/>
```

Missing notification ACKs stall server sync and history delivery.

### 10.4 Delivery Receipt

After successful decryption of an inbound message, send a receipt:

```xml
<receipt id="MSG_ID" to="sender@s.whatsapp.net"/>
```

- `type="delivery"` for regular inbound content
- `type` omitted for peer/protocol category

A delivery `<receipt>` is application delivery state; it does not replace the
transport-level stanza ACK.

---

## 11. Retry Mechanism

### 11.1 When We Send Retry Receipt

If decryption fails, send a retry receipt to ask sender to re-encrypt:

```xml
<receipt id="MSG_ID" to="sender@s.whatsapp.net" type="retry">
  <retry count="1" id="MSG_ID" t="TIMESTAMP" v="1" error="CODE"/>
  <registration>[4-byte big-endian registration ID]</registration>
  <!-- On retry count >= 2: include prekey bundle -->
  <keys>
    <type>[key type byte]</type>
    <identity>[identity public key]</identity>
    <key>...</key>         <!-- one-time prekey -->
    <skey>...</skey>       <!-- signed prekey -->
    <device-identity>[protobuf]</device-identity>
  </keys>
</receipt>
```

ExWapp retry error codes:
- `1` no session
- `3` unknown signed prekey
- `7` invalid MAC
- `0` other/unspecified

`prekey_not_found` and `key_unavailable` are not cryptographic duplicate proof.
An unseen message with either error gets a retry receipt. A decrypt failure may
be suppressed as an application redelivery only when the same message ID is
already persisted under the same canonical chat. `message_key_not_found` from
the base-key-matched ratchet is the strong replay signal.

### 11.2 When We Handle Retry Receipt

When server forwards a retry receipt for our message:

1. Look up original outbound text from chat store
2. Spawn retry send worker (bounded attempts)
3. Re-run normal send pipeline (DM/group/self rules apply)
4. If needed, refresh sessions/prekeys and re-encrypt

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
   - Use participant identity matching the group `addressing_mode` (`lid` or `pn`)
   - Exclude current sender device
   - ExWapp currently refreshes own-target prekeys defensively for reliable sync

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
- `addressing_mode` must match participant `<to jid>` identity family consistently

---

## 13. Error Handling

### 13.1 Server Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| 401 | Unauthorized / device removed | Stop, delete store, re-pair |
| 403 | Forbidden (blocked, deleted account) | Stop sending to this JID |
| 463 | Peer could not decrypt (broken Signal session) | Do NOT resend the same bytes. Drop the peer's sessions and re-encrypt under a fresh one, same message ID (see 10.1) |
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
- [ ] Prekey IQ uses wire PN JIDs (never mapped LID JIDs)
- [ ] Only fetch for devices without existing sessions (check both PN and LID)
- [ ] Missing bundles from batch response are retried individually
- [ ] Generated upload keys and `next_prekey_id` are persisted AND flushed before IQ send
- [ ] Unacknowledged upload batches survive reconnect and reuse the same IDs
- [ ] New prekey IDs are minted above `:max_advertised_prekey_id` (never reissue a served ID)

### Session Management
- [ ] Session aliasing/migration between wire and signal JIDs is deterministic
- [ ] Encryption uses whichever JID keyspace actually has session state (no blind remap)
- [ ] Direct self-chat sends reuse existing own-device sessions; only repair paths clear them
- [ ] Fresh inbound session is persisted before its one-time prekey is deleted
- [ ] Retained sessions carry the initiator base key for deterministic replay routing
- [ ] A retained session that decrypts a peer message is promoted back to current
- [ ] Ack error 463 triggers session repair (fresh session, same message ID), not a byte-identical resend

### Encryption
- [ ] Recipient devices get plain message protobuf
- [ ] Own devices get DeviceSentMessage-wrapped protobuf
- [ ] Current device is EXCLUDED from encryption targets
- [ ] First message to a device uses pkmsg; subsequent use msg
- [ ] Plaintext is padded before encryption

### Message Node
- [ ] Every DM participant `<to jid>` uses the outer destination's PN/LID family
- [ ] Final pre-send validation rejects mixed-family participant nodes
- [ ] DM messages do NOT include `phash` attr
- [ ] Group `phash` uses ADString input + first 6 hash bytes + base64(no padding)
- [ ] `<device-identity>` included when ANY target gets pkmsg
- [ ] Message `to` attribute is base JID (no device suffix)
- [ ] Message `type` is `"text"` (or media type)
- [ ] Message ID follows `3EB0` + SHA256-derived 22-char format

### Receiving
- [ ] Sender resolved to encryption identity (LID if mapping exists)
- [ ] Multiple enc candidates tried until one succeeds
- [ ] Inbound `message` and `call` stanzas ACKed before normal processing
- [ ] Notifications ACKed with `class="notification"`
- [ ] Delivery receipts sent after successful decrypt
- [ ] Public chat identity is device-stripped; participant identity may retain device

---

## 15. Reference Implementation Locations

### whatsmeow (Go) — `tmp/whatsmeow_upstream/` (git clone in this repo)
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
10. **Inbound protocol ACK**: class, type, correlation ID reference, queue priority
11. **Prekey inventory**: server/local/usable/unacknowledged counts and ID range
12. **Server response**: ACK, visible three-digit error code, phash mismatch

---

## 17. End-to-End Wire Encode/Decode Pipeline

### 17.1 Outbound Encode Path (ExWapp)

For a single outbound message, bytes are built in this order:

1. Build the WA protobuf payload as a `WAWebProtobufsE2E.Message` struct
   (generated by protox from the official schema) and encode it; the protox
   iodata output is flattened at the boundary
2. Build DSM payload for own-device copies when DM (`deviceSentMessage`, field 31)
3. Pad payload (`ExWapp.Signal.Encryption.pad_message/1`)
4. Encrypt with Signal session:
   - `pkmsg` => `0x33 || PreKeySignalMessage protobuf`
   - `msg` => `0x33 || SignalMessage protobuf || mac8`
   - `skmsg` (group top-level) => `0x33 || SenderKeyMessage protobuf || signature64`
5. Wrap ciphertext into binary node:
   - DM/group participant: `<to jid="..."><enc v="2" type="...">raw_bytes</enc></to>`
6. Build `<message>` node with attrs and children (`participants`, optional `device-identity`, optional `tctoken`, optional group `enc skmsg`)
7. Binary-node encode (`ExWapp.Binary.encode/1`)
8. Noise transport encrypt (`ExWapp.Noise.encrypt/2`)
9. WA frame encode (`ExWapp.Transport.Frame.encode/2`):
   - optional connection header once: `WA 06 03`
   - 24-bit big-endian payload length
   - encrypted payload bytes

### 17.2 Inbound Decode Path (ExWapp)

1. Read websocket frame bytes
2. Consume WA header once if present
3. Split frames by 24-bit length (`Frame.decode/1`)
4. Noise decrypt each frame (`Noise.decrypt/2`)
5. Binary unpack:
   - first byte is transport flags
   - if compression bit set (`0x02`), zlib-inflate payload
6. Binary-node decode (`ExWapp.Binary.decode/1`)
7. Message handler extraction:
   - collect `<enc>` payload candidates from root and nested participants
   - resolve sender candidates from attrs + PN/LID mapping
   - attempt decrypt over payload × sender candidate matrix
8. Post-decrypt:
   - unpad (except `enc v=3`)
   - classify protocol vs user payload
   - emit receipt or retry actions

### 17.3 WA Binary Node Encoding Essentials

- Raw ciphertext/keys must be encoded as raw binary (`Binary.raw/1`), not UTF-8 strings.
- Encoder starts with one leading `0x00` byte (whatsmeow parity).
- JIDs can be encoded as pair/ad/fb/interop tokenized forms internally.
- Attributes with `nil` or empty string are omitted.

---

## 18. Protobuf Fields Required for Correct Send/Decode

All protobuf encode/decode goes through the protox-generated modules in
`lib/ex_wapp/wa_proto/` (regenerated by `scripts/update_wa_protos.sh` from
whatsmeow's proto snapshot — never hand-edit them). The hand-rolled
`ExWapp.Proto.{Message, ExtendedTextMessage, ContextInfo, DeviceSentMessage,
ProtocolMessage, MessageKey, CompanionReg, SyncAction}` encoders are gone;
byte parity with them was pinned by test before the swap. The field numbers
below stay documented because the wire-format tests still pin the exact bytes
a phone parses.

### 18.1 `Message` (`WAWebProtobufsE2E.Message`)

- Field `1` => `conversation` (simple text)
- Field `6` => `extendedTextMessage`
- Field `12` => `protocolMessage`
- Field `31` => `deviceSentMessage` (wire tag bytes `0xFA 0x01`)

Known field-number traps caught by the generated schema:

- `ContextInfo.isForwarded` is field `22`, not 18 (18 is `conversionSource`,
  a string — the hand encoder wrote the flag there and no client ever saw it)
- `WebMessageInfo.participant` is field `5`, not 9 (the hand history-sync
  parser read the wrong field)

### 18.2 `DeviceSentMessage`

- Field `1` => `destinationJid` (base JID)
- Field `2` => nested original `Message`
- Field `3` => `phash` (optional; generally nil for DM)

### 18.3 `enc` Node Types

- `type="pkmsg"` => PreKeySignalMessage bytes
- `type="msg"` => SignalMessage bytes
- `type="skmsg"` => SenderKeyMessage bytes
- `v="2"` for current message encryption path

---

## 19. Runtime Validation Status (Jul 31, 2026)

- The send path lives in `lib/ex_wapp/session/outbound/` (direct, group,
  device_discovery, prekeys, encryptor, fanout, iq_requests) coordinated by
  `lib/ex_wapp/session/worker/outbound.ex`; inbound in
  `lib/ex_wapp/message/handler/inbound/`; the session process itself in
  `lib/ex_wapp/session/worker.ex` plus its per-concern `worker/` modules
  (connection, events, send_health, send_recovery, signal_sessions, ...).
- 750 automated tests cover send/decode invariants (message ID, DSM
  tag/fields, phash format, padding, sender-key paths), delivery confirmation
  and session repair, prekey ID integrity, send-health thresholds, and
  round-trips against the generated official protos (with golden byte vectors).
- Live-device validation has been run from production captures: DM send and
  receive, self-chat, delivery acks (including 463 repair), and prekey
  desync recovery all have log-driven fixes and tests behind them. Group
  sender-key distribution remains the least-exercised live path.

---

## 20. Source-Backed Rules To Follow

1. **Wire JID vs encryption identity split**
   - whatsmeow `encryptMessageForDeviceAndWrap` (`wireIdentity` + `encryptionIdentity`)
   - ExWapp `session/outbound/encryptor.ex` aliasing + session-aware resolution
2. **USync first, prekey second**
   - `usync` for device discovery
   - `encrypt` prekey IQ only for concrete wire JIDs
3. **Self-device DSM behavior**
   - own non-current targets receive DSM payload, current device excluded
4. **Message ID format**
   - `3EB0` + SHA256-derived uppercase hex (22 chars total)
5. **phash v2 algorithm**
   - ADString inputs, first 6 SHA256 bytes, base64 no padding, `"2:"` prefix
6. **device-identity inclusion**
   - include for outgoing messages when any target uses `pkmsg`
   - include `accountSignatureKey` for message sends

Web references:
- https://github.com/tulir/whatsmeow/blob/main/send.go
- https://github.com/WhiskeySockets/Baileys/blob/master/src/Socket/messages-send.ts
- https://github.com/WhiskeySockets/Baileys/issues/2106

---

## 21. Call Stanzas and Call Log

Companion clients receive call signalling without implementing VoIP: the
`<call>` stanza announces every phase, and the phone later syncs an
authoritative `CallLogRecord`. ExWapp merges both into one local register
(`ExWapp.Call`, store key `:call_log`, bounded by `calls.max_records`).

### 21.1 Live `<call>` Stanza

One child per stanza names the phase; the child carries `call-id` (record
identity) and `call-creator` (calling account, with `caller_pn`/`caller_lid`
alternates). The outer node carries `from` (chat) and `t` (unix seconds).

| Child | Meaning | Log effect |
|---|---|---|
| `offer` | 1:1 call ringing; `<video>` child ⇒ video call | `:ringing`, `start_time` |
| `offer_notice` | group call ringing; `media="audio\|video"`, `type="group"`, `group-jid` | `:ringing` |
| `accept` | some device answered | `:ongoing`, `accepted_at` |
| `terminate` | call over; `reason` attr (e.g. `timeout`), optional `duration` | final status, `ended_at` |
| `reject` | declined on a device | `:rejected` |
| `preaccept`/`transport`/`relaylatency`/... | VoIP negotiation | none (skipped) |

Terminate resolution: accept seen (or positive `duration` attr) ⇒
`:connected` with `duration = ended_at - accepted_at` unless the attr provided
it; otherwise `:cancelled` when the call-creator is a local identity
(outgoing), else `:missed`. The raw reason string is preserved in
`end_reason`. Reference: whatsmeow `call.go` (events only, no outcome
resolution) and Baileys `messages-recv.ts` (`terminate reason="timeout"` ⇒
missed; synthesizes `CALL_MISSED_*` stub messages).

`<call>` stanzas MUST still be ACKed at the connection boundary before this
processing (§10.2); the handler itself never sends nodes.

### 21.2 Synced `CallLogRecord`

`WAWebProtobufSyncAction.CallLogRecord` carries the phone's authoritative
outcome: `callResult` (CONNECTED/REJECTED/CANCELLED/ACCEPTEDELSEWHERE/
MISSED/...), `duration`, `startTime`, `isIncoming`, `isVideo`, `callType`,
`participants`. Two transports feed it:

- **App-state**: `SyncActionValue.callLogAction` (field 42), index
  `["call_log", ...]` in the `regular` collection; incremental after pairing.
  `DeleteIndividualCallLogAction` (`deleteIndividualCallLog`, field 46)
  removes one peer's 1:1 entries, direction-scoped by `isIncoming`.
- **History sync**: `HistorySync.callLogRecords` (field 13); the phone only
  includes it when DeviceProps registered `supportCallLogHistory: true`
  (config `protocol.pairing_device_props.history_sync_config.
  support_call_log_history`, default `false`; changing it requires re-pairing,
  and blob-delivered chunks still depend on the §"pending_blob" download gap).

Merge rule: records merge by call ID field-by-field; a transient status
(`:ringing`/`:ongoing`) never overwrites a final outcome, so replayed or late
stanzas cannot downgrade a settled call.

E2E `Message.callLogMesssage` (field 69, official triple-s typo) also exists
(`CallLogMessage`: `callOutcome`, `durationSecs`) but is not yet consumed.
