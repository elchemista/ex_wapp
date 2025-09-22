defmodule ExWapp.BinaryUnpackTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.Binary

  test "unpack returns raw payload when flag not set" do
    data = <<0, 1, 2, 3>>

    assert {:ok, <<1, 2, 3>>} = Binary.unpack(data)
  end

  test "unpack inflates zlib compressed payload" do
    original = "hello, whatsapp"
    compressed = :zlib.compress(original)

    # Leading flag byte with compression bit set (0x02)
    payload = <<0x02>> <> compressed

    assert {:ok, ^original} = Binary.unpack(payload)
  end

  test "unpack returns error for invalid frames" do
    assert {:error, :invalid_frame} = Binary.unpack(<<>>)
  end
end
