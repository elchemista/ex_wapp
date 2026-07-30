defmodule ExWapp.Proto.HistorySyncTest do
  use ExUnit.Case, async: true

  alias ExWapp.Proto.HistorySync
  alias WACommon.MessageKey
  alias WAWebProtobufsE2E.{HistorySyncNotification, Message, ProtocolMessage}
  alias WAWebProtobufsHistorySync.PhoneNumberToLIDMapping
  alias WAWebProtobufsHistorySync.Conversation
  alias WAWebProtobufsHistorySync.HistorySync, as: HistorySyncProto
  alias WAWebProtobufsHistorySync.HistorySyncMsg
  alias WAWebProtobufsWeb.WebMessageInfo

  test "extracts conversations, messages, and lid mappings from an inline payload" do
    history = %HistorySyncProto{
      syncType: :INITIAL_BOOTSTRAP,
      conversations: [
        %Conversation{
          ID: "15550001111@s.whatsapp.net",
          displayName: "Test Chat",
          unreadCount: 2,
          lastMsgTimestamp: 1_700_000_000,
          pinned: 1,
          archived: false,
          lidJID: "70000001111@lid",
          tcToken: <<1, 2, 3>>,
          tcTokenTimestamp: 1_700_000_001,
          messages: [
            %HistorySyncMsg{
              msgOrderID: 7,
              message: %WebMessageInfo{
                key: %MessageKey{
                  remoteJID: "15550001111@s.whatsapp.net",
                  fromMe: true,
                  ID: "3EB0AABBCCDDEEFF0011"
                },
                messageTimestamp: 1_699_999_999,
                message: %Message{conversation: "hello from history"}
              }
            }
          ]
        }
      ],
      phoneNumberToLidMappings: [
        %PhoneNumberToLIDMapping{
          pnJID: "15550002222@s.whatsapp.net",
          lidJID: "70000002222@lid"
        }
      ]
    }

    payload =
      %Message{
        protocolMessage: %ProtocolMessage{
          type: :HISTORY_SYNC_NOTIFICATION,
          historySyncNotification: %HistorySyncNotification{
            syncType: :INITIAL_BOOTSTRAP,
            initialHistBootstrapInlinePayload:
              history |> HistorySyncProto.encode!() |> IO.iodata_to_binary() |> :zlib.compress()
          }
        }
      }
      |> Message.encode!()
      |> IO.iodata_to_binary()

    assert {:ok, extracted} = HistorySync.extract_from_message(payload)
    assert extracted.sync_type == :INITIAL_BOOTSTRAP

    assert [conversation] = extracted.conversations
    assert conversation.jid == "15550001111@s.whatsapp.net"
    assert conversation.name == "Test Chat"
    assert conversation.unread_count == 2
    assert conversation.last_message_timestamp == 1_700_000_000
    assert conversation.pinned == true
    assert conversation.archived == false
    assert conversation.is_group == false
    assert conversation.lid_jid == "70000001111@lid"
    assert conversation.tc_token == <<1, 2, 3>>
    assert conversation.tc_token_timestamp == 1_700_000_001

    assert [message] = conversation.messages
    assert message.id == "3EB0AABBCCDDEEFF0011"
    assert message.from_me == true
    assert message.timestamp == 1_699_999_999
    assert message.text == "hello from history"
    assert message.remote_jid == "15550001111@s.whatsapp.net"
    assert message.order_id == 7

    assert {"70000002222@lid", "15550002222@s.whatsapp.net"} in extracted.lid_mappings
    assert {"70000001111@lid", "15550001111@s.whatsapp.net"} in extracted.lid_mappings
  end

  test "reports download-required when the inline payload is missing" do
    payload =
      %Message{
        protocolMessage: %ProtocolMessage{
          historySyncNotification: %HistorySyncNotification{syncType: :RECENT}
        }
      }
      |> Message.encode!()
      |> IO.iodata_to_binary()

    assert {:error, :history_sync_download_required} =
             HistorySync.extract_from_message(payload)
  end

  test "ignores messages that are not history sync notifications" do
    payload =
      %Message{conversation: "plain text"} |> Message.encode!() |> IO.iodata_to_binary()

    assert :not_history_sync = HistorySync.extract_from_message(payload)
  end
end
