defmodule ExWapp.PlaceholderResendTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary.Node
  alias ExWapp.JID
  alias ExWapp.Message.Handler.Inbound.Receipts
  alias ExWapp.MessageHandler
  alias ExWapp.Messages
  alias WAWebProtobufsE2E.Message
  alias ExWapp.Signal.{Keys, SessionStore}
  alias ExWapp.Store.Memory

  test "builds PLACEHOLDER_MESSAGE_RESEND peer-data request protobuf" do
    proto =
      Messages.build_placeholder_resend_proto(
        "111222333@g.us",
        "444555666:7@s.whatsapp.net",
        "MSG_PLACEHOLDER_1"
      )

    payload = IO.iodata_to_binary(Message.encode!(proto))

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

  test "builds a from-me placeholder request without a participant for a direct chat" do
    proto =
      Messages.build_placeholder_resend_proto(
        "111222333@s.whatsapp.net",
        "999888777:7@s.whatsapp.net",
        "MSG_PLACEHOLDER_SELF",
        from_me: true
      )

    payload = IO.iodata_to_binary(Message.encode!(proto))

    assert {:ok, [{12, 2, protocol_message}]} = decode_fields(payload)
    assert {:ok, protocol_fields} = decode_fields(protocol_message)
    request_message = field_value(protocol_fields, 16)
    assert {:ok, request_fields} = decode_fields(request_message)
    resend_request = field_value(request_fields, 5)
    assert {:ok, [{1, 2, message_key}]} = decode_fields(resend_request)
    assert {:ok, key_fields} = decode_fields(message_key)

    assert field_value(key_fields, 1) == "111222333@s.whatsapp.net"
    assert field_value(key_fields, 2) == 1
    assert field_value(key_fields, 3) == "MSG_PLACEHOLDER_SELF"
    assert field_value(key_fields, 4) == nil
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
            "MSG_PLACEHOLDER_2", %{from_me: false}} in actions

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

  test "undecryptable self-fanout messages request a resend even though the decoder hands JID structs" do
    from = JID.with_device(JID.new("15550001111", "s.whatsapp.net"), 7)

    node = %Node{
      tag: "message",
      attrs: %{
        "from" => from,
        "recipient" => JID.new("15550001111", "s.whatsapp.net"),
        "id" => "MSG_SELF_FANOUT",
        "type" => "text",
        "t" => "1730000203"
      },
      content: [
        %Node{tag: "enc", attrs: %{"type" => "msg", "v" => "2"}, content: <<0x33, 0x00>>}
      ]
    }

    state = %{
      store: Memory.new(),
      signal_sessions: SessionStore.new(),
      stats: %{messages_received: 0},
      retry_counters: %{}
    }

    assert {:ok, _state, actions} = MessageHandler.handle_node(node, self(), state)

    assert {:request_placeholder_resend, chat_jid, sender_jid, "MSG_SELF_FANOUT", %{from_me: _}} =
             Enum.find(actions, &match?({:request_placeholder_resend, _, _, _, _}, &1))

    # The session worker drops the request unless both references are non-empty strings.
    assert sender_jid == "15550001111:7@s.whatsapp.net"
    assert is_binary(chat_jid) and chat_jid != ""
  end

  test "group placeholder requests quote the participant rather than the group" do
    participant = JID.with_device(JID.new("444555666", "s.whatsapp.net"), 7)

    node = %Node{
      tag: "message",
      attrs: %{
        "from" => JID.new("111222333", "g.us"),
        "participant" => participant,
        "id" => "MSG_PLACEHOLDER_3",
        "type" => "text",
        "t" => "1730000204"
      },
      content: [
        %Node{tag: "unavailable", attrs: %{"type" => "no_sender_key"}, content: nil}
      ]
    }

    state = %{stats: %{messages_received: 0}, retry_counters: %{}}

    assert {:ok, _state, actions} = MessageHandler.handle_node(node, self(), state)

    assert {:request_placeholder_resend, "111222333@g.us", "444555666:7@s.whatsapp.net",
            "MSG_PLACEHOLDER_3", %{from_me: false}} in actions
  end

  test "placeholder senders keep the device and prefer the participant" do
    from = JID.with_device(JID.new("15550001111", "s.whatsapp.net"), 3)
    participant = JID.with_device(JID.new("444555666", "s.whatsapp.net"), 7)

    assert Receipts.placeholder_sender(from, participant) == "444555666:7@s.whatsapp.net"
    assert Receipts.placeholder_sender(from, nil) == "15550001111:3@s.whatsapp.net"
    assert Receipts.placeholder_sender(from, "") == "15550001111:3@s.whatsapp.net"
    assert Receipts.placeholder_sender(nil, nil) == ""
  end

  test "encrypted retry responses stop after two retries" do
    node = %Node{
      tag: "message",
      attrs: %{
        "from" => "15550001111@s.whatsapp.net",
        "id" => "MSG_RETRY_LIMIT",
        "type" => "text",
        "t" => "1730000202"
      },
      content: [
        %Node{
          tag: "enc",
          attrs: %{"type" => "pkmsg", "v" => "2", "count" => "2"},
          content: <<0x33, 0x00>>
        }
      ]
    }

    state = %{stats: %{messages_received: 0}, retry_counters: %{}}

    assert {:ok, updated_state, actions} = MessageHandler.handle_node(node, self(), state)

    refute Enum.any?(actions, fn
             {:send_retry_receipt, _, _, _, _, _, _, _} -> true
             _ -> false
           end)

    assert updated_state.retry_counters["15550001111@s.whatsapp.net|MSG_RETRY_LIMIT|"] == 3
  end

  test "missing prekey redeliveries with new stanza IDs share one retry budget" do
    sender_identity = Keys.generate_key_pair()
    receiver_identity = Keys.generate_key_pair()
    signed_prekey = Keys.generate_signed_prekey(receiver_identity, 1)
    missing_prekey = Keys.generate_prekey(814)

    receiver_bundle = %{
      registration_id: 55_001,
      identity_key: receiver_identity.public,
      signed_prekey: %{
        id: signed_prekey.id,
        public: signed_prekey.public,
        signature: signed_prekey.signature
      },
      prekey: %{id: missing_prekey.id, public: missing_prekey.public}
    }

    {ciphertexts, _sender_sessions} =
      Enum.map_reduce(
        ["first unavailable", "second unavailable", "third unavailable"],
        SessionStore.new(),
        fn plaintext, sender_sessions ->
          assert {:ok, ciphertext, :prekey, next_sender_sessions} =
                   SessionStore.encrypt_message(
                     sender_sessions,
                     "15550002222@s.whatsapp.net",
                     plaintext,
                     sender_identity,
                     44_001,
                     receiver_bundle
                   )

          {ciphertext, next_sender_sessions}
        end
      )

    store =
      Memory.new(
        initial_data: %{
          signal: %{
            identity_key: receiver_identity,
            registration_id: 55_001,
            signed_prekeys: %{signed_prekey.id => signed_prekey},
            prekeys: %{},
            next_prekey_id: 815
          }
        }
      )

    on_exit(fn -> Memory.stop(store) end)

    initial_state = %{
      store: store,
      signal_sessions: SessionStore.new(),
      stats: %{messages_received: 0},
      retry_counters: %{}
    }

    {final_state, retry_counts, placeholder_ids} =
      Enum.reduce(
        Enum.zip(
          ["BROKEN_PREKEY_A", "BROKEN_PREKEY_B", "BROKEN_PREKEY_C"],
          ciphertexts
        ),
        {initial_state, [], []},
        fn {id, ciphertext}, {state, counts, placeholder_ids} ->
          node = %Node{
            tag: "message",
            attrs: %{
              "from" => "15550001111@s.whatsapp.net",
              "id" => id,
              "type" => "text",
              "t" => "1730000205"
            },
            content: [
              %Node{
                tag: "enc",
                attrs: %{"type" => "pkmsg", "v" => "2"},
                content: ciphertext
              }
            ]
          }

          assert {:ok, next_state, actions} = MessageHandler.handle_node(node, self(), state)

          retry_count =
            Enum.find_value(actions, fn
              {:send_retry_receipt, _, _, _, _, count, _, _} -> count
              _ -> nil
            end)

          requested_ids =
            Enum.flat_map(actions, fn
              {:request_placeholder_resend, _, _, requested_id, _} -> [requested_id]
              _ -> []
            end)

          {next_state, counts ++ [retry_count], placeholder_ids ++ requested_ids}
        end
      )

    assert retry_counts == [1, 2, nil]
    assert placeholder_ids == ["BROKEN_PREKEY_A"]
    assert map_size(final_state.retry_counters) == 1
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
      <<value::binary-size(^len), next::binary>> = tail
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
