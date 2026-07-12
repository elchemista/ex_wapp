defmodule ExWapp.BinaryTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Binary.{Node, Raw}
  alias ExWapp.JID

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

  test "encodes jid-shaped protocol attributes as binary JIDs" do
    node =
      {"iq", %{"to" => "s.whatsapp.net", "type" => "get"},
       [
         {"key", %{},
          [
            {"user", %{"jid" => "393519534944@s.whatsapp.net", "reason" => "identity"},
             nil}
          ]}
       ]}

    decoded = node |> Binary.encode!() |> Binary.decode!()

    assert %JID{user: "", server: "s.whatsapp.net"} = decoded.attrs["to"]
    assert [key] = decoded.content
    assert [user] = key.content
    assert %JID{user: "393519534944", server: "s.whatsapp.net"} = user.attrs["jid"]
    assert user.attrs["reason"] == "identity"
  end

  test "encodes linked-device jid attributes with the AD JID token" do
    node = {"to", %{"jid" => "393519534944:32@s.whatsapp.net"}, nil}

    assert %Node{attrs: %{"jid" => %JID{user: "393519534944", device: 32}}} =
             node |> Binary.encode!() |> Binary.decode!()
  end
end
