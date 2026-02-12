# ExWapp Development History

## Feb 11, 2026 — Multi-Device Send: Own Devices Not Receiving Sent Messages

### Symptom

After pairing and connecting successfully, sending a message worked for the recipient
(they received it), but the message did NOT appear on the sender's other linked devices
(phone, other web sessions, etc.). Only 1 `<to>` participant node was emitted in the
outbound `<message>`, targeting only the recipient's single device.

Logs showed:
```
[SEND] Encrypting for 1 targets: ["393515058942@s.whatsapp.net"]
[SEND] Sent encrypted message to 1 targets (base=393515058942@s.whatsapp.net)
```

No log entries for own-device discovery, own-device prekey fetch, or own-device
encryption targets.

### Root Cause Analysis

**WhatsApp multi-device (MD) requires client-side fanout:** when sending a message,
the client must encrypt and send it to:
1. All of the **recipient's** devices (phone, linked web sessions, etc.)
2. All of the **sender's own** other devices (so they see the sent message too)

ex_wapp already had the **architecture** for own-device sending in `do_send_encrypted`:
- `resolve_encryption_targets()` for recipient devices
- `resolve_own_device_targets()` for own devices (excluding current)
- `build_dm_target_specs()` to combine both lists
- `build_own_devices_payload()` to wrap in `DeviceSentMessage` protobuf

But the **device discovery step was missing**. Both functions relied on existing Signal
sessions to find device JIDs. Signal sessions are only created when prekeys are fetched
for a device. The problem: **no one ever fetched prekeys for the sender's own devices**,
so no sessions existed, so `resolve_own_device_targets()` always returned `[]`.

The old `ensure_signal_session_worker` had an `ensure_own_device_sessions_worker` that
tried to call `fetch_prekeys_worker(state, own_base_jid, signal_sessions)`, but this
approach was fundamentally flawed because:

1. **Missing device discovery protocol**: WhatsApp uses a separate protocol called
   "usync" (user synchronization) to discover which devices a user has. The prekey
   endpoint (`xmlns="encrypt"`) returns prekey bundles for known device JIDs but does
   NOT reliably serve as a device discovery mechanism for your own number.

2. **Single-JID prekey requests**: The old `build_prekey_request/2` only accepted a
   single JID string. WhatsApp supports batch prekey requests with multiple `<user>`
   nodes in one IQ, which is how whatsmeow and Baileys do it efficiently.

### What I Learned from Reference Libraries

**whatsmeow (Go):**
- Uses `GetUserDevicesContext()` which sends a "usync" IQ query to discover all device
  JIDs for given users.
- Device list response contains `<devices><device-list><device id="0"/><device id="29"/>
  </device-list></devices>` per user.
- After discovering devices, fetches prekeys only for devices without existing sessions.
- Prekey fetch is batched (multiple `<user>` nodes in one `<key>` IQ).

**Baileys (TypeScript):**
- Uses `getUSyncDevices(meId, jid, useCache)` with the local user ID.
- Separates sender's own devices (`meJids`) from recipient's devices (`otherJids`).
- Uses `executeUSyncQuery()` with `context: "message"` and `mode: "query"`.
- Maintains device list cache for efficiency.

**Common pattern across all libraries:**
1. First: usync query to discover device JIDs (both recipient + own)
2. Then: filter out current device from own list
3. Then: fetch prekeys for devices needing sessions (batch)
4. Then: encrypt with different payloads:
   - Recipient devices get the actual message
   - Own devices get a `DeviceSentMessage` wrapper containing `destinationJid` + message

### USync Protocol Format

Request:
```xml
<iq xmlns="usync" type="get" to="s.whatsapp.net" id="...">
  <usync sid="..." mode="query" last="true" index="0" context="message">
    <query>
      <devices version="2"/>
    </query>
    <list>
      <user jid="recipient@s.whatsapp.net"/>
      <user jid="own_number@s.whatsapp.net"/>
    </list>
  </usync>
</iq>
```

Response:
```xml
<iq type="result">
  <usync>
    <list>
      <user jid="recipient@s.whatsapp.net">
        <devices>
          <device-list>
            <device id="0"/>
            <device id="2"/>
          </device-list>
        </devices>
      </user>
      <user jid="own_number@s.whatsapp.net">
        <devices>
          <device-list>
            <device id="0"/>
            <device id="29"/>
          </device-list>
        </devices>
      </user>
    </list>
  </usync>
</iq>
```

The device IDs map to JIDs like: `user:device_id@s.whatsapp.net` (e.g., `393519534944:29@s.whatsapp.net`).
Device ID 0 means the primary phone: `393519534944@s.whatsapp.net` (no `:0` suffix).

### What Was Changed

All changes in `lib/ex_wapp/session.ex`.

#### 1. New function: `build_usync_device_query/2`

Builds the usync IQ query node. Takes a list of base JIDs and a message ID. Produces
the exact XML structure expected by WhatsApp servers (matching whatsmeow/Baileys format):
`<iq xmlns="usync"><usync context="message" mode="query"><query><devices version="2"/></query><list>...</list></usync></iq>`.

#### 2. New function: `parse_usync_device_response/1`

Parses the server response. Walks the nested structure:
`<iq><usync><list><user><devices><device-list><device id=.../>`.
Returns a map: `%{"base_jid" => ["user:0@server", "user:29@server", ...]}`.
Handles both `%ExWapp.JID{}` structs and binary JID strings in attrs.

