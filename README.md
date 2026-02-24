# ExWapp

Experimental WhatsApp Web client in pure Elixir.

## Status

Working flows (debug-focused):
- QR pairing
- connect / reconnect / disconnect
- inbound message/notification handling with ACK + receipts
- multi-device send pipeline aligned with `SPEC.md` core rules
- wire identity (PN JID) separated from encryption identity (LID-mapped Signal JID)
- USync device discovery for recipient + own identity
- prekey fetch via `xmlns="encrypt"` and per-device session reuse checks
- DeviceSentMessage payload for own devices
- `phash` from all USync devices (raw base64, no padding)
- `device-identity` included when any target uses `pkmsg`

Still unstable and protocol-sensitive:
- full message delivery reliability across protocol changes
- complete parity for all retry and cache-invalidation edge cases

## Runtime Hardening Config

ExWapp now supports runtime hardening controls (with safe defaults) through:

- `config :ex_wapp, :runtime, ...` (application-wide)
- per-session override via `start_link(runtime: [...])` / `start_session(..., runtime: [...])`

Implemented configurable areas include:

- reconnect/backoff + max attempts
- IQ timeout + max pending IQ requests
- outbound queue size/drop policy
- send retry/confirmation limits
- send error guard (pause/disconnect/stop session)
- throttle and daily quota guards
- safety breaker for repeated `401` / `403` / `stream_replaced`
- trust/parity control surface per session:
  - strict compliance mode
  - adaptive governor
  - account risk breaker
  - canary checks
  - release gates/kill switch
  - auth churn guard
  - protocol-health thresholds
  - hygiene/enforcement settings

Inspect active policy/config from a running session:

```elixir
cfg = ExWapp.runtime_config(session)
status = ExWapp.policy_status(session)
health = ExWapp.health_status(session)
```

Example:

```elixir
config :ex_wapp, :runtime,
  reconnect: [enabled: true, max_attempts: 10, max_backoff_ms: 120_000],
  iq: [default_timeout_ms: 20_000, max_pending_requests: 500],
  queue: [max_size: 5_000, drop_policy: :reject_new],
  throttle: [enabled: true, global: [messages_per_second: 5, burst: 10]],
  send_error_guard: [
    enabled: true,
    max_consecutive_errors: 3,
    action: :stop_session
  ],
  quota: [enabled: true, per_session: [daily_messages: 2_000]],
  compliance: [strict_mode: true, require_explicit_opt_in: true],
  risk: [enabled: true, block_threshold: 75],
  protocol: [
    user_agent: [
      os_version: "Linux x86_64",
      manufacturer: "Mozilla",
      device_name: "Firefox"
    ]
  ]
```

Detailed implementation checklist: `SESSION_TRUST_PARITY_CHECKLIST.md`.

Health monitoring/control via PubSub:

- per-session topic: `ex_wapp:health:<session_id>`
- global topic: `ex_wapp:health`
- commands topic supports `{:ex_wapp_control, :pause_sends | :resume_sends | :disconnect | :stop_session}`

Programmatic control:

```elixir
ExWapp.control_session("acc_1", :pause_sends)
ExWapp.control_session("acc_1", :resume_sends)
ExWapp.control_session("acc_1", :stop_session)
```

## Quickstart

```bash
mix deps.get
iex -S mix
```

```elixir
{:ok, result} = ExWapp.Live.run()
session = result.session

# Send a text
ExWapp.send_message(session, "1234567890@s.whatsapp.net", "hello")

# Receive messages
ExWapp.message_stream(session)
|> Stream.each(&IO.inspect/1)
|> Stream.run()
```

## Live Pairing + Group Listing (Real Number)

Run this from a live VM (`iex -S mix`) to pair with your phone, save QR updates,
and print known chats/groups from the local synced chat store:

