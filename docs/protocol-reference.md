# Protocol reference

This is a maintainer reference for the private multi-device protocol behavior
implemented and tested by ExWapp. It is not an official WhatsApp specification.
Remote behavior can change without notice, so source code, wire fixtures, and
live validation take precedence when they disagree with this document.

Application developers should not build against the modules described here.
The only supported application boundary is the `ExWapp` facade operating on a
`%ExWapp.Client{}`.

## Upstream snapshot: 2026-09-09

The default WhatsApp Web version is `2.3000.1047068806`, verified against
[whatsmeow `9ec8f76`](https://github.com/tulir/whatsmeow/tree/9ec8f76db5f17712efc34a29b684a80d2dcb4aaf).
The generated Protox modules use that same checkout. Compared with the previous
[August snapshot](https://github.com/tulir/whatsmeow/compare/33cfac5116293e4cb86f8e4099e8eaf6de7ebc08...9ec8f76db5f17712efc34a29b684a80d2dcb4aaf),
the imported schema changes add fields and enum values without removing or
renumbering existing fields:

- ACP2 settings in protocol messages, message context and message wrappers.
- Scheduled newsletter wrappers, DASH video manifest URLs, packed experience
  IDs and TEE context anchors.
- Business AI onboarding events, response-stop metadata, new bot capabilities
  and original-recipient AI response metadata.
- AI migration and business broadcast device capabilities, plus `WORK_ANDROID`
  and `WORK_IOS` user-agent platform values.

These additions provide protobuf encoding and decoding; they do not add public
APIs for the corresponding features. The binary token dictionary is unchanged.
The upstream Labyrinth/WASM schema also changed, but it is outside this client's
generated entrypoints and runtime.

Other upstream commits adjust Go socket context lifetime and stream-error
ordering, self-authored history messages in LID chats, unencrypted thumbnails
and group metadata handling. They are separate runtime changes, not imported by
protobuf regeneration. Upstream also added
[experimental `companion_reg_refresh` handling](https://github.com/tulir/whatsmeow/commit/9ec8f76db5f17712efc34a29b684a80d2dcb4aaf)
to rotate the ADV secret and refresh QR codes; ExWapp does not implement that
notification yet.

To refresh this snapshot, run `scripts/update_wa_protos.sh`, compare the version
in `tmp/whatsmeow_upstream/store/clientpayload.go` with `ExWapp.Config`, and update
the verification date after checking upstream. Run the full test suite after
the script's wire checks. Version verification records the upstream value;
successful pairing still requires validation against a live WhatsApp account.

## Addressing and identity

### JID families

| Kind | Example | Primary use |
| --- | --- | --- |
| Phone number (PN) | `15550001111@s.whatsapp.net` | User-facing identity and server queries |
| PN device | `15550001111:2@s.whatsapp.net` | One linked device in the PN family |
| Linked identity (LID) | `203139403767907@lid` | Linked identity and Signal state |
| LID device | `203139403767907:2@lid` | One linked device in the LID family |
| Group | `120363043214477337@g.us` | Group conversation |

The public chat identity is device-stripped. A participant or encryption target
may retain its device suffix.

### Wire identity and Signal identity

The JID placed in a binary-node attribute is not always the key used to locate
Signal state. ExWapp resolves two related values:

- the **wire JID**, used in server-facing nodes and participant fanout;
- the **Signal JID**, used for peer-session storage and encryption.

PN-to-LID mappings can arrive from device discovery, inbound stanza attributes,
and history synchronization. The store retains both directions. Session lookup
checks deterministic aliases rather than blindly replacing every PN with a LID.

A direct-message stanza uses one addressing family. If the outer destination is
PN, every participant `<to jid>` is PN; if it is LID, every participant is LID.
The final message-node boundary removes and reports any mixed-family target.

## Device discovery and prekeys

### Device discovery

Device discovery uses an IQ in the `usync` namespace. A message-context query
includes the recipient and the sender identity when they differ. Each response
user can contain several devices; a device ID is combined with its parent user
to reconstruct the target JID.

The current linked device is known to topology calculations but excluded from
the encryption targets. Returned PN/LID mappings are stored before session
selection and encryption.

Discovery results are cached. A topology/hash mismatch or session-repair path
can evict the affected entries so a later send queries current devices.

### Peer prekey fetch

Missing peer sessions trigger an IQ in the `encrypt` namespace. Batch fetch is
preferred, with an individual fallback for targets whose bundles were missing
from the batch response. The request uses concrete wire device JIDs; session
creation then aliases the wire and mapped Signal identities deterministically.

Normal sends reuse an existing compatible session. Repair paths intentionally
discard stale peer sessions before obtaining fresh key material. Direct
self-chat also reuses its valid own-device sessions instead of opening a new
prekey session for every message.

### Local prekey durability

Publishing local prekeys is a durable two-phase operation:

1. reserve IDs and store both private and public material;
2. advance the local allocator and flush the store;
3. only after a successful flush, enqueue the upload IQ;
4. mark the reservation uploaded when the server acknowledges it;
5. retain unacknowledged reservations for reuse after timeout or reconnect.

ExWapp refuses to advertise public halves whose private halves are not durable.
It also maintains a high-water mark for advertised IDs so a restored older
snapshot cannot issue different key material under an ID the server may still
serve.

## Signal wire envelopes

Application message protobuf bytes are padded before Signal encryption. The
current implementation uses a non-zero random padding length and appends that
length as every padding byte.

| Node `type` | Signal envelope | Use |
| --- | --- | --- |
| `pkmsg` | PreKeySignalMessage | Opens a peer session from prekey material |
| `msg` | SignalMessage | Advances an established peer ratchet |
| `skmsg` | SenderKeyMessage | Carries group ciphertext |

The peer-session envelopes use the Signal version byte followed by their
encoded message. An established Signal message authenticates its header and
ciphertext with the truncated message MAC. Group sender-key messages carry
their signature as defined by the sender-key wire format.

Ratchet mutation is serialized by peer/device key. A fresh inbound prekey
session is persisted before its one-time prekey is removed. A bounded set of
retained sessions is indexed by initiator base key so delayed messages can be
routed to the ratchet that consumed them. When a retained session successfully
decrypts a current peer message, it is promoted back to the current slot.

## Direct-message fanout

A direct send produces two protobuf payload forms:

- recipient devices receive the original message;
- the sender's other devices receive a DeviceSentMessage (DSM) containing the
  original message and base destination JID.

The current device is excluded. In a self-chat, all other devices are own
devices and therefore receive DSM payloads.

The high-level sequence is:

1. build the original message and DSM payload;
2. discover recipient and own devices;
3. persist any PN/LID mappings;
4. select existing sessions and fetch missing bundles;
5. encrypt the correct payload independently for every target;
6. canonicalize target JIDs to the outer destination family;
7. build participant nodes and optional identity/token children;
8. enqueue the binary node for Noise transport.

### Message identifier

Generated outgoing IDs have 22 characters:

```text
3EB0 + UPPER_HEX(first 9 bytes of SHA256(timestamp || own-user@c.us || random16))
```

Retry and session repair preserve the original ID.

### Direct-message node

```xml
<message id="3EB0..." type="text" to="recipient@s.whatsapp.net">
  <participants>
    <to jid="recipient:0@s.whatsapp.net">
      <enc v="2" type="pkmsg">...</enc>
    </to>
    <to jid="recipient:2@s.whatsapp.net">
      <enc v="2" type="msg">...</enc>
    </to>
    <to jid="own:3@s.whatsapp.net">
      <enc v="2" type="msg">...DSM ciphertext...</enc>
    </to>
  </participants>
  <device-identity>...</device-identity>
  <tctoken>...</tctoken>
</message>
```

The `device-identity` child is included when any target receives `pkmsg`.
Outgoing-message identity encoding includes the account signature key; the
pair-success acknowledgement uses its pairing-specific self-signed form.

Trusted-contact privacy tokens are optional. ExWapp accepts records from the
current seven-day bucket and the preceding three, stores them under known JID
aliases, keeps the newest copy, and drops expired values before sending.

Direct-message attributes do not include `phash`. The participant hash remains
useful for group topology and diagnostics.

## Participant hash

Version 2 participant hashes are derived as follows:

1. convert each device JID to `user.agent:device@server` form;
2. sort the resulting strings lexicographically;
3. concatenate them without a separator;
4. hash with SHA-256;
5. take the first six hash bytes;
6. encode with standard Base64 without padding;
7. prefix the result with `2:`.

The current device participates where the topology calculation requires it,
even though it is not an encryption target.

## Group fanout

Groups use one SenderKey encryption for the top-level `skmsg`. Devices that do
not yet have the group sender key receive a SenderKeyDistributionMessage through
their individual `pkmsg` or `msg` session.

```xml
<message id="3EB0..." type="text" to="group@g.us"
         addressing_mode="lid" phash="2:...">
  <enc v="2" type="skmsg">...group ciphertext...</enc>
  <participants>
    <to jid="member:0@lid">
      <enc v="2" type="pkmsg">...sender-key distribution...</enc>
    </to>
  </participants>
  <device-identity>...</device-identity>
</message>
```

Group participant targets must match `addressing_mode`. Unlike a direct
message, the top-level group content is not DSM-wrapped and `<participants>`
contains only sender-key distribution targets.

## Inbound routing and decryption

An inbound message can expose identities through `from`, `participant`,
`sender_lid`, `sender_pn`, `participant_lid`, or `participant_pn`. ExWapp:

1. extracts available identities;
2. adds device-preserving and device-stripped forms where appropriate;
3. expands them through PN/LID mappings;
4. collects root and nested `<enc>` payload candidates;
5. tries the payload-by-sender candidate matrix until one decrypts.

After decryption it removes padding, decodes the generated message protobuf,
processes sender-key distribution and protocol messages, unwraps DSM payloads,
persists relevant chat/session state, and publishes user content. Internal
protocol payloads do not become empty chat messages.

`pkmsg` routing first attempts a stored session matching the envelope base key.
Fresh X3DH creation is a fallback when no retained/current session matches.

## ACKs, receipts, and retry

### Protocol ACK

Inbound message, call, status, and notification stanzas are acknowledged at the
connection boundary before ordinary decryption, persistence, or publication.
This ACK uses the priority control queue. Required participant, recipient, and
type attributes are copied or derived from the stanza.

Protocol ACK is distinct from application delivery state. After successful
message processing, ExWapp sends the appropriate delivery receipt.

### Outbound ACK classification

An outgoing socket write is not acceptance or delivery. A later server ACK can
accept or reject the message. `ExWapp.Error.Ack` currently classifies known ACK
codes conservatively:

| ACK code | Category | Runtime treatment |
| --- | --- | --- |
| `463` | Session | Refresh peer Signal state before bounded resend |
| `429` | Throttled | Retriable only after backoff |
| `479` | Transient | Retriable with backoff |
| `503`, `515` | Transient | Retry after reconnect |
| `401`, `403` | Permanent | Do not retry the message |
| `404`, `405` | Permanent | Recipient/route unavailable |
| Unknown | Unknown | Treat as non-retriable until identified |

This table is for message ACK classification. Connection-level failures use
their own state transitions and must not be inferred solely from this table.

A `463` repair finds the retained payload, drops the affected peer session,
re-runs discovery/session establishment, re-encrypts, and preserves the message
ID. Repair attempts and backoff are bounded by runtime configuration.

### Retry receipts

When decryption fails for a recoverable reason, ExWapp can request a fresh
delivery with a retry receipt. Lost or unavailable key material forces a fresh
key bundle rather than requesting byte-identical ciphertext that cannot decrypt.
Retry counters bound repeated requests.

When an inbound retry receipt asks ExWapp to resend an outgoing message, the
runtime locates the stored original, dispatches the resend under the same ID,
and acknowledges the retry receipt only after dispatch. If the worker dies
before dispatch, the unacknowledged receipt can be delivered again.

## Binary and protobuf pipeline

### Outbound

```text
typed ExWapp.Message
  -> generated message protobuf
  -> optional DSM or sender-key distribution payload
  -> Signal padding and encryption
  -> binary-node construction
  -> binary-node encoding
  -> Noise transport encryption
  -> 24-bit framed WebSocket payload
```

### Inbound

```text
WebSocket bytes
  -> frame splitting
  -> Noise authentication/decryption
  -> optional binary payload decompression
  -> binary-node decoding
  -> stanza routing and ACK
  -> Signal candidate decryption
  -> generated protobuf decoding
  -> projection, persistence, receipt, event
```

Raw ciphertext and key material must remain raw binary node content rather than
UTF-8 strings. Empty/nil attributes are omitted. The binary-node encoder and
decoder handle the supported tokenized JID forms.

### Generated protobuf boundary

All WhatsApp protobuf encode/decode uses the generated Protox modules under
`lib/ex_wapp/wa_proto/`. They are a checked-in snapshot produced by
`scripts/update_wa_protos.sh` and must not be edited manually.

Wire tests pin fields that have caused compatibility errors, including:

- `WAWebProtobufsE2E.Message.conversation`: field 1;
- `extendedTextMessage`: field 6;
- `protocolMessage`: field 12;
- `deviceSentMessage`: field 31;
- `DeviceSentMessage.destinationJID`: field 1;
- `DeviceSentMessage.message`: field 2;
- `DeviceSentMessage.phash`: field 3;
- `ContextInfo.isForwarded`: field 22;
- `WebMessageInfo.participant`: field 5.

Schema presence does not make a message type part of the supported public API.

## App state and history

App-state collection patches are authenticated before application. Collection
version, LTHash, and mutation MAC state advance together. A mismatch triggers
resynchronization rather than applying unauthenticated or out-of-sequence data.

Inline history synchronization can ingest contacts, chats, messages, privacy
tokens, PN/LID mappings, and call-log records. Blob-delivered chunks remain
pending references and are not downloaded, so history is not guaranteed to be
complete.

## Call signalling and call log

ExWapp records call signalling metadata but does not implement VoIP media or
answering calls.

| Call child | Local interpretation |
| --- | --- |
| `offer`, `offer_notice` | Ringing |
| `accept` | Ongoing/accepted |
| `terminate` | Final state using duration, creator, and prior acceptance |
| `reject` | Rejected |
| Negotiation-only children | Acknowledged but not stored as call-log transitions |

The authoritative phone-side outcome can later arrive as an app-state
`CallLogRecord`. History sync can also carry those records when call-log history
was enabled during pairing. Records merge by call ID; a transient state does
not overwrite an existing final outcome.

The generated E2E message schema also contains `callLogMesssage` (the field name
has three consecutive `s` characters), but ExWapp does not currently consume
that payload.

## Maintainer checklist

### Identity and discovery

- Keep one PN/LID family in each direct-message stanza.
- Store mappings before session selection.
- Include recipient and own identity in message-context device discovery.
- Exclude the current device from encryption targets.

### Key material and sessions

- Persist and flush local prekeys before advertising them.
- Never reissue an advertised prekey ID with different material.
- Reuse compatible sessions during normal sends; clear them only during repair.
- Persist an inbound session before deleting its consumed one-time prekey.
- Serialize mutation of the same ratchet.

### Outbound nodes

- Send the original payload to recipient devices and DSM to own devices.
- Preserve message IDs through retry and repair.
- Include `device-identity` when any target receives `pkmsg`.
- Use group `addressing_mode` consistently.
- Do not add `phash` to direct-message attributes.

### Inbound control flow

- ACK protocol stanzas before slow processing.
- Keep protocol ACK separate from delivery/read receipts.
- Try the sender/payload candidate matrix before declaring decryption failure.
- Bound retry receipts and session repair.
- Do not turn internal protocol payloads into user messages.

See [protocol flow](protocol-flow.md) for sequencing,
[architecture](architecture.md) for ownership boundaries, and
[strengths and limitations](strengths-and-limitations.md) for operational risk.
