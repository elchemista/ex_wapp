defmodule ExWapp.Binary do
  @moduledoc """
  Encoder/decoder for WhatsApp's binary node format.

  The structure is comparable to a compact binary XML with a shared token
  dictionary. The full mapping is large; the current module only exposes
  function stubs so the token tables and serializer can be filled in later.
  """

  @type t :: {String.t(), %{optional(String.t()) => String.t()}, [t() | binary()]}

  @doc """
  Encodes a node into iodata consumable by the Noise transport.
  """
  @spec encode(t()) :: iodata()
  def encode(_node), do: raise("binary encoder not implemented yet")

  @doc """
  Decodes a decrypted payload back into a node.
  """
  @spec decode(binary()) :: t()
  def decode(_payload), do: raise("binary decoder not implemented yet")
end