#### 3. New function: `query_device_list_worker/2`

Sends the usync query via the transport and waits for the IQ response (reuses the
existing `{:prekey_response, message_id, node}` forwarding mechanism that the Session
GenServer already provides for all IQ responses to workers). 15-second timeout.

#### 4. Rewritten: `ensure_signal_session_worker/2`

**Before:** Two sequential calls:
1. `ensure_sessions_for_identity_worker(state, jid, sessions)` — fetch prekeys for recipient
2. `ensure_own_device_sessions_worker(state, own_base_jid, jid, sessions)` — fetch prekeys for own JID

The own-device step used the prekey endpoint for device discovery, which doesn't
reliably return own devices. If it failed, the error was silently swallowed and
own_targets ended up empty.

**After:** Single coordinated flow:
1. Build query JID list (recipient + own base JID if different)
2. Send usync query to discover all device JIDs
3. Filter out current device from own devices
4. Find which discovered devices don't have Signal sessions yet
5. Batch fetch prekeys for all devices needing sessions
6. Create Signal sessions for each
7. Return all sessions + prekey bundles

Fallback: if usync fails, falls back to individual prekey fetch for recipient only
(graceful degradation).

#### 5. Refactored: `build_prekey_request/2`

**Before:** Accepted only a single JID string, produced one `<user>` node.

**After:** Accepts both a single string and a list of JIDs. When given a list,
produces multiple `<user>` nodes inside the `<key>` IQ, enabling batch prekey
fetch in a single round-trip (matching whatsmeow behavior).

#### 6. New function: `fetch_prekeys_batch_worker/3`

Sends a batch prekey request (multiple device JIDs in one IQ) and processes all
returned bundles into Signal sessions.

#### 7. Removed dead code

Removed `ensure_sessions_for_identity_worker/3` and `ensure_own_device_sessions_worker/4`
(replaced by the unified `ensure_signal_session_worker/2`).

### Expected Behavior After Fix

Logs should now show:
```
[USYNC] Querying device list for ["393515058942@s.whatsapp.net", "393519534944@s.whatsapp.net"]
[SEND] USync device map: %{"393515058942@..." => ["393515058942:0@..."], "393519534944@..." => ["393519534944:0@...", "393519534944:29@..."]}
[SEND] Discovered recipient devices: ["393515058942:0@s.whatsapp.net"]
[SEND] Discovered own devices (excl. self): ["393519534944:0@s.whatsapp.net"]
[SEND] Fetching prekeys for 2 devices: [...]
[SEND] Recipient targets for ...: [...]
[SEND] Own-device targets: ["393519534944:0@s.whatsapp.net"]
[SEND] Sent encrypted message to 2 targets (base=393515058942@s.whatsapp.net)
```

The outbound `<message>` node should contain multiple `<to>` children:
```xml
<message to="393515058942@s.whatsapp.net" type="text" id="...">
  <participants>
    <to jid="393515058942:0@s.whatsapp.net">
      <enc type="pkmsg" v="2">...</enc>
    </to>
    <to jid="393519534944:0@s.whatsapp.net">
      <enc type="pkmsg" v="2">...</enc>
    </to>
  </participants>
  <device-identity>...</device-identity>
</message>
```

Own devices receive the message wrapped in `DeviceSentMessage` protobuf, which tells
them "this message was sent TO 393515058942@s.whatsapp.net". This is how WhatsApp
multi-device sync works — the phone and other linked devices all see the conversation.

### Verification

- `mix compile` passes (no new warnings)
- `mix test` passes (63 tests, 0 failures)
- Runtime verification: requires fresh pair + send test (delete old session file first)

### Key Takeaway

WhatsApp multi-device has **two separate protocols** for message sending:
1. **usync** (`xmlns="usync"`) for **device discovery** — "which devices does this user have?"
2. **encrypt** (`xmlns="encrypt"`) for **prekey fetch** — "give me encryption keys for these specific devices"

You MUST use usync first to discover devices, then encrypt for all discovered devices.
Using only the prekey endpoint as a device discovery mechanism is unreliable, especially
for discovering your own devices.

---

## Feb 11, 2026 — Own Device Session: Inbound vs Outbound Session Mismatch

### Symptom

After implementing usync device discovery (see above), the usync query worked correctly
and discovered both recipient devices and own devices. However, the message still did NOT
arrive on the sender's phone. Logs showed:

```
[SEND] USync device map: %{"393515059842@..." => [...], "393519534944@..." => [...]}
[SEND] Discovered own devices (excl. self): ["393519534944@s.whatsapp.net"]
[SEND] All 2 devices already have sessions     <-- BUG: should have fetched prekeys!
```

The own phone device was skipped for prekey fetch because `has_session?` returned `true`.
The encryption then produced `enc type="msg"` (Signal whisper message) instead of
`enc type="pkmsg"` (Signal prekey message).

### Root Cause Analysis

During login/pairing, the phone sends multiple sync messages (`pkmsg`) to our new device
(device 31). Each `pkmsg` creates an **inbound** Signal session via X3DH from the phone's
side. In the logs, 7 sequential `pkmsg` messages were received from the phone during sync,
each one creating/replacing the session with "PreKey decrypt succeeded (new session)".

The resulting session in the session store is an **inbound** session — the phone initiated
the X3DH, so the ratchet state reflects the phone as sender and device 31 as receiver.

