defmodule ExWapp.WaProtoE2EParityTest do
  @moduledoc """
  Round-trips the `ExWapp.Messages` builders through the protox modules
  generated from WhatsApp's official proto files.

  The builders construct generated structs directly; encoding and decoding
  them back proves the payloads conform to the official schema — every field
  lands where a real WhatsApp client will look for it. Golden byte vectors pin
  the exact wire image of the most protocol-sensitive payloads so an upstream
  regeneration that shifts bytes fails loudly.
  """

  use ExUnit.Case, async: true

  alias ExWapp.Messages
  alias WAWebProtobufsE2E.Message

  @group "120363000000000000@g.us"
  @jid "15550001111@s.whatsapp.net"
  @peer "15550002222@s.whatsapp.net"

  defp encode(proto), do: proto |> Message.encode!() |> elem(0) |> IO.iodata_to_binary()
  defp roundtrip(proto), do: proto |> encode() |> Message.decode!()

  describe "placeholder-resend round-trip" do
    test "a group request decodes back with the device-stripped participant" do
      decoded =
        Messages.build_placeholder_resend_proto(@group, "15550002222:9@s.whatsapp.net", "3EB0AA")
        |> roundtrip()

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

    test "the wire image is byte-stable" do
      bytes =
        Messages.build_placeholder_resend_proto(@group, "15550002222:9@s.whatsapp.net", "3EB0AA")
        |> encode()

      assert bytes ==
               <<0x62, 0x4A, 0x10, 0x10, 0x82, 0x01, 0x45, 0x08, 0x04, 0x2A, 0x41, 0x0A, 0x3F,
                 0x0A, 0x17>> <>
                 @group <>
                 <<0x10, 0x00, 0x1A, 0x06, "3EB0AA", 0x22, 0x1A>> <> @peer
    end
  end

  describe "media round-trip" do
    test "an image builder decodes back with every field typed" do
      decoded =
        Messages.build_image_proto(upload_fixture(),
          caption: "look",
          height: 480,
          width: 640,
          view_once: true
        )
        |> roundtrip()

      image = decoded.imageMessage
      assert Map.get(image, :URL) == upload_fixture().url
      assert image.caption == "look"
      assert image.height == 480
      assert image.width == 640
      assert image.fileLength == upload_fixture().file_length
      assert image.mediaKey == upload_fixture().media_key
      assert image.viewOnce == true
    end

    test "an audio builder keeps the voice-note flag and waveform" do
      waveform = :binary.copy(<<7>>, 64)

      decoded =
        Messages.build_audio_proto(upload_fixture(), ptt: true, seconds: 12, waveform: waveform)
        |> roundtrip()

      audio = decoded.audioMessage
      assert Map.get(audio, :PTT) == true
      assert audio.seconds == 12
      assert audio.waveform == waveform
    end
  end

  describe "text and context round-trip" do
    test "a quoted reply decodes back with its context" do
      decoded =
        Messages.build_text_proto("reply", quoted_id: "3EB0AA", quoted_participant: @jid)
        |> roundtrip()

      extended = decoded.extendedTextMessage
      assert extended.text == "reply"
      assert extended.contextInfo.stanzaID == "3EB0AA"
      assert extended.contextInfo.participant == @jid
    end

    test "plain text stays a bare conversation" do
      assert %{conversation: "ciao", extendedTextMessage: nil} =
               Messages.build_text_proto("ciao") |> roundtrip()
    end
  end

  describe "event round-trip" do
    test "the message secret and event fields survive" do
      secret = :binary.copy(<<0xAB>>, 32)

      decoded =
        Messages.build_event_proto("standup", 1_800_000_000,
          message_secret: secret,
          location: %{latitude: 45.4642, longitude: 9.19, name: "Piazza"}
        )
        |> roundtrip()

      assert decoded.messageContextInfo.messageSecret == secret

      event = decoded.eventMessage
      assert event.name == "standup"
      assert event.startTime == 1_800_000_000
      assert event.location.degreesLatitude == 45.4642
      assert event.location.name == "Piazza"
    end
  end

  describe "September 2026 upstream wire fixtures" do
    # Produced by protoc --encode=WAWebProtobufsE2E.Message against
    # tulir/whatsmeow 9ec8f76db5f17712efc34a29b684a80d2dcb4aaf.
    # These bytes are independent of Protox and pin the new field numbers,
    # packed uint32 encoding and nested oneof alternatives.
    test "ACP2 settings decode in protocol messages, context and wrappers" do
      bytes =
        Base.decode16!(
          "621110279A020C080110011880A4A7DA0620009A020EA20106616E63686F72AA01020801" <>
            "AA080B0A090A0770726976616379"
        )

      decoded = Message.decode!(bytes)
      assert decoded.protocolMessage.type == :ACP2_SETTING

      assert %WACommon.ACP2Setting{
               enabled: true,
               trigger: :CHAT_SETTING,
               settingTimestamp: 1_800_000_000,
               initiatedByMe: false
             } = decoded.protocolMessage.acp2Setting

      assert decoded.messageContextInfo.teeContextAnchorMessageID == "anchor"
      assert decoded.messageContextInfo.acp2Setting.enabled == true
      assert decoded.acp2SettingMessage.message.conversation == "privacy"
      assert encode(decoded) == bytes
    end

    test "scheduled newsletter messages retain their nested payload" do
      bytes = Base.decode16!("A2080D0A0B0A097363686564756C6564")
      decoded = Message.decode!(bytes)

      assert decoded.newsletterScheduledMessage.message.conversation == "scheduled"
      assert encode(decoded) == bytes
    end

    test "DASH video metadata preserves packed experience IDs through uint32 maximum" do
      bytes =
        Base.decode16!(
          "4A2F8A010B92050801AC02FFFFFFFF0F8A021E" <>
            "68747470733A2F2F6578616D706C652E746573742F766964656F2E6D7064"
        )

      decoded = Message.decode!(bytes)

      assert decoded.videoMessage.dashManifestURL == "https://example.test/video.mpd"
      assert decoded.videoMessage.contextInfo.experienceIDs == [1, 300, 4_294_967_295]
      assert encode(decoded) == bytes
    end

    test "business AI metadata preserves both server-event alternatives" do
      fixtures = [
        {"620B1023FA010612040A020801", {:protocolEvent, :AGENT_CHAT_READY}},
        {"620D1023FA010812060A041202083C",
         {:agentOnboardingStarted,
          %WAWebProtobufsAICommon.BizAIMetadataSync.ServerEvent.AgentOnboardingStarted{
            composerBlockDurationSecs: 60
          }}}
      ]

      for {hex, expected_event} <- fixtures do
        bytes = Base.decode16!(hex)
        decoded = Message.decode!(bytes)
        assert decoded.protocolMessage.type == :AI_METADATA_OPERATION

        assert {:serverEvent, server_event} =
                 decoded.protocolMessage.aiMetadataOperation.bizAiMetadataSync.operation

        assert server_event.event == expected_event
        assert encode(decoded) == bytes
      end
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
