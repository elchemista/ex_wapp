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

  defp encode(proto), do: proto |> Message.encode!() |> IO.iodata_to_binary()
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
