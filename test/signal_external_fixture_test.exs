defmodule ExWapp.SignalExternalFixtureTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Bitwise

  alias ExWapp.Signal.{SenderKey, Session, WireFormat}
  alias ExWapp.Store.Memory

  @fixture_dir Path.expand("fixtures/protocol", __DIR__)
  @session_vector @fixture_dir
                  |> Path.join("signal_session_vector.fixture")
                  |> Code.eval_file()
                  |> elem(0)
  @sender_key_vector @fixture_dir
                     |> Path.join("sender_key_vector.fixture")
                     |> Code.eval_file()
                     |> elem(0)
  @wire_vectors @fixture_dir
                |> Path.join("signal_wire_vectors.fixture")
                |> Code.eval_file()
                |> elem(0)

  test "decrypts two Node/libsignal PreKeyWhisperMessages on one session" do
    responder = @session_vector.responder
    [first, second] = @session_vector.messages

    local_identity = %{
      public: responder.identity_pub |> hex!() |> strip_key_prefix(),
      private: hex!(responder.identity_priv)
    }

    signed_prekey = %{
      id: responder.signed_prekey_id,
      public: responder.signed_pub |> hex!() |> strip_key_prefix(),
      private: hex!(responder.signed_priv)
    }

    one_time_prekey = %{
      id: responder.prekey_id,
      public: responder.pre_pub |> hex!() |> strip_key_prefix(),
      private: hex!(responder.pre_priv)
    }

    local_prekeys = %{
      signed_prekeys: %{signed_prekey.id => signed_prekey},
      prekeys: %{one_time_prekey.id => one_time_prekey}
    }

    assert first.type == 3

    assert {:ok, first_plaintext, session} =
             Session.decrypt_prekey_message(hex!(first.body), local_identity, local_prekeys)

    assert first_plaintext == hex!(first.plaintext)

    assert {:ok, second_plaintext, _session} =
             Session.decrypt_prekey_message_with_session(session, hex!(second.body))

    assert second_plaintext == hex!(second.plaintext)
  end

  test "processes an external sender-key distribution and decrypts both skmsg values" do
    fixture = @sender_key_vector
    store = Memory.new(initial_data: %{signal: %{}})
    sender_jid = "#{fixture.sender_id}@s.whatsapp.net"
    distribution = Base.decode64!(fixture.distribution)

    sender_key_distribution =
      encode_bytes_field(1, fixture.group_id) <> encode_bytes_field(2, distribution)

    plaintext = encode_bytes_field(2, sender_key_distribution)

    assert {:ok, 1} =
             SenderKey.process_distributions_from_plaintext(
               store,
               fixture.group_id,
               sender_jid,
               plaintext
             )

    for message <- fixture.messages do
      assert {:ok, message.plaintext} ==
               SenderKey.decrypt_group_message(
                 store,
                 fixture.group_id,
                 sender_jid,
                 Base.decode64!(message.ciphertext)
               )
    end
  end

  test "parses Node/libsignal Whisper and PreKey protobuf layouts while enforcing DJB keys" do
    whisper = @wire_vectors.whisper
    raw_whisper = hex!(whisper.encoded)

    # The upstream codec-only fixture deliberately used a non-DJB type byte.
    # Keep that as a negative assertion, then normalize only the type byte to
    # exercise the exact external protobuf layout through our stricter parser.
    assert {:error, :invalid_key_format} =
             WireFormat.parse_signal_message(<<0x33>> <> raw_whisper <> :binary.copy(<<0>>, 8))

    <<0x0A, 0x21, _type, ratchet_key::binary-size(32), whisper_rest::binary>> = raw_whisper

    versioned_whisper =
      <<0x33, 0x0A, 0x21, 0x05, ratchet_key::binary, whisper_rest::binary>> <>
        :binary.copy(<<0>>, 8)

    assert {:ok, parsed_whisper} = WireFormat.parse_signal_message(versioned_whisper)
    assert parsed_whisper.ratchet_key == ratchet_key
    assert parsed_whisper.counter == whisper.counter
    assert parsed_whisper.previous_counter == whisper.previous_counter
    assert parsed_whisper.ciphertext == hex!(whisper.ciphertext)

    prekey = @wire_vectors.prekey
    raw_prekey = hex!(prekey.encoded)

    assert {:error, :invalid_key_format} =
             WireFormat.parse_prekey_signal_message(<<0x33>> <> raw_prekey)

    <<registration_field::binary-size(3), 0x12, 0x21, _base_type, base_key::binary-size(32), 0x1A,
      0x21, _identity_type, identity_key::binary-size(32), prekey_rest::binary>> = raw_prekey

    normalized_prekey =
      registration_field <>
        <<0x12, 0x21, 0x05, base_key::binary, 0x1A, 0x21, 0x05, identity_key::binary,
          prekey_rest::binary>>

    assert {:ok, parsed_prekey} =
             WireFormat.parse_prekey_signal_message(<<0x33>> <> normalized_prekey)

    assert parsed_prekey.prekey_id == prekey.prekey_id
    assert parsed_prekey.registration_id == prekey.registration_id
    assert parsed_prekey.signed_prekey_id == prekey.signed_prekey_id
    assert parsed_prekey.base_key == base_key
    assert parsed_prekey.identity_key == identity_key
  end

  defp hex!(value), do: Base.decode16!(value, case: :lower)
  defp strip_key_prefix(<<5, key::binary-size(32)>>), do: key
  defp strip_key_prefix(key) when byte_size(key) == 32, do: key

  defp encode_bytes_field(field_number, value) do
    tag = bor(field_number <<< 3, 2)
    WireFormat.encode_varint(tag) <> WireFormat.encode_varint(byte_size(value)) <> value
  end
end
