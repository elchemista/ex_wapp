defmodule ExWapp.AppState.LTHashTest do
  use ExUnit.Case, async: true

  alias ExWapp.AppState.LTHash

  test "new/0 returns 128 zero bytes" do
    hash = LTHash.new()
    assert byte_size(hash) == 128
    assert hash == :binary.copy(<<0>>, 128)
  end

  test "add then subtract returns original hash" do
    hash = LTHash.new()
    mac1 = :crypto.strong_rand_bytes(32)
    mac2 = :crypto.strong_rand_bytes(32)

    modified = LTHash.add(hash, [mac1, mac2])
    assert modified != hash

    restored = LTHash.subtract(modified, [mac1, mac2])
    assert restored == hash
  end

  test "subtract_then_add is equivalent to separate operations" do
    hash = :crypto.strong_rand_bytes(128)
    old_macs = [:crypto.strong_rand_bytes(32)]
    new_macs = [:crypto.strong_rand_bytes(32), :crypto.strong_rand_bytes(32)]

    result1 = LTHash.subtract_then_add(hash, old_macs, new_macs)
    result2 = hash |> LTHash.subtract(old_macs) |> LTHash.add(new_macs)

    assert result1 == result2
  end

  test "order of additions does not matter (commutative)" do
    hash = LTHash.new()
    mac1 = :crypto.strong_rand_bytes(32)
    mac2 = :crypto.strong_rand_bytes(32)

    result_a = LTHash.add(hash, [mac1, mac2])
    result_b = LTHash.add(hash, [mac2, mac1])

    assert result_a == result_b
  end

  test "wrapping behavior for u16 overflow" do
    # Create a hash where first u16 is 0xFFFF
    hash = <<0xFF, 0xFF>> <> :binary.copy(<<0>>, 126)
    # Adding something should wrap around
    mac = :crypto.strong_rand_bytes(32)

    result = LTHash.add(hash, [mac])
    assert byte_size(result) == 128
    # Result should differ from input
    assert result != hash
  end
end
