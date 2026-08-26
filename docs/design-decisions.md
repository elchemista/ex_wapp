# Design decisions

This document records current engineering choices. It is descriptive, not a
promise that internal modules will never change.

## One client-facing API

**Choice:** application code uses `ExWapp` with `%ExWapp.Client{}`.

**Why:** it keeps process topology, protocol workers, and storage details out of
callers. The same API can use the built-in runtime, a controlled test double, or
another complete adapter.

**Cost:** older PID-based Session functions remain visible during the migration
period and can make the boundary look less strict than it is. They are internal
compatibility entry points and do not carry the public compatibility promise.

## Caller-owned client state

**Choice:** mutating public operations return an updated client instead of
hiding all state behind a globally named process.

**Why:** applications can choose a GenServer, GenStateMachine, job, ETS table,
or plain functional flow as the owner. Tests do not need a fixed runtime.

**Cost:** callers must retain the latest returned client. Using an older value
can discard status, metadata, error, or trace updates.

## Configurable JSON implementation

**Choice:** ExWapp has no runtime dependency on a specific JSON package. The
host configures `config :ex_wapp, :json_library`.

**Why:** JSON is an application-wide choice in many Elixir systems. Avoiding a
forced implementation prevents dependency conflicts and lets hosts reuse the
library already present in their release.

**Cost:** startup configuration is required. `ExWapp.JSON` validates missing
modules, unsupported APIs, invalid return shapes, and non-iodata encoders so
misconfiguration fails explicitly rather than corrupting persisted data.

## Generated protobuf snapshot

**Choice:** generated Protox modules are checked in and updated as one snapshot.

**Why:** private protocol schemas drift. Deterministic generated sources make a
release reproducible and allow reviews to see schema changes. Stale generated
files are removed during regeneration.

**Cost:** the repository contains many generated modules. They must not be
edited by hand, and conventional line coverage is meaningless if every schema
module is counted as maintained application logic.

## Per-key mutation serialization

**Choice:** Signal and app-state mutations that share a logical key are
serialized, while unrelated keys can proceed concurrently.

**Why:** cryptographic ratchets and authenticated collection versions are
state machines; concurrent updates to the same state can reuse or skip keys and
make later messages undecipherable.

**Cost:** contention for one peer or collection is intentionally sequential.
The current in-process lock coordinator has an unbounded waiter queue and does
not persist ownership across a coordinator crash.

## Durable send semantics

**Choice:** storage/flush failure remains a send error, and a transport write is
distinguished from server acceptance or recipient delivery.

**Why:** retry receipts require the original message, identifier, and matching
cryptographic state. Reporting success before those invariants hold gives the
caller a result the runtime cannot reliably repair.

**Cost:** send calls can fail even when some work was already performed. Callers
must use returned structured errors and asynchronous receipts rather than treat
one return value as end-to-end delivery proof.

## Bounded data queue and priority control path

**Choice:** ordinary outbound work is bounded, while immediate protocol ACKs use
a priority lane.

**Why:** an overloaded application must exert backpressure instead of growing
memory indefinitely. ACK starvation can cause the server to close an otherwise
healthy stream.

**Cost:** the runtime can reject application sends under sustained pressure.
Operators must observe queue and send-health telemetry and choose appropriate
rate limits.

## Adapter boundaries for stores and events

**Choice:** persistence and event delivery are behaviours.

**Why:** the library should not dictate a database, PubSub system, or process
layout. Built-in adapters provide a usable default while production systems can
integrate their existing infrastructure.

**Cost:** custom adapters own their durability, ordering, and operational
quality. Passing behaviour tests is necessary but does not replace database and
failure-mode testing in the host application.
