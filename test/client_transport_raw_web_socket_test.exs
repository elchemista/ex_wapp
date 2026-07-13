defmodule ExWapp.Client.Transport.RawWebSocketTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Client, Message}
  alias ExWapp.Client.Transport.RawWebSocket

  test "rejects high-level messages before they can bypass the session pipeline" do
    client = %Client{metadata: %{}}
    message = Message.text("15550001111@s.whatsapp.net", "hello", id: "message-1")

    assert {:error, :raw_websocket_cannot_send_high_level_messages} =
             RawWebSocket.send_message(client, message)
  end
end