```elixir
{:ok, result} =
  ExWapp.Live.run(
    session_id: "acc_1",
    store_path: "tmp/ex_wapp/live_test_session.etf",
    qr_path: "tmp/whatsapp_qr.svg",
    pair_timeout_ms: 300_000,
    connect_timeout_ms: 30_000,
    sync_wait_ms: 15_000
  )

result.chats
result.groups
```

`result.chats` and `result.groups` are a snapshot taken when `run/1` returns.
For live updates, subscribe via `ExWapp.subscribe(session)` and call
`ExWapp.Live.list_chats(session)` again when messages arrive.

If a stored session was invalidated server-side, `run/1` now returns:

```elixir
{:error, :session_invalid_or_logged_out}
```

In that case, delete the store file and pair again.

Use the same session for day-to-day operations:

```elixir
session = result.session

ExWapp.Live.list_chats(session)
ExWapp.Live.list_groups(result.session)

# Send to user
ExWapp.Live.send_message(session, "393XXXXXXXXX@s.whatsapp.net", "hello from ex_wapp")

# Send to group
ExWapp.Live.send_message(session, "1234567890-123456789@g.us", "hello group")

# Read stored chat messages
# (local projection only; full historical blob backfill is not implemented yet)
ExWapp.Live.get_messages(session, "393XXXXXXXXX@s.whatsapp.net", limit: 20)

# Subscribe to messages + lifecycle events via PubSub
ExWapp.subscribe(session)
# Messages: {:ex_wapp_message, jid, message}
# Lifecycle: {:ex_wapp_session, :connected}, {:ex_wapp_session, :disconnected, reason}, etc.

# Send via session_id string (fire-and-forget, no pid needed)
ExWapp.send_message("my_session", "393XXXXXXXXX@s.whatsapp.net", "hello via pubsub")

# Show typing indicator before sending
ExWapp.send_typing(session, "393XXXXXXXXX@s.whatsapp.net")
Process.sleep(2_000)
ExWapp.send_message(session, "393XXXXXXXXX@s.whatsapp.net", "hello!")

# Send read receipts for received messages
ExWapp.send_read_receipt(session, "393XXXXXXXXX@s.whatsapp.net", ["MSG_ID"])

# Or use the lazy stream API
ExWapp.message_stream(session)
|> Stream.each(fn {jid, msg} -> IO.puts("[#{jid}] #{msg.text}") end)
|> Stream.run()

# Refresh chat projection after new events
ExWapp.Live.list_chats(session)
```

## Multiple Sessions (No Conflict)

Use `run_session/2` so each session is isolated by `session_id` and store path.
This avoids `stream_replaced` caused by two processes sharing one store file.

```elixir
{:ok, s1} = ExWapp.Live.run_session("acc_1")
{:ok, s2} = ExWapp.Live.run_session("acc_2")

# optional explicit paths
{:ok, _s3} =
  ExWapp.Live.run_session("acc_3",
    store_path: "tmp/ex_wapp/sessions/acc_3.etf",
    qr_path: "tmp/ex_wapp/qr/acc_3.svg"
  )

ExWapp.Live.list_sessions()
ExWapp.Live.stop_session("acc_2")
```

## Minimal API

```elixir
{:ok, session} = ExWapp.start_link(store: {ExWapp.Store.Ets, path: "/tmp/ex_wapp/bot_session.etf"})
:ok = ExWapp.connect(session)

ExWapp.qr_stream(session)
|> Enum.each(&IO.inspect/1)

ExWapp.send_message(session, "1234567890@s.whatsapp.net", "Hello")

ExWapp.list_groups(session)

:ok = ExWapp.disconnect(session)
```

## Typing Indicators & Read Receipts

```elixir
# Show "typing..." to the recipient
ExWapp.send_typing(session, "393XXXXXXXXX@s.whatsapp.net")

# Stop typing indicator (without sending a message)
ExWapp.send_typing(session, "393XXXXXXXXX@s.whatsapp.net", false)

# Send read receipt for specific messages
ExWapp.send_read_receipt(session, "393XXXXXXXXX@s.whatsapp.net", ["MSG_ID_1", "MSG_ID_2"])
```

