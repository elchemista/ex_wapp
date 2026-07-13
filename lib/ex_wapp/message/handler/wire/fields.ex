defmodule ExWapp.Message.Handler.Wire.Fields do
  @moduledoc """
  Pure protobuf wire-field primitives used by inbound decoders.

  This module knows wire types, varints, fixed-width numbers, and
  length-delimited fields. It has no knowledge of WhatsApp message kinds.
  """

  @type wire_field :: {non_neg_integer(), 0 | 1 | 2 | 5, term()}

  @doc """
  Decodes all supported protobuf fields without raising.
  """
  @spec decode_safe(binary()) :: {:ok, [wire_field()]} | {:error, term()}
  def decode_safe(binary) when is_binary(binary), do: decode_wire_fields_acc(binary, [])

  @doc """
  Finds the first length-delimited value in an already-decoded field list.
  """
  @spec first_length_delimited([wire_field()], non_neg_integer()) :: binary() | nil
  def first_length_delimited(fields, field_num) when is_list(fields) do
    Enum.find_value(fields, fn
      {^field_num, 2, value} when is_binary(value) -> value
      _ -> nil
    end)
  end

  @doc """
  Returns every length-delimited value for a field in decoded order.
  """
  @spec all_length_delimited([wire_field()], non_neg_integer()) :: [binary()]
  def all_length_delimited(fields, field_num) when is_list(fields) do
    Enum.flat_map(fields, fn
      {^field_num, 2, value} when is_binary(value) -> [value]
      _ -> []
    end)
  end

  @doc """
  Finds the first varint value in an already-decoded field list.
  """
  @spec first_varint([wire_field()], non_neg_integer()) :: integer() | nil
  def first_varint(fields, field_num) when is_list(fields) do
    Enum.find_value(fields, fn
      {^field_num, 0, value} when is_integer(value) -> value
      _ -> nil
    end)
  end

  @doc """
  Finds a length-delimited field directly in a protobuf payload.
  """
  @spec find_length_delimited(binary(), non_neg_integer()) ::
          {:ok, binary()} | {:error, term()}
  def find_length_delimited(binary, field_num) when is_binary(binary) do
    do_find_length_delimited_field(binary, field_num)
  end

  @doc """
  Returns a binary field value or nil.
  """
  @spec bytes(binary(), non_neg_integer()) :: binary() | nil
  def bytes(payload, field) do
    case find_length_delimited(payload, field) do
      {:ok, value} -> value
      _ -> nil
    end
  end

  @doc """
  Returns a varint field value or nil.
  """
  @spec varint(binary(), non_neg_integer()) :: integer() | nil
  def varint(payload, wanted_field), do: do_find_varint_field(payload, wanted_field)

  @doc """
  Returns a protobuf boolean field value or nil.
  """
  @spec bool(binary(), non_neg_integer()) :: boolean() | nil
  def bool(payload, field) do
    case varint(payload, field) do
      0 -> false
      1 -> true
      _ -> nil
    end
  end

  @doc """
  Returns a fixed64 double field value or nil.
  """
  @spec double(binary(), non_neg_integer()) :: float() | nil
  def double(payload, field), do: do_find_fixed_field(payload, field, 1)

  @doc """
  Returns a fixed32 float field value or nil.
  """
  @spec float(binary(), non_neg_integer()) :: float() | nil
  def float(payload, field), do: do_find_fixed_field(payload, field, 5)

  @doc """
  Collects every length-delimited value in a protobuf payload.
  """
  @spec collect_length_delimited_values(binary()) :: {:ok, [binary()]} | {:error, term()}
  def collect_length_delimited_values(binary) when is_binary(binary) do
    collect_length_delimited_fields(binary)
  end

  @spec decode_wire_fields_acc(binary(), [wire_field()]) ::
          {:ok, [wire_field()]} | {:error, term()}
  defp decode_wire_fields_acc(<<>>, acc), do: {:ok, Enum.reverse(acc)}

  defp decode_wire_fields_acc(binary, acc) when is_binary(binary) do
    with {:ok, tag, rest} <- decode_varint_safe(binary),
         wire_type <- Bitwise.band(tag, 0x07),
         field_num <- Bitwise.bsr(tag, 3) do
      decode_wire_field_acc(wire_type, rest, field_num, acc)
    end
  end

  @spec decode_wire_field_acc(non_neg_integer(), binary(), non_neg_integer(), [wire_field()]) ::
          {:ok, [wire_field()]} | {:error, term()}
  defp decode_wire_field_acc(0, rest, field_num, acc) do
    with {:ok, value, tail} <- decode_varint_safe(rest) do
      decode_wire_fields_acc(tail, [{field_num, 0, value} | acc])
    end
  end

  defp decode_wire_field_acc(1, rest, field_num, acc) do
    if byte_size(rest) >= 8 do
      <<_skip::binary-size(8), tail::binary>> = rest
      decode_wire_fields_acc(tail, [{field_num, 1, :fixed64} | acc])
    else
      {:error, :invalid_fixed64}
    end
  end

  defp decode_wire_field_acc(2, rest, field_num, acc) do
    with {:ok, len, tail} <- decode_varint_safe(rest),
         true <- byte_size(tail) >= len do
      <<value::binary-size(^len), next::binary>> = tail
      decode_wire_fields_acc(next, [{field_num, 2, value} | acc])
    else
      false -> {:error, :invalid_length}
    end
  end

  defp decode_wire_field_acc(5, rest, field_num, acc) do
    if byte_size(rest) >= 4 do
      <<_skip::binary-size(4), tail::binary>> = rest
      decode_wire_fields_acc(tail, [{field_num, 5, :fixed32} | acc])
    else
      {:error, :invalid_fixed32}
    end
  end

  defp decode_wire_field_acc(wire_type, _rest, _field_num, _acc),
    do: {:error, {:unsupported_wire_type, wire_type}}

  @spec decode_varint_safe(binary()) ::
          {:ok, non_neg_integer(), binary()} | {:error, atom()}
  defp decode_varint_safe(binary), do: decode_varint_safe(binary, 0, 0)

  @spec decode_varint_safe(binary(), non_neg_integer(), non_neg_integer()) ::
          {:ok, non_neg_integer(), binary()} | {:error, atom()}
  defp decode_varint_safe(_, _, shift) when shift > 63, do: {:error, :invalid_varint}
  defp decode_varint_safe(<<>>, _, _), do: {:error, :invalid_varint}

  defp decode_varint_safe(<<byte, rest::binary>>, acc, shift) do
    value = Bitwise.bor(acc, Bitwise.bsl(Bitwise.band(byte, 0x7F), shift))

    if Bitwise.band(byte, 0x80) == 0 do
      {:ok, value, rest}
    else
      decode_varint_safe(rest, value, shift + 7)
    end
  end

  @spec do_find_length_delimited_field(binary(), non_neg_integer()) ::
          {:ok, binary()} | {:error, term()}
  defp do_find_length_delimited_field(<<>>, _field_num), do: {:error, :not_found}

  defp do_find_length_delimited_field(binary, field_num) do
    with {:ok, tag, rest} <- decode_varint(binary),
         wire_type <- Bitwise.band(tag, 0x07),
         field <- Bitwise.bsr(tag, 3) do
      find_length_delimited_by_wire_type(wire_type, rest, field, field_num)
    end
  end

  @spec find_length_delimited_by_wire_type(
          non_neg_integer(),
          binary(),
          non_neg_integer(),
          non_neg_integer()
        ) :: {:ok, binary()} | {:error, term()}
  defp find_length_delimited_by_wire_type(0, rest, _field, field_num) do
    with {:ok, _value, tail} <- decode_varint(rest) do
      do_find_length_delimited_field(tail, field_num)
    end
  end

  defp find_length_delimited_by_wire_type(1, rest, _field, field_num) do
    if byte_size(rest) >= 8 do
      <<_skip::binary-size(8), tail::binary>> = rest
      do_find_length_delimited_field(tail, field_num)
    else
      {:error, :invalid_fixed64}
    end
  end

  defp find_length_delimited_by_wire_type(2, rest, field, field_num) do
    with {:ok, len, tail} <- decode_varint(rest),
         true <- byte_size(tail) >= len do
      <<value::binary-size(^len), next::binary>> = tail

      if field == field_num,
        do: {:ok, value},
        else: do_find_length_delimited_field(next, field_num)
    else
      false -> {:error, :invalid_length}
    end
  end

  defp find_length_delimited_by_wire_type(5, rest, _field, field_num) do
    if byte_size(rest) >= 4 do
      <<_skip::binary-size(4), tail::binary>> = rest
      do_find_length_delimited_field(tail, field_num)
    else
      {:error, :invalid_fixed32}
    end
  end

  defp find_length_delimited_by_wire_type(wire_type, _rest, _field, _field_num),
    do: {:error, {:unsupported_wire_type, wire_type}}

  @spec decode_varint(binary()) ::
          {:ok, non_neg_integer(), binary()} | {:error, atom()}
  defp decode_varint(binary), do: decode_varint(binary, 0, 0)

  @spec decode_varint(binary(), non_neg_integer(), non_neg_integer()) ::
          {:ok, non_neg_integer(), binary()} | {:error, atom()}
  defp decode_varint(_, _, shift) when shift > 63, do: {:error, :invalid_varint}
  defp decode_varint(<<>>, _, _), do: {:error, :invalid_varint}

  defp decode_varint(<<byte, rest::binary>>, acc, shift) do
    value = Bitwise.bor(acc, Bitwise.bsl(Bitwise.band(byte, 0x7F), shift))

    if Bitwise.band(byte, 0x80) == 0,
      do: {:ok, value, rest},
      else: decode_varint(rest, value, shift + 7)
  end

  @spec collect_length_delimited_fields(binary()) ::
          {:ok, [binary()]} | {:error, term()}
  defp collect_length_delimited_fields(binary), do: collect_length_delimited_fields(binary, [])

  @spec collect_length_delimited_fields(binary(), [binary()]) ::
          {:ok, [binary()]} | {:error, term()}
  defp collect_length_delimited_fields(<<>>, acc), do: {:ok, Enum.reverse(acc)}

  defp collect_length_delimited_fields(binary, acc) do
    with {:ok, tag, rest} <- decode_varint(binary),
         wire_type <- Bitwise.band(tag, 0x07) do
      collect_length_delimited_by_wire_type(wire_type, rest, acc)
    end
  end

  @spec collect_length_delimited_by_wire_type(
          non_neg_integer(),
          binary(),
          [binary()]
        ) :: {:ok, [binary()]} | {:error, term()}
  defp collect_length_delimited_by_wire_type(0, rest, acc) do
    with {:ok, _value, tail} <- decode_varint(rest) do
      collect_length_delimited_fields(tail, acc)
    end
  end

  defp collect_length_delimited_by_wire_type(1, rest, acc) do
    if byte_size(rest) >= 8 do
      <<_skip::binary-size(8), tail::binary>> = rest
      collect_length_delimited_fields(tail, acc)
    else
      {:error, :invalid_fixed64}
    end
  end

  defp collect_length_delimited_by_wire_type(2, rest, acc) do
    with {:ok, len, tail} <- decode_varint(rest),
         true <- byte_size(tail) >= len do
      <<value::binary-size(^len), next::binary>> = tail
      collect_length_delimited_fields(next, [value | acc])
    else
      false -> {:error, :invalid_length}
    end
  end

  defp collect_length_delimited_by_wire_type(5, rest, acc) do
    if byte_size(rest) >= 4 do
      <<_skip::binary-size(4), tail::binary>> = rest
      collect_length_delimited_fields(tail, acc)
    else
      {:error, :invalid_fixed32}
    end
  end

  defp collect_length_delimited_by_wire_type(wire_type, _rest, _acc),
    do: {:error, {:unsupported_wire_type, wire_type}}

  @spec do_find_varint_field(binary(), non_neg_integer()) :: integer() | nil
  defp do_find_varint_field(<<>>, _wanted_field), do: nil

  defp do_find_varint_field(binary, wanted_field) do
    with {:ok, tag, rest} <- decode_varint(binary),
         wire_type <- Bitwise.band(tag, 0x07),
         field <- Bitwise.bsr(tag, 3) do
      find_varint_by_wire_type(wire_type, rest, field, wanted_field)
    else
      _ -> nil
    end
  end

  @spec find_varint_by_wire_type(
          non_neg_integer(),
          binary(),
          non_neg_integer(),
          non_neg_integer()
        ) :: integer() | nil
  defp find_varint_by_wire_type(0, rest, field, wanted_field) do
    case decode_varint(rest) do
      {:ok, value, tail} ->
        if field == wanted_field, do: value, else: do_find_varint_field(tail, wanted_field)

      _ ->
        nil
    end
  end

  defp find_varint_by_wire_type(1, rest, _field, wanted_field) do
    if byte_size(rest) >= 8 do
      <<_skip::binary-size(8), tail::binary>> = rest
      do_find_varint_field(tail, wanted_field)
    end
  end

  defp find_varint_by_wire_type(2, rest, _field, wanted_field) do
    with {:ok, len, tail} <- decode_varint(rest),
         true <- byte_size(tail) >= len do
      <<_skip::binary-size(^len), next::binary>> = tail
      do_find_varint_field(next, wanted_field)
    else
      _ -> nil
    end
  end

  defp find_varint_by_wire_type(5, rest, _field, wanted_field) do
    if byte_size(rest) >= 4 do
      <<_skip::binary-size(4), tail::binary>> = rest
      do_find_varint_field(tail, wanted_field)
    end
  end

  defp find_varint_by_wire_type(_wire_type, _rest, _field, _wanted_field), do: nil

  @spec do_find_fixed_field(binary(), non_neg_integer(), 1 | 5) :: float() | nil
  defp do_find_fixed_field(<<>>, _wanted_field, _wanted_wire_type), do: nil

  defp do_find_fixed_field(binary, wanted_field, wanted_wire_type) do
    case decode_varint(binary) do
      {:ok, tag, rest} ->
        wire_type = Bitwise.band(tag, 0x07)
        field = Bitwise.bsr(tag, 3)
        find_fixed_by_wire_type(wire_type, rest, field, wanted_field, wanted_wire_type)

      _ ->
        nil
    end
  end

  @spec find_fixed_by_wire_type(
          non_neg_integer(),
          binary(),
          non_neg_integer(),
          non_neg_integer(),
          1 | 5
        ) :: float() | nil
  defp find_fixed_by_wire_type(0, rest, _field, wanted_field, wanted_wire_type) do
    case decode_varint(rest) do
      {:ok, _value, tail} -> do_find_fixed_field(tail, wanted_field, wanted_wire_type)
      _ -> nil
    end
  end

  defp find_fixed_by_wire_type(1, rest, field, wanted_field, wanted_wire_type) do
    if byte_size(rest) >= 8 do
      <<value::little-float-64, tail::binary>> = rest

      if field == wanted_field and wanted_wire_type == 1,
        do: value,
        else: do_find_fixed_field(tail, wanted_field, wanted_wire_type)
    end
  end

  defp find_fixed_by_wire_type(2, rest, _field, wanted_field, wanted_wire_type) do
    with {:ok, len, tail} <- decode_varint(rest),
         true <- byte_size(tail) >= len do
      <<_value::binary-size(^len), next::binary>> = tail
      do_find_fixed_field(next, wanted_field, wanted_wire_type)
    else
      _ -> nil
    end
  end

  defp find_fixed_by_wire_type(5, rest, field, wanted_field, wanted_wire_type) do
    if byte_size(rest) >= 4 do
      <<value::little-float-32, tail::binary>> = rest

      if field == wanted_field and wanted_wire_type == 5,
        do: value,
        else: do_find_fixed_field(tail, wanted_field, wanted_wire_type)
    end
  end

  defp find_fixed_by_wire_type(_wire_type, _rest, _field, _wanted_field, _wanted_wire_type),
    do: nil
end
