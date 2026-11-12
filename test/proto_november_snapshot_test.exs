defmodule ExWapp.ProtoNovemberSnapshotTest do
  use ExUnit.Case, async: true

  # Independent protoc fixtures from whatsmeow c88388f983b4bc43dfd0bcc2b46969fcde82d61f.
  test "omitted conversation metadata uses fields 25 and 26 and the new sync type" do
    bytes =
      Base.decode16!(
        "0809CA01220A08736E617073686F741080A0F1C2B13418002001280132090A07313233406C6964D20108736E617073686F74"
      )

    history = WAWebProtobufsHistorySync.HistorySync.decode!(bytes)
    assert history.syncType == :RECENT_CONVERSATIONS_ON_DEMAND
    assert history.omittedConversationMetadataSnapshotID == "snapshot"
    metadata = history.omittedConversationMetadata
    assert metadata.snapshotID == "snapshot"
    assert metadata.snapshotTimestampMS == 1_800_000_000_000
    assert metadata.batchIndex == 0
    assert metadata.batchCount == 1
    assert metadata.complete
    assert [%{ID: "123@lid"}] = metadata.conversations
    {encoded, size} = WAWebProtobufsHistorySync.HistorySync.encode!(history)
    assert size == byte_size(bytes)
    assert WAWebProtobufsHistorySync.HistorySync.decode!(IO.iodata_to_binary(encoded)) == history
  end

  test "new sync actions decode independently generated field numbers" do
    bytes = Base.decode16!("F20403980202AA060A0A067365637265741002")
    action = WAWebProtobufSyncAction.SyncActionValue.decode!(bytes)
    assert action.settingsSyncAction.mediaAutoDownloadQuality == :MEDIA_AUTO_DOWNLOAD_QUALITY_HD
    assert action.hatchCvmSecretAction.secret == "secret"
    assert action.hatchCvmSecretAction.generation == 2
  end
end
