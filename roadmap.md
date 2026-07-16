# ex_wapp hardening roadmap

This document records follow-up work identified while reviewing the Signal
mutation coordinator. The current implementation is suitable for the `0.1.0`
release: completed locks are removed, owner crashes are recovered through
monitors, and independent mutation keys can run concurrently. The items below
are production-hardening work, not release blockers.

## 1. Bound contention and apply backpressure

The coordinator retains queued callers while a mutation key is held. This is
correct, but a stalled holder combined with unbounded producers can grow the
live waiter queue indefinitely. Garbage collection cannot reclaim callers that
are still referenced by that queue.

- Put configurable concurrency and queue limits around outbound session tasks.
- Add a maximum waiter count per mutation key and a documented overload result.
- Design acquisition deadlines with explicit cancellation. A bare
  `GenServer.call/3` timeout is insufficient because a timed-out acquisition can
  remain queued and later be granted.
- Remove dead or cancelled waiters promptly instead of waiting for the current
  holder to release the key.
- Preserve FIFO ordering for accepted waiters and re-entrant locking for the
  current owner.

Acceptance criteria:

- Holding one key while continuously submitting work stays within a configured
  process and memory ceiling.
- A cancelled or timed-out caller can never become a later lock owner.
- Overload is observable and returned to the producer without crashing the
  coordinator.

## 2. Keep critical sections short

Signal crypto and ETS mutations are appropriate inside the lock. Network and
disk I/O are not, because a slow external operation would retain every waiter
for the same key.

- Audit every `MutationLock` callback for file, network, and synchronous writer
  calls.
- Pay particular attention to SenderKey store updates that may synchronously
  flush a snapshot.
- Where necessary, commit the runtime mutation in ETS while locked and persist
  the resulting snapshot after releasing the lock.
- Measure lock hold time so regressions are visible.

Acceptance criteria:

- No lock callback performs network I/O.
- Durable-store latency cannot extend a Signal mutation lock indefinitely.
- Slow persistence tests demonstrate that unrelated keys continue to progress.

## 3. Add lock telemetry

Emit low-cardinality telemetry without including JIDs, identity keys, or message
contents.

- Current active-lock count and total waiter count.
- Acquisition wait duration and lock hold duration.
- Maximum queue depth, rejected acquisitions, cancellations, and owner crashes.
- Coordinator restarts and abnormal termination reasons.

Define operational thresholds only after observing real workloads. Do not shard
or add processes based solely on synthetic benchmarks.

## 4. Harden coordinator failure semantics

Owner crashes are handled today, but a crash of the coordinator itself loses
its in-memory ownership table while an existing caller may still be executing.
A restarted coordinator could then grant the same key to another caller.

- Add a test that terminates the coordinator while a mutation is active.
- Couple coordinator and mutation-worker lifetimes through supervision, or add
  an ownership epoch/lease design that makes stale holders unable to commit.
- Verify that coordinator restart cannot allow two successful commits for one
  mutation key.

If stronger isolation is eventually needed, prefer a dedicated supervised
Signal state owner per session over reusing `ExWapp.Session.Worker`.
`Session.Worker` must remain responsive to inbound nodes, IQ responses,
acknowledgements, and timers; using it as the crypto lock would serialize
unrelated recipients and could block protocol progress.

## 5. Scale only when measurements require it

The coordinator only manages ownership metadata; crypto executes in caller
processes, and different keys already run concurrently. If telemetry later
shows the coordinator itself becoming a bottleneck:

- Shard coordinators deterministically by session/store identity or mutation
  key.
- Preserve a stable global ordering when an operation requires multiple keys.
- Re-run contention, crash-recovery, and deadlock tests across shard boundaries.

## 6. Treat idle heap cleanup as optional

Normal BEAM garbage collection already reclaims released lock entries. Do not
force garbage collection after every release.

- Consider a conservative `hibernate_after` interval only if production
  measurements show many long-idle coordinators retaining meaningful heap
  capacity.
- Benchmark wake-up latency and garbage-collection overhead before enabling it.

## 7. Extend stress and failure testing

- Run long-lived mixed pairwise and group Signal mutation tests.
- Cover holder crashes, waiter crashes, cancellation races, coordinator
  restarts, queue overload, and slow persistence.
- Assert monotonic ratchet counters, unique sender-key iterations, successful
  decryptability, bounded queue depth, and continued progress for unrelated
  keys.
- Run concurrency tests repeatedly with randomized scheduling and multiple
  scheduler counts.
