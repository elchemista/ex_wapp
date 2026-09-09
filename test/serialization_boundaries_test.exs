defmodule ExWapp.SerializationBoundariesTest do
  use ExUnit.Case, async: true
  alias ExWapp.Binary
  alias ExWapp.Store.Codec

  test "persistent snapshots reject malformed envelopes and nested type tags" do
    invalid_values = [
      nil,
      1,
      "raw",
      %{"$t" => "bin", "v" => "!"},
      %{"$t" => "tuple", "v" => ["untagged"]},
      %{"$t" => "map", "v" => [1]},
      %{"$t" => "map", "v" => [["untagged", nil]]},
      %{"$t" => "struct", "m" => "Elixir.ExWapp.Chat", "v" => []},
      %{"$t" => "struct", "m" => "Elixir.ExWapp.Chat", "v" => %{"bad" => 1}},
      %{"$t" => "struct", "m" => "Elixir.Enum", "v" => %{}}
    ]

    for value <- invalid_values do
      blob = blob(%{"codec" => "ex_wapp_json_v2", "version" => 2, "data" => value})
      assert Codec.encoded?(blob)
      assert {:error, :invalid_store_blob} = Codec.decode(blob)
    end

    for envelope <- [%{}, %{"codec" => "ex_wapp_json_v2", "version" => 3, "data" => %{}}] do
      assert {:error, :invalid_store_blob} = Codec.decode(blob(envelope))
    end

    assert {:error, :invalid_store_map} = Codec.encode([])

    for unsupported <- [self(), make_ref(), fn -> :ok end, <<1::1>>] do
      assert {:error, {:unsupported_store_term, _}} = Codec.encode(%{value: unsupported})
    end

    refute Codec.encoded?(nil)
    assert {:ok, encoded} = Codec.encode(%{latitude: 45.5, longitude: -9.125})
    assert {:ok, %{latitude: 45.5, longitude: -9.125}} = Codec.decode(encoded)
  end

  test "supported node shorthand normalizes to the same wire representation" do
    for {input, expected} <- [
          {:ping, %Binary.Node{tag: "ping"}},
          {"ping", %Binary.Node{tag: "ping"}},
          {{:iq, [type: :get, id: 42]},
           %Binary.Node{tag: "iq", attrs: %{"type" => "get", "id" => "42"}}},
          {{:iq, %{}, {:ping, %{}}},
           %Binary.Node{tag: "iq", content: [%Binary.Node{tag: "ping"}]}}
        ] do
      assert {:ok, bytes} = Binary.encode(input)
      assert {:ok, ^expected} = Binary.decode(bytes)
    end
  end

  test "unsupported node shapes fail before writing a partial stanza" do
    for value <- [
          123,
          {:iq, :bad_attrs},
          {:iq, [123]},
          {:iq, %{}, ["not a node"]},
          {:iq, %{}, make_ref()},
          {:iq, %{}, {:too, :many, :tuple, :fields}}
        ] do
      assert {:error, _} = Binary.encode(value)
      assert_raise Binary.Error, fn -> Binary.encode!(value) end
    end

    assert {:ok, encoded} = Binary.encode({:iq, ["last", {:id, "ok"}], nil})
    assert {:ok, %Binary.Node{attrs: %{"last" => "true", "id" => "ok"}}} = Binary.decode(encoded)
  end

  defp blob(envelope), do: "EXWAPPJ2" <> :zlib.gzip(JSON.encode!(envelope))
end
