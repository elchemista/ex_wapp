# ExWapp

[![Tests](https://github.com/elchemista/ex_wapp/actions/workflows/test.yml/badge.svg)](https://github.com/elchemista/ex_wapp/actions/workflows/test.yml)
[![Credo](https://github.com/elchemista/ex_wapp/actions/workflows/credo.yml/badge.svg)](https://github.com/elchemista/ex_wapp/actions/workflows/credo.yml)
[![Dialyzer](https://github.com/elchemista/ex_wapp/actions/workflows/dialyzer.yml/badge.svg)](https://github.com/elchemista/ex_wapp/actions/workflows/dialyzer.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/ex_wapp.svg)](https://hex.pm/packages/ex_wapp)
[![HexDocs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/ex_wapp)

ExWapp is a runtime-neutral WhatsApp Web client library for Elixir, proven through sustained production use across multiple applications.

See the [changelog](CHANGELOG.md) for release notes.

## Status and public API

The only supported public application API is the `%ExWapp.Client{}` workflow
exposed by the `ExWapp` facade:

1. create a client with `ExWapp.new/1`;
2. pass that client to `ExWapp.connect/1`, `pair/1`, send, media, contact, chat,
   and diagnostics functions;
3. keep the updated client returned by mutating operations in state owned by
   your application.

`ExWapp.Session` is the internal engine used by the built-in client transport.
It currently exposes functions that can also return chats, messages, and other
runtime state, and old PID-based clauses remain for compatibility. Those entry
points are not the stable public API and may change as the runtime evolves.

The library is production-tested but protocol-sensitive. WhatsApp can change
its private web protocol without notice.

In addition to its automated test suite, ExWapp has been exercised in field
testing for several months across many linked devices and device
configurations. This practical validation improves confidence in real-world
behavior, but it is not an official certification and cannot prevent future
protocol or policy changes.

## Requirements

CI tests these supported combinations:

- Elixir 1.19 with Erlang/OTP 28
- Elixir 1.20 with Erlang/OTP 29

## Installation

Add ExWapp and the JSON implementation of your choice to your application:

```elixir
def deps do
  [
    {:ex_wapp, "~> 0.1.6"},
    {:jason, "~> 1.4"}
  ]
end
```

ExWapp intentionally has no runtime dependency on Jason. Configure the JSON
module in your host application:

```elixir
# config/config.exs
config :ex_wapp, :json_library, Jason
```

You can instead select `Poison`, Elixir's built-in `JSON` module, or an adapter
for another implementation:

```elixir
config :ex_wapp, :json_library, Poison
# or, on an Elixir version that provides it:
config :ex_wapp, :json_library, JSON
```

The selected module may expose `encode/1` and `decode/1` with
`{:ok, value} | {:error, reason}` results, or the corresponding `encode!/1` and
`decode!/1` functions. For a library with a different API, implement a small
module following `ExWapp.JSON.Library` and configure that module instead. A
missing or invalid JSON configuration produces an explicit error.

QR rendering and ExWapp instrumentation are also supplied by the host application;
`qr_code` and `telemetry` are not direct dependencies of ExWapp. The currently
locked WebSockex version depends on `telemetry` itself, so it still appears as
a transitive dependency of that transport. ExWapp does not enable instrumentation
just because the package is installed.

Protox remains a runtime dependency: the checked-in generated modules delegate
wire encoding and decoding to its runtime helpers.
Only `protoc`, used when regenerating those files, is unnecessary in production.
The Protox 2.1 runtime has no Decimal or JSON package dependency.

`ed25519` is retained for the Signal/Noise verification boundary. Tests against
OTP's Ed25519 primitive agree for valid converted XEdDSA signatures, but expose
differences for noncanonical signatures and malformed inputs. See the
[dependency comparison](docs/design-decisions.md) before replacing it.

The 0.1.6 dependency baseline was checked against Hex on 2026-11-12. All 17
locked direct and transitive packages use their latest stable releases;
pre-releases are excluded. Direct dependencies are:

| Package | Version | Scope |
| --- | --- | --- |
| `ed25519` | 1.5.2 | Runtime |
| `protox` | 2.1.0 | Runtime |
| `phoenix_pubsub` | 2.4.1 | Runtime |
| `websockex` | 0.5.1 | Runtime |
| `credo` | 1.7.19 | Development/test |
| `dialyxir` | 1.4.9 | Development/test |
| `ex_doc` | 0.40.4 | Development |

## Quick start

The built-in session transport provides a complete WhatsApp connection while
the caller continues to use only the client API:

```elixir
client =
  ExWapp.new(
    session_id: "account_1",
    store: {ExWapp.Store.Ets, path: "/var/lib/my_app/account_1.etf"},
    transport: ExWapp.Client.Transport.Session,
    events: MyApp.WhatsAppEvents
  )

{:ok, client} = ExWapp.connect(client)
{:ok, client, {:code, qr_code}} = ExWapp.pair(client)

{:ok, client, message_id} =
  ExWapp.send_message(client,
    to: "393XXXXXXXXX@s.whatsapp.net",
    text: "hello"
  )

{:ok, chats} = ExWapp.list_chats(client)

{:ok, messages} =
  ExWapp.get_messages(client, "393XXXXXXXXX@s.whatsapp.net", limit: 50)
```

The client is regular data. Store the latest returned value in your GenServer,
GenStateMachine, LiveView, job, or another application-owned process. See
[`examples/gen_server_session.ex`](examples/gen_server_session.ex) for a
complete wrapper.

## Rendering pairing QR codes

`ExWapp.pair/1` returns a raw pairing payload in `{:code, payload}`. Render that
string with your preferred Elixir or browser library. No QR implementation is
bundled, and an already paired session needs no renderer.

For example, an application choosing the `qr_code` package adds
`{:qr_code, "~> 3.2.0"}` to **its own** dependencies and implements:

```elixir
defmodule MyApp.QRRenderer do
  @behaviour ExWapp.QR.Renderer

  @impl true
  def render(payload, opts) do
    payload
    |> QRCode.create(Keyword.get(opts, :error_correction, :high))
    |> QRCode.render(Keyword.get(opts, :format, :svg))
  end
end

{:ok, client, {:code, payload}} = ExWapp.pair(client)
{:ok, svg} = MyApp.QRRenderer.render(payload, format: :svg)
File.write!("/tmp/whatsapp.svg", svg)
```

Another library can implement the same `render/2` callback, returning
`{:ok, binary_or_iodata}` or `{:error, reason}`. Render new payloads when QR codes
rotate and wait for pairing/authentication to finish before sending messages.

The manual IEx helper uses that same contract:

```elixir
config :ex_wapp, :qr_renderer, MyApp.QRRenderer

# In IEx; qr_renderer overrides the application default when supplied.
ExWapp.Live.run_session("account_1",
  qr_renderer: MyApp.QRRenderer,
  qr_options: [format: :svg, error_correction: :high],
  qr_path: "/tmp/whatsapp.svg"
)
```

`:qr_options` goes unchanged to the renderer. Set `:qr_path` to match its output
format, for example `.png` for PNG. If a QR is received without a renderer, the
helper returns `{:error, :qr_renderer_not_configured}`. Rendering and file-write
errors are returned immediately and the helper releases its QR subscription;
it does not log the pairing payload.

## Client API overview

All functions below are called through `ExWapp` with a `%ExWapp.Client{}`.

Lifecycle and pairing:

- `new/1`
- `connect/1`
- `pair/1`
- `disconnect/1`

Messages and media:

- `send_message/2`
- `send_image/4`
- `send_video/4`, `send_sticker/4`
- `send_audio/4`
- `send_document/4`
- `send_location/5`
- `send_contact/5`
- `send_event/5`
- `send_reaction/5`
- `download_media/3`
- `receive_message/3`

Contacts, chats, calls, and local history:

- `list_contacts/1`, `get_contact/2`, `sync_contacts/1`
- `create_contact/3`, `delete_contact/2`
- `list_chats/1`, `list_groups/1`, `get_chat/2`
- `get_messages/3`, `stream_messages/3`, `all_messages/2`
- `delete_messages/3`
- `request_history/4` (requests older messages from the phone)
- `list_calls/2`, `get_call/2`

Diagnostics:

- `status/1`
- `last_error/1`
- `diagnostics/1`

Mutating operations return the updated client. A send, for example, returns
`{:ok, client, message_id}` or `{:error, %ExWapp.Error{}, client}`. Read
operations return `{:ok, value}` or the same structured client error.

## Messages

Text can be sent directly from keyword options:

```elixir
{:ok, client, id} =
  ExWapp.send_message(client,
    to: jid,
    text: "hello",
    quoted: quoted_message,
    mentions: ["123@s.whatsapp.net"]
  )
```

Media and structured messages use focused functions:

```elixir
{:ok, client, image_id} =
  ExWapp.send_image(client, jid, {:path, "photo.jpg"},
    mimetype: "image/jpeg",
    caption: "A photo"
  )

{:ok, client, audio_id} =
  ExWapp.send_audio(client, jid, {:path, "voice.ogg"},
    mimetype: "audio/ogg; codecs=opus",
    ptt: true
  )

{:ok, client, document_id} =
  ExWapp.send_document(client, jid, {:path, "contract.pdf"},
    mimetype: "application/pdf",
    caption: "Contract"
  )

{:ok, client, location_id} =
  ExWapp.send_location(client, jid, 45.4642, 9.1900,
    name: "Milano",
    address: "Milano, Italy"
  )
```

`ExWapp.send_message/2` returns after the built-in transport has written the
encrypted stanza. That is not proof that WhatsApp accepted or delivered it.
Delivery and read receipts arrive asynchronously.

## Incoming messages and events

Inbound payloads cross the public boundary through
`ExWapp.receive_message/3`. The configured transport converts them to
`ExWapp.Event` values, and the configured event adapter decides how your
application receives them:

```elixir
defmodule MyApp.WhatsAppEvents do
  @behaviour ExWapp.Events

  @impl true
  def emit(_client, event) do
    Phoenix.PubSub.broadcast(MyApp.PubSub, "whatsapp", event)
  end
end
```

The built-in session transport also persists inbound chats and messages in the
configured store. Read them through the client facade:

```elixir
{:ok, chats} = ExWapp.list_chats(client)
{:ok, page} = ExWapp.get_messages(client, jid, limit: 100, offset: 0)
{:ok, history} = ExWapp.all_messages(client, jid)

history
|> Stream.chunk_every(250)
|> Stream.each(&MyApp.MessageRepo.upsert_batch(jid, &1))
|> Stream.run()
```

`get_messages/3` materializes a newest-first page. `stream_messages/3` and
`all_messages/2` return lazy streams backed by the configured store. These are
local-history APIs; they do not request a complete remote account export.

The built-in session automatically downloads encrypted history-sync blobs sent
by the account's own devices, checks their integrity, decompresses them, and
imports their supported records into the same store as inline history. Downloads
run in supervised background tasks. Session subscribers receive
`{:ex_wapp_session, :history_sync, :completed, metadata}` after persistence, or
`{:ex_wapp_session, :history_sync, :failed, reason, metadata}` on failure.
Use the same history queries above after completion. `download_media/3` also
accepts a `%ExWapp.Media.Ref{type: :history}` for fetching decrypted compressed
bytes directly.

## Video, stickers, reactions, and older history

```elixir
{:ok, client, video_id} =
  ExWapp.send_video(client, jid, {:path, "/media/clip.mp4"},
    caption: "A short clip", seconds: 12, width: 1280, height: 720)

{:ok, client, sticker_id} =
  ExWapp.send_sticker(client, jid, {:path, "/media/sticker.webp"}, animated: true)

{:ok, client, reaction_id} = ExWapp.send_reaction(client, jid, received_message_id, "👍")
# Empty text removes your reaction. Set from_me: true when the target was your message.
{:ok, client, removal_id} = ExWapp.send_reaction(client, jid, received_message_id, "")
# For someone else's group message, identify the target's sender explicitly.
{:ok, client, group_reaction_id} =
  ExWapp.send_reaction(client, group_jid, received_message_id, "👍", participant: sender_jid)
```

Media sources also accept `{:bytes, binary}` or an existing `%ExWapp.Media.Upload{}`.
Supply already encoded MP4/WebP bytes; ExWapp does not transcode, generate
thumbnails or determine dimensions/duration. `gif_playback: true` sends an MP4
with GIF-style playback. Incoming videos and stickers expose a
`%ExWapp.Media.Ref{type: :video | :sticker}` that works with `download_media/3`.
Reactions arrive as messages with `content.kind == :reaction` and a `reaction`
map containing `message_id`, `chat_jid`, `from_me`, `participant`, `text`, and
`sender_timestamp_ms`. The key describes the target; the outer message describes
the reactor. Empty reaction text is a removal. These events are retained
separately; ExWapp does not aggregate reactions on the target message.

To request earlier history, use an existing message as the anchor:

```elixir
{:ok, history} = ExWapp.stream_messages(client, jid) # oldest first

case Enum.take(history, 1) do
  [anchor] -> ExWapp.request_history(client, jid, anchor, count: 50)
  [] -> {:error, :no_history_anchor}
end
```

The anchor must contain `id`, `from_me`, and `timestamp` in Unix **seconds**.
`count` defaults to 50, with a local bound of 1–1000. Success returns
`{:ok, updated_client, request_id}` when the encrypted request is sent to the
account's primary device. It does not mean the phone has returned history.
Responses use the existing asynchronous history import path; query the store
again after import. The phone may be offline, lack those messages, or return
fewer records. This API does not guarantee a complete account export.
Custom transport adapters receive `%ExWapp.Message{type: :history_request}`;
the built-in session handles peer routing and encryption.

### Validate the new APIs with the demo

The companion [demo_ex_wapp](https://github.com/elchemista/demo_ex_wapp/tree/ex-wapp-0.1.6-suite)
contains an interactive LiveView suite on `ex-wapp-0.1.6-suite`. Its Git
dependency pins a 0.1.6 commit; Mix fetches it without a separate library checkout.
For local library development, replace that dependency with
`{:ex_wapp, path: "../ex_wapp"}` and use `whatsmeow-update-0.1.6`.

From the demo directory, run `mix deps.get`, `mix precommit`, then
`mix phx.server`. The automated tests run offline. In the dashboard, pair a test
account, select a chat, and click **Run full messaging and history suite** to
send real fixtures and request older history.

| Feature | Interactive verification |
| --- | --- |
| Video | MP4 send, MP4 with GIF playback, inbound download and video preview |
| Stickers | Static and animated WebP sends, inbound download and image preview |
| Reactions | Add/remove on the same target with both server acknowledgements; decode inbound reactions/removals |
| History | Send an anchored request; separately observe account-level `ON_DEMAND` blob import |

Reply from WhatsApp to exercise inbound checks. A send acknowledgement does not
prove recipient delivery or rendering. History import events have no request ID,
so the demo cannot correlate a completed blob to a particular request or chat;
the import check may remain pending even after the request was sent successfully.

## Storage

ExWapp ships with two stores:

- `ExWapp.Store.Ets` for ETS-backed state with optional file persistence;
- `ExWapp.Store.Memory` for tests and short-lived usage.

Use a custom backend by implementing `ExWapp.Store`:

```elixir
client =
  ExWapp.new(
    session_id: "account_1",
    store: {MyApp.PostgresStore, account_id: "account_1"},
    transport: ExWapp.Client.Transport.Session
  )
```

The persisted built-in store format is a versioned, gzipped JSON envelope.
JSON implementation details are isolated behind `ExWapp.JSON`, so choosing a
different library does not change the on-disk format.

`ExWapp.Store.Ets` accepts `max_messages_per_chat`. Its default is unbounded;
choose a limit large enough for resend repair, receipt tracking, and media
retry requirements in your application.

### Incremental history persistence

The existing snapshot format remains the default. For a growing local archive,
opt into incremental history:

```elixir
store: {ExWapp.Store.Ets,
  path: "/var/lib/my_app/account.etf",
  history_storage: :incremental}
```

This keeps cryptographic state in the main snapshot and writes changed messages
to `account.etf.history`, with checksums, synchronous writes and periodic
compaction. Opening an existing snapshot in this mode preserves its original
bytes in `account.etf.pre-history` before publishing the new format. The
incremental marker is recognized on later opens even when the option is omitted.
A missing or corrupt history file fails explicitly; an incomplete final record
from an interrupted append is truncated to the last complete record.

Back up the main file **and** `.history` together while the session is stopped.
The `.pre-history` file is a migration backup, not a current backup.
If an existing migration backup differs from the source snapshot, migration stops
with `:snapshot_backup_conflict`; inspect and archive that backup before retrying.
Do not open an incremental store with an older ExWapp version. To return to snapshot storage,
export with `ExWapp.Store.Ets.load_path/1` and persist the result to a **new** store
using the default mode. Directory synchronization must be supported by the
filesystem; initialization or writes fail if it is unavailable.

The built-in adapter prevents duplicate opens of the same canonical path and
duplicate sessions sharing one store within a BEAM node. It does not coordinate
file access across independent BEAM nodes or machines: use a transactional
external adapter for that deployment. Message ID lookups use a secondary index.

Retention remains opt-in. `max_messages_per_chat: 5000` drops the oldest messages;
archive them first if needed. Retention is not secure erasure of backups or old
journal records awaiting compaction.

## Contacts, chats, and calls

```elixir
{:ok, contacts} = ExWapp.list_contacts(client)
{:ok, contact} = ExWapp.get_contact(client, jid)
{:ok, client} = ExWapp.create_contact(client, jid, "Alice")
{:ok, client} = ExWapp.sync_contacts(client)

{:ok, chats} = ExWapp.list_chats(client)
{:ok, groups} = ExWapp.list_groups(client)
{:ok, chat} = ExWapp.get_chat(client, jid)

{:ok, calls} = ExWapp.list_calls(client, status: :missed, limit: 20)
{:ok, call} = ExWapp.get_call(client, call_id)
```

Chat structs contain conversation metadata, not an embedded message list.
Messages are indexed separately and queried with the history functions above.
Call records contain signalling metadata only; ExWapp does not implement VoIP
audio/video or answer calls.

## Custom transports

`ExWapp.Client.Transport.Session` is the complete built-in transport. An
application can provide a different runtime by implementing
`ExWapp.Client.Transport`:

```elixir
defmodule MyApp.WhatsAppTransport do
  @behaviour ExWapp.Client.Transport

  def connect(client), do: {:ok, client}
  def disconnect(client), do: {:ok, client}
  def pair(client), do: {:ok, client, :pending}

  def send_message(client, %ExWapp.Message{} = message) do
    # Send with the runtime owned by your application.
    {:ok, client, message.id}
  end

  def receive_message(client, payload, _opts) do
    event = ExWapp.Event.new(:message_received, payload, session_id: client.session_id)
    {:ok, client, [event]}
  end
end
```

Low-level protocol modules such as `ExWapp.Noise`, `ExWapp.Signal`,
`ExWapp.Binary`, and `ExWapp.AppState.Engine` are implementation building
blocks for adapters and maintainers. They are not an alternative public
application API.

## Runtime configuration

Global defaults live under `config :ex_wapp, :runtime`. A client can override
them with its `:runtime` option:

```elixir
config :ex_wapp, :runtime, %{
  app_state: %{initial_sync_enabled: true},
  calls: %{max_records: 500}
}

client =
  ExWapp.new(
    runtime: [app_state: [initial_sync_enabled: false]],
    transport: ExWapp.Client.Transport.Session
  )
```

Disabling initial app-state sync can leave contacts and chat metadata
incomplete. It is mainly useful for send-only or externally persisted
integrations.

### Send safety and resource limits in 0.1.6

- A message ACK 429 starts the configured safety cool-off. ACK 401/403 suppresses
  that recipient temporarily; a connection-level forbidden response keeps its
  separate account-wide lock. Safety and daily quota state survive worker restarts
  with a persistent store.
- Retry, session repair and self-chat fallback preserve the message ID and the
  prepared protobuf, including quotes, mentions, media and reactions. They check
  the current safety state and throttle before resending, without charging the
  original message quota twice. Retained retry data is limited to 512 entries and
  16 MiB; media bytes are not cached. Evicted non-text payloads are not retried as
  captions.
- `throttle.on_limit: :delay` now waits for local rate limits, bounded by
  `max_delay_ms` and the send deadline. At most eight delayed sends / 16 MiB are
  queued. A rejected local admission consumes neither tokens nor quota.
- Stream replacement stops automatic reconnect. After stopping the conflicting
  instance, an explicit connect can retry without pairing again.
- Sends carry an absolute deadline checked immediately before transport. A
  `{:send_timeout, message_id}` error has an **unknown delivery outcome** if the
  transport was already invoked. Reconcile that ID before retrying; callers may
  supply `id:` to keep their own stable identifier.
- Stored delivered/read statuses cannot be downgraded by a late retry failure.
  Delivery events from concurrent workers can still arrive out of order; consumers
  should reconcile a conflicting failure event with the stored message status.
- Each session has at most 32 operation workers, four ordinary media operations,
  and two history-blob workers with a queue of 16 blobs. History requests have a
  60-second cooldown per chat and a separate one-per-second request budget.
  The phone's asynchronous history events are not correlated to a request ID.
- Downloads require HTTPS and validated encryption metadata. Known WhatsApp/CDN
  domains and hosts returned by authenticated `media_conn` are accepted;
  redirects are rejected. Reads have a shared deadline (60 seconds by default,
  connect timeout at most 10 seconds) and an actual-body cap. Local media sources
  and plaintext downloads default to a 64 MiB cap, adjustable with `max_bytes:`.
  Unencrypted downloads require explicit `allow_plaintext: true` and a SHA-256
  hash. `allowed_media_origins:` is an explicit trust override for controlled
  HTTPS endpoints, including integration fixtures.
- History decompression stops at 128 MiB and rejects compressed inputs over
  64 MiB. Imported messages retain media, reactions and structured content.
  Synthetic `history-sync-...` IDs cannot be used as phone-history anchors.

Incoming reaction `from_me` / `chat_jid` fields describe the target key as sent
by the reacting device; they are not a normalized local-account direction.

The configuration sections `compliance`, `adaptive_governor`, `risk`, `canary`,
`release_gates`, `auth_guard`, `protocol_health`, `hygiene`, and `enforcement`
are **reserved**, not additional implemented protections. Non-default values
produce a warning. The exception is `release_gates.remote_kill_switch: true`,
which blocks sends; the library does not fetch a remote switch service.
These controls reduce accidental traffic and resource growth; they do not
guarantee protection against account bans.

## Observability and security

ExWapp instrumentation is disabled by default. To use the Erlang `:telemetry`
backend, declare `{:telemetry, "~> 1.2"}` in your application's dependencies and
enable it explicitly:

```elixir
config :ex_wapp, :telemetry_adapter, :telemetry
```

`ExWapp.Telemetry.events/0` lists the canonical events. Use
`ExWapp.Telemetry.attach_many/3` and `detach/1` to manage their handlers.
High-level client events can additionally be forwarded with
`events: ExWapp.Events.Telemetry`.

For another metrics system, configure a module implementing
`ExWapp.Telemetry.Adapter` instead of `:telemetry`. Only
`execute(event_name, measurements, metadata)` is required; it should return
`:ok` promptly. `attach_many/4` and `detach/1` are optional. The helpers return
an explicit error when handler management is unavailable. Event emission is
best effort: backend errors do not interrupt sessions, sends, or persistence.
Setting `:telemetry_adapter` to `nil` disables ExWapp instrumentation, including
`ExWapp.Events.Telemetry`. This setting does not control WebSockex's own events.

The library redacts known secrets from its own logs, but application logs,
crash dumps, store files, and custom event handlers may still contain phone
numbers, message content, identity keys, or session material. Protect persisted
stores and avoid logging raw protocol payloads in production.

## Documentation map

- [HexDocs](https://hexdocs.pm/ex_wapp) contains generated module and function
  documentation.
- [`docs/architecture.md`](docs/architecture.md) describes boundaries and data
  flow.
- [`docs/design-decisions.md`](docs/design-decisions.md) records the main
  engineering choices and their consequences.
- [`docs/protocol-flow.md`](docs/protocol-flow.md) follows connection, Noise,
  authentication, Signal, messaging, recovery, and synchronization.
- [`docs/protocol-reference.md`](docs/protocol-reference.md) records the
  maintained addressing, wire, encryption, ACK, retry, and call invariants.
- [`docs/strengths-and-limitations.md`](docs/strengths-and-limitations.md)
  gives an evidence-based assessment of the library today.
- [`examples/gen_server_session.ex`](examples/gen_server_session.ex) shows an
  application-owned GenServer around `%ExWapp.Client{}`.

Generated protobuf modules live in `lib/ex_wapp/wa_proto/`. Do not edit them by
hand; `scripts/update_wa_protos.sh` regenerates the complete snapshot.

## Development

The same checks used in CI can be run locally:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix test --cover
mix credo --strict
mix dialyzer
MIX_ENV=dev mix docs --warnings-as-errors
mix hex.build
```

Pull requests and pushes to `main` run tests on Elixir 1.19/OTP 28 and Elixir
1.20/OTP 29. Credo and Dialyzer run as separate required checks.

The coverage configuration excludes the generated `WA*` Protox modules. Those
modules are validated by schema, wire-compatibility, and round-trip tests;
including every generated line would measure the size of the protocol snapshot
rather than the maintained ExWapp implementation. CI rejects maintained-code
coverage below 90%.

Protocol integration tests exchange authenticated Noise and Signal messages with
local peers, exercise HTTP/HTTPS and WebSocket servers, and verify persistence
and recovery after failures. They run without a WhatsApp account. The HTTPS
tests require `openssl` to generate a temporary certificate authority and server
certificate; certificate verification remains enabled.

### Publishing 0.1.6 to Hex

The release version is defined once in `mix.exs`; the installation example,
changelog and documentation source links use the same `0.1.6` version.
The Git tag `v0.1.6` must identify the source commit being published.
After the checks above, maintainers can inspect the local package and perform
a publish dry run before uploading the package and documentation:

```bash
mix hex.build
mix hex.publish --dry-run
mix hex.publish
```

The package includes source, generated protocol modules, documentation,
the supervised-session example and license. It excludes local dependencies,
compiled output, tests, logs and account/session stores. The generated
`ex_wapp-0.1.6.tar` is a local build artifact and is ignored by Git.

## License

Apache License 2.0. See the
[`LICENSE`](https://github.com/elchemista/ex_wapp/blob/main/LICENSE) file.

## Disclaimer

ExWapp is an unofficial, independent project. It is not affiliated with,
authorized, maintained, sponsored, or endorsed by WhatsApp or Meta. WhatsApp
and Meta are trademarks of their respective owners.

Using an unofficial client may violate WhatsApp's terms or trigger automated
abuse controls. A phone number or account can be temporarily suspended or
permanently banned. Use a dedicated test number, avoid spam and automation that
harms users, comply with applicable terms and laws, and use this library at
your own risk. The maintainers cannot guarantee continued protocol access or
account safety.

WhatsApp's official [Messaging Guidelines](https://www.whatsapp.com/legal/messaging-guidelines/)
address unofficial clients, bulk or automated messaging, spam, and harmful
automation, and describe enforcement that can include temporary or permanent
account suspension. Commercial messaging is also subject to the
[WhatsApp Business Messaging Policy](https://business.whatsapp.com/policy/),
including recipient opt-in, opt-out handling, approved-template, and customer
service-window requirements. Policies can change; users are responsible for
reviewing and complying with their current versions.