Notes:

- `send_typing/3` sends a `chatstate` node (`composing` or `paused`) to the
  recipient. The typing indicator auto-clears when a message is sent, so you
  don't need to explicitly send `paused` before sending.
- `send_read_receipt/3` sends blue ticks for the given message IDs (separate
  from the server-synced `mark_chat_as_read/2` which updates the chat's unread
  counter across linked devices).

## Session Introspection

```elixir
# Current session status (:idle, :connecting, :handshaking, :connected, :disconnected)
ExWapp.state(session)

# Session statistics (uptime, message counts, reconnects, errors)
ExWapp.stats(session)
```

## Chat & Contacts API (App State Sync)

ExWapp exposes server-synced chat/contact operations through App State patches.
When connected, changes propagate to linked devices.

```elixir
# Chat actions
:ok = ExWapp.archive_chat(session, "393XXXXXXXXX@s.whatsapp.net")
:ok = ExWapp.unarchive_chat(session, "393XXXXXXXXX@s.whatsapp.net")
:ok = ExWapp.delete_chat(session, "393XXXXXXXXX@s.whatsapp.net")

:ok = ExWapp.pin_chat(session, "393XXXXXXXXX@s.whatsapp.net")
:ok = ExWapp.unpin_chat(session, "393XXXXXXXXX@s.whatsapp.net")

# mute forever (-1), or pass an absolute unix ms timestamp
:ok = ExWapp.mute_chat(session, "393XXXXXXXXX@s.whatsapp.net", -1)
:ok = ExWapp.unmute_chat(session, "393XXXXXXXXX@s.whatsapp.net")

:ok = ExWapp.mark_chat_as_read(session, "393XXXXXXXXX@s.whatsapp.net")

# Get local metadata projection for a chat
{:ok, chat} = ExWapp.get_chat_info(session, "393XXXXXXXXX@s.whatsapp.net")
```

```elixir
# Contact actions
# server-synced contact upsert (there is no sync_contact/* API)
:ok = ExWapp.create_contact(session, "393XXXXXXXXX@s.whatsapp.net", "Alice Example")
:ok = ExWapp.delete_contact(session, "393XXXXXXXXX@s.whatsapp.net")

:ok = ExWapp.sync_contacts(session)
contacts = ExWapp.list_contacts(session)
contact = ExWapp.get_contact(session, "393XXXXXXXXX@s.whatsapp.net")
```

Notes:

- `archive_chat/2`, `unarchive_chat/2`, `delete_chat/2`, `pin_chat/2`,
  `unpin_chat/2`, and `mark_chat_as_read/2` use local fallback behavior when
  the session is not connected.
- contact APIs (`create_contact/3`, `delete_contact/2`, `list_contacts/1`,
  `get_contact/2`) are available directly from `ExWapp`.
- `sync_contacts/1` explicitly fetches and applies contact app-state collection
  (`critical_unblock_low`) when connected.
- `list_contacts/1` is a local projection: entries are populated by app-state
  contact sync and can be augmented by history-sync DM names, so it may be
  temporarily empty just after connect.
- `list_contacts/1` may include WhatsApp system/service contacts (for example
  `0@s.whatsapp.net` with push name `WhatsApp`, or `13135550002@s.whatsapp.net`
  with push name `Meta AI`) depending on account/region and synced state.
- `get_messages/3` returns only locally ingested/stored messages (live traffic
  plus any inline history-sync conversation messages that were parsed) and does
  not fetch missing history blobs on demand.

## Signal Implementation

Only the pure Elixir Signal path is active.

```elixir
ExWapp.Signal.Adapter.info()
ExWapp.Signal.Adapter.set_impl(:elixir)
```