When device 31 later tries to **send** a message to the phone using this inbound session:
1. `has_session?` returns `true` (session exists from sync)
2. Prekey fetch is skipped (the filter assumed existing session = ready to send)
3. Encryption uses the existing inbound session
4. Result: `enc type="msg"` (whisper) — a Signal message using existing ratchet state
5. The phone **cannot decrypt** this because:
   - The ratchet state is inconsistent (7 sequential pkmsg from phone created layers of state)
   - The phone expects device 31 to establish a NEW outbound session, not reuse the inbound one
   - A `msg` type message implies an established bidirectional session, but device 31 never completed its side of the handshake

### Signal Protocol Session Directionality

**Key insight**: In Signal Protocol, sessions created by receiving `pkmsg` (PreKeySignalMessage)
are **inbound** sessions. They allow you to DECRYPT messages from the initiator but are NOT
suitable for SENDING back to them in all cases — especially when:
- Multiple sequential pkmsg were received (ratchet state is advanced/complex)
- The remote side doesn't expect a `msg` (whisper) from you yet
- The session was never "confirmed" by sending a `pkmsg` back

For own-device communication specifically, the safe approach is to ALWAYS establish a fresh
**outbound** session by fetching the phone's prekeys and performing our own X3DH. This
ensures:
1. First message to the phone is `pkmsg` (the phone treats it as new session establishment)
2. Clean X3DH handshake from our side
3. No ratchet state confusion from accumulated inbound sync messages

### What Was Changed

In `ensure_signal_session_worker/2` in `lib/ex_wapp/session.ex`:

**Before:**
```elixir
devices_needing_prekeys =
  Enum.filter(all_device_jids, fn device_jid ->
    device_jid = normalize_jid_with_device(device_jid)
    not ExWapp.Signal.SessionStore.has_session?(signal_sessions, device_jid)
  end)
```

This skipped ALL devices with existing sessions, including own devices with inbound-only sessions.

**After:**
```elixir
own_device_set = MapSet.new(own_devices)

devices_needing_prekeys =
  Enum.filter(all_device_jids, fn device_jid ->
    device_jid = normalize_jid_with_device(device_jid)
    MapSet.member?(own_device_set, device_jid) or
      not ExWapp.Signal.SessionStore.has_session?(signal_sessions, device_jid)
  end)
```

Own devices are ALWAYS included in `devices_needing_prekeys`, forcing fresh prekey fetch
and new outbound X3DH session creation, regardless of existing inbound sessions.

### Expected Behavior After Fix

Logs should now show:
```
[SEND] Discovered own devices (excl. self): ["393519534944@s.whatsapp.net"]
[SEND] Fetching prekeys for 2 devices: ["393515059842@s.whatsapp.net", "393519534944@s.whatsapp.net"]
```

Instead of "All 2 devices already have sessions", both devices get fresh prekeys.
The outbound message to own phone will be `enc type="pkmsg"` (not `msg`), which the
phone can process as a new session establishment from device 31.

### Key Takeaway

**Never reuse inbound Signal sessions for sending to own devices.** Inbound sessions
(from receiving sync `pkmsg` during login) have ratchet state that reflects the remote
as sender. For own-device fanout, always establish a fresh outbound session by fetching
prekeys — this guarantees `pkmsg` type and clean X3DH handshake.

---

## Feb 11, 2026 — Root Cause Found: `pkmsg` Decrypt Was Resetting Sessions (Workaround Removed)

### What We Learned

After reviewing WhatsMeow/Baileys behavior more closely, the earlier "always fetch fresh
prekeys for own devices" rule was identified as a workaround, not the protocol-correct fix.

Both reference clients treat own devices and recipient devices the same for session checks:
- If session exists: reuse it
- If session missing: fetch prekeys

So if our own-device sync failed while reusing a session, the real bug had to be in our
Signal session/ratchet implementation.

### Actual Root Cause

The bug was in prekey decryption for existing sessions:

1. We received multiple inbound sync `pkmsg` from phone during login (normal).
2. In `SessionStore.decrypt_message/6` (prekey branch), when a session already existed,
   we still called `Signal.decrypt_prekey_message/3`.
3. `decrypt_prekey_message/3` always does fresh X3DH bootstrap and returns a new session.
4. We persisted that new session each time, replacing ratchet state repeatedly.
5. Outbound encryption then used a corrupted/shifted session state.

Net effect: own-device communication became unreliable unless we forced fresh prekeys.

### Proper Fix Implemented

Instead of rebuilding session on every inbound `pkmsg`, we now:

1. Parse `PreKeySignalMessage`
2. Verify remote identity key matches session identity
3. Decrypt the **inner SignalMessage** using the existing session ratchet
4. Only fall back to fresh X3DH if existing-session decrypt fails (or no session exists)

### Code Changes

- `lib/ex_wapp/signal/session.ex`
  - Added `decrypt_prekey_message_with_session/2`
  - Added `verify_remote_identity/2` guard
- `lib/ex_wapp/signal/adapter.ex`
  - Exposed `decrypt_prekey_message_with_session/2`
- `lib/ex_wapp/signal/session_store.ex`
  - Prekey decrypt path now tries existing session ratchet first
  - Fresh X3DH only as fallback
- `lib/ex_wapp/session.ex`
  - Removed "own devices always fetch prekeys" rule
  - Returned to WhatsMeow/Baileys semantics: fetch only when session missing
  - Kept recipient fallback when usync returns no devices
- `test/signal_session_store_test.exs`
  - Added regression: repeated `pkmsg` wrappers must not reset session and reply whisper must decrypt

