# Strengths and limitations

This assessment is deliberately limited to behavior visible in the repository
and its tests. It does not compare ExWapp with another project and does not
claim official protocol support.

## Where ExWapp is strong

### Protocol correctness is tested at state-machine boundaries

The suite exercises Noise, Signal sessions, sender keys, prekeys, app-state
authentication, binary nodes, receipts, retries, device fanout, and persistence.
It includes concurrent ratchet and mutation tests, not only isolated encoding
examples. Wire fixtures and protobuf round trips catch field-number and schema
drift that compilation alone would miss.

### Generated protocol code has a repeatable update path

The protobuf updater replaces a complete checked-in snapshot, removes stale
files, adds required typespecs, and is expected to compile with warnings as
errors. Generated modules are kept behind hand-written translation layers so
schema churn does not need to become application API churn.

### Failure and recovery semantics are explicit

The runtime distinguishes a local transport write from later acceptance,
delivery, and read receipts. Retry requests reuse the original message ID;
session repair has a bounded budget; failed durable flushes remain visible to
the caller. The test suite covers worker crashes, retry redelivery, missing
prekeys, disconnects, malformed nodes, and repair failures.

### Concurrency receives first-class attention

Signal and app-state state machines serialize mutations by logical key. Tests
exercise concurrent send/receive ratchets, lock-owner crashes, collection
updates, and durable store transitions. The outbound data queue is bounded and
protocol ACKs have a priority path.

### Host applications retain architectural control

The public client is runtime-neutral data. Stores, events, and the complete
client transport are adapter boundaries, so applications can select their own
supervision, persistence, event delivery, and JSON implementation. ExWapp does
not force a web framework or a particular JSON dependency.

### Static and compatibility checks are part of CI

CI covers the supported Elixir/OTP pairs and runs formatting, compilation with
warnings as errors, tests, Credo, Dialyzer, documentation generation, and Hex
package construction. Dialyzer ignores are explicit and unused ignore entries
cause the check to fail.

### Automated tests are complemented by field testing

ExWapp has also been exercised for several months with many linked devices and
different device configurations. This has validated connection, pairing,
message flow, persistence, and recovery behavior under conditions that isolated
fixtures cannot fully reproduce. Field testing increases confidence in the
current implementation; it does not constitute official certification or a
guarantee against a future remote protocol change.

## Current limitations

### The protocol is private and can change without notice

Even strong fixtures cannot predict a remote rollout. A new schema, handshake,
policy, or server-side behavior can break connection or messaging between
library releases. Live interoperability cannot be made as deterministic as the
offline suite.

### The high-level feature surface is intentionally incomplete

The supported send API currently covers text, image, audio, document, location,
contact, and event messages. Other protocol capabilities visible in generated
schemas are not automatically supported public features. In particular, users
should not assume public support for every media type, reaction, edit, poll,
channel, community, business, or calling operation.

Call storage contains signalling metadata only. ExWapp does not implement VoIP
audio/video or answering calls.

### History synchronization is partial

Inline history-sync payloads can be decoded and projected, but blob-delivered
history chunks are not downloaded yet. Local chat/message queries therefore do
not promise a complete remote account export.

### Some coordination remains process-local

The mutation lock has an unbounded waiter queue. If its coordinator crashes,
in-memory ownership information is lost even though dead lock owners are
normally monitored and released. Deployments should supervise the runtime and
apply upstream backpressure rather than allow unlimited work for one key.

### The built-in ETS store is not a universal production database

It provides durable file snapshots and useful atomic operations, but large or
multi-node installations will generally need a custom store with application-
specific backup, replication, retention, and access controls.

### Secrets and personal data cross application-owned boundaries

Custom logs, crash dumps, stores, event handlers, and telemetry metadata can
expose phone numbers, content, identity keys, or session material. The host is
responsible for file permissions, encryption at rest, retention, redaction, and
access control.

### Account safety cannot be guaranteed

ExWapp is unofficial and unaffiliated. Use of an unofficial client may violate
service terms or trigger abuse controls, including temporary suspension or a
permanent account/number ban. Use dedicated test accounts, avoid harmful or
spam automation, and treat every deployment as an operational risk decision.

WhatsApp's official
[Messaging Guidelines](https://www.whatsapp.com/legal/messaging-guidelines/)
identify unofficial clients, bulk messaging, auto-messaging, and automation
that harms WhatsApp or its users as prohibited adversarial behavior. They state
that enforcement can include temporarily or permanently suspending an account.

For commercial communication, the
[WhatsApp Business Messaging Policy](https://business.whatsapp.com/policy/)
requires that recipients provide their phone number and opt in to subsequent
messages or calls. Businesses must honor opt-out requests and follow additional
rules, including approved templates and the customer service window where
applicable. Violations or unauthorized messaging at scale can lead to limited
or removed access. These policies may change, so every integrator is responsible
for reviewing and complying with the current versions and applicable law.
