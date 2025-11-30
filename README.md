# ExWapp

> WARNING: This library is experimental, incomplete, and currently unreliable
> beyond pairing. Message delivery is still broken/intermittent due to ongoing
> protocol changes. Use only for debugging; do **not** depend on it. See
> FLOW.md for the latest breakage notes.

Experimental Elixir port of the WhatsMeow WhatsApp Web client. Built for protocol
debugging; APIs change frequently and features are incomplete.

## Quickstart (pair + test send)

```bash
mix deps.get
iex -S mix
iex> ExWapp.Example.run()
```

What `ExWapp.Example.run/1` does (intended for debugging, not production):
- starts a session with ETS persistence at `/tmp/ex_wapp/bot_session.etf` (override via `store:`)
- performs the websocket + Noise handshake and streams QR events
- saves the QR to `/tmp/whatsapp_qr.svg` (open and scan from WhatsApp > Linked Devices)
- retries on 401s by clearing the session; or call `ExWapp.Example.clear_session/0` yourself
- waits for the post-pairing reconnect, then keeps the session alive and sends a test message to your own JID when available

## Basic API (without the helper)

```elixir
{:ok, session} = ExWapp.start_link(store: {ExWapp.Store.Ets, path: "/tmp/ex_wapp/bot_session.etf"})
:ok = ExWapp.connect(session)

# Stream QR codes yourself
session
|> ExWapp.qr_stream()
|> Enum.each(&IO.inspect/1)

# After pairing, send a message
ExWapp.send_message(session, "1234567890@s.whatsapp.net", "Hello!")
```

## Signal implementations

- Show current implementation: `ExWapp.Example.signal_info/0`
- Switch to Rust NIF (default): `ExWapp.Example.use_native_signal/0`
- Switch to pure Elixir: `ExWapp.Example.use_elixir_signal/0`
- Smoke test the selected impl: `ExWapp.Example.test_signal/0`

## Sending with the new pipeline

- V2 (Rust session cipher, multi-device aware via the Session pipeline):

```elixir
{:ok, session} = ExWapp.Example.run()
ExWapp.Example.send_v2(session, "1234567890@s.whatsapp.net", "Hello!")
ExWapp.Example.send_v2(session, "1234567890@s.whatsapp.net", "Hello!", 40) # target specific device id
```

- V3 (explicit usync device listing + multi-device send; mostly for debugging):

```elixir
{:ok, session} = ExWapp.Example.run()
ExWapp.Example.send_v3(session, "1234567890@s.whatsapp.net", "Hello!")
```

Both helpers fetch prekeys, build the protobuf payload, encrypt with the Rust Signal
implementation, and send a single message node with the correct `enc` payloads.
`send_v2/3` already handles multi-device via the session-managed pipeline; the
`device_id` argument lets you force a specific target. `send_v3/3` keeps the explicit
usync flow if you need to debug device lists. DeviceSentMessage for your own other
devices is still TODO.

## Paths and helpers

- Session store: `/tmp/ex_wapp/bot_session.etf` (customizable via `ExWapp.Example.run(store: ...)`)
- QR output: `/tmp/whatsapp_qr.svg`
- Clear persisted state: `ExWapp.Example.clear_session/0`

## Limitations / Warnings

- Experimental and unstable; do not use in production or user-facing projects.
- Message delivery is currently broken/intermittent; expect failures even after pairing.
- Chat history sync and full Signal decryption are still in progress.
- Protocol changes can break flows at any time; see FLOW.md for current status.