## Protobuf Strategy (Generated + Custom)

This project intentionally uses a hybrid protobuf approach.

Generated `Protox` modules (default path):

- Dependency: `{:protox, "~> 1.7"}` in `mix.exs`
- Generated modules live in `lib/ex_wapp/wa_proto/*`
- Used for stable WhatsApp schemas such as:
- `WAWebProtobufsWa6.HandshakeMessage` in `lib/ex_wapp/noise.ex` (Noise handshake/client-server envelopes)
- `WAAdv.*` structs in `lib/ex_wapp/pairing/adv.ex` for normal ADV decode/encode paths

Custom minimal protobuf handling (intentional):

- `lib/ex_wapp/signal/wire_format.ex`: manual SignalMessage/PreKeySignalMessage protobuf encode/decode for strict wire-level control and parity work
- `lib/ex_wapp/signal/sender_key.ex`: minimal protobuf helpers for SenderKey distribution/message parsing in group encryption flows
- `lib/ex_wapp/proto/history_sync.ex`: minimal parser for protocol history sync payloads used to populate local chat/group metadata
- `lib/ex_wapp/proto/message.ex`: minimal outbound E2E message protobuf encoder for the subset currently needed by send flows
- `lib/ex_wapp/pairing/adv.ex`: fallback parser that extracts stable fields (for example `keyIndex`) when full generated decode fails due to schema drift/new fields
- `lib/ex_wapp/message_handler.ex`: lightweight wire scanning to classify decrypted content and extract text/protocol markers without full schema decode

Why not only generated protobuf everywhere:

- WhatsApp can add/shift fields quickly; minimal parsers keep critical paths resilient by decoding only stable fields and ignoring unknowns
- Signal payloads are byte-sensitive; manual encoding/decoding gives deterministic control where wire compatibility is critical
- Some hot paths only need a small subset of fields, so targeted parsers reduce coupling to large evolving protobuf schemas

## SPEC Conformance Snapshot

Validated against `SPEC.md` in the current codebase:

- Wire vs encryption identity split is implemented in send path (`Session.Outbound`)
- USync uses `xmlns="usync"` with `context="message"` and includes recipient + own identity
- Prekey fetch uses `xmlns="encrypt"` and PN/wire JIDs in `<user jid="...">`
- Session checks reuse existing sessions before prekey fetch (PN and LID-aware)
- Own-device payload uses `DeviceSentMessage` wrapper; recipient payload uses plain message proto
- Current device is excluded from encryption targets and included in `phash` input set
- `phash` is computed from sorted participant list and encoded with base64 no padding
- `device-identity` is attached when any encrypted participant node is `pkmsg`
- Notification ACK uses `<ack class="notification" ...>`
- Sender resolution for decrypt attempts includes `sender_lid` / `participant_lid` + stored PN<->LID mappings

Known gaps vs full spec ambitions:

- explicit phash-mismatch driven device-cache invalidation is not fully wired yet
- retry policy limits/cooldowns are not fully aligned to the strict limits documented in `SPEC.md`

## How It Works

ExWapp is an OTP-based pipeline with clear process boundaries:

- `ExWapp.Session.Supervisor`: dynamic parent for many sessions.
- `ExWapp.Session`: public API facade.
- `ExWapp.Session.Worker`: per-session GenServer state machine/lifecycle coordinator.
- `ExWapp.Session.Outbound`: send orchestration (USync, prekeys, fanout encryption, DM/group node assembly).
- `ExWapp.Session.Inbound`: inbound action conversion from `MessageHandler` outputs.
- `ExWapp.Conn`: websocket transport process implementing `ExWapp.Transport`.
- `ExWapp.Session.OutboundQueue`: buffers outbound nodes and flushes when connected.
- `ExWapp.Session.InboundRouter`: routes inbound nodes to session handling logic.
- `ExWapp.Noise`: handshake + transport encryption keys.
- `ExWapp.Pairing`: QR pairing state and pair-success handling.
- `ExWapp.Signal.*`: message/session crypto for send pipeline.
- `ExWapp.Chat`: local chat/message projections persisted in store.

