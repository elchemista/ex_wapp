defmodule ExWapp.Transport.Frame do
  @moduledoc """
  WhatsApp-specific websocket frame encoding.

  Frames are encoded as a WA header (sent once per connection) followed by a
  24-bit big-endian payload length and the raw payload bytes.
  """

  @wa_magic 0x06
  @dict_version 0x03
  @header <<?W, ?A, @wa_magic, @dict_version>>
  @length_size 3
  @max_payload_size 0xFF_FFFF

  @doc """
  Returns the static WA connection header.
  """
  @spec header() :: binary()
  def header, do: @header

  @doc false
  @spec max_payload_size() :: pos_integer()
  def max_payload_size, do: @max_payload_size

  @doc """
  Wraps the given payload in a WA websocket frame.

  The `:include_header` option ensures the header is prefixed once per
  connection. Callers are expected to keep track of whether the header was
  already sent for a connection and set the option accordingly.
  """
  @spec encode(binary(), keyword()) :: binary()
  def encode(payload, opts \\ [])

  def encode(payload, opts) when is_binary(payload) and byte_size(payload) <= @max_payload_size do
    include_header = Keyword.get(opts, :include_header, false)
    header = if include_header, do: @header, else: <<>>
    <<header::binary, byte_size(payload)::unsigned-big-size(24), payload::binary>>
  end

  def encode(payload, _opts) when is_binary(payload) do
    raise ArgumentError,
          "WA frame payload exceeds 24-bit limit (#{byte_size(payload)} > #{@max_payload_size})"
  end

  @doc """
  Consumes as many frames as possible from `buffer`.

  Returns `{frames, rest}` where `frames` is a list of payload binaries in FIFO
  order and `rest` is the leftover buffer that did not yet form a full frame.
  """
  @spec decode(binary()) :: {[binary()], binary()}
  def decode(buffer) when is_binary(buffer) do
    do_decode(buffer, [])
  end

  defp do_decode(buffer, acc) do
    if byte_size(buffer) < @length_size do
      {Enum.reverse(acc), buffer}
    else
      <<len::unsigned-big-size(24), rest::binary>> = buffer

      if byte_size(rest) < len do
        {Enum.reverse(acc), buffer}
      else
        <<frame::binary-size(^len), tail::binary>> = rest
        do_decode(tail, [frame | acc])
      end
    end
  end
end
