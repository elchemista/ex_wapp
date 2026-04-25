defmodule ExWapp.MediaCryptoTest do
  use ExUnit.Case, async: true

  alias ExWapp.Media

  test "encrypt_upload/decrypt_download round trips image bytes" do
    plaintext = "image-bytes"

    assert {:ok, upload, body} = Media.Crypto.encrypt_upload(plaintext, :image)

    ref = Media.ref_from_upload(upload, mimetype: "image/jpeg")

    assert {:ok, ^plaintext} = Media.Crypto.decrypt_download(body, ref)
    assert upload.file_length == byte_size(plaintext)
    assert byte_size(upload.media_key) == 32
    assert byte_size(upload.file_sha256) == 32
    assert byte_size(upload.file_enc_sha256) == 32
  end

  test "decrypt_download rejects modified ciphertext" do
    assert {:ok, upload, body} = Media.Crypto.encrypt_upload("audio-bytes", :audio)
    ref = Media.ref_from_upload(upload, mimetype: "audio/ogg; codecs=opus")

    tampered = binary_part(body, 0, byte_size(body) - 1) <> <<0>>

    assert {:error, reason} = Media.Crypto.decrypt_download(tampered, ref)
    assert reason in [:invalid_media_hmac, :invalid_media_enc_sha256]
  end
end
