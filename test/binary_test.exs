defmodule ExWapp.BinaryTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Binary.{Node, Raw}

  test "encode/decode simple node" do
    node = {
      "iq",
      %{"id" => "123", "type" => "get"},
      [
        {"ping", %{}, nil}
      ]
    }

    assert {:ok, encoded} = Binary.encode(node)
    assert is_binary(encoded)

    assert {:ok, decoded} = Binary.decode(encoded)
    assert decoded.tag == "iq"
    assert decoded.attrs == %{"id" => "123", "type" => "get"}
    assert [%Node{tag: "ping", attrs: %{}, content: nil}] = decoded.content
  end

  test "preserves raw binary content" do
    payload = <<1, 2, 3, 4>>
    node = %Node{tag: "binary", attrs: %{}, content: Binary.raw(payload)}

    encoded = Binary.encode!(node)
    decoded = Binary.decode!(encoded)

    assert decoded.tag == "binary"
    assert %Raw{data: ^payload} = decoded.content
  end

  test "packed nibble strings round-trip" do
    node = {"test", %{"number" => "12345"}, nil}

    encoded = Binary.encode!(node)
    decoded = Binary.decode!(encoded)

    assert decoded.attrs == %{"number" => "12345"}
  end
end
