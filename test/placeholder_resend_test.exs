defmodule ExWapp.PlaceholderResendTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary.Node
  alias ExWapp.MessageHandler
  alias ExWapp.Messages
  alias ExWapp.Proto.Message

  test "builds PLACEHOLDER_MESSAGE_RESEND peer-data request protobuf" do
    proto =
      Messages.build_placeholder_resend_proto(
        "111222333@g.us",
        "444555666:7@s.whatsapp.net",
        "MSG_PLACEHOLDER_1"
      )

    payload = Message.encode!(proto)

    assert {:ok, [{12, 2, protocol_message}]} = decode_fields(payload)
    assert {:ok, protocol_fields} = decode_fields(protocol_message)
    assert {2, 0, 16} in protocol_fields

    request_message = field_value(protocol_fields, 16)
    assert is_binary(request_message)
    assert {:ok, request_fields} = decode_fields(request_message)
    assert {1, 0, 4} in request_fields

    resend_request = field_value(request_fields, 5)
    assert is_binary(resend_request)
    assert {:ok, [{1, 2, message_key}]} = decode_fields(resend_request)
    assert {:ok, key_fields} = decode_fields(message_key)

    assert field_value(key_fields, 1) == "111222333@g.us"
    assert field_value(key_fields, 2) == 0
    assert field_value(key_fields, 3) == "MSG_PLACEHOLDER_1"
    assert field_value(key_fields, 4) == "444555666@s.whatsapp.net"
  end

  test "unavailable placeholder messages request primary-device resend" do
    node = %Node{
      tag: "message",
      attrs: %{
        "from" => "111222333@g.us",
        "participant" => "444555666:7@s.whatsapp.net",
        "id" => "MSG_PLACEHOLDER_2",
        "type" => "text",
        "t" => "1730000201"
      },
      content: [
        %Node{tag: "unavailable", attrs: %{"type" => "no_sender_key"}, content: nil}
      ]
    }

    state = %{stats: %{messages_received: 0}, retry_counters: %{}}

    assert {:ok, _state, actions} = MessageHandler.handle_node(node, self(), state)

    assert {:request_placeholder_resend, "111222333@g.us", "444555666:7@s.whatsapp.net",
            "MSG_PLACEHOLDER_2"} in actions

    assert Enum.any?(actions, fn
             {:send_receipt, "111222333@g.us", "MSG_PLACEHOLDER_2", "444555666:7@s.whatsapp.net",
              _, _} ->
               true

             _ ->
               false
           end)

    refute Enum.any?(actions, fn
             {:send_retry_receipt, _, _, _, _, _, _, _} -> true
             _ -> false
           end)
  end

  defp field_value(fields, field_num) do
    Enum.find_value(fields, fn
      {^field_num, _wire_type, value} -> value
      _ -> nil
    end)
  end

  defp decode_fields(binary), do: decode_fields(binary, [])

  defp decode_fields(<<>>, acc), do: {:ok, Enum.reverse(acc)}

  defp decode_fields(binary, acc) do
    with {:ok, tag, rest} <- decode_varint(binary),
         wire_type <- Bitwise.band(tag, 0x07),
         field_num <- Bitwise.bsr(tag, 3) do
      decode_field(wire_type, rest, field_num, acc)
    end
  end

  defp decode_field(0, rest, field_num, acc) do
    with {:ok, value, tail} <- decode_varint(rest) do
      decode_fields(tail, [{field_num, 0, value} | acc])
    end
  end

  defp decode_field(2, rest, field_num, acc) do
    with {:ok, len, tail} <- decode_varint(rest),
         true <- byte_size(tail) >= len do
      <<value::binary-size(len), next::binary>> = tail
      decode_fields(next, [{field_num, 2, value} | acc])
    else
      false -> {:error, :invalid_length}
    end
  end

  defp decode_field(wire_type, _rest, _field_num, _acc),
    do: {:error, {:unsupported_wire_type, wire_type}}

  defp decode_varint(binary), do: decode_varint(binary, 0, 0)
  defp decode_varint(_, _, shift) when shift > 63, do: {:error, :invalid_varint}
  defp decode_varint(<<>>, _, _), do: {:error, :invalid_varint}

  defp decode_varint(<<byte, rest::binary>>, acc, shift) do
    value = Bitwise.bor(acc, Bitwise.bsl(Bitwise.band(byte, 0x7F), shift))

    if Bitwise.band(byte, 0x80) == 0 do
      {:ok, value, rest}
    else
      decode_varint(rest, value, shift + 7)
    end
  end
end
