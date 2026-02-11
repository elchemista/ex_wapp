# ex_wapp Recovery Plan (Compressed)

## Current Runtime Status
- Still failing in real usage:
  - inbound messages remain `"(encrypted: pkmsg)"`,
  - recipient shows "waiting for message" for outbound,
  - stream eventually hits `401` (`device_removed`) and session is invalidated.
- Latest logs consistently show:
  - `decrypt_prekey_message` parses OK,
  - keys/prekeys are found,
  - inner Signal MAC verification fails (`:invalid_mac`),
  - many decrypt attempts run with `existing_session=false`,
  - post-login uploads a full initial prekey batch (`812`) again.

## What Has Already Been Done

### Signal / Message Path
- Added robust wire parsing for SignalMessage + PreKeySignalMessage.
- Added broader MAC verification strategies and decrypt diagnostics.
- Implemented version-aware unpadding and multi-candidate decrypt path (`enc` + sender candidates).
- Added session aliasing and worker/session synchronization improvements.

### Send Path
- First-message wrapping logic improved so `pkmsg` can be emitted when needed.
- Multi-device participant message structure implemented (`participants -> to -> enc`).
- Device identity injection logic for prekey sends improved.

### Pairing / ADV
- Pair-success ADV parsing hardened (direct + HMAC wrapper fallback).
- Relaxed decoding for proto drift in ADV details.
- Preserved Signal identity across pairing bootstrap to reduce identity drift.
- Added explicit ADV signed identity encoding helper.

### Chat / ACK / Notifications
- Better chat name fallback (`notify`, `pushname`, phone number fallback).
- Message status updates through `ack` and receipt.
- Notification ACK coverage expanded.

### Tests
- Many targeted tests added/updated and passing locally (including signal/parity/pairing suites).
- Important note: passing unit tests did not eliminate runtime interop failures.

## What External References Confirmed
- `libsignal-protocol-go`: receiver bootstrap and ratchet semantics are strict; session continuity is critical.
- `whatsapp-rust`: avoid replacing an existing valid session; session replacement can cause MAC failures.
- `Baileys`:
  - keeps PN<->LID mappings and uses them for decryption address resolution,
  - handles `privacy_token` and uses `tctoken` in outbound paths,
  - has peer-specific send/decrypt handling that differs from generic wrappers.

## Cross-Library Diff Inventory (Requested)

### 1) Prekey upload lifecycle after login
- Reference behavior:
  - Baileys validates prekeys on server (`count`) and uploads only if needed; also checks current prekey exists locally.
  - Evidence: `/tmp/Baileys/src/Socket/socket.ts` (`uploadPreKeysToServerIfRequired`, `getAvailablePreKeysOnServer`, `verifyCurrentPreKeyExists`).
- `ex_wapp` status:
  - Missing.
  - Current code uploads `initial: true` on every success path.
  - Evidence: `lib/ex_wapp/session.ex` (`handle_connection_node("success")`).
- Gap to close:
  - Use count-driven/top-up logic instead of unconditional initial upload.

### 2) Persist own LID + own PN<->LID mapping at login success
- Reference behavior:
  - Baileys persists `me.lid`, stores own mapping (`lid` <-> `pn`), and migrates session.
  - Evidence: `/tmp/Baileys/src/Socket/socket.ts` (`CB:success` handling).
- `ex_wapp` status:
  - Missing.
  - LID is logged but not persisted (`TODO`).
  - Evidence: `lib/ex_wapp/session.ex` (`LID from success`, `TODO: Store LID in session data`).
- Gap to close:
  - Persist `client_info.lid` + mapping and run local session migration hooks.

### 3) PN/LID decrypt address resolution + envelope mapping
- Reference behavior:
  - Baileys resolves decrypt JID via mapping (`getDecryptionJid`) and stores mapping from envelope attrs before decrypt (`storeMappingFromEnvelope`).
  - Evidence: `/tmp/Baileys/src/Utils/decode-wa-message.ts`.
- `ex_wapp` status:
  - Partial.
  - Candidate attrs are tried (`sender_lid/sender_pn/...`), but durable mapping/migration layer is missing.
  - Evidence: `lib/ex_wapp/message_handler.ex` (sender candidate extraction).
- Gap to close:
  - Add persistent PN<->LID mapping store + use it as primary decrypt target resolution.

### 4) Session re-establish guard to prevent MAC failures
- Reference behavior:
  - libsignal-go skips prekey session rebuild when state already exists for that prekey base key.
  - whatsapp-rust explicitly refuses risky re-establish paths when session checks fail (to avoid MAC failures).
  - Evidence: `/tmp/libsignal-protocol-go/session/Session.go` (`HasSessionState`), `/tmp/whatsapp-rust/src/client/sessions.rs`.
- `ex_wapp` status:
  - Missing/insufficient.
  - Runtime still frequently logs inbound prekey decrypt with `existing_session=false`.
- Gap to close:
  - Add strict dedupe/session-exists checks before creating/replacing sessions, keyed by normalized identity + base key.

### 5) `privacy_token` -> `tctoken` pipeline
- Reference behavior:
  - Baileys parses `privacy_token` notifications, stores trusted-contact token, and appends `<tctoken>` in outbound message.
  - Evidence:
    - `/tmp/Baileys/src/Socket/messages-recv.ts` (`handlePrivacyTokenNotification`)
    - `/tmp/Baileys/src/Socket/messages-send.ts` (append `tctoken`).