### Verification

- `mix test test/signal_session_store_test.exs` passed
- `mix test test/whatsmeow_parity_test.exs` passed
- Full suite: `mix test` passed (`64 tests, 0 failures`)

### Updated Takeaway

The real issue was not "inbound sessions are inherently unusable for sending".
The issue was that our implementation kept replacing existing sessions on inbound `pkmsg`.
Once that was fixed, we could safely reuse sessions for own devices exactly like
WhatsMeow/Baileys do.

---

## Feb 11, 2026 — Group Idle Decrypt Failures (`skmsg`) Fixed with Sender-Key Support

### Symptom

While connected and idle in group chats, incoming messages often failed decrypt with logs like:
- `enc_type="skmsg"`
- `Whisper decrypt failed ... :invalid_length_delimited_field` or `{:unsupported_wire_type, 6}`
- retry receipt sent
- sender re-sent as `pkmsg`
- message decrypted only after resend

This caused repeated decrypt-fail/retry cycles for normal group traffic.

### Root Cause

`ex_wapp` had no sender-key pipeline for group messages:

1. Incoming `skmsg` was incorrectly routed to 1:1 Signal session decrypt (`msg` path).
2. Incoming sender-key distribution payloads (`Message.senderKeyDistributionMessage`, field `2`) were not parsed/stored.
3. Distribution payloads were misclassified as user text in some cases (e.g. showing group JID string), instead of protocol/internal messages.

So the app never had sender chain state for group senders, and `skmsg` could not decrypt.

### What We Learned from Reference Libraries

From whatsmeow + libsignal group flow:
- `skmsg` uses Signal SenderKeyMessage wire format: `version || protobuf || signature(64)`.
- Signature is over `version||protobuf` (without trailing signature).
- Sender chain derivation:
  - message seed = `HMAC(chain_key, 0x01)`
  - next chain key = `HMAC(chain_key, 0x02)`
- Message keys from seed:
  - HKDF-SHA256 with info `"WhisperGroup"` output 48 bytes
  - first 16 bytes = IV, next 32 bytes = cipher key
- Distribution message (`SenderKeyDistributionMessage`) provides:
  - key id
  - iteration
  - chain key
  - signing key

### Fix Implemented

#### 1) New module: `lib/ex_wapp/signal/sender_key.ex`

Implemented:
- parsing/storing sender-key distribution messages from decrypted WA payloads (fields `2` and `15`)
- `skmsg` parse + signature verification
- sender-chain/message-key derivation compatible with libsignal (`WhisperGroup`)
- AES-CBC decrypt for group sender-key ciphertexts
- skipped-message key cache and future-iteration bound checks (max 2000, aligned with libsignal behavior)
- persistent sender-key state storage in `signal.sender_keys`

#### 2) Message handler integration: `lib/ex_wapp/message_handler.ex`

Implemented:
- route `enc type="skmsg"` in group chats through `SenderKey.decrypt_group_message/4` instead of 1:1 session decrypt
- after successful decrypt, process sender-key distribution payloads and persist state
- if sender-key distribution is present, classify content as protocol/internal and skip chat display

### Result

- Group `skmsg` messages now decrypt directly when sender-key state exists.
- Sender-key distribution messages are consumed and stored instead of displayed as chat text.
- Retry fallback for normal group traffic is no longer required in the common case.

### Verification

- Added tests: `test/signal_sender_key_test.exs`
  - distribution parse/store + direct `skmsg` decrypt
  - full handler flow: `pkmsg` distribution bootstrap -> `skmsg` group message decrypt
- `mix test test/signal_sender_key_test.exs` passed (`2 tests, 0 failures`).

---

## Feb 11, 2026 — Chat/Group Lists Fixed by Parsing Protocol History Sync Payloads

### Symptom

After successful login and sync, list output still showed:
- `No chats found in local store yet.`
- `No groups found in local chat store yet.`

Even though many encrypted `pkmsg` payloads were decrypted successfully.

### Root Cause

We were correctly decrypting protocol messages but dropping them:

1. Decrypted payloads containing `Message.protocolMessage` were classified as protocol/internal.
2. Protocol messages were intentionally skipped from chat display/storage.
3. We only populated chats from notification `<collection><item><chat|group ...>>` nodes.
4. In this account/session, most chat metadata arrived inside
   `protocolMessage.historySyncNotification.initialHistBootstrapInlinePayload`, not in those notification collections.

So chat metadata existed in decrypted data, but we never ingested it into local `:chats`.

### What Reference Libraries Do

Both Baileys and whatsmeow handle history sync through protocol message payloads:

- Detect `protocolMessage.historySyncNotification`
- Prefer `initialHistBootstrapInlinePayload` when present
- zlib-inflate payload
- Decode `HistorySync`
- Upsert conversation metadata (id/name/unread/archive/pin/mute/timestamps)

### Fix Implemented

#### 1) Added parser for inline protocol history sync

- New file: `lib/ex_wapp/proto/history_sync.ex`
- Implements minimal protobuf-wire parser for:
  - `Message.protocolMessage` (field 12)
  - `ProtocolMessage.historySyncNotification` (field 6)
  - `HistorySyncNotification.initialHistBootstrapInlinePayload` (field 11)
  - `HistorySync.conversations` (field 2)
  - `HistorySync.phoneNumberToLidMappings` (field 15)
- Inflates inline payload via zlib and extracts conversation metadata + PN/LID mappings.

#### 2) Wired ingestion into message handling path

