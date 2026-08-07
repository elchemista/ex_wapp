defmodule ExWapp.CallLogTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Call, Store}
  alias WAWebProtobufSyncAction.CallLogRecord

  @peer "15550002222@s.whatsapp.net"
  @group "120363999999999999@g.us"

  defp new_store, do: Store.new(Store.Memory)

  defp call(attrs) do
    struct(
      Call,
      Keyword.merge([id: "CALL-#{System.unique_integer([:positive])}", source: :live], attrs)
    )
  end

  describe "upsert/3 and get/2" do
    test "stores and fetches one record by call id" do
      store = new_store()

      {:ok, stored} =
        Call.upsert(store, call(id: "CALL1", chat_jid: @peer, status: :ringing, start_time: 100))

      assert stored.status == :ringing
      assert {:ok, %Call{id: "CALL1", chat_jid: @peer}} = Call.get(store, "CALL1")
      assert Call.count(store) == 1
    end

    test "rejects records without a call id" do
      assert {:error, :invalid_call} = Call.upsert(new_store(), %Call{id: nil})
      assert {:error, :invalid_call} = Call.upsert(new_store(), %Call{id: ""})
    end

    test "merges by field, keeping known values when the update has none" do
      store = new_store()

      {:ok, _ringing} =
        Call.upsert(
          store,
          call(id: "CALL1", chat_jid: @peer, status: :ringing, start_time: 100, is_video: true)
        )

      {:ok, merged} = Call.upsert(store, call(id: "CALL1", status: :missed, ended_at: 130))

      assert merged.status == :missed
      assert merged.chat_jid == @peer
      assert merged.start_time == 100
      assert merged.is_video == true
      assert merged.ended_at == 130
    end

    test "a transient status never downgrades a final outcome" do
      store = new_store()
      {:ok, _missed} = Call.upsert(store, call(id: "CALL1", status: :missed, ended_at: 130))
      {:ok, merged} = Call.upsert(store, call(id: "CALL1", status: :ringing))

      assert merged.status == :missed
    end

    test "derives duration from accept and terminate timestamps" do
      store = new_store()
      {:ok, _ongoing} = Call.upsert(store, call(id: "CALL1", status: :ongoing, accepted_at: 110))
      {:ok, merged} = Call.upsert(store, call(id: "CALL1", status: :connected, ended_at: 173))

      assert merged.duration == 63
    end

    test "prunes oldest records beyond max_records" do
      store = new_store()

      for index <- 1..5 do
        {:ok, _stored} =
          Call.upsert(
            store,
            call(id: "CALL#{index}", chat_jid: @peer, start_time: index),
            max_records: 3
          )
      end

      ids = store |> Call.list(order: :newest_first) |> Enum.map(& &1.id)
      assert ids == ["CALL5", "CALL4", "CALL3"]
    end
  end

  describe "list/2 and stream/2" do
    setup do
      store = new_store()

      {:ok, _one} =
        Call.upsert(
          store,
          call(id: "CALL1", chat_jid: @peer, status: :missed, start_time: 100, is_incoming: true)
        )

      {:ok, _two} =
        Call.upsert(
          store,
          call(id: "CALL2", chat_jid: @group, status: :connected, start_time: 200, duration: 60)
        )

      {:ok, _three} =
        Call.upsert(
          store,
          call(id: "CALL3", chat_jid: @peer, status: :rejected, start_time: 300)
        )

      {:ok, store: store}
    end

    test "lists newest first with limit and offset", %{store: store} do
      assert ["CALL3", "CALL2", "CALL1"] = store |> Call.list() |> Enum.map(& &1.id)
      assert ["CALL3"] = store |> Call.list(limit: 1) |> Enum.map(& &1.id)
      assert ["CALL2"] = store |> Call.list(limit: 1, offset: 1) |> Enum.map(& &1.id)
    end

    test "filters by status, jid, and time range", %{store: store} do
      assert ["CALL1"] = store |> Call.list(status: :missed) |> Enum.map(& &1.id)

      assert ["CALL3", "CALL1"] =
               store |> Call.list(status: [:missed, :rejected]) |> Enum.map(& &1.id)

      assert ["CALL2"] = store |> Call.list(jid: @group) |> Enum.map(& &1.id)
      assert ["CALL3", "CALL2"] = store |> Call.list(since: 150) |> Enum.map(& &1.id)
      assert ["CALL2", "CALL1"] = store |> Call.list(until: 250) |> Enum.map(& &1.id)
    end

    test "streams lazily oldest first", %{store: store} do
      assert ["CALL1", "CALL2"] = store |> Call.stream() |> Enum.take(2) |> Enum.map(& &1.id)
    end
  end

  describe "from_call_log_record/2" do
    test "maps a synced record onto the call struct" do
      record = %CallLogRecord{
        callID: "SYNC1",
        callResult: :MISSED,
        isIncoming: true,
        isVideo: false,
        startTime: 1_754_000_000,
        duration: 0,
        callCreatorJID: @peer,
        callType: :REGULAR,
        participants: [
          %CallLogRecord.ParticipantInfo{userJID: @peer, callResult: :MISSED}
        ]
      }

      assert %Call{
               id: "SYNC1",
               chat_jid: @peer,
               creator_jid: @peer,
               status: :missed,
               is_incoming: true,
               is_video: false,
               is_group: false,
               start_time: 1_754_000_000,
               duration: 0,
               call_type: :regular,
               source: :app_state,
               participants: [%{jid: @peer, status: :missed}]
             } = Call.from_call_log_record(record)
    end

    test "uses the group jid and marks group calls" do
      record = %CallLogRecord{
        callID: "SYNC2",
        callResult: :CONNECTED,
        groupJID: @group,
        duration: 120
      }

      assert %Call{chat_jid: @group, group_jid: @group, is_group: true, duration: 120} =
               Call.from_call_log_record(record, source: :history_sync)
    end

    test "resolves the peer of an outgoing call from participants" do
      own = "15550001111@s.whatsapp.net"

      record = %CallLogRecord{
        callID: "SYNC3",
        callResult: :CANCELLED,
        isIncoming: false,
        callCreatorJID: own,
        participants: [
          %CallLogRecord.ParticipantInfo{userJID: own, callResult: :CONNECTED},
          %CallLogRecord.ParticipantInfo{userJID: @peer, callResult: :CANCELLED}
        ]
      }

      assert %Call{chat_jid: @peer, creator_jid: ^own, status: :cancelled, is_incoming: false} =
               Call.from_call_log_record(record)
    end

    test "returns nil without a call id and :unknown for unknown results" do
      assert Call.from_call_log_record(%CallLogRecord{callID: ""}) == nil
      assert Call.from_call_log_record(nil) == nil

      assert %Call{status: :unknown} =
               Call.from_call_log_record(%CallLogRecord{callID: "SYNC4", callResult: 99})
    end
  end

  describe "merge_from_sync/3 and delete_by_peer/3" do
    test "merge_from_sync stores usable records and ignores empty ones" do
      store = new_store()

      assert :ok =
               Call.merge_from_sync(store, %CallLogRecord{
                 callID: "SYNC1",
                 callResult: :CONNECTED,
                 duration: 45
               })

      assert :ignored = Call.merge_from_sync(store, %CallLogRecord{callID: nil})
      assert {:ok, %Call{duration: 45, status: :connected}} = Call.get(store, "SYNC1")
    end

    test "delete_by_peer honors direction and leaves group calls alone" do
      store = new_store()

      {:ok, _in} = Call.upsert(store, call(id: "IN", chat_jid: @peer, is_incoming: true))
      {:ok, _out} = Call.upsert(store, call(id: "OUT", chat_jid: @peer, is_incoming: false))

      {:ok, _group} =
        Call.upsert(store, call(id: "GRP", chat_jid: @group, group_jid: @group))

      assert :ok = Call.delete_by_peer(store, @peer, true)
      assert {:error, :not_found} = Call.get(store, "IN")
      assert {:ok, _out_kept} = Call.get(store, "OUT")

      assert :ok = Call.delete_by_peer(store, @peer)
      assert {:error, :not_found} = Call.get(store, "OUT")
      assert {:ok, _group_kept} = Call.get(store, "GRP")
    end

    test "clear/1 empties the log" do
      store = new_store()
      {:ok, _stored} = Call.upsert(store, call(id: "CALL1"))

      assert :ok = Call.clear(store)
      assert Call.count(store) == 0
    end
  end
end
