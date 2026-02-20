# ExWapp Architecture

> Reference document for porting the WhatsApp Web client library to another platform (e.g. Telegram).
> Covers every layer: OTP supervision tree, process model, data structures, types, behaviours, and full message flows.

---

## Table of Contents

1. [High-Level Overview](#1-high-level-overview)
2. [OTP Supervision Tree](#2-otp-supervision-tree)
3. [Process Model](#3-process-model)
4. [Module Map](#4-module-map)
5. [Behaviours](#5-behaviours)
6. [Core Data Structures & Types](#6-core-data-structures--types)
7. [Transport Layer](#7-transport-layer)
8. [Noise Handshake Layer](#8-noise-handshake-layer)
9. [Binary Protocol Layer](#9-binary-protocol-layer)
10. [Pairing Flow](#10-pairing-flow)
11. [Signal Encryption Layer](#11-signal-encryption-layer)
12. [Session Worker State Machine](#12-session-worker-state-machine)
13. [Inbound Message Flow](#13-inbound-message-flow)
14. [Outbound Message Flow](#14-outbound-message-flow)
15. [PubSub & Subscription Model](#15-pubsub--subscription-model)
16. [Store / Persistence Layer](#16-store--persistence-layer)
17. [App State Sync](#17-app-state-sync)
18. [Telemetry](#18-telemetry)
19. [Porting Guide for Telegram](#19-porting-guide-for-telegram)

---

## 1. High-Level Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                      Your Application                            │
│  ExWapp.Session.Supervisor.start_session("user_id", store: ...) │
│  ExWapp.Session.connect(session)                                 │
│  ExWapp.Session.send_text(session, jid, "hello")                │
│  ExWapp.Session.message_stream(session) |> Enum.each(...)       │
└───────────────────────────┬──────────────────────────────────────┘
                            │ Public API (ExWapp.Session)
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│               ExWapp.Session.Worker (GenServer)                  │
│  State machine: idle → connecting → handshaking → connected      │
│  Owns: store, pairing state, signal sessions, pending IQs        │
│  Spawns: OutboundQueue, InboundRouter, Task.Supervisor           │
└──────┬───────────────────────────────────────┬────────────────────┘
       │ enqueue_node                          │ receives events
       ▼                                       ▼
┌──────────────────┐               ┌───────────────────────────────┐
│ OutboundQueue    │               │ InboundRouter (GenServer)     │
│ (GenServer)      │               │ Decouples burst ingestion     │
│ Serialises sends │               │ from session processing       │
│ Queues while     │               └───────────────────────────────┘
│ disconnected     │
└──────┬───────────┘
       │ transport.send_node/2
       ▼
┌──────────────────────────────────────────────────────────────────┐
│               ExWapp.Conn (WebSockex GenServer)                  │
│  WebSocket to wss://web.whatsapp.com/ws/chat                     │
│  Drives Noise XX handshake                                       │
│  Encrypts outgoing / decrypts incoming frames (AES-256-GCM)     │
│  Decodes binary frames → Binary.Node structs                     │
│  Sends {:connection_event, ...} to Session.Worker                │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. OTP Supervision Tree

```
ExWapp.Supervisor  (one_for_one)
├── Phoenix.PubSub          (name: ExWapp.PubSub)
├── Registry                (keys: :unique, name: ExWapp.Session.Registry)
└── ExWapp.Session.Supervisor  (DynamicSupervisor, strategy: one_for_one)
    ├── ExWapp.Session.Worker  [session_id: "user_1"]
    │   ├── ExWapp.Session.OutboundQueue  (GenServer, linked)
    │   ├── ExWapp.Session.InboundRouter  (GenServer, linked)
    │   ├── Task.Supervisor               (for send workers)
    │   └── ExWapp.Conn                   (WebSockex, monitored)
    └── ExWapp.Session.Worker  [session_id: "user_2"]
        └── ...
```

### Key Design Decisions

- **DynamicSupervisor** — sessions are started/stopped at runtime per user.
- **Registry** — sessions are looked up by `session_id` (any term, typically a string). Registered in `init/1` of the Worker.
- **`conn` is monitored, not linked** — Worker monitors `Conn` via `Process.monitor/1`. When `Conn` dies, the Worker receives `{:DOWN, ref, :process, pid, reason}` and handles reconnection logic.
- **`OutboundQueue` and `InboundRouter` are linked** — they die with the Worker and are restarted together.
- **Send workers are Tasks** — each outbound message spawns a `Task` under a `Task.Supervisor` to avoid blocking the GenServer during prekey fetching or IQ waiting.

---

## 3. Process Model

| Process | Module | Type | Role |
|---|---|---|---|
| Session Worker | `ExWapp.Session.Worker` | `GenServer` | Central coordinator, state machine |
| WebSocket conn | `ExWapp.Conn` | `WebSockex` | WebSocket + Noise layer |
| Outbound queue | `ExWapp.Session.OutboundQueue` | `GenServer` | Serialises outbound nodes |
| Inbound router | `ExWapp.Session.InboundRouter` | `GenServer` | Decouples inbound burst |
| Send workers | anonymous | `Task` | Per-message encryption + send |
| PubSub | `Phoenix.PubSub` | `GenServer` | Broadcast to subscribers |
| Registry | OTP Registry | ETS-backed | Session lookup by ID |

### Message Passing Conventions

```
Conn → Worker:            send(session_pid, {:connection_event, event})
InboundRouter → Worker:   send(session_pid, {:inbound_node, node})
Worker → Conn:            ExWapp.Transport.send_node(conn_pid, node)
Worker → OutboundQueue:   OutboundQueue.enqueue_node(queue_pid, node)
Worker → QR subscribers:  send(pid, {:ex_wapp_qr, ref, event})
Worker → msg subscribers: send(pid, {:ex_wapp_message, ref, jid, message})
PubSub → Worker:          Phoenix.PubSub on "ex_wapp:commands:<session_id>"
```

---

## 4. Module Map

### Public API

| Module | Role |
|---|---|
| `ExWapp.Session` | Facade — delegates everything to `Session.Worker` |
| `ExWapp.Session.Supervisor` | Start/stop/list sessions |

### Session Internals

| Module | Role |
|---|---|
| `ExWapp.Session.Worker` | GenServer, state machine, all coordination |
| `ExWapp.Session.OutboundQueue` | Serialised send queue with conn awareness |
| `ExWapp.Session.InboundRouter` | Burst-decoupling inbound router |
| `ExWapp.Session.IQ` | IQ stanza builders (prekey request, usync) |
| `ExWapp.Session.JIDUtils` | JID manipulation helpers |
| `ExWapp.Session.Account` | Account/device info helpers |
| `ExWapp.Session.MessageNode` | Outbound message node builder |
| `ExWapp.Session.Targets` | Resolves send targets (devices for a JID) |

### Transport

| Module | Role |
|---|---|
| `ExWapp.Transport` | Behaviour definition |
| `ExWapp.Conn` | Default implementation (WebSockex) |
| `ExWapp.Transport.Frame` | Frame encode/decode (3-byte length prefix) |

### Noise Protocol

| Module | Role |
|---|---|
| `ExWapp.Noise` | Public API: `init/1`, `handle_server_hello/2`, `encrypt/2`, `decrypt/2` |
| `ExWapp.Noise.Engine` | Pure Elixir Noise XX state machine |
| `ExWapp.Noise.ClientPayload` | Builds protobuf `ClientPayload` (login vs registration) |
| `ExWapp.Noise.Certificate` | Server certificate verification |

### Binary Protocol

| Module | Role |
|---|---|
| `ExWapp.Binary` | `encode/1`, `decode/1`, `unpack/1`, `raw/1` |
| `ExWapp.Binary.Node` | Core struct: `%{tag, attrs, content}` |
| `ExWapp.Binary.Raw` | Wrapper for raw binary content in nodes |
| `ExWapp.Binary.Encoder` | Token-based binary encoder |
| `ExWapp.Binary.Decoder` | Token-based binary decoder |
| `ExWapp.Binary.Token` | WhatsApp token dictionary (256 predefined strings) |

### Signal Protocol

| Module | Role |
|---|---|
| `ExWapp.Signal` | Bootstrap identity + prekey material |
| `ExWapp.Signal.Keys` | Curve25519 key generation, signing, verification |
| `ExWapp.Signal.Session` | X3DH session creation + Double Ratchet |
| `ExWapp.Signal.SessionStore` | In-memory Signal session registry |
| `ExWapp.Signal.Encryption` | High-level encrypt/decrypt for recipients |
| `ExWapp.Signal.SenderKey` | Group message sender key management |
| `ExWapp.Signal.WireFormat` | Signal wire format encode/decode |
| `ExWapp.Signal.PrekeyFetcher` | Fetches remote prekey bundles via IQ |
| `ExWapp.Signal.Native` | Rustler NIF wrapper (Curve25519, X3DH, encrypt) |

### Pairing

| Module | Role |
|---|---|
| `ExWapp.Pairing` | QR code generation, pair-device/pair-success handling |
| `ExWapp.Pairing.ADV` | Account Device Verification (ADV) parsing |

### App State Sync

| Module | Role |
|---|---|
| `ExWapp.AppState.Engine` | Encode/decode patches, build mutations, send via IQ |
| `ExWapp.AppState.Crypto` | HKDF key derivation for app state keys |
| `ExWapp.AppState.LTHash` | LT-Hash for app state version tracking |

### Domain

| Module | Role |
|---|---|
| `ExWapp.JID` | WhatsApp JID struct + parsing |
| `ExWapp.Chat` | Chat struct + CRUD against store |
| `ExWapp.Contact` | Contact struct + CRUD against store |
| `ExWapp.MessageHandler` | Dispatches incoming message/notification/receipt/ack nodes |
| `ExWapp.Prekeys` | Prekey upload IQ node builder |

### Infrastructure

| Module | Role |
|---|---|
| `ExWapp.Store` | Behaviour + dispatcher for persistence adapters |
| `ExWapp.Store.Ets` | ETS + file persistence adapter |
| `ExWapp.Store.Memory` | In-memory adapter (testing) |
| `ExWapp.Telemetry` | Telemetry event definitions + helpers |
| `ExWapp.MapPath` | Deep map path accessor |

---

## 5. Behaviours

### `ExWapp.Transport`

```elixir
@callback start_link(keyword()) :: GenServer.on_start()
@callback send_node(pid(), Binary.Node.t()) :: :ok | {:error, term()}
@callback restart_stream(pid()) :: :ok | {:error, term()}
```

Implemented by `ExWapp.Conn`. Swap for a mock in tests.

### `ExWapp.Store`

```elixir
@callback new(opts :: keyword()) :: t()
@callback load(store :: t()) :: {:ok, data()} | {:error, term()}
@callback persist(store :: t(), data :: data()) :: :ok | {:error, term()}
@callback clear(store :: t()) :: :ok | {:error, term()}
```

Implemented by `ExWapp.Store.Ets` (default) and `ExWapp.Store.Memory`.
Custom adapters (Postgres, Redis, etc.) implement this behaviour.

### `String.Chars` protocol

Implemented for `ExWapp.JID` — JIDs can be used in string interpolation.

---

## 6. Core Data Structures & Types

### `ExWapp.Binary.Node`

The fundamental unit of the WhatsApp binary protocol. Every message exchanged after the Noise handshake is a tree of nodes.

```elixir
%ExWapp.Binary.Node{
  tag:     String.t(),
  attrs:   %{String.t() => String.t() | integer() | JID.t()},
  content: nil
           | binary()        # UTF-8 text
           | Raw.t()         # raw binary blob (e.g. protobuf payload)
           | [Node.t()]      # child nodes
}
```

### `ExWapp.Binary.Raw`

```elixir
%ExWapp.Binary.Raw{data: binary()}
```

### `ExWapp.JID`

WhatsApp Jabber ID — identifies users, groups, and servers.

```elixir
%ExWapp.JID{
  user:        String.t(),             # phone number or group ID
  raw_agent:   non_neg_integer(),      # 0 for normal users
  device:      non_neg_integer(),      # 0 for primary device
  integrator:  non_neg_integer(),
  server:      String.t()
  # "s.whatsapp.net" | "g.us" | "broadcast" | "lid" | "msgr" | "interop"
}
```

String formats:
- User: `"1234567890@s.whatsapp.net"`
- User+device: `"1234567890:2@s.whatsapp.net"`
- Group: `"1234567890-1234567890@g.us"`
- Broadcast: `"status@broadcast"`

### `ExWapp.Noise.t()`

Noise protocol state — lives inside `ExWapp.Conn` state.

```elixir
%ExWapp.Noise{
  phase:                :handshake | :transport,
  handshake_ref:        term() | nil,
  static_key:           %{priv: binary(), pub: binary()} | nil,
  tx_key:               binary() | nil,
  rx_key:               binary() | nil,
  tx_counter:           non_neg_integer(),
  rx_counter:           non_neg_integer(),
  store:                Store.t() | nil,
  client_payload_fun:   function() | nil,
  certificate_verifier: function() | nil,
  pending_store_data:   map() | nil,
  handshake_hash:       binary() | nil,
  handshake_salt:       binary() | nil,
  cipher_ref:           term() | nil,
  handshake_header:     binary()
}
```

### `ExWapp.Session.Worker` state

```elixir
%ExWapp.Session.Worker{
  status:                          :idle | :connecting | :handshaking | :connected | :disconnected,
  store:                           Store.t() | nil,
  transport_mod:                   module(),
  pairing:                         Pairing.state(),
  conn:                            pid() | nil,
  conn_ref:                        reference() | nil,
  outbound_queue:                  pid() | nil,
  inbound_router:                  pid() | nil,
  send_worker_sup:                 pid() | nil,
  session_id:                      term() | nil,
  health_timer:                    reference() | nil,
  qr_subscribers:                  %{reference() => {pid(), reference()}},
  message_subscribers:             %{reference() => {pid(), reference()}},
  send_workers:                    %{pid() => binary()},
  send_worker_mons:                %{reference() => pid()},
  opts:                            keyword(),
  reconnect_attempts:              non_neg_integer(),
  last_disconnect_reason:          term() | nil,
  connected_at:                    DateTime.t() | nil,
  session_invalid:                 boolean(),
  pending_iqs:                     %{String.t() => %{from: GenServer.from(), timer: reference()}},
  signal_sessions:                 term() | nil,
  retry_counters:                  map(),
  outbound_confirmations:          map(),
  app_state_initial_sync_requested: boolean(),
  prekey_count_query_id:           String.t() | nil,
  stats: %{
    messages_sent:     non_neg_integer(),
    messages_received: non_neg_integer(),
    reconnects:        non_neg_integer(),
    errors:            non_neg_integer()
  }
}
```

### Signal types

```elixir
# Identity keypair (Curve25519)
@type identity_key :: %{public: binary(), private: binary()}

# Signed prekey
@type signed_prekey :: %{
  id:        pos_integer(),
  public:    binary(),
  private:   binary(),
  signature: binary()   # Ed25519 signature of public key
}

# One-time prekey
@type one_time_prekey :: %{id: pos_integer(), public: binary(), private: binary()}

# Persisted under :signal key in store
@type signal_state :: %{
  identity_key:     identity_key(),
  registration_id:  pos_integer(),
  device_id:        non_neg_integer(),
  signed_prekeys:   %{optional(pos_integer()) => signed_prekey()},
  prekeys:          %{optional(pos_integer()) => one_time_prekey()},
  next_prekey_id:   pos_integer(),
  sessions:         map(),
  updated_at:       integer()
}

# Signal session state (Double Ratchet)
@type session_state :: %{
  remote_identity_key: binary(),
  local_identity_key:  %{public: binary(), private: binary()},
  root_key:            binary(),
  sending_chain:       chain_state() | nil,
  receiving_chain:     chain_state() | nil,
  previous_counter:    non_neg_integer(),
  ratchet_key:         %{public: binary(), private: binary()} | nil,
  remote_ratchet_key:  binary() | nil
}

@type chain_state :: %{
  key:          binary(),
  counter:      non_neg_integer(),
  message_keys: %{non_neg_integer() => binary()}   # skipped message keys
}
```

### `ExWapp.Chat.t()` and `message()`

```elixir
%ExWapp.Chat{
  jid:                    String.t(),
  name:                   String.t() | nil,
  unread_count:           non_neg_integer(),
  last_message_timestamp: integer() | nil,
  pinned:                 boolean(),
  muted_until:            integer() | nil,
  archived:               boolean(),
  is_group:               boolean(),
  messages:               [message()]
}

@type message :: %{
  id:          String.t(),
  from_me:     boolean(),
  timestamp:   integer(),
  text:        String.t() | nil,
  status:      :pending | :sent | :received | :delivered | :read | :failed,
  participant: String.t() | JID.t() | nil,
  raw:         map() | nil
}
```

### `ExWapp.Contact.t()`

```elixir
%ExWapp.Contact{
  jid:          String.t(),
  lid:          String.t() | nil,
  full_name:    String.t() | nil,
  first_name:   String.t() | nil,
  push_name:    String.t() | nil,
  username:     String.t() | nil,
  phone_number: String.t() | nil
}
```

### Store data map (top-level keys)

```elixir
%{
  noise: %{
    static_private:   binary(),
    static_public:    binary(),
    handshake_hash:   binary(),
    handshake_salt:   binary(),
    server_static:    binary(),
    server_certificate: binary()
  },
  signal:   signal_state(),
  identity: %{public: binary(), private: binary()},
  adv_secret: binary(),          # 32-byte random secret for ADV
  pairing: %{
    device_identity: binary(),
    adv:             map(),
    adv_self_signed: binary(),
    device:          map(),
    biz:             map(),
    platform:        map(),
    paired_at:       integer(),
    signal:          signal_info()
  },
  client_info:              map(),
  chats:                    %{String.t() => Chat.t()},
  contacts:                 %{String.t() => Contact.t()},
  app_state_keys:           map(),
  app_state_versions:       map(),
  app_state_mutation_macs:  map()
}
```

### `ExWapp.AppState.Engine` types

```elixir
@type mutation_info :: %{
  required(:index)     => [String.t()],
  required(:version)   => integer(),
  required(:value)     => %SyncActionValue{},
  optional(:operation) => :remove
}

@type patch_info :: %{
  type:      String.t(),
  mutations: [mutation_info()],
  timestamp: integer() | nil
}

@type hash_state :: %{
  version: non_neg_integer(),
  hash:    binary()
}
```

---

## 7. Transport Layer

### Frame Format

```
First frame (client→server only):
  WA header: <<87, 65, 6, 5>>  ("WA" + version bytes)
  Immediately followed by first payload frame

Payload frame:
  3 bytes: big-endian length of payload
  N bytes: payload (encrypted ciphertext or handshake data)
```

`ExWapp.Transport.Frame` handles encode/decode of this framing.

### WebSocket Connection

- **URL**: `wss://web.whatsapp.com/ws/chat`
- **Origin**: `https://web.whatsapp.com`
- **Protocol**: binary WebSocket frames only
- **Library**: `WebSockex`

### `ExWapp.Conn` lifecycle

1. `start_link/1` — starts WebSockex, connects to WS URL
2. `handle_connect/2` — sends WA header + ClientHello (first Noise message)
3. `handle_frame/2` — receives binary frames, buffers partial data, dispatches complete frames
4. `handle_disconnect/2` — sends `{:connection_event, {:disconnected, reason}}` to session

---

## 8. Noise Handshake Layer

### Protocol

`Noise_XX_25519_AESGCM_SHA256`:
- **DH**: Curve25519 (X25519)
- **Cipher**: AES-256-GCM
- **Hash**: SHA-256
- **Prologue**: `"Noise_XX_25519_AESGCM_SHA256\x00\x00\x00\x00"`

### Handshake Sequence

```
Client                                     Server
  │── ClientHello (ephemeral pub key) ──────►│
  │   (protobuf HandshakeMessage)            │
  │                                          │
  │◄─ ServerHello (ephemeral, static_ct,    │
  │               cert_ct) ─────────────────│
  │   (protobuf HandshakeMessage)            │
  │                                          │
  │── ClientFinish (static_ct,              │
  │                payload_ct) ────────────►│
  │   (protobuf HandshakeMessage)            │
  │                                          │
  │◄══════ Transport (AES-256-GCM) ══════════│
```

After handshake, both sides derive `write_key` and `read_key` via HKDF.
All subsequent frames use AES-256-GCM with IV: `<<0::64, counter::big-32>>`.

### `ExWapp.Noise` public API

```elixir
Noise.init(opts)
  :: {:ok, client_hello_binary, Noise.t()} | {:error, term()}

Noise.handle_server_hello(state, payload)
  :: {:ok, client_finish_binary, Noise.t()} | {:error, term()}

Noise.encrypt(state, plaintext)
  :: {:ok, ciphertext, Noise.t()} | {:error, term()}

Noise.decrypt(state, ciphertext)
  :: {:ok, plaintext, Noise.t()} | {:error, term()}
```

### ClientPayload (Registration vs Login)

`ExWapp.Noise.ClientPayload.build/1` inspects the store:

| Condition | Payload type | Key fields |
|---|---|---|
| No pairing data in store | **Registration** | `devicePairingData` with Signal identity, signed prekey, one-time prekey, registration ID |
| Has pairing data (JID present) | **Login** | `username` (phone), `device` (index), `passive: true`, `pull: true`, `lidDbMigrated: true` |

---

## 9. Binary Protocol Layer

WhatsApp uses a custom token-based binary encoding (not XML, not standard protobuf).

### Encoding structure

```
Packed frame:
  1 byte:  flags (bit 1 = zlib compressed)
  N bytes: encoded node tree

Node encoding:
  - Tags and attribute keys use a token dictionary (256 predefined strings → 1 byte)
  - Unknown strings are length-prefixed UTF-8
  - JIDs have a special encoding (AD-JID or regular JID tokens)
  - Binary blobs use a length prefix
  - Lists use a list-start token + count
  - Leading 0x00 byte prepended to the entire encoded payload before encryption
```

### `ExWapp.Binary` public API

```elixir
Binary.encode(node)   :: {:ok, binary()} | {:error, term()}
Binary.decode(binary) :: {:ok, Node.t()} | {:error, term()}
Binary.unpack(binary) :: {:ok, binary()} | {:error, term()}
Binary.raw(binary)    :: Raw.t()
```

### Common Node Tags

| Tag | Direction | Meaning |
|---|---|---|
| `"message"` | inbound | Incoming chat message |
| `"notification"` | inbound | System notification (history sync, receipt, etc.) |
| `"receipt"` | inbound | Delivery/read receipt |
| `"ack"` | inbound | Server ack for sent message |
| `"iq"` | both | Info/query stanza (prekeys, app state, usync) |
| `"presence"` | inbound | Online/offline presence |
| `"chatstate"` | inbound | Typing indicator |
| `"call"` | inbound | Call notification |
| `"success"` | inbound | Login success |
| `"failure"` | inbound | Login failure |
| `"stream:error"` | inbound | Stream-level error |
| `"ib"` | inbound | Initialization block (post-login server data) |
| `"ping"` | inbound | Server keepalive ping |

---

## 10. Pairing Flow

### QR Code Pairing

```
1. Client connects → Noise handshake → sends Registration ClientPayload
2. Server sends: <iq type="set"><pair-device><ref>...</ref></pair-device></iq>
3. Client:
   a. Acknowledges with <iq type="result">
   b. Builds QR string: "2@<ref>,<noise_pub_b64>,<identity_pub_b64>,<adv_secret_b64>"
   c. Emits {:qr, qr_string} to QR subscribers
4. User scans QR with phone
5. Server sends: <iq type="set"><pair-success>...</pair-success></iq>
   Contains: <device-identity> (ADV payload), <device jid="...">, <biz>, <platform>
6. Client:
   a. Parses ADV (Account Device Verification) from device-identity
   b. Bootstraps Signal state (identity, registration_id, prekeys)
   c. Persists pairing data + signal state to store
   d. Sends <iq type="result"> with <pair-device-sign> containing self-signed ADV
   e. Emits {:status, :success} to QR subscribers
```

### `ExWapp.Pairing` public API

```elixir
Pairing.new(store)           :: state()
Pairing.apply_node(state, node) :: {state(), [event()]}
```

Events returned by `apply_node/2`:
- `{:send_node, node}` — node to send to server
- `{:qr, qr_string}` — QR code to display
- `{:status, :success}` — pairing succeeded
- `{:error, reason}` — pairing failed

### ADV (Account Device Verification)

The `device-identity` node in `pair-success` contains a protobuf-encoded ADV payload:
- `details` — device details (key index, account type, etc.)
- `accountSignatureKey` — server's signing key
- `accountSignature` — server's signature over device details
- `deviceSignature` — client's self-signature (computed during pairing)

`ExWapp.Pairing.ADV` verifies the server signature and computes the client self-signature using `adv_secret` and identity key.

---

## 11. Signal Encryption Layer

### Overview

WhatsApp uses the Signal Protocol for end-to-end encryption:
- **X3DH** (Extended Triple Diffie-Hellman) for initial session setup
- **Double Ratchet** for forward secrecy in ongoing conversations
- **Sender Keys** for group messages

### Key Types

- **Identity key**: Long-term Curve25519 keypair, generated once and persisted
- **Signed prekey**: Medium-term Curve25519 keypair, signed with identity key (Ed25519)
- **One-time prekeys**: Short-term Curve25519 keypairs, uploaded to server in batches

### Prekey Counts

| Constant | Value |
|---|---|
| Initial upload | 812 |
| Refill batch | 50 |
| Minimum threshold | 5 |

### X3DH Session Establishment

When sending to a new recipient:

```
1. Fetch recipient's prekey bundle from server (IQ stanza)
2. Generate ephemeral key pair (base_key)
3. Compute shared secrets:
   DH1 = X25519(our_identity.private, their_signed_prekey.public)
   DH2 = X25519(base_key.private, their_identity.public)
   DH3 = X25519(base_key.private, their_signed_prekey.public)
   DH4 = X25519(base_key.private, their_one_time_prekey.public)
4. Combine into master_secret -> derive root_key + chain_keys
```

### Implementation

- `ExWapp.Signal.Native`: Rust NIF wrapper for Signal logic (recommended for performance/correctness).
- `ExWapp.Signal.Encryption`: High-level facade handling prekey fetching and session locking.

---

## 12. Session Worker State Machine

The `ExWapp.Session.Worker` GenServer transitions through these states:

1. **`idle`**: Initial state. Waiting for `:connect` message.
2. **`connecting`**: `Conn` started, TCP/TLS connection in progress.
3. **`handshaking`**: `Conn` performing Noise handshake.
4. **`connected`**: Noise handshake complete. Session is authenticated (or pairing).
5. **`disconnected`**: Connection lost. Worker schedules reconnect timer.

### Critical Events

- `{:connection_event, {:connected, _}}` → Transition to `connected`.
- `{:connection_event, {:disconnected, reason}}` → Transition to `disconnected`.
- `{:inbound_node, node}` → Dispatched to `handle_inbound_node/2`.
- `{:send_text, jid, text}` → Spawns send worker task.

---

## 13. Inbound Message Flow

```
1. WebSocket receives binary frame
   ↓
2. ExWapp.Conn
   a. Decrypts frame (Noise AES-256-GCM)
   b. Unpacks (removes zlib flag, inflates if needed)
   c. Decodes binary → Binary.Node
   d. Sends {:inbound_node, node} to Session.Worker (via InboundRouter)
   ↓
3. ExWapp.Session.InboundRouter
   Buffers burst messages, forwards to Worker one by one
   ↓
4. ExWapp.Session.Worker.handle_inbound_node(node)
   ↓
5. ExWapp.MessageHandler.handle(node, session_state)
   Switch on node.tag:
   
   Case "message":
     a. Decrypt Signal message (Signal.Encryption.decrypt)
     b. Handle retry if decryption fails (send retry receipt)
     c. Parse content (text, image, reaction, etc.)
     d. Persist to Store (Chat/Message)
     e. Send "receipt" (delivery ack) to server
     f. Broadcast {:ex_wapp_message, ...} to subscribers
     
   Case "notification":
     Handle history sync, group changes, etc.
     
   Case "receipt":
     Update message status (delivered/read) in Store
     
   Case "call":
     Log call offer
```

---

## 14. Outbound Message Flow

```
1. ExWapp.Session.send_text(session, jid, text)
   ↓
2. Session.Worker spawns Task (send_worker)
   ↓
3. Send Worker Task:
   a. Fetch recipient's devices (usync or store)
   b. For each device:
      i.   Get Signal session lock
      ii.  Encrypt message (Signal.Encryption.encrypt)
           (May trigger IQ prekey fetch if no session exists)
      iii. Build protobuf Message structure
   c. Build "message" node with encrypted children
   d. Call Session.Worker.send_node(node)
   ↓
4. Session.Worker
   a. Assigns message ID (stanza ID)
   b. Adds to OutboundConfirmation tracker (if ack needed)
   c. Forwards to OutboundQueue
   ↓
5. OutboundQueue
   a. Serialises request
   b. Calls Transport.send_node(conn, node)
   ↓
6. ExWapp.Conn
   a. Encodes node → binary
   b. Encrypts (Noise)
   c. Sends WebSocket frame
```

---

## 15. PubSub & Subscription Model

The library uses `Phoenix.PubSub` for internal decoupling and `send/2` for direct subscriber notifications.

### Internal Topics
- `"ex_wapp:commands:<session_id>"`: Used to inject commands into the session worker from other processes (e.g. `ExWapp.Session.send_text` calls `PubSub.broadcast`).

### Subscriber Events

**1. QR Events**
- Subscribe: `ExWapp.Session.subscribe_qr(session, pid)`
- Events:
  - `{:ex_wapp_qr, ref, qr_string}` — New QR code to display.
  - `{:ex_wapp_qr, ref, {:status, :success}}` — Pairing success.

**2. Message Events**
- Subscribe: `ExWapp.Session.subscribe_messages(session, pid)`
- Events:
  - `{:ex_wapp_message, ref, jid, message_struct}` — Incoming chat message.

---

## 16. Store / Persistence Layer

The library is designed to be storage-agnostic via the `ExWapp.Store` behaviour.

### Default Adapter: `ExWapp.Store.Ets`
- **In-memory**: ETS tables for fast access.
- **Persistence**: Periodically dumps tables to disk (`.dets` or simple binary file).
- **Structure**: Flat map loaded into memory.

### Required Storage Keys
- `:noise` — Static keys (critical).
- `:signal` — Identity, prekeys, sessions (critical).
- `:pairing` — ADV, me-JID (critical).
- `:chats`, `:contacts` — History (can be rebuilt from history sync, but better persisted).

### Implementing a Custom Adapter
To use Postgres/Redis, implement `ExWapp.Store` behaviour and pass `store: {MyAdapter, opts}` to `Session.start_link`.

---

## 17. App State Sync

WhatsApp synchronises non-message state (pinned chats, muted chats, contact names) via "App State" (LT-Hash based).

**Flow:**
1. Server sends `<ib><sync>...</sync></ib>` on login.
2. Client checks local state hash vs server hash.
3. If mismatch, client sends `<iq type="get"><sync>...</sync></iq>`.
4. Server responds with protobuf patches.
5. `ExWapp.AppState.Engine` decodes patches:
   - Decrypts using `AppState.Crypto` (HKDF keys).
   - Apply mutations (e.g. `mute_chat`, `pin_chat`).
   - Updates local LT-Hash.

---

## 18. Telemetry

The library executes `:telemetry` events for observability.

| Event | Metadata | Description |
|---|---|---|
| `[:ex_wapp, :session, :connected]` | `%{session_id}` | Session connected |
| `[:ex_wapp, :session, :disconnected]` | `%{reason}` | Session disconnected |
| `[:ex_wapp, :message, :received]` | `%{jid, type}` | Message received |
| `[:ex_wapp, :message, :sent]` | `%{jid, type}` | Message sent |
| `[:ex_wapp, :noise, :handshake_error]` | `%{reason}` | Handshake failure |

---

## 19. Porting Guide for Telegram

Since your goal is to replicate this architecture for a Telegram library, here are the direct mappings and differences.

### Architecture Mapping

| Component | WhatsApp (ExWapp) | Telegram (MTProto) | Notes for Porting |
|---|---|---|---|
| **Transport** | WebSocket | TCP / Obfuscated TCP | Replace `WebSockex` with `gen_tcp` or `ranch` client. |
| **Encryption** | Noise Protocol (XX) | MTProto 2.0 Auth Key Creation | Replace `ExWapp.Noise` with MTProto Handshake (PQ factorization, DH). |
| **Framing** | Binary Nodes (Token Dict) | TL-Schema (Binary) | Replace `ExWapp.Binary` with a TL-Schema encoder/decoder (parse `.tl` files). |
| **E2E Encryption** | Signal Protocol | Secret Chats (MTProto E2E) | Telegram default chats are cloud-based (server encrypted), Secret Chats use E2E (modified Diffie-Hellman). |
| **Session State** | `Worker` + `Store` | `Worker` + `Store` | Keep the GenServer state machine model (`idle` -> `handshake` -> `connected`). |
| **Updates** | Binary Nodes (`message`) | `Updates` (Long Polling/Push) | Telegram sends `Updates` container. Map this to `handle_inbound` flow. |
| **Entities** | JID (`user@s.whatsapp.net`) | `Peer` (`PeerUser`, `PeerChat`) | Replace `ExWapp.JID` with a `Peer` struct (`id`, `access_hash`). |

### Key Differences for Telegram

1. **Layered Service Layer**: Telegram uses a strictly versioned "Layer" (e.g. Layer 180). You must send `invokeWithLayer` in the first request.
2. **Access Hashes**: Unlike JIDs (which are static), Telegram user/chat IDs usually require a 64-bit `access_hash` to interact with, which you gain from seeing the user in an update. You **must** persist these in your `Store` (e.g. `ExWapp.Contact` equivalent).
3. **Data Centers (DC)**: Telegram has multiple DCs (DC1...DC5). You might connect to DC2, and receive `PHONE_MIGRATE_X` error, requiring you to disconnect and move to the correct DC. Add a `switch_dc` state to your Worker.
4. **Auth Flow**: Instead of QR, Telegram uses Phone -> SMS Code -> 2FA Password. Replace `ExWapp.Pairing` with an interactive auth flow state machine.

### Recommended Steps
1. **Copy the Supervisor/Worker structure**: The `Session.Supervisor` -> `Worker` -> `Conn` hierarchy works perfectly for Telegram.
2. **Rewrite the Transport**: Implement MTProto framing (8 bytes auth_key_id + 8 bytes msg_id + ...).
3. **Rewrite the Store**: You will need tables for `auth_keys`, `salt`, `session_id`, and `access_hashes`.
4. **TL-Schema Compiler**: You'll need a way to compile `.tl` definitions into Elixir structs (like `ExWapp.Binary` handles nodes, but strongly typed).

---
