defmodule ExWapp.BinaryProtocolParityTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Binary.{Node, Raw}
  alias ExWapp.JID

  describe "binary length boundaries" do
    test "round-trips BINARY_8, BINARY_20 and BINARY_32 payload sizes" do
      for size <- [0, 1, 255, 256, 4_096, 1_048_576] do
        payload = :binary.copy(<<rem(size, 251)>>, size)
        node = %Node{tag: "message", attrs: %{}, content: Binary.raw(payload)}

        assert {:ok, encoded} = Binary.encode(node)
        assert {:ok, %Node{content: %Raw{data: ^payload}}} = Binary.decode(encoded)
      end
    end

    test "round-trips more than 255 child nodes through LIST_16" do
      children =
        for index <- 0..299 do
          %Node{
            tag: "key",
            attrs: %{"id" => index},
            content: Binary.raw(<<index::unsigned-integer-size(16)>>)
          }
        end

      decoded =
        %Node{tag: "list", attrs: %{}, content: children}
        |> Binary.encode!()
        |> Binary.decode!()

      assert length(decoded.content) == 300

      assert %Node{attrs: %{"id" => "0"}, content: %Raw{data: <<0::16>>}} =
               hd(decoded.content)

      assert %Node{attrs: %{"id" => "299"}, content: %Raw{data: <<299::16>>}} =
               List.last(decoded.content)
    end
  end

  describe "node and token round-trips" do
    test "handles double-byte dictionary tokens in attributes and child tags" do
      node = %Node{
        tag: "iq",
        attrs: %{"to" => "s.whatsapp.net", "xmlns" => "passive", "type" => "set"},
        content: [%Node{tag: "active", attrs: %{}, content: nil}]
      }

      decoded = node |> Binary.encode!() |> Binary.decode!()

      assert decoded.attrs["xmlns"] == "passive"
      assert [%Node{tag: "active"}] = decoded.content
    end

    test "normalizes nil attributes and omits nil or empty values" do
      assert %Node{attrs: %{}} =
               %Node{tag: "message", attrs: nil, content: nil}
               |> Binary.encode!()
               |> Binary.decode!()

      decoded =
        %Node{
          tag: "message",
          attrs: %{"keep" => "value", "drop_nil" => nil, "drop_empty" => ""},
          content: nil
        }
        |> Binary.encode!()
        |> Binary.decode!()

      assert decoded.attrs == %{"keep" => "value"}
    end

    test "normalizes integer and boolean attribute values to wire strings" do
      decoded =
        %Node{tag: "message", attrs: %{"count" => 42, "enabled" => true}, content: nil}
        |> Binary.encode!()
        |> Binary.decode!()

      assert decoded.attrs == %{"count" => "42", "enabled" => "true"}
    end

    test "preserves nested nodes, special characters and null bytes" do
      raw = <<0, 1, 0, 2, 0>>

      node = %Node{
        tag: "message",
        attrs: %{"text" => "Hello\nWorld\t\"quoted\""},
        content: [
          %Node{
            tag: "device-identity",
            attrs: %{"key-index" => "1"},
            content: Binary.raw(raw)
          }
        ]
      }

      decoded = node |> Binary.encode!() |> Binary.decode!()

      assert decoded.attrs["text"] == "Hello\nWorld\t\"quoted\""
      assert [%Node{tag: "device-identity", content: %Raw{data: ^raw}}] = decoded.content
    end
  end

  describe "JID wire forms" do
    test "round-trips device JIDs across WhatsApp, LID and hosted domains" do
      jids = [
        JID.new_ad("1234", 0, 5),
        JID.new_ad("1234", 1, 6),
        JID.new_ad("1234", 128, 7)
      ]

      for jid <- jids do
        decoded =
          %Node{tag: "message", attrs: %{"from" => jid}, content: nil}
          |> Binary.encode!()
          |> Binary.decode!()

        assert decoded.attrs["from"] == jid
      end
    end

    test "round-trips messenger and interop JIDs with extended fields" do
      messenger = JID.new("1234", JID.messenger_server()) |> JID.with_device(12)

      interop =
        JID.new("5678", JID.interop_server())
        |> JID.with_device(13)
        |> JID.with_integrator(99)

      for jid <- [messenger, interop] do
        decoded =
          %Node{tag: "message", attrs: %{"jid" => jid}, content: nil}
          |> Binary.encode!()
          |> Binary.decode!()

        assert decoded.attrs["jid"] == jid
      end
    end

    test "a malformed device segment round-trips as a raw string" do
      decoded =
        %Node{
          tag: "message",
          attrs: %{"from" => "1234:xx@s.whatsapp.net"},
          content: nil
        }
        |> Binary.encode!()
        |> Binary.decode!()

      assert decoded.attrs["from"] == "1234:xx@s.whatsapp.net"
    end
  end

  describe "decoder failures" do
    test "returns errors for empty, malformed and truncated frames" do
      malformed = [
        <<>>,
        <<0>>,
        <<255, 255, 255>>,
        <<0, 248>>,
        <<0, 249, 0>>,
        <<0, 248, 2>>
      ]

      for payload <- malformed do
        assert {:error, _reason} = Binary.decode(payload)
      end
    end

    test "rejects otherwise valid nodes with trailing bytes" do
      encoded = Binary.encode!(%Node{tag: "iq", attrs: %{}, content: nil})
      assert {:error, _reason} = Binary.decode(encoded <> <<0xFF>>)
    end
  end
end
