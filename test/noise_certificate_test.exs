defmodule ExWapp.NoiseCertificateTest do
  use ExUnit.Case, async: true

  alias ExWapp.Noise.Certificate

  @pub Base.decode16!("0537C2BB45CAC4CF3DDD0D41FD6B6F1733F9D182031E4AE98EF3477B680993BA57",
         case: :mixed
       )
       |> binary_part(1, 32)
  @sig Base.decode16!(
         "B97322CE463FF331C58AFD9713B5275F0C2CB66D341BCE8EA45A4362EC11A64A8FE010BBD2C5A28A72615EDA0A16ED85CC6298717E1F42AD8DB33DF846359505",
         case: :mixed
       )
  @msg "hello noise"

  test "curve25519 signatures verify" do
    assert Certificate.verify_signature(@pub, @msg, @sig)
  end

  test "curve25519 signature fails with wrong message" do
    refute Certificate.verify_signature(@pub, "hello", @sig)
  end
end
