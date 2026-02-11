# ex_wapp Signal + Pairing Interop Spec

## Scope
This spec covers:
- pairing and ADV handling,
- Signal session creation/decryption/encryption for 1:1 chats,
- outbound message node structure,
- inbound decrypt routing,
- notification/ack behavior relevant to history and sync,
- troubleshooting and validation workflow.

It does not cover:
- full group sender-key flow,
- media encryption,
- app-state patch cryptography internals.

## High-Level Architecture
1. Noise handshake authenticates transport session with WhatsApp Web.
2. Signal identity + prekeys bootstrap E2EE session state.
3. Outbound first message to a device is `pkmsg` (PreKeySignalMessage), then `msg` (SignalMessage).
4. WhatsApp routes encrypted payloads server-side; encryption is end-to-end between devices.

## Incident Symptoms
- Incoming messages persisted as `text: "(encrypted: pkmsg)"`.
- Decryption repeatedly failed with `:invalid_mac` for inbound `pkmsg`.
- Outbound messages appeared sent locally but recipient showed "waiting for message".
- Session later received stream errors (`401`, device removed).

Representative decrypt failure pattern:
- parsed prekey message OK,
- prekey lookup OK,
- X3DH DH outputs computed,
- MAC verification failed in inner SignalMessage.

## Protocol Invariants (Must Hold)

### 1) Identity Consistency Across Flows
The same Signal identity key pair must be used across:
- registration payload (`devicePairingData.eIdent`),
- QR/pairing state,
- Signal bootstrap used for prekey upload and session decrypt/encrypt.

If identity drifts, prekey sessions are created with wrong key material and MAC verification fails.

### 2) First Message Wrapping
When no established session exists for target device:
- create session from prekey bundle,
- wrap first encrypted payload as `pkmsg`.

Follow-up messages on established session must be `msg`.

### 3) Signal Wire Format
SignalMessage:
- `version || protobuf || mac(8 bytes)`,
- ciphertext is AES-256-CBC + PKCS7,
- MAC uses identity keys and derived `mac_key`.

PreKeySignalMessage:
- `version || protobuf` containing registration id, signed prekey id, optional prekey id, base key, identity key, inner SignalMessage.

### 4) Outgoing Message Node Shape (MD)
Use participant-based encrypted payloads:
- outer `<message to="base_jid"...>`
- `<participants><to jid="device_jid"><enc type="pkmsg|msg" v="2">...</enc></to></participants>`
- include `<device-identity>` when any participant payload is `pkmsg`.

### 5) Device Identity Payload Semantics
Two different encodings are required:
- Pair-success ACK (`pair-device-sign/device-identity`) expects self-signed encoding without `accountSignatureKey`.
- Outgoing prekey sends (`message/device-identity`) should use encoded signed identity compatible with MD clients (include signature key when present).

### 6) Inbound Decrypt Candidate Strategy
Inbound messages may include multiple `enc` candidates and mixed identity hints:
- consider `from`, `participant`, `sender_lid`, `sender_pn`, `participant_lid`, `participant_pn`,
- normalize PN/LID JIDs,
- try decrypt across sender candidates and payload candidates until one succeeds.

### 7) Notification ACK Contract
Notifications must be ACKed with class `notification`:
- `<ack class="notification" ... type="..."/>`

Missing ACKs can stall server sync/history delivery.

## Root Causes Identified
1. First outbound session path could emit `msg` instead of `pkmsg`.
2. Signal decrypt path was partially mismatched with WhatsApp wire behavior.
3. Prekeys were generated/uploaded but local persistence and session continuity paths were incomplete.
4. Chat metadata/status updates were incomplete (name fallback, ack-to-message status linkage).
5. Pairing ADV parsing was brittle to protobuf drift.
6. Signal identity could drift between registration/pairing/signal bootstrap.
7. Outgoing `device-identity` payload could use raw blob fallback incompatible for some recipients.
8. Receiver-side prekey bootstrap initialized the wrong chain direction (receiving vs sending), causing deterministic inner `SignalMessage` MAC failure.

## Implemented Fixes (Canonical Behavior)

