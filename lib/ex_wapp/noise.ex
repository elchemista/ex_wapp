defmodule ExWapp.Noise do
  @moduledoc """
  Placeholder for the Noise_XX_25519_AESGCM_SHA256 implementation.

  The real WhatsApp Web transport wraps every application frame in a Noise
  handshake followed by an AEAD-protected stream. Implementing the full
  state machine is outside the scope of this scaffold but the module exposes
  the functions the rest of the system will rely on.
  """

  @enforce_keys [:phase, :tx_counter, :rx_counter]
  defstruct phase: :handshake, tx_counter: 0, rx_counter: 0, cipher: nil

  @type t :: %__MODULE__{
          phase: :handshake | :transport,
          tx_counter: non_neg_integer(),
          rx_counter: non_neg_integer(),
          cipher: term()
        }

  @doc """
  Returns a fresh Noise state.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{phase: :handshake, tx_counter: 0, rx_counter: 0}
  end

  @doc """
  Processes an incoming WebSocket binary frame.
  """
  @spec handle_incoming(t(), binary()) :: {:ok, t(), binary()} | {:error, term()}
  def handle_incoming(_state, _payload) do
    {:error, :noise_handshake_not_implemented}
  end

  @doc """
  Wraps an application node into an outgoing binary frame.
  """
  @spec wrap_outgoing(t(), term()) :: {:ok, t(), binary()} | {:error, term()}
  def wrap_outgoing(_state, _node) do
    {:error, :noise_handshake_not_implemented}
  end
end