- Updated: `lib/ex_wapp/message_handler.ex`
- On decrypted protocol payloads, now:
  - parse inline history sync
  - upsert chat/group metadata via `Chat.merge_metadata/3`
  - persist PN<->LID mappings into `:lid_mapping` for better jid resolution
- Keeps protocol messages hidden from chat timeline, but now uses them to populate local chat index.

### Verification

- Added regression test:
  - `test/whatsmeow_parity_test.exs`
  - `protocol history sync inline payload populates chat and group metadata`
  - Sends encrypted `pkmsg` containing protocol history sync inline payload and asserts:
    - chats are created
    - group appears in group list
    - metadata fields (name/unread/pin/archive/mute/timestamp) are set
- Full suite passed:
  - `mix test` -> `67 tests, 0 failures`

---

## Feb 11, 2026 — Sent Messages Not Syncing to Phone/Other Own Devices

### Symptom

Outgoing 1:1 messages were accepted by server (`ack class=message`) but did not appear
on phone/other linked devices.

From logs:
- USync returned own devices including base + explicit device IDs.
- We logged own devices as:
  - `["393519534944@s.whatsapp.net", "393519534944:32@s.whatsapp.net"]`
- But final own-device fanout only used:
  - `["393519534944:32@s.whatsapp.net"]`

So the base own JID (phone path) was dropped from participant encryption targets.

### Root Cause

Target selection used session-derived own targets and applied base-alias dropping logic:
- if an explicit device JID existed, bare/base own JID was removed.

That optimization is unsafe for own-device fanout because bare own JID can represent the
primary phone route. Result: message sync copy skipped phone.

### Fix Implemented

Updated send path in `lib/ex_wapp/session.ex`:

1. `ensure_signal_session_worker/2` now returns USync-discovered target hints
   (`recipient_devices`, `own_devices`) alongside sessions/prekey bundles.
2. `do_send_encrypted/7` now uses those hints when resolving fanout targets.
3. `resolve_own_device_targets/4` no longer drops bare/base own JID when explicit device IDs exist.
4. Added `normalize_target_list/1` helper so target normalization is consistent.

### Expected Result

Outgoing participant fanout should now include both:
- recipient device targets
- own-device targets from USync, including base phone JID when present

so sent messages are mirrored correctly to phone/linked devices.

### Verification

- Full suite passed after patch:
  - `mix test` -> `67 tests, 0 failures`

---

## Feb 11, 2026 — Group Send Timeout Fixed with Real Sender-Key Outbound Flow

### Symptom

Sending to a group JID (`@g.us`) timed out after 5s in `GenServer.call/3`.

From logs:
- group JID was sent to usync/prekey as if it were a direct recipient
- prekey IQ contained `<user jid="...@g.us"/>`
- call timed out waiting for DM-style session flow

### Root Cause

`send_text` had only the 1:1 send pipeline. Group sends were incorrectly routed through:
1. usync for recipient/own devices (DM assumptions)
2. prekey fetch/session creation for a single recipient identity
3. participant fanout intended for direct + own-device DSM payloads

There was no outbound `skmsg` + sender-key distribution path for groups.

### What Was Implemented

#### 1) Dedicated group send branch in `session.ex`

- `do_send_text_worker/4` now detects `@g.us` and routes to `do_send_group_worker/4`.
- New `w:g2` interactive group-info query:
  - builds IQ: `xmlns="w:g2"`, `type="get"`, `<query request="interactive"/>`
  - parses `<group><participant .../>` + optional `addressing_mode`

#### 2) Group session/prekey preparation for sender-key distribution

- New group session prep worker:
  - resolves participant device targets via usync
  - excludes current local device from distribution fanout
  - fetches missing prekeys for participant devices
  - reuses existing sessions when available (same semantics as DM)

#### 3) Outbound sender-key APIs in `signal/sender_key.ex`

Added:
- `create_outbound_distribution_message/3`
  - creates/reuses local sender-key state
  - returns WA payload containing `senderKeyDistributionMessage` (field 2)
- `encrypt_outbound_group_message/4`
  - encrypts payload as sender-key message (`skmsg`)
  - signs message and advances sender chain

#### 4) Correct group message node shape

Group message now sends:
- `<participants>` with pairwise encrypted sender-key distribution payloads
- top-level `<enc type="skmsg" v="2">...</enc>` for group ciphertext
- `<device-identity>` when any participant distribution encryption is `pkmsg`
- `phash` derived from participant target list
- optional `addressing_mode` when provided by group metadata

### Additional Fix During This Patch

Batch prekey processing no longer aliases sessions using only the first requested JID.
For batch IQ prekey responses, session creation now keys by returned `device_jid` directly,
which avoids subtle alias/order corruption when multiple devices are requested together.

### Verification

- Added regression test in `test/signal_sender_key_test.exs`:
  - `creates outbound sender key distribution and encrypts skmsg`
- Full suite passed:
  - `mix test` -> `68 tests, 0 failures`

### Follow-up Parity Pass (Pre Live Test)

After re-checking WhatsMeow/Baileys DM sync behavior, one additional alignment was added:
- DM own-device discovery now chooses sender identity by destination addressing mode:
  - LID destination -> own LID identity
  - PN destination -> own PN identity (fallback to LID if PN missing)

This matches reference behavior where sender/recipient device enumeration is done with
conversation-consistent identity (important on migrated PN<->LID accounts).

---

## Feb 11, 2026 — Own-Device Sync: Prekey Fetch Was Not Rebuilding Session

