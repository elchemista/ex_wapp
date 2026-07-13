defmodule ExWapp.Message.Handler.Wire.ContentDecoderTest do
  use ExUnit.Case, async: true

  alias ExWapp.Message.Handler.Wire.ContentDecoder

  test "classifies plaintext text and sender-key distribution payloads" do
    plaintext = <<0x0A, 5, "hello">>

    assert {:user_message, "hello"} =
             ContentDecoder.classify_decrypted_content(plaintext, 0)

    assert {:protocol, nil} =
             ContentDecoder.classify_decrypted_content(plaintext, 1)
  end

  test "decodes supported media fields without envelope concerns" do
    image =
      <<0x0A, 3, "url", 0x12, 10, "image/jpeg", 0x1A, 5, "photo", 0x28, 42>>

    plaintext = <<0x1A, byte_size(image), image::binary>>

    decoded = ContentDecoder.apply_media_from_plaintext(%{id: "message-1"}, plaintext)

    assert decoded.id == "message-1"
    assert decoded.content_type == :image
    assert decoded.media_type == :image
    assert decoded.text == "photo"
    assert decoded.media.type == :image
    assert decoded.media.url == "url"
    assert decoded.media.mimetype == "image/jpeg"
    assert decoded.media.file_length == 42
  end
end
