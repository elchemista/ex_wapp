defmodule ExWapp.Message.Handler.Wire.FieldsTest do
  use ExUnit.Case, async: true

  alias ExWapp.Message.Handler.Wire.Fields

  test "decodes length-delimited and varint protobuf primitives" do
    payload = <<0x0A, 3, "abc", 0x10, 7>>

    assert {:ok, fields} = Fields.decode_safe(payload)
    assert Fields.first_length_delimited(fields, 1) == "abc"
    assert Fields.all_length_delimited(fields, 1) == ["abc"]
    assert Fields.first_varint(fields, 2) == 7
    assert Fields.bytes(payload, 1) == "abc"
    assert Fields.varint(payload, 2) == 7
  end

  test "returns explicit errors for malformed length-delimited data" do
    assert {:error, :invalid_length} = Fields.decode_safe(<<0x0A, 5, "abc">>)
    assert {:error, :invalid_length} = Fields.find_length_delimited(<<0x0A, 5, "abc">>, 1)
  end

  test "readers skip mixed wire types and preserve repeated bytes in wire order" do
    payload =
      <<8, 150, 1, 17, 1.25::little-float-64, 26, 1, "a", 37, -2.5::little-float-32, 26, 0, 26, 1,
        "b", 40, 0>>

    assert {:ok, fields} = Fields.decode_safe(payload)
    assert Fields.all_length_delimited(fields, 3) == ["a", "", "b"]
    assert Fields.first_length_delimited(fields, 99) == nil
    assert Fields.first_varint(fields, 99) == nil
    assert Fields.first_varint(fields, 5) == 0
    assert {:ok, ["a", "", "b"]} = Fields.collect_length_delimited_values(payload)
    assert Fields.bytes(payload, 3) == "a"
    assert Fields.bytes(payload, 99) == nil
    assert Fields.varint(payload, 5) == 0
    assert Fields.varint(payload, 99) == nil
    assert Fields.double(payload, 2) == 1.25
    assert Fields.float(payload, 4) == -2.5
    assert Fields.double(payload, 4) == nil
    assert Fields.float(payload, 2) == nil
    assert Fields.double(payload, 99) == nil
  end

  test "boolean lookup distinguishes false from absent or non-boolean values" do
    payload = <<8, 0, 16, 1, 24, 2>>
    assert Fields.bool(payload, 1) == false
    assert Fields.bool(payload, 2) == true
    assert Fields.bool(payload, 3) == nil
    assert Fields.bool(payload, 4) == nil
  end

  for {name, payload, reason} <- [
        {"truncated tag", <<128>>, :invalid_varint},
        {"oversized tag", :binary.copy(<<128>>, 11), :invalid_varint},
        {"truncated varint", <<8, 128>>, :invalid_varint},
        {"oversized varint", <<8>> <> :binary.copy(<<128>>, 11), :invalid_varint},
        {"truncated length", <<10, 128>>, :invalid_varint},
        {"oversized length", <<10>> <> :binary.copy(<<128>>, 11), :invalid_varint},
        {"truncated bytes", <<10, 3, "a">>, :invalid_length},
        {"truncated fixed64", <<17, 1, 2>>, :invalid_fixed64},
        {"truncated fixed32", <<37, 1, 2>>, :invalid_fixed32},
        {"unsupported group", <<11>>, {:unsupported_wire_type, 3}}
      ] do
    test "all readers handle #{name} without raising" do
      payload = unquote(payload)
      expected = {:error, unquote(Macro.escape(reason))}

      assert Fields.decode_safe(payload) == expected
      assert Fields.find_length_delimited(payload, 99) == expected
      assert Fields.collect_length_delimited_values(payload) == expected
      assert Fields.bytes(payload, 99) == nil
      assert Fields.varint(payload, 99) == nil
      assert Fields.float(payload, 99) == nil
      assert Fields.double(payload, 99) == nil
    end
  end
end
