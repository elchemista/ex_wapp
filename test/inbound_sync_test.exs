defmodule ExWapp.Message.Handler.Inbound.SyncTest do
  use ExUnit.Case, async: true

  alias ExWapp.Message.Handler.Inbound.Sync

  test "leaves ordinary user messages outside the sync pipeline" do
    state = %{marker: :unchanged}

    assert Sync.ingest(
             %{message_content_type: :user_message, text: "hello"},
             nil,
             state,
             "15550001111@s.whatsapp.net",
             "message-1"
           ) == state
  end

  test "keeps state unchanged for an unsupported protocol payload" do
    state = %{marker: :unchanged}

    assert Sync.ingest(
             %{message_content_type: :protocol, protocol_payload: <<0>>},
             nil,
             state,
             "15550001111@s.whatsapp.net",
             "message-2"
           ) == state
  end
end
