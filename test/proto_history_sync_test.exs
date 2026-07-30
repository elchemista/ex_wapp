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

  test "keeps the blob reference when a chunk is delivered as media" do
    media_key = :binary.copy(<<9>>, 32)

    payload =
      %Message{
        protocolMessage: %ProtocolMessage{
          historySyncNotification: %HistorySyncNotification{
            syncType: :RECENT,
            chunkOrder: 2,
            progress: 40,
            oldestMsgInChunkTimestampSec: 1_699_000_000,
            mediaKey: media_key,
            directPath: "/v/t62.7118-24/history-chunk",
            encHandle: "enc-handle-1",
            fileSHA256: <<1, 2, 3>>,
            fileEncSHA256: <<4, 5, 6>>,
            fileLength: 524_288
          }
        }
      }
      |> Message.encode!()
      |> IO.iodata_to_binary()

    # Downloading is not implemented, but nothing a downloader needs may be lost.
    assert {:pending_blob, blob} = HistorySync.extract_from_message(payload)

    assert blob == %{
             sync_type: :RECENT,
             chunk_order: 2,
             progress: 40,
             oldest_msg_timestamp: 1_699_000_000,
             media_key: media_key,
             direct_path: "/v/t62.7118-24/history-chunk",
             enc_handle: "enc-handle-1",
             file_sha256: <<1, 2, 3>>,
             file_enc_sha256: <<4, 5, 6>>,
             file_length: 524_288
           }
  end

  test "parse_history_payload/2 flattens a chunk a downloader would hand it" do
    history = %HistorySyncProto{
      syncType: :RECENT,
      conversations: [%Conversation{ID: "15550003333@s.whatsapp.net", name: "From blob"}]
    }

    inflated = history |> HistorySyncProto.encode!() |> IO.iodata_to_binary()

    assert {:ok, extracted} = HistorySync.parse_history_payload(inflated, :RECENT)
    assert extracted.sync_type == :RECENT
    assert [%{jid: "15550003333@s.whatsapp.net", name: "From blob"}] = extracted.conversations
  end

  test "ignores messages that are not history sync notifications" do
    payload =
      %Message{conversation: "plain text"} |> Message.encode!() |> IO.iodata_to_binary()

    assert :not_history_sync = HistorySync.extract_from_message(payload)
  end
end
