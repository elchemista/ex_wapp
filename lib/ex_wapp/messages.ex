defmodule ExWapp.Messages do
  @moduledoc """
  High-level helpers for constructing WhatsApp message nodes.

  Once the Signal pipeline exists this module will be responsible for
  encoding protobuf payloads and wrapping them in Signal envelopes before
  handing them over to the transport layer.
  """

  alias ExWapp.Binary

  @doc """
  Constructs the minimal plaintext message node.
  """
  @spec text(binary(), binary(), binary()) :: Binary.t()
  def text(_jid, _id, _body), do: raise("message encoding not implemented yet")
end
