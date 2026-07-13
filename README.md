# ExWapp

Runtime-neutral WhatsApp Web protocol library for Elixir.

ExWapp is shaped like a typical adapter-based Elixir library: it provides
high-level functions, message structs, protocol helpers, stores, behaviours,
and an optional built-in session transport. Your application can use the built-in
runtime, or replace it with its own GenServer, GenStateMachine, socket, queue,
and subscription strategy.

## Status

The library is protocol-sensitive and experimental. The recommended API is the
runtime-neutral `%ExWapp.Client{}` API.

Kept as library responsibilities:

- high-level `ExWapp.new/1`, `connect/1`, `pair/1`, `send_message/2`,
  `receive_message/3`
- built-in `ExWapp.Client.Transport.Session` for real WhatsApp send/receive
- optional low-level `ExWapp.Transport.WebSocket` for protocol diagnostics
- message builders via `ExWapp.Message`
- store behaviour and built-in stores
- event and transport behaviours
- Noise, Signal, binary node, protobuf, app-state, pairing, JID, chat/contact
  protocol modules

Still controlled by your application:

- whether to use the built-in session worker or your own process
- supervision and long-lived account ownership
- PubSub/subscription policy
- reconnect and queue policy
- multi-account orchestration

## Installation

```elixir
def deps do
  [
    {:ex_wapp, path: "path/to/ex_wapp"}
  ]
end
```

## Quickstart

Use the built-in session transport for real WhatsApp communication:

```elixir
client =
  ExWapp.new(
    session_id: "account_1",
    store: {ExWapp.Store.Ets, path: "/tmp/ex_wapp/account_1.etf"},
    transport: ExWapp.Client.Transport.Session,
    events: MyApp.WhatsAppEvents
  )

{:ok, client} = ExWapp.connect(client)

{:ok, client, message_id} =
  ExWapp.send_message(client,
    to: "393XXXXXXXXX@s.whatsapp.net",
    text: "hello"
  )

session = client.metadata.session_pid
messages = ExWapp.Session.message_stream(session)
```

The returned client is regular data. With the session transport, the worker pid
is stored at `client.metadata[:session_pid]`; keep the client in your own
GenServer state, GenStateMachine data, task state, ETS, or plain functional
flow.

Pairing returns the first QR event when one is available:

```elixir
{:ok, client, {:code, qr_code}} = ExWapp.pair(client)
```

If you only want protocol helpers and no built-in runtime, configure your own
transport adapter.

## Which API To Use

ExWapp exposes three practical layers:

- `ExWapp`: runtime-neutral client facade. Use this when your application owns
  the runtime and you want a stable, adapter-based API.
- `ExWapp.Session`: direct GenServer API for the built-in session worker. Use
  this when you want to work with the built-in runtime directly.
- lower-level protocol modules like `ExWapp.Messages`, `ExWapp.Signal`,
  `ExWapp.Noise`, and `ExWapp.AppState.Engine`: use these when you are building
  your own transport/runtime or debugging protocol internals.

For most applications, start with `ExWapp.new/1`, `connect/1`, `pair/1`,
`send_message/2`, and `download_media/3`.

## High-Level Client API

`ExWapp` is the main public facade. It wraps the configured transport and keeps
the public API consistent whether you use the built-in session worker or a
custom runtime.

Common functions:

- connection lifecycle: `new/1`, `connect/1`, `pair/1`, `disconnect/1`
- sending: `send_message/2`, `send_image/4`, `send_audio/4`,
  `send_document/4`, `send_location/5`, `send_contact/5`, `send_event/5`
- inbound processing: `receive_message/3`
- media download: `download_media/3`
- local data access: `list_contacts/1`, `get_contact/2`, `sync_contacts/1`,
  `create_contact/3`, `delete_contact/2`, `list_chats/1`, `list_groups/1`,
  `get_chat/2`
- diagnostics: `status/1`, `last_error/1`, `diagnostics/1`

