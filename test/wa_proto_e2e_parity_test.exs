defmodule ExWapp.WaProtoE2EParityTest do
  @moduledoc """
  Byte-parity between the hand-rolled encoders in `ExWapp.Proto.*` and the
  protox modules generated from WhatsApp's official proto files
  (`tmp/whatsmeow_upstream/proto/waE2E`, generated into `lib/ex_wapp/wa_proto`).

  The hand-rolled modules predate the generated ones and are what the message
  builders still use; these tests pin that both encoders emit identical bytes
  so call sites can migrate to the generated structs one by one without any
  wire-format risk. If a regeneration from a newer upstream ever changes these
  bytes, that is a protocol change worth noticing — not a formatting detail.
  """

  use ExUnit.Case, async: true

  alias ExWapp.Messages

  @group "120363000000000000@g.us"
  @jid "15550001111@s.whatsapp.net"
  @peer "15550002222@s.whatsapp.net"

  describe "MessageKey" do
    test "a peer's key (explicit fromMe=false) encodes identically" do
      hand =
        ExWapp.Proto.MessageKey.encode!(%ExWapp.Proto.MessageKey{
          remoteJID: @group,
          fromMe: false,
          id: "3EB0AA",
          participant: @peer
        })

      gen =
        %WACommon.MessageKey{
          remoteJID: @group,
          fromMe: false,
          ID: "3EB0AA",
          participant: @peer
        }
        |> WACommon.MessageKey.encode!()
        |> IO.iodata_to_binary()

      assert hand == gen
    end

    test "our own key (fromMe=true, no participant) encodes identically" do
      hand =
        ExWapp.Proto.MessageKey.encode!(%ExWapp.Proto.MessageKey{
          remoteJID: @jid,
          fromMe: true,
          id: "3EB0BB"
        })

      gen =
        %WACommon.MessageKey{remoteJID: @jid, fromMe: true, ID: "3EB0BB"}
        |> WACommon.MessageKey.encode!()
        |> IO.iodata_to_binary()

      assert hand == gen
    end

    test "unset fields are omitted by both encoders" do
      hand = ExWapp.Proto.MessageKey.encode!(%ExWapp.Proto.MessageKey{id: "3EB0CC"})

      gen =
        %WACommon.MessageKey{ID: "3EB0CC"}
        |> WACommon.MessageKey.encode!()
        |> IO.iodata_to_binary()

      assert hand == gen
    end
  end

  describe "ContextInfo" do
    test "quote plus mentions encode identically, mention order preserved" do
      hand =
        ExWapp.Proto.ContextInfo.encode!(%ExWapp.Proto.ContextInfo{
          stanzaID: "3EB0AA",
          participant: @jid,
          mentionedJID: [@peer, "70000001111@lid"]
        })

      gen =
        %WAWebProtobufsE2E.ContextInfo{
          stanzaID: "3EB0AA",
          participant: @jid,
          mentionedJID: [@peer, "70000001111@lid"]
        }
        |> WAWebProtobufsE2E.ContextInfo.encode!()
        |> IO.iodata_to_binary()

      assert hand == gen
    end

    test "the forwarded flag encodes identically" do
      hand = ExWapp.Proto.ContextInfo.encode!(%ExWapp.Proto.ContextInfo{isForwarded: true})

      gen =
        %WAWebProtobufsE2E.ContextInfo{isForwarded: true}
        |> WAWebProtobufsE2E.ContextInfo.encode!()
        |> IO.iodata_to_binary()

      assert hand == gen
    end
  end

  describe "placeholder-resend Message" do
    test "the hand-rolled __uf__ construction matches fully typed generated structs" do
      hand =
        Messages.build_placeholder_resend_proto(@group, "15550002222:9@s.whatsapp.net", "3EB0AA")
        |> ExWapp.Proto.Message.encode!()

      gen =
        %WAWebProtobufsE2E.Message{
          protocolMessage: %WAWebProtobufsE2E.ProtocolMessage{
            type: :PEER_DATA_OPERATION_REQUEST_MESSAGE,
            peerDataOperationRequestMessage: %WAWebProtobufsE2E.PeerDataOperationRequestMessage{
              peerDataOperationRequestType: :PLACEHOLDER_MESSAGE_RESEND,
              placeholderMessageResendRequest: [
                %WAWebProtobufsE2E.PeerDataOperationRequestMessage.PlaceholderMessageResendRequest{
                  messageKey: %WACommon.MessageKey{
                    remoteJID: @group,
                    fromMe: false,
                    ID: "3EB0AA",
                    participant: @peer
                  }
                }
              ]
            }
          }
        }
        |> WAWebProtobufsE2E.Message.encode!()
        |> IO.iodata_to_binary()

      assert hand == gen
    end

    test "the generated decoder round-trips the hand-rolled builder's bytes" do
      bytes =
        Messages.build_placeholder_resend_proto(@group, "15550002222:9@s.whatsapp.net", "3EB0AA")
        |> ExWapp.Proto.Message.encode!()

      assert {:ok, decoded} = WAWebProtobufsE2E.Message.decode(bytes)

      protocol = decoded.protocolMessage
      assert protocol.type == :PEER_DATA_OPERATION_REQUEST_MESSAGE

      request = protocol.peerDataOperationRequestMessage
      assert request.peerDataOperationRequestType == :PLACEHOLDER_MESSAGE_RESEND

      [resend] = request.placeholderMessageResendRequest
      assert resend.messageKey.remoteJID == @group
      assert resend.messageKey.fromMe == false
      assert Map.get(resend.messageKey, :ID) == "3EB0AA"
      assert resend.messageKey.participant == @peer
    end
  end

  describe "media Message via __uf__ passthrough" do
    test "raw media fields survive the generated encoder unchanged" do
      hand_proto = Messages.build_image_proto(upload_fixture(), caption: "look")
      hand = ExWapp.Proto.Message.encode!(hand_proto)

      gen =
        %WAWebProtobufsE2E.Message{__uf__: hand_proto.__uf__}
        |> WAWebProtobufsE2E.Message.encode!()
        |> IO.iodata_to_binary()

      assert hand == gen
    end

    test "the generated decoder types the hand-rolled image payload" do
      bytes =
        Messages.build_image_proto(upload_fixture(), caption: "look")
        |> ExWapp.Proto.Message.encode!()

      assert {:ok, decoded} = WAWebProtobufsE2E.Message.decode(bytes)

      image = decoded.imageMessage
      assert Map.get(image, :URL) == upload_fixture().url
      assert image.caption == "look"
      assert image.fileLength == upload_fixture().file_length
      assert image.mediaKey == upload_fixture().media_key
    end
  end

  defp upload_fixture do
    %ExWapp.Media.Upload{
      url: "https://mmg.whatsapp.net/d/f/synthetic",
      direct_path: "/v/t62.7118-24/synthetic",
      media_key: :binary.copy(<<1>>, 32),
      file_sha256: :binary.copy(<<2>>, 32),
      file_enc_sha256: :binary.copy(<<3>>, 32),
      file_length: 4096,
      media_key_timestamp: 1_700_000_000
    }
  end
end
