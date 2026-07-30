defmodule ExWapp.Message.Handler.Inbound.ContentTest do
  use ExUnit.Case, async: true

  alias ExWapp.Media.Upload
  alias ExWapp.Message.Handler.Inbound.Content
  alias ExWapp.Messages
  alias WAWebProtobufsE2E.Message
  alias ExWapp.Signal.SessionStore

  test "decodes decrypted text while preserving envelope fields" do
    plaintext =
      "hello from inbound"
      |> Messages.build_text_proto()
      |> Message.encode!()
      |> IO.iodata_to_binary()

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
    assert decoded.content.kind == :text
    assert decoded.content.text == "hello from inbound"
    refute decoded.from_me
  end

  test "marks own-device fanout wrapped in DeviceSentMessage as from_me" do
    inner = Messages.build_text_proto("sent from my phone")

    plaintext =
      %Message{
        deviceSentMessage: %WAWebProtobufsE2E.DeviceSentMessage{
          destinationJID: "15550002222@s.whatsapp.net",
          message: inner
        }
      }
      |> Message.encode!()
      |> IO.iodata_to_binary()

    decoded =
      Content.decode_decrypted(%{
        message_data: %{encrypted: true, enc_type: "msg", id: "own-fanout-1"},
        plaintext: plaintext,
        updated_sessions: SessionStore.new(),
        sender_jid: "15550001111@s.whatsapp.net",
        payload: %{enc_type: "msg"},
        sender_key_distribution_count: 0,
        enc_type: "msg"
      })

    assert decoded.from_me
    assert decoded.message_content_type == :user_message
    assert decoded.text == "sent from my phone"
  end

  test "keeps sender-key distribution plaintext as protocol content" do
    plaintext =
      "distribution"
      |> Messages.build_text_proto()
      |> Message.encode!()
      |> IO.iodata_to_binary()

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
    assert decoded.content.kind == :protocol
    assert decoded.content.protocol_payload == plaintext
    refute decoded.from_me
  end

  test "normalizes every supported decoded format to the canonical contract" do
    upload = %Upload{
      type: :image,
      url: "https://media.example/file",
      direct_path: "/v/t62/file",
      media_key: <<1::256>>,
      file_sha256: <<2::256>>,
      file_enc_sha256: <<3::256>>,
      file_length: 42,
      media_key_timestamp: 1_700_000_000
    }

    cases = [
      {Messages.build_image_proto(upload, caption: "photo"), :media, :image},
      {Messages.build_audio_proto(upload, ptt: true, seconds: 2), :media, :audio},
      {Messages.build_document_proto(upload, file_name: "file.pdf"), :media, :document},
      {Messages.build_location_proto(45.4642, 9.19, name: "Milano"), :location, nil},
      {Messages.build_contact_proto("Alice", "BEGIN:VCARD\\nFN:Alice\\nEND:VCARD"), :contact,
       nil},
      {Messages.build_event_proto("Planning", 1_700_000_000), :event, nil}
    ]

    Enum.each(cases, fn {proto, expected_kind, expected_media_type} ->
      plaintext = IO.iodata_to_binary(Message.encode!(proto))

      decoded =
        Content.decode_decrypted(%{
          message_data: %{encrypted: true, enc_type: "msg"},
          plaintext: plaintext,
          updated_sessions: SessionStore.new(),
          sender_jid: "15550001111@s.whatsapp.net",
          payload: %{enc_type: "msg"},
          sender_key_distribution_count: 0,
          enc_type: "msg"
        })

      assert decoded.content.kind == expected_kind

      if expected_media_type do
        assert decoded.content.media_type == expected_media_type
        assert decoded.media.type == expected_media_type
      end
    end)
  end
end
