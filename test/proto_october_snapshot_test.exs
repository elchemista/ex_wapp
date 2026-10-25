defmodule ExWapp.ProtoOctoberSnapshotTest do
  use ExUnit.Case, async: true

  alias WAWebProtobufsE2E.{ChatThemeSetting, Message}
  alias WAWebProtobufsHistorySync.HistorySync
  alias WAWebProtobufsWa6.ClientPayload
  alias WAWebProtobufSyncAction.SyncActionValue

  # Golden bytes generated independently with protoc --encode against
  # tulir/whatsmeow b2b1e71d45e2ff171153b025b5a42f475bb30ef8.
  # These fixtures cover changed wire types, oneofs and new field numbers.

  test "solid wallpaper colors use unsigned fixed32 ARGB values" do
    theme =
      decode_fixture(
        ChatThemeSetting,
        "0880A0F1C2B1345A160DFFFFFFFF15000000FF180125443322112D88776655"
      )

    assert theme.settingTimestampMS == 1_800_000_000_000
    assert {:solidColor, colors} = theme.wallpaper
    assert colors.backgroundLightArgb == 0xFFFFFFFF
    assert colors.backgroundDarkArgb == 0xFF000000
    assert colors.isDoodleEnabled
    assert colors.doodleLightArgb == 0x11223344
    assert colors.doodleDarkArgb == 0x55667788
  end

  test "animated wallpapers occupy their own oneof alternative" do
    theme = decode_fixture(ChatThemeSetting, "72100A0977616C6C7061706572150000003F")
    assert {:animatedWallpaper, wallpaper} = theme.wallpaper
    assert wallpaper.animatedWallpaperID == "wallpaper"
    assert wallpaper.dimLevel == 0.5
  end

  test "shared-device contact keys retain their kind, epoch and prompt IDs" do
    message =
      decode_fixture(Message, "62191028A2020B0A09080710021A036B6579B2020670726F6D7074")

    assert message.protocolMessage.type == :SHARED_DEVICE_CONTACT_HASH_KEY_SHARE
    assert [key] = message.protocolMessage.sharedDeviceContactHashKeyShare.keys
    assert key.kind == :PHONE_NUMBER
    assert key.epoch == 7
    assert key.keyData == "key"
    assert message.protocolMessage.additionalPromptIDs == ["prompt"]
  end

  test "audio stickers preserve the nested audio oneof" do
    message =
      decode_fixture(
        Message,
        "B208210A1FD2011C2A0A696D6167652F77656270D2010D1209617564696F2F6F67672803"
      )

    sticker = message.audioStickerMessage.message.stickerMessage
    assert sticker.mimetype == "image/webp"
    assert {:audioMessage, audio} = sticker.audio
    assert audio.mimetype == "audio/ogg"
    assert audio.seconds == 3
  end

  test "location requests and cancellations preserve their referenced message" do
    message =
      decode_fixture(
        Message,
        "C2080B0A090A0772657175657374D208140A091A077265717565737410011880A0F1C2B134"
      )

    assert message.requestLocationMessage.contextInfo.stanzaID == "request"
    update = message.requestLocationUpdateMessage
    assert update.key."ID" == "request"
    assert update.updateType == :CANCEL
    assert update.senderTimestampMS == 1_800_000_000_000
  end

  test "history sync preserves withheld ACP2 history and omitted conversations" do
    history =
      decode_fixture(
        HistorySync,
        "0802120E0A04636861748204020801880401BA01120A076F6D69747465641207313233406C6964C00101"
      )

    assert history.syncType == :FULL
    assert [conversation] = history.conversations
    assert conversation."ID" == "chat"
    assert conversation.acp2Setting.enabled
    assert conversation.acp2HistoryWithheld
    assert history.omittedConversationsProvided
    assert [omitted] = history.omittedConversations
    assert omitted.historyChatID == "omitted"
    assert omitted.accountLid == "123@lid"
  end

  test "new sync actions retain independent fields and enum values" do
    action =
      decode_fixture(
        SyncActionValue,
        "8A0602080192060208019A06020801A2060C0A0673656372657410E0D403"
      )

    assert action.groupHistoryToggleAction.groupHistoryToggleMode == :GROUP_HISTORY_TOGGLE_MODE_ON
    assert action.bbProPendingCustomerBaseAction.pending
    assert action.communityNestingStateAction.nestingState == :NESTING_STATE_NESTED
    assert action.sharedDeviceSecretAction.secret == "secret"
    assert action.sharedDeviceSecretAction.ttlMS == 60_000
  end

  test "client payload recognizes the automotive platform and message timestamp" do
    payload = decode_fixture(ClientPayload, "2A020829880380A4A7DA06")
    assert payload.userAgent.platform == :AUTOMOTIVE
    assert payload.messageSts == 1_800_000_000
  end

  defp decode_fixture(module, hex) do
    bytes = Base.decode16!(hex)
    decoded = module.decode!(bytes)
    # Protobuf permits fields in either order. Check both Protox 2 encode APIs
    # and their byte counts against the independently generated wire fixture.
    assert {:ok, iodata, size} = module.encode(decoded)
    assert {^iodata, ^size} = module.encode!(decoded)
    reencoded = IO.iodata_to_binary(iodata)
    assert size == byte_size(reencoded)
    assert size == byte_size(bytes)
    assert module.decode!(reencoded) == decoded
    decoded
  end
end
