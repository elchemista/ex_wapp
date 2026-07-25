defmodule ExWapp.Proto.HistorySync do
  @moduledoc """
  Minimal parser for WhatsApp history sync payloads embedded in protocol messages.

  Mirrors the flow used in reference clients:
  - `Message.protocolMessage.historySyncNotification`
  - `initialHistBootstrapInlinePayload` (zlib-compressed)
  - `HistorySync.conversations`
  """

  import Bitwise

  alias ExWapp.JID

  @type conversation_message :: %{
          id: String.t() | nil,
          from_me: boolean(),
          timestamp: non_neg_integer() | nil,
          text: String.t() | nil,
          participant: String.t() | nil,
          remote_jid: String.t() | nil,
          order_id: non_neg_integer() | nil
        }

  @type conversation :: %{
          jid: String.t(),
          name: String.t() | nil,
          unread_count: non_neg_integer() | nil,
          last_message_timestamp: non_neg_integer() | nil,
          pinned: boolean() | nil,
          archived: boolean() | nil,
          muted_until: non_neg_integer() | nil,
          is_group: boolean(),
          pn_jid: String.t() | nil,
          lid_jid: String.t() | nil,
          tc_token: binary() | nil,
          tc_token_timestamp: non_neg_integer() | nil,
          tc_token_sender_timestamp: non_neg_integer() | nil,
          messages: [conversation_message()]
        }

  @type t :: %{
          sync_type: non_neg_integer() | nil,
          conversations: [conversation()],
          lid_mappings: [{String.t(), String.t()}]
        }

  @max_message_text_decode_depth 6
  @jid_like_payload_pattern ~r/^[0-9+:-]+@(?:s\.whatsapp\.net|g\.us|lid|hosted\.lid)$/

  @spec extract_from_message(binary()) :: {:ok, t()} | :not_history_sync | {:error, term()}
  def extract_from_message(message_payload) when is_binary(message_payload) do
    with {:ok, message_fields} <- decode_wire_fields(message_payload),
         protocol_message when is_binary(protocol_message) <-
           first_length_delimited_field(message_fields, 12),
         {:ok, protocol_fields} <- decode_wire_fields(protocol_message),
         history_notification when is_binary(history_notification) <-
           first_length_delimited_field(protocol_fields, 6),
         {:ok, notification_fields} <- decode_wire_fields(history_notification) do
      sync_type_from_notification = first_varint_field(notification_fields, 6)

      case first_length_delimited_field(notification_fields, 11) do
        nil ->
          {:error, :history_sync_download_required}

        inline_payload ->
          parse_inline_history_payload(inline_payload, sync_type_from_notification)
      end
    else
      nil ->
        :not_history_sync

      {:error, _reason} = error ->
        error
    end
  end

  def extract_from_message(_), do: :not_history_sync

  defp parse_inline_history_payload(inline_payload, sync_type_from_notification) do
    with {:ok, history_payload} <- inflate_history_payload(inline_payload),
         {:ok, history_fields} <- decode_wire_fields(history_payload) do
      conversations =
        history_fields
        |> all_length_delimited_fields(2)
        |> Enum.map(&parse_conversation/1)
        |> Enum.reject(&is_nil/1)

      explicit_mappings =
        history_fields
        |> all_length_delimited_fields(15)
        |> Enum.map(&parse_phone_number_lid_mapping/1)
        |> Enum.reject(&is_nil/1)

      conversation_mappings =
        conversations
        |> Enum.map(&conversation_mapping/1)
        |> Enum.reject(&is_nil/1)

      {:ok,
       %{
         sync_type: first_varint_field(history_fields, 1) || sync_type_from_notification,
         conversations: conversations,
         lid_mappings: Enum.uniq(explicit_mappings ++ conversation_mappings)
       }}
    end
  end

  defp parse_conversation(conversation_payload) when is_binary(conversation_payload) do
    with {:ok, fields} <- decode_wire_fields(conversation_payload),
         jid_raw when is_binary(jid_raw) <- first_length_delimited_field(fields, 1),
         jid when is_binary(jid) <- normalize_non_empty_jid(jid_raw) do
      %{
        jid: jid,
        name:
          first_non_empty([
            normalize_optional_text(first_length_delimited_field(fields, 38)),
            normalize_optional_text(first_length_delimited_field(fields, 13)),
            normalize_optional_text(first_length_delimited_field(fields, 43))
          ]),
        unread_count: first_non_neg_integer_field(fields, [6]),
        last_message_timestamp: first_non_neg_integer_field(fields, [5, 12]),
        pinned: parse_optional_boolean(first_varint_field(fields, 24)),
        archived: parse_optional_boolean(first_varint_field(fields, 16)),
        muted_until: first_non_neg_integer_field(fields, [25]),
        is_group: JID.group?(jid),
        pn_jid: normalize_optional_jid(first_length_delimited_field(fields, 39)),
        lid_jid: normalize_optional_jid(first_length_delimited_field(fields, 42)),
        tc_token: first_length_delimited_field(fields, 21),
        tc_token_timestamp: first_varint_field(fields, 22),
        tc_token_sender_timestamp: first_varint_field(fields, 28),
        messages: parse_conversation_messages(fields)
      }
    else
      _ ->
        nil
    end
  end

  defp parse_conversation(_), do: nil

  defp parse_conversation_messages(fields) when is_list(fields) do
    fields
    |> all_length_delimited_fields(2)
    |> Enum.map(&parse_history_sync_message/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_history_sync_message(payload) when is_binary(payload) do
    with {:ok, fields} <- decode_wire_fields(payload),
         web_message when is_binary(web_message) <- first_length_delimited_field(fields, 1),
         parsed when is_map(parsed) <- parse_web_message_info(web_message) do
      Map.put(parsed, :order_id, first_varint_field(fields, 2))
    else
      _ -> nil
    end
  end

  defp parse_history_sync_message(_), do: nil

  defp parse_web_message_info(payload) when is_binary(payload) do
    case decode_wire_fields(payload) do
      {:ok, fields} ->
        key = parse_message_key(first_length_delimited_field(fields, 1))

        timestamp =
          case first_varint_field(fields, 3) do
            value when is_integer(value) and value >= 0 -> value
            _ -> nil
          end

        text = extract_web_message_text(first_length_delimited_field(fields, 2))

        participant =
          first_non_empty([
            normalize_optional_jid(first_length_delimited_field(fields, 9)),
            Map.get(key, :participant)
          ])

        id = Map.get(key, :id)

        if is_binary(id) or is_integer(timestamp) or is_binary(text) do
          %{
            id: id,
            from_me: Map.get(key, :from_me, false),
            timestamp: timestamp,
            text: text,
            participant: participant,
            remote_jid: Map.get(key, :remote_jid)
          }
        else
          nil
        end

      _ ->
        nil
    end
  end

  defp parse_message_key(payload) when is_binary(payload) do
    case decode_wire_fields(payload) do
      {:ok, fields} ->
        %{
          remote_jid: normalize_optional_jid(first_length_delimited_field(fields, 1)),
          from_me: parse_optional_boolean(first_varint_field(fields, 2)) || false,
          id: normalize_optional_text(first_length_delimited_field(fields, 3)),
          participant: normalize_optional_jid(first_length_delimited_field(fields, 4))
        }

      _ ->
        %{remote_jid: nil, from_me: false, id: nil, participant: nil}
    end
  end

  defp parse_message_key(_), do: %{remote_jid: nil, from_me: false, id: nil, participant: nil}

  defp extract_web_message_text(payload) when is_binary(payload) do
    case decode_message_text_recursive(payload, 0) do
      {:ok, text} -> text
      :error -> nil
    end
  end

  defp extract_web_message_text(_), do: nil

  defp decode_message_text_recursive(_payload, depth) when depth > @max_message_text_decode_depth,
    do: :error

  defp decode_message_text_recursive(payload, depth) when is_binary(payload) do
    case decode_message_text_shallow(payload) do
      {:ok, text} ->
        {:ok, text}

      :error ->
        decode_nested_message_text(payload, depth)
    end
  end

  defp decode_message_text_recursive(_payload, _depth), do: :error

  defp decode_nested_message_text(payload, depth) do
    case collect_length_delimited_fields(payload) do
      {:ok, nested_values} ->
        Enum.reduce_while(nested_values, :error, fn nested, _acc ->
          reduce_nested_text(nested, depth)
        end)

      {:error, _reason} ->
        :error
    end
  end

  defp reduce_nested_text(nested_payload, depth) do
    case decode_message_text_recursive(nested_payload, depth + 1) do
      {:ok, text} -> {:halt, {:ok, text}}
      :error -> {:cont, :error}
    end
  end

  defp decode_message_text_shallow(payload) when is_binary(payload) do
    with {:ok, fields} <- decode_wire_fields(payload),
         conversation when is_binary(conversation) <- first_length_delimited_field(fields, 1),
         true <- valid_text_payload?(conversation) do
      {:ok, conversation}
    else
      _ ->
        with {:ok, fields} <- decode_wire_fields(payload),
             extended when is_binary(extended) <- first_length_delimited_field(fields, 6),
             {:ok, extended_fields} <- decode_wire_fields(extended),
             text when is_binary(text) <- first_length_delimited_field(extended_fields, 1),
             true <- valid_text_payload?(text) do
          {:ok, text}
        else
          _ -> :error
        end
    end
  end

  defp collect_length_delimited_fields(payload) when is_binary(payload) do
    with {:ok, fields} <- decode_wire_fields(payload) do
      values =
        fields
        |> Enum.reduce([], fn
          {_field_num, 2, value}, acc when is_binary(value) -> [value | acc]
          _, acc -> acc
        end)
        |> Enum.reverse()

      {:ok, values}
    end
  end

  defp valid_text_payload?(value) when is_binary(value) do
    trimmed = String.trim(value)

    trimmed != "" and String.valid?(trimmed) and
      not Regex.match?(@jid_like_payload_pattern, trimmed)
  end

  defp parse_phone_number_lid_mapping(mapping_payload) when is_binary(mapping_payload) do
    with {:ok, fields} <- decode_wire_fields(mapping_payload),
         pn_raw when is_binary(pn_raw) <- first_length_delimited_field(fields, 1),
         lid_raw when is_binary(lid_raw) <- first_length_delimited_field(fields, 2),
         pn when is_binary(pn) <- normalize_non_empty_jid(pn_raw),
         lid when is_binary(lid) <- normalize_non_empty_jid(lid_raw) do
      {lid, pn}
    else
      _ ->
        nil
    end
  end

  defp parse_phone_number_lid_mapping(_), do: nil

  defp conversation_mapping(%{
         jid: jid,
         is_group: false,
         pn_jid: pn_jid,
         lid_jid: lid_jid
       }) do
    cond do
      lid_jid?(jid) and is_binary(pn_jid) and pn_jid != "" ->
        {jid, pn_jid}

      pn_jid?(jid) and is_binary(lid_jid) and lid_jid != "" ->
        {lid_jid, jid}

      true ->
        nil
    end
  end

  defp conversation_mapping(_), do: nil

  defp lid_jid?(jid) when is_binary(jid) do
    String.ends_with?(jid, "@lid") or String.ends_with?(jid, "@hosted.lid")
  end

  defp lid_jid?(_), do: false

  defp pn_jid?(jid) when is_binary(jid) do
    not lid_jid?(jid) and not JID.group?(jid) and String.contains?(jid, "@")
  end

  defp pn_jid?(_), do: false

  defp first_length_delimited_field(fields, field_num)
       when is_list(fields) and is_integer(field_num) do
    Enum.find_value(fields, fn
      {^field_num, 2, value} when is_binary(value) -> value
      _ -> nil
    end)
  end

  defp all_length_delimited_fields(fields, field_num)
       when is_list(fields) and is_integer(field_num) do
    fields
    |> Enum.reduce([], fn
      {^field_num, 2, value}, acc when is_binary(value) -> [value | acc]
      _, acc -> acc
    end)
    |> Enum.reverse()
  end

  defp first_varint_field(fields, field_num) when is_list(fields) and is_integer(field_num) do
    Enum.find_value(fields, fn
      {^field_num, 0, value} when is_integer(value) -> value
      _ -> nil
    end)
  end

  defp first_non_neg_integer_field(fields, candidate_field_nums)
       when is_list(fields) and is_list(candidate_field_nums) do
    Enum.reduce_while(candidate_field_nums, nil, fn field_num, _acc ->
      case first_varint_field(fields, field_num) do
        value when is_integer(value) and value >= 0 -> {:halt, value}
        _ -> {:cont, nil}
      end
    end)
  end

  defp parse_optional_boolean(nil), do: nil
  defp parse_optional_boolean(0), do: false
  defp parse_optional_boolean(value) when is_integer(value) and value > 0, do: true
  defp parse_optional_boolean(_), do: nil

  defp first_non_empty(values) when is_list(values) do
    Enum.find(values, fn
      value when is_binary(value) and value != "" -> true
      _ -> false
    end)
  end

  defp normalize_optional_text(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end

  defp normalize_optional_text(_), do: nil

  defp normalize_optional_jid(value) do
    case normalize_jid(value) do
      "" -> nil
      jid -> jid
    end
  end

  defp normalize_non_empty_jid(value) do
    case normalize_jid(value) do
      "" -> nil
      jid -> jid
    end
  end

  defp normalize_jid(%JID{} = jid), do: normalize_jid(JID.to_string(jid))
  defp normalize_jid(nil), do: ""

  defp normalize_jid(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
    |> then(fn value ->
      case String.split(value, "@", parts: 2) do
        [user, domain] when user != "" and domain != "" ->
          Regex.replace(~r/:(\d+)$/, user, "") <> "@" <> domain

        _ ->
          value
      end
    end)
  end

  defp normalize_jid(_), do: ""

  defp inflate_history_payload(payload) when is_binary(payload) do
    try do
      {:ok, :zlib.uncompress(payload)}
    rescue
      _ ->
        # In some edge cases this payload may already be plain protobuf bytes.
        {:ok, payload}
    end
  end

  defp decode_wire_fields(binary), do: decode_wire_fields(binary, [])
  defp decode_wire_fields(<<>>, acc), do: {:ok, Enum.reverse(acc)}

  defp decode_wire_fields(binary, acc) when is_binary(binary) do
    with {:ok, tag, rest} <- decode_varint(binary),
         wire_type <- band(tag, 0x07),
         field_num <- bsr(tag, 3) do
      decode_wire_field(wire_type, rest, field_num, acc)
    end
  end

  defp decode_wire_field(0, rest, field_num, acc) do
    with {:ok, value, tail} <- decode_varint(rest) do
      decode_wire_fields(tail, [{field_num, 0, value} | acc])
    end
  end

  defp decode_wire_field(1, rest, field_num, acc) do
    if byte_size(rest) >= 8 do
      <<_skip::binary-size(8), tail::binary>> = rest
      decode_wire_fields(tail, [{field_num, 1, :fixed64} | acc])
    else
      {:error, :invalid_fixed64}
    end
  end

  defp decode_wire_field(2, rest, field_num, acc) do
    with {:ok, len, tail} <- decode_varint(rest),
         true <- byte_size(tail) >= len do
      <<value::binary-size(^len), next::binary>> = tail
      decode_wire_fields(next, [{field_num, 2, value} | acc])
    else
      false -> {:error, :invalid_length_delimited_field}
    end
  end

  defp decode_wire_field(5, rest, field_num, acc) do
    if byte_size(rest) >= 4 do
      <<_skip::binary-size(4), tail::binary>> = rest
      decode_wire_fields(tail, [{field_num, 5, :fixed32} | acc])
    else
      {:error, :invalid_fixed32}
    end
  end

  defp decode_wire_field(wire_type, _rest, _field_num, _acc),
    do: {:error, {:unsupported_wire_type, wire_type}}

  defp decode_varint(binary), do: decode_varint(binary, 0, 0)
  defp decode_varint(_, _, shift) when shift > 63, do: {:error, :invalid_varint}
  defp decode_varint(<<>>, _, _), do: {:error, :invalid_varint}

  defp decode_varint(<<byte, rest::binary>>, acc, shift) do
    value = bor(acc, bsl(band(byte, 0x7F), shift))

    if band(byte, 0x80) == 0 do
      {:ok, value, rest}
    else
      decode_varint(rest, value, shift + 7)
    end
  end
end
