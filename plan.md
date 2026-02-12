# ExWapp Code Quality Improvement Plan

## Context

Post-refactor review (Feb 12, 2026). The session monolith was split into
`session/worker.ex`, `session/outbound.ex`, and 10+ submodules. Tests pass
(80/0). This plan addresses gaps found against `Code Guidelines.md` and
`Refactor Agent.md`.

---

## Phase 1: @spec + @type coverage (8 modules, ~43 public functions)

### 1.1 jid_utils.ex — 12 public functions
- Add `@spec` to all 12 public functions
- Alias `ExWapp.JID` (used fully qualified 3x)

### 1.2 account.ex — 11 public functions
- Add `@spec` to all 11 public functions
- Fix 6x bare `rescue _ ->` (log the error, don't swallow)
- Alias `ExWapp.Pairing.ADV`

### 1.3 targets.ex — 5 public functions
- Add `@spec` to all 5 public functions
- Fix double negation: `Enum.reject(... not ...)` -> `Enum.filter`

### 1.4 message_node.ex — 5 public functions
- Add `@spec` to all 5 public functions

### 1.5 subscribers.ex — 5 public functions
- Add `@spec` to all 5 public functions
- Remove unused `@type telemetry_fun` or use it in a spec

### 1.6 iq.ex — 4 public functions
- Add `@spec` to all 4 public functions
- Alias `ExWapp.JID`

### 1.7 retry.ex — 1 public function
- Add `@spec` to `maybe_retry_outgoing_message/4`
- Alias `ExWapp.Chat`

### 1.8 outbound.ex — 1 public function
- Add `@spec` to `send_text_worker/4`
- Add missing aliases: `Signal.Encryption`, `Signal.SessionStore`,
  `Signal.SenderKey`, `Messages`, `Chat`, `Proto.Message`

### 1.9 inbound.ex
- Replace `@moduledoc false` with descriptive doc (consistency with siblings)
- Extract named `@type` from the verbose 18-line inline spec

---

## Phase 2: Anti-pattern fixes

### 2.1 One-branch cond -> if/else
- outbound.ex ~L1022: `cond` with 2 branches -> `if/else`
- retry.ex ~L23: two-branch `cond` -> `if/else`

### 2.2 Dead logic
- worker.ex ~L1017: `code == "401" or (code == "401" and ...)` — second
  disjunct is subsumed. Simplify or split into separate branches.

### 2.3 Double negation
- targets.ex ~L18: `Enum.reject(... not ...)` -> `Enum.filter(...)`

### 2.4 O(n^2) list append
- jid_utils.ex ~L141: `acc ++ [spec]` -> `[spec | acc]` + reverse

### 2.5 Silent rescues
- account.ex: 6x `rescue _ ->` that swallow errors. Add `Logger.warning`.
- outbound.ex ~L1309: `persist_signal_sessions` rescue -> add logging.

---

## Phase 3: Large function splits

### 3.1 outbound.ex — do_send_encrypted/7 (161 lines)
Split into:
- `build_send_payloads/4` — proto encoding + DSM wrapping
- `resolve_and_encrypt_targets/5` — target resolution + encryption
- `assemble_and_send_message/7` — node building + transport send

### 3.2 outbound.ex — ensure_signal_session_worker/3 (120 lines)
Split into:
- `discover_devices/3` — usync query + response parsing
- `fetch_missing_prekeys/4` — prekey fetch + retry for missing bundles

### 3.3 outbound.ex — encrypt_for_targets/5 (105 lines)
Extract reduce callback body into `encrypt_single_target/6`

### 3.4 worker.ex — handle_connection_node/2 for "iq" (93 lines)
Split into:
- `forward_iq_to_workers/3`
- `resolve_pending_iq/3`
- `handle_iq_by_xmlns/3`

### 3.5 iq.ex — parse_usync_device_response/1 (72 lines)
Extract inner reduce into `parse_user_device_list/2`

### 3.6 retry.ex — maybe_retry_outgoing_message/4 (68 lines)
Extract nested case chain into `build_and_send_retry/4`

### 3.7 worker.ex — build_retry_receipt_ack/8 (60 lines, 8 params)
Accept a map/struct instead of 8 positional params.

---

## Phase 4: Cleanup

### 4.1 Remove ~25 trivial delegation wrappers in outbound.ex
Replace with direct module calls or `import` where appropriate.

### 4.2 Remove unused _timestamp parameter
outbound.ex `build_multi_device_encrypted_message_node` — remove `_timestamp`.

### 4.3 Logger level audit
Downgrade routine `Logger.info` calls to `Logger.debug` in outbound.ex (~30 calls).

### 4.4 Code duplication in account.ex
Merge `get_device_identity_node/1` and `get_device_identity_node_fallback/1`
(nearly identical branch logic).

---

## Acceptance Criteria

- `mix test` passes (80 tests, 0 failures)
- `mix format --check-formatted` passes
- Every public function in session/* has `@spec`
- No function body exceeds ~50 lines
- No bare `rescue _ ->` without logging
- No one-branch `cond`
- No `Enum.reject(... not ...)`
- No `acc ++ [item]` in loops
