defmodule ExWapp.Message.Handler.Inbound.SyncTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Chat, Messages}
  alias ExWapp.Message.Handler.Inbound.Sync
  alias WAWebProtobufsE2E.Message
  alias ExWapp.Store
  alias ExWapp.Store.Memory

  test "leaves ordinary user messages outside the sync pipeline" do
    state = %{marker: :unchanged}

    assert Sync.ingest(
             %{message_content_type: :user_message, text: "hello"},
             nil,
             state,
             "15550001111@s.whatsapp.net",
             "message-1"
           ) == state
  end

  test "keeps state unchanged for an unsupported protocol payload" do
    state = %{marker: :unchanged}

    assert Sync.ingest(
             %{message_content_type: :protocol, protocol_payload: <<0>>},
             nil,
             state,
             "15550001111@s.whatsapp.net",
             "message-2"
           ) == state
  end

  test "rejects an app-state key share from a non-local sender" do
    store = Memory.new()
    state = %{store: store}
    key_id = <<1, 2, 3, 4>>
    key_data = :binary.copy(<<7>>, 32)
    message_data = app_state_key_share_message(key_id, key_data)

    assert Sync.ingest(
             message_data,
             nil,
             state,
             "15550001111@s.whatsapp.net",
             "spoofed-key-share",
             false
           ) == state

    assert Store.get(store, :app_state_keys, %{}) == %{}
  end

  test "accepts an app-state key share from a verified local sender" do
    store = Memory.new()
    state = %{store: store}
    key_id = <<1, 2, 3, 4>>
    key_data = :binary.copy(<<7>>, 32)
    message_data = app_state_key_share_message(key_id, key_data)

    assert Sync.ingest(
             message_data,
             nil,
             state,
             "15550009999@s.whatsapp.net",
             "trusted-key-share",
             true
           ) == state

    key_id_hex = Base.encode16(key_id, case: :lower)

    assert %{^key_id_hex => %{data: ^key_data}} =
             Store.get(store, :app_state_keys, %{})
  end

  test "ingests a primary-device placeholder response as the original message" do
    store = Memory.new(initial_data: %{chats: %{}})
    state = %{store: store}
    chat_jid = "15550002222@s.whatsapp.net"
    message_id = "RECOVERED_MESSAGE_1"

    original_message =
      Messages.build_text_proto("recovered from primary", [])
      |> Message.encode!()
      |> elem(0)
      |> IO.iodata_to_binary()

    message_key =
      length_delimited(1, chat_jid) <>
        varint_field(2, 1) <>
        length_delimited(3, message_id)

    web_message_info =
      length_delimited(1, message_key) <>
        length_delimited(2, original_message) <>
        varint_field(3, 1_730_000_500) <>
        length_delimited(19, "Primary device")

    placeholder_response = length_delimited(1, web_message_info)
    operation_result = length_delimited(4, placeholder_response)

    peer_response =
      varint_field(1, 4) <>
        length_delimited(2, "PLACEHOLDER_REQUEST_1") <>
        length_delimited(3, operation_result)

    protocol_message =
      varint_field(2, 17) <>
        length_delimited(17, peer_response)

    message_data = %{
      message_content_type: :protocol,
      protocol_payload: length_delimited(12, protocol_message)
    }

    assert Sync.ingest(
             message_data,
             self(),
             state,
             "15550009999@s.whatsapp.net",
             "PLACEHOLDER_RESPONSE_1",
             true
           ) == state

    assert_receive {:new_message, ^chat_jid,
                    %{id: ^message_id, text: "recovered from primary", from_me: true}}

    assert [%{id: ^message_id, text: "recovered from primary", from_me: true}] =
             Chat.messages(store, chat_jid, limit: 1)
  end

  test "queues a trusted history blob for background download without touching state" do
    store = Memory.new(initial_data: %{chats: %{}})
    state = %{store: store}

    payload =
      %Message{
        protocolMessage: %WAWebProtobufsE2E.ProtocolMessage{
          historySyncNotification: %WAWebProtobufsE2E.HistorySyncNotification{
            syncType: :RECENT,
            chunkOrder: 2,
            mediaKey: :binary.copy(<<9>>, 32),
            directPath: "/v/history-chunk",
            fileLength: 524_288
          }
        }
      }
      |> Message.encode!()
      |> elem(0)
      |> IO.iodata_to_binary()

    message_data = %{message_content_type: :protocol, protocol_payload: payload}

    # A foreign device cannot cause a history download or store mutation.
    assert Sync.ingest(message_data, self(), state, "foreign@lid", "untrusted", false) == state
    refute_received {:history_sync_blob, _, _, _, _}

    assert Sync.ingest(
             message_data,
             self(),
             state,
             "15550009999@s.whatsapp.net",
             "HISTORY_BLOB_1",
             true
           ) == state

    assert_receive {:history_sync_blob, nil,
                    %{sync_type: :RECENT, chunk_order: 2, direct_path: "/v/history-chunk"},
                    "15550009999@s.whatsapp.net", "HISTORY_BLOB_1"}

    assert Chat.list(store) == []
  end

  test "ignores a peer-data response that is not a placeholder resend" do
    store = Memory.new(initial_data: %{chats: %{}})
    state = %{store: store}

    web_message_info =
      length_delimited(1, length_delimited(1, "15550002222@s.whatsapp.net")) <>
        length_delimited(
          2,
          Messages.build_text_proto("should not be ingested", [])
          |> Message.encode!()
          |> elem(0)
          |> IO.iodata_to_binary()
        )

    # HISTORY_SYNC_ON_DEMAND instead of PLACEHOLDER_MESSAGE_RESEND
    peer_response =
      varint_field(1, 3) <>
        length_delimited(2, "REQUEST_1") <>
        length_delimited(3, length_delimited(4, length_delimited(1, web_message_info)))

    message_data = %{
      message_content_type: :protocol,
      protocol_payload:
        length_delimited(12, varint_field(2, 17) <> length_delimited(17, peer_response))
    }

    assert Sync.ingest(
             message_data,
             self(),
             state,
             "15550009999@s.whatsapp.net",
             "PEER_RESPONSE_1",
             true
           ) == state

    refute_receive {:new_message, _chat_jid, _message}
    assert Chat.messages(store, "15550002222@s.whatsapp.net", limit: 1) == []
  end

  defp app_state_key_share_message(key_id, key_data) do
    key_id_message = length_delimited(1, key_id)
    key_data_message = length_delimited(1, key_data)

    app_state_key =
      length_delimited(1, key_id_message) <>
        length_delimited(2, key_data_message)

    key_share = length_delimited(1, app_state_key)
    protocol_message = length_delimited(7, key_share)

    %{
      message_content_type: :protocol,
      protocol_payload: length_delimited(12, protocol_message)
    }
  end

  test "a failed key-share write cannot start sync and a redelivery recovers" do
    store = ExWapp.Test.FaultStore.new()
    state = %{store: store}
    data = app_state_key_share_message(<<1, 2>>, <<7::256>>)

    for failure <- [{:return, {:error, :disk_full}}, :raise] do
      ExWapp.Test.FaultStore.arm(store, :get_and_update, failure)
      assert Sync.ingest(data, self(), state, "70000001111@lid", "keys", true) == state
      assert Store.get(store, :app_state_keys, %{}) == %{}
      refute_received {:app_state_initial_sync, _}
    end

    assert Sync.ingest(data, self(), state, "70000001111@lid", "keys", true) == state
    assert Store.get(store, :app_state_keys)["0102"].data == <<7::256>>
    assert_receive {:app_state_initial_sync, collections}
    assert length(collections) == 5
  end

  test "malformed placeholder entries do not prevent a valid recovered message" do
    store = Memory.new()
    on_exit(fn -> Memory.stop(store) end)
    state = %{store: store}
    jid = "15550001111@s.whatsapp.net"

    valid = %WAWebProtobufsWeb.WebMessageInfo{
      key: %WACommon.MessageKey{remoteJID: jid, ID: "recovered", fromMe: false},
      message: %Message{conversation: "valid recovered text"},
      messageTimestamp: 1_754_000_100
    }

    missing_id = %{valid | key: %{valid.key | ID: nil}}
    missing_chat = %{valid | key: %{valid.key | remoteJID: nil}}

    encoded_entries =
      Enum.map(
        [
          %WAWebProtobufsWeb.WebMessageInfo{key: %WACommon.MessageKey{}},
          missing_id,
          missing_chat,
          valid
        ],
        fn info ->
          bytes =
            info |> WAWebProtobufsWeb.WebMessageInfo.encode!() |> elem(0) |> IO.iodata_to_binary()

          length_delimited(3, length_delimited(4, length_delimited(1, bytes)))
        end
      )

    # An empty operation result and a corrupt WebMessageInfo precede the valid entry.
    response =
      varint_field(1, 4) <>
        length_delimited(3, <<>>) <>
        length_delimited(3, length_delimited(4, length_delimited(1, <<255>>))) <>
        IO.iodata_to_binary(encoded_entries)

    data = %{
      message_content_type: :protocol,
      protocol_payload:
        length_delimited(12, varint_field(2, 17) <> length_delimited(17, response))
    }

    assert Sync.ingest(data, self(), state, "70000009999@lid", "placeholder", true) == state
    assert_receive {:new_message, ^jid, %{id: "recovered", text: "valid recovered text"}}
    refute_received {:new_message, _, _}
    assert [%{id: "recovered"}] = Chat.messages(store, jid)
  end

  defp length_delimited(field_number, value)
       when is_integer(field_number) and field_number > 0 and is_binary(value) do
    encode_varint(field_number * 8 + 2) <> encode_varint(byte_size(value)) <> value
  end

  defp varint_field(field_number, value)
       when is_integer(field_number) and field_number > 0 and is_integer(value) and value >= 0 do
    encode_varint(field_number * 8) <> encode_varint(value)
  end

  defp encode_varint(value) when value < 128, do: <<value>>

  defp encode_varint(value) do
    byte = Bitwise.bor(Bitwise.band(value, 0x7F), 0x80)
    <<byte>> <> encode_varint(Bitwise.bsr(value, 7))
  end
end
