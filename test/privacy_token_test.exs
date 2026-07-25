defmodule ExWapp.PrivacyTokenTest do
  use ExUnit.Case, async: true

  alias ExWapp.PrivacyToken

  @week_seconds 7 * 24 * 60 * 60

  test "accepts tokens from the current and previous three weekly buckets" do
    now = 100 * @week_seconds + 123
    cutoff = PrivacyToken.cutoff_timestamp(now)

    assert PrivacyToken.valid?(%{token: <<1>>, timestamp: now}, now)
    assert PrivacyToken.valid?(%{token: <<1>>, timestamp: Integer.to_string(cutoff)}, now)
    refute PrivacyToken.valid?(%{token: <<1>>, timestamp: cutoff - 1}, now)
  end

  test "requires a non-empty token and a parseable timestamp" do
    now = 100 * @week_seconds

    refute PrivacyToken.valid?(%{token: <<>>, timestamp: now}, now)
    refute PrivacyToken.valid?(%{token: <<1>>, timestamp: "not-a-timestamp"}, now)
    refute PrivacyToken.valid?(%{timestamp: now}, now)
  end

  test "compares token records monotonically" do
    assert PrivacyToken.newer_or_equal?(
             %{token: <<2>>, timestamp: "11"},
             %{token: <<1>>, timestamp: 10}
           )

    refute PrivacyToken.newer_or_equal?(
             %{token: <<1>>, timestamp: 9},
             %{token: <<2>>, timestamp: "10"}
           )
  end
end
