defmodule ExWapp.MessageTableRecoveryTest do
  use ExUnit.Case, async: true
  alias ExWapp.Store.MessageTable

  test "legacy and current snapshots merge histories while stripping embedded messages" do
    legacy =
      Map.put(%ExWapp.Chat{jid: "chat", name: "Alice"}, :messages, [%{id: "old", timestamp: 1}])

    data = %{
      chats: %{"chat" => legacy, "unknown" => :old_metadata},
      chat_messages: %{"chat" => [%{id: "new", timestamp: 2}], nil => :invalid}
    }

    assert {metadata, messages} = MessageTable.extract(data)
    assert metadata.chats["chat"] == %ExWapp.Chat{jid: "chat", name: "Alice"}
    refute Map.has_key?(metadata, :chat_messages)
    refute Map.has_key?(metadata.chats["chat"], :messages)
    table = MessageTable.new(messages, max_per_chat: nil)
    assert Enum.map(MessageTable.list(table, "chat"), & &1.id) == ["new", "old"]
    assert MessageTable.snapshot(MessageTable.new(:invalid_old_messages)) == %{}
  end

  test "invalid mutation inputs leave existing history and indexes intact" do
    table = MessageTable.new(%{"chat" => [%{id: "saved", timestamp: 1}]})
    before = MessageTable.snapshot(table)
    assert :ok = MessageTable.upsert(table, nil, :invalid)
    assert 0 = MessageTable.upsert_count(table, "chat", nil)
    assert 0 = MessageTable.upsert_count(table, "chat", [%{}, %{id: nil}, %{id: 2}])
    assert nil == MessageTable.find(table, "chat", nil)
    assert nil == MessageTable.find_by_id(table, nil)
    assert :ok = MessageTable.update_status_by_id(table, nil, :read)
    assert 0 = MessageTable.update_status_by_id_count(table, nil, :read)
    assert :ok = MessageTable.delete(table, "chat", nil)
    assert 0 = MessageTable.delete_count(table, nil, [])
    assert :ok = MessageTable.delete_chat(table, nil)
    assert 0 = MessageTable.delete_chat_count(table, nil)
    assert MessageTable.snapshot(table) == before
    assert {"chat", %{id: "saved"}} = MessageTable.find_by_id(table, "saved")
  end

  test "timestamps outside the wire range remain ordered without crossing chat boundaries" do
    table =
      MessageTable.new(%{
        "a" => [%{id: "low", timestamp: -1}, %{id: "high", timestamp: Bitwise.bsl(1, 80)}],
        "b" => [%{id: "other", timestamp: 2}]
      })

    assert Enum.map(MessageTable.list(table, "a", offset: :invalid, limit: :invalid), & &1.id) ==
             ["high", "low"]

    assert Enum.map(MessageTable.list(table, "a", order: :oldest_first), & &1.id) == [
             "low",
             "high"
           ]

    assert MessageTable.list(table, "absent") == []
    assert MessageTable.list(table, "a", offset: 20) == []
  end

  test "a history stream terminates cleanly if its owning store closes mid-enumeration" do
    owner = self()

    task =
      Task.async(fn ->
        table =
          MessageTable.new(%{"chat" => Enum.map(1..5, &%{id: to_string(&1), timestamp: &1})})

        send(owner, {:table, table})

        receive do
          :close -> :ok
        end
      end)

    assert_receive {:table, table}

    values =
      table
      |> MessageTable.stream("chat", limit: :all)
      |> Enum.map(fn value ->
        send(task.pid, :close)
        Task.await(task)
        value
      end)

    assert [%{id: "5"}] = values
  end
end