### Symptom

Even after forcing prekey fetch for own targets, outbound fanout still contained own
entries with `enc type="msg"` instead of `enc type="pkmsg"`, and sent messages still did
not appear on phone/linked devices.

### Root Cause

`process_prekey_response -> create_sessions_for_bundles` called:

- `SessionStore.get_or_create_session(..., bundle, ...)`

But `get_or_create_session` returned existing sessions unchanged when one was already in
store. In that path:

- `base_key` came back as `nil`
- encryption fallback in `SessionStore.encrypt_message/6` emitted whisper (`msg`)

So "fetching prekeys" did not actually refresh the ratchet/session for already-known own
targets.

### Fix Implemented

#### 1) Added forced session recreation option

File: `lib/ex_wapp/signal/session_store.ex`

- Added `get_or_create_session/6` with `force: true` option.
- When forced, session is always rebuilt from the fetched bundle (`Signal.create_session`)
  even if a previous session exists.
- Existing 5-arg API is preserved and delegates to 6-arg with default `[]`.

#### 2) Wired forced recreation into prekey-processing path

File: `lib/ex_wapp/session.ex`

- In `create_sessions_for_bundles/5`, switched to:
  - `SessionStore.get_or_create_session(..., force: true)`
- In the legacy single-recipient prekey setup path, same `force: true` applied for
  consistency.

This guarantees fetched bundles produce fresh sessions + non-nil `base_key`, so outbound
encryption can wrap as `pkmsg` for those targets.

### Verification

- Added regression test:
  - `test/signal_session_store_test.exs`
  - `get_or_create_session with force recreates an existing session and returns a new base key`
- Ran:
  - `mix test test/signal_session_store_test.exs test/signal_sender_key_test.exs test/whatsmeow_parity_test.exs`
  - Result: `13 tests, 0 failures`

---

## Feb 11, 2026 — Logs_8 Audit + Final Send-Path Hardening

### What We Verified in `logs_8.txt`

1. **Group send flow is structurally correct and server-accepted**
- Group path executes: `w:g2` info query -> group usync -> group prekey fetch -> participant fanout + top-level `skmsg`.
- Final group stanza is ACKed by server (`class=message`), so transport/stanza shape is valid.

2. **Most visible “errors” in this run are transient/non-fatal**
- ADV decode fallback warnings during pairing are recovered by HMAC parse path.
- Stream `515` and `503` are followed by successful reconnect/login.
- One IEx `undefined variable "session"` is local shell typo, not protocol failure.

3. **Real remaining risk identified from logs**
- Own-device targets can still appear as `enc type="msg"` in outbound fanout when prekey/session refresh is incomplete for some own targets.
- This can happen even when batch prekey fetch succeeds partially and returns fewer bundles than requested.

### Additional Fixes Implemented

#### 1) Explicit handling for stream error `503`

File: `lib/ex_wapp/session.ex`

- Added dedicated `503` branch in `stream:error` handling:
  - logs as transient service unavailable
  - follows reconnect path (instead of “unknown stream error” noise)

#### 2) Stronger local identity extraction (PN/LID)

File: `lib/ex_wapp/session.ex`

- Hardened `local_account_jid_value/1` and `local_account_lid_value/1` with exhaustive atom/string key-path fallbacks for:
  - `pairing.device.jid/lid`
  - `client_info.jid/lid`
- This reduces risk of choosing the wrong own sender identity when store maps are mixed atom/string keyed.

#### 3) Retry missing prekeys after batch response (DM + Group)

File: `lib/ex_wapp/session.ex`

- Added `retry_missing_prekeys_worker/5`.
- After batch prekey fetch, code now:
  - compares requested device JIDs vs returned bundle keys
  - retries missing devices individually
  - merges recovered bundles/sessions before encryption
- Wired into both:
  - DM path (`ensure_signal_session_worker/2`)
  - Group path (`ensure_group_sender_key_sessions_worker/3`)

This closes partial batch-response gaps that could leave some own targets on stale sessions (`msg`) instead of refreshed prekey bootstrap (`pkmsg`).

### Test Coverage Added/Confirmed

1. New outbound-chain simulation test:
- File: `test/signal_sender_key_test.exs`
- Test: `simulated outbound chain yields pkmsg distribution and signed skmsg`
- Verifies:
  - pairwise distribution is emitted as `pkmsg`
  - prekey wire payload fields are correct
  - sender-key group ciphertext decrypts correctly
  - signature tampering is rejected (`:invalid_sender_key_signature`)

2. Existing force-rebuild regression retained:
- File: `test/signal_session_store_test.exs`
- Test: `get_or_create_session with force recreates an existing session and returns a new base key`

3. Verification command:
- `mix test test/signal_session_store_test.exs test/signal_sender_key_test.exs test/whatsmeow_parity_test.exs`
- Result after latest hardening: `14 tests, 0 failures`

### Current Status

- Send pipeline now follows the same core order as reference clients:
  1. discover devices (usync)
  2. ensure sessions/prekeys (with missing-bundle retry)
  3. encrypt fanout for recipient + own devices
  4. send stanza with correct participant payload types and sender-key envelope for groups
- Remaining validation is live runtime parity check on a fresh log:
  - confirm own-device participants are consistently refreshed and emitted as expected during real sends.

---

## Feb 12, 2026 — Sent Messages Not Visible on Phone: Device-Identity Missing accountSignatureKey

### Symptom

