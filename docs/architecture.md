# Architecture

ExWapp has one public application boundary: functions in `ExWapp` receive a
`%ExWapp.Client{}`. The client is ordinary data owned by the host application;
the built-in transport hides the processes required by the protocol.

```text
Host application
  |
  | ExWapp.new/connect/pair/send_*/list_*/...
  v
ExWapp facade -> ExWapp.Client.API -> ExWapp.Client.Transport behaviour
                                      |
                                      v
                            built-in Session adapter
                                      |
                +---------------------+--------------------+
                |                     |                    |
          session workers         Store adapter       Events adapter
                |
      WebSocket / Noise / binary nodes
                |
      Signal, device fanout, app state
                |
       generated Protox wire modules
```

## Public boundary

`ExWapp.Client` contains the selected transport, store, event adapter, runtime
configuration, status, and compact trace. Operations that change client state
return the updated client. The caller must retain that returned value.

`ExWapp.Client.API` coordinates validation, transport calls, normalized errors,
events, telemetry, and status transitions. Applications call these operations
through `ExWapp`, not through `ExWapp.Client.API` directly.

`ExWapp.Client.Transport` is a complete runtime adapter contract, despite its
historical name. A raw socket is insufficient: a working adapter must also
provide authentication, Signal state, device fanout, retries, persistence, and
inbound routing. `ExWapp.Client.Transport.Session` is the complete built-in
implementation.

Legacy functions that accept a session PID still exist. They are compatibility
entry points into the internal runtime, not an additional supported public API.

## Built-in runtime

The Session adapter starts and retains the internal session PID in client
metadata. Session workers divide protocol responsibilities so that connection,
post-authentication synchronization, inbound processing, outbound sending,
receipts, retries, and recovery do not share one undifferentiated loop.

The major layers are:

| Layer | Responsibility |
| --- | --- |
| WebSocket and Noise | Transport lifecycle, handshake, encrypted frames |
| Binary nodes | Encode and decode protocol tree nodes |
| Signal | Identity keys, prekeys, peer sessions, ratchets, sender keys |
| Outbound | Content encoding, device discovery, fanout, encryption, queueing |
| Inbound handlers | ACKs, receipts, messages, notifications, calls, sync data |
| App state | Authenticate and apply synchronized mutations and collection state |
| Store | Persist cryptographic state, session data, chats, and messages |
| Events and telemetry | Deliver high-level results without prescribing an OTP topology |

## Outbound path

1. The facade builds a typed `ExWapp.Message` and passes it to the configured
   transport.
2. The built-in runtime resolves recipient devices and addressing families.
3. Signal sessions or sender keys encrypt the payload for the required targets.
4. The stanza enters a bounded outbound queue. Protocol-critical ACK traffic
   has a separate priority path so ordinary sends cannot starve it.
5. A successful send result means the encrypted stanza was written by the
   transport. Acceptance, delivery, and reading are later asynchronous states.
6. Retry and session-repair paths preserve the original message identifier.

Durable store failures are not reported as successful sends. This matters
because resend repair and receipt processing depend on the locally stored
message and cryptographic state.

## Inbound path

1. The transport decrypts a Noise frame and parses its binary node.
2. Inbound routing first handles protocol obligations such as ACKs and receipts.
3. Message candidates are resolved to the correct sender/device identity and
   decrypted with Signal.
4. Typed handlers project protocol payloads into ExWapp data structures.
5. Chats, messages, receipts, calls, and synchronized state are persisted.
6. High-level `ExWapp.Event` values cross the application boundary through the
   configured `ExWapp.Events` adapter.

## Persistence and ownership

`ExWapp.Store` is the persistence contract. The built-in ETS adapter keeps hot
state in ETS and can durably flush a versioned, gzipped JSON envelope; the
memory adapter is intended for tests and short-lived runs. Applications may
provide a database-backed adapter.

The host application owns supervision and the latest client value. The built-in
runtime owns its internal workers. A store struct created by the caller remains
caller-owned; a store created from client options can be closed by the runtime.

## Optional integrations

| Integration | Host configuration | Contract |
| --- | --- | --- |
| JSON | `config :ex_wapp, :json_library, MyJSON` | `ExWapp.JSON.Library` |
| QR rendering | `config :ex_wapp, :qr_renderer, MyRenderer` or the Live helper's `:qr_renderer` option | `c:ExWapp.QR.Renderer.render/2` |
| Instrumentation | `config :ex_wapp, :telemetry_adapter, MyMetrics` | `ExWapp.Telemetry.Adapter` |

Pairing exposes the raw QR payload to the application; rendering is optional
and uses no bundled QR library. The Live helper calls the selected renderer
with `:qr_options`, writes its returned iodata to `:qr_path`, and returns render
or file-write failures without retaining the QR subscription. See the README
for an application-owned `qr_code` adapter example.

Instrumentation is disabled unless configured. All ExWapp metrics, including
client connection and session policy events, pass through `ExWapp.Telemetry`.
Backend exceptions cannot fail protocol work. Callbacks run synchronously and
must return promptly. The Erlang `:telemetry` module can be selected directly;
custom backends only need `execute/3`, with handler management optional.
WebSockex currently brings its own transitive `telemetry` dependency and owns
its own events independently of ExWapp's adapter setting.

## Generated protocol boundary

Protox modules under `lib/ex_wapp/wa_proto/` are generated artifacts, not
hand-maintained application logic. The update script replaces the complete
snapshot, removes stale output, keeps the generated typespecs, compiles with
warnings as errors, and is backed by schema, round-trip, and wire-compatibility
tests. Hand-written modules translate between those wire structures and the
stable client-facing model.

Generated encoders and decoders call Protox runtime functions. Keeping their
source in the repository removes the production need for the `protoc`
generator, but not for the `protox` library itself.
