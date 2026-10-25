defmodule ExWapp.WireProtocolBoundariesTest do
  use ExUnit.Case, async: true
  alias ExWapp.Signal.WireFormat
  alias ExWapp.Message.Handler.Wire.ContentDecoder

  alias WAWebProtobufsE2E.{
    Message,
    FutureProofMessage,
    LiveLocationMessage,
    EventMessage,
    LocationMessage
  }

  test "Signal parser skips unknown fixed-width fields while rejecting truncated or mistyped fields" do
    key = <<5, 0::256>>
    valid = <<10, 33, key::binary, 34, 1, 42>>
    unknown = <<249, 1, 0::64, 253, 1, 0::32>>

    assert {:ok, parsed} =
             WireFormat.parse_signal_message(<<51>> <> valid <> unknown <> <<0::64>>)

    assert parsed.ciphertext == <<42>>
    assert parsed.counter == 0

    for {fields, reason} <- [
          {<<10, 33, 1>>, :invalid_length_delimited_field},
          {<<8, 1>>, {:invalid_field_type, 1}},
          {<<34, 1, 42>>, {:missing_field, 1}},
          {valid <> <<18, 1, 0>>, {:invalid_uint_field, 2}},
          {<<15>>, {:unsupported_wire_type, 7}},
          {:binary.copy(<<128>>, 11), :invalid_varint}
        ] do
      assert {:error, ^reason} = WireFormat.parse_signal_message(<<51>> <> fields <> <<0::64>>)
    end

    prekey = <<18, 33, key::binary, 26, 33, key::binary, 34, 1, 42, 10, 1, 0>>

    assert {:error, {:invalid_uint_field, 1}} =
             WireFormat.parse_prekey_signal_message(<<51>> <> prekey)
  end

  test "live locations and event locations survive protobuf decoding with every supported field" do
    live = %LiveLocationMessage{
      degreesLatitude: 45.5,
      degreesLongitude: 9.2,
      accuracyInMeters: 12,
      speedInMps: 1.5,
      degreesClockwiseFromMagneticNorth: 90,
      caption: "walking",
      sequenceNumber: 42,
      timeOffset: 3,
      JPEGThumbnail: <<1, 2>>
    }

    decoded =
      ContentDecoder.apply_media_from_plaintext(
        %{id: "location"},
        encode(%Message{liveLocationMessage: live})
      )

    assert decoded.id == "location"
    assert decoded.content_type == :location
    assert decoded.text == "walking"

    assert decoded.location == %{
             latitude: 45.5,
             longitude: 9.2,
             accuracy: 12,
             speed: 1.5,
             bearing: 90,
             comment: "walking",
             sequence_number: 42,
             time_offset: 3,
             jpeg_thumbnail: <<1, 2>>,
             is_live: true,
             name: nil,
             address: nil,
             url: nil
           }

    event = %EventMessage{
      name: "Meeting",
      location: %LocationMessage{degreesLatitude: 45.5, degreesLongitude: 9.2, name: "Office"}
    }

    result = ContentDecoder.apply_media_from_plaintext(%{}, encode(%Message{eventMessage: event}))
    assert result.event.location.name == "Office"
    assert result.event.location.latitude == 45.5
  end

  test "invalid and excessively nested message bodies cannot replace visible content" do
    before = %{text: "previous", id: "stable"}
    assert ContentDecoder.apply_media_from_plaintext(before, <<255>>) == before
    assert ContentDecoder.classify_decrypted_content(<<255>>, 0) == {:user_message, nil}

    nested =
      Enum.reduce(1..8, %Message{locationMessage: %LocationMessage{degreesLatitude: 45.0}}, fn _,
                                                                                               message ->
        %Message{ephemeralMessage: %FutureProofMessage{message: message}}
      end)

    assert ContentDecoder.apply_media_from_plaintext(before, encode(nested)) == before
    assert ContentDecoder.classify_decrypted_content(encode(nested), 0) == {:user_message, nil}
  end

  defp encode(message), do: message |> Message.encode!() |> elem(0) |> IO.iodata_to_binary()
end
