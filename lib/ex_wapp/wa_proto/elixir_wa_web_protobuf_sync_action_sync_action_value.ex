# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.SyncActionValue do
  @moduledoc false
  defstruct timestamp: nil,
            starAction: nil,
            contactAction: nil,
            muteAction: nil,
            pinAction: nil,
            pushNameSetting: nil,
            quickReplyAction: nil,
            recentEmojiWeightsAction: nil,
            labelEditAction: nil,
            labelAssociationAction: nil,
            localeSetting: nil,
            archiveChatAction: nil,
            deleteMessageForMeAction: nil,
            keyExpiration: nil,
            markChatAsReadAction: nil,
            clearChatAction: nil,
            deleteChatAction: nil,
            unarchiveChatsSetting: nil,
            primaryFeature: nil,
            androidUnsupportedActions: nil,
            agentAction: nil,
            subscriptionAction: nil,
            userStatusMuteAction: nil,
            timeFormatAction: nil,
            nuxAction: nil,
            primaryVersionAction: nil,
            stickerAction: nil,
            removeRecentStickerAction: nil,
            chatAssignment: nil,
            chatAssignmentOpenedStatus: nil,
            pnForLidChatAction: nil,
            marketingMessageAction: nil,
            marketingMessageBroadcastAction: nil,
            externalWebBetaAction: nil,
            privacySettingRelayAllCalls: nil,
            callLogAction: nil,
            ugcBot: nil,
            statusPrivacy: nil,
            botWelcomeRequestAction: nil,
            deleteIndividualCallLog: nil,
            labelReorderingAction: nil,
            paymentInfoAction: nil,
            customPaymentMethodsAction: nil,
            lockChatAction: nil,
            chatLockSettings: nil,
            wamoUserIdentifierAction: nil,
            privacySettingDisableLinkPreviewsAction: nil,
            deviceCapabilities: nil,
            noteEditAction: nil,
            favoritesAction: nil,
            merchantPaymentPartnerAction: nil,
            waffleAccountLinkStateAction: nil,
            usernameChatStartMode: nil,
            notificationActivitySettingAction: nil,
            lidContactAction: nil,
            ctwaPerCustomerDataSharingAction: nil,
            paymentTosAction: nil,
            privacySettingChannelsPersonalisedRecommendationAction: nil,
            detectedOutcomesStatusAction: nil,
            maibaAiFeaturesControlAction: nil,
            businessBroadcastListAction: nil,
            musicUserIDAction: nil,
            statusPostOptInNotificationPreferencesAction: nil,
            avatarUpdatedAction: nil,
            privateProcessingSettingAction: nil,
            newsletterSavedInterestsAction: nil,
            aiThreadRenameAction: nil,
            interactiveMessageAction: nil,
            settingsSyncAction: nil,
            outContactAction: nil,
            nctSaltSyncAction: nil,
            businessBroadcastCampaignAction: nil,
            businessBroadcastInsightsAction: nil,
            customerDataAction: nil,
            subscriptionsSyncV2Action: nil,
            threadPinAction: nil,
            autoOrganizeBusinessChatSetting: nil,
            bizAiSettingsNudgeAction: nil,
            coexV2VersionAction: nil,
            wasaRootSecretAction: nil,
            bubbleLockMessageAction: nil,
            labelSublistAction: nil,
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
        |> encode_timestamp(msg)
        |> encode_starAction(msg)
        |> encode_contactAction(msg)
        |> encode_muteAction(msg)
        |> encode_pinAction(msg)
        |> encode_pushNameSetting(msg)
        |> encode_quickReplyAction(msg)
        |> encode_recentEmojiWeightsAction(msg)
        |> encode_labelEditAction(msg)
        |> encode_labelAssociationAction(msg)
        |> encode_localeSetting(msg)
        |> encode_archiveChatAction(msg)
        |> encode_deleteMessageForMeAction(msg)
        |> encode_keyExpiration(msg)
        |> encode_markChatAsReadAction(msg)
        |> encode_clearChatAction(msg)
        |> encode_deleteChatAction(msg)
        |> encode_unarchiveChatsSetting(msg)
        |> encode_primaryFeature(msg)
        |> encode_androidUnsupportedActions(msg)
        |> encode_agentAction(msg)
        |> encode_subscriptionAction(msg)
        |> encode_userStatusMuteAction(msg)
        |> encode_timeFormatAction(msg)
        |> encode_nuxAction(msg)
        |> encode_primaryVersionAction(msg)
        |> encode_stickerAction(msg)
        |> encode_removeRecentStickerAction(msg)
        |> encode_chatAssignment(msg)
        |> encode_chatAssignmentOpenedStatus(msg)
        |> encode_pnForLidChatAction(msg)
        |> encode_marketingMessageAction(msg)
        |> encode_marketingMessageBroadcastAction(msg)
        |> encode_externalWebBetaAction(msg)
        |> encode_privacySettingRelayAllCalls(msg)
        |> encode_callLogAction(msg)
        |> encode_ugcBot(msg)
        |> encode_statusPrivacy(msg)
        |> encode_botWelcomeRequestAction(msg)
        |> encode_deleteIndividualCallLog(msg)
        |> encode_labelReorderingAction(msg)
        |> encode_paymentInfoAction(msg)
        |> encode_customPaymentMethodsAction(msg)
        |> encode_lockChatAction(msg)
        |> encode_chatLockSettings(msg)
        |> encode_wamoUserIdentifierAction(msg)
        |> encode_privacySettingDisableLinkPreviewsAction(msg)
        |> encode_deviceCapabilities(msg)
        |> encode_noteEditAction(msg)
        |> encode_favoritesAction(msg)
        |> encode_merchantPaymentPartnerAction(msg)
        |> encode_waffleAccountLinkStateAction(msg)
        |> encode_usernameChatStartMode(msg)
        |> encode_notificationActivitySettingAction(msg)
        |> encode_lidContactAction(msg)
        |> encode_ctwaPerCustomerDataSharingAction(msg)
        |> encode_paymentTosAction(msg)
        |> encode_privacySettingChannelsPersonalisedRecommendationAction(msg)
        |> encode_detectedOutcomesStatusAction(msg)
        |> encode_maibaAiFeaturesControlAction(msg)
        |> encode_businessBroadcastListAction(msg)
        |> encode_musicUserIDAction(msg)
        |> encode_statusPostOptInNotificationPreferencesAction(msg)
        |> encode_avatarUpdatedAction(msg)
        |> encode_privateProcessingSettingAction(msg)
        |> encode_newsletterSavedInterestsAction(msg)
        |> encode_aiThreadRenameAction(msg)
        |> encode_interactiveMessageAction(msg)
        |> encode_settingsSyncAction(msg)
        |> encode_outContactAction(msg)
        |> encode_nctSaltSyncAction(msg)
        |> encode_businessBroadcastCampaignAction(msg)
        |> encode_businessBroadcastInsightsAction(msg)
        |> encode_customerDataAction(msg)
        |> encode_subscriptionsSyncV2Action(msg)
        |> encode_threadPinAction(msg)
        |> encode_autoOrganizeBusinessChatSetting(msg)
        |> encode_bizAiSettingsNudgeAction(msg)
        |> encode_coexV2VersionAction(msg)
        |> encode_wasaRootSecretAction(msg)
        |> encode_bubbleLockMessageAction(msg)
        |> encode_labelSublistAction(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_timestamp(acc, msg) do
        try do
          case msg.timestamp do
            nil -> acc
            _ -> [acc, "\b", Protox.Encode.encode_int64(msg.timestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:timestamp, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_starAction(acc, msg) do
        try do
          case msg.starAction do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_message(msg.starAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:starAction, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_contactAction(acc, msg) do
        try do
          case msg.contactAction do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_message(msg.contactAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contactAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_muteAction(acc, msg) do
        try do
          case msg.muteAction do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_message(msg.muteAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:muteAction, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pinAction(acc, msg) do
        try do
          case msg.pinAction do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_message(msg.pinAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pinAction, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pushNameSetting(acc, msg) do
        try do
          case msg.pushNameSetting do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_message(msg.pushNameSetting)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pushNameSetting, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_quickReplyAction(acc, msg) do
        try do
          case msg.quickReplyAction do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_message(msg.quickReplyAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:quickReplyAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_recentEmojiWeightsAction(acc, msg) do
        try do
          case msg.recentEmojiWeightsAction do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_message(msg.recentEmojiWeightsAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:recentEmojiWeightsAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_labelEditAction(acc, msg) do
        try do
          case msg.labelEditAction do
            nil -> acc
            _ -> [acc, "r", Protox.Encode.encode_message(msg.labelEditAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:labelEditAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_labelAssociationAction(acc, msg) do
        try do
          case msg.labelAssociationAction do
            nil -> acc
            _ -> [acc, "z", Protox.Encode.encode_message(msg.labelAssociationAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:labelAssociationAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_localeSetting(acc, msg) do
        try do
          case msg.localeSetting do
            nil -> acc
            _ -> [acc, "\x82\x01", Protox.Encode.encode_message(msg.localeSetting)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:localeSetting, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_archiveChatAction(acc, msg) do
        try do
          case msg.archiveChatAction do
            nil -> acc
            _ -> [acc, "\x8A\x01", Protox.Encode.encode_message(msg.archiveChatAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:archiveChatAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_deleteMessageForMeAction(acc, msg) do
        try do
          case msg.deleteMessageForMeAction do
            nil -> acc
            _ -> [acc, "\x92\x01", Protox.Encode.encode_message(msg.deleteMessageForMeAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deleteMessageForMeAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_keyExpiration(acc, msg) do
        try do
          case msg.keyExpiration do
            nil -> acc
            _ -> [acc, "\x9A\x01", Protox.Encode.encode_message(msg.keyExpiration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:keyExpiration, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_markChatAsReadAction(acc, msg) do
        try do
          case msg.markChatAsReadAction do
            nil -> acc
            _ -> [acc, "\xA2\x01", Protox.Encode.encode_message(msg.markChatAsReadAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:markChatAsReadAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_clearChatAction(acc, msg) do
        try do
          case msg.clearChatAction do
            nil -> acc
            _ -> [acc, "\xAA\x01", Protox.Encode.encode_message(msg.clearChatAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:clearChatAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_deleteChatAction(acc, msg) do
        try do
          case msg.deleteChatAction do
            nil -> acc
            _ -> [acc, "\xB2\x01", Protox.Encode.encode_message(msg.deleteChatAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deleteChatAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_unarchiveChatsSetting(acc, msg) do
        try do
          case msg.unarchiveChatsSetting do
            nil -> acc
            _ -> [acc, "\xBA\x01", Protox.Encode.encode_message(msg.unarchiveChatsSetting)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:unarchiveChatsSetting, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_primaryFeature(acc, msg) do
        try do
          case msg.primaryFeature do
            nil -> acc
            _ -> [acc, "\xC2\x01", Protox.Encode.encode_message(msg.primaryFeature)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:primaryFeature, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_androidUnsupportedActions(acc, msg) do
        try do
          case msg.androidUnsupportedActions do
            nil -> acc
            _ -> [acc, "\xD2\x01", Protox.Encode.encode_message(msg.androidUnsupportedActions)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:androidUnsupportedActions, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_agentAction(acc, msg) do
        try do
          case msg.agentAction do
            nil -> acc
            _ -> [acc, "\xDA\x01", Protox.Encode.encode_message(msg.agentAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:agentAction, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_subscriptionAction(acc, msg) do
        try do
          case msg.subscriptionAction do
            nil -> acc
            _ -> [acc, "\xE2\x01", Protox.Encode.encode_message(msg.subscriptionAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:subscriptionAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_userStatusMuteAction(acc, msg) do
        try do
          case msg.userStatusMuteAction do
            nil -> acc
            _ -> [acc, "\xEA\x01", Protox.Encode.encode_message(msg.userStatusMuteAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:userStatusMuteAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_timeFormatAction(acc, msg) do
        try do
          case msg.timeFormatAction do
            nil -> acc
            _ -> [acc, "\xF2\x01", Protox.Encode.encode_message(msg.timeFormatAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:timeFormatAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_nuxAction(acc, msg) do
        try do
          case msg.nuxAction do
            nil -> acc
            _ -> [acc, "\xFA\x01", Protox.Encode.encode_message(msg.nuxAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:nuxAction, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_primaryVersionAction(acc, msg) do
        try do
          case msg.primaryVersionAction do
            nil -> acc
            _ -> [acc, "\x82\x02", Protox.Encode.encode_message(msg.primaryVersionAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:primaryVersionAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_stickerAction(acc, msg) do
        try do
          case msg.stickerAction do
            nil -> acc
            _ -> [acc, "\x8A\x02", Protox.Encode.encode_message(msg.stickerAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:stickerAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_removeRecentStickerAction(acc, msg) do
        try do
          case msg.removeRecentStickerAction do
            nil -> acc
            _ -> [acc, "\x92\x02", Protox.Encode.encode_message(msg.removeRecentStickerAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:removeRecentStickerAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_chatAssignment(acc, msg) do
        try do
          case msg.chatAssignment do
            nil -> acc
            _ -> [acc, "\x9A\x02", Protox.Encode.encode_message(msg.chatAssignment)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:chatAssignment, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_chatAssignmentOpenedStatus(acc, msg) do
        try do
          case msg.chatAssignmentOpenedStatus do
            nil -> acc
            _ -> [acc, "\xA2\x02", Protox.Encode.encode_message(msg.chatAssignmentOpenedStatus)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:chatAssignmentOpenedStatus, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pnForLidChatAction(acc, msg) do
        try do
          case msg.pnForLidChatAction do
            nil -> acc
            _ -> [acc, "\xAA\x02", Protox.Encode.encode_message(msg.pnForLidChatAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pnForLidChatAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_marketingMessageAction(acc, msg) do
        try do
          case msg.marketingMessageAction do
            nil -> acc
            _ -> [acc, "\xB2\x02", Protox.Encode.encode_message(msg.marketingMessageAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:marketingMessageAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_marketingMessageBroadcastAction(acc, msg) do
        try do
          case msg.marketingMessageBroadcastAction do
            nil ->
              acc

            _ ->
              [acc, "\xBA\x02", Protox.Encode.encode_message(msg.marketingMessageBroadcastAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :marketingMessageBroadcastAction,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_externalWebBetaAction(acc, msg) do
        try do
          case msg.externalWebBetaAction do
            nil -> acc
            _ -> [acc, "\xC2\x02", Protox.Encode.encode_message(msg.externalWebBetaAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:externalWebBetaAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_privacySettingRelayAllCalls(acc, msg) do
        try do
          case msg.privacySettingRelayAllCalls do
            nil -> acc
            _ -> [acc, "\xCA\x02", Protox.Encode.encode_message(msg.privacySettingRelayAllCalls)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:privacySettingRelayAllCalls, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_callLogAction(acc, msg) do
        try do
          case msg.callLogAction do
            nil -> acc
            _ -> [acc, "\xD2\x02", Protox.Encode.encode_message(msg.callLogAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callLogAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ugcBot(acc, msg) do
        try do
          case msg.ugcBot do
            nil -> acc
            _ -> [acc, "\xDA\x02", Protox.Encode.encode_message(msg.ugcBot)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ugcBot, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_statusPrivacy(acc, msg) do
        try do
          case msg.statusPrivacy do
            nil -> acc
            _ -> [acc, "\xE2\x02", Protox.Encode.encode_message(msg.statusPrivacy)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusPrivacy, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botWelcomeRequestAction(acc, msg) do
        try do
          case msg.botWelcomeRequestAction do
            nil -> acc
            _ -> [acc, "\xEA\x02", Protox.Encode.encode_message(msg.botWelcomeRequestAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botWelcomeRequestAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_deleteIndividualCallLog(acc, msg) do
        try do
          case msg.deleteIndividualCallLog do
            nil -> acc
            _ -> [acc, "\xF2\x02", Protox.Encode.encode_message(msg.deleteIndividualCallLog)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deleteIndividualCallLog, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_labelReorderingAction(acc, msg) do
        try do
          case msg.labelReorderingAction do
            nil -> acc
            _ -> [acc, "\xFA\x02", Protox.Encode.encode_message(msg.labelReorderingAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:labelReorderingAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_paymentInfoAction(acc, msg) do
        try do
          case msg.paymentInfoAction do
            nil -> acc
            _ -> [acc, "\x82\x03", Protox.Encode.encode_message(msg.paymentInfoAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:paymentInfoAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_customPaymentMethodsAction(acc, msg) do
        try do
          case msg.customPaymentMethodsAction do
            nil -> acc
            _ -> [acc, "\x8A\x03", Protox.Encode.encode_message(msg.customPaymentMethodsAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:customPaymentMethodsAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_lockChatAction(acc, msg) do
        try do
          case msg.lockChatAction do
            nil -> acc
            _ -> [acc, "\x92\x03", Protox.Encode.encode_message(msg.lockChatAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:lockChatAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_chatLockSettings(acc, msg) do
        try do
          case msg.chatLockSettings do
            nil -> acc
            _ -> [acc, "\x9A\x03", Protox.Encode.encode_message(msg.chatLockSettings)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:chatLockSettings, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_wamoUserIdentifierAction(acc, msg) do
        try do
          case msg.wamoUserIdentifierAction do
            nil -> acc
            _ -> [acc, "\xA2\x03", Protox.Encode.encode_message(msg.wamoUserIdentifierAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:wamoUserIdentifierAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_privacySettingDisableLinkPreviewsAction(acc, msg) do
        try do
          case msg.privacySettingDisableLinkPreviewsAction do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xAA\x03",
                Protox.Encode.encode_message(msg.privacySettingDisableLinkPreviewsAction)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :privacySettingDisableLinkPreviewsAction,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_deviceCapabilities(acc, msg) do
        try do
          case msg.deviceCapabilities do
            nil -> acc
            _ -> [acc, "\xB2\x03", Protox.Encode.encode_message(msg.deviceCapabilities)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deviceCapabilities, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_noteEditAction(acc, msg) do
        try do
          case msg.noteEditAction do
            nil -> acc
            _ -> [acc, "\xBA\x03", Protox.Encode.encode_message(msg.noteEditAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:noteEditAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_favoritesAction(acc, msg) do
        try do
          case msg.favoritesAction do
            nil -> acc
            _ -> [acc, "\xC2\x03", Protox.Encode.encode_message(msg.favoritesAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:favoritesAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_merchantPaymentPartnerAction(acc, msg) do
        try do
          case msg.merchantPaymentPartnerAction do
            nil -> acc
            _ -> [acc, "\xCA\x03", Protox.Encode.encode_message(msg.merchantPaymentPartnerAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :merchantPaymentPartnerAction,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_waffleAccountLinkStateAction(acc, msg) do
        try do
          case msg.waffleAccountLinkStateAction do
            nil -> acc
            _ -> [acc, "\xD2\x03", Protox.Encode.encode_message(msg.waffleAccountLinkStateAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :waffleAccountLinkStateAction,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_usernameChatStartMode(acc, msg) do
        try do
          case msg.usernameChatStartMode do
            nil -> acc
            _ -> [acc, "\xDA\x03", Protox.Encode.encode_message(msg.usernameChatStartMode)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:usernameChatStartMode, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_notificationActivitySettingAction(acc, msg) do
        try do
          case msg.notificationActivitySettingAction do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xE2\x03",
                Protox.Encode.encode_message(msg.notificationActivitySettingAction)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :notificationActivitySettingAction,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_lidContactAction(acc, msg) do
        try do
          case msg.lidContactAction do
            nil -> acc
            _ -> [acc, "\xEA\x03", Protox.Encode.encode_message(msg.lidContactAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:lidContactAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ctwaPerCustomerDataSharingAction(acc, msg) do
        try do
          case msg.ctwaPerCustomerDataSharingAction do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xF2\x03",
                Protox.Encode.encode_message(msg.ctwaPerCustomerDataSharingAction)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :ctwaPerCustomerDataSharingAction,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_paymentTosAction(acc, msg) do
        try do
          case msg.paymentTosAction do
            nil -> acc
            _ -> [acc, "\xFA\x03", Protox.Encode.encode_message(msg.paymentTosAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:paymentTosAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_privacySettingChannelsPersonalisedRecommendationAction(acc, msg) do
        try do
          case msg.privacySettingChannelsPersonalisedRecommendationAction do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x82\x04",
                Protox.Encode.encode_message(
                  msg.privacySettingChannelsPersonalisedRecommendationAction
                )
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :privacySettingChannelsPersonalisedRecommendationAction,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_detectedOutcomesStatusAction(acc, msg) do
        try do
          case msg.detectedOutcomesStatusAction do
            nil -> acc
            _ -> [acc, "\x92\x04", Protox.Encode.encode_message(msg.detectedOutcomesStatusAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :detectedOutcomesStatusAction,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_maibaAiFeaturesControlAction(acc, msg) do
        try do
          case msg.maibaAiFeaturesControlAction do
            nil -> acc
            _ -> [acc, "\xA2\x04", Protox.Encode.encode_message(msg.maibaAiFeaturesControlAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :maibaAiFeaturesControlAction,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_businessBroadcastListAction(acc, msg) do
        try do
          case msg.businessBroadcastListAction do
            nil -> acc
            _ -> [acc, "\xAA\x04", Protox.Encode.encode_message(msg.businessBroadcastListAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:businessBroadcastListAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_musicUserIDAction(acc, msg) do
        try do
          case msg.musicUserIDAction do
            nil -> acc
            _ -> [acc, "\xB2\x04", Protox.Encode.encode_message(msg.musicUserIDAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:musicUserIDAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusPostOptInNotificationPreferencesAction(acc, msg) do
        try do
          case msg.statusPostOptInNotificationPreferencesAction do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xBA\x04",
                Protox.Encode.encode_message(msg.statusPostOptInNotificationPreferencesAction)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :statusPostOptInNotificationPreferencesAction,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_avatarUpdatedAction(acc, msg) do
        try do
          case msg.avatarUpdatedAction do
            nil -> acc
            _ -> [acc, "\xC2\x04", Protox.Encode.encode_message(msg.avatarUpdatedAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:avatarUpdatedAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_privateProcessingSettingAction(acc, msg) do
        try do
          case msg.privateProcessingSettingAction do
            nil ->
              acc

            _ ->
              [acc, "\xD2\x04", Protox.Encode.encode_message(msg.privateProcessingSettingAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :privateProcessingSettingAction,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_newsletterSavedInterestsAction(acc, msg) do
        try do
          case msg.newsletterSavedInterestsAction do
            nil ->
              acc

            _ ->
              [acc, "\xDA\x04", Protox.Encode.encode_message(msg.newsletterSavedInterestsAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :newsletterSavedInterestsAction,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_aiThreadRenameAction(acc, msg) do
        try do
          case msg.aiThreadRenameAction do
            nil -> acc
            _ -> [acc, "\xE2\x04", Protox.Encode.encode_message(msg.aiThreadRenameAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:aiThreadRenameAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_interactiveMessageAction(acc, msg) do
        try do
          case msg.interactiveMessageAction do
            nil -> acc
            _ -> [acc, "\xEA\x04", Protox.Encode.encode_message(msg.interactiveMessageAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:interactiveMessageAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_settingsSyncAction(acc, msg) do
        try do
          case msg.settingsSyncAction do
            nil -> acc
            _ -> [acc, "\xF2\x04", Protox.Encode.encode_message(msg.settingsSyncAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:settingsSyncAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_outContactAction(acc, msg) do
        try do
          case msg.outContactAction do
            nil -> acc
            _ -> [acc, "\xFA\x04", Protox.Encode.encode_message(msg.outContactAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:outContactAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_nctSaltSyncAction(acc, msg) do
        try do
          case msg.nctSaltSyncAction do
            nil -> acc
            _ -> [acc, "\x82\x05", Protox.Encode.encode_message(msg.nctSaltSyncAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:nctSaltSyncAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_businessBroadcastCampaignAction(acc, msg) do
        try do
          case msg.businessBroadcastCampaignAction do
            nil ->
              acc

            _ ->
              [acc, "\x8A\x05", Protox.Encode.encode_message(msg.businessBroadcastCampaignAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :businessBroadcastCampaignAction,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_businessBroadcastInsightsAction(acc, msg) do
        try do
          case msg.businessBroadcastInsightsAction do
            nil ->
              acc

            _ ->
              [acc, "\x92\x05", Protox.Encode.encode_message(msg.businessBroadcastInsightsAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :businessBroadcastInsightsAction,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_customerDataAction(acc, msg) do
        try do
          case msg.customerDataAction do
            nil -> acc
            _ -> [acc, "\x9A\x05", Protox.Encode.encode_message(msg.customerDataAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:customerDataAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_subscriptionsSyncV2Action(acc, msg) do
        try do
          case msg.subscriptionsSyncV2Action do
            nil -> acc
            _ -> [acc, "\xA2\x05", Protox.Encode.encode_message(msg.subscriptionsSyncV2Action)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:subscriptionsSyncV2Action, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_threadPinAction(acc, msg) do
        try do
          case msg.threadPinAction do
            nil -> acc
            _ -> [acc, "\xAA\x05", Protox.Encode.encode_message(msg.threadPinAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:threadPinAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_autoOrganizeBusinessChatSetting(acc, msg) do
        try do
          case msg.autoOrganizeBusinessChatSetting do
            nil ->
              acc

            _ ->
              [acc, "\xB2\x05", Protox.Encode.encode_message(msg.autoOrganizeBusinessChatSetting)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :autoOrganizeBusinessChatSetting,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_bizAiSettingsNudgeAction(acc, msg) do
        try do
          case msg.bizAiSettingsNudgeAction do
            nil -> acc
            _ -> [acc, "\xBA\x05", Protox.Encode.encode_message(msg.bizAiSettingsNudgeAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:bizAiSettingsNudgeAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_coexV2VersionAction(acc, msg) do
        try do
          case msg.coexV2VersionAction do
            nil -> acc
            _ -> [acc, "\xC2\x05", Protox.Encode.encode_message(msg.coexV2VersionAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:coexV2VersionAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_wasaRootSecretAction(acc, msg) do
        try do
          case msg.wasaRootSecretAction do
            nil -> acc
            _ -> [acc, "\xCA\x05", Protox.Encode.encode_message(msg.wasaRootSecretAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:wasaRootSecretAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_bubbleLockMessageAction(acc, msg) do
        try do
          case msg.bubbleLockMessageAction do
            nil -> acc
            _ -> [acc, "\xD2\x05", Protox.Encode.encode_message(msg.bubbleLockMessageAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:bubbleLockMessageAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_labelSublistAction(acc, msg) do
        try do
          case msg.labelSublistAction do
            nil -> acc
            _ -> [acc, "\xDA\x05", Protox.Encode.encode_message(msg.labelSublistAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:labelSublistAction, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufSyncAction.SyncActionValue))
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
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[timestamp: value], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 starAction:
                   Protox.MergeMessage.merge(
                     msg.starAction,
                     WAWebProtobufSyncAction.StarAction.decode!(delimited)
                   )
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 contactAction:
                   Protox.MergeMessage.merge(
                     msg.contactAction,
                     WAWebProtobufSyncAction.ContactAction.decode!(delimited)
                   )
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 muteAction:
                   Protox.MergeMessage.merge(
                     msg.muteAction,
                     WAWebProtobufSyncAction.MuteAction.decode!(delimited)
                   )
               ], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pinAction:
                   Protox.MergeMessage.merge(
                     msg.pinAction,
                     WAWebProtobufSyncAction.PinAction.decode!(delimited)
                   )
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pushNameSetting:
                   Protox.MergeMessage.merge(
                     msg.pushNameSetting,
                     WAWebProtobufSyncAction.PushNameSetting.decode!(delimited)
                   )
               ], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 quickReplyAction:
                   Protox.MergeMessage.merge(
                     msg.quickReplyAction,
                     WAWebProtobufSyncAction.QuickReplyAction.decode!(delimited)
                   )
               ], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 recentEmojiWeightsAction:
                   Protox.MergeMessage.merge(
                     msg.recentEmojiWeightsAction,
                     WAWebProtobufSyncAction.RecentEmojiWeightsAction.decode!(delimited)
                   )
               ], rest}

            {14, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 labelEditAction:
                   Protox.MergeMessage.merge(
                     msg.labelEditAction,
                     WAWebProtobufSyncAction.LabelEditAction.decode!(delimited)
                   )
               ], rest}

            {15, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 labelAssociationAction:
                   Protox.MergeMessage.merge(
                     msg.labelAssociationAction,
                     WAWebProtobufSyncAction.LabelAssociationAction.decode!(delimited)
                   )
               ], rest}

            {16, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 localeSetting:
                   Protox.MergeMessage.merge(
                     msg.localeSetting,
                     WAWebProtobufSyncAction.LocaleSetting.decode!(delimited)
                   )
               ], rest}

            {17, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 archiveChatAction:
                   Protox.MergeMessage.merge(
                     msg.archiveChatAction,
                     WAWebProtobufSyncAction.ArchiveChatAction.decode!(delimited)
                   )
               ], rest}

            {18, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 deleteMessageForMeAction:
                   Protox.MergeMessage.merge(
                     msg.deleteMessageForMeAction,
                     WAWebProtobufSyncAction.DeleteMessageForMeAction.decode!(delimited)
                   )
               ], rest}

            {19, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 keyExpiration:
                   Protox.MergeMessage.merge(
                     msg.keyExpiration,
                     WAWebProtobufSyncAction.KeyExpiration.decode!(delimited)
                   )
               ], rest}

            {20, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 markChatAsReadAction:
                   Protox.MergeMessage.merge(
                     msg.markChatAsReadAction,
                     WAWebProtobufSyncAction.MarkChatAsReadAction.decode!(delimited)
                   )
               ], rest}

            {21, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 clearChatAction:
                   Protox.MergeMessage.merge(
                     msg.clearChatAction,
                     WAWebProtobufSyncAction.ClearChatAction.decode!(delimited)
                   )
               ], rest}

            {22, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 deleteChatAction:
                   Protox.MergeMessage.merge(
                     msg.deleteChatAction,
                     WAWebProtobufSyncAction.DeleteChatAction.decode!(delimited)
                   )
               ], rest}

            {23, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 unarchiveChatsSetting:
                   Protox.MergeMessage.merge(
                     msg.unarchiveChatsSetting,
                     WAWebProtobufSyncAction.UnarchiveChatsSetting.decode!(delimited)
                   )
               ], rest}

            {24, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 primaryFeature:
                   Protox.MergeMessage.merge(
                     msg.primaryFeature,
                     WAWebProtobufSyncAction.PrimaryFeature.decode!(delimited)
                   )
               ], rest}

            {26, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 androidUnsupportedActions:
                   Protox.MergeMessage.merge(
                     msg.androidUnsupportedActions,
                     WAWebProtobufSyncAction.AndroidUnsupportedActions.decode!(delimited)
                   )
               ], rest}

            {27, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 agentAction:
                   Protox.MergeMessage.merge(
                     msg.agentAction,
                     WAWebProtobufSyncAction.AgentAction.decode!(delimited)
                   )
               ], rest}

            {28, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 subscriptionAction:
                   Protox.MergeMessage.merge(
                     msg.subscriptionAction,
                     WAWebProtobufSyncAction.SubscriptionAction.decode!(delimited)
                   )
               ], rest}

            {29, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 userStatusMuteAction:
                   Protox.MergeMessage.merge(
                     msg.userStatusMuteAction,
                     WAWebProtobufSyncAction.UserStatusMuteAction.decode!(delimited)
                   )
               ], rest}

            {30, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 timeFormatAction:
                   Protox.MergeMessage.merge(
                     msg.timeFormatAction,
                     WAWebProtobufSyncAction.TimeFormatAction.decode!(delimited)
                   )
               ], rest}

            {31, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 nuxAction:
                   Protox.MergeMessage.merge(
                     msg.nuxAction,
                     WAWebProtobufSyncAction.NuxAction.decode!(delimited)
                   )
               ], rest}

            {32, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 primaryVersionAction:
                   Protox.MergeMessage.merge(
                     msg.primaryVersionAction,
                     WAWebProtobufSyncAction.PrimaryVersionAction.decode!(delimited)
                   )
               ], rest}

            {33, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 stickerAction:
                   Protox.MergeMessage.merge(
                     msg.stickerAction,
                     WAWebProtobufSyncAction.StickerAction.decode!(delimited)
                   )
               ], rest}

            {34, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 removeRecentStickerAction:
                   Protox.MergeMessage.merge(
                     msg.removeRecentStickerAction,
                     WAWebProtobufSyncAction.RemoveRecentStickerAction.decode!(delimited)
                   )
               ], rest}

            {35, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 chatAssignment:
                   Protox.MergeMessage.merge(
                     msg.chatAssignment,
                     WAWebProtobufSyncAction.ChatAssignmentAction.decode!(delimited)
                   )
               ], rest}

            {36, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 chatAssignmentOpenedStatus:
                   Protox.MergeMessage.merge(
                     msg.chatAssignmentOpenedStatus,
                     WAWebProtobufSyncAction.ChatAssignmentOpenedStatusAction.decode!(delimited)
                   )
               ], rest}

            {37, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pnForLidChatAction:
                   Protox.MergeMessage.merge(
                     msg.pnForLidChatAction,
                     WAWebProtobufSyncAction.PnForLidChatAction.decode!(delimited)
                   )
               ], rest}

            {38, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 marketingMessageAction:
                   Protox.MergeMessage.merge(
                     msg.marketingMessageAction,
                     WAWebProtobufSyncAction.MarketingMessageAction.decode!(delimited)
                   )
               ], rest}

            {39, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 marketingMessageBroadcastAction:
                   Protox.MergeMessage.merge(
                     msg.marketingMessageBroadcastAction,
                     WAWebProtobufSyncAction.MarketingMessageBroadcastAction.decode!(delimited)
                   )
               ], rest}

            {40, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 externalWebBetaAction:
                   Protox.MergeMessage.merge(
                     msg.externalWebBetaAction,
                     WAWebProtobufSyncAction.ExternalWebBetaAction.decode!(delimited)
                   )
               ], rest}

            {41, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 privacySettingRelayAllCalls:
                   Protox.MergeMessage.merge(
                     msg.privacySettingRelayAllCalls,
                     WAWebProtobufSyncAction.PrivacySettingRelayAllCalls.decode!(delimited)
                   )
               ], rest}

            {42, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 callLogAction:
                   Protox.MergeMessage.merge(
                     msg.callLogAction,
                     WAWebProtobufSyncAction.CallLogAction.decode!(delimited)
                   )
               ], rest}

            {43, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 ugcBot:
                   Protox.MergeMessage.merge(
                     msg.ugcBot,
                     WAWebProtobufSyncAction.UGCBot.decode!(delimited)
                   )
               ], rest}

            {44, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 statusPrivacy:
                   Protox.MergeMessage.merge(
                     msg.statusPrivacy,
                     WAWebProtobufSyncAction.StatusPrivacyAction.decode!(delimited)
                   )
               ], rest}

            {45, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botWelcomeRequestAction:
                   Protox.MergeMessage.merge(
                     msg.botWelcomeRequestAction,
                     WAWebProtobufSyncAction.BotWelcomeRequestAction.decode!(delimited)
                   )
               ], rest}

            {46, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 deleteIndividualCallLog:
                   Protox.MergeMessage.merge(
                     msg.deleteIndividualCallLog,
                     WAWebProtobufSyncAction.DeleteIndividualCallLogAction.decode!(delimited)
                   )
               ], rest}

            {47, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 labelReorderingAction:
                   Protox.MergeMessage.merge(
                     msg.labelReorderingAction,
                     WAWebProtobufSyncAction.LabelReorderingAction.decode!(delimited)
                   )
               ], rest}

            {48, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 paymentInfoAction:
                   Protox.MergeMessage.merge(
                     msg.paymentInfoAction,
                     WAWebProtobufSyncAction.PaymentInfoAction.decode!(delimited)
                   )
               ], rest}

            {49, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 customPaymentMethodsAction:
                   Protox.MergeMessage.merge(
                     msg.customPaymentMethodsAction,
                     WAWebProtobufSyncAction.CustomPaymentMethodsAction.decode!(delimited)
                   )
               ], rest}

            {50, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 lockChatAction:
                   Protox.MergeMessage.merge(
                     msg.lockChatAction,
                     WAWebProtobufSyncAction.LockChatAction.decode!(delimited)
                   )
               ], rest}

            {51, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 chatLockSettings:
                   Protox.MergeMessage.merge(
                     msg.chatLockSettings,
                     WAWebProtobufsChatLockSettings.ChatLockSettings.decode!(delimited)
                   )
               ], rest}

            {52, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 wamoUserIdentifierAction:
                   Protox.MergeMessage.merge(
                     msg.wamoUserIdentifierAction,
                     WAWebProtobufSyncAction.WamoUserIdentifierAction.decode!(delimited)
                   )
               ], rest}

            {53, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 privacySettingDisableLinkPreviewsAction:
                   Protox.MergeMessage.merge(
                     msg.privacySettingDisableLinkPreviewsAction,
                     WAWebProtobufSyncAction.PrivacySettingDisableLinkPreviewsAction.decode!(
                       delimited
                     )
                   )
               ], rest}

            {54, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 deviceCapabilities:
                   Protox.MergeMessage.merge(
                     msg.deviceCapabilities,
                     WAWebProtobufsDeviceCapabilities.DeviceCapabilities.decode!(delimited)
                   )
               ], rest}

            {55, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 noteEditAction:
                   Protox.MergeMessage.merge(
                     msg.noteEditAction,
                     WAWebProtobufSyncAction.NoteEditAction.decode!(delimited)
                   )
               ], rest}

            {56, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 favoritesAction:
                   Protox.MergeMessage.merge(
                     msg.favoritesAction,
                     WAWebProtobufSyncAction.FavoritesAction.decode!(delimited)
                   )
               ], rest}

            {57, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 merchantPaymentPartnerAction:
                   Protox.MergeMessage.merge(
                     msg.merchantPaymentPartnerAction,
                     WAWebProtobufSyncAction.MerchantPaymentPartnerAction.decode!(delimited)
                   )
               ], rest}

            {58, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 waffleAccountLinkStateAction:
                   Protox.MergeMessage.merge(
                     msg.waffleAccountLinkStateAction,
                     WAWebProtobufSyncAction.WaffleAccountLinkStateAction.decode!(delimited)
                   )
               ], rest}

            {59, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 usernameChatStartMode:
                   Protox.MergeMessage.merge(
                     msg.usernameChatStartMode,
                     WAWebProtobufSyncAction.UsernameChatStartModeAction.decode!(delimited)
                   )
               ], rest}

            {60, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 notificationActivitySettingAction:
                   Protox.MergeMessage.merge(
                     msg.notificationActivitySettingAction,
                     WAWebProtobufSyncAction.NotificationActivitySettingAction.decode!(delimited)
                   )
               ], rest}

            {61, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 lidContactAction:
                   Protox.MergeMessage.merge(
                     msg.lidContactAction,
                     WAWebProtobufSyncAction.LidContactAction.decode!(delimited)
                   )
               ], rest}

            {62, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 ctwaPerCustomerDataSharingAction:
                   Protox.MergeMessage.merge(
                     msg.ctwaPerCustomerDataSharingAction,
                     WAWebProtobufSyncAction.CtwaPerCustomerDataSharingAction.decode!(delimited)
                   )
               ], rest}

            {63, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 paymentTosAction:
                   Protox.MergeMessage.merge(
                     msg.paymentTosAction,
                     WAWebProtobufSyncAction.PaymentTosAction.decode!(delimited)
                   )
               ], rest}

            {64, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 privacySettingChannelsPersonalisedRecommendationAction:
                   Protox.MergeMessage.merge(
                     msg.privacySettingChannelsPersonalisedRecommendationAction,
                     WAWebProtobufSyncAction.PrivacySettingChannelsPersonalisedRecommendationAction.decode!(
                       delimited
                     )
                   )
               ], rest}

            {66, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 detectedOutcomesStatusAction:
                   Protox.MergeMessage.merge(
                     msg.detectedOutcomesStatusAction,
                     WAWebProtobufSyncAction.DetectedOutcomesStatusAction.decode!(delimited)
                   )
               ], rest}

            {68, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 maibaAiFeaturesControlAction:
                   Protox.MergeMessage.merge(
                     msg.maibaAiFeaturesControlAction,
                     WAWebProtobufSyncAction.MaibaAIFeaturesControlAction.decode!(delimited)
                   )
               ], rest}

            {69, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 businessBroadcastListAction:
                   Protox.MergeMessage.merge(
                     msg.businessBroadcastListAction,
                     WAWebProtobufSyncAction.BusinessBroadcastListAction.decode!(delimited)
                   )
               ], rest}

            {70, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 musicUserIDAction:
                   Protox.MergeMessage.merge(
                     msg.musicUserIDAction,
                     WAWebProtobufSyncAction.MusicUserIdAction.decode!(delimited)
                   )
               ], rest}

            {71, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 statusPostOptInNotificationPreferencesAction:
                   Protox.MergeMessage.merge(
                     msg.statusPostOptInNotificationPreferencesAction,
                     WAWebProtobufSyncAction.StatusPostOptInNotificationPreferencesAction.decode!(
                       delimited
                     )
                   )
               ], rest}

            {72, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 avatarUpdatedAction:
                   Protox.MergeMessage.merge(
                     msg.avatarUpdatedAction,
                     WAWebProtobufSyncAction.AvatarUpdatedAction.decode!(delimited)
                   )
               ], rest}

            {74, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 privateProcessingSettingAction:
                   Protox.MergeMessage.merge(
                     msg.privateProcessingSettingAction,
                     WAWebProtobufSyncAction.PrivateProcessingSettingAction.decode!(delimited)
                   )
               ], rest}

            {75, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 newsletterSavedInterestsAction:
                   Protox.MergeMessage.merge(
                     msg.newsletterSavedInterestsAction,
                     WAWebProtobufSyncAction.NewsletterSavedInterestsAction.decode!(delimited)
                   )
               ], rest}

            {76, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 aiThreadRenameAction:
                   Protox.MergeMessage.merge(
                     msg.aiThreadRenameAction,
                     WAWebProtobufSyncAction.AiThreadRenameAction.decode!(delimited)
                   )
               ], rest}

            {77, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 interactiveMessageAction:
                   Protox.MergeMessage.merge(
                     msg.interactiveMessageAction,
                     WAWebProtobufSyncAction.InteractiveMessageAction.decode!(delimited)
                   )
               ], rest}

            {78, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 settingsSyncAction:
                   Protox.MergeMessage.merge(
                     msg.settingsSyncAction,
                     WAWebProtobufSyncAction.SettingsSyncAction.decode!(delimited)
                   )
               ], rest}

            {79, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 outContactAction:
                   Protox.MergeMessage.merge(
                     msg.outContactAction,
                     WAWebProtobufSyncAction.OutContactAction.decode!(delimited)
                   )
               ], rest}

            {80, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 nctSaltSyncAction:
                   Protox.MergeMessage.merge(
                     msg.nctSaltSyncAction,
                     WAWebProtobufSyncAction.NctSaltSyncAction.decode!(delimited)
                   )
               ], rest}

            {81, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 businessBroadcastCampaignAction:
                   Protox.MergeMessage.merge(
                     msg.businessBroadcastCampaignAction,
                     WAWebProtobufSyncAction.BusinessBroadcastCampaignAction.decode!(delimited)
                   )
               ], rest}

            {82, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 businessBroadcastInsightsAction:
                   Protox.MergeMessage.merge(
                     msg.businessBroadcastInsightsAction,
                     WAWebProtobufSyncAction.BusinessBroadcastInsightsAction.decode!(delimited)
                   )
               ], rest}

            {83, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 customerDataAction:
                   Protox.MergeMessage.merge(
                     msg.customerDataAction,
                     WAWebProtobufSyncAction.CustomerDataAction.decode!(delimited)
                   )
               ], rest}

            {84, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 subscriptionsSyncV2Action:
                   Protox.MergeMessage.merge(
                     msg.subscriptionsSyncV2Action,
                     WAWebProtobufSyncAction.SubscriptionsSyncV2Action.decode!(delimited)
                   )
               ], rest}

            {85, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 threadPinAction:
                   Protox.MergeMessage.merge(
                     msg.threadPinAction,
                     WAWebProtobufSyncAction.ThreadPinAction.decode!(delimited)
                   )
               ], rest}

            {86, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 autoOrganizeBusinessChatSetting:
                   Protox.MergeMessage.merge(
                     msg.autoOrganizeBusinessChatSetting,
                     WAWebProtobufSyncAction.AutoOrganizeBusinessChatSetting.decode!(delimited)
                   )
               ], rest}

            {87, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 bizAiSettingsNudgeAction:
                   Protox.MergeMessage.merge(
                     msg.bizAiSettingsNudgeAction,
                     WAWebProtobufSyncAction.BizAISettingsNudgeAction.decode!(delimited)
                   )
               ], rest}

            {88, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 coexV2VersionAction:
                   Protox.MergeMessage.merge(
                     msg.coexV2VersionAction,
                     WAWebProtobufSyncAction.CoexV2VersionAction.decode!(delimited)
                   )
               ], rest}

            {89, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 wasaRootSecretAction:
                   Protox.MergeMessage.merge(
                     msg.wasaRootSecretAction,
                     WAWebProtobufSyncAction.WASARootSecretAction.decode!(delimited)
                   )
               ], rest}

            {90, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 bubbleLockMessageAction:
                   Protox.MergeMessage.merge(
                     msg.bubbleLockMessageAction,
                     WAWebProtobufSyncAction.BubbleLockMessageAction.decode!(delimited)
                   )
               ], rest}

            {91, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 labelSublistAction:
                   Protox.MergeMessage.merge(
                     msg.labelSublistAction,
                     WAWebProtobufSyncAction.LabelSublistAction.decode!(delimited)
                   )
               ], rest}

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
        WAWebProtobufSyncAction.SyncActionValue,
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
        1 => {:timestamp, {:scalar, 0}, :int64},
        2 => {:starAction, {:scalar, nil}, {:message, WAWebProtobufSyncAction.StarAction}},
        3 => {:contactAction, {:scalar, nil}, {:message, WAWebProtobufSyncAction.ContactAction}},
        4 => {:muteAction, {:scalar, nil}, {:message, WAWebProtobufSyncAction.MuteAction}},
        5 => {:pinAction, {:scalar, nil}, {:message, WAWebProtobufSyncAction.PinAction}},
        7 =>
          {:pushNameSetting, {:scalar, nil}, {:message, WAWebProtobufSyncAction.PushNameSetting}},
        8 =>
          {:quickReplyAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.QuickReplyAction}},
        11 =>
          {:recentEmojiWeightsAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.RecentEmojiWeightsAction}},
        14 =>
          {:labelEditAction, {:scalar, nil}, {:message, WAWebProtobufSyncAction.LabelEditAction}},
        15 =>
          {:labelAssociationAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.LabelAssociationAction}},
        16 => {:localeSetting, {:scalar, nil}, {:message, WAWebProtobufSyncAction.LocaleSetting}},
        17 =>
          {:archiveChatAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.ArchiveChatAction}},
        18 =>
          {:deleteMessageForMeAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.DeleteMessageForMeAction}},
        19 => {:keyExpiration, {:scalar, nil}, {:message, WAWebProtobufSyncAction.KeyExpiration}},
        20 =>
          {:markChatAsReadAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.MarkChatAsReadAction}},
        21 =>
          {:clearChatAction, {:scalar, nil}, {:message, WAWebProtobufSyncAction.ClearChatAction}},
        22 =>
          {:deleteChatAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.DeleteChatAction}},
        23 =>
          {:unarchiveChatsSetting, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.UnarchiveChatsSetting}},
        24 =>
          {:primaryFeature, {:scalar, nil}, {:message, WAWebProtobufSyncAction.PrimaryFeature}},
        26 =>
          {:androidUnsupportedActions, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.AndroidUnsupportedActions}},
        27 => {:agentAction, {:scalar, nil}, {:message, WAWebProtobufSyncAction.AgentAction}},
        28 =>
          {:subscriptionAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.SubscriptionAction}},
        29 =>
          {:userStatusMuteAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.UserStatusMuteAction}},
        30 =>
          {:timeFormatAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.TimeFormatAction}},
        31 => {:nuxAction, {:scalar, nil}, {:message, WAWebProtobufSyncAction.NuxAction}},
        32 =>
          {:primaryVersionAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.PrimaryVersionAction}},
        33 => {:stickerAction, {:scalar, nil}, {:message, WAWebProtobufSyncAction.StickerAction}},
        34 =>
          {:removeRecentStickerAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.RemoveRecentStickerAction}},
        35 =>
          {:chatAssignment, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.ChatAssignmentAction}},
        36 =>
          {:chatAssignmentOpenedStatus, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.ChatAssignmentOpenedStatusAction}},
        37 =>
          {:pnForLidChatAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.PnForLidChatAction}},
        38 =>
          {:marketingMessageAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.MarketingMessageAction}},
        39 =>
          {:marketingMessageBroadcastAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.MarketingMessageBroadcastAction}},
        40 =>
          {:externalWebBetaAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.ExternalWebBetaAction}},
        41 =>
          {:privacySettingRelayAllCalls, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.PrivacySettingRelayAllCalls}},
        42 => {:callLogAction, {:scalar, nil}, {:message, WAWebProtobufSyncAction.CallLogAction}},
        43 => {:ugcBot, {:scalar, nil}, {:message, WAWebProtobufSyncAction.UGCBot}},
        44 =>
          {:statusPrivacy, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.StatusPrivacyAction}},
        45 =>
          {:botWelcomeRequestAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.BotWelcomeRequestAction}},
        46 =>
          {:deleteIndividualCallLog, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.DeleteIndividualCallLogAction}},
        47 =>
          {:labelReorderingAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.LabelReorderingAction}},
        48 =>
          {:paymentInfoAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.PaymentInfoAction}},
        49 =>
          {:customPaymentMethodsAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.CustomPaymentMethodsAction}},
        50 =>
          {:lockChatAction, {:scalar, nil}, {:message, WAWebProtobufSyncAction.LockChatAction}},
        51 =>
          {:chatLockSettings, {:scalar, nil},
           {:message, WAWebProtobufsChatLockSettings.ChatLockSettings}},
        52 =>
          {:wamoUserIdentifierAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.WamoUserIdentifierAction}},
        53 =>
          {:privacySettingDisableLinkPreviewsAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.PrivacySettingDisableLinkPreviewsAction}},
        54 =>
          {:deviceCapabilities, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities}},
        55 =>
          {:noteEditAction, {:scalar, nil}, {:message, WAWebProtobufSyncAction.NoteEditAction}},
        56 =>
          {:favoritesAction, {:scalar, nil}, {:message, WAWebProtobufSyncAction.FavoritesAction}},
        57 =>
          {:merchantPaymentPartnerAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.MerchantPaymentPartnerAction}},
        58 =>
          {:waffleAccountLinkStateAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.WaffleAccountLinkStateAction}},
        59 =>
          {:usernameChatStartMode, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.UsernameChatStartModeAction}},
        60 =>
          {:notificationActivitySettingAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.NotificationActivitySettingAction}},
        61 =>
          {:lidContactAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.LidContactAction}},
        62 =>
          {:ctwaPerCustomerDataSharingAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.CtwaPerCustomerDataSharingAction}},
        63 =>
          {:paymentTosAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.PaymentTosAction}},
        64 =>
          {:privacySettingChannelsPersonalisedRecommendationAction, {:scalar, nil},
           {:message,
            WAWebProtobufSyncAction.PrivacySettingChannelsPersonalisedRecommendationAction}},
        66 =>
          {:detectedOutcomesStatusAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.DetectedOutcomesStatusAction}},
        68 =>
          {:maibaAiFeaturesControlAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.MaibaAIFeaturesControlAction}},
        69 =>
          {:businessBroadcastListAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.BusinessBroadcastListAction}},
        70 =>
          {:musicUserIDAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.MusicUserIdAction}},
        71 =>
          {:statusPostOptInNotificationPreferencesAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.StatusPostOptInNotificationPreferencesAction}},
        72 =>
          {:avatarUpdatedAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.AvatarUpdatedAction}},
        74 =>
          {:privateProcessingSettingAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.PrivateProcessingSettingAction}},
        75 =>
          {:newsletterSavedInterestsAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.NewsletterSavedInterestsAction}},
        76 =>
          {:aiThreadRenameAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.AiThreadRenameAction}},
        77 =>
          {:interactiveMessageAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.InteractiveMessageAction}},
        78 =>
          {:settingsSyncAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.SettingsSyncAction}},
        79 =>
          {:outContactAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.OutContactAction}},
        80 =>
          {:nctSaltSyncAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.NctSaltSyncAction}},
        81 =>
          {:businessBroadcastCampaignAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.BusinessBroadcastCampaignAction}},
        82 =>
          {:businessBroadcastInsightsAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.BusinessBroadcastInsightsAction}},
        83 =>
          {:customerDataAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.CustomerDataAction}},
        84 =>
          {:subscriptionsSyncV2Action, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.SubscriptionsSyncV2Action}},
        85 =>
          {:threadPinAction, {:scalar, nil}, {:message, WAWebProtobufSyncAction.ThreadPinAction}},
        86 =>
          {:autoOrganizeBusinessChatSetting, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.AutoOrganizeBusinessChatSetting}},
        87 =>
          {:bizAiSettingsNudgeAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.BizAISettingsNudgeAction}},
        88 =>
          {:coexV2VersionAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.CoexV2VersionAction}},
        89 =>
          {:wasaRootSecretAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.WASARootSecretAction}},
        90 =>
          {:bubbleLockMessageAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.BubbleLockMessageAction}},
        91 =>
          {:labelSublistAction, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.LabelSublistAction}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        agentAction: {27, {:scalar, nil}, {:message, WAWebProtobufSyncAction.AgentAction}},
        aiThreadRenameAction:
          {76, {:scalar, nil}, {:message, WAWebProtobufSyncAction.AiThreadRenameAction}},
        androidUnsupportedActions:
          {26, {:scalar, nil}, {:message, WAWebProtobufSyncAction.AndroidUnsupportedActions}},
        archiveChatAction:
          {17, {:scalar, nil}, {:message, WAWebProtobufSyncAction.ArchiveChatAction}},
        autoOrganizeBusinessChatSetting:
          {86, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.AutoOrganizeBusinessChatSetting}},
        avatarUpdatedAction:
          {72, {:scalar, nil}, {:message, WAWebProtobufSyncAction.AvatarUpdatedAction}},
        bizAiSettingsNudgeAction:
          {87, {:scalar, nil}, {:message, WAWebProtobufSyncAction.BizAISettingsNudgeAction}},
        botWelcomeRequestAction:
          {45, {:scalar, nil}, {:message, WAWebProtobufSyncAction.BotWelcomeRequestAction}},
        bubbleLockMessageAction:
          {90, {:scalar, nil}, {:message, WAWebProtobufSyncAction.BubbleLockMessageAction}},
        businessBroadcastCampaignAction:
          {81, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.BusinessBroadcastCampaignAction}},
        businessBroadcastInsightsAction:
          {82, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.BusinessBroadcastInsightsAction}},
        businessBroadcastListAction:
          {69, {:scalar, nil}, {:message, WAWebProtobufSyncAction.BusinessBroadcastListAction}},
        callLogAction: {42, {:scalar, nil}, {:message, WAWebProtobufSyncAction.CallLogAction}},
        chatAssignment:
          {35, {:scalar, nil}, {:message, WAWebProtobufSyncAction.ChatAssignmentAction}},
        chatAssignmentOpenedStatus:
          {36, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.ChatAssignmentOpenedStatusAction}},
        chatLockSettings:
          {51, {:scalar, nil}, {:message, WAWebProtobufsChatLockSettings.ChatLockSettings}},
        clearChatAction:
          {21, {:scalar, nil}, {:message, WAWebProtobufSyncAction.ClearChatAction}},
        coexV2VersionAction:
          {88, {:scalar, nil}, {:message, WAWebProtobufSyncAction.CoexV2VersionAction}},
        contactAction: {3, {:scalar, nil}, {:message, WAWebProtobufSyncAction.ContactAction}},
        ctwaPerCustomerDataSharingAction:
          {62, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.CtwaPerCustomerDataSharingAction}},
        customPaymentMethodsAction:
          {49, {:scalar, nil}, {:message, WAWebProtobufSyncAction.CustomPaymentMethodsAction}},
        customerDataAction:
          {83, {:scalar, nil}, {:message, WAWebProtobufSyncAction.CustomerDataAction}},
        deleteChatAction:
          {22, {:scalar, nil}, {:message, WAWebProtobufSyncAction.DeleteChatAction}},
        deleteIndividualCallLog:
          {46, {:scalar, nil}, {:message, WAWebProtobufSyncAction.DeleteIndividualCallLogAction}},
        deleteMessageForMeAction:
          {18, {:scalar, nil}, {:message, WAWebProtobufSyncAction.DeleteMessageForMeAction}},
        detectedOutcomesStatusAction:
          {66, {:scalar, nil}, {:message, WAWebProtobufSyncAction.DetectedOutcomesStatusAction}},
        deviceCapabilities:
          {54, {:scalar, nil}, {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities}},
        externalWebBetaAction:
          {40, {:scalar, nil}, {:message, WAWebProtobufSyncAction.ExternalWebBetaAction}},
        favoritesAction:
          {56, {:scalar, nil}, {:message, WAWebProtobufSyncAction.FavoritesAction}},
        interactiveMessageAction:
          {77, {:scalar, nil}, {:message, WAWebProtobufSyncAction.InteractiveMessageAction}},
        keyExpiration: {19, {:scalar, nil}, {:message, WAWebProtobufSyncAction.KeyExpiration}},
        labelAssociationAction:
          {15, {:scalar, nil}, {:message, WAWebProtobufSyncAction.LabelAssociationAction}},
        labelEditAction:
          {14, {:scalar, nil}, {:message, WAWebProtobufSyncAction.LabelEditAction}},
        labelReorderingAction:
          {47, {:scalar, nil}, {:message, WAWebProtobufSyncAction.LabelReorderingAction}},
        labelSublistAction:
          {91, {:scalar, nil}, {:message, WAWebProtobufSyncAction.LabelSublistAction}},
        lidContactAction:
          {61, {:scalar, nil}, {:message, WAWebProtobufSyncAction.LidContactAction}},
        localeSetting: {16, {:scalar, nil}, {:message, WAWebProtobufSyncAction.LocaleSetting}},
        lockChatAction: {50, {:scalar, nil}, {:message, WAWebProtobufSyncAction.LockChatAction}},
        maibaAiFeaturesControlAction:
          {68, {:scalar, nil}, {:message, WAWebProtobufSyncAction.MaibaAIFeaturesControlAction}},
        markChatAsReadAction:
          {20, {:scalar, nil}, {:message, WAWebProtobufSyncAction.MarkChatAsReadAction}},
        marketingMessageAction:
          {38, {:scalar, nil}, {:message, WAWebProtobufSyncAction.MarketingMessageAction}},
        marketingMessageBroadcastAction:
          {39, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.MarketingMessageBroadcastAction}},
        merchantPaymentPartnerAction:
          {57, {:scalar, nil}, {:message, WAWebProtobufSyncAction.MerchantPaymentPartnerAction}},
        musicUserIDAction:
          {70, {:scalar, nil}, {:message, WAWebProtobufSyncAction.MusicUserIdAction}},
        muteAction: {4, {:scalar, nil}, {:message, WAWebProtobufSyncAction.MuteAction}},
        nctSaltSyncAction:
          {80, {:scalar, nil}, {:message, WAWebProtobufSyncAction.NctSaltSyncAction}},
        newsletterSavedInterestsAction:
          {75, {:scalar, nil}, {:message, WAWebProtobufSyncAction.NewsletterSavedInterestsAction}},
        noteEditAction: {55, {:scalar, nil}, {:message, WAWebProtobufSyncAction.NoteEditAction}},
        notificationActivitySettingAction:
          {60, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.NotificationActivitySettingAction}},
        nuxAction: {31, {:scalar, nil}, {:message, WAWebProtobufSyncAction.NuxAction}},
        outContactAction:
          {79, {:scalar, nil}, {:message, WAWebProtobufSyncAction.OutContactAction}},
        paymentInfoAction:
          {48, {:scalar, nil}, {:message, WAWebProtobufSyncAction.PaymentInfoAction}},
        paymentTosAction:
          {63, {:scalar, nil}, {:message, WAWebProtobufSyncAction.PaymentTosAction}},
        pinAction: {5, {:scalar, nil}, {:message, WAWebProtobufSyncAction.PinAction}},
        pnForLidChatAction:
          {37, {:scalar, nil}, {:message, WAWebProtobufSyncAction.PnForLidChatAction}},
        primaryFeature: {24, {:scalar, nil}, {:message, WAWebProtobufSyncAction.PrimaryFeature}},
        primaryVersionAction:
          {32, {:scalar, nil}, {:message, WAWebProtobufSyncAction.PrimaryVersionAction}},
        privacySettingChannelsPersonalisedRecommendationAction:
          {64, {:scalar, nil},
           {:message,
            WAWebProtobufSyncAction.PrivacySettingChannelsPersonalisedRecommendationAction}},
        privacySettingDisableLinkPreviewsAction:
          {53, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.PrivacySettingDisableLinkPreviewsAction}},
        privacySettingRelayAllCalls:
          {41, {:scalar, nil}, {:message, WAWebProtobufSyncAction.PrivacySettingRelayAllCalls}},
        privateProcessingSettingAction:
          {74, {:scalar, nil}, {:message, WAWebProtobufSyncAction.PrivateProcessingSettingAction}},
        pushNameSetting: {7, {:scalar, nil}, {:message, WAWebProtobufSyncAction.PushNameSetting}},
        quickReplyAction:
          {8, {:scalar, nil}, {:message, WAWebProtobufSyncAction.QuickReplyAction}},
        recentEmojiWeightsAction:
          {11, {:scalar, nil}, {:message, WAWebProtobufSyncAction.RecentEmojiWeightsAction}},
        removeRecentStickerAction:
          {34, {:scalar, nil}, {:message, WAWebProtobufSyncAction.RemoveRecentStickerAction}},
        settingsSyncAction:
          {78, {:scalar, nil}, {:message, WAWebProtobufSyncAction.SettingsSyncAction}},
        starAction: {2, {:scalar, nil}, {:message, WAWebProtobufSyncAction.StarAction}},
        statusPostOptInNotificationPreferencesAction:
          {71, {:scalar, nil},
           {:message, WAWebProtobufSyncAction.StatusPostOptInNotificationPreferencesAction}},
        statusPrivacy:
          {44, {:scalar, nil}, {:message, WAWebProtobufSyncAction.StatusPrivacyAction}},
        stickerAction: {33, {:scalar, nil}, {:message, WAWebProtobufSyncAction.StickerAction}},
        subscriptionAction:
          {28, {:scalar, nil}, {:message, WAWebProtobufSyncAction.SubscriptionAction}},
        subscriptionsSyncV2Action:
          {84, {:scalar, nil}, {:message, WAWebProtobufSyncAction.SubscriptionsSyncV2Action}},
        threadPinAction:
          {85, {:scalar, nil}, {:message, WAWebProtobufSyncAction.ThreadPinAction}},
        timeFormatAction:
          {30, {:scalar, nil}, {:message, WAWebProtobufSyncAction.TimeFormatAction}},
        timestamp: {1, {:scalar, 0}, :int64},
        ugcBot: {43, {:scalar, nil}, {:message, WAWebProtobufSyncAction.UGCBot}},
        unarchiveChatsSetting:
          {23, {:scalar, nil}, {:message, WAWebProtobufSyncAction.UnarchiveChatsSetting}},
        userStatusMuteAction:
          {29, {:scalar, nil}, {:message, WAWebProtobufSyncAction.UserStatusMuteAction}},
        usernameChatStartMode:
          {59, {:scalar, nil}, {:message, WAWebProtobufSyncAction.UsernameChatStartModeAction}},
        waffleAccountLinkStateAction:
          {58, {:scalar, nil}, {:message, WAWebProtobufSyncAction.WaffleAccountLinkStateAction}},
        wamoUserIdentifierAction:
          {52, {:scalar, nil}, {:message, WAWebProtobufSyncAction.WamoUserIdentifierAction}},
        wasaRootSecretAction:
          {89, {:scalar, nil}, {:message, WAWebProtobufSyncAction.WASARootSecretAction}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "timestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :timestamp,
          tag: 1,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "starAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :starAction,
          tag: 2,
          type: {:message, WAWebProtobufSyncAction.StarAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "contactAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :contactAction,
          tag: 3,
          type: {:message, WAWebProtobufSyncAction.ContactAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "muteAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :muteAction,
          tag: 4,
          type: {:message, WAWebProtobufSyncAction.MuteAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pinAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :pinAction,
          tag: 5,
          type: {:message, WAWebProtobufSyncAction.PinAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pushNameSetting",
          kind: {:scalar, nil},
          label: :optional,
          name: :pushNameSetting,
          tag: 7,
          type: {:message, WAWebProtobufSyncAction.PushNameSetting}
        },
        %{
          __struct__: Protox.Field,
          json_name: "quickReplyAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :quickReplyAction,
          tag: 8,
          type: {:message, WAWebProtobufSyncAction.QuickReplyAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "recentEmojiWeightsAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :recentEmojiWeightsAction,
          tag: 11,
          type: {:message, WAWebProtobufSyncAction.RecentEmojiWeightsAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "labelEditAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :labelEditAction,
          tag: 14,
          type: {:message, WAWebProtobufSyncAction.LabelEditAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "labelAssociationAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :labelAssociationAction,
          tag: 15,
          type: {:message, WAWebProtobufSyncAction.LabelAssociationAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "localeSetting",
          kind: {:scalar, nil},
          label: :optional,
          name: :localeSetting,
          tag: 16,
          type: {:message, WAWebProtobufSyncAction.LocaleSetting}
        },
        %{
          __struct__: Protox.Field,
          json_name: "archiveChatAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :archiveChatAction,
          tag: 17,
          type: {:message, WAWebProtobufSyncAction.ArchiveChatAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "deleteMessageForMeAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :deleteMessageForMeAction,
          tag: 18,
          type: {:message, WAWebProtobufSyncAction.DeleteMessageForMeAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "keyExpiration",
          kind: {:scalar, nil},
          label: :optional,
          name: :keyExpiration,
          tag: 19,
          type: {:message, WAWebProtobufSyncAction.KeyExpiration}
        },
        %{
          __struct__: Protox.Field,
          json_name: "markChatAsReadAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :markChatAsReadAction,
          tag: 20,
          type: {:message, WAWebProtobufSyncAction.MarkChatAsReadAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "clearChatAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :clearChatAction,
          tag: 21,
          type: {:message, WAWebProtobufSyncAction.ClearChatAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "deleteChatAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :deleteChatAction,
          tag: 22,
          type: {:message, WAWebProtobufSyncAction.DeleteChatAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "unarchiveChatsSetting",
          kind: {:scalar, nil},
          label: :optional,
          name: :unarchiveChatsSetting,
          tag: 23,
          type: {:message, WAWebProtobufSyncAction.UnarchiveChatsSetting}
        },
        %{
          __struct__: Protox.Field,
          json_name: "primaryFeature",
          kind: {:scalar, nil},
          label: :optional,
          name: :primaryFeature,
          tag: 24,
          type: {:message, WAWebProtobufSyncAction.PrimaryFeature}
        },
        %{
          __struct__: Protox.Field,
          json_name: "androidUnsupportedActions",
          kind: {:scalar, nil},
          label: :optional,
          name: :androidUnsupportedActions,
          tag: 26,
          type: {:message, WAWebProtobufSyncAction.AndroidUnsupportedActions}
        },
        %{
          __struct__: Protox.Field,
          json_name: "agentAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :agentAction,
          tag: 27,
          type: {:message, WAWebProtobufSyncAction.AgentAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "subscriptionAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :subscriptionAction,
          tag: 28,
          type: {:message, WAWebProtobufSyncAction.SubscriptionAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "userStatusMuteAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :userStatusMuteAction,
          tag: 29,
          type: {:message, WAWebProtobufSyncAction.UserStatusMuteAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "timeFormatAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :timeFormatAction,
          tag: 30,
          type: {:message, WAWebProtobufSyncAction.TimeFormatAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "nuxAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :nuxAction,
          tag: 31,
          type: {:message, WAWebProtobufSyncAction.NuxAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "primaryVersionAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :primaryVersionAction,
          tag: 32,
          type: {:message, WAWebProtobufSyncAction.PrimaryVersionAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "stickerAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :stickerAction,
          tag: 33,
          type: {:message, WAWebProtobufSyncAction.StickerAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "removeRecentStickerAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :removeRecentStickerAction,
          tag: 34,
          type: {:message, WAWebProtobufSyncAction.RemoveRecentStickerAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "chatAssignment",
          kind: {:scalar, nil},
          label: :optional,
          name: :chatAssignment,
          tag: 35,
          type: {:message, WAWebProtobufSyncAction.ChatAssignmentAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "chatAssignmentOpenedStatus",
          kind: {:scalar, nil},
          label: :optional,
          name: :chatAssignmentOpenedStatus,
          tag: 36,
          type: {:message, WAWebProtobufSyncAction.ChatAssignmentOpenedStatusAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pnForLidChatAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :pnForLidChatAction,
          tag: 37,
          type: {:message, WAWebProtobufSyncAction.PnForLidChatAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "marketingMessageAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :marketingMessageAction,
          tag: 38,
          type: {:message, WAWebProtobufSyncAction.MarketingMessageAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "marketingMessageBroadcastAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :marketingMessageBroadcastAction,
          tag: 39,
          type: {:message, WAWebProtobufSyncAction.MarketingMessageBroadcastAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "externalWebBetaAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :externalWebBetaAction,
          tag: 40,
          type: {:message, WAWebProtobufSyncAction.ExternalWebBetaAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "privacySettingRelayAllCalls",
          kind: {:scalar, nil},
          label: :optional,
          name: :privacySettingRelayAllCalls,
          tag: 41,
          type: {:message, WAWebProtobufSyncAction.PrivacySettingRelayAllCalls}
        },
        %{
          __struct__: Protox.Field,
          json_name: "callLogAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :callLogAction,
          tag: 42,
          type: {:message, WAWebProtobufSyncAction.CallLogAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "ugcBot",
          kind: {:scalar, nil},
          label: :optional,
          name: :ugcBot,
          tag: 43,
          type: {:message, WAWebProtobufSyncAction.UGCBot}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusPrivacy",
          kind: {:scalar, nil},
          label: :optional,
          name: :statusPrivacy,
          tag: 44,
          type: {:message, WAWebProtobufSyncAction.StatusPrivacyAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botWelcomeRequestAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :botWelcomeRequestAction,
          tag: 45,
          type: {:message, WAWebProtobufSyncAction.BotWelcomeRequestAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "deleteIndividualCallLog",
          kind: {:scalar, nil},
          label: :optional,
          name: :deleteIndividualCallLog,
          tag: 46,
          type: {:message, WAWebProtobufSyncAction.DeleteIndividualCallLogAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "labelReorderingAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :labelReorderingAction,
          tag: 47,
          type: {:message, WAWebProtobufSyncAction.LabelReorderingAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "paymentInfoAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :paymentInfoAction,
          tag: 48,
          type: {:message, WAWebProtobufSyncAction.PaymentInfoAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "customPaymentMethodsAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :customPaymentMethodsAction,
          tag: 49,
          type: {:message, WAWebProtobufSyncAction.CustomPaymentMethodsAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "lockChatAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :lockChatAction,
          tag: 50,
          type: {:message, WAWebProtobufSyncAction.LockChatAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "chatLockSettings",
          kind: {:scalar, nil},
          label: :optional,
          name: :chatLockSettings,
          tag: 51,
          type: {:message, WAWebProtobufsChatLockSettings.ChatLockSettings}
        },
        %{
          __struct__: Protox.Field,
          json_name: "wamoUserIdentifierAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :wamoUserIdentifierAction,
          tag: 52,
          type: {:message, WAWebProtobufSyncAction.WamoUserIdentifierAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "privacySettingDisableLinkPreviewsAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :privacySettingDisableLinkPreviewsAction,
          tag: 53,
          type: {:message, WAWebProtobufSyncAction.PrivacySettingDisableLinkPreviewsAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "deviceCapabilities",
          kind: {:scalar, nil},
          label: :optional,
          name: :deviceCapabilities,
          tag: 54,
          type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities}
        },
        %{
          __struct__: Protox.Field,
          json_name: "noteEditAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :noteEditAction,
          tag: 55,
          type: {:message, WAWebProtobufSyncAction.NoteEditAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "favoritesAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :favoritesAction,
          tag: 56,
          type: {:message, WAWebProtobufSyncAction.FavoritesAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "merchantPaymentPartnerAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :merchantPaymentPartnerAction,
          tag: 57,
          type: {:message, WAWebProtobufSyncAction.MerchantPaymentPartnerAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "waffleAccountLinkStateAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :waffleAccountLinkStateAction,
          tag: 58,
          type: {:message, WAWebProtobufSyncAction.WaffleAccountLinkStateAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "usernameChatStartMode",
          kind: {:scalar, nil},
          label: :optional,
          name: :usernameChatStartMode,
          tag: 59,
          type: {:message, WAWebProtobufSyncAction.UsernameChatStartModeAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "notificationActivitySettingAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :notificationActivitySettingAction,
          tag: 60,
          type: {:message, WAWebProtobufSyncAction.NotificationActivitySettingAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "lidContactAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :lidContactAction,
          tag: 61,
          type: {:message, WAWebProtobufSyncAction.LidContactAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "ctwaPerCustomerDataSharingAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :ctwaPerCustomerDataSharingAction,
          tag: 62,
          type: {:message, WAWebProtobufSyncAction.CtwaPerCustomerDataSharingAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "paymentTosAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :paymentTosAction,
          tag: 63,
          type: {:message, WAWebProtobufSyncAction.PaymentTosAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "privacySettingChannelsPersonalisedRecommendationAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :privacySettingChannelsPersonalisedRecommendationAction,
          tag: 64,
          type:
            {:message,
             WAWebProtobufSyncAction.PrivacySettingChannelsPersonalisedRecommendationAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "detectedOutcomesStatusAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :detectedOutcomesStatusAction,
          tag: 66,
          type: {:message, WAWebProtobufSyncAction.DetectedOutcomesStatusAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "maibaAiFeaturesControlAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :maibaAiFeaturesControlAction,
          tag: 68,
          type: {:message, WAWebProtobufSyncAction.MaibaAIFeaturesControlAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "businessBroadcastListAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :businessBroadcastListAction,
          tag: 69,
          type: {:message, WAWebProtobufSyncAction.BusinessBroadcastListAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "musicUserIDAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :musicUserIDAction,
          tag: 70,
          type: {:message, WAWebProtobufSyncAction.MusicUserIdAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusPostOptInNotificationPreferencesAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :statusPostOptInNotificationPreferencesAction,
          tag: 71,
          type: {:message, WAWebProtobufSyncAction.StatusPostOptInNotificationPreferencesAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "avatarUpdatedAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :avatarUpdatedAction,
          tag: 72,
          type: {:message, WAWebProtobufSyncAction.AvatarUpdatedAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "privateProcessingSettingAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :privateProcessingSettingAction,
          tag: 74,
          type: {:message, WAWebProtobufSyncAction.PrivateProcessingSettingAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "newsletterSavedInterestsAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :newsletterSavedInterestsAction,
          tag: 75,
          type: {:message, WAWebProtobufSyncAction.NewsletterSavedInterestsAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "aiThreadRenameAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :aiThreadRenameAction,
          tag: 76,
          type: {:message, WAWebProtobufSyncAction.AiThreadRenameAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "interactiveMessageAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :interactiveMessageAction,
          tag: 77,
          type: {:message, WAWebProtobufSyncAction.InteractiveMessageAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "settingsSyncAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :settingsSyncAction,
          tag: 78,
          type: {:message, WAWebProtobufSyncAction.SettingsSyncAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "outContactAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :outContactAction,
          tag: 79,
          type: {:message, WAWebProtobufSyncAction.OutContactAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "nctSaltSyncAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :nctSaltSyncAction,
          tag: 80,
          type: {:message, WAWebProtobufSyncAction.NctSaltSyncAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "businessBroadcastCampaignAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :businessBroadcastCampaignAction,
          tag: 81,
          type: {:message, WAWebProtobufSyncAction.BusinessBroadcastCampaignAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "businessBroadcastInsightsAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :businessBroadcastInsightsAction,
          tag: 82,
          type: {:message, WAWebProtobufSyncAction.BusinessBroadcastInsightsAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "customerDataAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :customerDataAction,
          tag: 83,
          type: {:message, WAWebProtobufSyncAction.CustomerDataAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "subscriptionsSyncV2Action",
          kind: {:scalar, nil},
          label: :optional,
          name: :subscriptionsSyncV2Action,
          tag: 84,
          type: {:message, WAWebProtobufSyncAction.SubscriptionsSyncV2Action}
        },
        %{
          __struct__: Protox.Field,
          json_name: "threadPinAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :threadPinAction,
          tag: 85,
          type: {:message, WAWebProtobufSyncAction.ThreadPinAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "autoOrganizeBusinessChatSetting",
          kind: {:scalar, nil},
          label: :optional,
          name: :autoOrganizeBusinessChatSetting,
          tag: 86,
          type: {:message, WAWebProtobufSyncAction.AutoOrganizeBusinessChatSetting}
        },
        %{
          __struct__: Protox.Field,
          json_name: "bizAiSettingsNudgeAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :bizAiSettingsNudgeAction,
          tag: 87,
          type: {:message, WAWebProtobufSyncAction.BizAISettingsNudgeAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "coexV2VersionAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :coexV2VersionAction,
          tag: 88,
          type: {:message, WAWebProtobufSyncAction.CoexV2VersionAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "wasaRootSecretAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :wasaRootSecretAction,
          tag: 89,
          type: {:message, WAWebProtobufSyncAction.WASARootSecretAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "bubbleLockMessageAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :bubbleLockMessageAction,
          tag: 90,
          type: {:message, WAWebProtobufSyncAction.BubbleLockMessageAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "labelSublistAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :labelSublistAction,
          tag: 91,
          type: {:message, WAWebProtobufSyncAction.LabelSublistAction}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:timestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "timestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :timestamp,
             tag: 1,
             type: :int64
           }}
        end

        def field_def("timestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "timestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :timestamp,
             tag: 1,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:starAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "starAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :starAction,
             tag: 2,
             type: {:message, WAWebProtobufSyncAction.StarAction}
           }}
        end

        def field_def("starAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "starAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :starAction,
             tag: 2,
             type: {:message, WAWebProtobufSyncAction.StarAction}
           }}
        end

        []
      ),
      (
        def field_def(:contactAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contactAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :contactAction,
             tag: 3,
             type: {:message, WAWebProtobufSyncAction.ContactAction}
           }}
        end

        def field_def("contactAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contactAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :contactAction,
             tag: 3,
             type: {:message, WAWebProtobufSyncAction.ContactAction}
           }}
        end

        []
      ),
      (
        def field_def(:muteAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "muteAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :muteAction,
             tag: 4,
             type: {:message, WAWebProtobufSyncAction.MuteAction}
           }}
        end

        def field_def("muteAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "muteAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :muteAction,
             tag: 4,
             type: {:message, WAWebProtobufSyncAction.MuteAction}
           }}
        end

        []
      ),
      (
        def field_def(:pinAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pinAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :pinAction,
             tag: 5,
             type: {:message, WAWebProtobufSyncAction.PinAction}
           }}
        end

        def field_def("pinAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pinAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :pinAction,
             tag: 5,
             type: {:message, WAWebProtobufSyncAction.PinAction}
           }}
        end

        []
      ),
      (
        def field_def(:pushNameSetting) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pushNameSetting",
             kind: {:scalar, nil},
             label: :optional,
             name: :pushNameSetting,
             tag: 7,
             type: {:message, WAWebProtobufSyncAction.PushNameSetting}
           }}
        end

        def field_def("pushNameSetting") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pushNameSetting",
             kind: {:scalar, nil},
             label: :optional,
             name: :pushNameSetting,
             tag: 7,
             type: {:message, WAWebProtobufSyncAction.PushNameSetting}
           }}
        end

        []
      ),
      (
        def field_def(:quickReplyAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quickReplyAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :quickReplyAction,
             tag: 8,
             type: {:message, WAWebProtobufSyncAction.QuickReplyAction}
           }}
        end

        def field_def("quickReplyAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quickReplyAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :quickReplyAction,
             tag: 8,
             type: {:message, WAWebProtobufSyncAction.QuickReplyAction}
           }}
        end

        []
      ),
      (
        def field_def(:recentEmojiWeightsAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recentEmojiWeightsAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :recentEmojiWeightsAction,
             tag: 11,
             type: {:message, WAWebProtobufSyncAction.RecentEmojiWeightsAction}
           }}
        end

        def field_def("recentEmojiWeightsAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recentEmojiWeightsAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :recentEmojiWeightsAction,
             tag: 11,
             type: {:message, WAWebProtobufSyncAction.RecentEmojiWeightsAction}
           }}
        end

        []
      ),
      (
        def field_def(:labelEditAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "labelEditAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :labelEditAction,
             tag: 14,
             type: {:message, WAWebProtobufSyncAction.LabelEditAction}
           }}
        end

        def field_def("labelEditAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "labelEditAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :labelEditAction,
             tag: 14,
             type: {:message, WAWebProtobufSyncAction.LabelEditAction}
           }}
        end

        []
      ),
      (
        def field_def(:labelAssociationAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "labelAssociationAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :labelAssociationAction,
             tag: 15,
             type: {:message, WAWebProtobufSyncAction.LabelAssociationAction}
           }}
        end

        def field_def("labelAssociationAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "labelAssociationAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :labelAssociationAction,
             tag: 15,
             type: {:message, WAWebProtobufSyncAction.LabelAssociationAction}
           }}
        end

        []
      ),
      (
        def field_def(:localeSetting) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "localeSetting",
             kind: {:scalar, nil},
             label: :optional,
             name: :localeSetting,
             tag: 16,
             type: {:message, WAWebProtobufSyncAction.LocaleSetting}
           }}
        end

        def field_def("localeSetting") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "localeSetting",
             kind: {:scalar, nil},
             label: :optional,
             name: :localeSetting,
             tag: 16,
             type: {:message, WAWebProtobufSyncAction.LocaleSetting}
           }}
        end

        []
      ),
      (
        def field_def(:archiveChatAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "archiveChatAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :archiveChatAction,
             tag: 17,
             type: {:message, WAWebProtobufSyncAction.ArchiveChatAction}
           }}
        end

        def field_def("archiveChatAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "archiveChatAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :archiveChatAction,
             tag: 17,
             type: {:message, WAWebProtobufSyncAction.ArchiveChatAction}
           }}
        end

        []
      ),
      (
        def field_def(:deleteMessageForMeAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deleteMessageForMeAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :deleteMessageForMeAction,
             tag: 18,
             type: {:message, WAWebProtobufSyncAction.DeleteMessageForMeAction}
           }}
        end

        def field_def("deleteMessageForMeAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deleteMessageForMeAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :deleteMessageForMeAction,
             tag: 18,
             type: {:message, WAWebProtobufSyncAction.DeleteMessageForMeAction}
           }}
        end

        []
      ),
      (
        def field_def(:keyExpiration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "keyExpiration",
             kind: {:scalar, nil},
             label: :optional,
             name: :keyExpiration,
             tag: 19,
             type: {:message, WAWebProtobufSyncAction.KeyExpiration}
           }}
        end

        def field_def("keyExpiration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "keyExpiration",
             kind: {:scalar, nil},
             label: :optional,
             name: :keyExpiration,
             tag: 19,
             type: {:message, WAWebProtobufSyncAction.KeyExpiration}
           }}
        end

        []
      ),
      (
        def field_def(:markChatAsReadAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "markChatAsReadAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :markChatAsReadAction,
             tag: 20,
             type: {:message, WAWebProtobufSyncAction.MarkChatAsReadAction}
           }}
        end

        def field_def("markChatAsReadAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "markChatAsReadAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :markChatAsReadAction,
             tag: 20,
             type: {:message, WAWebProtobufSyncAction.MarkChatAsReadAction}
           }}
        end

        []
      ),
      (
        def field_def(:clearChatAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "clearChatAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :clearChatAction,
             tag: 21,
             type: {:message, WAWebProtobufSyncAction.ClearChatAction}
           }}
        end

        def field_def("clearChatAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "clearChatAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :clearChatAction,
             tag: 21,
             type: {:message, WAWebProtobufSyncAction.ClearChatAction}
           }}
        end

        []
      ),
      (
        def field_def(:deleteChatAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deleteChatAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :deleteChatAction,
             tag: 22,
             type: {:message, WAWebProtobufSyncAction.DeleteChatAction}
           }}
        end

        def field_def("deleteChatAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deleteChatAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :deleteChatAction,
             tag: 22,
             type: {:message, WAWebProtobufSyncAction.DeleteChatAction}
           }}
        end

        []
      ),
      (
        def field_def(:unarchiveChatsSetting) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "unarchiveChatsSetting",
             kind: {:scalar, nil},
             label: :optional,
             name: :unarchiveChatsSetting,
             tag: 23,
             type: {:message, WAWebProtobufSyncAction.UnarchiveChatsSetting}
           }}
        end

        def field_def("unarchiveChatsSetting") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "unarchiveChatsSetting",
             kind: {:scalar, nil},
             label: :optional,
             name: :unarchiveChatsSetting,
             tag: 23,
             type: {:message, WAWebProtobufSyncAction.UnarchiveChatsSetting}
           }}
        end

        []
      ),
      (
        def field_def(:primaryFeature) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "primaryFeature",
             kind: {:scalar, nil},
             label: :optional,
             name: :primaryFeature,
             tag: 24,
             type: {:message, WAWebProtobufSyncAction.PrimaryFeature}
           }}
        end

        def field_def("primaryFeature") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "primaryFeature",
             kind: {:scalar, nil},
             label: :optional,
             name: :primaryFeature,
             tag: 24,
             type: {:message, WAWebProtobufSyncAction.PrimaryFeature}
           }}
        end

        []
      ),
      (
        def field_def(:androidUnsupportedActions) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "androidUnsupportedActions",
             kind: {:scalar, nil},
             label: :optional,
             name: :androidUnsupportedActions,
             tag: 26,
             type: {:message, WAWebProtobufSyncAction.AndroidUnsupportedActions}
           }}
        end

        def field_def("androidUnsupportedActions") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "androidUnsupportedActions",
             kind: {:scalar, nil},
             label: :optional,
             name: :androidUnsupportedActions,
             tag: 26,
             type: {:message, WAWebProtobufSyncAction.AndroidUnsupportedActions}
           }}
        end

        []
      ),
      (
        def field_def(:agentAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "agentAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :agentAction,
             tag: 27,
             type: {:message, WAWebProtobufSyncAction.AgentAction}
           }}
        end

        def field_def("agentAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "agentAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :agentAction,
             tag: 27,
             type: {:message, WAWebProtobufSyncAction.AgentAction}
           }}
        end

        []
      ),
      (
        def field_def(:subscriptionAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "subscriptionAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :subscriptionAction,
             tag: 28,
             type: {:message, WAWebProtobufSyncAction.SubscriptionAction}
           }}
        end

        def field_def("subscriptionAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "subscriptionAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :subscriptionAction,
             tag: 28,
             type: {:message, WAWebProtobufSyncAction.SubscriptionAction}
           }}
        end

        []
      ),
      (
        def field_def(:userStatusMuteAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "userStatusMuteAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :userStatusMuteAction,
             tag: 29,
             type: {:message, WAWebProtobufSyncAction.UserStatusMuteAction}
           }}
        end

        def field_def("userStatusMuteAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "userStatusMuteAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :userStatusMuteAction,
             tag: 29,
             type: {:message, WAWebProtobufSyncAction.UserStatusMuteAction}
           }}
        end

        []
      ),
      (
        def field_def(:timeFormatAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "timeFormatAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :timeFormatAction,
             tag: 30,
             type: {:message, WAWebProtobufSyncAction.TimeFormatAction}
           }}
        end

        def field_def("timeFormatAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "timeFormatAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :timeFormatAction,
             tag: 30,
             type: {:message, WAWebProtobufSyncAction.TimeFormatAction}
           }}
        end

        []
      ),
      (
        def field_def(:nuxAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nuxAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :nuxAction,
             tag: 31,
             type: {:message, WAWebProtobufSyncAction.NuxAction}
           }}
        end

        def field_def("nuxAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nuxAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :nuxAction,
             tag: 31,
             type: {:message, WAWebProtobufSyncAction.NuxAction}
           }}
        end

        []
      ),
      (
        def field_def(:primaryVersionAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "primaryVersionAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :primaryVersionAction,
             tag: 32,
             type: {:message, WAWebProtobufSyncAction.PrimaryVersionAction}
           }}
        end

        def field_def("primaryVersionAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "primaryVersionAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :primaryVersionAction,
             tag: 32,
             type: {:message, WAWebProtobufSyncAction.PrimaryVersionAction}
           }}
        end

        []
      ),
      (
        def field_def(:stickerAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :stickerAction,
             tag: 33,
             type: {:message, WAWebProtobufSyncAction.StickerAction}
           }}
        end

        def field_def("stickerAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :stickerAction,
             tag: 33,
             type: {:message, WAWebProtobufSyncAction.StickerAction}
           }}
        end

        []
      ),
      (
        def field_def(:removeRecentStickerAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "removeRecentStickerAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :removeRecentStickerAction,
             tag: 34,
             type: {:message, WAWebProtobufSyncAction.RemoveRecentStickerAction}
           }}
        end

        def field_def("removeRecentStickerAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "removeRecentStickerAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :removeRecentStickerAction,
             tag: 34,
             type: {:message, WAWebProtobufSyncAction.RemoveRecentStickerAction}
           }}
        end

        []
      ),
      (
        def field_def(:chatAssignment) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatAssignment",
             kind: {:scalar, nil},
             label: :optional,
             name: :chatAssignment,
             tag: 35,
             type: {:message, WAWebProtobufSyncAction.ChatAssignmentAction}
           }}
        end

        def field_def("chatAssignment") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatAssignment",
             kind: {:scalar, nil},
             label: :optional,
             name: :chatAssignment,
             tag: 35,
             type: {:message, WAWebProtobufSyncAction.ChatAssignmentAction}
           }}
        end

        []
      ),
      (
        def field_def(:chatAssignmentOpenedStatus) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatAssignmentOpenedStatus",
             kind: {:scalar, nil},
             label: :optional,
             name: :chatAssignmentOpenedStatus,
             tag: 36,
             type: {:message, WAWebProtobufSyncAction.ChatAssignmentOpenedStatusAction}
           }}
        end

        def field_def("chatAssignmentOpenedStatus") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatAssignmentOpenedStatus",
             kind: {:scalar, nil},
             label: :optional,
             name: :chatAssignmentOpenedStatus,
             tag: 36,
             type: {:message, WAWebProtobufSyncAction.ChatAssignmentOpenedStatusAction}
           }}
        end

        []
      ),
      (
        def field_def(:pnForLidChatAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pnForLidChatAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :pnForLidChatAction,
             tag: 37,
             type: {:message, WAWebProtobufSyncAction.PnForLidChatAction}
           }}
        end

        def field_def("pnForLidChatAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pnForLidChatAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :pnForLidChatAction,
             tag: 37,
             type: {:message, WAWebProtobufSyncAction.PnForLidChatAction}
           }}
        end

        []
      ),
      (
        def field_def(:marketingMessageAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "marketingMessageAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :marketingMessageAction,
             tag: 38,
             type: {:message, WAWebProtobufSyncAction.MarketingMessageAction}
           }}
        end

        def field_def("marketingMessageAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "marketingMessageAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :marketingMessageAction,
             tag: 38,
             type: {:message, WAWebProtobufSyncAction.MarketingMessageAction}
           }}
        end

        []
      ),
      (
        def field_def(:marketingMessageBroadcastAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "marketingMessageBroadcastAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :marketingMessageBroadcastAction,
             tag: 39,
             type: {:message, WAWebProtobufSyncAction.MarketingMessageBroadcastAction}
           }}
        end

        def field_def("marketingMessageBroadcastAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "marketingMessageBroadcastAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :marketingMessageBroadcastAction,
             tag: 39,
             type: {:message, WAWebProtobufSyncAction.MarketingMessageBroadcastAction}
           }}
        end

        []
      ),
      (
        def field_def(:externalWebBetaAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "externalWebBetaAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :externalWebBetaAction,
             tag: 40,
             type: {:message, WAWebProtobufSyncAction.ExternalWebBetaAction}
           }}
        end

        def field_def("externalWebBetaAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "externalWebBetaAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :externalWebBetaAction,
             tag: 40,
             type: {:message, WAWebProtobufSyncAction.ExternalWebBetaAction}
           }}
        end

        []
      ),
      (
        def field_def(:privacySettingRelayAllCalls) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "privacySettingRelayAllCalls",
             kind: {:scalar, nil},
             label: :optional,
             name: :privacySettingRelayAllCalls,
             tag: 41,
             type: {:message, WAWebProtobufSyncAction.PrivacySettingRelayAllCalls}
           }}
        end

        def field_def("privacySettingRelayAllCalls") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "privacySettingRelayAllCalls",
             kind: {:scalar, nil},
             label: :optional,
             name: :privacySettingRelayAllCalls,
             tag: 41,
             type: {:message, WAWebProtobufSyncAction.PrivacySettingRelayAllCalls}
           }}
        end

        []
      ),
      (
        def field_def(:callLogAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callLogAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :callLogAction,
             tag: 42,
             type: {:message, WAWebProtobufSyncAction.CallLogAction}
           }}
        end

        def field_def("callLogAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callLogAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :callLogAction,
             tag: 42,
             type: {:message, WAWebProtobufSyncAction.CallLogAction}
           }}
        end

        []
      ),
      (
        def field_def(:ugcBot) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ugcBot",
             kind: {:scalar, nil},
             label: :optional,
             name: :ugcBot,
             tag: 43,
             type: {:message, WAWebProtobufSyncAction.UGCBot}
           }}
        end

        def field_def("ugcBot") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ugcBot",
             kind: {:scalar, nil},
             label: :optional,
             name: :ugcBot,
             tag: 43,
             type: {:message, WAWebProtobufSyncAction.UGCBot}
           }}
        end

        []
      ),
      (
        def field_def(:statusPrivacy) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusPrivacy",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusPrivacy,
             tag: 44,
             type: {:message, WAWebProtobufSyncAction.StatusPrivacyAction}
           }}
        end

        def field_def("statusPrivacy") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusPrivacy",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusPrivacy,
             tag: 44,
             type: {:message, WAWebProtobufSyncAction.StatusPrivacyAction}
           }}
        end

        []
      ),
      (
        def field_def(:botWelcomeRequestAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botWelcomeRequestAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :botWelcomeRequestAction,
             tag: 45,
             type: {:message, WAWebProtobufSyncAction.BotWelcomeRequestAction}
           }}
        end

        def field_def("botWelcomeRequestAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botWelcomeRequestAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :botWelcomeRequestAction,
             tag: 45,
             type: {:message, WAWebProtobufSyncAction.BotWelcomeRequestAction}
           }}
        end

        []
      ),
      (
        def field_def(:deleteIndividualCallLog) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deleteIndividualCallLog",
             kind: {:scalar, nil},
             label: :optional,
             name: :deleteIndividualCallLog,
             tag: 46,
             type: {:message, WAWebProtobufSyncAction.DeleteIndividualCallLogAction}
           }}
        end

        def field_def("deleteIndividualCallLog") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deleteIndividualCallLog",
             kind: {:scalar, nil},
             label: :optional,
             name: :deleteIndividualCallLog,
             tag: 46,
             type: {:message, WAWebProtobufSyncAction.DeleteIndividualCallLogAction}
           }}
        end

        []
      ),
      (
        def field_def(:labelReorderingAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "labelReorderingAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :labelReorderingAction,
             tag: 47,
             type: {:message, WAWebProtobufSyncAction.LabelReorderingAction}
           }}
        end

        def field_def("labelReorderingAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "labelReorderingAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :labelReorderingAction,
             tag: 47,
             type: {:message, WAWebProtobufSyncAction.LabelReorderingAction}
           }}
        end

        []
      ),
      (
        def field_def(:paymentInfoAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentInfoAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentInfoAction,
             tag: 48,
             type: {:message, WAWebProtobufSyncAction.PaymentInfoAction}
           }}
        end

        def field_def("paymentInfoAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentInfoAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentInfoAction,
             tag: 48,
             type: {:message, WAWebProtobufSyncAction.PaymentInfoAction}
           }}
        end

        []
      ),
      (
        def field_def(:customPaymentMethodsAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "customPaymentMethodsAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :customPaymentMethodsAction,
             tag: 49,
             type: {:message, WAWebProtobufSyncAction.CustomPaymentMethodsAction}
           }}
        end

        def field_def("customPaymentMethodsAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "customPaymentMethodsAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :customPaymentMethodsAction,
             tag: 49,
             type: {:message, WAWebProtobufSyncAction.CustomPaymentMethodsAction}
           }}
        end

        []
      ),
      (
        def field_def(:lockChatAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lockChatAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :lockChatAction,
             tag: 50,
             type: {:message, WAWebProtobufSyncAction.LockChatAction}
           }}
        end

        def field_def("lockChatAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lockChatAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :lockChatAction,
             tag: 50,
             type: {:message, WAWebProtobufSyncAction.LockChatAction}
           }}
        end

        []
      ),
      (
        def field_def(:chatLockSettings) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatLockSettings",
             kind: {:scalar, nil},
             label: :optional,
             name: :chatLockSettings,
             tag: 51,
             type: {:message, WAWebProtobufsChatLockSettings.ChatLockSettings}
           }}
        end

        def field_def("chatLockSettings") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatLockSettings",
             kind: {:scalar, nil},
             label: :optional,
             name: :chatLockSettings,
             tag: 51,
             type: {:message, WAWebProtobufsChatLockSettings.ChatLockSettings}
           }}
        end

        []
      ),
      (
        def field_def(:wamoUserIdentifierAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "wamoUserIdentifierAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :wamoUserIdentifierAction,
             tag: 52,
             type: {:message, WAWebProtobufSyncAction.WamoUserIdentifierAction}
           }}
        end

        def field_def("wamoUserIdentifierAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "wamoUserIdentifierAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :wamoUserIdentifierAction,
             tag: 52,
             type: {:message, WAWebProtobufSyncAction.WamoUserIdentifierAction}
           }}
        end

        []
      ),
      (
        def field_def(:privacySettingDisableLinkPreviewsAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "privacySettingDisableLinkPreviewsAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :privacySettingDisableLinkPreviewsAction,
             tag: 53,
             type: {:message, WAWebProtobufSyncAction.PrivacySettingDisableLinkPreviewsAction}
           }}
        end

        def field_def("privacySettingDisableLinkPreviewsAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "privacySettingDisableLinkPreviewsAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :privacySettingDisableLinkPreviewsAction,
             tag: 53,
             type: {:message, WAWebProtobufSyncAction.PrivacySettingDisableLinkPreviewsAction}
           }}
        end

        []
      ),
      (
        def field_def(:deviceCapabilities) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceCapabilities",
             kind: {:scalar, nil},
             label: :optional,
             name: :deviceCapabilities,
             tag: 54,
             type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities}
           }}
        end

        def field_def("deviceCapabilities") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceCapabilities",
             kind: {:scalar, nil},
             label: :optional,
             name: :deviceCapabilities,
             tag: 54,
             type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities}
           }}
        end

        []
      ),
      (
        def field_def(:noteEditAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "noteEditAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :noteEditAction,
             tag: 55,
             type: {:message, WAWebProtobufSyncAction.NoteEditAction}
           }}
        end

        def field_def("noteEditAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "noteEditAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :noteEditAction,
             tag: 55,
             type: {:message, WAWebProtobufSyncAction.NoteEditAction}
           }}
        end

        []
      ),
      (
        def field_def(:favoritesAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "favoritesAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :favoritesAction,
             tag: 56,
             type: {:message, WAWebProtobufSyncAction.FavoritesAction}
           }}
        end

        def field_def("favoritesAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "favoritesAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :favoritesAction,
             tag: 56,
             type: {:message, WAWebProtobufSyncAction.FavoritesAction}
           }}
        end

        []
      ),
      (
        def field_def(:merchantPaymentPartnerAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "merchantPaymentPartnerAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :merchantPaymentPartnerAction,
             tag: 57,
             type: {:message, WAWebProtobufSyncAction.MerchantPaymentPartnerAction}
           }}
        end

        def field_def("merchantPaymentPartnerAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "merchantPaymentPartnerAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :merchantPaymentPartnerAction,
             tag: 57,
             type: {:message, WAWebProtobufSyncAction.MerchantPaymentPartnerAction}
           }}
        end

        []
      ),
      (
        def field_def(:waffleAccountLinkStateAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "waffleAccountLinkStateAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :waffleAccountLinkStateAction,
             tag: 58,
             type: {:message, WAWebProtobufSyncAction.WaffleAccountLinkStateAction}
           }}
        end

        def field_def("waffleAccountLinkStateAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "waffleAccountLinkStateAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :waffleAccountLinkStateAction,
             tag: 58,
             type: {:message, WAWebProtobufSyncAction.WaffleAccountLinkStateAction}
           }}
        end

        []
      ),
      (
        def field_def(:usernameChatStartMode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "usernameChatStartMode",
             kind: {:scalar, nil},
             label: :optional,
             name: :usernameChatStartMode,
             tag: 59,
             type: {:message, WAWebProtobufSyncAction.UsernameChatStartModeAction}
           }}
        end

        def field_def("usernameChatStartMode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "usernameChatStartMode",
             kind: {:scalar, nil},
             label: :optional,
             name: :usernameChatStartMode,
             tag: 59,
             type: {:message, WAWebProtobufSyncAction.UsernameChatStartModeAction}
           }}
        end

        []
      ),
      (
        def field_def(:notificationActivitySettingAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "notificationActivitySettingAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :notificationActivitySettingAction,
             tag: 60,
             type: {:message, WAWebProtobufSyncAction.NotificationActivitySettingAction}
           }}
        end

        def field_def("notificationActivitySettingAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "notificationActivitySettingAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :notificationActivitySettingAction,
             tag: 60,
             type: {:message, WAWebProtobufSyncAction.NotificationActivitySettingAction}
           }}
        end

        []
      ),
      (
        def field_def(:lidContactAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lidContactAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :lidContactAction,
             tag: 61,
             type: {:message, WAWebProtobufSyncAction.LidContactAction}
           }}
        end

        def field_def("lidContactAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lidContactAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :lidContactAction,
             tag: 61,
             type: {:message, WAWebProtobufSyncAction.LidContactAction}
           }}
        end

        []
      ),
      (
        def field_def(:ctwaPerCustomerDataSharingAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctwaPerCustomerDataSharingAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :ctwaPerCustomerDataSharingAction,
             tag: 62,
             type: {:message, WAWebProtobufSyncAction.CtwaPerCustomerDataSharingAction}
           }}
        end

        def field_def("ctwaPerCustomerDataSharingAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctwaPerCustomerDataSharingAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :ctwaPerCustomerDataSharingAction,
             tag: 62,
             type: {:message, WAWebProtobufSyncAction.CtwaPerCustomerDataSharingAction}
           }}
        end

        []
      ),
      (
        def field_def(:paymentTosAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentTosAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentTosAction,
             tag: 63,
             type: {:message, WAWebProtobufSyncAction.PaymentTosAction}
           }}
        end

        def field_def("paymentTosAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentTosAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentTosAction,
             tag: 63,
             type: {:message, WAWebProtobufSyncAction.PaymentTosAction}
           }}
        end

        []
      ),
      (
        def field_def(:privacySettingChannelsPersonalisedRecommendationAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "privacySettingChannelsPersonalisedRecommendationAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :privacySettingChannelsPersonalisedRecommendationAction,
             tag: 64,
             type:
               {:message,
                WAWebProtobufSyncAction.PrivacySettingChannelsPersonalisedRecommendationAction}
           }}
        end

        def field_def("privacySettingChannelsPersonalisedRecommendationAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "privacySettingChannelsPersonalisedRecommendationAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :privacySettingChannelsPersonalisedRecommendationAction,
             tag: 64,
             type:
               {:message,
                WAWebProtobufSyncAction.PrivacySettingChannelsPersonalisedRecommendationAction}
           }}
        end

        []
      ),
      (
        def field_def(:detectedOutcomesStatusAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "detectedOutcomesStatusAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :detectedOutcomesStatusAction,
             tag: 66,
             type: {:message, WAWebProtobufSyncAction.DetectedOutcomesStatusAction}
           }}
        end

        def field_def("detectedOutcomesStatusAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "detectedOutcomesStatusAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :detectedOutcomesStatusAction,
             tag: 66,
             type: {:message, WAWebProtobufSyncAction.DetectedOutcomesStatusAction}
           }}
        end

        []
      ),
      (
        def field_def(:maibaAiFeaturesControlAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "maibaAiFeaturesControlAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :maibaAiFeaturesControlAction,
             tag: 68,
             type: {:message, WAWebProtobufSyncAction.MaibaAIFeaturesControlAction}
           }}
        end

        def field_def("maibaAiFeaturesControlAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "maibaAiFeaturesControlAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :maibaAiFeaturesControlAction,
             tag: 68,
             type: {:message, WAWebProtobufSyncAction.MaibaAIFeaturesControlAction}
           }}
        end

        []
      ),
      (
        def field_def(:businessBroadcastListAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "businessBroadcastListAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :businessBroadcastListAction,
             tag: 69,
             type: {:message, WAWebProtobufSyncAction.BusinessBroadcastListAction}
           }}
        end

        def field_def("businessBroadcastListAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "businessBroadcastListAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :businessBroadcastListAction,
             tag: 69,
             type: {:message, WAWebProtobufSyncAction.BusinessBroadcastListAction}
           }}
        end

        []
      ),
      (
        def field_def(:musicUserIDAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "musicUserIDAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :musicUserIDAction,
             tag: 70,
             type: {:message, WAWebProtobufSyncAction.MusicUserIdAction}
           }}
        end

        def field_def("musicUserIDAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "musicUserIDAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :musicUserIDAction,
             tag: 70,
             type: {:message, WAWebProtobufSyncAction.MusicUserIdAction}
           }}
        end

        []
      ),
      (
        def field_def(:statusPostOptInNotificationPreferencesAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusPostOptInNotificationPreferencesAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusPostOptInNotificationPreferencesAction,
             tag: 71,
             type:
               {:message, WAWebProtobufSyncAction.StatusPostOptInNotificationPreferencesAction}
           }}
        end

        def field_def("statusPostOptInNotificationPreferencesAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusPostOptInNotificationPreferencesAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusPostOptInNotificationPreferencesAction,
             tag: 71,
             type:
               {:message, WAWebProtobufSyncAction.StatusPostOptInNotificationPreferencesAction}
           }}
        end

        []
      ),
      (
        def field_def(:avatarUpdatedAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "avatarUpdatedAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :avatarUpdatedAction,
             tag: 72,
             type: {:message, WAWebProtobufSyncAction.AvatarUpdatedAction}
           }}
        end

        def field_def("avatarUpdatedAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "avatarUpdatedAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :avatarUpdatedAction,
             tag: 72,
             type: {:message, WAWebProtobufSyncAction.AvatarUpdatedAction}
           }}
        end

        []
      ),
      (
        def field_def(:privateProcessingSettingAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "privateProcessingSettingAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :privateProcessingSettingAction,
             tag: 74,
             type: {:message, WAWebProtobufSyncAction.PrivateProcessingSettingAction}
           }}
        end

        def field_def("privateProcessingSettingAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "privateProcessingSettingAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :privateProcessingSettingAction,
             tag: 74,
             type: {:message, WAWebProtobufSyncAction.PrivateProcessingSettingAction}
           }}
        end

        []
      ),
      (
        def field_def(:newsletterSavedInterestsAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterSavedInterestsAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :newsletterSavedInterestsAction,
             tag: 75,
             type: {:message, WAWebProtobufSyncAction.NewsletterSavedInterestsAction}
           }}
        end

        def field_def("newsletterSavedInterestsAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterSavedInterestsAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :newsletterSavedInterestsAction,
             tag: 75,
             type: {:message, WAWebProtobufSyncAction.NewsletterSavedInterestsAction}
           }}
        end

        []
      ),
      (
        def field_def(:aiThreadRenameAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiThreadRenameAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :aiThreadRenameAction,
             tag: 76,
             type: {:message, WAWebProtobufSyncAction.AiThreadRenameAction}
           }}
        end

        def field_def("aiThreadRenameAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiThreadRenameAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :aiThreadRenameAction,
             tag: 76,
             type: {:message, WAWebProtobufSyncAction.AiThreadRenameAction}
           }}
        end

        []
      ),
      (
        def field_def(:interactiveMessageAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "interactiveMessageAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :interactiveMessageAction,
             tag: 77,
             type: {:message, WAWebProtobufSyncAction.InteractiveMessageAction}
           }}
        end

        def field_def("interactiveMessageAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "interactiveMessageAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :interactiveMessageAction,
             tag: 77,
             type: {:message, WAWebProtobufSyncAction.InteractiveMessageAction}
           }}
        end

        []
      ),
      (
        def field_def(:settingsSyncAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "settingsSyncAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :settingsSyncAction,
             tag: 78,
             type: {:message, WAWebProtobufSyncAction.SettingsSyncAction}
           }}
        end

        def field_def("settingsSyncAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "settingsSyncAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :settingsSyncAction,
             tag: 78,
             type: {:message, WAWebProtobufSyncAction.SettingsSyncAction}
           }}
        end

        []
      ),
      (
        def field_def(:outContactAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "outContactAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :outContactAction,
             tag: 79,
             type: {:message, WAWebProtobufSyncAction.OutContactAction}
           }}
        end

        def field_def("outContactAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "outContactAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :outContactAction,
             tag: 79,
             type: {:message, WAWebProtobufSyncAction.OutContactAction}
           }}
        end

        []
      ),
      (
        def field_def(:nctSaltSyncAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nctSaltSyncAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :nctSaltSyncAction,
             tag: 80,
             type: {:message, WAWebProtobufSyncAction.NctSaltSyncAction}
           }}
        end

        def field_def("nctSaltSyncAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nctSaltSyncAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :nctSaltSyncAction,
             tag: 80,
             type: {:message, WAWebProtobufSyncAction.NctSaltSyncAction}
           }}
        end

        []
      ),
      (
        def field_def(:businessBroadcastCampaignAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "businessBroadcastCampaignAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :businessBroadcastCampaignAction,
             tag: 81,
             type: {:message, WAWebProtobufSyncAction.BusinessBroadcastCampaignAction}
           }}
        end

        def field_def("businessBroadcastCampaignAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "businessBroadcastCampaignAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :businessBroadcastCampaignAction,
             tag: 81,
             type: {:message, WAWebProtobufSyncAction.BusinessBroadcastCampaignAction}
           }}
        end

        []
      ),
      (
        def field_def(:businessBroadcastInsightsAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "businessBroadcastInsightsAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :businessBroadcastInsightsAction,
             tag: 82,
             type: {:message, WAWebProtobufSyncAction.BusinessBroadcastInsightsAction}
           }}
        end

        def field_def("businessBroadcastInsightsAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "businessBroadcastInsightsAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :businessBroadcastInsightsAction,
             tag: 82,
             type: {:message, WAWebProtobufSyncAction.BusinessBroadcastInsightsAction}
           }}
        end

        []
      ),
      (
        def field_def(:customerDataAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "customerDataAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :customerDataAction,
             tag: 83,
             type: {:message, WAWebProtobufSyncAction.CustomerDataAction}
           }}
        end

        def field_def("customerDataAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "customerDataAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :customerDataAction,
             tag: 83,
             type: {:message, WAWebProtobufSyncAction.CustomerDataAction}
           }}
        end

        []
      ),
      (
        def field_def(:subscriptionsSyncV2Action) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "subscriptionsSyncV2Action",
             kind: {:scalar, nil},
             label: :optional,
             name: :subscriptionsSyncV2Action,
             tag: 84,
             type: {:message, WAWebProtobufSyncAction.SubscriptionsSyncV2Action}
           }}
        end

        def field_def("subscriptionsSyncV2Action") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "subscriptionsSyncV2Action",
             kind: {:scalar, nil},
             label: :optional,
             name: :subscriptionsSyncV2Action,
             tag: 84,
             type: {:message, WAWebProtobufSyncAction.SubscriptionsSyncV2Action}
           }}
        end

        []
      ),
      (
        def field_def(:threadPinAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "threadPinAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :threadPinAction,
             tag: 85,
             type: {:message, WAWebProtobufSyncAction.ThreadPinAction}
           }}
        end

        def field_def("threadPinAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "threadPinAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :threadPinAction,
             tag: 85,
             type: {:message, WAWebProtobufSyncAction.ThreadPinAction}
           }}
        end

        []
      ),
      (
        def field_def(:autoOrganizeBusinessChatSetting) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "autoOrganizeBusinessChatSetting",
             kind: {:scalar, nil},
             label: :optional,
             name: :autoOrganizeBusinessChatSetting,
             tag: 86,
             type: {:message, WAWebProtobufSyncAction.AutoOrganizeBusinessChatSetting}
           }}
        end

        def field_def("autoOrganizeBusinessChatSetting") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "autoOrganizeBusinessChatSetting",
             kind: {:scalar, nil},
             label: :optional,
             name: :autoOrganizeBusinessChatSetting,
             tag: 86,
             type: {:message, WAWebProtobufSyncAction.AutoOrganizeBusinessChatSetting}
           }}
        end

        []
      ),
      (
        def field_def(:bizAiSettingsNudgeAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bizAiSettingsNudgeAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :bizAiSettingsNudgeAction,
             tag: 87,
             type: {:message, WAWebProtobufSyncAction.BizAISettingsNudgeAction}
           }}
        end

        def field_def("bizAiSettingsNudgeAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bizAiSettingsNudgeAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :bizAiSettingsNudgeAction,
             tag: 87,
             type: {:message, WAWebProtobufSyncAction.BizAISettingsNudgeAction}
           }}
        end

        []
      ),
      (
        def field_def(:coexV2VersionAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "coexV2VersionAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :coexV2VersionAction,
             tag: 88,
             type: {:message, WAWebProtobufSyncAction.CoexV2VersionAction}
           }}
        end

        def field_def("coexV2VersionAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "coexV2VersionAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :coexV2VersionAction,
             tag: 88,
             type: {:message, WAWebProtobufSyncAction.CoexV2VersionAction}
           }}
        end

        []
      ),
      (
        def field_def(:wasaRootSecretAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "wasaRootSecretAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :wasaRootSecretAction,
             tag: 89,
             type: {:message, WAWebProtobufSyncAction.WASARootSecretAction}
           }}
        end

        def field_def("wasaRootSecretAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "wasaRootSecretAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :wasaRootSecretAction,
             tag: 89,
             type: {:message, WAWebProtobufSyncAction.WASARootSecretAction}
           }}
        end

        []
      ),
      (
        def field_def(:bubbleLockMessageAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bubbleLockMessageAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :bubbleLockMessageAction,
             tag: 90,
             type: {:message, WAWebProtobufSyncAction.BubbleLockMessageAction}
           }}
        end

        def field_def("bubbleLockMessageAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bubbleLockMessageAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :bubbleLockMessageAction,
             tag: 90,
             type: {:message, WAWebProtobufSyncAction.BubbleLockMessageAction}
           }}
        end

        []
      ),
      (
        def field_def(:labelSublistAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "labelSublistAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :labelSublistAction,
             tag: 91,
             type: {:message, WAWebProtobufSyncAction.LabelSublistAction}
           }}
        end

        def field_def("labelSublistAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "labelSublistAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :labelSublistAction,
             tag: 91,
             type: {:message, WAWebProtobufSyncAction.LabelSublistAction}
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
    def default(:timestamp) do
      {:ok, 0}
    end,
    def default(:starAction) do
      {:ok, nil}
    end,
    def default(:contactAction) do
      {:ok, nil}
    end,
    def default(:muteAction) do
      {:ok, nil}
    end,
    def default(:pinAction) do
      {:ok, nil}
    end,
    def default(:pushNameSetting) do
      {:ok, nil}
    end,
    def default(:quickReplyAction) do
      {:ok, nil}
    end,
    def default(:recentEmojiWeightsAction) do
      {:ok, nil}
    end,
    def default(:labelEditAction) do
      {:ok, nil}
    end,
    def default(:labelAssociationAction) do
      {:ok, nil}
    end,
    def default(:localeSetting) do
      {:ok, nil}
    end,
    def default(:archiveChatAction) do
      {:ok, nil}
    end,
    def default(:deleteMessageForMeAction) do
      {:ok, nil}
    end,
    def default(:keyExpiration) do
      {:ok, nil}
    end,
    def default(:markChatAsReadAction) do
      {:ok, nil}
    end,
    def default(:clearChatAction) do
      {:ok, nil}
    end,
    def default(:deleteChatAction) do
      {:ok, nil}
    end,
    def default(:unarchiveChatsSetting) do
      {:ok, nil}
    end,
    def default(:primaryFeature) do
      {:ok, nil}
    end,
    def default(:androidUnsupportedActions) do
      {:ok, nil}
    end,
    def default(:agentAction) do
      {:ok, nil}
    end,
    def default(:subscriptionAction) do
      {:ok, nil}
    end,
    def default(:userStatusMuteAction) do
      {:ok, nil}
    end,
    def default(:timeFormatAction) do
      {:ok, nil}
    end,
    def default(:nuxAction) do
      {:ok, nil}
    end,
    def default(:primaryVersionAction) do
      {:ok, nil}
    end,
    def default(:stickerAction) do
      {:ok, nil}
    end,
    def default(:removeRecentStickerAction) do
      {:ok, nil}
    end,
    def default(:chatAssignment) do
      {:ok, nil}
    end,
    def default(:chatAssignmentOpenedStatus) do
      {:ok, nil}
    end,
    def default(:pnForLidChatAction) do
      {:ok, nil}
    end,
    def default(:marketingMessageAction) do
      {:ok, nil}
    end,
    def default(:marketingMessageBroadcastAction) do
      {:ok, nil}
    end,
    def default(:externalWebBetaAction) do
      {:ok, nil}
    end,
    def default(:privacySettingRelayAllCalls) do
      {:ok, nil}
    end,
    def default(:callLogAction) do
      {:ok, nil}
    end,
    def default(:ugcBot) do
      {:ok, nil}
    end,
    def default(:statusPrivacy) do
      {:ok, nil}
    end,
    def default(:botWelcomeRequestAction) do
      {:ok, nil}
    end,
    def default(:deleteIndividualCallLog) do
      {:ok, nil}
    end,
    def default(:labelReorderingAction) do
      {:ok, nil}
    end,
    def default(:paymentInfoAction) do
      {:ok, nil}
    end,
    def default(:customPaymentMethodsAction) do
      {:ok, nil}
    end,
    def default(:lockChatAction) do
      {:ok, nil}
    end,
    def default(:chatLockSettings) do
      {:ok, nil}
    end,
    def default(:wamoUserIdentifierAction) do
      {:ok, nil}
    end,
    def default(:privacySettingDisableLinkPreviewsAction) do
      {:ok, nil}
    end,
    def default(:deviceCapabilities) do
      {:ok, nil}
    end,
    def default(:noteEditAction) do
      {:ok, nil}
    end,
    def default(:favoritesAction) do
      {:ok, nil}
    end,
    def default(:merchantPaymentPartnerAction) do
      {:ok, nil}
    end,
    def default(:waffleAccountLinkStateAction) do
      {:ok, nil}
    end,
    def default(:usernameChatStartMode) do
      {:ok, nil}
    end,
    def default(:notificationActivitySettingAction) do
      {:ok, nil}
    end,
    def default(:lidContactAction) do
      {:ok, nil}
    end,
    def default(:ctwaPerCustomerDataSharingAction) do
      {:ok, nil}
    end,
    def default(:paymentTosAction) do
      {:ok, nil}
    end,
    def default(:privacySettingChannelsPersonalisedRecommendationAction) do
      {:ok, nil}
    end,
    def default(:detectedOutcomesStatusAction) do
      {:ok, nil}
    end,
    def default(:maibaAiFeaturesControlAction) do
      {:ok, nil}
    end,
    def default(:businessBroadcastListAction) do
      {:ok, nil}
    end,
    def default(:musicUserIDAction) do
      {:ok, nil}
    end,
    def default(:statusPostOptInNotificationPreferencesAction) do
      {:ok, nil}
    end,
    def default(:avatarUpdatedAction) do
      {:ok, nil}
    end,
    def default(:privateProcessingSettingAction) do
      {:ok, nil}
    end,
    def default(:newsletterSavedInterestsAction) do
      {:ok, nil}
    end,
    def default(:aiThreadRenameAction) do
      {:ok, nil}
    end,
    def default(:interactiveMessageAction) do
      {:ok, nil}
    end,
    def default(:settingsSyncAction) do
      {:ok, nil}
    end,
    def default(:outContactAction) do
      {:ok, nil}
    end,
    def default(:nctSaltSyncAction) do
      {:ok, nil}
    end,
    def default(:businessBroadcastCampaignAction) do
      {:ok, nil}
    end,
    def default(:businessBroadcastInsightsAction) do
      {:ok, nil}
    end,
    def default(:customerDataAction) do
      {:ok, nil}
    end,
    def default(:subscriptionsSyncV2Action) do
      {:ok, nil}
    end,
    def default(:threadPinAction) do
      {:ok, nil}
    end,
    def default(:autoOrganizeBusinessChatSetting) do
      {:ok, nil}
    end,
    def default(:bizAiSettingsNudgeAction) do
      {:ok, nil}
    end,
    def default(:coexV2VersionAction) do
      {:ok, nil}
    end,
    def default(:wasaRootSecretAction) do
      {:ok, nil}
    end,
    def default(:bubbleLockMessageAction) do
      {:ok, nil}
    end,
    def default(:labelSublistAction) do
      {:ok, nil}
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
        go_package: "go.mau.fi/whatsmeow/proto/waSyncAction",
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