Example:

```elixir
client =
  ExWapp.new(
    session_id: "account_1",
    store: {ExWapp.Store.Ets, path: "/tmp/ex_wapp/account_1.etf"},
    transport: ExWapp.Client.Transport.Session,
    events: ExWapp.Events.Telemetry
  )

{:ok, client} = ExWapp.connect(client)
{:ok, client, {:code, qr}} = ExWapp.pair(client)

{:ok, client, message_id} =
  ExWapp.send_message(client,
    to: "393XXXXXXXXX@s.whatsapp.net",
    text: "hello from ExWapp"
  )

{:ok, chats} = ExWapp.list_chats(client)
status = ExWapp.status(client)
diag = ExWapp.diagnostics(client)
```

## Built-In Session Transport

`ExWapp.Client.Transport.Session` wraps the full session engine. This is the
path that handles:

- WebSocket and Noise connection lifecycle
- QR/auth pairing and session persistence
- Signal sessions, prekeys, device fanout, and group sender keys
- binary node encode/decode
- inbound message decode, storage, and subscriber delivery
- logs and telemetry under `[:ex_wapp, :session, ...]`

Incoming messages can be consumed directly:

```elixir
{:ok, client} = ExWapp.connect(client)
session = client.metadata.session_pid

for {jid, message} <- ExWapp.Session.message_stream(session) do
  IO.inspect({jid, message})
end
```

## Direct Session API

If you want to call the built-in worker directly instead of going through the
runtime-neutral client facade, use `ExWapp.Session`.

```elixir
{:ok, session} =
  ExWapp.Session.start_link(
    session_id: "account_1",
    store: ExWapp.Store.new({ExWapp.Store.Ets, path: "/tmp/ex_wapp/account_1.etf"})
  )

:ok = ExWapp.Session.connect(session)
{:ok, _ref} = ExWapp.Session.subscribe_messages(session)

{:ok, message_id} =
  ExWapp.Session.send_text(session, "393XXXXXXXXX@s.whatsapp.net", "hello")

{:ok, image_id} =
  ExWapp.Session.send_image(session, "393XXXXXXXXX@s.whatsapp.net", {:path, "photo.jpg"},
    mimetype: "image/jpeg",
    caption: "a photo"
  )

{:ok, audio_id} =
  ExWapp.Session.send_audio(session, "393XXXXXXXXX@s.whatsapp.net", {:path, "voice.ogg"},
    mimetype: "audio/ogg; codecs=opus",
    ptt: true
  )
```

`ExWapp.Session` also exposes:

- streams and subscriptions: `subscribe_qr/1`, `subscribe_messages/1`,
  `qr_stream/1`, `message_stream/1`
- status and runtime info: `state/1`, `stats/1`, `runtime_config/1`,
  `policy_status/1`, `health_status/1`
- server-synced operations: `archive_chat/2`, `unarchive_chat/2`,
  `delete_chat/2`, `create_contact/3`, `delete_contact/2`, `sync_contacts/1`

## Transport Adapter

The transport adapter is where your app connects ExWapp to its runtime.

```elixir
defmodule MyApp.WhatsAppTransport do
  @behaviour ExWapp.Client.Transport

  def connect(client) do
    # Open or attach to your socket/session runtime.
    {:ok, client}
  end

  def pair(client) do
    # Run your pairing flow and return a QR payload/update.
    {:ok, client, "qr-payload"}
  end

  def send_message(client, %ExWapp.Message{} = message) do
    # Use ExWapp protocol modules or your runtime to send the message.
    {:ok, client, message.id}
  end

  def receive_message(client, payload, _opts) do
    event = ExWapp.Event.new(:message_received, payload, session_id: client.session_id)
    {:ok, client, [event]}
  end
end
```

