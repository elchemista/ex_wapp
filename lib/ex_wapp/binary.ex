defmodule ExWapp.Binary do
  @moduledoc """
  WhatsApp binary node encoder/decoder (ported from whatsmeow).

  The public API currently exposes helpers to turn structured nodes into the
  on-the-wire representation used by WhatsApp Web and to decode the payloads
  back to nodes.
  """

  import Bitwise

  alias __MODULE__.{Encoder, Decoder, Node, Raw}
  alias ExWapp.Binary.Token
  alias ExWapp.JID

  defmodule Error do
    defexception [:message]
  end

  defmodule Node do
    @enforce_keys [:tag]
    defstruct tag: nil, attrs: %{}, content: nil
  end

  defmodule Raw do
    @enforce_keys [:data]
    defstruct data: nil

    def new(data) when is_binary(data), do: %__MODULE__{data: data}
  end

  @type binary_node :: %Node{
          tag: String.t(),
          attrs: map(),
          content: nil | Raw.t() | binary() | [binary_node()]
        }

  @doc """
  Wraps a binary payload so that the encoder treats it as raw bytes instead of a
  UTF-8 string.
  """
  @spec raw(binary()) :: Raw.t()
  def raw(data) when is_binary(data), do: Raw.new(data)

  @doc """
  Encodes a node into WhatsApp's binary node format.
  """
  @spec encode(binary_node() | tuple()) :: {:ok, binary()} | {:error, any()}
  def encode(node) do
    node = normalize_node(node)

    try do
      {:ok, encode!(node)}
    rescue
      e -> {:error, e}
    end
  end

  @doc """
  Encodes a node into WhatsApp's binary node format. Raises on failure.
  """
  @spec encode!(binary_node() | tuple()) :: binary()
  def encode!(node) do
    node = normalize_node(node)
    encoder = Encoder.new()
    encoder |> Encoder.write_node(node) |> Encoder.to_binary()
  end

  @doc """
  Decodes a WhatsApp binary node payload back into a node struct.
  """
  @spec decode(binary()) :: {:ok, binary_node()} | {:error, any()}
  def decode(payload) when is_binary(payload) do
    try do
      {:ok, decode!(payload)}
    rescue
      e -> {:error, e}
    end
  end

  @doc """
  Decodes a WhatsApp binary node payload back into a node struct. Raises on failure.
  """
  @spec decode!(binary()) :: binary_node()
  def decode!(payload) when is_binary(payload) do
    decoder = Decoder.new(payload)
    {node, decoder} = Decoder.read_node(decoder)

    if Decoder.bytes_remaining(decoder) != 0 do
      raise(Error, message: "leftover bytes after decoding")
    end

    node
  end

  @spec normalize_node(any()) :: binary_node()
  defp normalize_node(%Node{} = node) do
    %Node{
      tag: normalize_tag(node.tag),
      attrs: normalize_attrs(node.attrs),
      content: normalize_content(node.content)
    }
  end

  defp normalize_node({tag, attrs, content}) do
    %Node{
      tag: normalize_tag(tag),
      attrs: normalize_attrs(attrs),
      content: normalize_content(content)
    }
  end

  defp normalize_node({tag, attrs}) do
    %Node{tag: normalize_tag(tag), attrs: normalize_attrs(attrs), content: nil}
  end

  defp normalize_node(tag) when is_binary(tag), do: %Node{tag: tag, attrs: %{}, content: nil}

  defp normalize_node(tag) when is_atom(tag),
    do: %Node{tag: Atom.to_string(tag), attrs: %{}, content: nil}

  defp normalize_node(other) do
    raise(Error, message: "invalid node representation: #{inspect(other)}")
  end

  defp normalize_tag(tag) when is_binary(tag), do: tag
  defp normalize_tag(tag) when is_atom(tag), do: Atom.to_string(tag)
  defp normalize_tag(tag), do: to_string(tag)

  defp normalize_attrs(nil), do: %{}

  defp normalize_attrs(attrs) when is_map(attrs) do
    attrs
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, normalize_tag(key), normalize_attr_value(value))
    end)
  end

  defp normalize_attrs(attrs) when is_list(attrs) do
    attrs
    |> Enum.reduce(%{}, fn
      {key, value}, acc -> Map.put(acc, normalize_tag(key), normalize_attr_value(value))
      key, acc when is_atom(key) or is_binary(key) -> Map.put(acc, normalize_tag(key), true)
      other, _acc -> raise(Error, message: "invalid attribute tuple: #{inspect(other)}")
    end)
  end

  defp normalize_attrs(other) do
    raise(Error, message: "invalid attributes: #{inspect(other)}")
  end

  defp normalize_attr_value(value) do
    cond do
      value in [nil, ""] -> value
      match?(%Raw{}, value) -> value
      match?(%Node{}, value) -> normalize_node(value)
      is_binary(value) or is_boolean(value) or is_integer(value) -> value
      is_atom(value) -> Atom.to_string(value)
      true -> value
    end
  end

  defp normalize_content(nil), do: nil
  defp normalize_content(%Raw{} = raw), do: raw
  defp normalize_content(binary) when is_binary(binary), do: binary

  defp normalize_content(list) when is_list(list) do
    if Enum.all?(list, &node_like?/1) do
      Enum.map(list, &normalize_node/1)
    else
      raise(Error, message: "content lists must contain nodes")
    end
  end

  defp normalize_content(value) do
    if node_like?(value) do
      [normalize_node(value)]
    else
      raise(Error, message: "unsupported node content: #{inspect(value)}")
    end
  end

  defp node_like?(%Node{}), do: true
  defp node_like?({_, _, _}), do: true
  defp node_like?({_, _}), do: true
  defp node_like?(value) when is_binary(value), do: false
  defp node_like?(_), do: false

  defmodule Encoder do
    import Bitwise

    alias ExWapp.Binary.{Node, Raw}
    alias ExWapp.Binary.Token
    alias ExWapp.JID

    defstruct data: []

    @spec new() :: %__MODULE__{}
    def new, do: %__MODULE__{data: []}

    @spec to_binary(%__MODULE__{}) :: binary()
    def to_binary(%__MODULE__{data: data}) do
      data
      |> Enum.reverse()
      |> IO.iodata_to_binary()
    end

    @spec write_node(%__MODULE__{}, Node.t()) :: %__MODULE__{}
    def write_node(encoder, %Node{tag: "0"}) do
      encoder
      |> push_byte(Token.list8())
      |> push_byte(Token.list_empty())
    end

    def write_node(encoder, %Node{} = node) do
      attrs = node.attrs || %{}
      attr_count = count_attributes(attrs)
      has_content = if node.content == nil, do: 0, else: 1
      list_size = 2 * attr_count + 1 + has_content

      encoder
      |> write_list_start(list_size)
      |> write_string(node.tag)
      |> write_attributes(attrs)
      |> maybe_write_content(node.content)
    end

    defp maybe_write_content(encoder, nil), do: encoder
    defp maybe_write_content(encoder, content), do: write(encoder, content)

    defp write(encoder, nil), do: push_byte(encoder, Token.list_empty())

    defp write(encoder, %JID{} = jid), do: write_jid(encoder, jid)

    defp write(encoder, %Raw{data: data}) when is_binary(data) do
      encoder
      |> write_byte_length(byte_size(data))
      |> push_bytes(data)
    end

    defp write(encoder, binary) when is_binary(binary), do: write_string(encoder, binary)

    defp write(encoder, value) when is_integer(value),
      do: write_string(encoder, Integer.to_string(value))

    defp write(encoder, value) when is_boolean(value),
      do: write_string(encoder, if(value, do: "true", else: "false"))

    defp write(encoder, list) when is_list(list) do
      if Enum.all?(list, &match?(%Node{}, &1)) do
        encoder = write_list_start(encoder, length(list))
        Enum.reduce(list, encoder, fn node, acc -> write_node(acc, node) end)
      else
        raise(Error, message: "unsupported list payload: #{inspect(list)}")
      end
    end

    defp write(_encoder, other),
      do: raise(Error, message: "unsupported payload type: #{inspect(other)}")

    defp write_string(encoder, value) do
      case Token.index_of_single_token(value) do
        {:ok, index} ->
          push_byte(encoder, index)

        :error ->
          case Token.index_of_double_token(value) do
            {:ok, dict, index} ->
              encoder
              |> push_byte(Token.dictionary0() + dict)
              |> push_byte(index)

            :error ->
              cond do
                validate_nibble?(value) -> write_packed_bytes(encoder, value, Token.nibble8())
                validate_hex?(value) -> write_packed_bytes(encoder, value, Token.hex8())
                true -> write_string_raw(encoder, value)
              end
          end
      end
    end

    defp write_string_raw(encoder, value) do
      bytes = :unicode.characters_to_binary(value)

      encoder
      |> write_byte_length(byte_size(bytes))
      |> push_bytes(bytes)
    end

    defp write_jid(encoder, %JID{} = jid) do
      cond do
        (jid.server in [JID.default_user_server(), JID.hidden_user_server()] and jid.device > 0) or
            jid.server == JID.hosted_server() ->
          encoder
          |> push_byte(Token.ad_jid())
          |> push_byte(JID.actual_agent(jid))
          |> push_byte(jid.device &&& 0xFF)
          |> write_string(jid.user)

        jid.server == JID.messenger_server() ->
          encoder
          |> push_byte(Token.fb_jid())
          |> write(jid.user)
          |> push_int16(jid.device)
          |> write(jid.server)

        jid.server == JID.interop_server() ->
          encoder
          |> push_byte(Token.interop_jid())
          |> write(jid.user)
          |> push_int16(jid.device)
          |> push_int16(jid.integrator)
          |> write(jid.server)

        true ->
          encoder
          |> push_byte(Token.jid_pair())
          |> write(if(jid.user == "", do: nil, else: jid.user))
          |> write(jid.server)
      end
    end

    defp write_attributes(encoder, attrs) do
      Enum.reduce(attrs, encoder, fn
        {_key, nil}, acc ->
          acc

        {_key, ""}, acc ->
          acc

        {key, value}, acc ->
          acc
          |> write_string(key)
          |> write(value)
      end)
    end

    defp count_attributes(attrs) do
      Enum.count(attrs, fn
        {_key, nil} -> false
        {_key, ""} -> false
        _ -> true
      end)
    end

    defp write_list_start(encoder, 0), do: push_byte(encoder, Token.list_empty())

    defp write_list_start(encoder, size) when size < 256 do
      encoder
      |> push_byte(Token.list8())
      |> push_int8(size)
    end

    defp write_list_start(encoder, size) do
      encoder
      |> push_byte(Token.list16())
      |> push_int16(size)
    end

    defp write_packed_bytes(encoder, value, tag) do
      if String.length(value) > Token.packed_max() do
        raise(Error, message: "too many bytes to pack")
      end

      length = byte_size(value)
      rounded = div(length + 1, 2)
      rounded = if rem(length, 2) == 0, do: rounded, else: rounded ||| 0x80

      encoder
      |> push_byte(tag)
      |> push_byte(rounded)
      |> do_write_packed(value, tag)
    end

    defp do_write_packed(encoder, value, tag) do
      packer =
        cond do
          tag == Token.nibble8() -> &pack_nibble/1
          tag == Token.hex8() -> &pack_hex/1
          true -> raise(Error, message: "invalid packed byte tag")
        end

      bytes = :binary.bin_to_list(value)

      chunks =
        if rem(length(bytes), 2) == 0 do
          Enum.chunk_every(bytes, 2)
        else
          Enum.chunk_every(bytes ++ [0], 2)
        end

      Enum.reduce(chunks, encoder, fn [part1, part2], acc ->
        push_byte(acc, packer.(part1) <<< 4 ||| packer.(part2))
      end)
    end

    defp pack_nibble(?-), do: 10
    defp pack_nibble(?.), do: 11
    defp pack_nibble(0), do: 15
    defp pack_nibble(digit) when digit in ?0..?9, do: digit - ?0

    defp pack_nibble(other),
      do: raise(Error, message: "invalid nibble character: #{inspect(other)}")

    defp pack_hex(0), do: 15
    defp pack_hex(digit) when digit in ?0..?9, do: digit - ?0
    defp pack_hex(letter) when letter in ?A..?F, do: 10 + letter - ?A
    defp pack_hex(other), do: raise(Error, message: "invalid hex character: #{inspect(other)}")

    defp validate_nibble?(value) do
      byte_size(value) <= Token.packed_max() and
        Enum.all?(:binary.bin_to_list(value), fn c ->
          c in [?-, ?., 0] or (?0 <= c and c <= ?9)
        end)
    end

    defp validate_hex?(value) do
      byte_size(value) <= Token.packed_max() and
        Enum.all?(:binary.bin_to_list(value), fn c ->
          (?0 <= c and c <= ?9) or (?A <= c and c <= ?F)
        end)
    end

    defp write_byte_length(encoder, length) when length < 256 do
      encoder
      |> push_byte(Token.binary8())
      |> push_int8(length)
    end

    defp write_byte_length(encoder, length) when length < 1 <<< 20 do
      encoder
      |> push_byte(Token.binary20())
      |> push_int20(length)
    end

    defp write_byte_length(encoder, length) do
      encoder
      |> push_byte(Token.binary32())
      |> push_int32(length)
    end

    defp push_byte(%__MODULE__{data: data} = encoder, byte) when is_integer(byte) do
      %{encoder | data: [<<byte &&& 0xFF>> | data]}
    end

    defp push_bytes(%__MODULE__{data: data} = encoder, bytes) do
      %{encoder | data: [bytes | data]}
    end

    defp push_int8(encoder, value), do: push_bytes(encoder, <<value::unsigned-integer-size(8)>>)
    defp push_int16(encoder, value), do: push_bytes(encoder, <<value::unsigned-integer-size(16)>>)

    defp push_int20(encoder, value) do
      b1 = value >>> 16 &&& 0x0F
      b2 = value >>> 8 &&& 0xFF
      b3 = value &&& 0xFF
      push_bytes(encoder, <<b1, b2, b3>>)
    end

    defp push_int32(encoder, value), do: push_bytes(encoder, <<value::unsigned-integer-size(32)>>)
  end

  defmodule Decoder do
    import Bitwise

    alias ExWapp.Binary.{Error, Node, Raw}
    alias ExWapp.Binary.Token
    alias ExWapp.JID

    defstruct data: <<>>, index: 0

    @spec new(binary()) :: %__MODULE__{}
    def new(data) when is_binary(data), do: %__MODULE__{data: data, index: 0}

    @spec bytes_remaining(%__MODULE__{}) :: non_neg_integer()
    def bytes_remaining(%__MODULE__{data: data, index: index}), do: byte_size(data) - index

    @spec read_node(%__MODULE__{}) :: {Node.t(), %__MODULE__{}}
    def read_node(decoder) do
      {tag_token, decoder} = read_int8(decoder)
      {list_size, decoder} = read_list_size(decoder, tag_token)
      {raw_desc, decoder} = read(decoder, true)

      tag =
        case raw_desc do
          nil -> raise(Error, message: "node tag is nil")
          tag when is_binary(tag) and tag != "" -> tag
          other -> raise(Error, message: "invalid node tag: #{inspect(other)}")
        end

      if list_size == 0 do
        raise(Error, message: "invalid node with empty list")
      end

      attr_pairs = div(list_size - 1, 2)

      {attrs, decoder} = read_attributes(decoder, attr_pairs)

      if rem(list_size, 2) == 1 do
        {%Node{tag: tag, attrs: attrs, content: nil}, decoder}
      else
        {content, decoder} = read(decoder, false)
        content = post_process_content(content)
        {%Node{tag: tag, attrs: attrs, content: content}, decoder}
      end
    end

    defp post_process_content(list) when is_list(list) do
      Enum.map(list, fn
        %Node{} = node -> node
        other -> raise(Error, message: "unexpected list content: #{inspect(other)}")
      end)
    end

    defp post_process_content(%Raw{} = raw), do: raw
    defp post_process_content(other), do: other

    defp read_attributes(decoder, 0), do: {%{}, decoder}

    defp read_attributes(decoder, count) do
      {pairs, decoder} =
        Enum.reduce(1..count, {[], decoder}, fn _, {acc, dec} ->
          {key, dec} = read(dec, true)

          key =
            case key do
              k when is_binary(k) ->
                k

              other ->
                raise(Error, message: "attribute key must be string, got #{inspect(other)}")
            end

          {value, dec} = read(dec, true)
          {[{key, value} | acc], dec}
        end)

      {Map.new(pairs), decoder}
    end

    defp read(%__MODULE__{} = decoder, as_string) do
      {tag, decoder} = read_int8(decoder)

      cond do
        tag == Token.list_empty() ->
          {nil, decoder}

        tag in [Token.list8(), Token.list16()] ->
          read_list(decoder, tag)

        tag == Token.binary8() ->
          read_length_prefixed(decoder, 1, as_string)

        tag == Token.binary20() ->
          read_length_prefixed(decoder, :int20, as_string)

        tag == Token.binary32() ->
          read_length_prefixed(decoder, 4, as_string)

        tag in [
          Token.dictionary0(),
          Token.dictionary1(),
          Token.dictionary2(),
          Token.dictionary3()
        ] ->
          {index, decoder} = read_int8(decoder)

          case Token.get_double_token(tag - Token.dictionary0(), index) do
            {:ok, token} -> {token, decoder}
            :error -> raise(Error, message: "double token out of range")
          end

        tag == Token.fb_jid() ->
          read_fb_jid(decoder)

        tag == Token.interop_jid() ->
          read_interop_jid(decoder)

        tag == Token.jid_pair() ->
          read_jid_pair(decoder)

        tag == Token.ad_jid() ->
          read_ad_jid(decoder)

        tag in [Token.nibble8(), Token.hex8()] ->
          read_packed(decoder, tag)

        tag >= 1 and tag < Token.single_byte_max() ->
          tokens = Token.single_byte_tokens()

          if tag < length(tokens) do
            {Enum.at(tokens, tag), decoder}
          else
            raise(Error, message: "invalid single byte token index #{tag}")
          end

        true ->
          raise(Error, message: "invalid token #{tag} at position #{decoder.index}")
      end
    end

    defp read_length_prefixed(decoder, :int20, as_string) do
      {length, decoder} = read_int20(decoder)
      read_bytes_or_string(decoder, length, as_string)
    end

    defp read_length_prefixed(decoder, bytes, as_string) do
      {length, decoder} = read_int(decoder, bytes)
      read_bytes_or_string(decoder, length, as_string)
    end

    defp read_bytes_or_string(decoder, length, true) do
      {data, decoder} = read_raw(decoder, length)
      {data, decoder}
    end

    defp read_bytes_or_string(decoder, length, false) do
      {data, decoder} = read_raw(decoder, length)
      {Raw.new(data), decoder}
    end

    defp read_packed(decoder, tag) do
      {length_byte, decoder} = read_int8(decoder)
      count = length_byte &&& 0x7F
      odd? = (length_byte &&& 0x80) != 0

      {chars, decoder} =
        Enum.reduce(1..count, {[], decoder}, fn _, {acc, dec} ->
          {byte, dec} = read_int8(dec)
          upper = unpack_byte(tag, byte >>> 4)
          lower = unpack_byte(tag, byte &&& 0x0F)
          {[lower, upper | acc], dec}
        end)

      chars = Enum.reverse(chars)
      chars = if odd?, do: List.delete_at(chars, -1), else: chars
      {IO.iodata_to_binary(chars), decoder}
    end

    defp unpack_byte(tag, value) do
      cond do
        tag == Token.nibble8() -> unpack_nibble(value)
        tag == Token.hex8() -> unpack_hex(value)
        true -> raise(Error, message: "unknown packed tag #{tag}")
      end
    end

    defp unpack_nibble(value) when value < 10, do: <<?0 + value>>
    defp unpack_nibble(10), do: <<?->>
    defp unpack_nibble(11), do: <<?.>>
    defp unpack_nibble(15), do: <<0>>
    defp unpack_nibble(value), do: raise(Error, message: "invalid nibble value #{value}")

    defp unpack_hex(value) when value < 10, do: <<?0 + value>>
    defp unpack_hex(value) when value < 16, do: <<?A + value - 10>>
    defp unpack_hex(value), do: raise(Error, message: "invalid hex value #{value}")

    defp read_list(decoder, tag) do
      {size, decoder} = read_list_size(decoder, tag)

      {nodes, decoder} =
        Enum.reduce(1..size, {[], decoder}, fn _, {acc, dec} ->
          {node, dec} = read_node(dec)
          {[node | acc], dec}
        end)

      {Enum.reverse(nodes), decoder}
    end

    defp read_jid_pair(decoder) do
      {user, decoder} = read(decoder, true)
      {server, decoder} = read(decoder, true)

      cond do
        server in [nil, ""] -> raise(Error, message: "JID pair missing server")
        user in [nil, ""] -> {JID.new("", server), decoder}
        true -> {JID.new(user, server), decoder}
      end
    end

    defp read_fb_jid(decoder) do
      {user, decoder} = read(decoder, true)
      {device, decoder} = read_int16(decoder)
      {server, decoder} = read(decoder, true)

      if server != JID.messenger_server() do
        raise(Error, message: "unexpected FB JID server #{inspect(server)}")
      end

      {JID.new(user, server) |> JID.with_device(device), decoder}
    end

    defp read_interop_jid(decoder) do
      {user, decoder} = read(decoder, true)
      {device, decoder} = read_int16(decoder)
      {integrator, decoder} = read_int16(decoder)
      {server, decoder} = read(decoder, true)

      if server != JID.interop_server() do
        raise(Error, message: "unexpected interop server #{inspect(server)}")
      end

      jid =
        JID.new(user, server)
        |> JID.with_device(device)
        |> JID.with_integrator(integrator)

      {jid, decoder}
    end

    defp read_ad_jid(decoder) do
      {agent, decoder} = read_int8(decoder)
      {device, decoder} = read_int8(decoder)
      {user, decoder} = read(decoder, true)
      {JID.new_ad(user, agent, device), decoder}
    end

    defp read_int8(decoder), do: read_int(decoder, 1)
    defp read_int16(decoder), do: read_int(decoder, 2)

    defp read_int20(%__MODULE__{data: data, index: index} = decoder) do
      ensure_bytes(decoder, 3)
      <<b1, b2, b3, _::binary>> = binary_part(data, index, 3)
      value = (b1 &&& 0x0F) <<< 16 ||| b2 <<< 8 ||| b3
      {value, %{decoder | index: index + 3}}
    end

    defp read_int(%__MODULE__{data: data, index: index} = decoder, bytes) do
      ensure_bytes(decoder, bytes)
      <<value::unsigned-integer-size(bytes * 8), _::binary>> = binary_part(data, index, bytes)
      {value, %{decoder | index: index + bytes}}
    end

    defp read_raw(%__MODULE__{data: data, index: index} = decoder, length) do
      ensure_bytes(decoder, length)
      {binary_part(data, index, length), %{decoder | index: index + length}}
    end

    defp read_list_size(decoder, tag) do
      cond do
        tag == Token.list_empty() -> {0, decoder}
        tag == Token.list8() -> read_int8(decoder)
        tag == Token.list16() -> read_int16(decoder)
        true -> raise(Error, message: "unknown list tag #{tag}")
      end
    end

    defp ensure_bytes(%__MODULE__{data: data, index: index}, amount) do
      if index + amount > byte_size(data) do
        raise(Error, message: "unexpected end of stream")
      end
    end
  end

  defimpl Inspect, for: Node do
    import Inspect.Algebra

    def inspect(%Node{tag: tag, attrs: attrs, content: content}, opts) do
      concat([
        "#Node<",
        Inspect.Algebra.to_doc(tag, opts),
        ", ",
        Inspect.Algebra.to_doc(attrs, opts),
        ", ",
        Inspect.Algebra.to_doc(content, opts),
        ">"
      ])
    end
  end
end
