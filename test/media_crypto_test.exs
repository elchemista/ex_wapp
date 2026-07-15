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

  test "validates encrypted hash, plaintext hash, length and media key" do
    assert {:ok, upload, body} = Media.Crypto.encrypt_upload("document-bytes", :document)
    ref = Media.ref_from_upload(upload)

    assert {:error, :invalid_media_enc_sha256} =
             Media.Crypto.decrypt_download(body, %{ref | file_enc_sha256: <<0::256>>})

    assert {:error, :invalid_media_sha256} =
             Media.Crypto.decrypt_download(body, %{ref | file_sha256: <<0::256>>})

    assert {:error, :media_length_mismatch} =
             Media.Crypto.decrypt_download(body, %{ref | file_length: upload.file_length + 1})

    assert {:error, :missing_media_key} =
             Media.Crypto.decrypt_download(body, %{ref | media_key: nil})

    assert {:error, :invalid_media_key} =
             Media.Crypto.decrypt_download(body, %{ref | media_key: <<1, 2>>})
  end

  test "rejects truncated bodies, unsupported types and invalid CBC padding" do
    assert {:ok, upload, body} =
             Media.Crypto.encrypt_upload("padding-check-needs-two-blocks", :image)

    ref = Media.ref_from_upload(upload)

    assert {:error, :media_too_short} = Media.Crypto.decrypt_download(<<0::80>>, ref)

    assert {:error, :unsupported_media_type} =
             Media.Crypto.decrypt_download(body, %{ref | type: :video})

    keys = Media.Crypto.derive_keys(upload.media_key, :image)
    ciphertext_size = byte_size(body) - 10
    <<ciphertext::binary-size(^ciphertext_size), _mac::binary-size(10)>> = body
    prefix_size = ciphertext_size - 17

    <<prefix::binary-size(^prefix_size), previous_last, last_block::binary-size(16)>> =
      ciphertext

    bad_ciphertext = prefix <> <<Bitwise.bxor(previous_last, 0xFF), last_block::binary>>

    bad_mac =
      :crypto.mac(:hmac, :sha256, keys.mac_key, keys.iv <> bad_ciphertext)
      |> binary_part(0, 10)

    padding_ref = %{ref | file_sha256: nil, file_enc_sha256: nil, file_length: nil}

    assert {:error, :invalid_padding} =
             Media.Crypto.decrypt_download(bad_ciphertext <> bad_mac, padding_ref)
  end
end
