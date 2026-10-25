defmodule ExWapp.HistoryBlobTest do
  use ExUnit.Case, async: true

  alias ExWapp.Media
  alias ExWapp.Proto.HistorySync
  alias ExWapp.Session.Worker
  alias ExWapp.Test.HistoryBlob

  test "decrypts an independently encrypted history blob and recovers its messages and LID" do
    {blob, body} = HistoryBlob.encrypted()
    ref = HistoryBlob.ref(blob)
    assert {:ok, compressed} = Media.Crypto.decrypt_download(body, ref)
    assert compressed == HistoryBlob.payload()

    assert {:ok, history} = HistorySync.parse_history_payload({:compressed, compressed}, :FULL)
    assert history.sync_type == :RECENT
    assert [{"90000000011@lid", "15550001111@s.whatsapp.net"}] = history.lid_mappings
    assert [%{messages: [%{id: "history-1"}, %{id: "history-2"}]}] = history.conversations

    # Using the document context instead of the history context must fail authentication.
    assert {:error, :invalid_media_hmac} =
             Media.Crypto.decrypt_download(body, %{ref | type: :document})
  end

  test "history downloads reject tampering, hash mismatches, lengths and invalid keys" do
    {blob, body} = HistoryBlob.encrypted()
    ref = HistoryBlob.ref(blob)
    <<first, rest::binary>> = body

    assert {:error, :invalid_media_hmac} =
             Media.Crypto.decrypt_download(<<Bitwise.bxor(first, 1), rest::binary>>, ref)

    for {field, value, reason} <- [
          {:file_sha256, <<0::256>>, :invalid_media_sha256},
          {:file_enc_sha256, <<0::256>>, :invalid_media_enc_sha256},
          {:file_length, blob.file_length + 1, :media_length_mismatch},
          {:media_key, nil, :missing_media_key},
          {:media_key, <<1>>, :invalid_media_key}
        ] do
      assert {:error, ^reason} = Media.Crypto.decrypt_download(body, Map.put(ref, field, value))
    end
  end

  test "compressed history rejects invalid zlib, truncated streams and malformed protobuf" do
    compressed = HistoryBlob.payload()
    truncated = binary_part(compressed, 0, byte_size(compressed) - 4)

    for payload <- ["not zlib", <<>>, truncated] do
      assert {:error, :invalid_history_compression} =
               HistorySync.parse_history_payload({:compressed, payload}, :RECENT)
    end

    assert {:error, _} =
             HistorySync.parse_history_payload(
               {:compressed, :zlib.compress(<<10, 255>>)},
               :RECENT
             )
  end

  test "history blobs from an old connection or a disconnected session are ignored" do
    {blob, _body} = HistoryBlob.encrypted()
    state = %Worker{conn: nil}
    request = {:history_sync_blob, self(), blob, "own@lid", "chunk"}
    assert {:noreply, ^state} = Worker.handle_info(request, state)
    assert {:noreply, ^state} = Worker.handle_info(put_elem(request, 1, nil), state)
  end

  test "an unavailable worker supervisor reports history failure without crashing the session" do
    id = "history-no-supervisor-#{System.unique_integer([:positive])}"
    :ok = ExWapp.subscribe(id)
    state = %Worker{conn: self(), session_id: id}
    {blob, _} = HistoryBlob.encrypted()

    assert {:noreply, ^state} =
             Worker.handle_info({:history_sync_blob, self(), blob, "own@lid", "chunk"}, state)

    assert_receive {:ex_wapp_session, :history_sync, :failed,
                    {:missing_send_worker_supervisor, "history_sync"},
                    %{sync_type: :RECENT, chunk_order: 2}}
  end

  test "a supervisor that exits before the task starts is reported as a history failure" do
    supervisor = start_supervised!(Task.Supervisor)
    stop_supervised!(Task.Supervisor)
    id = "history-dead-supervisor-#{System.unique_integer([:positive])}"
    :ok = ExWapp.subscribe(id)
    state = %Worker{conn: self(), session_id: id, send_worker_sup: supervisor}
    {blob, _} = HistoryBlob.encrypted()

    assert {:noreply, ^state} =
             Worker.handle_info({:history_sync_blob, self(), blob, "own@lid", "chunk"}, state)

    assert_receive {:ex_wapp_session, :history_sync, :failed, {:task_supervisor_exit, _}, _}
  end
end
