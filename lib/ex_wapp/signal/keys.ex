defmodule ExWapp.Signal.Keys do
  @moduledoc false

  import Bitwise

  @p 57_896_044_618_658_097_711_785_492_504_343_953_926_634_992_332_820_282_019_728_792_003_956_564_819_949
  @l 7_237_005_577_332_262_213_973_186_563_042_994_240_857_116_359_379_907_606_001_950_938_285_454_250_989
  @d -4_513_249_062_541_557_337_682_894_930_092_624_173_785_641_285_191_125_241_628_941_591_882_900_924_598_840_740
  @base {15_112_221_349_535_400_772_501_151_409_588_531_511_454_012_693_041_857_206_046_113_283_949_847_762_202,
         46_316_835_694_926_478_169_428_394_003_475_163_141_307_993_866_256_225_615_783_033_603_165_251_855_960}
  @diversifier <<0xFE, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>

  @doc """
  Generate a new Curve25519 key pair suitable for Signal identity or pre-keys.
  """
  def generate_key_pair do
    priv = clamp(:crypto.strong_rand_bytes(32))
    {pub, _} = :crypto.generate_key(:ecdh, :x25519, priv)
    %{private: priv, public: pub}
  end

  @doc """
  Generate an unsigned one-time pre-key map.
  """
  def generate_prekey(id) when is_integer(id) do
    key = generate_key_pair()
    %{id: id, public: key.public, private: key.private}
  end

  @doc """
  Generate a signed pre-key using the identity key pair.
  """
  def generate_signed_prekey(%{private: identity_priv}, id) when is_integer(id) do
    pre = generate_prekey(id)
    signature = sign(identity_priv, pre.public)
    Map.put(pre, :signature, signature)
  end

  @doc """
  Sign the given Curve25519 public key using the identity private key with the
  Signal-specific XEdDSA scheme.
  """
  def sign(identity_private, curve25519_public)
      when is_binary(identity_private) and byte_size(identity_private) == 32 and
             is_binary(curve25519_public) and byte_size(curve25519_public) == 32 do
    message = <<5, curve25519_public::binary>>
    random = :crypto.strong_rand_bytes(64)

    sign_curve25519(identity_private, message, random)
  end

  @doc """
  Sign an arbitrary message using XEdDSA (Signal's curve25519 signature scheme).
  This is used for device signatures in ADV pairing.
  """
  def sign_message(identity_private, message)
      when is_binary(identity_private) and byte_size(identity_private) == 32 and
             is_binary(message) do
    random = :crypto.strong_rand_bytes(64)
    sign_curve25519(identity_private, message, random)
  end

  @doc """
  Verify a signature produced by `sign/2`.
  """
  def verify(identity_public, curve25519_public, signature)
      when is_binary(identity_public) and byte_size(identity_public) == 32 and
             is_binary(curve25519_public) and byte_size(curve25519_public) == 32 and
             is_binary(signature) and byte_size(signature) == 64 do
    message = <<5, curve25519_public::binary>>

    <<sig_prefix::binary-size(63), sig_last>> = signature
    sign_bit = sig_last &&& 0x80
    cleared_signature = sig_prefix <> <<sig_last &&& 0x7F>>

    case convert_curve_to_edwards(identity_public) do
      {:ok, ed_public} ->
        <<ed_prefix::binary-size(31), ed_last>> = ed_public
        adjusted_public = ed_prefix <> <<bor(ed_last, sign_bit)>>
        Ed25519.valid_signature?(cleared_signature, message, adjusted_public)

      :error ->
        false
    end
  end

  defp sign_curve25519(private_key, message, random) do
    priv_scalar = private_key |> :binary.decode_unsigned(:little)
    base_point = scalarmult(priv_scalar, @base)
    public_key = encodepoint(base_point)

    r_hash = :crypto.hash(:sha512, @diversifier <> private_key <> message <> random)
    r_scalar = reduce_scalar(r_hash)
    r_point = scalarmult(r_scalar, @base)
    encoded_r = encodepoint(r_point)

    hram_hash = :crypto.hash(:sha512, encoded_r <> public_key <> message)
    hram_scalar = reduce_scalar(hram_hash)

    s_scalar = mod(hram_scalar * priv_scalar + r_scalar, @l)
    s_bytes = <<s_scalar::little-size(256)>>

    <<sig_prefix::binary-size(63), sig_last>> = encoded_r <> s_bytes
    <<_::binary-size(31), pub_last>> = public_key
    signature = sig_prefix <> <<sig_last ||| (pub_last &&& 0x80)>>
    signature
  end

  defp reduce_scalar(binary) when is_binary(binary) do
    binary |> :binary.decode_unsigned(:little) |> mod(@l)
  end

  defp scalarmult(0, _pair), do: {0, 1}

  defp scalarmult(e, pair) do
    q = scalarmult(div(e, 2), pair)
    q = edwards(q, q)

    case band(e, 1) do
      1 -> edwards(q, pair)
      _ -> q
    end
  end

  defp edwards({x1, y1}, {x2, y2}) do
    x = (x1 * y2 + x2 * y1) * inv(1 + @d * x1 * x2 * y1 * y2)
    y = (y1 * y2 + x1 * x2) * inv(1 - @d * x1 * x2 * y1 * y2)
    {mod(x, @p), mod(y, @p)}
  end

  defp encodepoint({x, y}) do
    val =
      y
      |> band(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      |> bor((x &&& 1) <<< 255)

    <<val::little-size(256)>>
  end

  defp convert_curve_to_edwards(curve_public) do
    mont_x = curve_public |> :binary.decode_unsigned(:little)
    mont_x_minus_one = mod(mont_x - 1, @p)
    mont_x_plus_one = mod(mont_x + 1, @p)

    case mont_x_plus_one do
      0 ->
        :error

      _ ->
        inv_plus_one = inv(mont_x_plus_one)
        ed_y = mod(mont_x_minus_one * inv_plus_one, @p)
        {:ok, <<ed_y::little-size(256)>>}
    end
  end

  defp inv(x), do: expmod(x, @p - 2, @p)

  defp expmod(b, e, m) when b > 0 do
    b |> :crypto.mod_pow(e, m) |> :binary.decode_unsigned()
  end

  defp expmod(b, e, m) do
    i = b |> abs() |> :crypto.mod_pow(e, m) |> :binary.decode_unsigned()

    cond do
      mod(e, 2) == 0 -> i
      i == 0 -> i
      true -> m - i
    end
  end

  defp mod(x, _y) when x == 0, do: 0
  defp mod(x, y) when x > 0, do: rem(x, y)
  defp mod(x, y) when x < 0, do: rem(y + rem(x, y), y)

  defp clamp(<<b0, middle::binary-size(30), b31>>) do
    <<band(b0, 0xF8), middle::binary, bor(band(b31, 0x7F), 0x40)>>
  end
end
