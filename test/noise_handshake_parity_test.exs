defmodule ExWapp.Noise.HandshakeParityTest do
  use ExUnit.Case, async: true

  alias ExWapp.Noise.Handshake
  alias ExWapp.Signal.Keys

  @pattern "Noise_XX_25519_AESGCM_SHA256\x00\x00\x00\x00"

  describe "state initialization and authentication" do
    test "new/2 derives the expected hash, salt, key and counter" do
      header = "WA"
      state = Handshake.new(@pattern, header)

      assert state.salt == @pattern
      assert state.key == @pattern
      assert state.hash == :crypto.hash(:sha256, @pattern <> header)
      assert state.counter == 0
    end

    test "non-32-byte patterns are hashed before the header is authenticated" do
      pattern = "short pattern"
      initial = :crypto.hash(:sha256, pattern)
      state = Handshake.new(pattern, "header")

      assert state.salt == initial
      assert state.key == initial
      assert state.hash == :crypto.hash(:sha256, initial <> "header")
    end

    test "authenticate/2 chains the hash and preserves key schedule state" do
      state = Handshake.new(@pattern, "header")
      updated = Handshake.authenticate(state, "ephemeral")

      assert updated.hash == :crypto.hash(:sha256, state.hash <> "ephemeral")
      assert updated.salt == state.salt
      assert updated.key == state.key
      assert updated.counter == state.counter
    end
  end

  describe "handshake encryption" do
    test "mirrored encrypt/decrypt states stay synchronized" do
      initial = Handshake.new(@pattern, "header") |> Handshake.mix_into_key("shared secret")
      {encrypted_state, ciphertext} = Handshake.encrypt(initial, "hello noise")

      assert {:ok, decrypted_state, "hello noise"} = Handshake.decrypt(initial, ciphertext)
      assert encrypted_state == decrypted_state
      assert encrypted_state.counter == 1
    end

    test "multiple messages advance counters and hashes in lockstep" do
      initial = Handshake.new(@pattern, "header") |> Handshake.mix_into_key("shared secret")
      messages = [<<>>, "one", :binary.copy(<<0xA5>>, 4_096)]

      {send_state, receive_state} =
        Enum.reduce(messages, {initial, initial}, fn message, {sender, receiver} ->
          {next_sender, ciphertext} = Handshake.encrypt(sender, message)
          assert {:ok, next_receiver, ^message} = Handshake.decrypt(receiver, ciphertext)
          assert next_sender == next_receiver
          {next_sender, next_receiver}
        end)

      assert send_state == receive_state
      assert send_state.counter == length(messages)
    end

    test "rejects short and tampered ciphertext without advancing caller state" do
      initial = Handshake.new(@pattern, "header") |> Handshake.mix_into_key("shared secret")
      {_next_state, ciphertext} = Handshake.encrypt(initial, "authenticated")
      prefix_size = byte_size(ciphertext) - 1
      <<prefix::binary-size(^prefix_size), last>> = ciphertext
      tampered = prefix <> <<Bitwise.bxor(last, 1)>>

      assert {:error, :ciphertext_too_short} = Handshake.decrypt(initial, <<0, 1, 2>>)
      assert {:error, :decrypt_failed} = Handshake.decrypt(initial, tampered)
      assert initial.counter == 0
    end
  end

  describe "key schedule" do
    test "mix_into_key/2 matches HKDF and resets the counter" do
      state = %{Handshake.new(@pattern, "header") | counter: 9}
      secret = :binary.copy(<<0x42>>, 32)
      expected = hkdf(state.salt, secret)
      <<expected_salt::binary-size(32), expected_key::binary-size(32)>> = expected

      mixed = Handshake.mix_into_key(state, secret)

      assert mixed.salt == expected_salt
      assert mixed.key == expected_key
      assert mixed.hash == state.hash
      assert mixed.counter == 0
    end

    test "both sides derive the same state from an X25519 shared secret" do
      alice = Keys.generate_key_pair()
      bob = Keys.generate_key_pair()
      alice_state = Handshake.new(@pattern, "header")
      bob_state = Handshake.new(@pattern, "header")

      assert {:ok, mixed_alice} =
               Handshake.mix_shared_secret(alice_state, alice.private, bob.public)

      assert {:ok, mixed_bob} =
               Handshake.mix_shared_secret(bob_state, bob.private, alice.public)

      assert mixed_alice.salt == mixed_bob.salt
      assert mixed_alice.key == mixed_bob.key
      assert mixed_alice.counter == 0
    end

    test "derive_transport_keys/1 is deterministic and matches the HKDF split" do
      state = Handshake.new(@pattern, "header") |> Handshake.mix_into_key("shared secret")
      <<expected_write::binary-size(32), expected_read::binary-size(32)>> =
        hkdf(state.salt, <<>>)

      assert {expected_write, expected_read} == Handshake.derive_transport_keys(state)
      assert byte_size(expected_write) == 32
      assert byte_size(expected_read) == 32
      refute expected_write == expected_read
    end
  end

  defp hkdf(salt, key_material) do
    prk = :crypto.mac(:hmac, :sha256, salt, key_material)
    t1 = :crypto.mac(:hmac, :sha256, prk, <<1>>)
    t2 = :crypto.mac(:hmac, :sha256, prk, t1 <> <<2>>)
    t1 <> t2
  end
end
