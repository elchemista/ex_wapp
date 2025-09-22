# ExWapp

An experimental Elixir port of the WhatsMeow WhatsApp Web client. The code in
`lib/` mirrors the high-level architecture of the Go project and focuses on the
minimum viable path to “QR pairing + send a text message”.

## Current status

* Project skeleton in place with dedicated modules for transport, Noise,
  binary nodes, pairing, messaging, Signal, and persistence.
* Pairing events can already be observed via `ExWapp.qr_stream/1` (the stream is
  fed manually until the full handshake is implemented).
* File-based store keeps key material and other state using Erlang ETF terms.
* Tests cover the QR event stream and store persistence helpers.

> :warning: The cryptographic and protocol heavy lifting is **not implemented**
> yet. Noise, binary node encoding, Signal, and actual message exchange still
> need to be ported from WhatsMeow or re-implemented from the spec.

## Usage snapshot

```elixir
{:ok, session} = ExWapp.start_link()

qr_task = Task.async(fn ->
  ExWapp.qr_stream(session)
  |> Enum.each(&IO.inspect/1)
end)

ExWapp.connect(session)
```

The `connect/1` call will eventually drive the Noise handshake, emit QR codes,
and transition to a paired session. For now the process only stubs the flow so
that the supervising infrastructure and persistence hooks can be validated.

### Pairing with a QR code

Once the Noise and pairing layers are in place you can run a small script to
stream QR events, render them in the terminal, and persist credentials for the
paired device. The example below uses the default ETS+file store and the
`eqrcode` dependency to print each QR refresh on screen.

```elixir
defmodule PairOnce do
  @store_path Path.expand("~/.cache/ex_wapp/example_session.etf")

  def run do
    {:ok, session} =
      ExWapp.start_link(store: {ExWapp.Store.ETS, path: @store_path})

    qr_task =
      Task.async(fn ->
        ExWapp.qr_stream(session)
        |> Enum.reduce_while(:ok, fn event, acc ->
          case event do
            {:code, ref} ->
              render_qr(ref)
              {:cont, acc}

            :success ->
              IO.puts("\n\e[32mPaired successfully!\e[0m")
              {:halt, :ok}

            {:error, reason} ->
              IO.inspect(reason, label: "pairing_error")
              {:halt, {:error, reason}}
          end
        end)
      end)

    ExWapp.connect(session)
    Task.await(qr_task, :infinity)
  end

  defp render_qr(ref) do
    IO.write("\e[2J\e[H")
    IO.puts("Scan this code in WhatsApp > Linked Devices:
")

    ref
    |> EQRCode.encode()
    |> EQRCode.Render.render()
  end
end

case PairOnce.run() do
  :ok -> :ok
  {:error, reason} -> IO.puts("Pairing failed: ") && IO.inspect(reason)
end
```

You can save the snippet to `scripts/pair_once.exs` and run it with `mix run
scripts/pair_once.exs`, or paste it inside an `iex -S mix` shell. On success the
session keys stay on disk at `@store_path`, allowing future runs to reconnect
without showing another QR code.

## Module map

* `ExWapp.Conn` – WebSocket transport (Noise placeholders in place)
* `ExWapp.Noise` – Noise_XX handshake scaffold
* `ExWapp.Binary` – WhatsApp binary node encoder/decoder stubs
* `ExWapp.Pairing` – QR pairing coordinator (state machine pending)
* `ExWapp.Messages` – Message protobuf + Signal envelope TODOs
* `ExWapp.Signal` – Signal bootstrap/encrypt/decrypt placeholders
* `ExWapp.Store.File` – Simple file-backed persistence helper

## Next steps

1. Fill in `ExWapp.Noise` with the proper handshake and AEAD framing.
2. Implement binary node encoding/decoding with the necessary token tables.
3. Drive the QR pairing flow by producing/consuming the relevant nodes.
4. Add protobuf models (e.g. `Message`) via `protox` and wire in the Signal
   pipeline for outbound texts.

Run the test suite with:

```bash
mix test
```

### TODO 
* Expand the Noise client payload to include the device registration bundle (registration id, identity key, signed prekey + signature, device props); right now lib/ex_wapp/noise/client_payload.ex:13 only emits push-name metadata, so the server never receives the data it needs to offer a pairing QR (see Go’s store/clientpayload.go for the reference structure).
* Fix the pair-success acknowledgement to send a pair-device-sign/device-identity node carrying the self-signed identity and key index; build_pair_success_ack/3 in lib/ex_wapp/pairing.ex:285 currently emits pair-success/adv-device-identity, which doesn’t match the WhatsApp handshake and the pairing will be rejected.
* After Pairing reports :success, add logic in the session to tear down the registration socket and reconnect using the freshly stored credentials (login payload instead of registration); without that post-pairing reconnect path (lib/ex_wapp/session.ex:138 and the surrounding state machine) you end up paired but never establish a normal logged-in transport.
 
__Send Text__

* Replace the stub in lib/ex_wapp/messages.ex:16 with real message construction: generate message IDs, populate WAWebProtobufsWa6.Message, wrap it in the correct binary node, and attach any context info the server expects.
* Flesh out lib/ex_wapp/signal.ex beyond bootstrap/1 so it can create/fetch sessions for recipients, encrypt outgoing payloads with libsignal, advance ratchets, and persist the updated state; you’ll also need helpers to upload our prekeys and fetch the contact/device bundle before the first message.
* Rework maybe_send_text/3 in lib/ex_wapp/session.ex:186 to orchestrate the full send pipeline (load signal state from the store, call the new encryption helper, hand the node to Conn.send_node/2, track acks/errors) instead of returning :ok unconditionally.
* Add the missing contact/device sync + prekey fetch flow so you know where to route encrypted messages; at minimum port the fetchPreKeys + device-list handling that exists in the Go client before attempting to call the new send pipeline.