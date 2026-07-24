defmodule ExWapp.Message.Handler.Inbound.PublisherTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Chat, Message.Content}
  alias ExWapp.Message.Handler.Inbound.Publisher
  alias ExWapp.Store.Memory

  test "persists and publishes a normalized user message" do
    store = Memory.new()

    envelope = %{
      id: "message-1",
      from: "15550001111@s.whatsapp.net",
      from_me: false,
      timestamp: 123,
      participant: nil,
      type: "text",
      attrs: %{"notify" => "Alice"}
    }

    assert {:published, message} =
             Publisher.publish(
               %{
                 content: Content.new(:text, text: "hello"),
                 text: "hello",
                 message_content_type: :user_message
               },
               envelope,
               self(),
               %{store: store}
             )

    assert message.text == "hello"
    assert message.content.kind == :text
    assert message.status == :received
    assert message.raw.from_me == false

    assert_receive {:new_message, "15550001111@s.whatsapp.net", ^message}
  end

  test "does not publish protocol payloads as chat messages" do
    envelope = %{
      id: "message-2",
      from: "15550001111@s.whatsapp.net",
      from_me: false,
      timestamp: 123,
      participant: nil,
      type: "text",
      attrs: %{}
    }

    assert {:suppressed, message} =
             Publisher.publish(
               %{
                 content: Content.new(:protocol, protocol_payload: <<1>>),
                 text: nil,
                 message_content_type: :protocol
               },
               envelope,
               self(),
               %{}
             )

    assert message.id == "message-2"
    refute_received {:new_message, _, _}
  end

  test "publishes and stores device-addressed inbound messages under one canonical chat" do
    store = Memory.new()

    envelope = %{
      id: "message-from-linked-device",
      from: "70000001111:32@lid",
      from_me: false,
      timestamp: 456,
      participant: "70000001111:32@lid",
      type: "text",
      attrs: %{}
    }

    assert {:published, message} =
             Publisher.publish(
               %{
                 content: Content.new(:text, text: "from linked device"),
                 text: "from linked device",
                 message_content_type: :user_message
               },
               envelope,
               self(),
               %{store: store}
             )

    assert_receive {:new_message, "70000001111@lid", ^message}
    assert [%{id: "message-from-linked-device"}] = Chat.messages(store, "70000001111@lid")
    assert [%Chat{jid: "70000001111@lid"}] = Chat.list(store)
  end
end