Event names are intentionally not duplicated in this README. To see the
canonical high-level event type definition, check `ExWapp.Event.type/0` in
`lib/ex_wapp/event.ex`. `ExWapp.Event.new/3` accepts those documented event
types and any custom atom your application wants to route through its own event
adapter. To see which events ExWapp emits internally, search for
`Event.new(` and `emit_client_event(` in `lib/`. For telemetry event names, use
`ExWapp.Telemetry.events/0` or check `lib/ex_wapp/telemetry.ex`.

In IEx:

```elixir
t ExWapp.Event.type
ExWapp.Telemetry.events()
```

ExWapp also ships a raw diagnostic WebSocket adapter:

```elixir
client =
  ExWapp.new(
    session_id: "account_1",
    store: {ExWapp.Store.Ets, path: "/tmp/ex_wapp/account_1.etf"},
    transport: ExWapp.Client.Transport.RawWebSocket,
    metadata: %{
      owner: self(),
      websocket: [
        url: "wss://web.whatsapp.com/ws/chat"
      ]
    }
  )

{:ok, client} = ExWapp.connect(client)

receive do
  {:ex_wapp_transport, {:handshake, :started}} -> :ok
  {:ex_wapp_transport, {:node, node}} -> IO.inspect(node)
  {:ex_wapp_transport, {:error, reason}} -> IO.inspect(reason, label: "transport error")
end
```

`ExWapp.Transport.WebSocket` handles WebSocket framing, Noise handshake,
transport encryption/decryption, and binary node encode/decode. The diagnostic
adapter deliberately rejects `ExWapp.send_message/2`: a raw socket does not
provide Signal sessions, linked-device fanout, sender keys, retry, or state
synchronization. Use `ExWapp.Client.Transport.Session` for complete sending
and receiving. The old `ExWapp.Client.Transport.WebSocket` adapter name is
deprecated in favor of `RawWebSocket`.

## Event Adapter

Events are runtime-neutral. Emit them however your application wants:

```elixir
defmodule MyApp.WhatsAppEvents do
  @behaviour ExWapp.Events

  def emit(_client, event) do
    Phoenix.PubSub.broadcast(MyApp.PubSub, "whatsapp", event)
  end
end
```

For a CLI or tests, use the default `ExWapp.Events.Noop` or send events to the
calling process.

Telemetry is available through `ExWapp.Telemetry`:

```elixir
:ok =
  ExWapp.Telemetry.attach_many(
    "my-handler",
    fn event, measurements, metadata, _config ->
      IO.inspect({event, measurements, metadata})
    end
  )
```

To forward high-level ExWapp events to telemetry, configure:

```elixir
client = ExWapp.new(events: ExWapp.Events.Telemetry, transport: MyTransport)
```

High-level operations also log at the client boundary:

- `debug` when an operation starts
- `info` when it succeeds
- `error` when it fails or raises

## Wrapper Module

You can define a small application wrapper with default adapters:

```elixir
defmodule MyApp.WhatsApp do
  use ExWapp.Client,
    store: {ExWapp.Store.Ets, path: "/tmp/ex_wapp/account_1.etf"},
    transport: MyApp.WhatsAppTransport,
    events: MyApp.WhatsAppEvents
end

client = MyApp.WhatsApp.new(session_id: "account_1")
{:ok, client} = MyApp.WhatsApp.connect(client)
{:ok, client, id} = MyApp.WhatsApp.send_message(client, to: jid, text: "hello")
```

The macro only generates thin forwarding helpers. It does not start processes.

## GenServer Example

See `examples/gen_server_session.ex` for a complete application-owned GenServer
that embeds `%ExWapp.Client{}` in its state.

The important pattern is:

```elixir
def handle_call({:send_text, to, text}, _from, state) do
  case ExWapp.send_message(state.client, to: to, text: text) do
    {:ok, client, message_id} ->
      {:reply, {:ok, message_id}, %{state | client: client}}

    {:error, error, client} ->
      {:reply, {:error, error}, %{state | client: client}}
  end
end
```

## Stores

