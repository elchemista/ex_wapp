# Changelog

## 0.1.4 — 2026-10-18

### Changed

- Update the default WhatsApp Web version to `2.3000.1050728964`, verified
  against whatsmeow `b2b1e71` on 2026-10-18.
- Regenerate the protobuf snapshot, including audio stickers, location requests,
  shared-device contact keys, history restrictions, community settings and new
  device capabilities. Internal wallpaper colors now follow upstream's
  `fixed32` ARGB representation; new wire fixtures verify the changed types.
- Allow `UPSTREAM_REF=<commit>` in the proto updater for reproducible snapshots,
  preserve local upstream edits and include all proto wire suites in its checks.

### Fixed

- Honor `state="false"` on incoming prekey messages without replacing or
  advancing existing Signal sessions, pending aliases or persisted sessions.
  Consume one-time prekeys only after successful decryption; keep established
  sessions intact when a stateless message fails authentication.
- Prevent receipt, notification and call ACKs from changing the status of a
  message with the same ID. Only message-class ACKs carry a delivery verdict.

### Validation

- 1,101 passing tests and 90.03% maintained-code coverage on Elixir 1.20.4 /
  OTP 29.1.1. Validation uses local protocol peers, without a live WhatsApp account.
- Add authenticated stateless-prekey tests for map and ETS stores, ACK ID
  collision tests and independent protoc wire fixtures for the October schema.
- Verify existing handling of split encrypted frames, malformed stanza tags
  and group `participant_pn` aliases without an addressing-mode hint.

[Full changes](https://github.com/elchemista/ex_wapp/compare/v0.1.3...v0.1.4)

## 0.1.3 — 2026-09-10

### Changed

- Update the default WhatsApp Web version to `2.3000.1047068806`, verified
  against whatsmeow `9ec8f76` on 2026-09-09.
- Refresh the generated protobuf modules with additive upstream schema changes
  for ACP2, newsletters, video, AI, business and device capabilities. These
  changes extend wire compatibility; they do not introduce new public APIs.
- Enforce 90% coverage for maintained code, with the existing exclusion for
  generated protobuf modules unchanged.

### Fixed

- Start the diagnostic WebSocket transport with a valid WebSockex connection
  callback and close its socket when disconnecting.
- Use the configured client version consistently in the diagnostic Noise payload.
- Parse decoded binary prekey bundles and preserve device IDs in peer JIDs.
- Replace existing message IDs correctly in custom store adapters and migrate
  legacy message lists without resurrecting deleted messages.
- Return an error from `ExWapp.Binary.encode/1` for invalid node shapes.
- Report invalid media retry keys explicitly and complete session cleanup when
  a store flush raises, throws or exits.

### Validation

- 1,081 passing tests, including authenticated Noise and Signal exchanges, local
  HTTP/HTTPS and WebSocket servers, persistence recovery and failure injection.
- 90% maintained-code coverage. Protocol tests run without a WhatsApp account;
  live interoperability remains dependent on WhatsApp's private protocol.

[Full changes](https://github.com/elchemista/ex_wapp/compare/v0.1.2...v0.1.3)
