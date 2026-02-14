# credo:disable-for-this-file
defmodule ExWapp.AppState.LTHash do
  @moduledoc """
  Linked-list Truncated Hash for WhatsApp App State integrity verification.

  Maintains a 128-byte hash that tracks the state of all applied mutations
  via pointwise u16 little-endian arithmetic with wrapping.

  Matches whatsmeow `appstate/lthash/lthash.go`.
  """

  import Bitwise

  @hkdf_info "WhatsApp Patch Integrity"
  @hash_size 128

  @doc """
  Create a new empty LTHash (128 zero bytes).
  """
  @spec new() :: binary()
  def new, do: :binary.copy(<<0>>, @hash_size)

  @doc """
  Subtract old MACs then add new MACs to the hash state.

  Returns updated 128-byte hash.

  Matches whatsmeow `LTHash.SubtractThenAdd()`.
  """
  @spec subtract_then_add(binary(), [binary()], [binary()]) :: binary()
  def subtract_then_add(hash, subtract_macs, add_macs)
      when byte_size(hash) == @hash_size and is_list(subtract_macs) and is_list(add_macs) do
    hash
    |> multiple_op(subtract_macs, :subtract)
    |> multiple_op(add_macs, :add)
  end

  @doc """
  Add MACs to the hash state.
  """
  @spec add(binary(), [binary()]) :: binary()
  def add(hash, macs), do: multiple_op(hash, macs, :add)

  @doc """
  Subtract MACs from the hash state.
  """
  @spec subtract(binary(), [binary()]) :: binary()
  def subtract(hash, macs), do: multiple_op(hash, macs, :subtract)

  defp multiple_op(hash, macs, op) do
    Enum.reduce(macs, hash, fn mac, acc ->
      intermediate = expand_mac(mac)
      pointwise_op(acc, intermediate, op)
    end)
  end

  defp expand_mac(mac) do
    # HKDF-SHA256: key=mac, salt=nil, info="WhatsApp Patch Integrity", length=128
    salt = :binary.copy(<<0>>, 32)
    prk = :crypto.mac(:hmac, :sha256, salt, mac)
    hkdf_expand(prk, @hkdf_info, @hash_size)
  end

  # Pointwise u16 little-endian addition/subtraction with wrapping
  defp pointwise_op(base, input, op) when byte_size(base) == @hash_size and byte_size(input) == @hash_size do
    for i <- 0..(@hash_size - 1)//2, into: <<>> do
      <<x::little-unsigned-16>> = binary_part(base, i, 2)
      <<y::little-unsigned-16>> = binary_part(input, i, 2)

      result =
        case op do
          :add -> band(x + y, 0xFFFF)
          :subtract -> band(x - y + 0x10000, 0xFFFF)
        end

      <<result::little-unsigned-16>>
    end
  end

  defp hkdf_expand(prk, info, length) do
    n = ceil(length / 32)

    {output, _} =
      Enum.reduce(1..n, {<<>>, <<>>}, fn i, {acc, prev} ->
        t = :crypto.mac(:hmac, :sha256, prk, prev <> info <> <<i::8>>)
        {acc <> t, t}
      end)

    binary_part(output, 0, length)
  end
end