ExWapp keeps the store behaviour first-class. Built-in stores include:

- `ExWapp.Store.Memory`
- `ExWapp.Store.Ets`

Create custom stores by implementing `ExWapp.Store`.

```elixir
client =
  ExWapp.new(
    store: {MyApp.PostgresStore, account_id: "account_1"},
    transport: MyApp.WhatsAppTransport
  )
```

## Messages

Use keyword options or explicit message structs:

```elixir
ExWapp.send_message(client, to: jid, text: "hello")

message = ExWapp.Message.text(jid, "hello", mentions: ["123@s.whatsapp.net"])
ExWapp.send_message(client, message)

typing = ExWapp.Message.typing(jid, true)
ExWapp.send_message(client, typing)

receipt = ExWapp.Message.read_receipt(jid, ["MSG_ID"])
ExWapp.send_message(client, receipt)

ExWapp.send_image(client, jid, {:path, "photo.jpg"}, mimetype: "image/jpeg", caption: "hello")
ExWapp.send_audio(client, jid, {:path, "voice.ogg"},
  mimetype: "audio/ogg; codecs=opus",
  ptt: true
)

ExWapp.send_document(client, jid, {:path, "contract.pdf"},
  mimetype: "application/pdf",
  caption: "Contract"
)

ExWapp.send_location(client, jid, 45.4642, 9.1900,
  name: "Milano",
  address: "Milano, Italy"
)

vcard = ExWapp.Contact.vcard("Mario Rossi", "+393331234567")
ExWapp.send_contact(client, jid, "Mario Rossi", vcard)

# EventMessage is supported by WhatsApp Web but is less stable than the other types.
ExWapp.send_event(client, jid, "Project meeting", DateTime.utc_now(),
  description: "Weekly review",
  end_time: DateTime.add(DateTime.utc_now(), 3600, :second)
)
```

`ExWapp.Message` is the user-facing message builder module. It returns a small
runtime-neutral struct that adapters and transports can send later:

- `ExWapp.Message.text/3`
- `ExWapp.Message.typing/3`
- `ExWapp.Message.read_receipt/3`
- `ExWapp.Message.image/3`
- `ExWapp.Message.audio/3`
- `ExWapp.Message.document/3`
- `ExWapp.Message.location/4`
- `ExWapp.Message.contact/4`
- `ExWapp.Message.event/4`

`ExWapp.Messages` is a lower-level helper used by the session worker. It builds
protobuf payloads, message IDs, context info, resend requests, and binary nodes.
Use it when you are writing your own transport or debugging the wire format.

Group JIDs use the same API. When the target ends in `@g.us`, the session
transport uses the group sender-key path:

```elixir
ExWapp.send_message(client, to: "123456789@g.us", text: "team update")
ExWapp.send_image(client, "123456789@g.us", {:bytes, image_bytes}, mimetype: "image/png")
```

## Media

Media sending and receiving is split into a small public API plus focused
implementation modules.

Most applications only need:

- `ExWapp.send_image/4`
- `ExWapp.send_audio/4`
- `ExWapp.send_document/4`
- `ExWapp.download_media/3`
- `ExWapp.Media.read_source/1`
- `ExWapp.Media.ref_from_upload/2`

Media source forms accepted by the public API:

- `{:path, "/path/to/file"}`
- `{:bytes, binary}`
- `%ExWapp.Media.Upload{}` when you already have uploaded media metadata

Downloading inbound media:

```elixir
{:ok, client, download} =
  ExWapp.download_media(client, media_ref)

File.write!("/tmp/out.bin", download.bytes)
```

Inbound messages expose one canonical, already-decoded content value:

```elixir
case message.content do
  %ExWapp.Message.Content{kind: :text, text: text} ->
    {:text, text}

  %ExWapp.Message.Content{kind: :media, media: media, media_type: type} ->
    {:media, type, media}

  %ExWapp.Message.Content{kind: kind} when kind in [:location, :contact, :event] ->
    {kind, message.content}
end
```

