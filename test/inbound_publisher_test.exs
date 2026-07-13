defmodule ExWapp.Message.Handler.Inbound.PublisherTest do
  use ExUnit.Case, async: true

  alias ExWapp.Message.Handler.Inbound.Publisher
  alias ExWapp.Store.Memory

  test "persists and publishes a normalized user message" do
    store = Memory.new()
    on_exit(fn -> Memory.stop(store) end)

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
               %{text: "hello", message_content_type: :user_message},
               envelope,
               self(),
               %{store: store}
             )

    assert message.text == "hello"
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
               %{text: nil, message_content_type: :protocol},
               envelope,
               self(),
               %{}
             )

    assert message.id == "message-2"
    refute_received {:new_message, _, _}
  end
end