### A) Signal Session and Wire Handling
- Parse PreKeySignalMessage and SignalMessage via wire-format parser.
- Use AES-CBC + Signal MAC verification on decrypt.
- Preserve message key derivation and chain advancement semantics.
- Add compatibility fallback attempts for prekey shared-secret composition when initial inner MAC fails.
- Align receiver-side prekey bootstrap with libsignal:
  - initialize `sending_chain` from X3DH chain key,
  - keep `receiving_chain` empty until first inner SignalMessage ratchet step.

Files:
- `lib/ex_wapp/signal/wire_format.ex`
- `lib/ex_wapp/signal/session.ex`
- `lib/ex_wapp/signal/session_store.ex`
- `lib/ex_wapp/signal/encryption.ex`

### B) First-Message / Multi-Device Send Path
- Ensure first message remains `pkmsg` even when session was pre-created in worker flow.
- Build participant-targeted encryption nodes for all resolved devices.
- Attach `device-identity` when sending prekey payloads.

Files:
- `lib/ex_wapp/session.ex`
- `lib/ex_wapp/signal/session_store.ex`

### C) Pairing + ADV Robustness
- Parse `device-identity` as direct signed ADV first, then HMAC wrapper fallback.
- Relax `ADVDeviceIdentity` decode to survive unknown future fields; extract key index best-effort.
- Add explicit encoder for signed ADV identity with optional `accountSignatureKey`.
- Preserve existing `signal.identity_key` during pair-success bootstrap; only fallback to pairing identity when missing.

Files:
- `lib/ex_wapp/pairing.ex`
- `lib/ex_wapp/pairing/adv.ex`

### D) Inbound Message Handling / Chat UX
- Try multiple sender and payload candidates for decrypt.
- Support version-aware unpadding behavior.
- Improve chat naming from `notify/pushname` and phone-number fallback.
- Improve outgoing status transitions via ack/receipt + id fallback updates.

Files:
- `lib/ex_wapp/message_handler.ex`
- `lib/ex_wapp/chat.ex`

### E) Sync and Notification Flow
- ACK notification types consistently.
- Handle device/server/account sync notification paths with visibility logs.

Files:
- `lib/ex_wapp/message_handler.ex`

## Reference Behavior Alignment
The implementation intent was aligned to:
- Baileys (JS) behavior for pairing validation and device identity encoding,
- whatsapp-rust/wacore(libsignal) behavior for session/prekey pipeline and ratchet semantics,
- whatsmeow-style interop expectations for WhatsApp MD node structures.

## Operational Runbook

### When You See `invalid_mac` on Every Inbound `pkmsg`
1. Verify Signal identity continuity in logs during pairing and login.
2. Verify prekey ids referenced by inbound message exist locally.
3. Verify sender candidate JIDs include PN/LID variants.
4. Confirm message is parsed as proper `pkmsg` and not malformed payload candidate.
5. If session had previous `401/device_removed`, force fresh re-pair (see below).

### When Recipient Shows "Waiting for Message"
1. Confirm first outbound payload type is `pkmsg`.
2. Confirm `<participants><to jid=...><enc .../></to></participants>` is used.
3. Confirm `<device-identity>` is included for prekey sends.
4. Confirm `device-identity` payload comes from encoded signed ADV identity, not stale raw blob.

### On `401` / `device_removed`
Treat current store as invalid:
1. stop session,
2. delete session store file,
3. pair again from QR,
4. rerun send/decrypt checks.

## Test Coverage Added/Used
- `test/signal_session_store_test.exs`
- `test/whatsmeow_parity_test.exs`
- `test/signal_encryption_padding_test.exs`
- `test/pairing_adv_test.exs`
- `test/pairing_test.exs`

Current expected baseline:
- `mix test` passes (`62 tests, 0 failures`) after this patch set.

## Debug Log Checklist (Minimum)
For incident triage, ensure logs include:
- pairing identity source chosen,
- parsed prekey bundle ids and resolved device jid,
- outbound targets list and payload types,
- inbound sender candidates + payload candidate count,
- decrypt result per candidate,
- MAC verification result and session existence state,
- notification ACK emission.

## Known Risks / Future Work
- Group sender-key path is not fully covered in this incident spec.
- Some ADV/account signature verification paths remain intentionally permissive for interop; tighten once broader fixtures are available.
- Existing project warnings unrelated to this incident remain and should be cleaned separately.
