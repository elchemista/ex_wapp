defmodule ExWapp.MessageWindowTest do
  @moduledoc """
  Coverage for bounding how much history a chat keeps.

  The built-in file adapter re-encodes its entire snapshot on every write, and
  message upserts go through that same path, so an unbounded history makes each
  arriving message cost more than the one before it. A host that does not read
  old messages back can cap the window; one that does keeps the default and pays
  for what it asked for.

  The cap is not free to get wrong. Three things the library itself does read
  back — the payload to resend after a rejection, the record that marks a
  redelivery as already seen, and the message a media retry refers to — all come
  out of this table.
  """

  use ExUnit.Case, async: true

  alias ExWapp.Store
  alias ExWapp.Store.Ets, as: FileStore
  alias ExWapp.Store.MessageTable

  @jid "15550007777@s.whatsapp.net"
  @other "15550008888@s.whatsapp.net"

  describe "bounded history" do
    test "keeps the newest messages and drops the oldest" do
      table = MessageTable.new(%{}, max_per_chat: 3)

      MessageTable.upsert(table, @jid, messages(1..5))

      assert ids(table, @jid) == ["msg-5", "msg-4", "msg-3"]
    end

    test "trims a batch that arrives all at once" do
      table = MessageTable.new(%{}, max_per_chat: 2)

      MessageTable.upsert(table, @jid, messages(1..50))

      assert ids(table, @jid) == ["msg-50", "msg-49"]
    end

    test "bounds each chat on its own" do
      table = MessageTable.new(%{}, max_per_chat: 2)

      MessageTable.upsert(table, @jid, messages(1..4))
      MessageTable.upsert(table, @other, messages(1..4))

      assert ids(table, @jid) == ["msg-4", "msg-3"]
      assert ids(table, @other) == ["msg-4", "msg-3"]
    end

    test "updating a message in place does not consume window" do
      # Status updates arrive as upserts of a message already stored. Counting
      # them as new arrivals would evict live history on a chat that is not
      # actually growing.
      table = MessageTable.new(%{}, max_per_chat: 3)

      MessageTable.upsert(table, @jid, messages(1..3))

      Enum.each(1..10, fn _attempt ->
        MessageTable.upsert(table, @jid, [message(2, status: :read)])
      end)

      assert ids(table, @jid) == ["msg-3", "msg-2", "msg-1"]
      assert %{status: :read} = MessageTable.find(table, @jid, "msg-2")
    end

    test "an evicted message is gone from the id index too" do
      # A stale index entry would point the by-id lookups at a deleted row.
      table = MessageTable.new(%{}, max_per_chat: 1)

      MessageTable.upsert(table, @jid, messages(1..2))

      assert MessageTable.find(table, @jid, "msg-1") == nil
      assert MessageTable.find_by_id(table, "msg-1") == nil
      assert %{id: "msg-2"} = MessageTable.find(table, @jid, "msg-2")
    end

    test "deleting messages frees window rather than leaking it" do
      # If deletes did not give the space back, a chat would shrink towards zero
      # retained history over its lifetime.
      table = MessageTable.new(%{}, max_per_chat: 3)

      MessageTable.upsert(table, @jid, messages(1..3))
      MessageTable.delete(table, @jid, ["msg-1", "msg-2"])
      MessageTable.upsert(table, @jid, messages(4..5))

      assert ids(table, @jid) == ["msg-5", "msg-4", "msg-3"]
    end

    test "restored history is trimmed on the way in" do
      # A session file written before the cap was configured still has to come
      # back within it, or the first flush writes the whole old history again.
      table = MessageTable.new(%{@jid => messages(1..100)}, max_per_chat: 5)

      assert ids(table, @jid) == ["msg-100", "msg-99", "msg-98", "msg-97", "msg-96"]
    end

    test "history is unbounded unless the host asks for a bound" do
      table = MessageTable.new()

      MessageTable.upsert(table, @jid, messages(1..2_000))

      assert table |> MessageTable.stream(@jid) |> Enum.count() == 2_000
    end
  end

  describe "the adapter option" do
    test "the file store passes the bound through" do
      path =
        Path.join(
          System.tmp_dir!(),
          "ex_wapp_window_#{System.unique_integer([:positive])}.etf"
        )

      store = FileStore.new(path: path, max_messages_per_chat: 4)
      on_exit(fn -> File.rm(path) end)

      :ok = Store.upsert_messages(store, @jid, messages(1..10))

      assert store |> Store.stream_messages(@jid, []) |> Enum.map(& &1.id) ==
               ["msg-10", "msg-9", "msg-8", "msg-7"]
    end

    test "a nonsense bound falls back to unbounded instead of dropping everything" do
      table = MessageTable.new(%{}, max_per_chat: 0)

      MessageTable.upsert(table, @jid, messages(1..5))

      assert length(ids(table, @jid)) == 5
    end
  end

  defp messages(range), do: Enum.map(range, &message/1)

  defp message(number, overrides \\ []) do
    Enum.into(overrides, %{
      id: "msg-#{number}",
      timestamp: number,
      from_me: false,
      status: :received,
      text: "message #{number}"
    })
  end

  defp ids(table, jid) do
    table
    |> MessageTable.stream(jid)
    |> Enum.map(& &1.id)
  end
end