Outgoing messages were accepted by server (`ack class=message`), encrypted for both
recipient and own device (phone), but did NOT appear on the sender's phone or other
linked devices. From `logs_10.txt`:

```
[SEND] Using adv_self_signed device identity: 152 bytes
[SEND] Including device-identity in message
[ACK] id=... class=message
```

Message was sent, server ACKed, but phone silently dropped it.

### Root Cause Analysis

**Three bugs identified by comparing with whatsmeow and Baileys:**

#### Bug 1 (Critical): `device-identity` encoded WITHOUT `accountSignatureKey`

The `<device-identity>` node in outgoing messages used the `adv_self_signed` payload,
which was specifically encoded **without** `accountSignatureKey` for the pair-device-sign
ACK during pairing. But outgoing **messages** require the full ADV identity **with**
`accountSignatureKey` so that recipients can verify our device identity.

From whatsmeow `send.go`:
```go
// For pairing ACK: removes accountSignatureKey
ownDeviceIdentity := proto.Clone(cli.Store.Account).(*waProto.ADVSignedDeviceIdentity)
ownDeviceIdentity.AccountSignatureKey = nil

// For messages: uses full Store.Account (WITH accountSignatureKey)
func (cli *Client) makeDeviceIdentityNode() waBinary.Node {
    identity := cli.Store.Account  // Full identity
    return waBinary.Node{Tag: "device-identity", Content: identity}
}
```

In ex_wapp, the `get_device_identity_node` function matched `adv_self_signed` FIRST
(the pairing-only encoding), so message device-identity was always missing
`accountSignatureKey`. Without it, the phone can't verify our device identity and
silently drops the message.

**Fix**: Reordered `get_device_identity_node` to prefer `adv.signed` struct encoded
with `include_signature_key: true` (matching whatsmeow). The `adv_self_signed` payload
is now only used for pair-device-sign ACK (in `pairing.ex`), never for messages.

#### Bug 2: Self-chat detection failed (user-part comparison)

When sending to your own number, `self_chat_destination?` was always `false` because it
compared `{user, server}` tuples. If the own JID came from a different source or had
different server suffix, the tuples wouldn't match.

whatsmeow compares **user parts only**:
```go
if jid.User == ownJID.User || jid.User == ownLID.User { ... }
```

**Fix**: Changed self-chat detection to compare user parts only via new `jid_user_part/1`
helper. This matches whatsmeow behavior and handles PN/LID addressing differences.

#### Bug 3: `phash` computation slightly wrong

The participant hash used `first 6 chars of base64(full_hash)` instead of
`base64(first 6 bytes of hash)` (whatsmeow format). While the server accepted both,
aligning with whatsmeow is safer.

**Fix**: Changed to `Base.encode64(first_6_bytes, padding: false)`.

### What Was Changed

All changes in `lib/ex_wapp/session.ex`:

1. **`get_device_identity_node/1`**: Reordered to prefer `adv.signed` struct with
   `include_signature_key: true` over `adv_self_signed`. Removed the `adv_self_signed`
   path entirely from message sending.

2. **Self-chat detection** (in `do_send_encrypted`): Changed from `MapSet` of
   `{user, server}` identity tuples to `MapSet` of user parts only. Added
   `jid_user_part/1` helper.

3. **`generate_participant_hash_v2/1`**: Changed from `binary_part(Base.encode64(hash), 0, 6)`
   to `Base.encode64(binary_part(hash, 0, 6), padding: false)` to match whatsmeow.

### Key Takeaway

WhatsApp `device-identity` has **two different encoding requirements**:
- **Pair-device-sign ACK**: `ADVSignedDeviceIdentity` **without** `accountSignatureKey`
- **Outgoing messages**: `ADVSignedDeviceIdentity` **with** `accountSignatureKey`

Using the pairing-only encoding for messages causes recipients to silently drop the
message because they can't verify the sender's device identity.

### Verification

- `mix compile` passes
- `mix test` passes (70 tests, 0 failures)
- Runtime verification: requires fresh pair + send test to confirm messages now
  appear on phone

---

## Feb 12, 2026 — Messages Not Arriving: Prekey Fetch Using LID Instead of PN JIDs

### Symptom

After applying the device-identity fix, messages were sent (server ACKed) but still not
arriving at the recipient's phone. Logs showed:

```
Discovered recipient devices: ["6287865904022@s.whatsapp.net"]    ← USync returned PN
Fetching prekeys for 2 devices: ["203139403767907@lid", ...]      ← Prekey fetched for LID!
Encrypting target=6287865904022@s.whatsapp.net using mapped signal_jid=203139403767907@lid
```

The prekey IQ request sent `203139403767907@lid` to the server instead of
`6287865904022@s.whatsapp.net`.

### Root Cause

In `session.ex` line ~2094 (the DM send worker), `devices_needing_prekeys` was being
remapped through `resolve_signal_encryption_jid()` via `lid_mapping` **before** the
prekey fetch IQ was sent to the server:

```elixir
# BEFORE (BUG):
devices_needing_prekeys =
  Enum.filter(all_device_jids, fn device_jid -> ... end)
  |> Enum.map(&resolve_signal_encryption_jid(&1, lid_mapping))  # ← remaps PN to LID
  |> normalize_target_list()
```

This caused the `<iq xmlns="encrypt">` prekey request to use LID JIDs. But whatsmeow
fetches prekeys using the **original PN JIDs** from usync, NOT LID-mapped JIDs.

