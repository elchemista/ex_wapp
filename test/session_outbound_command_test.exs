defmodule ExWapp.Session.Outbound.CommandTest do
  use ExUnit.Case, async: true

  alias ExWapp.Message
  alias ExWapp.Session
  alias ExWapp.Session.Outbound.Command

  defmodule SessionStub do
    use GenServer

    def start_link(owner), do: GenServer.start_link(__MODULE__, owner)

    @impl true
    def init(owner), do: {:ok, owner}

    @impl true
    def handle_call({:send_message, message}, _from, owner) do
      send(owner, {:canonical_message, message})
      {:reply, {:ok, message.id || "generated-id"}, owner}
    end
  end

  test "session message helpers all emit the canonical message command" do
    session = start_supervised!({SessionStub, self()})
    jid = "15550001111@s.whatsapp.net"

    assert {:ok, "text-id"} =
             Session.send_text(session, jid, "hello", retry_message_id: "text-id")

    assert_receive {:canonical_message,
                    %Message{id: "text-id", to: ^jid, type: :text, body: "hello"}}

    assert {:ok, "image-id"} = Session.send_image(session, jid, {:bytes, "image"}, id: "image-id")
    assert_receive {:canonical_message, %Message{id: "image-id", type: :image}}

    assert {:ok, "audio-id"} = Session.send_audio(session, jid, {:bytes, "audio"}, id: "audio-id")
    assert_receive {:canonical_message, %Message{id: "audio-id", type: :audio}}

    assert {:ok, "document-id"} =
             Session.send_document(session, jid, {:bytes, "document"}, id: "document-id")

    assert_receive {:canonical_message, %Message{id: "document-id", type: :document}}

    assert {:ok, "location-id"} =
             Session.send_location(session, jid, 45.46, 9.19, id: "location-id")

    assert_receive {:canonical_message,
                    %Message{
                      id: "location-id",
                      type: :location,
                      body: %{latitude: 45.46, longitude: 9.19}
                    }}

    vcard = "BEGIN:VCARD\nFN:Alice\nEND:VCARD"

    assert {:ok, "contact-id"} =
             Session.send_contact(session, jid, "Alice", vcard, id: "contact-id")

    assert_receive {:canonical_message,
                    %Message{
                      id: "contact-id",
                      type: :contact,
                      body: %{display_name: "Alice", vcard: ^vcard}
                    }}

    assert {:ok, "event-id"} =
             Session.send_event(session, jid, "Meeting", 1_700_000_000, id: "event-id")

    assert_receive {:canonical_message,
                    %Message{
                      id: "event-id",
                      type: :event,
                      body: %{name: "Meeting", start_time: 1_700_000_000}
                    }}
  end

  test "command validation makes the struct ID authoritative" do
    message = %Message{
      id: "canonical-id",
      to: "15550001111@s.whatsapp.net",
      type: :text,
      body: "hello",
      opts: [retry_message_id: "stale-id"]
    }

    assert {:ok, prepared} = Command.prepare(message)
    assert prepared.id == "canonical-id"
    assert prepared.opts[:retry_message_id] == "canonical-id"
  end

  test "command validation rejects malformed and unsupported messages" do
    valid = Message.text("15550001111@s.whatsapp.net", "hello")

    assert {:error, :invalid_recipient} = Command.prepare(%{valid | to: ""})
    assert {:error, :invalid_message_id} = Command.prepare(%{valid | id: ""})
    assert {:error, :invalid_send_options} = Command.prepare(%{valid | opts: %{}})

    assert {:error, {:unsupported_message_type, :typing}} =
             Command.prepare(Message.typing(valid.to))
  end
end
