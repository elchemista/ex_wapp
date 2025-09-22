# ExWapp

An experimental Elixir port of the WhatsMeow WhatsApp Web client. The code in
`lib/` mirrors the high-level architecture of the Go project and focuses on the
minimum viable path to “QR pairing + send a text message”.

## Current status

* Project skeleton in place with dedicated modules for transport, Noise,
  binary nodes, pairing, messaging, Signal, and persistence.
* Pairing events can already be observed via `ExWapp.qr_stream/1` (the stream is
  fed manually until the full handshake is implemented).
* File-based store keeps key material and other state using Erlang ETF terms.
* Tests cover the QR event stream and store persistence helpers.

> :warning: The cryptographic and protocol heavy lifting is **not implemented**
> yet. Noise, binary node encoding, Signal, and actual message exchange still
> need to be ported from WhatsMeow or re-implemented from the spec.

## Usage snapshot

```elixir
{:ok, session} = ExWapp.start_link()

qr_task = Task.async(fn ->
  ExWapp.qr_stream(session)
  |> Enum.each(&IO.inspect/1)
end)

ExWapp.connect(session)
```

The `connect/1` call will eventually drive the Noise handshake, emit QR codes,
and transition to a paired session. For now the process only stubs the flow so
that the supervising infrastructure and persistence hooks can be validated.

## Module map

* `ExWapp.Conn` – WebSocket transport (Noise placeholders in place)
* `ExWapp.Noise` – Noise_XX handshake scaffold
* `ExWapp.Binary` – WhatsApp binary node encoder/decoder stubs
* `ExWapp.Pairing` – QR pairing coordinator (state machine pending)
* `ExWapp.Messages` – Message protobuf + Signal envelope TODOs
* `ExWapp.Signal` – Signal bootstrap/encrypt/decrypt placeholders
* `ExWapp.Store.File` – Simple file-backed persistence helper

## Next steps

1. Fill in `ExWapp.Noise` with the proper handshake and AEAD framing.
2. Implement binary node encoding/decoding with the necessary token tables.
3. Drive the QR pairing flow by producing/consuming the relevant nodes.
4. Add protobuf models (e.g. `Message`) via `protox` and wire in the Signal
   pipeline for outbound texts.

Run the test suite with:

```bash
mix test
```
