defmodule ExWapp.InboundMessageContractTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Media, Messages}
  alias ExWapp.Message.Handler.Wire
  alias WAWebProtobufsE2E.Message

  test "image payload exposes a direct public media reference" do
    message =
      :image
      |> upload()
      |> Messages.build_image_proto(
        mimetype: "image/png",
        caption: "inbound image",
        height: 720,
        width: 1280,
        jpeg_thumbnail: <<10, 11, 12>>
      )
      |> decode_inbound()

    assert %{
             content_type: :image,
             media_type: :image,
             text: "inbound image",
             media: %Media.Ref{
               type: :image,
               url: "https://example.test/image",
               direct_path: "/mms/image/fixture",
               mimetype: "image/png",
               file_length: 123,
               metadata: %{
                 height: 720,
                 width: 1280,
                 thumbnail: <<10, 11, 12>>
               }
             }
           } = message
  end

  test "PTT payload exposes audio metadata on the direct media reference" do
    message =
      :audio
      |> upload()
      |> Messages.build_audio_proto(
        mimetype: "audio/ogg; codecs=opus",
        ptt: true,
        seconds: 7,
        waveform: <<1, 3, 5, 7>>
      )
      |> decode_inbound()

    assert %{
             content_type: :audio,
             media_type: :audio,
             text: nil,
             media: %Media.Ref{
               type: :audio,
               mimetype: "audio/ogg; codecs=opus",
               metadata: %{ptt: true, seconds: 7, waveform: <<1, 3, 5, 7>>}
             }
           } = message
  end

  test "document payload exposes filename, title, caption, and page count" do
    message =
      :document
      |> upload()
      |> Messages.build_document_proto(
        mimetype: "application/pdf",
        title: "Contract",
        file_name: "contract.pdf",
        caption: "inbound document",
        page_count: 3
      )
      |> decode_inbound()

    assert %{
             content_type: :document,
             media_type: :document,
             text: "inbound document",
             media: %Media.Ref{
               type: :document,
               mimetype: "application/pdf",
               metadata: %{
                 title: "Contract",
                 file_name: "contract.pdf",
                 page_count: 3
               }
             }
           } = message
  end

  test "location payload exposes decoded coordinates and labels" do
    location =
      Messages.build_location_proto(45.4642, 9.19,
        name: "Duomo di Milano",
        address: "Piazza del Duomo, Milano",
        comment: "meet here",
        accuracy: 5
      )
      |> decode_inbound()

    assert %{content_type: :location, text: "meet here", location: location_value} = location
    assert_in_delta location_value.latitude, 45.4642, 0.000_001
    assert_in_delta location_value.longitude, 9.19, 0.000_001
    assert location_value.name == "Duomo di Milano"
    assert location_value.address == "Piazza del Duomo, Milano"
    assert location_value.accuracy == 5
  end

  test "contact payload exposes a decoded vCard" do
    contact =
      Messages.build_contact_proto(
        "Ada Lovelace",
        "BEGIN:VCARD\nFN:Ada Lovelace\nEND:VCARD",
        is_self_contact: false
      )
      |> decode_inbound()

    assert %{
             content_type: :contact,
             text: "Ada Lovelace",
             contact: %{
               display_name: "Ada Lovelace",
               vcard: "BEGIN:VCARD\nFN:Ada Lovelace\nEND:VCARD",
               is_self_contact: false
             }
           } = contact
  end

  test "event payload exposes decoded scheduling fields" do
    event =
      Messages.build_event_proto("Release", 1_800_000_000,
        description: "Ship it",
        end_time: 1_800_003_600,
        has_reminder: true,
        reminder_offset_seconds: 900,
        message_secret: :binary.copy(<<9>>, 32)
      )
      |> decode_inbound()

    assert %{
             content_type: :event,
             text: "Release",
             event: %{
               name: "Release",
               description: "Ship it",
               start_time: 1_800_000_000,
               end_time: 1_800_003_600,
               has_reminder: true,
               reminder_offset_seconds: 900
             }
           } = event
  end

  test "supported content is decoded through ephemeral wrappers" do
    image_payload =
      :image
      |> upload()
      |> Messages.build_image_proto(caption: "wrapped image")
      |> Message.encode!()
      |> elem(0)
      |> IO.iodata_to_binary()

    wrapped_payload = encode_length_delimited(31, encode_length_delimited(2, image_payload))
    message = Wire.apply_media_from_plaintext(%{text: nil, media: nil}, wrapped_payload)

    assert %{
             content_type: :image,
             text: "wrapped image",
             media: %Media.Ref{type: :image}
           } = message
  end

  defp decode_inbound(proto) do
    payload = IO.iodata_to_binary(elem(Message.encode!(proto), 0))
    Wire.apply_media_from_plaintext(%{text: nil, media: nil}, payload)
  end

  defp upload(type) do
    %Media.Upload{
      type: type,
      url: "https://example.test/#{type}",
      direct_path: "/mms/#{type}/fixture",
      media_key: :binary.copy(<<1>>, 32),
      file_sha256: :binary.copy(<<2>>, 32),
      file_enc_sha256: :binary.copy(<<3>>, 32),
      file_length: 123,
      media_key_timestamp: 1_800_000_000
    }
  end

  defp encode_length_delimited(field, payload) do
    encode_varint(Bitwise.bsl(field, 3) + 2) <> encode_varint(byte_size(payload)) <> payload
  end

  defp encode_varint(value) when value < 128, do: <<value>>

  defp encode_varint(value) do
    byte = Bitwise.bor(Bitwise.band(value, 0x7F), 0x80)
    <<byte, encode_varint(Bitwise.bsr(value, 7))::binary>>
  end
end