Wrappers should branch on `message.content.kind`; they do not need to parse
protobuf or infer image, audio, document, location, contact, or event formats.
The legacy projections remain available during migration:

```elixir
message.media     # %ExWapp.Media.Ref{} for image/audio/document
message.location  # latitude, longitude, name, address, ...
message.contact   # display_name, vcard, is_self_contact
message.event     # name, start_time, end_time, location, ...
```

Pass `message.content.media` (or the compatible `message.media`) to
`ExWapp.download_media/3` to fetch, verify, and decrypt the original bytes.
ExWapp does not transcode audio: a WhatsApp voice note should normally be
supplied as Opus in an OGG container.

Media modules:

- `ExWapp.Media`: public entry point
- `ExWapp.Media.HTTP`: upload/download transport helpers
- `ExWapp.Media.Crypto`: WhatsApp media encryption and decryption
- `ExWapp.Media.Ref`: reusable reference for inbound/outbound media
- `ExWapp.Media.Upload`: uploaded media metadata returned by the upload flow
- `ExWapp.Media.Download`: decrypted media payload returned by downloads

## Contacts and Chats

Contacts and chats are exposed through the runtime-neutral client facade:

```elixir
{:ok, contacts} = ExWapp.list_contacts(client)
{:ok, contact} = ExWapp.get_contact(client, "15550001111@s.whatsapp.net")
{:ok, client} = ExWapp.sync_contacts(client)
{:ok, client} = ExWapp.create_contact(client, "15550001111@s.whatsapp.net", "Alice")
{:ok, client} = ExWapp.delete_contact(client, "15550001111@s.whatsapp.net")

{:ok, chats} = ExWapp.list_chats(client)
{:ok, groups} = ExWapp.list_groups(client)
{:ok, group} = ExWapp.get_chat(client, "123456789@g.us")
```

Implementation notes:

- `ExWapp.Contact` is the public contact struct plus CRUD helpers
- `ExWapp.Chat` is the public chat/message store API
- contacts are updated from app-state sync, history sync, and inbound push-name metadata
- chats are updated from outbound sends, inbound messages, receipts, and app-state mutations

When you use the built-in session transport, these modules read and write the
configured store directly, so they are useful both at runtime and in tests.

## How It Works

At a high level, the built-in session flow looks like this:

1. `ExWapp.connect/1` or `ExWapp.Session.connect/1` opens the WebSocket and runs
   the Noise handshake.
2. `pair/1` starts QR/device-link flow when the account is not yet registered.
3. outbound messages are built as `%ExWapp.Message{}` values, translated into
   protobufs by `ExWapp.Messages`, and then encrypted per target device.
4. the session worker resolves device fanout with USync and prekey fetches,
   then sends WhatsApp binary nodes over the encrypted transport.
5. inbound nodes are routed through `ExWapp.MessageHandler`, which delegates to
   focused handler modules for messages, receipts, notifications, status, and
   low-level wire parsing.
6. contacts, chats, Signal sessions, app-state versions, and related metadata
   are persisted through the configured `ExWapp.Store`.
7. events and telemetry are emitted so the application can react without being
   tightly coupled to the internal worker implementation.

Relevant flow documents in this repository:

- `FLOW.md` for the WebSocket/Noise/session flow
- `SPEC.md` for protocol and addressing rules

## Protocol Modules

Advanced users and adapters can use lower-level modules directly:

- `ExWapp.Binary`
- `ExWapp.Noise`
- `ExWapp.Signal`
- `ExWapp.Pairing`
- `ExWapp.Messages`
- `ExWapp.MessageHandler`
- `ExWapp.AppState.Engine`
- `ExWapp.Transport.Frame`

These modules are building blocks. The public entry point remains the high-level
client API.

## Module Guide

Use this section as a map of the current codebase.

Core public entry points:

