defmodule ExWapp.ProtoMessageMediaTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Media, Messages}
  alias WAWebProtobufsE2E.Message

  test "encodes image message at WA E2E message field 3" do
    upload = upload(:image)

    encoded =
      upload
      |> Messages.build_image_proto(mimetype: "image/png", caption: "hello")
      |> Message.encode!()
      |> elem(0)
      |> IO.iodata_to_binary()

    assert <<0x1A, _::binary>> = encoded
    assert :binary.match(encoded, "image/png") != :nomatch
    assert :binary.match(encoded, "hello") != :nomatch
  end

  test "encodes audio message at WA E2E message field 8" do
    upload = upload(:audio)

    encoded =
      upload
      |> Messages.build_audio_proto(
        mimetype: "audio/ogg; codecs=opus",
        ptt: true,
        duration: 7
      )
      |> Message.encode!()
      |> elem(0)
      |> IO.iodata_to_binary()

    assert <<0x42, _::binary>> = encoded
    assert :binary.match(encoded, "audio/ogg; codecs=opus") != :nomatch
  end

  defp upload(type) do
    %Media.Upload{
      type: type,
      url: "https://example.test/media",
      direct_path: "/mms/#{type}/abc",
      media_key: :binary.copy(<<1>>, 32),
      file_sha256: :binary.copy(<<2>>, 32),
      file_enc_sha256: :binary.copy(<<3>>, 32),
      file_length: 123
    }
  end
end