## Session Lifecycle

Main status transitions:

- `:idle` -> `:connecting` -> `:handshaking` -> `:connected`
- `:connected` -> `:disconnected` on socket/transport failure
- `:disconnected` -> reconnect with exponential backoff
- `:disconnect` API call -> `:idle` (reconnect disabled for that disconnect)

Important runtime rules:

- reconnect is automatic by default
- pending IQ waits are cleared on disconnect
- outbound queue detaches/reattaches on transport changes
- on stream conflict `type=replaced`, session now closes current connection and reconnects immediately

## Pairing Flow

High-level flow when unpaired:

1. `ExWapp.connect(session)` starts websocket + Noise handshake.
2. server sends `pair-device` refs.
3. ExWapp emits QR event `{:code, qr_payload}` (first active ref only).
4. phone scans QR.
5. server sends `pair-success`.
6. ExWapp persists pairing/signal state and emits `:success`.

QR stream contract:

- `{:code, payload}` new QR payload to render
- `:success` pairing completed
- `{:error, reason}` pairing failed/interrupted

## Message Flow

Outgoing text (`ExWapp.send_message/3`):

1. build primary payload and own-device DSM payload
2. USync query for recipient + own devices
3. resolve wire JIDs vs encryption JIDs (PN/LID mapping)
4. reuse sessions where present; fetch prekeys for missing devices
5. encrypt per target (`pkmsg` for new session, `msg` for existing), include DSM only for own devices
6. build participant fanout + `phash` + optional `device-identity`
7. send through transport and persist message projection/status

Incoming nodes:

1. transport receives encrypted frame
2. session gets decoded node via inbound router
3. message handler processes decrypt/receipt/notification logic
4. PubSub broadcasts `{:ex_wapp_message, jid, message}` to subscribed processes

## PubSub Topics & Messages

ExWapp uses Phoenix PubSub for all event broadcasting. A single `subscribe/1`
call gives you both incoming messages and session lifecycle events. No need to
hold onto the session pid — use the session_id string anywhere.

### Getting the Session ID

```elixir
session_id = ExWapp.get_session_id(session)
```

### Subscribe / Unsubscribe

```elixir
# Per-session (accepts pid or session_id string)
ExWapp.subscribe(session)
ExWapp.subscribe("my_session")
ExWapp.unsubscribe(session)

# All sessions (global)
ExWapp.subscribe_all()
ExWapp.unsubscribe_all()
```

One `subscribe/1` call subscribes to **both** topics below:

### Per-Session Topics

| Topic | Message format |
|---|---|
| `"ex_wapp:messages:<id>"` | `{:ex_wapp_message, jid, message}` |
| `"ex_wapp:session:<id>"` | `{:ex_wapp_session, :connected}` |
| | `{:ex_wapp_session, :disconnected, reason}` |
| | `{:ex_wapp_session, :terminated, reason}` |

### Global Topics (via `subscribe_all/0`)

| Topic | Message format |
|---|---|
| `"ex_wapp:messages"` | `{:ex_wapp_message, session_id, jid, message}` |
| `"ex_wapp:session"` | `{session_id, {:ex_wapp_session, event, ...}}` |

### Sending via PubSub (no pid needed)

```elixir
# Fire-and-forget send using session_id string
ExWapp.send_message("my_session", "393XXXXXXXXX@s.whatsapp.net", "hello!")

# Synchronous send using session pid (returns {:ok, message_id})
{:ok, id} = ExWapp.send_message(session, "393XXXXXXXXX@s.whatsapp.net", "hello!")
```

The worker subscribes to `"ex_wapp:commands:<session_id>"` and picks up
`{:ex_wapp_send, jid, text}` messages automatically.

