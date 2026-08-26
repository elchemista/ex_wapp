# Protocol flow

This document describes the current built-in runtime from a connection request
to encrypted message delivery. It intentionally avoids fixed client-version
values and debugging history, because both become stale quickly.

Application code still has one supported boundary: call `ExWapp` with a
`%ExWapp.Client{}`. The Session, Noise, Signal, binary-node, and protobuf modules
mentioned below are implementation details.

## Layers

```text
ExWapp public client facade
          |
ExWapp.Client.Transport.Session
          |
Session workers and persistence
          |
Binary nodes, Signal, app state
          |
Noise encrypted transport
          |
WhatsApp framing over WebSocket/TLS
```

The complete runtime is required for production messaging. A raw WebSocket does
not provide pairing, authentication, Signal sessions, device fanout, sender
keys, retries, receipts, or synchronized state.

## 1. Starting the built-in runtime

```elixir
client =
  ExWapp.new(
    session_id: "account-1",
    store: {ExWapp.Store.Ets, path: "account-1.etf"},
    transport: ExWapp.Client.Transport.Session,
    events: MyApp.WhatsAppEvents
  )

{:ok, client} = ExWapp.connect(client)
```

The Session transport creates the internal session runtime when necessary and
keeps its PID in client metadata. That PID is private runtime state. The caller
retains the updated client and continues to use the `ExWapp` facade.

The runtime loads persistent credentials and protocol state before connecting.
This includes Noise keys, Signal identity and sessions, signed and one-time
prekeys, paired-device data, app-state keys, contacts, chats, messages, and
retry information.

## 2. WebSocket and framing

The built-in connection opens a TLS WebSocket to the configured WhatsApp Web
endpoint. The WebSocket implementation supplies upgrade headers; ExWapp adds
the required origin instead of duplicating protocol-managed headers.

WhatsApp payloads use a 24-bit big-endian length prefix:

```text
+----------------+----------------------+----------------------+
| optional WA    | payload length       | payload              |
| header         | 3 bytes, big-endian  | variable length      |
+----------------+----------------------+----------------------+
```

The four-byte WA header appears on the initial client frame. Handshake payloads
are protobuf messages. After the Noise split, payloads are authenticated and
encrypted transport frames.

## 3. Noise handshake

ExWapp implements `Noise_XX_25519_AESGCM_SHA256` in pure Elixir.

```text
Client                                      Server
  |                                            |
  | ClientHello(client ephemeral public key)  |
  |------------------------------------------->|
  |                                            |
  | ServerHello(server ephemeral, encrypted   |
  | static key, encrypted certificate)         |
  |<-------------------------------------------|
  |                                            |
  | ClientFinish(encrypted client static key, |
  | encrypted client payload)                  |
  |------------------------------------------->|
  |                                            |
  |<====== encrypted transport frames =======>|
```

### Client hello

The client generates an ephemeral Curve25519 key pair, initializes the Noise
state with the protocol name and WA prologue, mixes the client ephemeral public
key into the handshake hash, and sends it in a generated handshake protobuf.

### Server hello

The server returns its ephemeral public key, encrypted static public key, and
encrypted certificate payload. The client:

1. authenticates the server ephemeral value into the transcript;
2. mixes the ephemeral-to-ephemeral shared secret;
3. decrypts and authenticates the server static key;
4. mixes the client-ephemeral/server-static shared secret;
5. decrypts and validates the certificate payload.

Any authentication, certificate, or transcript failure stops the handshake.
The runtime does not continue with partially trusted key material.

### Client finish and transport keys

The client encrypts its static public key, mixes the
client-static/server-ephemeral shared secret, and encrypts the client payload.
The payload differs between a new-device registration and a login using stored
pairing data.

After ClientFinish, the Noise state splits into independent write and read keys.
Transport frames use AES-256-GCM with monotonically increasing nonces. A
connection restart creates new transport keys and counters; persistent Signal
identity is a separate layer.

The advertised client version comes from `ExWapp.Config` and can be overridden
through runtime configuration. It must be reviewed as the remote web client
changes; this document deliberately does not duplicate the current numeric
value.

## 4. Pairing and login

For a new device, the encrypted client payload contains the identity,
registration, signed-prekey, device-properties, and history-sync information
needed for companion registration. QR or phone-number pairing events are routed
back through the client pairing flow.

Pairing credentials are durably stored before they are treated as reusable.
After the server requests a stream restart, the runtime reconnects using the
stored identity and a login payload rather than repeating registration.

