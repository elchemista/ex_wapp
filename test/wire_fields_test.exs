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
end
