defmodule ExWapp.Message.Handler.Wire do
  @moduledoc false

  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.Common

  @max_message_decode_depth 6

  @spec extract_message_content(term(), term()) :: map()
  def extract_message_content(nil, _type), do: %{text: nil, media: nil}

  def extract_message_content(content, _type) when is_binary(content),
    do: %{text: content, media: nil}

  def extract_message_content(content, _type) when is_list(content) do
    enc_candidates = extract_enc_candidates(content)
    extract_list_message_content(content, enc_candidates)
  end

  def extract_message_content(_, _), do: %{text: nil, media: nil}

  @spec apply_media_from_plaintext(map(), binary()) :: map()
  def apply_media_from_plaintext(message_data, plaintext) when is_binary(plaintext) do
    case extract_media_ref(plaintext) do
      nil ->
        message_data

      %{type: type, ref: ref, caption: caption} ->
        message_data
        |> Map.put(:media, ref)
        |> Map.put(:media_type, type)
        |> Map.update(:text, caption, fn existing -> existing || caption end)
    end
  end

  @spec classify_decrypted_content(binary(), non_neg_integer()) ::
          {:protocol | :user_message, binary() | nil}
  def classify_decrypted_content(_payload, sender_key_distribution_count)
      when sender_key_distribution_count > 0 do
    {:protocol, nil}
  end

  def classify_decrypted_content(payload, _sender_key_distribution_count)
      when is_binary(payload) do
    case find_length_delimited_field(payload, 12) do
      {:ok, _protocol_msg} ->
        {:protocol, nil}

      _ ->
        case decode_message_text_recursive(payload, 0) do
          {:ok, text} -> {:user_message, text}
          :error -> {:user_message, nil}
        end
    end
  end

  @spec decode_wire_fields_safe(binary()) :: {:ok, list()} | {:error, term()}
  def decode_wire_fields_safe(binary) when is_binary(binary),
    do: decode_wire_fields_acc(binary, [])

  @spec find_first_ld_field(list(), non_neg_integer()) :: binary() | nil
  def find_first_ld_field(fields, field_num) when is_list(fields) do
    Enum.find_value(fields, fn
      {^field_num, 2, value} when is_binary(value) -> value
      _ -> nil
    end)
  end

  @spec find_all_ld_fields(list(), non_neg_integer()) :: [binary()]
  def find_all_ld_fields(fields, field_num) when is_list(fields) do
    Enum.flat_map(fields, fn
      {^field_num, 2, value} when is_binary(value) -> [value]
      _ -> []
    end)
  end

  @spec find_first_varint_field(list(), non_neg_integer()) :: integer() | nil
  def find_first_varint_field(fields, field_num) when is_list(fields) do
    Enum.find_value(fields, fn
      {^field_num, 0, value} when is_integer(value) -> value
      _ -> nil
    end)
  end

  @spec find_length_delimited_field(binary(), non_neg_integer()) ::
          {:ok, binary()} | {:error, term()}
  def find_length_delimited_field(binary, field_num) when is_binary(binary) do
    do_find_length_delimited_field(binary, field_num)
  end

  @spec field_bytes(binary(), non_neg_integer()) :: binary() | nil
  def field_bytes(payload, field) do
    case find_length_delimited_field(payload, field) do
      {:ok, value} -> value
      _ -> nil
    end
  end

  @spec field_varint(binary(), non_neg_integer()) :: integer() | nil
  def field_varint(payload, wanted_field), do: do_find_varint_field(payload, wanted_field)

  @spec field_bool(binary(), non_neg_integer()) :: boolean() | nil
  def field_bool(payload, field) do
    case field_varint(payload, field) do
      0 -> false
      1 -> true
      _ -> nil
    end
  end

  defp extract_list_message_content(
         _content,
         [%{enc_type: enc_type, enc_version: enc_version, ciphertext: ciphertext} | _] =
           enc_candidates
       ) do
    %{
      text: "(encrypted: #{enc_type})",
      media: nil,
      encrypted: true,
      enc_type: enc_type,
      enc_version: enc_version,
      ciphertext: ciphertext,
      enc_candidates: enc_candidates
    }
  end

  defp extract_list_message_content(content, []) do
    case Common.find_child_node(content, "unavailable") do
      %Node{} = unavailable_node ->
        %{
          text: nil,
          media: nil,
          placeholder_unavailable: true,
          unavailable_type: Common.node_attr(unavailable_node, "type")
        }

      _ ->
        extract_plain_body_content(content)
    end
  end

  defp extract_plain_body_content(content) do
    case Common.find_child_node(content, "body") do
      %Node{content: body} when is_binary(body) -> %{text: body, media: nil}
      _ -> %{text: nil, media: nil}
    end
  end

  defp extract_enc_candidates(content) when is_list(content) do
    do_extract_enc_candidates(content, nil, [])
    |> Enum.reverse()
  end

  defp extract_enc_candidates(_), do: []

  defp do_extract_enc_candidates([], _current_to_jid, acc), do: acc

  defp do_extract_enc_candidates([node | rest], current_to_jid, acc) do
    acc =
      case node do
        %Node{tag: "enc", attrs: enc_attrs, content: enc_content} ->
          [
            %{
              enc_type: Map.get(enc_attrs, "type", "msg"),
              enc_version: Common.parse_enc_version(Map.get(enc_attrs, "v")),
              ciphertext: Common.normalize_content(enc_content),
              to_jid: Common.normalize_jid_with_device(current_to_jid)
            }
            | acc
          ]

        %Node{tag: "to", attrs: to_attrs, content: nested} when is_list(nested) ->
          do_extract_enc_candidates(nested, Map.get(to_attrs, "jid"), acc)

        %Node{content: nested} when is_list(nested) ->
          do_extract_enc_candidates(nested, current_to_jid, acc)

        _ ->
          acc
      end

    do_extract_enc_candidates(rest, current_to_jid, acc)
  end

  defp extract_media_ref(message_payload) do
    cond do
      match?({:ok, _}, find_length_delimited_field(message_payload, 3)) ->
        {:ok, payload} = find_length_delimited_field(message_payload, 3)
        build_media_ref(:image, payload)

      match?({:ok, _}, find_length_delimited_field(message_payload, 8)) ->
        {:ok, payload} = find_length_delimited_field(message_payload, 8)
        build_media_ref(:audio, payload)

      true ->
        nil
    end
  end

  defp build_media_ref(:image, payload) do
    %{
      type: :image,
      caption: field_bytes(payload, 3),
      ref: %ExWapp.Media.Ref{
        type: :image,
        url: field_bytes(payload, 1),
        mimetype: field_bytes(payload, 2),
        file_sha256: field_bytes(payload, 4),
        file_length: field_varint(payload, 5),
        media_key: field_bytes(payload, 8),
        file_enc_sha256: field_bytes(payload, 9),
        direct_path: field_bytes(payload, 11),
        metadata: %{
          height: field_varint(payload, 6),
          width: field_varint(payload, 7),
          media_key_timestamp: field_varint(payload, 12),
          thumbnail: field_bytes(payload, 16)
        }
      }
    }
  end

  defp build_media_ref(:audio, payload) do
    %{
      type: :audio,
      caption: nil,
      ref: %ExWapp.Media.Ref{
        type: :audio,
        url: field_bytes(payload, 1),
        mimetype: field_bytes(payload, 2),
        file_sha256: field_bytes(payload, 3),
        file_length: field_varint(payload, 4),
        media_key: field_bytes(payload, 7),
        file_enc_sha256: field_bytes(payload, 8),
        direct_path: field_bytes(payload, 9),
        metadata: %{
          seconds: field_varint(payload, 5),
          ptt: field_bool(payload, 6),
          media_key_timestamp: field_varint(payload, 10),
          waveform: field_bytes(payload, 19)
        }
      }
    }
  end

  defp decode_message_text_recursive(_payload, depth) when depth > @max_message_decode_depth,
    do: :error

  defp decode_message_text_recursive(payload, depth) do
    case decode_message_text_shallow(payload) do
      {:ok, text} -> {:ok, text}
      :error -> decode_nested_message_text(payload, depth)
    end
  end

  defp decode_nested_message_text(payload, depth) do
    case collect_length_delimited_fields(payload) do
      {:ok, nested_values} ->
        Enum.reduce_while(nested_values, :error, fn nested, _acc ->
          reduce_nested_message_text(nested, depth)
        end)

      {:error, _reason} ->
        :error
    end
  end

  defp reduce_nested_message_text(nested, depth) do
    case decode_message_text_recursive(nested, depth + 1) do
      {:ok, text} -> {:halt, {:ok, text}}
      :error -> {:cont, :error}
    end
  end

  defp decode_message_text_shallow(payload) do
    with {:ok, conversation} <- find_length_delimited_field(payload, 1),
         true <- valid_text_payload?(conversation) do
      {:ok, conversation}
    else
      _ ->
        with {:ok, extended} <- find_length_delimited_field(payload, 6),
             {:ok, text} <- find_length_delimited_field(extended, 1),
             true <- valid_text_payload?(text) do
          {:ok, text}
        else
          _ -> :error
        end
    end
  end

  defp valid_text_payload?(value) when is_binary(value), do: value != "" and String.valid?(value)

  defp decode_wire_fields_acc(<<>>, acc), do: {:ok, Enum.reverse(acc)}

  defp decode_wire_fields_acc(binary, acc) when is_binary(binary) do
    with {:ok, tag, rest} <- decode_varint_safe(binary),
         wire_type <- Bitwise.band(tag, 0x07),
         field_num <- Bitwise.bsr(tag, 3) do
      decode_wire_field_acc(wire_type, rest, field_num, acc)
    end
  end

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
      <<value::binary-size(len), next::binary>> = tail
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

  defp decode_varint_safe(binary), do: decode_varint_safe(binary, 0, 0)
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

  defp do_find_length_delimited_field(<<>>, _field_num), do: {:error, :not_found}

  defp do_find_length_delimited_field(binary, field_num) do
    with {:ok, tag, rest} <- decode_varint(binary),
         wire_type <- Bitwise.band(tag, 0x07),
         field <- Bitwise.bsr(tag, 3) do
      find_length_delimited_by_wire_type(wire_type, rest, field, field_num)
    end
  end

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
      <<value::binary-size(len), next::binary>> = tail

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

  defp decode_varint(binary), do: decode_varint(binary, 0, 0)
  defp decode_varint(_, _, shift) when shift > 63, do: {:error, :invalid_varint}
  defp decode_varint(<<>>, _, _), do: {:error, :invalid_varint}

  defp decode_varint(<<byte, rest::binary>>, acc, shift) do
    value = Bitwise.bor(acc, Bitwise.bsl(Bitwise.band(byte, 0x7F), shift))

    if Bitwise.band(byte, 0x80) == 0,
      do: {:ok, value, rest},
      else: decode_varint(rest, value, shift + 7)
  end

  defp collect_length_delimited_fields(binary), do: collect_length_delimited_fields(binary, [])
  defp collect_length_delimited_fields(<<>>, acc), do: {:ok, Enum.reverse(acc)}

  defp collect_length_delimited_fields(binary, acc) do
    with {:ok, tag, rest} <- decode_varint(binary),
         wire_type <- Bitwise.band(tag, 0x07) do
      collect_length_delimited_by_wire_type(wire_type, rest, acc)
    end
  end

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
      <<value::binary-size(len), next::binary>> = tail
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
      <<_skip::binary-size(len), next::binary>> = tail
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
end
