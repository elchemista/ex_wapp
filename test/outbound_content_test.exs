defmodule ExWapp.Session.Outbound.ContentTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Media, Message}
  alias ExWapp.Session.Outbound.Content

  test "prepares location, contact, and event payloads with explicit wire metadata" do
    jid = "15550001111@s.whatsapp.net"

    location = Message.location(jid, 45.46, 9.19, name: "Milan")
    assert {:ok, _proto, location_opts} = Content.prepare(self(), %{}, location)
    assert location_opts[:message_node_type] == "text"
    assert location_opts[:chat_text] == "Milan"
    assert location_opts[:outgoing_raw].content_type == :location

    contact = Message.contact(jid, "Alice", "BEGIN:VCARD\nFN:Alice\nEND:VCARD")
    assert {:ok, _proto, contact_opts} = Content.prepare(self(), %{}, contact)
    assert contact_opts[:message_node_type] == "media"
    assert contact_opts[:mediatype] == "vcard"
    assert contact_opts[:outgoing_raw].contact == contact.body

    event = Message.event(jid, "Meeting", 1_700_000_000, description: "Planning")
    assert {:ok, _proto, event_opts} = Content.prepare(self(), %{}, event)
    assert event_opts[:message_node_type] == "event"
    assert event_opts[:outgoing_raw].event.name == "Meeting"

    assert [%ExWapp.Binary.Node{tag: "meta", attrs: %{"event_type" => "creation"}}] =
             event_opts[:additional_message_nodes]
  end

  test "rejects invalid structured content before the Signal send pipeline" do
    jid = "15550001111@s.whatsapp.net"

    invalid_location = %Message{to: jid, type: :location, body: %{latitude: 91, longitude: 9}}
    invalid_contact = %Message{to: jid, type: :contact, body: %{display_name: "", vcard: ""}}
    invalid_event = %Message{to: jid, type: :event, body: %{name: "", start_time: nil}}

    assert {:error, :invalid_location} = Content.prepare(self(), %{}, invalid_location)
    assert {:error, :invalid_contact} = Content.prepare(self(), %{}, invalid_contact)
    assert {:error, :invalid_event} = Content.prepare(self(), %{}, invalid_event)
  end

  test "accepts matching uploads and rejects media type mismatches" do
    jid = "15550001111@s.whatsapp.net"
    upload = upload(:image)

    assert {:ok, _proto, send_opts} =
             Content.prepare(self(), %{}, Message.image(jid, upload, caption: "hello"))

    assert send_opts[:mediatype] == "image"
    assert send_opts[:chat_text] == "hello"
    assert send_opts[:outgoing_raw].media.type == :image

    assert {:error, {:media_type_mismatch, :audio, :image}} =
             Content.prepare(self(), %{}, Message.audio(jid, upload))
  end

  defp upload(type) do
    %Media.Upload{
      type: type,
      url: "https://example.test/media",
      direct_path: "/mms/#{type}/abc",
      media_key: :binary.copy(<<1>>, 32),
      file_sha256: :binary.copy(<<2>>, 32),
      file_enc_sha256: :binary.copy(<<3>>, 32),
      file_length: 123
    }
  end
end
