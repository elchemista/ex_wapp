defmodule ExWapp.SignalEncryptionPaddingTest do
  use ExUnit.Case, async: true

  alias ExWapp.Signal.Encryption

  test "unpad_message strips valid trailing padding" do
    plaintext = <<0x0A, 0x03, "hello">>
    padded = plaintext <> <<3, 3, 3>>

    assert Encryption.unpad_message(padded) == plaintext
  end

  test "unpad_message does not strip when trailing bytes are not padding" do
    payload = <<0x0A, 0x03, "hey", 0x02, 0x03>>

    assert Encryption.unpad_message(payload) == payload
  end

  test "unpad_message keeps payload unchanged for version 3" do
    payload = <<0x0A, 0x05, "hello", 0x01>>

    assert Encryption.unpad_message(payload, 3) == payload
    assert Encryption.unpad_message(payload, "3") == payload
  end
end
