defmodule ExWapp.Test.HistoryBlob do
  @moduledoc false

  alias WAWebProtobufsE2E.{HistorySyncNotification, Message, ProtocolMessage}
  alias WAWebProtobufsHistorySync.{Conversation, HistorySync, HistorySyncMsg}
  alias WAWebProtobufsWeb.WebMessageInfo

  def payload do
    %HistorySync{
      syncType: :RECENT,
      conversations: [
        %Conversation{
          ID: "15550001111@s.whatsapp.net",
          lidJID: "90000000011@lid",
          name: "History contact",
          conversationTimestamp: 200,
          messages:
            for index <- 1..2 do
              %HistorySyncMsg{
                message: %WebMessageInfo{
                  key: %WACommon.MessageKey{
                    ID: "history-#{index}",
                    remoteJID: "15550001111@s.whatsapp.net",
                    fromMe: false
                  },
                  messageTimestamp: index * 100,
                  message: %Message{conversation: "Historical message #{index}"}
                }
              }
            end
        }
      ]
    }
    |> HistorySync.encode!()
    |> elem(0)
    |> IO.iodata_to_binary()
    |> :zlib.compress()
  end

  # Independent producer: do not use Media.Crypto to generate its own test input.
  def encrypted(payload \\ payload()) do
    key = :binary.list_to_bin(Enum.to_list(0..31))
    prk = :crypto.mac(:hmac, :sha256, <<0::256>>, key)
    first = :crypto.mac(:hmac, :sha256, prk, "WhatsApp History Keys" <> <<1>>)
    second = :crypto.mac(:hmac, :sha256, prk, first <> "WhatsApp History Keys" <> <<2>>)
    third = :crypto.mac(:hmac, :sha256, prk, second <> "WhatsApp History Keys" <> <<3>>)

    <<iv::binary-size(16), cipher_key::binary-size(32), mac_key::binary-size(32), _::binary>> =
      first <> second <> third

    padding = 16 - rem(byte_size(payload), 16)
    padded = payload <> :binary.copy(<<padding>>, padding)
    ciphertext = :crypto.crypto_one_time(:aes_256_cbc, cipher_key, iv, padded, true)
    mac = :crypto.mac(:hmac, :sha256, mac_key, iv <> ciphertext) |> binary_part(0, 10)
    body = ciphertext <> mac

    blob = %{
      sync_type: :RECENT,
      chunk_order: 2,
      progress: 100,
      oldest_msg_timestamp: 100,
      enc_handle: "fixture",
      direct_path: "/history",
      media_key: key,
      file_sha256: :crypto.hash(:sha256, payload),
      file_enc_sha256: :crypto.hash(:sha256, body),
      file_length: byte_size(payload)
    }

    {blob, body}
  end

  def notification(blob) do
    %Message{
      protocolMessage: %ProtocolMessage{
        type: :HISTORY_SYNC_NOTIFICATION,
        historySyncNotification: %HistorySyncNotification{
          syncType: blob.sync_type,
          chunkOrder: blob.chunk_order,
          progress: blob.progress,
          mediaKey: blob.media_key,
          directPath: blob.direct_path,
          fileSHA256: blob.file_sha256,
          fileEncSHA256: blob.file_enc_sha256,
          fileLength: blob.file_length
        }
      }
    }
    |> Message.encode!()
    |> elem(0)
    |> IO.iodata_to_binary()
  end

  def ref(blob) do
    attrs =
      Map.take(blob, [:direct_path, :media_key, :file_sha256, :file_enc_sha256, :file_length])

    struct!(ExWapp.Media.Ref, Map.put(attrs, :type, :history))
  end
end
