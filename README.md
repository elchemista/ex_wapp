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
- optional low-level `ExWapp.Client.Transport.WebSocket`
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

ExWapp also ships a lower-level WebSocket transport layer:

```elixir
client =
  ExWapp.new(
    session_id: "account_1",
    store: {ExWapp.Store.Ets, path: "/tmp/ex_wapp/account_1.etf"},
    transport: ExWapp.Client.Transport.WebSocket,
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
transport encryption/decryption, and binary node encode/decode. It does not
replace the full session send path; use `ExWapp.Client.Transport.Session` when
you want complete sending and receiving.

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
```

Group JIDs use the same API. When the target ends in `@g.us`, the session
transport uses the group sender-key path:

```elixir
ExWapp.send_message(client, to: "123456789@g.us", text: "team update")
ExWapp.send_image(client, "123456789@g.us", {:bytes, image_bytes}, mimetype: "image/png")
```

## Contacts and Chats

Contacts and chats are exposed through the runtime-neutral client facade:

```elixir
{:ok, contacts} = ExWapp.list_contacts(client)
{:ok, contact} = ExWapp.get_contact(client, "15550001111@s.whatsapp.net")
{:ok, client} = ExWapp.sync_contacts(client)

{:ok, chats} = ExWapp.list_chats(client)
{:ok, groups} = ExWapp.list_groups(client)
{:ok, group} = ExWapp.get_chat(client, "123456789@g.us")
```

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