- `ex_wapp` status:
  - Missing.
  - Currently just logs unhandled notification and sends ack.
- Gap to close:
  - Parse/store trusted-contact token and include `tctoken` on 1:1 sends.

### 6) Prekey bundle JID normalization consistency
- Reference behavior:
  - whatsapp-rust normalizes JIDs for prekey-bundle lookup and session addressing to avoid key mismatch.
  - Evidence: `/tmp/whatsapp-rust/wacore/src/prekeys.rs`, `/tmp/whatsapp-rust/wacore/src/send.rs`.
- `ex_wapp` status:
  - Partial.
  - Device JID parsing/normalization exists, but end-to-end normalization consistency is still not guaranteed in all paths.
- Gap to close:
  - Normalize once at fetch-parse stage and use exact normalized key for create/encrypt/decrypt lookup.

### 7) Retry semantics for `invalid_mac` / missing session
- Reference behavior:
  - whatsapp-rust aggressively uses retry receipts to trigger fresh prekey/session recovery on invalid message/no-session states.
- `ex_wapp` status:
  - Partial.
  - Retry receipt machinery exists (`type=retry`, optional keys).
  - Evidence: `lib/ex_wapp/message_handler.ex`, `lib/ex_wapp/session.ex`.
- Gap to close:
  - Align retry triggers and key-inclusion policy with observed runtime failure patterns (especially repeated `invalid_mac` prekey flows).

### 8) Post-login key bundle validation
- Reference behavior:
  - Baileys runs digest/validation of key bundle after opening connection.
  - Evidence: `/tmp/Baileys/src/Socket/socket.ts` (`digestKeyBundle`).
- `ex_wapp` status:
  - Missing.
- Gap to close:
  - Add optional key-bundle digest/consistency check after login success.

### 9) Avoid dual PN/LID session conflicts
- Reference behavior:
  - whatsapp-rust avoids proactive PN primary-phone prekey establishment to prevent PN/LID dual-session conflicts.
  - Evidence: `/tmp/whatsapp-rust/src/client/sessions.rs` comments and checks.
- `ex_wapp` status:
  - Missing/unknown.
  - Current behavior may create/alias sessions without full PN/LID conflict policy.
- Gap to close:
  - Enforce a single authoritative addressing/session strategy per peer device.

### 10) Outbound peer metadata parity
- Reference behavior:
  - Baileys conditionally augments outbound 1:1 messages with privacy/reporting metadata nodes (`tctoken`, reporting token).
- `ex_wapp` status:
  - Partial.
  - Core encrypted node path exists, metadata parity not complete.
- Gap to close:
  - Implement missing metadata nodes required by modern WA peers where applicable.

## Confirmed Remaining Gaps (Need to Fix)

### P0 (Blocking)
- Prekey upload policy is wrong in runtime:
  - currently uploads "initial" prekeys on every login success;
  - must validate/query server count and upload only when required.
- Device identity/address continuity is incomplete:
  - Signal bootstrap can still fall back to `device_id=0`;
  - must derive/persist real device id from JID/device attrs.
- PN/LID mapping is not persisted/used end-to-end:
  - decryption candidates are not backed by durable mapping logic;
  - must store envelope/history mappings and resolve target JIDs via mapping.
- Privacy token flow is missing:
  - `privacy_token` is currently only acked/logged;
  - must parse/store token and include `tctoken` where required on send.
- Session continuity around incoming prekey messages is still unstable:
  - runtime often decrypts as `existing_session=false`;
  - must avoid unnecessary session recreation/replacement and enforce stable key lookup identity.

### P1 (High Value)
- Persist own LID from success and create self PN<->LID mapping early.
- Re-check peer message node shape parity for single-recipient peer sends.
- Add integration-style regression tests from captured runtime traces (not only unit-level tests).

## Execution Plan (Next Concrete Steps)

1. Fix login-success prekey behavior
   - Replace unconditional `initial: true` upload with count-driven logic.
   - Persist upload metadata and only top-up when below threshold.

2. Fix device-id derivation/persistence
   - Update `Signal.ensure_device_id/2` to derive from JID/device attrs first.
   - Never silently default to `0` when real device id is known.

3. Add PN<->LID mapping store + resolver
   - Persist mappings from envelope attrs/history sync.
   - Use resolver for decrypt candidate expansion and outbound target normalization.

4. Implement privacy token/tctoken flow
   - Parse `privacy_token` notification payload.
   - Store token and attach `tctoken` where protocol requires.

5. Harden session continuity rules
   - If a valid session exists for resolved device, do not recreate/replace it.
   - Ensure prekey decrypt and whisper decrypt read/write the same normalized session key.

6. Validate with runtime scenario (not only tests)
   - Fresh pair -> receive plaintext inbound -> send outbound not stuck at waiting -> no `401 device_removed`.

## Verification Checklist
- Inbound decrypt:
  - no repeated `:invalid_mac` for normal 1:1 messages,
  - `text` contains plaintext, not `(encrypted: pkmsg)`.
- Outbound:
  - recipient receives and decrypts immediately (no waiting banner).
- Stability:
  - no forced `401 device_removed` during normal run.
- Logs:
  - no full initial prekey upload on every reconnect.

## Session Reset Note
- After any `401 device_removed`, old local session data is invalid.
- Required for valid verification run:
  - delete session file,
  - pair again from QR,
  - re-test with the fixed runtime.
