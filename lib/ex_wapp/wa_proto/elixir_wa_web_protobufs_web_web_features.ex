# credo:disable-for-this-file
defmodule WAWebProtobufsWeb.WebFeatures do
  @moduledoc false
  defstruct labelsDisplay: nil,
            voipIndividualOutgoing: nil,
            groupsV3: nil,
            groupsV3Create: nil,
            changeNumberV2: nil,
            queryStatusV3Thumbnail: nil,
            liveLocations: nil,
            queryVname: nil,
            voipIndividualIncoming: nil,
            quickRepliesQuery: nil,
            payments: nil,
            stickerPackQuery: nil,
            liveLocationsFinal: nil,
            labelsEdit: nil,
            mediaUpload: nil,
            mediaUploadRichQuickReplies: nil,
            vnameV2: nil,
            videoPlaybackURL: nil,
            statusRanking: nil,
            voipIndividualVideo: nil,
            thirdPartyStickers: nil,
            frequentlyForwardedSetting: nil,
            groupsV4JoinPermission: nil,
            recentStickers: nil,
            catalog: nil,
            starredStickers: nil,
            voipGroupCall: nil,
            templateMessage: nil,
            templateMessageInteractivity: nil,
            ephemeralMessages: nil,
            e2ENotificationSync: nil,
            recentStickersV2: nil,
            recentStickersV3: nil,
            userNotice: nil,
            support: nil,
            groupUiiCleanup: nil,
            groupDogfoodingInternalOnly: nil,
            settingsSync: nil,
            archiveV2: nil,
            ephemeralAllowGroupMembers: nil,
            ephemeral24HDuration: nil,
            mdForceUpgrade: nil,
            disappearingMode: nil,
            externalMdOptInAvailable: nil,
            noDeleteMessageTimeLimit: nil,
            __uf__: []

  (
    (
      @spec encode(struct) :: {:ok, iodata} | {:error, any}
      def encode(msg) do
        try do
          {:ok, encode!(msg)}
        rescue
          e in [Protox.EncodingError, Protox.RequiredFieldsError] -> {:error, e}
        end
      end

      @spec encode!(struct) :: iodata | no_return
      def encode!(msg) do
        []
        |> encode_labelsDisplay(msg)
        |> encode_voipIndividualOutgoing(msg)
        |> encode_groupsV3(msg)
        |> encode_groupsV3Create(msg)
        |> encode_changeNumberV2(msg)
        |> encode_queryStatusV3Thumbnail(msg)
        |> encode_liveLocations(msg)
        |> encode_queryVname(msg)
        |> encode_voipIndividualIncoming(msg)
        |> encode_quickRepliesQuery(msg)
        |> encode_payments(msg)
        |> encode_stickerPackQuery(msg)
        |> encode_liveLocationsFinal(msg)
        |> encode_labelsEdit(msg)
        |> encode_mediaUpload(msg)
        |> encode_mediaUploadRichQuickReplies(msg)
        |> encode_vnameV2(msg)
        |> encode_videoPlaybackURL(msg)
        |> encode_statusRanking(msg)
        |> encode_voipIndividualVideo(msg)
        |> encode_thirdPartyStickers(msg)
        |> encode_frequentlyForwardedSetting(msg)
        |> encode_groupsV4JoinPermission(msg)
        |> encode_recentStickers(msg)
        |> encode_catalog(msg)
        |> encode_starredStickers(msg)
        |> encode_voipGroupCall(msg)
        |> encode_templateMessage(msg)
        |> encode_templateMessageInteractivity(msg)
        |> encode_ephemeralMessages(msg)
        |> encode_e2ENotificationSync(msg)
        |> encode_recentStickersV2(msg)
        |> encode_recentStickersV3(msg)
        |> encode_userNotice(msg)
        |> encode_support(msg)
        |> encode_groupUiiCleanup(msg)
        |> encode_groupDogfoodingInternalOnly(msg)
        |> encode_settingsSync(msg)
        |> encode_archiveV2(msg)
        |> encode_ephemeralAllowGroupMembers(msg)
        |> encode_ephemeral24HDuration(msg)
        |> encode_mdForceUpgrade(msg)
        |> encode_disappearingMode(msg)
        |> encode_externalMdOptInAvailable(msg)
        |> encode_noDeleteMessageTimeLimit(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_labelsDisplay(acc, msg) do
        try do
          case msg.labelsDisplay do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.labelsDisplay
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:labelsDisplay, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_voipIndividualOutgoing(acc, msg) do
        try do
          case msg.voipIndividualOutgoing do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x10",
                msg.voipIndividualOutgoing
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:voipIndividualOutgoing, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_groupsV3(acc, msg) do
        try do
          case msg.groupsV3 do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x18",
                msg.groupsV3
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupsV3, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_groupsV3Create(acc, msg) do
        try do
          case msg.groupsV3Create do
            nil ->
              acc

            _ ->
              [
                acc,
                " ",
                msg.groupsV3Create
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupsV3Create, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_changeNumberV2(acc, msg) do
        try do
          case msg.changeNumberV2 do
            nil ->
              acc

            _ ->
              [
                acc,
                "(",
                msg.changeNumberV2
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:changeNumberV2, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_queryStatusV3Thumbnail(acc, msg) do
        try do
          case msg.queryStatusV3Thumbnail do
            nil ->
              acc

            _ ->
              [
                acc,
                "0",
                msg.queryStatusV3Thumbnail
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:queryStatusV3Thumbnail, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_liveLocations(acc, msg) do
        try do
          case msg.liveLocations do
            nil ->
              acc

            _ ->
              [
                acc,
                "8",
                msg.liveLocations
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:liveLocations, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_queryVname(acc, msg) do
        try do
          case msg.queryVname do
            nil ->
              acc

            _ ->
              [
                acc,
                "@",
                msg.queryVname
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:queryVname, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_voipIndividualIncoming(acc, msg) do
        try do
          case msg.voipIndividualIncoming do
            nil ->
              acc

            _ ->
              [
                acc,
                "H",
                msg.voipIndividualIncoming
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:voipIndividualIncoming, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_quickRepliesQuery(acc, msg) do
        try do
          case msg.quickRepliesQuery do
            nil ->
              acc

            _ ->
              [
                acc,
                "P",
                msg.quickRepliesQuery
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:quickRepliesQuery, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_payments(acc, msg) do
        try do
          case msg.payments do
            nil ->
              acc

            _ ->
              [
                acc,
                "X",
                msg.payments
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:payments, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_stickerPackQuery(acc, msg) do
        try do
          case msg.stickerPackQuery do
            nil ->
              acc

            _ ->
              [
                acc,
                "`",
                msg.stickerPackQuery
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:stickerPackQuery, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_liveLocationsFinal(acc, msg) do
        try do
          case msg.liveLocationsFinal do
            nil ->
              acc

            _ ->
              [
                acc,
                "h",
                msg.liveLocationsFinal
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:liveLocationsFinal, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_labelsEdit(acc, msg) do
        try do
          case msg.labelsEdit do
            nil ->
              acc

            _ ->
              [
                acc,
                "p",
                msg.labelsEdit
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:labelsEdit, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaUpload(acc, msg) do
        try do
          case msg.mediaUpload do
            nil ->
              acc

            _ ->
              [
                acc,
                "x",
                msg.mediaUpload
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaUpload, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaUploadRichQuickReplies(acc, msg) do
        try do
          case msg.mediaUploadRichQuickReplies do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x90\x01",
                msg.mediaUploadRichQuickReplies
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaUploadRichQuickReplies, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_vnameV2(acc, msg) do
        try do
          case msg.vnameV2 do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x98\x01",
                msg.vnameV2
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:vnameV2, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_videoPlaybackURL(acc, msg) do
        try do
          case msg.videoPlaybackURL do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xA0\x01",
                msg.videoPlaybackURL
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:videoPlaybackURL, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusRanking(acc, msg) do
        try do
          case msg.statusRanking do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xA8\x01",
                msg.statusRanking
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusRanking, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_voipIndividualVideo(acc, msg) do
        try do
          case msg.voipIndividualVideo do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xB0\x01",
                msg.voipIndividualVideo
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:voipIndividualVideo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thirdPartyStickers(acc, msg) do
        try do
          case msg.thirdPartyStickers do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xB8\x01",
                msg.thirdPartyStickers
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thirdPartyStickers, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_frequentlyForwardedSetting(acc, msg) do
        try do
          case msg.frequentlyForwardedSetting do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xC0\x01",
                msg.frequentlyForwardedSetting
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:frequentlyForwardedSetting, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_groupsV4JoinPermission(acc, msg) do
        try do
          case msg.groupsV4JoinPermission do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xC8\x01",
                msg.groupsV4JoinPermission
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupsV4JoinPermission, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_recentStickers(acc, msg) do
        try do
          case msg.recentStickers do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xD0\x01",
                msg.recentStickers
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:recentStickers, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_catalog(acc, msg) do
        try do
          case msg.catalog do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xD8\x01",
                msg.catalog
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:catalog, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_starredStickers(acc, msg) do
        try do
          case msg.starredStickers do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xE0\x01",
                msg.starredStickers
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:starredStickers, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_voipGroupCall(acc, msg) do
        try do
          case msg.voipGroupCall do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xE8\x01",
                msg.voipGroupCall
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:voipGroupCall, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_templateMessage(acc, msg) do
        try do
          case msg.templateMessage do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xF0\x01",
                msg.templateMessage
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:templateMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_templateMessageInteractivity(acc, msg) do
        try do
          case msg.templateMessageInteractivity do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xF8\x01",
                msg.templateMessageInteractivity
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :templateMessageInteractivity,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_ephemeralMessages(acc, msg) do
        try do
          case msg.ephemeralMessages do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x80\x02",
                msg.ephemeralMessages
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeralMessages, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_e2ENotificationSync(acc, msg) do
        try do
          case msg.e2ENotificationSync do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x88\x02",
                msg.e2ENotificationSync
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:e2ENotificationSync, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_recentStickersV2(acc, msg) do
        try do
          case msg.recentStickersV2 do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x90\x02",
                msg.recentStickersV2
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:recentStickersV2, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_recentStickersV3(acc, msg) do
        try do
          case msg.recentStickersV3 do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xA0\x02",
                msg.recentStickersV3
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:recentStickersV3, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_userNotice(acc, msg) do
        try do
          case msg.userNotice do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xA8\x02",
                msg.userNotice
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:userNotice, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_support(acc, msg) do
        try do
          case msg.support do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xB8\x02",
                msg.support
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:support, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_groupUiiCleanup(acc, msg) do
        try do
          case msg.groupUiiCleanup do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xC0\x02",
                msg.groupUiiCleanup
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupUiiCleanup, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_groupDogfoodingInternalOnly(acc, msg) do
        try do
          case msg.groupDogfoodingInternalOnly do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xC8\x02",
                msg.groupDogfoodingInternalOnly
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupDogfoodingInternalOnly, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_settingsSync(acc, msg) do
        try do
          case msg.settingsSync do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xD0\x02",
                msg.settingsSync
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:settingsSync, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_archiveV2(acc, msg) do
        try do
          case msg.archiveV2 do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xD8\x02",
                msg.archiveV2
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:archiveV2, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_ephemeralAllowGroupMembers(acc, msg) do
        try do
          case msg.ephemeralAllowGroupMembers do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xE0\x02",
                msg.ephemeralAllowGroupMembers
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeralAllowGroupMembers, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ephemeral24HDuration(acc, msg) do
        try do
          case msg.ephemeral24HDuration do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xE8\x02",
                msg.ephemeral24HDuration
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeral24HDuration, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_mdForceUpgrade(acc, msg) do
        try do
          case msg.mdForceUpgrade do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xF0\x02",
                msg.mdForceUpgrade
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mdForceUpgrade, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_disappearingMode(acc, msg) do
        try do
          case msg.disappearingMode do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xF8\x02",
                msg.disappearingMode
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:disappearingMode, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_externalMdOptInAvailable(acc, msg) do
        try do
          case msg.externalMdOptInAvailable do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x80\x03",
                msg.externalMdOptInAvailable
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:externalMdOptInAvailable, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_noDeleteMessageTimeLimit(acc, msg) do
        try do
          case msg.noDeleteMessageTimeLimit do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x88\x03",
                msg.noDeleteMessageTimeLimit
                |> WAWebProtobufsWeb.WebFeatures.Flag.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:noDeleteMessageTimeLimit, "invalid field value"),
                    __STACKTRACE__
        end
      end
    ]

    defp encode_unknown_fields(acc, msg) do
      Enum.reduce(msg.__struct__.unknown_fields(msg), acc, fn {tag, wire_type, bytes}, acc ->
        case wire_type do
          0 ->
            [acc, Protox.Encode.make_key_bytes(tag, :int32), bytes]

          1 ->
            [acc, Protox.Encode.make_key_bytes(tag, :double), bytes]

          2 ->
            len_bytes = bytes |> byte_size() |> Protox.Varint.encode()
            [acc, Protox.Encode.make_key_bytes(tag, :packed), len_bytes, bytes]

          5 ->
            [acc, Protox.Encode.make_key_bytes(tag, :float), bytes]
        end
      end)
    end
  )

  (
    (
      @spec decode(binary) :: {:ok, struct} | {:error, any}
      def decode(bytes) do
        try do
          {:ok, decode!(bytes)}
        rescue
          e in [Protox.DecodingError, Protox.IllegalTagError, Protox.RequiredFieldsError] ->
            {:error, e}
        end
      end

      (
        @spec decode!(binary) :: struct | no_return
        def decode!(bytes) do
          parse_key_value(bytes, struct(WAWebProtobufsWeb.WebFeatures))
        end
      )
    )

    (
      @spec parse_key_value(binary, struct) :: struct
      defp parse_key_value(<<>>, msg) do
        msg
      end

      defp parse_key_value(bytes, msg) do
        {field, rest} =
          case Protox.Decode.parse_key(bytes) do
            {0, _, _} ->
              raise %Protox.IllegalTagError{}

            {1, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[labelsDisplay: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[voipIndividualOutgoing: value], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[groupsV3: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[groupsV3Create: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[changeNumberV2: value], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[queryStatusV3Thumbnail: value], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[liveLocations: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[queryVname: value], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[voipIndividualIncoming: value], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[quickRepliesQuery: value], rest}

            {11, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[payments: value], rest}

            {12, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[stickerPackQuery: value], rest}

            {13, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[liveLocationsFinal: value], rest}

            {14, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[labelsEdit: value], rest}

            {15, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[mediaUpload: value], rest}

            {18, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[mediaUploadRichQuickReplies: value], rest}

            {19, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[vnameV2: value], rest}

            {20, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[videoPlaybackURL: value], rest}

            {21, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[statusRanking: value], rest}

            {22, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[voipIndividualVideo: value], rest}

            {23, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[thirdPartyStickers: value], rest}

            {24, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[frequentlyForwardedSetting: value], rest}

            {25, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[groupsV4JoinPermission: value], rest}

            {26, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[recentStickers: value], rest}

            {27, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[catalog: value], rest}

            {28, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[starredStickers: value], rest}

            {29, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[voipGroupCall: value], rest}

            {30, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[templateMessage: value], rest}

            {31, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[templateMessageInteractivity: value], rest}

            {32, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[ephemeralMessages: value], rest}

            {33, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[e2ENotificationSync: value], rest}

            {34, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[recentStickersV2: value], rest}

            {36, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[recentStickersV3: value], rest}

            {37, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[userNotice: value], rest}

            {39, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[support: value], rest}

            {40, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[groupUiiCleanup: value], rest}

            {41, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[groupDogfoodingInternalOnly: value], rest}

            {42, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[settingsSync: value], rest}

            {43, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[archiveV2: value], rest}

            {44, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[ephemeralAllowGroupMembers: value], rest}

            {45, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[ephemeral24HDuration: value], rest}

            {46, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[mdForceUpgrade: value], rest}

            {47, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[disappearingMode: value], rest}

            {48, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[externalMdOptInAvailable: value], rest}

            {49, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebFeatures.Flag)
              {[noDeleteMessageTimeLimit: value], rest}

            {tag, wire_type, rest} ->
              {value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

              {[
                 {msg.__struct__.unknown_fields_name(),
                  [value | msg.__struct__.unknown_fields(msg)]}
               ], rest}
          end

        msg_updated = struct(msg, field)
        parse_key_value(rest, msg_updated)
      end
    )

    []
  )

  (
    @spec json_decode(iodata(), keyword()) :: {:ok, struct()} | {:error, any()}
    def json_decode(input, opts \\ []) do
      try do
        {:ok, json_decode!(input, opts)}
      rescue
        e in Protox.JsonDecodingError -> {:error, e}
      end
    end

    @spec json_decode!(iodata(), keyword()) :: struct() | no_return()
    def json_decode!(input, opts \\ []) do
      {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :decode)

      Protox.JsonDecode.decode!(
        input,
        WAWebProtobufsWeb.WebFeatures,
        &json_library_wrapper.decode!(json_library, &1)
      )
    end

    @spec json_encode(struct(), keyword()) :: {:ok, iodata()} | {:error, any()}
    def json_encode(msg, opts \\ []) do
      try do
        {:ok, json_encode!(msg, opts)}
      rescue
        e in Protox.JsonEncodingError -> {:error, e}
      end
    end

    @spec json_encode!(struct(), keyword()) :: iodata() | no_return()
    def json_encode!(msg, opts \\ []) do
      {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :encode)
      Protox.JsonEncode.encode!(msg, &json_library_wrapper.encode!(json_library, &1))
    end
  )

  (
    @deprecated "Use fields_defs()/0 instead"
    @spec defs() :: %{
            required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs() do
      %{
        1 =>
          {:labelsDisplay, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        2 =>
          {:voipIndividualOutgoing, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        3 => {:groupsV3, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        4 =>
          {:groupsV3Create, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        5 =>
          {:changeNumberV2, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        6 =>
          {:queryStatusV3Thumbnail, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        7 =>
          {:liveLocations, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        8 => {:queryVname, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        9 =>
          {:voipIndividualIncoming, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        10 =>
          {:quickRepliesQuery, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        11 => {:payments, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        12 =>
          {:stickerPackQuery, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        13 =>
          {:liveLocationsFinal, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        14 => {:labelsEdit, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        15 =>
          {:mediaUpload, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        18 =>
          {:mediaUploadRichQuickReplies, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        19 => {:vnameV2, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        20 =>
          {:videoPlaybackURL, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        21 =>
          {:statusRanking, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        22 =>
          {:voipIndividualVideo, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        23 =>
          {:thirdPartyStickers, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        24 =>
          {:frequentlyForwardedSetting, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        25 =>
          {:groupsV4JoinPermission, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        26 =>
          {:recentStickers, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        27 => {:catalog, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        28 =>
          {:starredStickers, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        29 =>
          {:voipGroupCall, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        30 =>
          {:templateMessage, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        31 =>
          {:templateMessageInteractivity, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        32 =>
          {:ephemeralMessages, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        33 =>
          {:e2ENotificationSync, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        34 =>
          {:recentStickersV2, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        36 =>
          {:recentStickersV3, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        37 => {:userNotice, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        39 => {:support, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        40 =>
          {:groupUiiCleanup, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        41 =>
          {:groupDogfoodingInternalOnly, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        42 =>
          {:settingsSync, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        43 => {:archiveV2, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        44 =>
          {:ephemeralAllowGroupMembers, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        45 =>
          {:ephemeral24HDuration, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        46 =>
          {:mdForceUpgrade, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        47 =>
          {:disappearingMode, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        48 =>
          {:externalMdOptInAvailable, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        49 =>
          {:noDeleteMessageTimeLimit, {:scalar, :NOT_STARTED},
           {:enum, WAWebProtobufsWeb.WebFeatures.Flag}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        archiveV2: {43, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        catalog: {27, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        changeNumberV2: {5, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        disappearingMode:
          {47, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        e2ENotificationSync:
          {33, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        ephemeral24HDuration:
          {45, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        ephemeralAllowGroupMembers:
          {44, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        ephemeralMessages:
          {32, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        externalMdOptInAvailable:
          {48, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        frequentlyForwardedSetting:
          {24, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        groupDogfoodingInternalOnly:
          {41, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        groupUiiCleanup:
          {40, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        groupsV3: {3, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        groupsV3Create: {4, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        groupsV4JoinPermission:
          {25, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        labelsDisplay: {1, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        labelsEdit: {14, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        liveLocations: {7, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        liveLocationsFinal:
          {13, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        mdForceUpgrade:
          {46, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        mediaUpload: {15, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        mediaUploadRichQuickReplies:
          {18, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        noDeleteMessageTimeLimit:
          {49, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        payments: {11, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        queryStatusV3Thumbnail:
          {6, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        queryVname: {8, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        quickRepliesQuery:
          {10, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        recentStickers:
          {26, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        recentStickersV2:
          {34, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        recentStickersV3:
          {36, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        settingsSync: {42, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        starredStickers:
          {28, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        statusRanking: {21, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        stickerPackQuery:
          {12, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        support: {39, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        templateMessage:
          {30, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        templateMessageInteractivity:
          {31, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        thirdPartyStickers:
          {23, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        userNotice: {37, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        videoPlaybackURL:
          {20, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        vnameV2: {19, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        voipGroupCall: {29, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        voipIndividualIncoming:
          {9, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        voipIndividualOutgoing:
          {2, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}},
        voipIndividualVideo:
          {22, {:scalar, :NOT_STARTED}, {:enum, WAWebProtobufsWeb.WebFeatures.Flag}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "labelsDisplay",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :labelsDisplay,
          tag: 1,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "voipIndividualOutgoing",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :voipIndividualOutgoing,
          tag: 2,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupsV3",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :groupsV3,
          tag: 3,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupsV3Create",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :groupsV3Create,
          tag: 4,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "changeNumberV2",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :changeNumberV2,
          tag: 5,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "queryStatusV3Thumbnail",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :queryStatusV3Thumbnail,
          tag: 6,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "liveLocations",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :liveLocations,
          tag: 7,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "queryVname",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :queryVname,
          tag: 8,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "voipIndividualIncoming",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :voipIndividualIncoming,
          tag: 9,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "quickRepliesQuery",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :quickRepliesQuery,
          tag: 10,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "payments",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :payments,
          tag: 11,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "stickerPackQuery",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :stickerPackQuery,
          tag: 12,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "liveLocationsFinal",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :liveLocationsFinal,
          tag: 13,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "labelsEdit",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :labelsEdit,
          tag: 14,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaUpload",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :mediaUpload,
          tag: 15,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaUploadRichQuickReplies",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :mediaUploadRichQuickReplies,
          tag: 18,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "vnameV2",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :vnameV2,
          tag: 19,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "videoPlaybackURL",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :videoPlaybackURL,
          tag: 20,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusRanking",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :statusRanking,
          tag: 21,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "voipIndividualVideo",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :voipIndividualVideo,
          tag: 22,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "thirdPartyStickers",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :thirdPartyStickers,
          tag: 23,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "frequentlyForwardedSetting",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :frequentlyForwardedSetting,
          tag: 24,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupsV4JoinPermission",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :groupsV4JoinPermission,
          tag: 25,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "recentStickers",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :recentStickers,
          tag: 26,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "catalog",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :catalog,
          tag: 27,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "starredStickers",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :starredStickers,
          tag: 28,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "voipGroupCall",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :voipGroupCall,
          tag: 29,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "templateMessage",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :templateMessage,
          tag: 30,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "templateMessageInteractivity",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :templateMessageInteractivity,
          tag: 31,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeralMessages",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :ephemeralMessages,
          tag: 32,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "e2ENotificationSync",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :e2ENotificationSync,
          tag: 33,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "recentStickersV2",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :recentStickersV2,
          tag: 34,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "recentStickersV3",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :recentStickersV3,
          tag: 36,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "userNotice",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :userNotice,
          tag: 37,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "support",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :support,
          tag: 39,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupUiiCleanup",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :groupUiiCleanup,
          tag: 40,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupDogfoodingInternalOnly",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :groupDogfoodingInternalOnly,
          tag: 41,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "settingsSync",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :settingsSync,
          tag: 42,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "archiveV2",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :archiveV2,
          tag: 43,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeralAllowGroupMembers",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :ephemeralAllowGroupMembers,
          tag: 44,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeral24HDuration",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :ephemeral24HDuration,
          tag: 45,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "mdForceUpgrade",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :mdForceUpgrade,
          tag: 46,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "disappearingMode",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :disappearingMode,
          tag: 47,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "externalMdOptInAvailable",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :externalMdOptInAvailable,
          tag: 48,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        },
        %{
          __struct__: Protox.Field,
          json_name: "noDeleteMessageTimeLimit",
          kind: {:scalar, :NOT_STARTED},
          label: :optional,
          name: :noDeleteMessageTimeLimit,
          tag: 49,
          type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:labelsDisplay) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "labelsDisplay",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :labelsDisplay,
             tag: 1,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("labelsDisplay") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "labelsDisplay",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :labelsDisplay,
             tag: 1,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:voipIndividualOutgoing) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "voipIndividualOutgoing",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :voipIndividualOutgoing,
             tag: 2,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("voipIndividualOutgoing") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "voipIndividualOutgoing",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :voipIndividualOutgoing,
             tag: 2,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:groupsV3) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupsV3",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :groupsV3,
             tag: 3,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("groupsV3") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupsV3",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :groupsV3,
             tag: 3,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:groupsV3Create) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupsV3Create",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :groupsV3Create,
             tag: 4,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("groupsV3Create") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupsV3Create",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :groupsV3Create,
             tag: 4,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:changeNumberV2) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "changeNumberV2",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :changeNumberV2,
             tag: 5,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("changeNumberV2") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "changeNumberV2",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :changeNumberV2,
             tag: 5,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:queryStatusV3Thumbnail) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "queryStatusV3Thumbnail",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :queryStatusV3Thumbnail,
             tag: 6,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("queryStatusV3Thumbnail") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "queryStatusV3Thumbnail",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :queryStatusV3Thumbnail,
             tag: 6,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:liveLocations) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "liveLocations",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :liveLocations,
             tag: 7,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("liveLocations") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "liveLocations",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :liveLocations,
             tag: 7,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:queryVname) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "queryVname",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :queryVname,
             tag: 8,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("queryVname") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "queryVname",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :queryVname,
             tag: 8,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:voipIndividualIncoming) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "voipIndividualIncoming",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :voipIndividualIncoming,
             tag: 9,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("voipIndividualIncoming") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "voipIndividualIncoming",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :voipIndividualIncoming,
             tag: 9,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:quickRepliesQuery) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quickRepliesQuery",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :quickRepliesQuery,
             tag: 10,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("quickRepliesQuery") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quickRepliesQuery",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :quickRepliesQuery,
             tag: 10,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:payments) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "payments",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :payments,
             tag: 11,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("payments") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "payments",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :payments,
             tag: 11,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:stickerPackQuery) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerPackQuery",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :stickerPackQuery,
             tag: 12,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("stickerPackQuery") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerPackQuery",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :stickerPackQuery,
             tag: 12,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:liveLocationsFinal) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "liveLocationsFinal",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :liveLocationsFinal,
             tag: 13,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("liveLocationsFinal") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "liveLocationsFinal",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :liveLocationsFinal,
             tag: 13,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:labelsEdit) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "labelsEdit",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :labelsEdit,
             tag: 14,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("labelsEdit") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "labelsEdit",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :labelsEdit,
             tag: 14,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:mediaUpload) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaUpload",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :mediaUpload,
             tag: 15,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("mediaUpload") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaUpload",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :mediaUpload,
             tag: 15,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:mediaUploadRichQuickReplies) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaUploadRichQuickReplies",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :mediaUploadRichQuickReplies,
             tag: 18,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("mediaUploadRichQuickReplies") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaUploadRichQuickReplies",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :mediaUploadRichQuickReplies,
             tag: 18,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:vnameV2) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "vnameV2",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :vnameV2,
             tag: 19,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("vnameV2") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "vnameV2",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :vnameV2,
             tag: 19,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:videoPlaybackURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoPlaybackURL",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :videoPlaybackURL,
             tag: 20,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("videoPlaybackURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoPlaybackURL",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :videoPlaybackURL,
             tag: 20,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:statusRanking) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusRanking",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :statusRanking,
             tag: 21,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("statusRanking") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusRanking",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :statusRanking,
             tag: 21,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:voipIndividualVideo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "voipIndividualVideo",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :voipIndividualVideo,
             tag: 22,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("voipIndividualVideo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "voipIndividualVideo",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :voipIndividualVideo,
             tag: 22,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:thirdPartyStickers) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thirdPartyStickers",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :thirdPartyStickers,
             tag: 23,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("thirdPartyStickers") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thirdPartyStickers",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :thirdPartyStickers,
             tag: 23,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:frequentlyForwardedSetting) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "frequentlyForwardedSetting",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :frequentlyForwardedSetting,
             tag: 24,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("frequentlyForwardedSetting") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "frequentlyForwardedSetting",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :frequentlyForwardedSetting,
             tag: 24,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:groupsV4JoinPermission) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupsV4JoinPermission",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :groupsV4JoinPermission,
             tag: 25,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("groupsV4JoinPermission") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupsV4JoinPermission",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :groupsV4JoinPermission,
             tag: 25,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:recentStickers) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recentStickers",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :recentStickers,
             tag: 26,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("recentStickers") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recentStickers",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :recentStickers,
             tag: 26,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:catalog) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "catalog",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :catalog,
             tag: 27,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("catalog") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "catalog",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :catalog,
             tag: 27,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:starredStickers) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "starredStickers",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :starredStickers,
             tag: 28,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("starredStickers") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "starredStickers",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :starredStickers,
             tag: 28,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:voipGroupCall) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "voipGroupCall",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :voipGroupCall,
             tag: 29,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("voipGroupCall") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "voipGroupCall",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :voipGroupCall,
             tag: 29,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:templateMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "templateMessage",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :templateMessage,
             tag: 30,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("templateMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "templateMessage",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :templateMessage,
             tag: 30,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:templateMessageInteractivity) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "templateMessageInteractivity",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :templateMessageInteractivity,
             tag: 31,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("templateMessageInteractivity") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "templateMessageInteractivity",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :templateMessageInteractivity,
             tag: 31,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:ephemeralMessages) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralMessages",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :ephemeralMessages,
             tag: 32,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("ephemeralMessages") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralMessages",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :ephemeralMessages,
             tag: 32,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:e2ENotificationSync) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "e2ENotificationSync",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :e2ENotificationSync,
             tag: 33,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("e2ENotificationSync") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "e2ENotificationSync",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :e2ENotificationSync,
             tag: 33,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:recentStickersV2) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recentStickersV2",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :recentStickersV2,
             tag: 34,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("recentStickersV2") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recentStickersV2",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :recentStickersV2,
             tag: 34,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:recentStickersV3) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recentStickersV3",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :recentStickersV3,
             tag: 36,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("recentStickersV3") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recentStickersV3",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :recentStickersV3,
             tag: 36,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:userNotice) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "userNotice",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :userNotice,
             tag: 37,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("userNotice") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "userNotice",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :userNotice,
             tag: 37,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:support) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "support",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :support,
             tag: 39,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("support") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "support",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :support,
             tag: 39,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:groupUiiCleanup) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupUiiCleanup",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :groupUiiCleanup,
             tag: 40,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("groupUiiCleanup") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupUiiCleanup",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :groupUiiCleanup,
             tag: 40,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:groupDogfoodingInternalOnly) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupDogfoodingInternalOnly",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :groupDogfoodingInternalOnly,
             tag: 41,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("groupDogfoodingInternalOnly") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupDogfoodingInternalOnly",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :groupDogfoodingInternalOnly,
             tag: 41,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:settingsSync) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "settingsSync",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :settingsSync,
             tag: 42,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("settingsSync") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "settingsSync",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :settingsSync,
             tag: 42,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:archiveV2) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "archiveV2",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :archiveV2,
             tag: 43,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("archiveV2") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "archiveV2",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :archiveV2,
             tag: 43,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:ephemeralAllowGroupMembers) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralAllowGroupMembers",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :ephemeralAllowGroupMembers,
             tag: 44,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("ephemeralAllowGroupMembers") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralAllowGroupMembers",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :ephemeralAllowGroupMembers,
             tag: 44,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:ephemeral24HDuration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeral24HDuration",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :ephemeral24HDuration,
             tag: 45,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("ephemeral24HDuration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeral24HDuration",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :ephemeral24HDuration,
             tag: 45,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:mdForceUpgrade) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mdForceUpgrade",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :mdForceUpgrade,
             tag: 46,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("mdForceUpgrade") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mdForceUpgrade",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :mdForceUpgrade,
             tag: 46,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:disappearingMode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "disappearingMode",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :disappearingMode,
             tag: 47,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("disappearingMode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "disappearingMode",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :disappearingMode,
             tag: 47,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:externalMdOptInAvailable) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "externalMdOptInAvailable",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :externalMdOptInAvailable,
             tag: 48,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("externalMdOptInAvailable") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "externalMdOptInAvailable",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :externalMdOptInAvailable,
             tag: 48,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      (
        def field_def(:noDeleteMessageTimeLimit) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "noDeleteMessageTimeLimit",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :noDeleteMessageTimeLimit,
             tag: 49,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        def field_def("noDeleteMessageTimeLimit") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "noDeleteMessageTimeLimit",
             kind: {:scalar, :NOT_STARTED},
             label: :optional,
             name: :noDeleteMessageTimeLimit,
             tag: 49,
             type: {:enum, WAWebProtobufsWeb.WebFeatures.Flag}
           }}
        end

        []
      ),
      def field_def(_) do
        {:error, :no_such_field}
      end
    ]
  )

  (
    @spec unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
    def unknown_fields(msg) do
      msg.__uf__
    end

    @spec unknown_fields_name() :: :__uf__
    def unknown_fields_name() do
      :__uf__
    end

    @spec clear_unknown_fields(struct) :: struct
    def clear_unknown_fields(msg) do
      struct!(msg, [{unknown_fields_name(), []}])
    end
  )

  (
    @spec required_fields() :: []
    def required_fields() do
      []
    end
  )

  (
    @spec syntax() :: atom()
    def syntax() do
      :proto2
    end
  )

  [
    @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
    def default(:labelsDisplay) do
      {:ok, :NOT_STARTED}
    end,
    def default(:voipIndividualOutgoing) do
      {:ok, :NOT_STARTED}
    end,
    def default(:groupsV3) do
      {:ok, :NOT_STARTED}
    end,
    def default(:groupsV3Create) do
      {:ok, :NOT_STARTED}
    end,
    def default(:changeNumberV2) do
      {:ok, :NOT_STARTED}
    end,
    def default(:queryStatusV3Thumbnail) do
      {:ok, :NOT_STARTED}
    end,
    def default(:liveLocations) do
      {:ok, :NOT_STARTED}
    end,
    def default(:queryVname) do
      {:ok, :NOT_STARTED}
    end,
    def default(:voipIndividualIncoming) do
      {:ok, :NOT_STARTED}
    end,
    def default(:quickRepliesQuery) do
      {:ok, :NOT_STARTED}
    end,
    def default(:payments) do
      {:ok, :NOT_STARTED}
    end,
    def default(:stickerPackQuery) do
      {:ok, :NOT_STARTED}
    end,
    def default(:liveLocationsFinal) do
      {:ok, :NOT_STARTED}
    end,
    def default(:labelsEdit) do
      {:ok, :NOT_STARTED}
    end,
    def default(:mediaUpload) do
      {:ok, :NOT_STARTED}
    end,
    def default(:mediaUploadRichQuickReplies) do
      {:ok, :NOT_STARTED}
    end,
    def default(:vnameV2) do
      {:ok, :NOT_STARTED}
    end,
    def default(:videoPlaybackURL) do
      {:ok, :NOT_STARTED}
    end,
    def default(:statusRanking) do
      {:ok, :NOT_STARTED}
    end,
    def default(:voipIndividualVideo) do
      {:ok, :NOT_STARTED}
    end,
    def default(:thirdPartyStickers) do
      {:ok, :NOT_STARTED}
    end,
    def default(:frequentlyForwardedSetting) do
      {:ok, :NOT_STARTED}
    end,
    def default(:groupsV4JoinPermission) do
      {:ok, :NOT_STARTED}
    end,
    def default(:recentStickers) do
      {:ok, :NOT_STARTED}
    end,
    def default(:catalog) do
      {:ok, :NOT_STARTED}
    end,
    def default(:starredStickers) do
      {:ok, :NOT_STARTED}
    end,
    def default(:voipGroupCall) do
      {:ok, :NOT_STARTED}
    end,
    def default(:templateMessage) do
      {:ok, :NOT_STARTED}
    end,
    def default(:templateMessageInteractivity) do
      {:ok, :NOT_STARTED}
    end,
    def default(:ephemeralMessages) do
      {:ok, :NOT_STARTED}
    end,
    def default(:e2ENotificationSync) do
      {:ok, :NOT_STARTED}
    end,
    def default(:recentStickersV2) do
      {:ok, :NOT_STARTED}
    end,
    def default(:recentStickersV3) do
      {:ok, :NOT_STARTED}
    end,
    def default(:userNotice) do
      {:ok, :NOT_STARTED}
    end,
    def default(:support) do
      {:ok, :NOT_STARTED}
    end,
    def default(:groupUiiCleanup) do
      {:ok, :NOT_STARTED}
    end,
    def default(:groupDogfoodingInternalOnly) do
      {:ok, :NOT_STARTED}
    end,
    def default(:settingsSync) do
      {:ok, :NOT_STARTED}
    end,
    def default(:archiveV2) do
      {:ok, :NOT_STARTED}
    end,
    def default(:ephemeralAllowGroupMembers) do
      {:ok, :NOT_STARTED}
    end,
    def default(:ephemeral24HDuration) do
      {:ok, :NOT_STARTED}
    end,
    def default(:mdForceUpgrade) do
      {:ok, :NOT_STARTED}
    end,
    def default(:disappearingMode) do
      {:ok, :NOT_STARTED}
    end,
    def default(:externalMdOptInAvailable) do
      {:ok, :NOT_STARTED}
    end,
    def default(:noDeleteMessageTimeLimit) do
      {:ok, :NOT_STARTED}
    end,
    def default(_) do
      {:error, :no_such_field}
    end
  ]

  (
    @spec file_options() :: struct()
    def file_options() do
      file_options = %{
        __struct__: Protox.Google.Protobuf.FileOptions,
        __uf__: [],
        cc_enable_arenas: nil,
        cc_generic_services: nil,
        csharp_namespace: nil,
        deprecated: nil,
        go_package: "go.mau.fi/whatsmeow/proto/waWeb",
        java_generate_equals_and_hash: nil,
        java_generic_services: nil,
        java_multiple_files: nil,
        java_outer_classname: nil,
        java_package: nil,
        java_string_check_utf8: nil,
        objc_class_prefix: nil,
        optimize_for: nil,
        php_class_prefix: nil,
        php_generic_services: nil,
        php_metadata_namespace: nil,
        php_namespace: nil,
        py_generic_services: nil,
        ruby_package: nil,
        swift_prefix: nil,
        uninterpreted_option: []
      }

      case function_exported?(Google.Protobuf.FileOptions, :decode!, 1) do
        true ->
          bytes =
            file_options |> Protox.Google.Protobuf.FileOptions.encode!() |> :binary.list_to_bin()

          apply(Google.Protobuf.FileOptions, :decode!, [bytes])

        false ->
          file_options
      end
    end
  )
end