For an already paired client, the same connection and Noise handshake run, but
the login payload identifies the linked device from persisted credentials.

## 5. Post-authentication initialization

After authentication the runtime coordinates protocol initialization instead
of immediately accepting arbitrary application traffic. The sequence includes:

1. querying the server prekey count;
2. comparing it with usable local private prekeys;
3. reserving and durably persisting new prekeys before upload when refill is
   necessary;
4. updating passive/presence state;
5. starting the configured app-state synchronization;
6. moving the session into its connected state when required initialization
   has completed.

Prekey persistence is part of correctness. Advertising a public prekey whose
private half was not durably stored would make a later inbound message
undecryptable.

## 6. Outbound messages

```text
ExWapp.send_*
  -> typed ExWapp.Message
  -> recipient and addressing-family resolution
  -> device discovery
  -> Signal session or group sender-key preparation
  -> per-device encryption and fanout
  -> bounded outbound queue
  -> Noise frame write
  -> asynchronous server ACK / delivery / read receipts
```

Direct messages may target several devices. The runtime fetches missing prekey
bundles, creates Signal sessions, and encrypts the payload separately for each
target. Group messages use sender-key distribution and group fanout rules.

Mutations of one Signal ratchet are serialized by logical key. Unrelated peers
can progress concurrently, while two operations cannot advance the same
ratchet from the same state.

Protocol ACK traffic has a priority lane separate from normal bounded outbound
work. Under overload, application sends can be rejected rather than growing
memory without limit or starving protocol-critical acknowledgements.

A successful send return means the encrypted stanza was written by the
transport. It does not prove server acceptance, recipient delivery, or reading.
Those states arrive later through ACKs and receipts.

## 7. Inbound messages

```text
WebSocket frame
  -> Noise authentication and decryption
  -> binary-node decoding
  -> immediate protocol ACK where required
  -> stanza routing
  -> sender/device candidate resolution
  -> Signal decryption
  -> typed content projection
  -> durable store update
  -> ExWapp.Event emission
```

The inbound router separates messages, receipts, acknowledgements,
notifications, calls, and synchronization payloads. Signal ciphertext can be a
new prekey message, an established session message, or a group sender-key
message. Decryption commits updated ratchet state through the configured store.

Malformed or undecryptable payloads remain explicit failures. Where the
protocol permits it, retry receipts request redelivery; retry counters prevent
an unbounded loop.

## 8. Delivery confirmation and repair

Server ACKs are classified separately from delivery and read receipts. A
session rejection can trigger bounded repair:

1. locate the original persisted message;
2. preserve its message identifier;
3. invalidate the affected peer session where appropriate;
4. obtain fresh device/session material;
5. resend within the configured repair budget;
6. expose the final result to the caller and telemetry.

The runtime does not report durable-store failure as a successful send. The
original message and matching cryptographic state must remain available for
retry processing.

## 9. App state and history sync

App-state patches are authenticated before they mutate contacts, chats, or
collection state. Collection version, LTHash state, and mutation MACs advance
together. Concurrent mutations for one collection are serialized.

Inline history-sync payloads are decoded and projected into the configured
store. Blob-delivered history chunks are represented as pending blob references
but are not downloaded yet. Consequently, local history queries do not promise
a complete remote account export.

## 10. Disconnect and reconnect

A transport close is a Session event, not an ignored socket detail. The runtime
clears connection-scoped waits, closes the failed connection, applies reconnect
policy and backoff, and starts a new WebSocket and Noise handshake when allowed.

Credentials, Signal state, messages, and app-state data survive through the
store. Noise transport keys, frame counters, pending connection waits, and
other socket-scoped data do not survive a reconnect.

Fatal authentication, policy, or account failures are not treated as an
unlimited reconnect loop. They are surfaced through structured state, events,
logs, and diagnostics.

## Maintainer invariants

- Never bypass the Session pipeline for high-level production sends.
- Never reuse Noise transport keys or counters across connections.
- Never advertise prekeys before their private halves are durably stored.
- Never mutate the same Signal ratchet or app-state collection concurrently.
- Never change a message ID during retry or session repair.
- Never interpret a socket write as end-to-end delivery.
- Never count generated protobuf lines as maintained-code coverage.

See [Architecture](architecture.md) for component ownership,
[Design decisions](design-decisions.md) for the reasons behind these boundaries,
and [strengths and limitations](strengths-and-limitations.md) for current gaps
and operational risks. [Protocol reference](protocol-reference.md) records the
wire and addressing invariants used by the implementation.