In whatsmeow `send.go:1261-1289`:
- `sessionAddressToJID` maps LID signal addresses **back** to original PN JIDs
- `retryDevices` contains PN JIDs (mapped back from LID addresses)
- `fetchPreKeysNoError(retryDevices)` sends prekey request with PN JIDs
- LID mapping is used **only** for Signal session storage/encryption, not server requests

The prekey response for a LID may return a bundle for a different device identity or
fail silently, causing the recipient to be unable to decrypt the message.

### Fix

Removed the LID remapping from the prekey fetch list. The `resolve_signal_encryption_jid`
mapping is still used correctly in `encrypt_for_targets()` for Signal session encryption,
but the prekey IQ request now uses the original PN JIDs from usync:

```elixir
# AFTER (FIXED):
devices_needing_prekeys =
  Enum.filter(all_device_jids, fn device_jid -> ... end)
  |> normalize_target_list()   # ← no LID remapping, use PN JIDs for server request
```

### Key Insight

WhatsApp protocol uses two JID identities for the same device:
- **Wire JID (PN)**: Used for server-facing operations (usync, prekey fetch, `<to>` nodes)
- **Encryption JID (LID)**: Used for Signal session storage and encryption

These must NOT be mixed. Prekey fetch = server request = PN. Encryption = Signal session = LID.

### Verification

- `mix test` passes (80 tests, 0 failures)

## Feb 12, 2026 — Wire JID vs Encryption JID Session Migration Fix

### Symptom

Sends were ACKed by server but still not rendering on phone/linked devices.
Logs showed prekeys fetched and sessions created, but delivery/decrypt behavior was inconsistent.

### Root Cause

Our send path still diverged from whatsmeow in a critical place:

1. We fetched prekeys by wire JID (PN) (correct), but then
2. We did not consistently migrate/alias sessions to the mapped encryption JID (LID) before encryption.

whatsmeow uses two identities simultaneously:
- **wireIdentity**: PN JID for `<to jid="...">` and prekey fetch
- **encryptionIdentity**: LID JID for Signal session address when mapping exists

Without this split, sessions can be created under one identity and encrypted under another,
causing devices to fail decrypt even though transport ACK is received.

### Fix Implemented

In `lib/ex_wapp/session.ex`:

- `process_prekey_response/4` now loads LID mapping and passes it into session creation.
- `create_sessions_for_bundles/6` now:
  - resolves `signal_jid` via mapping for each wire bundle,
  - creates session under `signal_jid`,
  - aliases wire/session JIDs in store to keep continuity,
  - stores bundle metadata for both wire and signal keys.
- `encrypt_for_targets/5` now:
  - always computes `signal_jid` from mapping,
  - migrates/aliases existing wire session -> signal session when needed,
  - encrypts using `signal_jid` while still emitting `<to jid="wire_jid">`.
- Added helper `ensure_signal_session_alias/3` for deterministic PN->LID session aliasing.

### Why This Matches Other Libraries

This follows whatsmeow's `encryptMessageForDeviceAndWrap(wireIdentity, encryptionIdentity, ...)`
pattern and its PN->LID session migration intent (`migrateSessionStore` behavior).

### Verification

- `mix compile` passes
- `mix test test/send_path_test.exs` passes (10 tests, 0 failures)
- `mix test test/send_path_test.exs test/whatsmeow_parity_test.exs test/signal_session_store_test.exs` passes (20 tests, 0 failures)

## Feb 12, 2026 — Messages Still Not Arriving: Double Session Creation + Wrong phash

### Symptom

After the prekey fetch LID fix above, messages still didn't arrive at the recipient.
Logs showed prekeys were now fetched using PN JIDs (correct), but encryption still failed
because `encrypt_for_targets` unconditionally remapped wire JIDs to LID via
`resolve_signal_encryption_jid`, creating a NEW session under the LID even though a
valid session already existed under the PN JID from prekey fetch.

### Root Cause 1: Double Session Creation in encrypt_for_targets

`encrypt_for_targets` always called `resolve_signal_encryption_jid(target_jid, lid_mapping)`
and used the resulting LID for encryption. Since no session existed under the LID (only under
the PN from prekey fetch), it created a brand new session from the bundle — wasting the
prekey-fetch session and producing ciphertext encrypted under the wrong session state.

**Fix**: Added session-aware JID resolution in `encrypt_for_targets`:
- If LID == wire JID (no mapping), use wire JID
- If session exists under LID (migrated), use LID
- If session exists under wire JID but NOT LID, use wire JID (preserves prekey-fetch session)
- If no session under either, use wire JID (so prekey fetch session will be found)

This matches whatsmeow's behavior where `migrateSessionStore` migrates sessions from PN→LID
before encryption. Without that migration step, we must use whichever JID the session was
created under.

### Root Cause 2: phash Computed from Wrong Device Set

`build_multi_device_encrypted_message_node` computed phash from `participant_nodes` — the
encrypted `<to>` nodes, which exclude the current device. But whatsmeow computes phash from
ALL usync-returned devices INCLUDING the current device (see `send.go:859`):
```go
phash := participantListHashV2(allDevices)  // allDevices includes current device
```

**Fix**: Added `all_usync_devices` list (before current-device filtering) through the send
pipeline: `discover_and_fetch_prekeys` → `target_hints` → `do_send_encrypted` →
`build_multi_device_encrypted_message_node`. phash is now computed from this full list.

### Verification

- `mix test` passes (80 tests, 0 failures)
