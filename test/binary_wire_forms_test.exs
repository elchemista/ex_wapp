defmodule ExWapp.BinaryWireFormsTest do
  @moduledoc """
  Coverage for the counted wire forms and for the closure property between the
  encoder and the decoder.

  Two tags carry a count that the decoder must honour exactly. Numeric and
  hex-looking strings — message ids, timestamps, device numbers, prekey ids —
  travel as two characters per byte under NIBBLE_8 and HEX_8, whose length byte
  counts *pairs*; child nodes travel under LIST_8 and LIST_16, whose size counts
  children. Both counts can legitimately be zero, and whatsmeow reads either as
  "nothing here" by looping `i < count`.

  A decoder that reads a fixed two elements for a count of zero instead
  swallows the start of whichever field comes next, and every remaining field in
  the frame is then read at the wrong offset — so the damage is never confined
  to the empty value itself.

  That matters in both directions. A peer can put a zero count on the wire, and
  this library's own encoder emits one for an empty string, so the cheapest
  statement of the invariant is closure: anything `encode` accepts, `decode` has
  to read back.
  """

  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Binary.{Node, Raw, Token}

  # A frame the library did not build itself, assembled from the wire tags, so
  # these stay honest about inbound data rather than only testing a round-trip
  # against our own encoder.
  defp raw_string(value), do: <<Token.binary8(), byte_size(value)::8>> <> value

  defp frame(list_size, body), do: <<0, Token.list8(), list_size::8>> <> body

  defp empty_packed(tag), do: <<tag, 0>>

  describe "zero-length packed strings on the wire" do
    test "an empty packed value decodes as an empty string" do
      for tag <- [Token.nibble8(), Token.hex8()] do
        payload = frame(3, raw_string("iq") <> raw_string("a") <> empty_packed(tag))

        assert {:ok, %Node{tag: "iq", attrs: %{"a" => ""}}} = Binary.decode(payload),
               "tag #{tag} did not decode an empty packed string"
      end
    end

    test "an empty packed value does not consume the field that follows it" do
      # The regression: reading two bytes for a zero-pair string ate the next
      # attribute's tag and length, so "b" was parsed from the wrong offset and
      # the rest of the frame decoded as garbage or failed outright.
      for tag <- [Token.nibble8(), Token.hex8()] do
        payload =
          frame(
            5,
            raw_string("iq") <>
              raw_string("a") <> empty_packed(tag) <> raw_string("b") <> raw_string("ok")
          )

        assert {:ok, %Node{attrs: attrs}} = Binary.decode(payload)
        assert attrs == %{"a" => "", "b" => "ok"}, "tag #{tag} desynchronized the frame"
      end
    end

    test "an empty packed content byte still leaves the node's attributes intact" do
      payload =
        frame(
          4,
          raw_string("iq") <>
            raw_string("k") <> raw_string("v") <> empty_packed(Token.nibble8())
        )

      assert {:ok, %Node{tag: "iq", attrs: %{"k" => "v"}, content: ""}} = Binary.decode(payload)
    end

    test "an empty packed string inside a child node keeps the siblings readable" do
      child = frame(3, raw_string("enc") <> raw_string("v") <> empty_packed(Token.nibble8()))
      sibling = <<Token.list8(), 2>> <> raw_string("enc") <> raw_string("later")

      # Strip the leading transport flag byte from the nested frame.
      <<0, child_body::binary>> = child

      payload =
        frame(2, raw_string("message") <> <<Token.list8(), 2>> <> child_body <> sibling)

      assert {:ok, %Node{content: [first, second]}} = Binary.decode(payload)
      assert %Node{tag: "enc", attrs: %{"v" => ""}} = first
      assert %Node{tag: "enc", content: %Raw{data: "later"}} = second
    end
  end

  describe "zero-size child lists" do
    test "a zero-size list decodes as no children" do
      # Same shape of defect as the packed length byte, one tag over: the list
      # size counts children, and a size of zero has to mean zero.
      payload = frame(2, raw_string("message") <> <<Token.list8(), 0>>)

      assert {:ok, %Node{tag: "message", content: []}} = Binary.decode(payload)
    end

    test "a zero-size list does not consume the nodes after it" do
      sibling = <<Token.list8(), 2>> <> raw_string("enc") <> raw_string("payload")

      payload =
        frame(
          2,
          raw_string("message") <>
            <<Token.list8(), 2>> <>
            (<<Token.list8(), 2>> <> raw_string("a") <> <<Token.list8(), 0>>) <> sibling
        )

      assert {:ok, %Node{content: [first, second]}} = Binary.decode(payload)
      assert %Node{tag: "a", content: []} = first
      assert %Node{tag: "enc", content: %Raw{data: "payload"}} = second
    end
  end

  describe "encoder and decoder agree" do
    test "every node the encoder accepts decodes back" do
      # Closure, stated directly: a frame this library builds and cannot read is
      # a frame WhatsApp cannot read either.
      nodes = [
        %Node{tag: "iq", attrs: %{}, content: ""},
        %Node{tag: "iq", attrs: %{"id" => "1"}, content: ""},
        %Node{tag: "message", attrs: %{}, content: [%Node{tag: "body", content: ""}]},
        %Node{tag: "message", attrs: %{}, content: Binary.raw("")},
        %Node{tag: "iq", attrs: %{}, content: "0"},
        %Node{tag: "iq", attrs: %{}, content: "-"}
      ]

      for node <- nodes do
        assert {:ok, encoded} = Binary.encode(node)

        assert {:ok, _decoded} = Binary.decode(encoded),
               "encoder produced a frame it cannot read back: #{inspect(node)}"
      end
    end

    test "a hosted JID keeps its server class through encode and decode" do
      # Hosted JIDs ride the AD-JID form, whose agent byte doubles as the
      # domain type: 0 means s.whatsapp.net. A hosted JID parsed from a string
      # has no agent to carry, so the encoder must supply the hosted domain
      # type itself — or the address silently becomes a different account.
      decoded =
        %Node{tag: "message", attrs: %{"to" => "12345@hosted"}, content: nil}
        |> Binary.encode!()
        |> Binary.decode!()

      assert %ExWapp.JID{user: "12345", server: "hosted"} = decoded.attrs["to"]
    end

    test "an empty string survives as content rather than becoming nil" do
      decoded =
        %Node{tag: "iq", attrs: %{"id" => "7"}, content: ""}
        |> Binary.encode!()
        |> Binary.decode!()

      assert decoded.content == ""
      assert decoded.attrs == %{"id" => "7"}
    end
  end

  describe "packed alphabets" do
    test "round-trips every nibble character at odd and even lengths" do
      # NIBBLE_8 covers the digits plus '-' and '.', which is what carries
      # timestamps, counts and dotted device ids.
      for value <- ["0", "9", "-", ".", "12", "1-2.3", "0123456789", "1.2.3-4.5", "..--"] do
        decoded =
          %Node{tag: "iq", attrs: %{"v" => value}, content: nil}
          |> Binary.encode!()
          |> Binary.decode!()

        assert decoded.attrs["v"] == value
      end
    end

    test "round-trips every hex character at odd and even lengths" do
      for value <- ["A", "F", "AF", "ABCDEF", "0123456789ABCDEF", "3EB0C24E29478A59475F17"] do
        decoded =
          %Node{tag: "iq", attrs: %{"v" => value}, content: nil}
          |> Binary.encode!()
          |> Binary.decode!()

        assert decoded.attrs["v"] == value
      end
    end

    test "round-trips at and beyond the packed length ceiling" do
      # Above PackedMax the encoder has to fall back to a raw string; the two
      # paths must produce the same value on the way back.
      max = Token.packed_max()

      for length <- [max - 1, max, max + 1, max * 2] do
        value = String.duplicate("7", length)

        decoded =
          %Node{tag: "iq", attrs: %{"v" => value}, content: nil}
          |> Binary.encode!()
          |> Binary.decode!()

        assert decoded.attrs["v"] == value, "failed at length #{length}"
      end
    end

    test "a digit string that also parses as hex comes back unchanged" do
      # "0123456789" satisfies both alphabets. Whichever tag the encoder picks,
      # the decoder has to agree with it.
      for value <- ["0", "00", "000000", "9999999999999999999999"] do
        decoded =
          %Node{tag: "iq", attrs: %{"v" => value}, content: nil}
          |> Binary.encode!()
          |> Binary.decode!()

        assert decoded.attrs["v"] == value
      end
    end
  end

  describe "randomized round-trips" do
    test "realistic node shapes survive encode and decode" do
      # Seeded so a failure is reproducible. This is the shape of check that
      # catches offset bugs: they only show up when a short field is followed by
      # something whose value the assertion can notice moving.
      :rand.seed(:exsss, {20_260_729, 1, 1})

      for _ <- 1..2_000 do
        node = random_node(3)

        assert {:ok, encoded} = Binary.encode(node)
        assert {:ok, decoded} = Binary.decode(encoded)

        assert comparable(node) == comparable(decoded),
               "round-trip changed the node: #{inspect(node, limit: :infinity)}"
      end
    end
  end

  # Raw and string content are the same bytes on the wire, so compare them as
  # bytes rather than by which struct the decoder chose.
  defp comparable(%Node{} = node) do
    content =
      case node.content do
        nil -> nil
        %Raw{data: data} -> {:bytes, data}
        binary when is_binary(binary) -> {:bytes, binary}
        list when is_list(list) -> Enum.map(list, &comparable/1)
      end

    %{tag: node.tag, attrs: node.attrs, content: content}
  end

  # Attribute keys that name a JID decode into a %JID{} struct by design, and
  # empty attribute values are dropped by design. Neither is what these
  # round-trips are measuring, so the generator stays clear of both.
  @jid_attribute_names ~w(to from participant recipient sender_lid participant_lid jid)
  @tags ~w(message iq enc node list item user key a receipt ack)

  defp random_node(0),
    do: %Node{tag: random_tag(), attrs: random_attrs(), content: leaf_content()}

  defp random_node(depth) do
    content =
      case :rand.uniform(5) do
        1 -> nil
        2 -> random_value()
        3 -> Binary.raw(:crypto.strong_rand_bytes(:rand.uniform(60)))
        _ -> for _ <- 1..:rand.uniform(4), do: random_node(depth - 1)
      end

    %Node{tag: random_tag(), attrs: random_attrs(), content: content}
  end

  defp leaf_content do
    case :rand.uniform(4) do
      1 -> nil
      2 -> random_value()
      _ -> Binary.raw(:crypto.strong_rand_bytes(:rand.uniform(40)))
    end
  end

  defp random_tag, do: Enum.random(@tags)

  defp random_attrs do
    for _ <- 1..:rand.uniform(5), into: %{}, do: {random_key(), random_value()}
  end

  defp random_key do
    Stream.repeatedly(&random_string/0)
    |> Enum.find(&(&1 != "" and &1 not in @jid_attribute_names))
  end

  defp random_value do
    Stream.repeatedly(&random_string/0) |> Enum.find(&(&1 != ""))
  end

  defp random_string do
    case :rand.uniform(6) do
      1 -> Enum.random(~w(message iq receipt id type xmlns count v t))
      2 -> random_chars(~c"abcdefghijklmnopqrstuvwxyz0123456789-_.", 12)
      3 -> random_chars(~c"0123456789", 20)
      4 -> random_chars(~c"ABCDEF0123456789", 30)
      5 -> Enum.random(["1-2.3", "...", "---", "0", "9", "3EB0"])
      6 -> for _ <- 1..:rand.uniform(6), into: "", do: <<Enum.random(~c"àéîõü✓😀")::utf8>>
    end
  end

  defp random_chars(alphabet, max) do
    for _ <- 1..:rand.uniform(max), into: "", do: <<Enum.random(alphabet)>>
  end
end
