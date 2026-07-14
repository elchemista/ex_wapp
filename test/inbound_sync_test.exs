defmodule ExWapp.Message.Handler.Inbound.SyncTest do
  use ExUnit.Case, async: true

  alias ExWapp.Message.Handler.Inbound.Sync
  alias ExWapp.Store
  alias ExWapp.Store.Memory

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

  test "rejects an app-state key share from a non-local sender" do
    store = Memory.new()
    state = %{store: store}
    key_id = <<1, 2, 3, 4>>
    key_data = :binary.copy(<<7>>, 32)
    message_data = app_state_key_share_message(key_id, key_data)

    assert Sync.ingest(
             message_data,
             nil,
             state,
             "15550001111@s.whatsapp.net",
             "spoofed-key-share",
             false
           ) == state

    assert Store.get(store, :app_state_keys, %{}) == %{}
  end

  test "accepts an app-state key share from a verified local sender" do
    store = Memory.new()
    state = %{store: store}
    key_id = <<1, 2, 3, 4>>
    key_data = :binary.copy(<<7>>, 32)
    message_data = app_state_key_share_message(key_id, key_data)

    assert Sync.ingest(
             message_data,
             nil,
             state,
             "15550009999@s.whatsapp.net",
             "trusted-key-share",
             true
           ) == state

    key_id_hex = Base.encode16(key_id, case: :lower)

    assert %{^key_id_hex => %{data: ^key_data}} =
             Store.get(store, :app_state_keys, %{})
  end

  defp app_state_key_share_message(key_id, key_data) do
    key_id_message = length_delimited(1, key_id)
    key_data_message = length_delimited(1, key_data)

    app_state_key =
      length_delimited(1, key_id_message) <>
        length_delimited(2, key_data_message)

    key_share = length_delimited(1, app_state_key)
    protocol_message = length_delimited(7, key_share)

    %{
      message_content_type: :protocol,
      protocol_payload: length_delimited(12, protocol_message)
    }
  end

  defp length_delimited(field_number, value)
       when is_integer(field_number) and field_number > 0 and is_binary(value) and
              byte_size(value) < 128 do
    <<field_number * 8 + 2, byte_size(value), value::binary>>
  end
end