- `ExWapp`: runtime-neutral client facade
- `ExWapp.Client`: client struct and `use ExWapp.Client` wrapper macro
- `ExWapp.Session`: direct built-in session API
- `ExWapp.Message`: user-facing outbound message builders
- `ExWapp.Media`: user-facing media helpers
- `ExWapp.Contact`: public contact struct and repository facade
- `ExWapp.Chat`: public chat/message store API
- `ExWapp.Event`, `ExWapp.Events`, `ExWapp.Telemetry`: events and observability

Built-in transport/runtime:

- `ExWapp.Client.Transport.Session`: full WhatsApp session transport
- `ExWapp.Client.Transport.RawWebSocket`: raw diagnostic adapter; it rejects
  high-level message sending
- `ExWapp.Client.Transport.WebSocket`: deprecated compatibility name for the
  raw diagnostic adapter
- `ExWapp.Session.Worker`: main GenServer implementation
- `ExWapp.Session.Worker.Outbound`: outgoing send path
- `ExWapp.Session.Worker.Inbound`: incoming message/event helpers
- `ExWapp.Session.InboundRouter`, `ExWapp.Session.IQ`, `ExWapp.Session.MessageNode`,
  `ExWapp.Session.Targets`: focused helpers used by the worker

Message parsing and routing:

- `ExWapp.MessageHandler`: high-level inbound router
- `ExWapp.Message.Handler.Inbound`: thin incoming-message orchestrator
- `ExWapp.Message.Handler.Inbound.Content`: maps decrypted plaintext to the
  canonical `ExWapp.Message.Content` contract
- `ExWapp.Message.Handler.Receipt`: delivery/read receipt handling
- `ExWapp.Message.Handler.Notification`: notification and sync events
- `ExWapp.Message.Handler.Status`: presence and chat-state handling
- `ExWapp.Message.Handler.Wire`: compatible facade for envelope and wire helpers
- `ExWapp.Message.Handler.Wire.Fields`: generic protobuf primitives
- `ExWapp.Message.Handler.Wire.ContentDecoder`: pure supported-content decoder
- `ExWapp.Message.Handler.Ack`, `ExWapp.Message.Handler.Common`: shared handler utilities

Protocol internals:

- `ExWapp.Noise`, `ExWapp.Noise.Handshake`, `ExWapp.Noise.Engine`: Noise handshake and transport crypto
- `ExWapp.Signal`, `ExWapp.Signal.Encryption`, `ExWapp.Signal.SessionStore`,
  `ExWapp.Signal.SenderKey`, `ExWapp.Signal.WireFormat`: Signal/Session/SenderKey logic
- `ExWapp.Pairing`, `ExWapp.Pairing.ADV`: QR registration and ADV payload handling
- `ExWapp.Binary`, `ExWapp.Transport.Frame`, `ExWapp.Transport.WebSocket`: binary node and frame encoding

Server-synced app state:

- `ExWapp.AppState.Engine`: public app-state facade
- `ExWapp.AppState.Engine.Builders`: build outgoing patch descriptions
- `ExWapp.AppState.Engine.Codec`: encode/decode and hash-chain validation
- `ExWapp.AppState.Engine.Sync`: fetch/apply collections and external blobs
- `ExWapp.AppState.Engine.Dispatch`: apply decoded mutations to contacts/chats
- `ExWapp.AppState.Engine.State`: persist app-state versions and mutation MACs

Storage:

- `ExWapp.Store`: store behaviour and adapter entry point
- `ExWapp.Store.Ets`, `ExWapp.Store.Memory`: built-in stores
- `ExWapp.Store.Codec`: on-disk codec helpers for persisted store data

## Diagnostics

```elixir
ExWapp.status(client)
ExWapp.last_error(client)
ExWapp.diagnostics(client)
```

Errors are structured:

```elixir
{:error,
 %ExWapp.Error{
   operation: :send_message,
   phase: :transport,
   reason: reason
 },
 client}
```
