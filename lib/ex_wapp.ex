defmodule ExWapp do
  @moduledoc """
  Public entrypoint for the ExWapp WhatsApp Web client.

  This module exposes a very small surface area around a managed
  `ExWapp.Session` process so that callers can focus on three core flows:

    * boot the client (`start_link/1`)
    * run the network handshake (`connect/1`)
    * interact with pairing/messages (`qr_stream/1`, `send_text/3`)

  All heavy lifting lives in purpose-specific modules under the
  `ExWapp.` namespace. They are currently skeletal but documented so the
  missing protocol pieces can be filled in incrementally.
  """

  alias ExWapp.Session

  @doc """
  Starts a supervised session process.

  The returned `pid` controls the lifecycle of the Noise channel, pairing
  state, and message pipeline. See `ExWapp.Session` for the list of
  available options.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    Session.start_link(opts)
  end

  @doc """
  Initiates the WhatsApp Web connection lifecycle.

  This triggers the Noise handshake, pairing flow, and initial sync. The
  call is asynchronous; callers should subscribe to the QR stream (see
  `qr_stream/1`) and other events they are interested in.
  """
  @spec connect(GenServer.server()) :: :ok
  defdelegate connect(server), to: Session

  @doc """
  Returns a `Stream` that yields QR related events.

  The stream is built from messages emitted by the underlying session
  process. Events are intentionally descriptive atoms/tuples so the caller
  can react accordingly (render QR, refresh expired codes, handle
  success/failure, ...).
  """
  @spec qr_stream(GenServer.server()) :: Enumerable.t()
  defdelegate qr_stream(server), to: Session

  @doc """
  Sends a plain-text WhatsApp message once a session is paired.

  This is the public hook for the MVP “send text” functionality. The
  session process coordinates message proto construction, Signal
  encryption, and delivery over the WebSocket transport.
  """
  @spec send_text(GenServer.server(), binary(), iodata()) :: :ok
  defdelegate send_text(server, jid, text), to: Session
end