### Example: LiveView subscriber

```elixir
defmodule MyAppWeb.ChatLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      ExWapp.subscribe("my_session")
    end

    {:ok, assign(socket, messages: [], status: :unknown)}
  end

  def handle_info({:ex_wapp_message, jid, message}, socket) do
    {:noreply, update(socket, :messages, &[{jid, message} | &1])}
  end

  def handle_info({:ex_wapp_session, :connected}, socket) do
    {:noreply, assign(socket, :status, :connected)}
  end

  def handle_info({:ex_wapp_session, :disconnected, _reason}, socket) do
    {:noreply, assign(socket, :status, :disconnected)}
  end

  def handle_info({:ex_wapp_session, :terminated, _reason}, socket) do
    {:noreply, assign(socket, :status, :terminated)}
  end
end
```

## Multi-Session Safety

Conflicts happen if two processes share one WhatsApp identity/store file.

Use:

- `ExWapp.Live.run_session(session_id)` for concurrent sessions
- distinct `store_path` per session
- `ExWapp.Live.list_sessions/0` to inspect active sessions
- `ExWapp.Live.stop_session/1` to close one cleanly

Guardrails implemented:

- store-path conflict detection across active live sessions
- optional replacement of existing session with same `session_id`
- immediate reconnect on `stream_replaced`

## Persistence Model

Stores keep protocol-critical state:

- pairing/device identity
- noise static/session data
- signal identity/prekeys/session records
- local chat and message projections

Default store:

- `ExWapp.Store.Ets` with file persistence (`.etf`)

## Telemetry

ExWapp emits standard Telemetry events under `[:ex_wapp, :session, ...]`.

Canonical events are available via:

```elixir
ExWapp.Telemetry.events()
```

Attach one handler to all ExWapp events:

```elixir
handler_id = "exwapp-observer"

defmodule MyApp.ExWappTelemetry do
  def handle_event(event, measurements, metadata, _config) do
    IO.inspect({event, measurements, metadata}, label: "telemetry")
  end
end

:ok =
  ExWapp.Telemetry.attach_many(
    handler_id,
    &MyApp.ExWappTelemetry.handle_event/4,
    nil
  )

# later
ExWapp.Telemetry.detach(handler_id)
```

## Troubleshooting

Common log patterns:

- `Stream replaced by another connection`
- cause: same account connected elsewhere or duplicate local session/store
- action: stop old session/process, ensure unique store per session, reconnect

- `{:error, :pair_timeout}`
- cause: QR not scanned before expiry
- action: keep `qr_stream` running and scan latest QR immediately

- repeated reconnect scheduling
- cause: transient network/protocol errors
- action: inspect `stream:error` code and transport close reason in logs

- `Sending node: #Node<"iq", %{"to" => %ExWapp.JID{user: "", server: "s.whatsapp.net"}, "type" => "result"}, nil>`
- cause: normal server keepalive ping/pong on bare server JID (`s.whatsapp.net`)
- action: none; this is expected and now logged at debug level in `ExWapp.Conn`

- device shown as active in WhatsApp linked devices (similar to browser)
- cause: expected behavior for a valid WhatsApp Web companion session
- action: none; remove old linked devices only if you see stream conflicts/replacements

For protocol-level internals and message structure details, see `FLOW.md`.

## Debug Focus Files

- `lib/ex_wapp/conn.ex`
- `lib/ex_wapp/session.ex`
- `lib/ex_wapp/session/worker.ex`
- `lib/ex_wapp/session/outbound.ex`
- `lib/ex_wapp/session/inbound.ex`
- `lib/ex_wapp/session/outbound_queue.ex`
- `lib/ex_wapp/session/inbound_router.ex`
- `lib/ex_wapp/transport.ex`
- `lib/ex_wapp/noise/*`
- `lib/ex_wapp/pairing.ex`
- `lib/ex_wapp/signal/*`
