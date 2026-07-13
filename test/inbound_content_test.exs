defmodule ExWapp.Message.Handler.Inbound.ContentTest do
  use ExUnit.Case, async: true

  alias ExWapp.Message.Handler.Inbound.Content
  alias ExWapp.Messages
  alias ExWapp.Proto.Message
  alias ExWapp.Signal.SessionStore

  test "decodes decrypted text while preserving envelope fields" do
    {:ok, plaintext} =
      "hello from inbound"
      |> Messages.build_text_proto()
      |> Message.encode()

    message_data = %{
      encrypted: true,
      enc_type: "msg",
      id: "message-1",
      signal_sessions_update: SessionStore.new()
    }

    decoded =
      Content.decode_decrypted(%{
        message_data: message_data,
        plaintext: plaintext,
        updated_sessions: SessionStore.new(),
        sender_jid: "15550001111@s.whatsapp.net",
        payload: %{enc_type: "msg"},
        sender_key_distribution_count: 0,
        enc_type: "msg"
      })

    assert decoded.id == "message-1"
    assert decoded.text == "hello from inbound"
    assert decoded.decrypt_status == :ok
    assert decoded.message_content_type == :user_message
    refute decoded.from_me
  end

  test "keeps sender-key distribution plaintext as protocol content" do
    {:ok, plaintext} =
      "distribution"
      |> Messages.build_text_proto()
      |> Message.encode()

    decoded =
      Content.decode_decrypted(%{
        message_data: %{encrypted: true, enc_type: "skmsg"},
        plaintext: plaintext,
        updated_sessions: SessionStore.new(),
        sender_jid: "15550001111@s.whatsapp.net",
        payload: %{enc_type: "skmsg"},
        sender_key_distribution_count: 1,
        enc_type: "skmsg"
      })

    assert decoded.text == "(encrypted: skmsg)"
    assert decoded.decrypt_status == :ok
    assert decoded.message_content_type == :protocol
    assert decoded.protocol_payload == plaintext
    refute decoded.from_me
  end
end
