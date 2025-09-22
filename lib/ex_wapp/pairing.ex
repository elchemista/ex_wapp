defmodule ExWapp.Pairing do
  @moduledoc """
  Implements the QR-code based pairing handshake used by WhatsApp Web.

  The current version focuses on documenting the required touch points so
  the actual binary node plumbing can be filled in incrementally.
  """

  alias ExWapp.Binary

  @typedoc """
  Aggregate structure that keeps temporary pairing data.
  """
  @type state :: %{
          status: :idle | :waiting_for_scan | :paired,
          ref: String.t() | nil,
          client_static: binary() | nil
        }

  @doc """
  Returns the initial pairing state.
  """
  @spec new() :: state()
  def new do
    %{status: :idle, ref: nil, client_static: nil}
  end

  @doc """
  Produces the first binary node that kicks off the pairing flow.

  The payload is sent right after the Noise handshake concludes.
  """
  @spec initial_node(state()) :: Binary.t()
  def initial_node(_state), do: raise("pairing init node not implemented yet")

  @doc """
  Applies a decoded node and returns the updated state + events.
  """
  @spec apply_node(state(), Binary.t()) :: {state(), [term()]}
  def apply_node(state, _node) do
    {state, []}
  end

  @doc """
  Turns the server-provided ref into a QR string.
  """
  @spec qr_from_ref(state(), String.t()) :: String.t()
  def qr_from_ref(_state, _ref), do: raise("QR builder missing implementation")
end
