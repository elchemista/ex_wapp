defmodule ExWapp.Transport.WebSocket.State do
  @moduledoc """
  Holds runtime state for the WhatsApp WebSocket transport.

  The struct keeps the owner, store, Noise state, and incremental frame buffer
  used by `ExWapp.Transport.WebSocket` callbacks.
  """

  alias ExWapp.{Client, Noise, Store}

  defstruct client: nil,
            owner: nil,
            store: nil,
            noise: nil,
            noise_opts: [],
            buffer: <<>>,
            header_seen?: false,
            header_sent?: false

  @type t :: %__MODULE__{
          client: Client.t(),
          owner: pid(),
          store: Store.t(),
          noise: Noise.t() | nil,
          noise_opts: keyword(),
          buffer: binary(),
          header_seen?: boolean(),
          header_sent?: boolean()
        }
end
