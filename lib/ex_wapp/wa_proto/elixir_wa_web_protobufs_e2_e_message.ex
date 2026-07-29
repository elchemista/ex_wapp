# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.Message do
  @moduledoc false
  defstruct conversation: nil,
            senderKeyDistributionMessage: nil,
            imageMessage: nil,
            contactMessage: nil,
            locationMessage: nil,
            extendedTextMessage: nil,
            documentMessage: nil,
            audioMessage: nil,
            videoMessage: nil,
            call: nil,
            chat: nil,
            protocolMessage: nil,
            contactsArrayMessage: nil,
            highlyStructuredMessage: nil,
            fastRatchetKeySenderKeyDistributionMessage: nil,
            sendPaymentMessage: nil,
            liveLocationMessage: nil,
            requestPaymentMessage: nil,
            declinePaymentRequestMessage: nil,
            cancelPaymentRequestMessage: nil,
            templateMessage: nil,
            stickerMessage: nil,
            groupInviteMessage: nil,
            templateButtonReplyMessage: nil,
            productMessage: nil,
            deviceSentMessage: nil,
            messageContextInfo: nil,
            listMessage: nil,
            viewOnceMessage: nil,
            orderMessage: nil,
            listResponseMessage: nil,
            ephemeralMessage: nil,
            invoiceMessage: nil,
            buttonsMessage: nil,
            buttonsResponseMessage: nil,
            paymentInviteMessage: nil,
            interactiveMessage: nil,
            reactionMessage: nil,
            stickerSyncRmrMessage: nil,
            interactiveResponseMessage: nil,
            pollCreationMessage: nil,
            pollUpdateMessage: nil,
            keepInChatMessage: nil,
            documentWithCaptionMessage: nil,
            requestPhoneNumberMessage: nil,
            viewOnceMessageV2: nil,
            encReactionMessage: nil,
            editedMessage: nil,
            viewOnceMessageV2Extension: nil,
            pollCreationMessageV2: nil,
            scheduledCallCreationMessage: nil,
            groupMentionedMessage: nil,
            pinInChatMessage: nil,
            pollCreationMessageV3: nil,
            scheduledCallEditMessage: nil,
            ptvMessage: nil,
            botInvokeMessage: nil,
            callLogMesssage: nil,
            messageHistoryBundle: nil,
            encCommentMessage: nil,
            bcallMessage: nil,
            lottieStickerMessage: nil,
            eventMessage: nil,
            encEventResponseMessage: nil,
            commentMessage: nil,
            newsletterAdminInviteMessage: nil,
            placeholderMessage: nil,
            secretEncryptedMessage: nil,
            albumMessage: nil,
            eventCoverImage: nil,
            stickerPackMessage: nil,
            statusMentionMessage: nil,
            pollResultSnapshotMessage: nil,
            pollCreationOptionImageMessage: nil,
            associatedChildMessage: nil,
            groupStatusMentionMessage: nil,
            pollCreationMessageV4: nil,
            statusAddYours: nil,
            groupStatusMessage: nil,
            richResponseMessage: nil,
            statusNotificationMessage: nil,
            limitSharingMessage: nil,
            botTaskMessage: nil,
            questionMessage: nil,
            messageHistoryNotice: nil,
            groupStatusMessageV2: nil,
            botForwardedMessage: nil,
            statusQuestionAnswerMessage: nil,
            questionReplyMessage: nil,
            questionResponseMessage: nil,
            statusQuotedMessage: nil,
            statusStickerInteractionMessage: nil,
            pollCreationMessageV5: nil,
            newsletterFollowerInviteMessageV2: nil,
            pollResultSnapshotMessageV3: nil,
            newsletterAdminProfileMessage: nil,
            newsletterAdminProfileMessageV2: nil,
            spoilerMessage: nil,
            pollCreationMessageV6: nil,
            conditionalRevealMessage: nil,
            pollAddOptionMessage: nil,
            eventInviteMessage: nil,
            groupRootKeyShare: nil,
            paymentReminderMessage: nil,
            splitPaymentMessage: nil,
            newsletterAdminProfileStatusMessage: nil,
            rootSecretDistributeMessage: nil,
            splitPaymentUpdateMessage: nil,
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
        |> encode_conversation(msg)
        |> encode_senderKeyDistributionMessage(msg)
        |> encode_imageMessage(msg)
        |> encode_contactMessage(msg)
        |> encode_locationMessage(msg)
        |> encode_extendedTextMessage(msg)
        |> encode_documentMessage(msg)
        |> encode_audioMessage(msg)
        |> encode_videoMessage(msg)
        |> encode_call(msg)
        |> encode_chat(msg)
        |> encode_protocolMessage(msg)
        |> encode_contactsArrayMessage(msg)
        |> encode_highlyStructuredMessage(msg)
        |> encode_fastRatchetKeySenderKeyDistributionMessage(msg)
        |> encode_sendPaymentMessage(msg)
        |> encode_liveLocationMessage(msg)
        |> encode_requestPaymentMessage(msg)
        |> encode_declinePaymentRequestMessage(msg)
        |> encode_cancelPaymentRequestMessage(msg)
        |> encode_templateMessage(msg)
        |> encode_stickerMessage(msg)
        |> encode_groupInviteMessage(msg)
        |> encode_templateButtonReplyMessage(msg)
        |> encode_productMessage(msg)
        |> encode_deviceSentMessage(msg)
        |> encode_messageContextInfo(msg)
        |> encode_listMessage(msg)
        |> encode_viewOnceMessage(msg)
        |> encode_orderMessage(msg)
        |> encode_listResponseMessage(msg)
        |> encode_ephemeralMessage(msg)
        |> encode_invoiceMessage(msg)
        |> encode_buttonsMessage(msg)
        |> encode_buttonsResponseMessage(msg)
        |> encode_paymentInviteMessage(msg)
        |> encode_interactiveMessage(msg)
        |> encode_reactionMessage(msg)
        |> encode_stickerSyncRmrMessage(msg)
        |> encode_interactiveResponseMessage(msg)
        |> encode_pollCreationMessage(msg)
        |> encode_pollUpdateMessage(msg)
        |> encode_keepInChatMessage(msg)
        |> encode_documentWithCaptionMessage(msg)
        |> encode_requestPhoneNumberMessage(msg)
        |> encode_viewOnceMessageV2(msg)
        |> encode_encReactionMessage(msg)
        |> encode_editedMessage(msg)
        |> encode_viewOnceMessageV2Extension(msg)
        |> encode_pollCreationMessageV2(msg)
        |> encode_scheduledCallCreationMessage(msg)
        |> encode_groupMentionedMessage(msg)
        |> encode_pinInChatMessage(msg)
        |> encode_pollCreationMessageV3(msg)
        |> encode_scheduledCallEditMessage(msg)
        |> encode_ptvMessage(msg)
        |> encode_botInvokeMessage(msg)
        |> encode_callLogMesssage(msg)
        |> encode_messageHistoryBundle(msg)
        |> encode_encCommentMessage(msg)
        |> encode_bcallMessage(msg)
        |> encode_lottieStickerMessage(msg)
        |> encode_eventMessage(msg)
        |> encode_encEventResponseMessage(msg)
        |> encode_commentMessage(msg)
        |> encode_newsletterAdminInviteMessage(msg)
        |> encode_placeholderMessage(msg)
        |> encode_secretEncryptedMessage(msg)
        |> encode_albumMessage(msg)
        |> encode_eventCoverImage(msg)
        |> encode_stickerPackMessage(msg)
        |> encode_statusMentionMessage(msg)
        |> encode_pollResultSnapshotMessage(msg)
        |> encode_pollCreationOptionImageMessage(msg)
        |> encode_associatedChildMessage(msg)
        |> encode_groupStatusMentionMessage(msg)
        |> encode_pollCreationMessageV4(msg)
        |> encode_statusAddYours(msg)
        |> encode_groupStatusMessage(msg)
        |> encode_richResponseMessage(msg)
        |> encode_statusNotificationMessage(msg)
        |> encode_limitSharingMessage(msg)
        |> encode_botTaskMessage(msg)
        |> encode_questionMessage(msg)
        |> encode_messageHistoryNotice(msg)
        |> encode_groupStatusMessageV2(msg)
        |> encode_botForwardedMessage(msg)
        |> encode_statusQuestionAnswerMessage(msg)
        |> encode_questionReplyMessage(msg)
        |> encode_questionResponseMessage(msg)
        |> encode_statusQuotedMessage(msg)
        |> encode_statusStickerInteractionMessage(msg)
        |> encode_pollCreationMessageV5(msg)
        |> encode_newsletterFollowerInviteMessageV2(msg)
        |> encode_pollResultSnapshotMessageV3(msg)
        |> encode_newsletterAdminProfileMessage(msg)
        |> encode_newsletterAdminProfileMessageV2(msg)
        |> encode_spoilerMessage(msg)
        |> encode_pollCreationMessageV6(msg)
        |> encode_conditionalRevealMessage(msg)
        |> encode_pollAddOptionMessage(msg)
        |> encode_eventInviteMessage(msg)
        |> encode_groupRootKeyShare(msg)
        |> encode_paymentReminderMessage(msg)
        |> encode_splitPaymentMessage(msg)
        |> encode_newsletterAdminProfileStatusMessage(msg)
        |> encode_rootSecretDistributeMessage(msg)
        |> encode_splitPaymentUpdateMessage(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_conversation(acc, msg) do
        try do
          case msg.conversation do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.conversation)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:conversation, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_senderKeyDistributionMessage(acc, msg) do
        try do
          case msg.senderKeyDistributionMessage do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_message(msg.senderKeyDistributionMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :senderKeyDistributionMessage,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_imageMessage(acc, msg) do
        try do
          case msg.imageMessage do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_message(msg.imageMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:imageMessage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_contactMessage(acc, msg) do
        try do
          case msg.contactMessage do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_message(msg.contactMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contactMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_locationMessage(acc, msg) do
        try do
          case msg.locationMessage do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_message(msg.locationMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:locationMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_extendedTextMessage(acc, msg) do
        try do
          case msg.extendedTextMessage do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_message(msg.extendedTextMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:extendedTextMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_documentMessage(acc, msg) do
        try do
          case msg.documentMessage do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_message(msg.documentMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:documentMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_audioMessage(acc, msg) do
        try do
          case msg.audioMessage do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_message(msg.audioMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:audioMessage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_videoMessage(acc, msg) do
        try do
          case msg.videoMessage do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_message(msg.videoMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:videoMessage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_call(acc, msg) do
        try do
          case msg.call do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_message(msg.call)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:call, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_chat(acc, msg) do
        try do
          case msg.chat do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_message(msg.chat)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:chat, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_protocolMessage(acc, msg) do
        try do
          case msg.protocolMessage do
            nil -> acc
            _ -> [acc, "b", Protox.Encode.encode_message(msg.protocolMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:protocolMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_contactsArrayMessage(acc, msg) do
        try do
          case msg.contactsArrayMessage do
            nil -> acc
            _ -> [acc, "j", Protox.Encode.encode_message(msg.contactsArrayMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contactsArrayMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_highlyStructuredMessage(acc, msg) do
        try do
          case msg.highlyStructuredMessage do
            nil -> acc
            _ -> [acc, "r", Protox.Encode.encode_message(msg.highlyStructuredMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:highlyStructuredMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_fastRatchetKeySenderKeyDistributionMessage(acc, msg) do
        try do
          case msg.fastRatchetKeySenderKeyDistributionMessage do
            nil ->
              acc

            _ ->
              [
                acc,
                "z",
                Protox.Encode.encode_message(msg.fastRatchetKeySenderKeyDistributionMessage)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :fastRatchetKeySenderKeyDistributionMessage,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_sendPaymentMessage(acc, msg) do
        try do
          case msg.sendPaymentMessage do
            nil -> acc
            _ -> [acc, "\x82\x01", Protox.Encode.encode_message(msg.sendPaymentMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:sendPaymentMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_liveLocationMessage(acc, msg) do
        try do
          case msg.liveLocationMessage do
            nil -> acc
            _ -> [acc, "\x92\x01", Protox.Encode.encode_message(msg.liveLocationMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:liveLocationMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_requestPaymentMessage(acc, msg) do
        try do
          case msg.requestPaymentMessage do
            nil -> acc
            _ -> [acc, "\xB2\x01", Protox.Encode.encode_message(msg.requestPaymentMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:requestPaymentMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_declinePaymentRequestMessage(acc, msg) do
        try do
          case msg.declinePaymentRequestMessage do
            nil -> acc
            _ -> [acc, "\xBA\x01", Protox.Encode.encode_message(msg.declinePaymentRequestMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :declinePaymentRequestMessage,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_cancelPaymentRequestMessage(acc, msg) do
        try do
          case msg.cancelPaymentRequestMessage do
            nil -> acc
            _ -> [acc, "\xC2\x01", Protox.Encode.encode_message(msg.cancelPaymentRequestMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:cancelPaymentRequestMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_templateMessage(acc, msg) do
        try do
          case msg.templateMessage do
            nil -> acc
            _ -> [acc, "\xCA\x01", Protox.Encode.encode_message(msg.templateMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:templateMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_stickerMessage(acc, msg) do
        try do
          case msg.stickerMessage do
            nil -> acc
            _ -> [acc, "\xD2\x01", Protox.Encode.encode_message(msg.stickerMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:stickerMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_groupInviteMessage(acc, msg) do
        try do
          case msg.groupInviteMessage do
            nil -> acc
            _ -> [acc, "\xE2\x01", Protox.Encode.encode_message(msg.groupInviteMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupInviteMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_templateButtonReplyMessage(acc, msg) do
        try do
          case msg.templateButtonReplyMessage do
            nil -> acc
            _ -> [acc, "\xEA\x01", Protox.Encode.encode_message(msg.templateButtonReplyMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:templateButtonReplyMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_productMessage(acc, msg) do
        try do
          case msg.productMessage do
            nil -> acc
            _ -> [acc, "\xF2\x01", Protox.Encode.encode_message(msg.productMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:productMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_deviceSentMessage(acc, msg) do
        try do
          case msg.deviceSentMessage do
            nil -> acc
            _ -> [acc, "\xFA\x01", Protox.Encode.encode_message(msg.deviceSentMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deviceSentMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messageContextInfo(acc, msg) do
        try do
          case msg.messageContextInfo do
            nil -> acc
            _ -> [acc, "\x9A\x02", Protox.Encode.encode_message(msg.messageContextInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageContextInfo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_listMessage(acc, msg) do
        try do
          case msg.listMessage do
            nil -> acc
            _ -> [acc, "\xA2\x02", Protox.Encode.encode_message(msg.listMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:listMessage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_viewOnceMessage(acc, msg) do
        try do
          case msg.viewOnceMessage do
            nil -> acc
            _ -> [acc, "\xAA\x02", Protox.Encode.encode_message(msg.viewOnceMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:viewOnceMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_orderMessage(acc, msg) do
        try do
          case msg.orderMessage do
            nil -> acc
            _ -> [acc, "\xB2\x02", Protox.Encode.encode_message(msg.orderMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:orderMessage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_listResponseMessage(acc, msg) do
        try do
          case msg.listResponseMessage do
            nil -> acc
            _ -> [acc, "\xBA\x02", Protox.Encode.encode_message(msg.listResponseMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:listResponseMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ephemeralMessage(acc, msg) do
        try do
          case msg.ephemeralMessage do
            nil -> acc
            _ -> [acc, "\xC2\x02", Protox.Encode.encode_message(msg.ephemeralMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeralMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_invoiceMessage(acc, msg) do
        try do
          case msg.invoiceMessage do
            nil -> acc
            _ -> [acc, "\xCA\x02", Protox.Encode.encode_message(msg.invoiceMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:invoiceMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_buttonsMessage(acc, msg) do
        try do
          case msg.buttonsMessage do
            nil -> acc
            _ -> [acc, "\xD2\x02", Protox.Encode.encode_message(msg.buttonsMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:buttonsMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_buttonsResponseMessage(acc, msg) do
        try do
          case msg.buttonsResponseMessage do
            nil -> acc
            _ -> [acc, "\xDA\x02", Protox.Encode.encode_message(msg.buttonsResponseMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:buttonsResponseMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_paymentInviteMessage(acc, msg) do
        try do
          case msg.paymentInviteMessage do
            nil -> acc
            _ -> [acc, "\xE2\x02", Protox.Encode.encode_message(msg.paymentInviteMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:paymentInviteMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_interactiveMessage(acc, msg) do
        try do
          case msg.interactiveMessage do
            nil -> acc
            _ -> [acc, "\xEA\x02", Protox.Encode.encode_message(msg.interactiveMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:interactiveMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_reactionMessage(acc, msg) do
        try do
          case msg.reactionMessage do
            nil -> acc
            _ -> [acc, "\xF2\x02", Protox.Encode.encode_message(msg.reactionMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:reactionMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_stickerSyncRmrMessage(acc, msg) do
        try do
          case msg.stickerSyncRmrMessage do
            nil -> acc
            _ -> [acc, "\xFA\x02", Protox.Encode.encode_message(msg.stickerSyncRmrMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:stickerSyncRmrMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_interactiveResponseMessage(acc, msg) do
        try do
          case msg.interactiveResponseMessage do
            nil -> acc
            _ -> [acc, "\x82\x03", Protox.Encode.encode_message(msg.interactiveResponseMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:interactiveResponseMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pollCreationMessage(acc, msg) do
        try do
          case msg.pollCreationMessage do
            nil -> acc
            _ -> [acc, "\x8A\x03", Protox.Encode.encode_message(msg.pollCreationMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollCreationMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pollUpdateMessage(acc, msg) do
        try do
          case msg.pollUpdateMessage do
            nil -> acc
            _ -> [acc, "\x92\x03", Protox.Encode.encode_message(msg.pollUpdateMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollUpdateMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_keepInChatMessage(acc, msg) do
        try do
          case msg.keepInChatMessage do
            nil -> acc
            _ -> [acc, "\x9A\x03", Protox.Encode.encode_message(msg.keepInChatMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:keepInChatMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_documentWithCaptionMessage(acc, msg) do
        try do
          case msg.documentWithCaptionMessage do
            nil -> acc
            _ -> [acc, "\xAA\x03", Protox.Encode.encode_message(msg.documentWithCaptionMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:documentWithCaptionMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_requestPhoneNumberMessage(acc, msg) do
        try do
          case msg.requestPhoneNumberMessage do
            nil -> acc
            _ -> [acc, "\xB2\x03", Protox.Encode.encode_message(msg.requestPhoneNumberMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:requestPhoneNumberMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_viewOnceMessageV2(acc, msg) do
        try do
          case msg.viewOnceMessageV2 do
            nil -> acc
            _ -> [acc, "\xBA\x03", Protox.Encode.encode_message(msg.viewOnceMessageV2)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:viewOnceMessageV2, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_encReactionMessage(acc, msg) do
        try do
          case msg.encReactionMessage do
            nil -> acc
            _ -> [acc, "\xC2\x03", Protox.Encode.encode_message(msg.encReactionMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:encReactionMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_editedMessage(acc, msg) do
        try do
          case msg.editedMessage do
            nil -> acc
            _ -> [acc, "\xD2\x03", Protox.Encode.encode_message(msg.editedMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:editedMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_viewOnceMessageV2Extension(acc, msg) do
        try do
          case msg.viewOnceMessageV2Extension do
            nil -> acc
            _ -> [acc, "\xDA\x03", Protox.Encode.encode_message(msg.viewOnceMessageV2Extension)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:viewOnceMessageV2Extension, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pollCreationMessageV2(acc, msg) do
        try do
          case msg.pollCreationMessageV2 do
            nil -> acc
            _ -> [acc, "\xE2\x03", Protox.Encode.encode_message(msg.pollCreationMessageV2)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollCreationMessageV2, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_scheduledCallCreationMessage(acc, msg) do
        try do
          case msg.scheduledCallCreationMessage do
            nil -> acc
            _ -> [acc, "\xEA\x03", Protox.Encode.encode_message(msg.scheduledCallCreationMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :scheduledCallCreationMessage,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_groupMentionedMessage(acc, msg) do
        try do
          case msg.groupMentionedMessage do
            nil -> acc
            _ -> [acc, "\xF2\x03", Protox.Encode.encode_message(msg.groupMentionedMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupMentionedMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pinInChatMessage(acc, msg) do
        try do
          case msg.pinInChatMessage do
            nil -> acc
            _ -> [acc, "\xFA\x03", Protox.Encode.encode_message(msg.pinInChatMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pinInChatMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pollCreationMessageV3(acc, msg) do
        try do
          case msg.pollCreationMessageV3 do
            nil -> acc
            _ -> [acc, "\x82\x04", Protox.Encode.encode_message(msg.pollCreationMessageV3)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollCreationMessageV3, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_scheduledCallEditMessage(acc, msg) do
        try do
          case msg.scheduledCallEditMessage do
            nil -> acc
            _ -> [acc, "\x8A\x04", Protox.Encode.encode_message(msg.scheduledCallEditMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:scheduledCallEditMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ptvMessage(acc, msg) do
        try do
          case msg.ptvMessage do
            nil -> acc
            _ -> [acc, "\x92\x04", Protox.Encode.encode_message(msg.ptvMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ptvMessage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_botInvokeMessage(acc, msg) do
        try do
          case msg.botInvokeMessage do
            nil -> acc
            _ -> [acc, "\x9A\x04", Protox.Encode.encode_message(msg.botInvokeMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botInvokeMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_callLogMesssage(acc, msg) do
        try do
          case msg.callLogMesssage do
            nil -> acc
            _ -> [acc, "\xAA\x04", Protox.Encode.encode_message(msg.callLogMesssage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callLogMesssage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messageHistoryBundle(acc, msg) do
        try do
          case msg.messageHistoryBundle do
            nil -> acc
            _ -> [acc, "\xB2\x04", Protox.Encode.encode_message(msg.messageHistoryBundle)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageHistoryBundle, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_encCommentMessage(acc, msg) do
        try do
          case msg.encCommentMessage do
            nil -> acc
            _ -> [acc, "\xBA\x04", Protox.Encode.encode_message(msg.encCommentMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:encCommentMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_bcallMessage(acc, msg) do
        try do
          case msg.bcallMessage do
            nil -> acc
            _ -> [acc, "\xC2\x04", Protox.Encode.encode_message(msg.bcallMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:bcallMessage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_lottieStickerMessage(acc, msg) do
        try do
          case msg.lottieStickerMessage do
            nil -> acc
            _ -> [acc, "\xD2\x04", Protox.Encode.encode_message(msg.lottieStickerMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:lottieStickerMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_eventMessage(acc, msg) do
        try do
          case msg.eventMessage do
            nil -> acc
            _ -> [acc, "\xDA\x04", Protox.Encode.encode_message(msg.eventMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:eventMessage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_encEventResponseMessage(acc, msg) do
        try do
          case msg.encEventResponseMessage do
            nil -> acc
            _ -> [acc, "\xE2\x04", Protox.Encode.encode_message(msg.encEventResponseMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:encEventResponseMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_commentMessage(acc, msg) do
        try do
          case msg.commentMessage do
            nil -> acc
            _ -> [acc, "\xEA\x04", Protox.Encode.encode_message(msg.commentMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:commentMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_newsletterAdminInviteMessage(acc, msg) do
        try do
          case msg.newsletterAdminInviteMessage do
            nil -> acc
            _ -> [acc, "\xF2\x04", Protox.Encode.encode_message(msg.newsletterAdminInviteMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :newsletterAdminInviteMessage,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_placeholderMessage(acc, msg) do
        try do
          case msg.placeholderMessage do
            nil -> acc
            _ -> [acc, "\x82\x05", Protox.Encode.encode_message(msg.placeholderMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:placeholderMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_secretEncryptedMessage(acc, msg) do
        try do
          case msg.secretEncryptedMessage do
            nil -> acc
            _ -> [acc, "\x92\x05", Protox.Encode.encode_message(msg.secretEncryptedMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:secretEncryptedMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_albumMessage(acc, msg) do
        try do
          case msg.albumMessage do
            nil -> acc
            _ -> [acc, "\x9A\x05", Protox.Encode.encode_message(msg.albumMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:albumMessage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_eventCoverImage(acc, msg) do
        try do
          case msg.eventCoverImage do
            nil -> acc
            _ -> [acc, "\xAA\x05", Protox.Encode.encode_message(msg.eventCoverImage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:eventCoverImage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_stickerPackMessage(acc, msg) do
        try do
          case msg.stickerPackMessage do
            nil -> acc
            _ -> [acc, "\xB2\x05", Protox.Encode.encode_message(msg.stickerPackMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:stickerPackMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusMentionMessage(acc, msg) do
        try do
          case msg.statusMentionMessage do
            nil -> acc
            _ -> [acc, "\xBA\x05", Protox.Encode.encode_message(msg.statusMentionMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusMentionMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pollResultSnapshotMessage(acc, msg) do
        try do
          case msg.pollResultSnapshotMessage do
            nil -> acc
            _ -> [acc, "\xC2\x05", Protox.Encode.encode_message(msg.pollResultSnapshotMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollResultSnapshotMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pollCreationOptionImageMessage(acc, msg) do
        try do
          case msg.pollCreationOptionImageMessage do
            nil ->
              acc

            _ ->
              [acc, "\xD2\x05", Protox.Encode.encode_message(msg.pollCreationOptionImageMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :pollCreationOptionImageMessage,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_associatedChildMessage(acc, msg) do
        try do
          case msg.associatedChildMessage do
            nil -> acc
            _ -> [acc, "\xDA\x05", Protox.Encode.encode_message(msg.associatedChildMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:associatedChildMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_groupStatusMentionMessage(acc, msg) do
        try do
          case msg.groupStatusMentionMessage do
            nil -> acc
            _ -> [acc, "\xE2\x05", Protox.Encode.encode_message(msg.groupStatusMentionMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupStatusMentionMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pollCreationMessageV4(acc, msg) do
        try do
          case msg.pollCreationMessageV4 do
            nil -> acc
            _ -> [acc, "\xEA\x05", Protox.Encode.encode_message(msg.pollCreationMessageV4)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollCreationMessageV4, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusAddYours(acc, msg) do
        try do
          case msg.statusAddYours do
            nil -> acc
            _ -> [acc, "\xFA\x05", Protox.Encode.encode_message(msg.statusAddYours)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusAddYours, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_groupStatusMessage(acc, msg) do
        try do
          case msg.groupStatusMessage do
            nil -> acc
            _ -> [acc, "\x82\x06", Protox.Encode.encode_message(msg.groupStatusMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupStatusMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_richResponseMessage(acc, msg) do
        try do
          case msg.richResponseMessage do
            nil -> acc
            _ -> [acc, "\x8A\x06", Protox.Encode.encode_message(msg.richResponseMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:richResponseMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusNotificationMessage(acc, msg) do
        try do
          case msg.statusNotificationMessage do
            nil -> acc
            _ -> [acc, "\x92\x06", Protox.Encode.encode_message(msg.statusNotificationMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusNotificationMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_limitSharingMessage(acc, msg) do
        try do
          case msg.limitSharingMessage do
            nil -> acc
            _ -> [acc, "\x9A\x06", Protox.Encode.encode_message(msg.limitSharingMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:limitSharingMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botTaskMessage(acc, msg) do
        try do
          case msg.botTaskMessage do
            nil -> acc
            _ -> [acc, "\xA2\x06", Protox.Encode.encode_message(msg.botTaskMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botTaskMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_questionMessage(acc, msg) do
        try do
          case msg.questionMessage do
            nil -> acc
            _ -> [acc, "\xAA\x06", Protox.Encode.encode_message(msg.questionMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:questionMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messageHistoryNotice(acc, msg) do
        try do
          case msg.messageHistoryNotice do
            nil -> acc
            _ -> [acc, "\xB2\x06", Protox.Encode.encode_message(msg.messageHistoryNotice)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageHistoryNotice, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_groupStatusMessageV2(acc, msg) do
        try do
          case msg.groupStatusMessageV2 do
            nil -> acc
            _ -> [acc, "\xBA\x06", Protox.Encode.encode_message(msg.groupStatusMessageV2)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupStatusMessageV2, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botForwardedMessage(acc, msg) do
        try do
          case msg.botForwardedMessage do
            nil -> acc
            _ -> [acc, "\xC2\x06", Protox.Encode.encode_message(msg.botForwardedMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botForwardedMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusQuestionAnswerMessage(acc, msg) do
        try do
          case msg.statusQuestionAnswerMessage do
            nil -> acc
            _ -> [acc, "\xCA\x06", Protox.Encode.encode_message(msg.statusQuestionAnswerMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusQuestionAnswerMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_questionReplyMessage(acc, msg) do
        try do
          case msg.questionReplyMessage do
            nil -> acc
            _ -> [acc, "\xD2\x06", Protox.Encode.encode_message(msg.questionReplyMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:questionReplyMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_questionResponseMessage(acc, msg) do
        try do
          case msg.questionResponseMessage do
            nil -> acc
            _ -> [acc, "\xDA\x06", Protox.Encode.encode_message(msg.questionResponseMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:questionResponseMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusQuotedMessage(acc, msg) do
        try do
          case msg.statusQuotedMessage do
            nil -> acc
            _ -> [acc, "\xEA\x06", Protox.Encode.encode_message(msg.statusQuotedMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusQuotedMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusStickerInteractionMessage(acc, msg) do
        try do
          case msg.statusStickerInteractionMessage do
            nil ->
              acc

            _ ->
              [acc, "\xF2\x06", Protox.Encode.encode_message(msg.statusStickerInteractionMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :statusStickerInteractionMessage,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_pollCreationMessageV5(acc, msg) do
        try do
          case msg.pollCreationMessageV5 do
            nil -> acc
            _ -> [acc, "\xFA\x06", Protox.Encode.encode_message(msg.pollCreationMessageV5)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollCreationMessageV5, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_newsletterFollowerInviteMessageV2(acc, msg) do
        try do
          case msg.newsletterFollowerInviteMessageV2 do
            nil ->
              acc

            _ ->
              [acc, "\x8A\a", Protox.Encode.encode_message(msg.newsletterFollowerInviteMessageV2)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :newsletterFollowerInviteMessageV2,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_pollResultSnapshotMessageV3(acc, msg) do
        try do
          case msg.pollResultSnapshotMessageV3 do
            nil -> acc
            _ -> [acc, "\x9A\a", Protox.Encode.encode_message(msg.pollResultSnapshotMessageV3)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollResultSnapshotMessageV3, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_newsletterAdminProfileMessage(acc, msg) do
        try do
          case msg.newsletterAdminProfileMessage do
            nil -> acc
            _ -> [acc, "\xA2\a", Protox.Encode.encode_message(msg.newsletterAdminProfileMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :newsletterAdminProfileMessage,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_newsletterAdminProfileMessageV2(acc, msg) do
        try do
          case msg.newsletterAdminProfileMessageV2 do
            nil ->
              acc

            _ ->
              [acc, "\xAA\a", Protox.Encode.encode_message(msg.newsletterAdminProfileMessageV2)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :newsletterAdminProfileMessageV2,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_spoilerMessage(acc, msg) do
        try do
          case msg.spoilerMessage do
            nil -> acc
            _ -> [acc, "\xB2\a", Protox.Encode.encode_message(msg.spoilerMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:spoilerMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pollCreationMessageV6(acc, msg) do
        try do
          case msg.pollCreationMessageV6 do
            nil -> acc
            _ -> [acc, "\xBA\a", Protox.Encode.encode_message(msg.pollCreationMessageV6)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollCreationMessageV6, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_conditionalRevealMessage(acc, msg) do
        try do
          case msg.conditionalRevealMessage do
            nil -> acc
            _ -> [acc, "\xC2\a", Protox.Encode.encode_message(msg.conditionalRevealMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:conditionalRevealMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pollAddOptionMessage(acc, msg) do
        try do
          case msg.pollAddOptionMessage do
            nil -> acc
            _ -> [acc, "\xCA\a", Protox.Encode.encode_message(msg.pollAddOptionMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollAddOptionMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_eventInviteMessage(acc, msg) do
        try do
          case msg.eventInviteMessage do
            nil -> acc
            _ -> [acc, "\xD2\a", Protox.Encode.encode_message(msg.eventInviteMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:eventInviteMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_groupRootKeyShare(acc, msg) do
        try do
          case msg.groupRootKeyShare do
            nil -> acc
            _ -> [acc, "\xDA\a", Protox.Encode.encode_message(msg.groupRootKeyShare)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupRootKeyShare, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_paymentReminderMessage(acc, msg) do
        try do
          case msg.paymentReminderMessage do
            nil -> acc
            _ -> [acc, "\xE2\a", Protox.Encode.encode_message(msg.paymentReminderMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:paymentReminderMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_splitPaymentMessage(acc, msg) do
        try do
          case msg.splitPaymentMessage do
            nil -> acc
            _ -> [acc, "\xEA\a", Protox.Encode.encode_message(msg.splitPaymentMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:splitPaymentMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_newsletterAdminProfileStatusMessage(acc, msg) do
        try do
          case msg.newsletterAdminProfileStatusMessage do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xF2\a",
                Protox.Encode.encode_message(msg.newsletterAdminProfileStatusMessage)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :newsletterAdminProfileStatusMessage,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_rootSecretDistributeMessage(acc, msg) do
        try do
          case msg.rootSecretDistributeMessage do
            nil -> acc
            _ -> [acc, "\xFA\a", Protox.Encode.encode_message(msg.rootSecretDistributeMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:rootSecretDistributeMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_splitPaymentUpdateMessage(acc, msg) do
        try do
          case msg.splitPaymentUpdateMessage do
            nil -> acc
            _ -> [acc, "\x82\b", Protox.Encode.encode_message(msg.splitPaymentUpdateMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:splitPaymentUpdateMessage, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.Message))
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
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[conversation: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 senderKeyDistributionMessage:
                   Protox.MergeMessage.merge(
                     msg.senderKeyDistributionMessage,
                     WAWebProtobufsE2E.SenderKeyDistributionMessage.decode!(delimited)
                   )
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 imageMessage:
                   Protox.MergeMessage.merge(
                     msg.imageMessage,
                     WAWebProtobufsE2E.ImageMessage.decode!(delimited)
                   )
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 contactMessage:
                   Protox.MergeMessage.merge(
                     msg.contactMessage,
                     WAWebProtobufsE2E.ContactMessage.decode!(delimited)
                   )
               ], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 locationMessage:
                   Protox.MergeMessage.merge(
                     msg.locationMessage,
                     WAWebProtobufsE2E.LocationMessage.decode!(delimited)
                   )
               ], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 extendedTextMessage:
                   Protox.MergeMessage.merge(
                     msg.extendedTextMessage,
                     WAWebProtobufsE2E.ExtendedTextMessage.decode!(delimited)
                   )
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 documentMessage:
                   Protox.MergeMessage.merge(
                     msg.documentMessage,
                     WAWebProtobufsE2E.DocumentMessage.decode!(delimited)
                   )
               ], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 audioMessage:
                   Protox.MergeMessage.merge(
                     msg.audioMessage,
                     WAWebProtobufsE2E.AudioMessage.decode!(delimited)
                   )
               ], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 videoMessage:
                   Protox.MergeMessage.merge(
                     msg.videoMessage,
                     WAWebProtobufsE2E.VideoMessage.decode!(delimited)
                   )
               ], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 call:
                   Protox.MergeMessage.merge(msg.call, WAWebProtobufsE2E.Call.decode!(delimited))
               ], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 chat:
                   Protox.MergeMessage.merge(msg.chat, WAWebProtobufsE2E.Chat.decode!(delimited))
               ], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 protocolMessage:
                   Protox.MergeMessage.merge(
                     msg.protocolMessage,
                     WAWebProtobufsE2E.ProtocolMessage.decode!(delimited)
                   )
               ], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 contactsArrayMessage:
                   Protox.MergeMessage.merge(
                     msg.contactsArrayMessage,
                     WAWebProtobufsE2E.ContactsArrayMessage.decode!(delimited)
                   )
               ], rest}

            {14, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 highlyStructuredMessage:
                   Protox.MergeMessage.merge(
                     msg.highlyStructuredMessage,
                     WAWebProtobufsE2E.HighlyStructuredMessage.decode!(delimited)
                   )
               ], rest}

            {15, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 fastRatchetKeySenderKeyDistributionMessage:
                   Protox.MergeMessage.merge(
                     msg.fastRatchetKeySenderKeyDistributionMessage,
                     WAWebProtobufsE2E.SenderKeyDistributionMessage.decode!(delimited)
                   )
               ], rest}

            {16, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 sendPaymentMessage:
                   Protox.MergeMessage.merge(
                     msg.sendPaymentMessage,
                     WAWebProtobufsE2E.SendPaymentMessage.decode!(delimited)
                   )
               ], rest}

            {18, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 liveLocationMessage:
                   Protox.MergeMessage.merge(
                     msg.liveLocationMessage,
                     WAWebProtobufsE2E.LiveLocationMessage.decode!(delimited)
                   )
               ], rest}

            {22, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 requestPaymentMessage:
                   Protox.MergeMessage.merge(
                     msg.requestPaymentMessage,
                     WAWebProtobufsE2E.RequestPaymentMessage.decode!(delimited)
                   )
               ], rest}

            {23, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 declinePaymentRequestMessage:
                   Protox.MergeMessage.merge(
                     msg.declinePaymentRequestMessage,
                     WAWebProtobufsE2E.DeclinePaymentRequestMessage.decode!(delimited)
                   )
               ], rest}

            {24, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 cancelPaymentRequestMessage:
                   Protox.MergeMessage.merge(
                     msg.cancelPaymentRequestMessage,
                     WAWebProtobufsE2E.CancelPaymentRequestMessage.decode!(delimited)
                   )
               ], rest}

            {25, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 templateMessage:
                   Protox.MergeMessage.merge(
                     msg.templateMessage,
                     WAWebProtobufsE2E.TemplateMessage.decode!(delimited)
                   )
               ], rest}

            {26, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 stickerMessage:
                   Protox.MergeMessage.merge(
                     msg.stickerMessage,
                     WAWebProtobufsE2E.StickerMessage.decode!(delimited)
                   )
               ], rest}

            {28, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 groupInviteMessage:
                   Protox.MergeMessage.merge(
                     msg.groupInviteMessage,
                     WAWebProtobufsE2E.GroupInviteMessage.decode!(delimited)
                   )
               ], rest}

            {29, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 templateButtonReplyMessage:
                   Protox.MergeMessage.merge(
                     msg.templateButtonReplyMessage,
                     WAWebProtobufsE2E.TemplateButtonReplyMessage.decode!(delimited)
                   )
               ], rest}

            {30, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 productMessage:
                   Protox.MergeMessage.merge(
                     msg.productMessage,
                     WAWebProtobufsE2E.ProductMessage.decode!(delimited)
                   )
               ], rest}

            {31, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 deviceSentMessage:
                   Protox.MergeMessage.merge(
                     msg.deviceSentMessage,
                     WAWebProtobufsE2E.DeviceSentMessage.decode!(delimited)
                   )
               ], rest}

            {35, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 messageContextInfo:
                   Protox.MergeMessage.merge(
                     msg.messageContextInfo,
                     WAWebProtobufsE2E.MessageContextInfo.decode!(delimited)
                   )
               ], rest}

            {36, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 listMessage:
                   Protox.MergeMessage.merge(
                     msg.listMessage,
                     WAWebProtobufsE2E.ListMessage.decode!(delimited)
                   )
               ], rest}

            {37, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 viewOnceMessage:
                   Protox.MergeMessage.merge(
                     msg.viewOnceMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {38, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 orderMessage:
                   Protox.MergeMessage.merge(
                     msg.orderMessage,
                     WAWebProtobufsE2E.OrderMessage.decode!(delimited)
                   )
               ], rest}

            {39, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 listResponseMessage:
                   Protox.MergeMessage.merge(
                     msg.listResponseMessage,
                     WAWebProtobufsE2E.ListResponseMessage.decode!(delimited)
                   )
               ], rest}

            {40, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 ephemeralMessage:
                   Protox.MergeMessage.merge(
                     msg.ephemeralMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {41, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 invoiceMessage:
                   Protox.MergeMessage.merge(
                     msg.invoiceMessage,
                     WAWebProtobufsE2E.InvoiceMessage.decode!(delimited)
                   )
               ], rest}

            {42, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 buttonsMessage:
                   Protox.MergeMessage.merge(
                     msg.buttonsMessage,
                     WAWebProtobufsE2E.ButtonsMessage.decode!(delimited)
                   )
               ], rest}

            {43, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 buttonsResponseMessage:
                   Protox.MergeMessage.merge(
                     msg.buttonsResponseMessage,
                     WAWebProtobufsE2E.ButtonsResponseMessage.decode!(delimited)
                   )
               ], rest}

            {44, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 paymentInviteMessage:
                   Protox.MergeMessage.merge(
                     msg.paymentInviteMessage,
                     WAWebProtobufsE2E.PaymentInviteMessage.decode!(delimited)
                   )
               ], rest}

            {45, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 interactiveMessage:
                   Protox.MergeMessage.merge(
                     msg.interactiveMessage,
                     WAWebProtobufsE2E.InteractiveMessage.decode!(delimited)
                   )
               ], rest}

            {46, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 reactionMessage:
                   Protox.MergeMessage.merge(
                     msg.reactionMessage,
                     WAWebProtobufsE2E.ReactionMessage.decode!(delimited)
                   )
               ], rest}

            {47, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 stickerSyncRmrMessage:
                   Protox.MergeMessage.merge(
                     msg.stickerSyncRmrMessage,
                     WAWebProtobufsE2E.StickerSyncRMRMessage.decode!(delimited)
                   )
               ], rest}

            {48, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 interactiveResponseMessage:
                   Protox.MergeMessage.merge(
                     msg.interactiveResponseMessage,
                     WAWebProtobufsE2E.InteractiveResponseMessage.decode!(delimited)
                   )
               ], rest}

            {49, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pollCreationMessage:
                   Protox.MergeMessage.merge(
                     msg.pollCreationMessage,
                     WAWebProtobufsE2E.PollCreationMessage.decode!(delimited)
                   )
               ], rest}

            {50, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pollUpdateMessage:
                   Protox.MergeMessage.merge(
                     msg.pollUpdateMessage,
                     WAWebProtobufsE2E.PollUpdateMessage.decode!(delimited)
                   )
               ], rest}

            {51, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 keepInChatMessage:
                   Protox.MergeMessage.merge(
                     msg.keepInChatMessage,
                     WAWebProtobufsE2E.KeepInChatMessage.decode!(delimited)
                   )
               ], rest}

            {53, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 documentWithCaptionMessage:
                   Protox.MergeMessage.merge(
                     msg.documentWithCaptionMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {54, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 requestPhoneNumberMessage:
                   Protox.MergeMessage.merge(
                     msg.requestPhoneNumberMessage,
                     WAWebProtobufsE2E.RequestPhoneNumberMessage.decode!(delimited)
                   )
               ], rest}

            {55, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 viewOnceMessageV2:
                   Protox.MergeMessage.merge(
                     msg.viewOnceMessageV2,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {56, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 encReactionMessage:
                   Protox.MergeMessage.merge(
                     msg.encReactionMessage,
                     WAWebProtobufsE2E.EncReactionMessage.decode!(delimited)
                   )
               ], rest}

            {58, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 editedMessage:
                   Protox.MergeMessage.merge(
                     msg.editedMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {59, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 viewOnceMessageV2Extension:
                   Protox.MergeMessage.merge(
                     msg.viewOnceMessageV2Extension,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {60, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pollCreationMessageV2:
                   Protox.MergeMessage.merge(
                     msg.pollCreationMessageV2,
                     WAWebProtobufsE2E.PollCreationMessage.decode!(delimited)
                   )
               ], rest}

            {61, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 scheduledCallCreationMessage:
                   Protox.MergeMessage.merge(
                     msg.scheduledCallCreationMessage,
                     WAWebProtobufsE2E.ScheduledCallCreationMessage.decode!(delimited)
                   )
               ], rest}

            {62, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 groupMentionedMessage:
                   Protox.MergeMessage.merge(
                     msg.groupMentionedMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {63, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pinInChatMessage:
                   Protox.MergeMessage.merge(
                     msg.pinInChatMessage,
                     WAWebProtobufsE2E.PinInChatMessage.decode!(delimited)
                   )
               ], rest}

            {64, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pollCreationMessageV3:
                   Protox.MergeMessage.merge(
                     msg.pollCreationMessageV3,
                     WAWebProtobufsE2E.PollCreationMessage.decode!(delimited)
                   )
               ], rest}

            {65, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 scheduledCallEditMessage:
                   Protox.MergeMessage.merge(
                     msg.scheduledCallEditMessage,
                     WAWebProtobufsE2E.ScheduledCallEditMessage.decode!(delimited)
                   )
               ], rest}

            {66, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 ptvMessage:
                   Protox.MergeMessage.merge(
                     msg.ptvMessage,
                     WAWebProtobufsE2E.VideoMessage.decode!(delimited)
                   )
               ], rest}

            {67, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botInvokeMessage:
                   Protox.MergeMessage.merge(
                     msg.botInvokeMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {69, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 callLogMesssage:
                   Protox.MergeMessage.merge(
                     msg.callLogMesssage,
                     WAWebProtobufsE2E.CallLogMessage.decode!(delimited)
                   )
               ], rest}

            {70, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 messageHistoryBundle:
                   Protox.MergeMessage.merge(
                     msg.messageHistoryBundle,
                     WAWebProtobufsE2E.MessageHistoryBundle.decode!(delimited)
                   )
               ], rest}

            {71, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 encCommentMessage:
                   Protox.MergeMessage.merge(
                     msg.encCommentMessage,
                     WAWebProtobufsE2E.EncCommentMessage.decode!(delimited)
                   )
               ], rest}

            {72, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 bcallMessage:
                   Protox.MergeMessage.merge(
                     msg.bcallMessage,
                     WAWebProtobufsE2E.BCallMessage.decode!(delimited)
                   )
               ], rest}

            {74, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 lottieStickerMessage:
                   Protox.MergeMessage.merge(
                     msg.lottieStickerMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {75, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 eventMessage:
                   Protox.MergeMessage.merge(
                     msg.eventMessage,
                     WAWebProtobufsE2E.EventMessage.decode!(delimited)
                   )
               ], rest}

            {76, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 encEventResponseMessage:
                   Protox.MergeMessage.merge(
                     msg.encEventResponseMessage,
                     WAWebProtobufsE2E.EncEventResponseMessage.decode!(delimited)
                   )
               ], rest}

            {77, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 commentMessage:
                   Protox.MergeMessage.merge(
                     msg.commentMessage,
                     WAWebProtobufsE2E.CommentMessage.decode!(delimited)
                   )
               ], rest}

            {78, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 newsletterAdminInviteMessage:
                   Protox.MergeMessage.merge(
                     msg.newsletterAdminInviteMessage,
                     WAWebProtobufsE2E.NewsletterAdminInviteMessage.decode!(delimited)
                   )
               ], rest}

            {80, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 placeholderMessage:
                   Protox.MergeMessage.merge(
                     msg.placeholderMessage,
                     WAWebProtobufsE2E.PlaceholderMessage.decode!(delimited)
                   )
               ], rest}

            {82, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 secretEncryptedMessage:
                   Protox.MergeMessage.merge(
                     msg.secretEncryptedMessage,
                     WAWebProtobufsE2E.SecretEncryptedMessage.decode!(delimited)
                   )
               ], rest}

            {83, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 albumMessage:
                   Protox.MergeMessage.merge(
                     msg.albumMessage,
                     WAWebProtobufsE2E.AlbumMessage.decode!(delimited)
                   )
               ], rest}

            {85, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 eventCoverImage:
                   Protox.MergeMessage.merge(
                     msg.eventCoverImage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {86, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 stickerPackMessage:
                   Protox.MergeMessage.merge(
                     msg.stickerPackMessage,
                     WAWebProtobufsE2E.StickerPackMessage.decode!(delimited)
                   )
               ], rest}

            {87, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 statusMentionMessage:
                   Protox.MergeMessage.merge(
                     msg.statusMentionMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {88, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pollResultSnapshotMessage:
                   Protox.MergeMessage.merge(
                     msg.pollResultSnapshotMessage,
                     WAWebProtobufsE2E.PollResultSnapshotMessage.decode!(delimited)
                   )
               ], rest}

            {90, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pollCreationOptionImageMessage:
                   Protox.MergeMessage.merge(
                     msg.pollCreationOptionImageMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {91, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 associatedChildMessage:
                   Protox.MergeMessage.merge(
                     msg.associatedChildMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {92, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 groupStatusMentionMessage:
                   Protox.MergeMessage.merge(
                     msg.groupStatusMentionMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {93, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pollCreationMessageV4:
                   Protox.MergeMessage.merge(
                     msg.pollCreationMessageV4,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {95, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 statusAddYours:
                   Protox.MergeMessage.merge(
                     msg.statusAddYours,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {96, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 groupStatusMessage:
                   Protox.MergeMessage.merge(
                     msg.groupStatusMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {97, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 richResponseMessage:
                   Protox.MergeMessage.merge(
                     msg.richResponseMessage,
                     WAWebProtobufsE2E.AIRichResponseMessage.decode!(delimited)
                   )
               ], rest}

            {98, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 statusNotificationMessage:
                   Protox.MergeMessage.merge(
                     msg.statusNotificationMessage,
                     WAWebProtobufsE2E.StatusNotificationMessage.decode!(delimited)
                   )
               ], rest}

            {99, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 limitSharingMessage:
                   Protox.MergeMessage.merge(
                     msg.limitSharingMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {100, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botTaskMessage:
                   Protox.MergeMessage.merge(
                     msg.botTaskMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {101, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 questionMessage:
                   Protox.MergeMessage.merge(
                     msg.questionMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {102, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 messageHistoryNotice:
                   Protox.MergeMessage.merge(
                     msg.messageHistoryNotice,
                     WAWebProtobufsE2E.MessageHistoryNotice.decode!(delimited)
                   )
               ], rest}

            {103, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 groupStatusMessageV2:
                   Protox.MergeMessage.merge(
                     msg.groupStatusMessageV2,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {104, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botForwardedMessage:
                   Protox.MergeMessage.merge(
                     msg.botForwardedMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {105, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 statusQuestionAnswerMessage:
                   Protox.MergeMessage.merge(
                     msg.statusQuestionAnswerMessage,
                     WAWebProtobufsE2E.StatusQuestionAnswerMessage.decode!(delimited)
                   )
               ], rest}

            {106, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 questionReplyMessage:
                   Protox.MergeMessage.merge(
                     msg.questionReplyMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {107, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 questionResponseMessage:
                   Protox.MergeMessage.merge(
                     msg.questionResponseMessage,
                     WAWebProtobufsE2E.QuestionResponseMessage.decode!(delimited)
                   )
               ], rest}

            {109, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 statusQuotedMessage:
                   Protox.MergeMessage.merge(
                     msg.statusQuotedMessage,
                     WAWebProtobufsE2E.StatusQuotedMessage.decode!(delimited)
                   )
               ], rest}

            {110, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 statusStickerInteractionMessage:
                   Protox.MergeMessage.merge(
                     msg.statusStickerInteractionMessage,
                     WAWebProtobufsE2E.StatusStickerInteractionMessage.decode!(delimited)
                   )
               ], rest}

            {111, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pollCreationMessageV5:
                   Protox.MergeMessage.merge(
                     msg.pollCreationMessageV5,
                     WAWebProtobufsE2E.PollCreationMessage.decode!(delimited)
                   )
               ], rest}

            {113, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 newsletterFollowerInviteMessageV2:
                   Protox.MergeMessage.merge(
                     msg.newsletterFollowerInviteMessageV2,
                     WAWebProtobufsE2E.NewsletterFollowerInviteMessage.decode!(delimited)
                   )
               ], rest}

            {115, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pollResultSnapshotMessageV3:
                   Protox.MergeMessage.merge(
                     msg.pollResultSnapshotMessageV3,
                     WAWebProtobufsE2E.PollResultSnapshotMessage.decode!(delimited)
                   )
               ], rest}

            {116, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 newsletterAdminProfileMessage:
                   Protox.MergeMessage.merge(
                     msg.newsletterAdminProfileMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {117, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 newsletterAdminProfileMessageV2:
                   Protox.MergeMessage.merge(
                     msg.newsletterAdminProfileMessageV2,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {118, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 spoilerMessage:
                   Protox.MergeMessage.merge(
                     msg.spoilerMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {119, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pollCreationMessageV6:
                   Protox.MergeMessage.merge(
                     msg.pollCreationMessageV6,
                     WAWebProtobufsE2E.PollCreationMessage.decode!(delimited)
                   )
               ], rest}

            {120, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 conditionalRevealMessage:
                   Protox.MergeMessage.merge(
                     msg.conditionalRevealMessage,
                     WAWebProtobufsE2E.ConditionalRevealMessage.decode!(delimited)
                   )
               ], rest}

            {121, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pollAddOptionMessage:
                   Protox.MergeMessage.merge(
                     msg.pollAddOptionMessage,
                     WAWebProtobufsE2E.PollAddOptionMessage.decode!(delimited)
                   )
               ], rest}

            {122, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 eventInviteMessage:
                   Protox.MergeMessage.merge(
                     msg.eventInviteMessage,
                     WAWebProtobufsE2E.EventInviteMessage.decode!(delimited)
                   )
               ], rest}

            {123, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 groupRootKeyShare:
                   Protox.MergeMessage.merge(
                     msg.groupRootKeyShare,
                     WAWebProtobufsE2E.GroupRootKeyShare.decode!(delimited)
                   )
               ], rest}

            {124, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 paymentReminderMessage:
                   Protox.MergeMessage.merge(
                     msg.paymentReminderMessage,
                     WAWebProtobufsE2E.PaymentReminderMessage.decode!(delimited)
                   )
               ], rest}

            {125, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 splitPaymentMessage:
                   Protox.MergeMessage.merge(
                     msg.splitPaymentMessage,
                     WAWebProtobufsE2E.SplitPaymentMessage.decode!(delimited)
                   )
               ], rest}

            {126, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 newsletterAdminProfileStatusMessage:
                   Protox.MergeMessage.merge(
                     msg.newsletterAdminProfileStatusMessage,
                     WAWebProtobufsE2E.FutureProofMessage.decode!(delimited)
                   )
               ], rest}

            {127, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 rootSecretDistributeMessage:
                   Protox.MergeMessage.merge(
                     msg.rootSecretDistributeMessage,
                     WAWebProtobufsE2E.RootSecretDistributeMessage.decode!(delimited)
                   )
               ], rest}

            {128, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 splitPaymentUpdateMessage:
                   Protox.MergeMessage.merge(
                     msg.splitPaymentUpdateMessage,
                     WAWebProtobufsE2E.SplitPaymentUpdateMessage.decode!(delimited)
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
        WAWebProtobufsE2E.Message,
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
        1 => {:conversation, {:scalar, ""}, :string},
        2 =>
          {:senderKeyDistributionMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.SenderKeyDistributionMessage}},
        3 => {:imageMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.ImageMessage}},
        4 => {:contactMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContactMessage}},
        5 => {:locationMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.LocationMessage}},
        6 =>
          {:extendedTextMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ExtendedTextMessage}},
        7 => {:documentMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.DocumentMessage}},
        8 => {:audioMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.AudioMessage}},
        9 => {:videoMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.VideoMessage}},
        10 => {:call, {:scalar, nil}, {:message, WAWebProtobufsE2E.Call}},
        11 => {:chat, {:scalar, nil}, {:message, WAWebProtobufsE2E.Chat}},
        12 => {:protocolMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.ProtocolMessage}},
        13 =>
          {:contactsArrayMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ContactsArrayMessage}},
        14 =>
          {:highlyStructuredMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.HighlyStructuredMessage}},
        15 =>
          {:fastRatchetKeySenderKeyDistributionMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.SenderKeyDistributionMessage}},
        16 =>
          {:sendPaymentMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.SendPaymentMessage}},
        18 =>
          {:liveLocationMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.LiveLocationMessage}},
        22 =>
          {:requestPaymentMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.RequestPaymentMessage}},
        23 =>
          {:declinePaymentRequestMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.DeclinePaymentRequestMessage}},
        24 =>
          {:cancelPaymentRequestMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.CancelPaymentRequestMessage}},
        25 => {:templateMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.TemplateMessage}},
        26 => {:stickerMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.StickerMessage}},
        28 =>
          {:groupInviteMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.GroupInviteMessage}},
        29 =>
          {:templateButtonReplyMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.TemplateButtonReplyMessage}},
        30 => {:productMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.ProductMessage}},
        31 =>
          {:deviceSentMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.DeviceSentMessage}},
        35 =>
          {:messageContextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.MessageContextInfo}},
        36 => {:listMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.ListMessage}},
        37 =>
          {:viewOnceMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        38 => {:orderMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.OrderMessage}},
        39 =>
          {:listResponseMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ListResponseMessage}},
        40 =>
          {:ephemeralMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        41 => {:invoiceMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.InvoiceMessage}},
        42 => {:buttonsMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.ButtonsMessage}},
        43 =>
          {:buttonsResponseMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ButtonsResponseMessage}},
        44 =>
          {:paymentInviteMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PaymentInviteMessage}},
        45 =>
          {:interactiveMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.InteractiveMessage}},
        46 => {:reactionMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.ReactionMessage}},
        47 =>
          {:stickerSyncRmrMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.StickerSyncRMRMessage}},
        48 =>
          {:interactiveResponseMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.InteractiveResponseMessage}},
        49 =>
          {:pollCreationMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PollCreationMessage}},
        50 =>
          {:pollUpdateMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollUpdateMessage}},
        51 =>
          {:keepInChatMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.KeepInChatMessage}},
        53 =>
          {:documentWithCaptionMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FutureProofMessage}},
        54 =>
          {:requestPhoneNumberMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.RequestPhoneNumberMessage}},
        55 =>
          {:viewOnceMessageV2, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        56 =>
          {:encReactionMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.EncReactionMessage}},
        58 => {:editedMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        59 =>
          {:viewOnceMessageV2Extension, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FutureProofMessage}},
        60 =>
          {:pollCreationMessageV2, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PollCreationMessage}},
        61 =>
          {:scheduledCallCreationMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ScheduledCallCreationMessage}},
        62 =>
          {:groupMentionedMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FutureProofMessage}},
        63 => {:pinInChatMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.PinInChatMessage}},
        64 =>
          {:pollCreationMessageV3, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PollCreationMessage}},
        65 =>
          {:scheduledCallEditMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ScheduledCallEditMessage}},
        66 => {:ptvMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.VideoMessage}},
        67 =>
          {:botInvokeMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        69 => {:callLogMesssage, {:scalar, nil}, {:message, WAWebProtobufsE2E.CallLogMessage}},
        70 =>
          {:messageHistoryBundle, {:scalar, nil},
           {:message, WAWebProtobufsE2E.MessageHistoryBundle}},
        71 =>
          {:encCommentMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.EncCommentMessage}},
        72 => {:bcallMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.BCallMessage}},
        74 =>
          {:lottieStickerMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FutureProofMessage}},
        75 => {:eventMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.EventMessage}},
        76 =>
          {:encEventResponseMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.EncEventResponseMessage}},
        77 => {:commentMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.CommentMessage}},
        78 =>
          {:newsletterAdminInviteMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.NewsletterAdminInviteMessage}},
        80 =>
          {:placeholderMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.PlaceholderMessage}},
        82 =>
          {:secretEncryptedMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.SecretEncryptedMessage}},
        83 => {:albumMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.AlbumMessage}},
        85 =>
          {:eventCoverImage, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        86 =>
          {:stickerPackMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.StickerPackMessage}},
        87 =>
          {:statusMentionMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FutureProofMessage}},
        88 =>
          {:pollResultSnapshotMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PollResultSnapshotMessage}},
        90 =>
          {:pollCreationOptionImageMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FutureProofMessage}},
        91 =>
          {:associatedChildMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FutureProofMessage}},
        92 =>
          {:groupStatusMentionMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FutureProofMessage}},
        93 =>
          {:pollCreationMessageV4, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FutureProofMessage}},
        95 => {:statusAddYours, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        96 =>
          {:groupStatusMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        97 =>
          {:richResponseMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.AIRichResponseMessage}},
        98 =>
          {:statusNotificationMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.StatusNotificationMessage}},
        99 =>
          {:limitSharingMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        100 =>
          {:botTaskMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        101 =>
          {:questionMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        102 =>
          {:messageHistoryNotice, {:scalar, nil},
           {:message, WAWebProtobufsE2E.MessageHistoryNotice}},
        103 =>
          {:groupStatusMessageV2, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FutureProofMessage}},
        104 =>
          {:botForwardedMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        105 =>
          {:statusQuestionAnswerMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.StatusQuestionAnswerMessage}},
        106 =>
          {:questionReplyMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FutureProofMessage}},
        107 =>
          {:questionResponseMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.QuestionResponseMessage}},
        109 =>
          {:statusQuotedMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.StatusQuotedMessage}},
        110 =>
          {:statusStickerInteractionMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.StatusStickerInteractionMessage}},
        111 =>
          {:pollCreationMessageV5, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PollCreationMessage}},
        113 =>
          {:newsletterFollowerInviteMessageV2, {:scalar, nil},
           {:message, WAWebProtobufsE2E.NewsletterFollowerInviteMessage}},
        115 =>
          {:pollResultSnapshotMessageV3, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PollResultSnapshotMessage}},
        116 =>
          {:newsletterAdminProfileMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FutureProofMessage}},
        117 =>
          {:newsletterAdminProfileMessageV2, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FutureProofMessage}},
        118 =>
          {:spoilerMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        119 =>
          {:pollCreationMessageV6, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PollCreationMessage}},
        120 =>
          {:conditionalRevealMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ConditionalRevealMessage}},
        121 =>
          {:pollAddOptionMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PollAddOptionMessage}},
        122 =>
          {:eventInviteMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.EventInviteMessage}},
        123 =>
          {:groupRootKeyShare, {:scalar, nil}, {:message, WAWebProtobufsE2E.GroupRootKeyShare}},
        124 =>
          {:paymentReminderMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PaymentReminderMessage}},
        125 =>
          {:splitPaymentMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.SplitPaymentMessage}},
        126 =>
          {:newsletterAdminProfileStatusMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FutureProofMessage}},
        127 =>
          {:rootSecretDistributeMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.RootSecretDistributeMessage}},
        128 =>
          {:splitPaymentUpdateMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.SplitPaymentUpdateMessage}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        albumMessage: {83, {:scalar, nil}, {:message, WAWebProtobufsE2E.AlbumMessage}},
        associatedChildMessage:
          {91, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        audioMessage: {8, {:scalar, nil}, {:message, WAWebProtobufsE2E.AudioMessage}},
        bcallMessage: {72, {:scalar, nil}, {:message, WAWebProtobufsE2E.BCallMessage}},
        botForwardedMessage:
          {104, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        botInvokeMessage: {67, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        botTaskMessage: {100, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        buttonsMessage: {42, {:scalar, nil}, {:message, WAWebProtobufsE2E.ButtonsMessage}},
        buttonsResponseMessage:
          {43, {:scalar, nil}, {:message, WAWebProtobufsE2E.ButtonsResponseMessage}},
        call: {10, {:scalar, nil}, {:message, WAWebProtobufsE2E.Call}},
        callLogMesssage: {69, {:scalar, nil}, {:message, WAWebProtobufsE2E.CallLogMessage}},
        cancelPaymentRequestMessage:
          {24, {:scalar, nil}, {:message, WAWebProtobufsE2E.CancelPaymentRequestMessage}},
        chat: {11, {:scalar, nil}, {:message, WAWebProtobufsE2E.Chat}},
        commentMessage: {77, {:scalar, nil}, {:message, WAWebProtobufsE2E.CommentMessage}},
        conditionalRevealMessage:
          {120, {:scalar, nil}, {:message, WAWebProtobufsE2E.ConditionalRevealMessage}},
        contactMessage: {4, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContactMessage}},
        contactsArrayMessage:
          {13, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContactsArrayMessage}},
        conversation: {1, {:scalar, ""}, :string},
        declinePaymentRequestMessage:
          {23, {:scalar, nil}, {:message, WAWebProtobufsE2E.DeclinePaymentRequestMessage}},
        deviceSentMessage: {31, {:scalar, nil}, {:message, WAWebProtobufsE2E.DeviceSentMessage}},
        documentMessage: {7, {:scalar, nil}, {:message, WAWebProtobufsE2E.DocumentMessage}},
        documentWithCaptionMessage:
          {53, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        editedMessage: {58, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        encCommentMessage: {71, {:scalar, nil}, {:message, WAWebProtobufsE2E.EncCommentMessage}},
        encEventResponseMessage:
          {76, {:scalar, nil}, {:message, WAWebProtobufsE2E.EncEventResponseMessage}},
        encReactionMessage:
          {56, {:scalar, nil}, {:message, WAWebProtobufsE2E.EncReactionMessage}},
        ephemeralMessage: {40, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        eventCoverImage: {85, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        eventInviteMessage:
          {122, {:scalar, nil}, {:message, WAWebProtobufsE2E.EventInviteMessage}},
        eventMessage: {75, {:scalar, nil}, {:message, WAWebProtobufsE2E.EventMessage}},
        extendedTextMessage:
          {6, {:scalar, nil}, {:message, WAWebProtobufsE2E.ExtendedTextMessage}},
        fastRatchetKeySenderKeyDistributionMessage:
          {15, {:scalar, nil}, {:message, WAWebProtobufsE2E.SenderKeyDistributionMessage}},
        groupInviteMessage:
          {28, {:scalar, nil}, {:message, WAWebProtobufsE2E.GroupInviteMessage}},
        groupMentionedMessage:
          {62, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        groupRootKeyShare: {123, {:scalar, nil}, {:message, WAWebProtobufsE2E.GroupRootKeyShare}},
        groupStatusMentionMessage:
          {92, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        groupStatusMessage:
          {96, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        groupStatusMessageV2:
          {103, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        highlyStructuredMessage:
          {14, {:scalar, nil}, {:message, WAWebProtobufsE2E.HighlyStructuredMessage}},
        imageMessage: {3, {:scalar, nil}, {:message, WAWebProtobufsE2E.ImageMessage}},
        interactiveMessage:
          {45, {:scalar, nil}, {:message, WAWebProtobufsE2E.InteractiveMessage}},
        interactiveResponseMessage:
          {48, {:scalar, nil}, {:message, WAWebProtobufsE2E.InteractiveResponseMessage}},
        invoiceMessage: {41, {:scalar, nil}, {:message, WAWebProtobufsE2E.InvoiceMessage}},
        keepInChatMessage: {51, {:scalar, nil}, {:message, WAWebProtobufsE2E.KeepInChatMessage}},
        limitSharingMessage:
          {99, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        listMessage: {36, {:scalar, nil}, {:message, WAWebProtobufsE2E.ListMessage}},
        listResponseMessage:
          {39, {:scalar, nil}, {:message, WAWebProtobufsE2E.ListResponseMessage}},
        liveLocationMessage:
          {18, {:scalar, nil}, {:message, WAWebProtobufsE2E.LiveLocationMessage}},
        locationMessage: {5, {:scalar, nil}, {:message, WAWebProtobufsE2E.LocationMessage}},
        lottieStickerMessage:
          {74, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        messageContextInfo:
          {35, {:scalar, nil}, {:message, WAWebProtobufsE2E.MessageContextInfo}},
        messageHistoryBundle:
          {70, {:scalar, nil}, {:message, WAWebProtobufsE2E.MessageHistoryBundle}},
        messageHistoryNotice:
          {102, {:scalar, nil}, {:message, WAWebProtobufsE2E.MessageHistoryNotice}},
        newsletterAdminInviteMessage:
          {78, {:scalar, nil}, {:message, WAWebProtobufsE2E.NewsletterAdminInviteMessage}},
        newsletterAdminProfileMessage:
          {116, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        newsletterAdminProfileMessageV2:
          {117, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        newsletterAdminProfileStatusMessage:
          {126, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        newsletterFollowerInviteMessageV2:
          {113, {:scalar, nil}, {:message, WAWebProtobufsE2E.NewsletterFollowerInviteMessage}},
        orderMessage: {38, {:scalar, nil}, {:message, WAWebProtobufsE2E.OrderMessage}},
        paymentInviteMessage:
          {44, {:scalar, nil}, {:message, WAWebProtobufsE2E.PaymentInviteMessage}},
        paymentReminderMessage:
          {124, {:scalar, nil}, {:message, WAWebProtobufsE2E.PaymentReminderMessage}},
        pinInChatMessage: {63, {:scalar, nil}, {:message, WAWebProtobufsE2E.PinInChatMessage}},
        placeholderMessage:
          {80, {:scalar, nil}, {:message, WAWebProtobufsE2E.PlaceholderMessage}},
        pollAddOptionMessage:
          {121, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollAddOptionMessage}},
        pollCreationMessage:
          {49, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollCreationMessage}},
        pollCreationMessageV2:
          {60, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollCreationMessage}},
        pollCreationMessageV3:
          {64, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollCreationMessage}},
        pollCreationMessageV4:
          {93, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        pollCreationMessageV5:
          {111, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollCreationMessage}},
        pollCreationMessageV6:
          {119, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollCreationMessage}},
        pollCreationOptionImageMessage:
          {90, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        pollResultSnapshotMessage:
          {88, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollResultSnapshotMessage}},
        pollResultSnapshotMessageV3:
          {115, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollResultSnapshotMessage}},
        pollUpdateMessage: {50, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollUpdateMessage}},
        productMessage: {30, {:scalar, nil}, {:message, WAWebProtobufsE2E.ProductMessage}},
        protocolMessage: {12, {:scalar, nil}, {:message, WAWebProtobufsE2E.ProtocolMessage}},
        ptvMessage: {66, {:scalar, nil}, {:message, WAWebProtobufsE2E.VideoMessage}},
        questionMessage: {101, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        questionReplyMessage:
          {106, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        questionResponseMessage:
          {107, {:scalar, nil}, {:message, WAWebProtobufsE2E.QuestionResponseMessage}},
        reactionMessage: {46, {:scalar, nil}, {:message, WAWebProtobufsE2E.ReactionMessage}},
        requestPaymentMessage:
          {22, {:scalar, nil}, {:message, WAWebProtobufsE2E.RequestPaymentMessage}},
        requestPhoneNumberMessage:
          {54, {:scalar, nil}, {:message, WAWebProtobufsE2E.RequestPhoneNumberMessage}},
        richResponseMessage:
          {97, {:scalar, nil}, {:message, WAWebProtobufsE2E.AIRichResponseMessage}},
        rootSecretDistributeMessage:
          {127, {:scalar, nil}, {:message, WAWebProtobufsE2E.RootSecretDistributeMessage}},
        scheduledCallCreationMessage:
          {61, {:scalar, nil}, {:message, WAWebProtobufsE2E.ScheduledCallCreationMessage}},
        scheduledCallEditMessage:
          {65, {:scalar, nil}, {:message, WAWebProtobufsE2E.ScheduledCallEditMessage}},
        secretEncryptedMessage:
          {82, {:scalar, nil}, {:message, WAWebProtobufsE2E.SecretEncryptedMessage}},
        sendPaymentMessage:
          {16, {:scalar, nil}, {:message, WAWebProtobufsE2E.SendPaymentMessage}},
        senderKeyDistributionMessage:
          {2, {:scalar, nil}, {:message, WAWebProtobufsE2E.SenderKeyDistributionMessage}},
        splitPaymentMessage:
          {125, {:scalar, nil}, {:message, WAWebProtobufsE2E.SplitPaymentMessage}},
        splitPaymentUpdateMessage:
          {128, {:scalar, nil}, {:message, WAWebProtobufsE2E.SplitPaymentUpdateMessage}},
        spoilerMessage: {118, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        statusAddYours: {95, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        statusMentionMessage:
          {87, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        statusNotificationMessage:
          {98, {:scalar, nil}, {:message, WAWebProtobufsE2E.StatusNotificationMessage}},
        statusQuestionAnswerMessage:
          {105, {:scalar, nil}, {:message, WAWebProtobufsE2E.StatusQuestionAnswerMessage}},
        statusQuotedMessage:
          {109, {:scalar, nil}, {:message, WAWebProtobufsE2E.StatusQuotedMessage}},
        statusStickerInteractionMessage:
          {110, {:scalar, nil}, {:message, WAWebProtobufsE2E.StatusStickerInteractionMessage}},
        stickerMessage: {26, {:scalar, nil}, {:message, WAWebProtobufsE2E.StickerMessage}},
        stickerPackMessage:
          {86, {:scalar, nil}, {:message, WAWebProtobufsE2E.StickerPackMessage}},
        stickerSyncRmrMessage:
          {47, {:scalar, nil}, {:message, WAWebProtobufsE2E.StickerSyncRMRMessage}},
        templateButtonReplyMessage:
          {29, {:scalar, nil}, {:message, WAWebProtobufsE2E.TemplateButtonReplyMessage}},
        templateMessage: {25, {:scalar, nil}, {:message, WAWebProtobufsE2E.TemplateMessage}},
        videoMessage: {9, {:scalar, nil}, {:message, WAWebProtobufsE2E.VideoMessage}},
        viewOnceMessage: {37, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        viewOnceMessageV2: {55, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}},
        viewOnceMessageV2Extension:
          {59, {:scalar, nil}, {:message, WAWebProtobufsE2E.FutureProofMessage}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "conversation",
          kind: {:scalar, ""},
          label: :optional,
          name: :conversation,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "senderKeyDistributionMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :senderKeyDistributionMessage,
          tag: 2,
          type: {:message, WAWebProtobufsE2E.SenderKeyDistributionMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "imageMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :imageMessage,
          tag: 3,
          type: {:message, WAWebProtobufsE2E.ImageMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "contactMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :contactMessage,
          tag: 4,
          type: {:message, WAWebProtobufsE2E.ContactMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "locationMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :locationMessage,
          tag: 5,
          type: {:message, WAWebProtobufsE2E.LocationMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "extendedTextMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :extendedTextMessage,
          tag: 6,
          type: {:message, WAWebProtobufsE2E.ExtendedTextMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "documentMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :documentMessage,
          tag: 7,
          type: {:message, WAWebProtobufsE2E.DocumentMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "audioMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :audioMessage,
          tag: 8,
          type: {:message, WAWebProtobufsE2E.AudioMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "videoMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :videoMessage,
          tag: 9,
          type: {:message, WAWebProtobufsE2E.VideoMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "call",
          kind: {:scalar, nil},
          label: :optional,
          name: :call,
          tag: 10,
          type: {:message, WAWebProtobufsE2E.Call}
        },
        %{
          __struct__: Protox.Field,
          json_name: "chat",
          kind: {:scalar, nil},
          label: :optional,
          name: :chat,
          tag: 11,
          type: {:message, WAWebProtobufsE2E.Chat}
        },
        %{
          __struct__: Protox.Field,
          json_name: "protocolMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :protocolMessage,
          tag: 12,
          type: {:message, WAWebProtobufsE2E.ProtocolMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "contactsArrayMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :contactsArrayMessage,
          tag: 13,
          type: {:message, WAWebProtobufsE2E.ContactsArrayMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "highlyStructuredMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :highlyStructuredMessage,
          tag: 14,
          type: {:message, WAWebProtobufsE2E.HighlyStructuredMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "fastRatchetKeySenderKeyDistributionMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :fastRatchetKeySenderKeyDistributionMessage,
          tag: 15,
          type: {:message, WAWebProtobufsE2E.SenderKeyDistributionMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "sendPaymentMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :sendPaymentMessage,
          tag: 16,
          type: {:message, WAWebProtobufsE2E.SendPaymentMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "liveLocationMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :liveLocationMessage,
          tag: 18,
          type: {:message, WAWebProtobufsE2E.LiveLocationMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "requestPaymentMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :requestPaymentMessage,
          tag: 22,
          type: {:message, WAWebProtobufsE2E.RequestPaymentMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "declinePaymentRequestMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :declinePaymentRequestMessage,
          tag: 23,
          type: {:message, WAWebProtobufsE2E.DeclinePaymentRequestMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "cancelPaymentRequestMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :cancelPaymentRequestMessage,
          tag: 24,
          type: {:message, WAWebProtobufsE2E.CancelPaymentRequestMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "templateMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :templateMessage,
          tag: 25,
          type: {:message, WAWebProtobufsE2E.TemplateMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "stickerMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :stickerMessage,
          tag: 26,
          type: {:message, WAWebProtobufsE2E.StickerMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupInviteMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :groupInviteMessage,
          tag: 28,
          type: {:message, WAWebProtobufsE2E.GroupInviteMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "templateButtonReplyMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :templateButtonReplyMessage,
          tag: 29,
          type: {:message, WAWebProtobufsE2E.TemplateButtonReplyMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "productMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :productMessage,
          tag: 30,
          type: {:message, WAWebProtobufsE2E.ProductMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "deviceSentMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :deviceSentMessage,
          tag: 31,
          type: {:message, WAWebProtobufsE2E.DeviceSentMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageContextInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :messageContextInfo,
          tag: 35,
          type: {:message, WAWebProtobufsE2E.MessageContextInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "listMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :listMessage,
          tag: 36,
          type: {:message, WAWebProtobufsE2E.ListMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "viewOnceMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :viewOnceMessage,
          tag: 37,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "orderMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :orderMessage,
          tag: 38,
          type: {:message, WAWebProtobufsE2E.OrderMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "listResponseMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :listResponseMessage,
          tag: 39,
          type: {:message, WAWebProtobufsE2E.ListResponseMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeralMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :ephemeralMessage,
          tag: 40,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "invoiceMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :invoiceMessage,
          tag: 41,
          type: {:message, WAWebProtobufsE2E.InvoiceMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "buttonsMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :buttonsMessage,
          tag: 42,
          type: {:message, WAWebProtobufsE2E.ButtonsMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "buttonsResponseMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :buttonsResponseMessage,
          tag: 43,
          type: {:message, WAWebProtobufsE2E.ButtonsResponseMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "paymentInviteMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :paymentInviteMessage,
          tag: 44,
          type: {:message, WAWebProtobufsE2E.PaymentInviteMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "interactiveMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :interactiveMessage,
          tag: 45,
          type: {:message, WAWebProtobufsE2E.InteractiveMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "reactionMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :reactionMessage,
          tag: 46,
          type: {:message, WAWebProtobufsE2E.ReactionMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "stickerSyncRmrMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :stickerSyncRmrMessage,
          tag: 47,
          type: {:message, WAWebProtobufsE2E.StickerSyncRMRMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "interactiveResponseMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :interactiveResponseMessage,
          tag: 48,
          type: {:message, WAWebProtobufsE2E.InteractiveResponseMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollCreationMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :pollCreationMessage,
          tag: 49,
          type: {:message, WAWebProtobufsE2E.PollCreationMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollUpdateMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :pollUpdateMessage,
          tag: 50,
          type: {:message, WAWebProtobufsE2E.PollUpdateMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "keepInChatMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :keepInChatMessage,
          tag: 51,
          type: {:message, WAWebProtobufsE2E.KeepInChatMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "documentWithCaptionMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :documentWithCaptionMessage,
          tag: 53,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "requestPhoneNumberMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :requestPhoneNumberMessage,
          tag: 54,
          type: {:message, WAWebProtobufsE2E.RequestPhoneNumberMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "viewOnceMessageV2",
          kind: {:scalar, nil},
          label: :optional,
          name: :viewOnceMessageV2,
          tag: 55,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "encReactionMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :encReactionMessage,
          tag: 56,
          type: {:message, WAWebProtobufsE2E.EncReactionMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "editedMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :editedMessage,
          tag: 58,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "viewOnceMessageV2Extension",
          kind: {:scalar, nil},
          label: :optional,
          name: :viewOnceMessageV2Extension,
          tag: 59,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollCreationMessageV2",
          kind: {:scalar, nil},
          label: :optional,
          name: :pollCreationMessageV2,
          tag: 60,
          type: {:message, WAWebProtobufsE2E.PollCreationMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "scheduledCallCreationMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :scheduledCallCreationMessage,
          tag: 61,
          type: {:message, WAWebProtobufsE2E.ScheduledCallCreationMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupMentionedMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :groupMentionedMessage,
          tag: 62,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pinInChatMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :pinInChatMessage,
          tag: 63,
          type: {:message, WAWebProtobufsE2E.PinInChatMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollCreationMessageV3",
          kind: {:scalar, nil},
          label: :optional,
          name: :pollCreationMessageV3,
          tag: 64,
          type: {:message, WAWebProtobufsE2E.PollCreationMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "scheduledCallEditMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :scheduledCallEditMessage,
          tag: 65,
          type: {:message, WAWebProtobufsE2E.ScheduledCallEditMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "ptvMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :ptvMessage,
          tag: 66,
          type: {:message, WAWebProtobufsE2E.VideoMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botInvokeMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :botInvokeMessage,
          tag: 67,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "callLogMesssage",
          kind: {:scalar, nil},
          label: :optional,
          name: :callLogMesssage,
          tag: 69,
          type: {:message, WAWebProtobufsE2E.CallLogMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageHistoryBundle",
          kind: {:scalar, nil},
          label: :optional,
          name: :messageHistoryBundle,
          tag: 70,
          type: {:message, WAWebProtobufsE2E.MessageHistoryBundle}
        },
        %{
          __struct__: Protox.Field,
          json_name: "encCommentMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :encCommentMessage,
          tag: 71,
          type: {:message, WAWebProtobufsE2E.EncCommentMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "bcallMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :bcallMessage,
          tag: 72,
          type: {:message, WAWebProtobufsE2E.BCallMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "lottieStickerMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :lottieStickerMessage,
          tag: 74,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "eventMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :eventMessage,
          tag: 75,
          type: {:message, WAWebProtobufsE2E.EventMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "encEventResponseMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :encEventResponseMessage,
          tag: 76,
          type: {:message, WAWebProtobufsE2E.EncEventResponseMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "commentMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :commentMessage,
          tag: 77,
          type: {:message, WAWebProtobufsE2E.CommentMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "newsletterAdminInviteMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :newsletterAdminInviteMessage,
          tag: 78,
          type: {:message, WAWebProtobufsE2E.NewsletterAdminInviteMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "placeholderMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :placeholderMessage,
          tag: 80,
          type: {:message, WAWebProtobufsE2E.PlaceholderMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "secretEncryptedMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :secretEncryptedMessage,
          tag: 82,
          type: {:message, WAWebProtobufsE2E.SecretEncryptedMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "albumMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :albumMessage,
          tag: 83,
          type: {:message, WAWebProtobufsE2E.AlbumMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "eventCoverImage",
          kind: {:scalar, nil},
          label: :optional,
          name: :eventCoverImage,
          tag: 85,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "stickerPackMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :stickerPackMessage,
          tag: 86,
          type: {:message, WAWebProtobufsE2E.StickerPackMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusMentionMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :statusMentionMessage,
          tag: 87,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollResultSnapshotMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :pollResultSnapshotMessage,
          tag: 88,
          type: {:message, WAWebProtobufsE2E.PollResultSnapshotMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollCreationOptionImageMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :pollCreationOptionImageMessage,
          tag: 90,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "associatedChildMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :associatedChildMessage,
          tag: 91,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupStatusMentionMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :groupStatusMentionMessage,
          tag: 92,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollCreationMessageV4",
          kind: {:scalar, nil},
          label: :optional,
          name: :pollCreationMessageV4,
          tag: 93,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusAddYours",
          kind: {:scalar, nil},
          label: :optional,
          name: :statusAddYours,
          tag: 95,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupStatusMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :groupStatusMessage,
          tag: 96,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "richResponseMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :richResponseMessage,
          tag: 97,
          type: {:message, WAWebProtobufsE2E.AIRichResponseMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusNotificationMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :statusNotificationMessage,
          tag: 98,
          type: {:message, WAWebProtobufsE2E.StatusNotificationMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "limitSharingMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :limitSharingMessage,
          tag: 99,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botTaskMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :botTaskMessage,
          tag: 100,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "questionMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :questionMessage,
          tag: 101,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageHistoryNotice",
          kind: {:scalar, nil},
          label: :optional,
          name: :messageHistoryNotice,
          tag: 102,
          type: {:message, WAWebProtobufsE2E.MessageHistoryNotice}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupStatusMessageV2",
          kind: {:scalar, nil},
          label: :optional,
          name: :groupStatusMessageV2,
          tag: 103,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botForwardedMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :botForwardedMessage,
          tag: 104,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusQuestionAnswerMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :statusQuestionAnswerMessage,
          tag: 105,
          type: {:message, WAWebProtobufsE2E.StatusQuestionAnswerMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "questionReplyMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :questionReplyMessage,
          tag: 106,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "questionResponseMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :questionResponseMessage,
          tag: 107,
          type: {:message, WAWebProtobufsE2E.QuestionResponseMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusQuotedMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :statusQuotedMessage,
          tag: 109,
          type: {:message, WAWebProtobufsE2E.StatusQuotedMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusStickerInteractionMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :statusStickerInteractionMessage,
          tag: 110,
          type: {:message, WAWebProtobufsE2E.StatusStickerInteractionMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollCreationMessageV5",
          kind: {:scalar, nil},
          label: :optional,
          name: :pollCreationMessageV5,
          tag: 111,
          type: {:message, WAWebProtobufsE2E.PollCreationMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "newsletterFollowerInviteMessageV2",
          kind: {:scalar, nil},
          label: :optional,
          name: :newsletterFollowerInviteMessageV2,
          tag: 113,
          type: {:message, WAWebProtobufsE2E.NewsletterFollowerInviteMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollResultSnapshotMessageV3",
          kind: {:scalar, nil},
          label: :optional,
          name: :pollResultSnapshotMessageV3,
          tag: 115,
          type: {:message, WAWebProtobufsE2E.PollResultSnapshotMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "newsletterAdminProfileMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :newsletterAdminProfileMessage,
          tag: 116,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "newsletterAdminProfileMessageV2",
          kind: {:scalar, nil},
          label: :optional,
          name: :newsletterAdminProfileMessageV2,
          tag: 117,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "spoilerMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :spoilerMessage,
          tag: 118,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollCreationMessageV6",
          kind: {:scalar, nil},
          label: :optional,
          name: :pollCreationMessageV6,
          tag: 119,
          type: {:message, WAWebProtobufsE2E.PollCreationMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "conditionalRevealMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :conditionalRevealMessage,
          tag: 120,
          type: {:message, WAWebProtobufsE2E.ConditionalRevealMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollAddOptionMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :pollAddOptionMessage,
          tag: 121,
          type: {:message, WAWebProtobufsE2E.PollAddOptionMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "eventInviteMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :eventInviteMessage,
          tag: 122,
          type: {:message, WAWebProtobufsE2E.EventInviteMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupRootKeyShare",
          kind: {:scalar, nil},
          label: :optional,
          name: :groupRootKeyShare,
          tag: 123,
          type: {:message, WAWebProtobufsE2E.GroupRootKeyShare}
        },
        %{
          __struct__: Protox.Field,
          json_name: "paymentReminderMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :paymentReminderMessage,
          tag: 124,
          type: {:message, WAWebProtobufsE2E.PaymentReminderMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "splitPaymentMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :splitPaymentMessage,
          tag: 125,
          type: {:message, WAWebProtobufsE2E.SplitPaymentMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "newsletterAdminProfileStatusMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :newsletterAdminProfileStatusMessage,
          tag: 126,
          type: {:message, WAWebProtobufsE2E.FutureProofMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "rootSecretDistributeMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :rootSecretDistributeMessage,
          tag: 127,
          type: {:message, WAWebProtobufsE2E.RootSecretDistributeMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "splitPaymentUpdateMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :splitPaymentUpdateMessage,
          tag: 128,
          type: {:message, WAWebProtobufsE2E.SplitPaymentUpdateMessage}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:conversation) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversation",
             kind: {:scalar, ""},
             label: :optional,
             name: :conversation,
             tag: 1,
             type: :string
           }}
        end

        def field_def("conversation") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversation",
             kind: {:scalar, ""},
             label: :optional,
             name: :conversation,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:senderKeyDistributionMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderKeyDistributionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :senderKeyDistributionMessage,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.SenderKeyDistributionMessage}
           }}
        end

        def field_def("senderKeyDistributionMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderKeyDistributionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :senderKeyDistributionMessage,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.SenderKeyDistributionMessage}
           }}
        end

        []
      ),
      (
        def field_def(:imageMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :imageMessage,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.ImageMessage}
           }}
        end

        def field_def("imageMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :imageMessage,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.ImageMessage}
           }}
        end

        []
      ),
      (
        def field_def(:contactMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contactMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :contactMessage,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.ContactMessage}
           }}
        end

        def field_def("contactMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contactMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :contactMessage,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.ContactMessage}
           }}
        end

        []
      ),
      (
        def field_def(:locationMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "locationMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :locationMessage,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.LocationMessage}
           }}
        end

        def field_def("locationMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "locationMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :locationMessage,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.LocationMessage}
           }}
        end

        []
      ),
      (
        def field_def(:extendedTextMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "extendedTextMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :extendedTextMessage,
             tag: 6,
             type: {:message, WAWebProtobufsE2E.ExtendedTextMessage}
           }}
        end

        def field_def("extendedTextMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "extendedTextMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :extendedTextMessage,
             tag: 6,
             type: {:message, WAWebProtobufsE2E.ExtendedTextMessage}
           }}
        end

        []
      ),
      (
        def field_def(:documentMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "documentMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :documentMessage,
             tag: 7,
             type: {:message, WAWebProtobufsE2E.DocumentMessage}
           }}
        end

        def field_def("documentMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "documentMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :documentMessage,
             tag: 7,
             type: {:message, WAWebProtobufsE2E.DocumentMessage}
           }}
        end

        []
      ),
      (
        def field_def(:audioMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "audioMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :audioMessage,
             tag: 8,
             type: {:message, WAWebProtobufsE2E.AudioMessage}
           }}
        end

        def field_def("audioMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "audioMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :audioMessage,
             tag: 8,
             type: {:message, WAWebProtobufsE2E.AudioMessage}
           }}
        end

        []
      ),
      (
        def field_def(:videoMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :videoMessage,
             tag: 9,
             type: {:message, WAWebProtobufsE2E.VideoMessage}
           }}
        end

        def field_def("videoMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :videoMessage,
             tag: 9,
             type: {:message, WAWebProtobufsE2E.VideoMessage}
           }}
        end

        []
      ),
      (
        def field_def(:call) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "call",
             kind: {:scalar, nil},
             label: :optional,
             name: :call,
             tag: 10,
             type: {:message, WAWebProtobufsE2E.Call}
           }}
        end

        def field_def("call") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "call",
             kind: {:scalar, nil},
             label: :optional,
             name: :call,
             tag: 10,
             type: {:message, WAWebProtobufsE2E.Call}
           }}
        end

        []
      ),
      (
        def field_def(:chat) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chat",
             kind: {:scalar, nil},
             label: :optional,
             name: :chat,
             tag: 11,
             type: {:message, WAWebProtobufsE2E.Chat}
           }}
        end

        def field_def("chat") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chat",
             kind: {:scalar, nil},
             label: :optional,
             name: :chat,
             tag: 11,
             type: {:message, WAWebProtobufsE2E.Chat}
           }}
        end

        []
      ),
      (
        def field_def(:protocolMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "protocolMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :protocolMessage,
             tag: 12,
             type: {:message, WAWebProtobufsE2E.ProtocolMessage}
           }}
        end

        def field_def("protocolMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "protocolMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :protocolMessage,
             tag: 12,
             type: {:message, WAWebProtobufsE2E.ProtocolMessage}
           }}
        end

        []
      ),
      (
        def field_def(:contactsArrayMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contactsArrayMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :contactsArrayMessage,
             tag: 13,
             type: {:message, WAWebProtobufsE2E.ContactsArrayMessage}
           }}
        end

        def field_def("contactsArrayMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contactsArrayMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :contactsArrayMessage,
             tag: 13,
             type: {:message, WAWebProtobufsE2E.ContactsArrayMessage}
           }}
        end

        []
      ),
      (
        def field_def(:highlyStructuredMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "highlyStructuredMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :highlyStructuredMessage,
             tag: 14,
             type: {:message, WAWebProtobufsE2E.HighlyStructuredMessage}
           }}
        end

        def field_def("highlyStructuredMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "highlyStructuredMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :highlyStructuredMessage,
             tag: 14,
             type: {:message, WAWebProtobufsE2E.HighlyStructuredMessage}
           }}
        end

        []
      ),
      (
        def field_def(:fastRatchetKeySenderKeyDistributionMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fastRatchetKeySenderKeyDistributionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :fastRatchetKeySenderKeyDistributionMessage,
             tag: 15,
             type: {:message, WAWebProtobufsE2E.SenderKeyDistributionMessage}
           }}
        end

        def field_def("fastRatchetKeySenderKeyDistributionMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fastRatchetKeySenderKeyDistributionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :fastRatchetKeySenderKeyDistributionMessage,
             tag: 15,
             type: {:message, WAWebProtobufsE2E.SenderKeyDistributionMessage}
           }}
        end

        []
      ),
      (
        def field_def(:sendPaymentMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sendPaymentMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :sendPaymentMessage,
             tag: 16,
             type: {:message, WAWebProtobufsE2E.SendPaymentMessage}
           }}
        end

        def field_def("sendPaymentMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sendPaymentMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :sendPaymentMessage,
             tag: 16,
             type: {:message, WAWebProtobufsE2E.SendPaymentMessage}
           }}
        end

        []
      ),
      (
        def field_def(:liveLocationMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "liveLocationMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :liveLocationMessage,
             tag: 18,
             type: {:message, WAWebProtobufsE2E.LiveLocationMessage}
           }}
        end

        def field_def("liveLocationMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "liveLocationMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :liveLocationMessage,
             tag: 18,
             type: {:message, WAWebProtobufsE2E.LiveLocationMessage}
           }}
        end

        []
      ),
      (
        def field_def(:requestPaymentMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestPaymentMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :requestPaymentMessage,
             tag: 22,
             type: {:message, WAWebProtobufsE2E.RequestPaymentMessage}
           }}
        end

        def field_def("requestPaymentMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestPaymentMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :requestPaymentMessage,
             tag: 22,
             type: {:message, WAWebProtobufsE2E.RequestPaymentMessage}
           }}
        end

        []
      ),
      (
        def field_def(:declinePaymentRequestMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "declinePaymentRequestMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :declinePaymentRequestMessage,
             tag: 23,
             type: {:message, WAWebProtobufsE2E.DeclinePaymentRequestMessage}
           }}
        end

        def field_def("declinePaymentRequestMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "declinePaymentRequestMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :declinePaymentRequestMessage,
             tag: 23,
             type: {:message, WAWebProtobufsE2E.DeclinePaymentRequestMessage}
           }}
        end

        []
      ),
      (
        def field_def(:cancelPaymentRequestMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "cancelPaymentRequestMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :cancelPaymentRequestMessage,
             tag: 24,
             type: {:message, WAWebProtobufsE2E.CancelPaymentRequestMessage}
           }}
        end

        def field_def("cancelPaymentRequestMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "cancelPaymentRequestMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :cancelPaymentRequestMessage,
             tag: 24,
             type: {:message, WAWebProtobufsE2E.CancelPaymentRequestMessage}
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
             kind: {:scalar, nil},
             label: :optional,
             name: :templateMessage,
             tag: 25,
             type: {:message, WAWebProtobufsE2E.TemplateMessage}
           }}
        end

        def field_def("templateMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "templateMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :templateMessage,
             tag: 25,
             type: {:message, WAWebProtobufsE2E.TemplateMessage}
           }}
        end

        []
      ),
      (
        def field_def(:stickerMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :stickerMessage,
             tag: 26,
             type: {:message, WAWebProtobufsE2E.StickerMessage}
           }}
        end

        def field_def("stickerMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :stickerMessage,
             tag: 26,
             type: {:message, WAWebProtobufsE2E.StickerMessage}
           }}
        end

        []
      ),
      (
        def field_def(:groupInviteMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupInviteMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupInviteMessage,
             tag: 28,
             type: {:message, WAWebProtobufsE2E.GroupInviteMessage}
           }}
        end

        def field_def("groupInviteMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupInviteMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupInviteMessage,
             tag: 28,
             type: {:message, WAWebProtobufsE2E.GroupInviteMessage}
           }}
        end

        []
      ),
      (
        def field_def(:templateButtonReplyMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "templateButtonReplyMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :templateButtonReplyMessage,
             tag: 29,
             type: {:message, WAWebProtobufsE2E.TemplateButtonReplyMessage}
           }}
        end

        def field_def("templateButtonReplyMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "templateButtonReplyMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :templateButtonReplyMessage,
             tag: 29,
             type: {:message, WAWebProtobufsE2E.TemplateButtonReplyMessage}
           }}
        end

        []
      ),
      (
        def field_def(:productMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "productMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :productMessage,
             tag: 30,
             type: {:message, WAWebProtobufsE2E.ProductMessage}
           }}
        end

        def field_def("productMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "productMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :productMessage,
             tag: 30,
             type: {:message, WAWebProtobufsE2E.ProductMessage}
           }}
        end

        []
      ),
      (
        def field_def(:deviceSentMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceSentMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :deviceSentMessage,
             tag: 31,
             type: {:message, WAWebProtobufsE2E.DeviceSentMessage}
           }}
        end

        def field_def("deviceSentMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceSentMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :deviceSentMessage,
             tag: 31,
             type: {:message, WAWebProtobufsE2E.DeviceSentMessage}
           }}
        end

        []
      ),
      (
        def field_def(:messageContextInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageContextInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :messageContextInfo,
             tag: 35,
             type: {:message, WAWebProtobufsE2E.MessageContextInfo}
           }}
        end

        def field_def("messageContextInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageContextInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :messageContextInfo,
             tag: 35,
             type: {:message, WAWebProtobufsE2E.MessageContextInfo}
           }}
        end

        []
      ),
      (
        def field_def(:listMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "listMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :listMessage,
             tag: 36,
             type: {:message, WAWebProtobufsE2E.ListMessage}
           }}
        end

        def field_def("listMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "listMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :listMessage,
             tag: 36,
             type: {:message, WAWebProtobufsE2E.ListMessage}
           }}
        end

        []
      ),
      (
        def field_def(:viewOnceMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "viewOnceMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :viewOnceMessage,
             tag: 37,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("viewOnceMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "viewOnceMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :viewOnceMessage,
             tag: 37,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:orderMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "orderMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :orderMessage,
             tag: 38,
             type: {:message, WAWebProtobufsE2E.OrderMessage}
           }}
        end

        def field_def("orderMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "orderMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :orderMessage,
             tag: 38,
             type: {:message, WAWebProtobufsE2E.OrderMessage}
           }}
        end

        []
      ),
      (
        def field_def(:listResponseMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "listResponseMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :listResponseMessage,
             tag: 39,
             type: {:message, WAWebProtobufsE2E.ListResponseMessage}
           }}
        end

        def field_def("listResponseMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "listResponseMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :listResponseMessage,
             tag: 39,
             type: {:message, WAWebProtobufsE2E.ListResponseMessage}
           }}
        end

        []
      ),
      (
        def field_def(:ephemeralMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :ephemeralMessage,
             tag: 40,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("ephemeralMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :ephemeralMessage,
             tag: 40,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:invoiceMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "invoiceMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :invoiceMessage,
             tag: 41,
             type: {:message, WAWebProtobufsE2E.InvoiceMessage}
           }}
        end

        def field_def("invoiceMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "invoiceMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :invoiceMessage,
             tag: 41,
             type: {:message, WAWebProtobufsE2E.InvoiceMessage}
           }}
        end

        []
      ),
      (
        def field_def(:buttonsMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "buttonsMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :buttonsMessage,
             tag: 42,
             type: {:message, WAWebProtobufsE2E.ButtonsMessage}
           }}
        end

        def field_def("buttonsMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "buttonsMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :buttonsMessage,
             tag: 42,
             type: {:message, WAWebProtobufsE2E.ButtonsMessage}
           }}
        end

        []
      ),
      (
        def field_def(:buttonsResponseMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "buttonsResponseMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :buttonsResponseMessage,
             tag: 43,
             type: {:message, WAWebProtobufsE2E.ButtonsResponseMessage}
           }}
        end

        def field_def("buttonsResponseMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "buttonsResponseMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :buttonsResponseMessage,
             tag: 43,
             type: {:message, WAWebProtobufsE2E.ButtonsResponseMessage}
           }}
        end

        []
      ),
      (
        def field_def(:paymentInviteMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentInviteMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentInviteMessage,
             tag: 44,
             type: {:message, WAWebProtobufsE2E.PaymentInviteMessage}
           }}
        end

        def field_def("paymentInviteMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentInviteMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentInviteMessage,
             tag: 44,
             type: {:message, WAWebProtobufsE2E.PaymentInviteMessage}
           }}
        end

        []
      ),
      (
        def field_def(:interactiveMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "interactiveMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :interactiveMessage,
             tag: 45,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage}
           }}
        end

        def field_def("interactiveMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "interactiveMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :interactiveMessage,
             tag: 45,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage}
           }}
        end

        []
      ),
      (
        def field_def(:reactionMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reactionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :reactionMessage,
             tag: 46,
             type: {:message, WAWebProtobufsE2E.ReactionMessage}
           }}
        end

        def field_def("reactionMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reactionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :reactionMessage,
             tag: 46,
             type: {:message, WAWebProtobufsE2E.ReactionMessage}
           }}
        end

        []
      ),
      (
        def field_def(:stickerSyncRmrMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerSyncRmrMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :stickerSyncRmrMessage,
             tag: 47,
             type: {:message, WAWebProtobufsE2E.StickerSyncRMRMessage}
           }}
        end

        def field_def("stickerSyncRmrMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerSyncRmrMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :stickerSyncRmrMessage,
             tag: 47,
             type: {:message, WAWebProtobufsE2E.StickerSyncRMRMessage}
           }}
        end

        []
      ),
      (
        def field_def(:interactiveResponseMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "interactiveResponseMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :interactiveResponseMessage,
             tag: 48,
             type: {:message, WAWebProtobufsE2E.InteractiveResponseMessage}
           }}
        end

        def field_def("interactiveResponseMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "interactiveResponseMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :interactiveResponseMessage,
             tag: 48,
             type: {:message, WAWebProtobufsE2E.InteractiveResponseMessage}
           }}
        end

        []
      ),
      (
        def field_def(:pollCreationMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollCreationMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollCreationMessage,
             tag: 49,
             type: {:message, WAWebProtobufsE2E.PollCreationMessage}
           }}
        end

        def field_def("pollCreationMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollCreationMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollCreationMessage,
             tag: 49,
             type: {:message, WAWebProtobufsE2E.PollCreationMessage}
           }}
        end

        []
      ),
      (
        def field_def(:pollUpdateMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollUpdateMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollUpdateMessage,
             tag: 50,
             type: {:message, WAWebProtobufsE2E.PollUpdateMessage}
           }}
        end

        def field_def("pollUpdateMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollUpdateMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollUpdateMessage,
             tag: 50,
             type: {:message, WAWebProtobufsE2E.PollUpdateMessage}
           }}
        end

        []
      ),
      (
        def field_def(:keepInChatMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "keepInChatMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :keepInChatMessage,
             tag: 51,
             type: {:message, WAWebProtobufsE2E.KeepInChatMessage}
           }}
        end

        def field_def("keepInChatMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "keepInChatMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :keepInChatMessage,
             tag: 51,
             type: {:message, WAWebProtobufsE2E.KeepInChatMessage}
           }}
        end

        []
      ),
      (
        def field_def(:documentWithCaptionMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "documentWithCaptionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :documentWithCaptionMessage,
             tag: 53,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("documentWithCaptionMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "documentWithCaptionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :documentWithCaptionMessage,
             tag: 53,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:requestPhoneNumberMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestPhoneNumberMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :requestPhoneNumberMessage,
             tag: 54,
             type: {:message, WAWebProtobufsE2E.RequestPhoneNumberMessage}
           }}
        end

        def field_def("requestPhoneNumberMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestPhoneNumberMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :requestPhoneNumberMessage,
             tag: 54,
             type: {:message, WAWebProtobufsE2E.RequestPhoneNumberMessage}
           }}
        end

        []
      ),
      (
        def field_def(:viewOnceMessageV2) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "viewOnceMessageV2",
             kind: {:scalar, nil},
             label: :optional,
             name: :viewOnceMessageV2,
             tag: 55,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("viewOnceMessageV2") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "viewOnceMessageV2",
             kind: {:scalar, nil},
             label: :optional,
             name: :viewOnceMessageV2,
             tag: 55,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:encReactionMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "encReactionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :encReactionMessage,
             tag: 56,
             type: {:message, WAWebProtobufsE2E.EncReactionMessage}
           }}
        end

        def field_def("encReactionMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "encReactionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :encReactionMessage,
             tag: 56,
             type: {:message, WAWebProtobufsE2E.EncReactionMessage}
           }}
        end

        []
      ),
      (
        def field_def(:editedMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "editedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :editedMessage,
             tag: 58,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("editedMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "editedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :editedMessage,
             tag: 58,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:viewOnceMessageV2Extension) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "viewOnceMessageV2Extension",
             kind: {:scalar, nil},
             label: :optional,
             name: :viewOnceMessageV2Extension,
             tag: 59,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("viewOnceMessageV2Extension") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "viewOnceMessageV2Extension",
             kind: {:scalar, nil},
             label: :optional,
             name: :viewOnceMessageV2Extension,
             tag: 59,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:pollCreationMessageV2) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollCreationMessageV2",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollCreationMessageV2,
             tag: 60,
             type: {:message, WAWebProtobufsE2E.PollCreationMessage}
           }}
        end

        def field_def("pollCreationMessageV2") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollCreationMessageV2",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollCreationMessageV2,
             tag: 60,
             type: {:message, WAWebProtobufsE2E.PollCreationMessage}
           }}
        end

        []
      ),
      (
        def field_def(:scheduledCallCreationMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "scheduledCallCreationMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :scheduledCallCreationMessage,
             tag: 61,
             type: {:message, WAWebProtobufsE2E.ScheduledCallCreationMessage}
           }}
        end

        def field_def("scheduledCallCreationMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "scheduledCallCreationMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :scheduledCallCreationMessage,
             tag: 61,
             type: {:message, WAWebProtobufsE2E.ScheduledCallCreationMessage}
           }}
        end

        []
      ),
      (
        def field_def(:groupMentionedMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupMentionedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupMentionedMessage,
             tag: 62,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("groupMentionedMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupMentionedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupMentionedMessage,
             tag: 62,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:pinInChatMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pinInChatMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :pinInChatMessage,
             tag: 63,
             type: {:message, WAWebProtobufsE2E.PinInChatMessage}
           }}
        end

        def field_def("pinInChatMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pinInChatMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :pinInChatMessage,
             tag: 63,
             type: {:message, WAWebProtobufsE2E.PinInChatMessage}
           }}
        end

        []
      ),
      (
        def field_def(:pollCreationMessageV3) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollCreationMessageV3",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollCreationMessageV3,
             tag: 64,
             type: {:message, WAWebProtobufsE2E.PollCreationMessage}
           }}
        end

        def field_def("pollCreationMessageV3") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollCreationMessageV3",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollCreationMessageV3,
             tag: 64,
             type: {:message, WAWebProtobufsE2E.PollCreationMessage}
           }}
        end

        []
      ),
      (
        def field_def(:scheduledCallEditMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "scheduledCallEditMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :scheduledCallEditMessage,
             tag: 65,
             type: {:message, WAWebProtobufsE2E.ScheduledCallEditMessage}
           }}
        end

        def field_def("scheduledCallEditMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "scheduledCallEditMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :scheduledCallEditMessage,
             tag: 65,
             type: {:message, WAWebProtobufsE2E.ScheduledCallEditMessage}
           }}
        end

        []
      ),
      (
        def field_def(:ptvMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ptvMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :ptvMessage,
             tag: 66,
             type: {:message, WAWebProtobufsE2E.VideoMessage}
           }}
        end

        def field_def("ptvMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ptvMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :ptvMessage,
             tag: 66,
             type: {:message, WAWebProtobufsE2E.VideoMessage}
           }}
        end

        []
      ),
      (
        def field_def(:botInvokeMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botInvokeMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :botInvokeMessage,
             tag: 67,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("botInvokeMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botInvokeMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :botInvokeMessage,
             tag: 67,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:callLogMesssage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callLogMesssage",
             kind: {:scalar, nil},
             label: :optional,
             name: :callLogMesssage,
             tag: 69,
             type: {:message, WAWebProtobufsE2E.CallLogMessage}
           }}
        end

        def field_def("callLogMesssage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callLogMesssage",
             kind: {:scalar, nil},
             label: :optional,
             name: :callLogMesssage,
             tag: 69,
             type: {:message, WAWebProtobufsE2E.CallLogMessage}
           }}
        end

        []
      ),
      (
        def field_def(:messageHistoryBundle) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageHistoryBundle",
             kind: {:scalar, nil},
             label: :optional,
             name: :messageHistoryBundle,
             tag: 70,
             type: {:message, WAWebProtobufsE2E.MessageHistoryBundle}
           }}
        end

        def field_def("messageHistoryBundle") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageHistoryBundle",
             kind: {:scalar, nil},
             label: :optional,
             name: :messageHistoryBundle,
             tag: 70,
             type: {:message, WAWebProtobufsE2E.MessageHistoryBundle}
           }}
        end

        []
      ),
      (
        def field_def(:encCommentMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "encCommentMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :encCommentMessage,
             tag: 71,
             type: {:message, WAWebProtobufsE2E.EncCommentMessage}
           }}
        end

        def field_def("encCommentMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "encCommentMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :encCommentMessage,
             tag: 71,
             type: {:message, WAWebProtobufsE2E.EncCommentMessage}
           }}
        end

        []
      ),
      (
        def field_def(:bcallMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bcallMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :bcallMessage,
             tag: 72,
             type: {:message, WAWebProtobufsE2E.BCallMessage}
           }}
        end

        def field_def("bcallMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bcallMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :bcallMessage,
             tag: 72,
             type: {:message, WAWebProtobufsE2E.BCallMessage}
           }}
        end

        []
      ),
      (
        def field_def(:lottieStickerMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lottieStickerMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :lottieStickerMessage,
             tag: 74,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("lottieStickerMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lottieStickerMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :lottieStickerMessage,
             tag: 74,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:eventMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eventMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :eventMessage,
             tag: 75,
             type: {:message, WAWebProtobufsE2E.EventMessage}
           }}
        end

        def field_def("eventMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eventMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :eventMessage,
             tag: 75,
             type: {:message, WAWebProtobufsE2E.EventMessage}
           }}
        end

        []
      ),
      (
        def field_def(:encEventResponseMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "encEventResponseMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :encEventResponseMessage,
             tag: 76,
             type: {:message, WAWebProtobufsE2E.EncEventResponseMessage}
           }}
        end

        def field_def("encEventResponseMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "encEventResponseMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :encEventResponseMessage,
             tag: 76,
             type: {:message, WAWebProtobufsE2E.EncEventResponseMessage}
           }}
        end

        []
      ),
      (
        def field_def(:commentMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "commentMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :commentMessage,
             tag: 77,
             type: {:message, WAWebProtobufsE2E.CommentMessage}
           }}
        end

        def field_def("commentMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "commentMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :commentMessage,
             tag: 77,
             type: {:message, WAWebProtobufsE2E.CommentMessage}
           }}
        end

        []
      ),
      (
        def field_def(:newsletterAdminInviteMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterAdminInviteMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :newsletterAdminInviteMessage,
             tag: 78,
             type: {:message, WAWebProtobufsE2E.NewsletterAdminInviteMessage}
           }}
        end

        def field_def("newsletterAdminInviteMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterAdminInviteMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :newsletterAdminInviteMessage,
             tag: 78,
             type: {:message, WAWebProtobufsE2E.NewsletterAdminInviteMessage}
           }}
        end

        []
      ),
      (
        def field_def(:placeholderMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "placeholderMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :placeholderMessage,
             tag: 80,
             type: {:message, WAWebProtobufsE2E.PlaceholderMessage}
           }}
        end

        def field_def("placeholderMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "placeholderMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :placeholderMessage,
             tag: 80,
             type: {:message, WAWebProtobufsE2E.PlaceholderMessage}
           }}
        end

        []
      ),
      (
        def field_def(:secretEncryptedMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "secretEncryptedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :secretEncryptedMessage,
             tag: 82,
             type: {:message, WAWebProtobufsE2E.SecretEncryptedMessage}
           }}
        end

        def field_def("secretEncryptedMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "secretEncryptedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :secretEncryptedMessage,
             tag: 82,
             type: {:message, WAWebProtobufsE2E.SecretEncryptedMessage}
           }}
        end

        []
      ),
      (
        def field_def(:albumMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "albumMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :albumMessage,
             tag: 83,
             type: {:message, WAWebProtobufsE2E.AlbumMessage}
           }}
        end

        def field_def("albumMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "albumMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :albumMessage,
             tag: 83,
             type: {:message, WAWebProtobufsE2E.AlbumMessage}
           }}
        end

        []
      ),
      (
        def field_def(:eventCoverImage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eventCoverImage",
             kind: {:scalar, nil},
             label: :optional,
             name: :eventCoverImage,
             tag: 85,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("eventCoverImage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eventCoverImage",
             kind: {:scalar, nil},
             label: :optional,
             name: :eventCoverImage,
             tag: 85,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:stickerPackMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerPackMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :stickerPackMessage,
             tag: 86,
             type: {:message, WAWebProtobufsE2E.StickerPackMessage}
           }}
        end

        def field_def("stickerPackMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerPackMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :stickerPackMessage,
             tag: 86,
             type: {:message, WAWebProtobufsE2E.StickerPackMessage}
           }}
        end

        []
      ),
      (
        def field_def(:statusMentionMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusMentionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusMentionMessage,
             tag: 87,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("statusMentionMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusMentionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusMentionMessage,
             tag: 87,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:pollResultSnapshotMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollResultSnapshotMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollResultSnapshotMessage,
             tag: 88,
             type: {:message, WAWebProtobufsE2E.PollResultSnapshotMessage}
           }}
        end

        def field_def("pollResultSnapshotMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollResultSnapshotMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollResultSnapshotMessage,
             tag: 88,
             type: {:message, WAWebProtobufsE2E.PollResultSnapshotMessage}
           }}
        end

        []
      ),
      (
        def field_def(:pollCreationOptionImageMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollCreationOptionImageMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollCreationOptionImageMessage,
             tag: 90,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("pollCreationOptionImageMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollCreationOptionImageMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollCreationOptionImageMessage,
             tag: 90,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:associatedChildMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "associatedChildMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :associatedChildMessage,
             tag: 91,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("associatedChildMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "associatedChildMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :associatedChildMessage,
             tag: 91,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:groupStatusMentionMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupStatusMentionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupStatusMentionMessage,
             tag: 92,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("groupStatusMentionMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupStatusMentionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupStatusMentionMessage,
             tag: 92,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:pollCreationMessageV4) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollCreationMessageV4",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollCreationMessageV4,
             tag: 93,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("pollCreationMessageV4") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollCreationMessageV4",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollCreationMessageV4,
             tag: 93,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:statusAddYours) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusAddYours",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusAddYours,
             tag: 95,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("statusAddYours") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusAddYours",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusAddYours,
             tag: 95,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:groupStatusMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupStatusMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupStatusMessage,
             tag: 96,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("groupStatusMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupStatusMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupStatusMessage,
             tag: 96,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:richResponseMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "richResponseMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :richResponseMessage,
             tag: 97,
             type: {:message, WAWebProtobufsE2E.AIRichResponseMessage}
           }}
        end

        def field_def("richResponseMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "richResponseMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :richResponseMessage,
             tag: 97,
             type: {:message, WAWebProtobufsE2E.AIRichResponseMessage}
           }}
        end

        []
      ),
      (
        def field_def(:statusNotificationMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusNotificationMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusNotificationMessage,
             tag: 98,
             type: {:message, WAWebProtobufsE2E.StatusNotificationMessage}
           }}
        end

        def field_def("statusNotificationMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusNotificationMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusNotificationMessage,
             tag: 98,
             type: {:message, WAWebProtobufsE2E.StatusNotificationMessage}
           }}
        end

        []
      ),
      (
        def field_def(:limitSharingMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharingMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :limitSharingMessage,
             tag: 99,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("limitSharingMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharingMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :limitSharingMessage,
             tag: 99,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:botTaskMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botTaskMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :botTaskMessage,
             tag: 100,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("botTaskMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botTaskMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :botTaskMessage,
             tag: 100,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:questionMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "questionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :questionMessage,
             tag: 101,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("questionMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "questionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :questionMessage,
             tag: 101,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:messageHistoryNotice) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageHistoryNotice",
             kind: {:scalar, nil},
             label: :optional,
             name: :messageHistoryNotice,
             tag: 102,
             type: {:message, WAWebProtobufsE2E.MessageHistoryNotice}
           }}
        end

        def field_def("messageHistoryNotice") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageHistoryNotice",
             kind: {:scalar, nil},
             label: :optional,
             name: :messageHistoryNotice,
             tag: 102,
             type: {:message, WAWebProtobufsE2E.MessageHistoryNotice}
           }}
        end

        []
      ),
      (
        def field_def(:groupStatusMessageV2) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupStatusMessageV2",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupStatusMessageV2,
             tag: 103,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("groupStatusMessageV2") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupStatusMessageV2",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupStatusMessageV2,
             tag: 103,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:botForwardedMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botForwardedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :botForwardedMessage,
             tag: 104,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("botForwardedMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botForwardedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :botForwardedMessage,
             tag: 104,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:statusQuestionAnswerMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusQuestionAnswerMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusQuestionAnswerMessage,
             tag: 105,
             type: {:message, WAWebProtobufsE2E.StatusQuestionAnswerMessage}
           }}
        end

        def field_def("statusQuestionAnswerMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusQuestionAnswerMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusQuestionAnswerMessage,
             tag: 105,
             type: {:message, WAWebProtobufsE2E.StatusQuestionAnswerMessage}
           }}
        end

        []
      ),
      (
        def field_def(:questionReplyMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "questionReplyMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :questionReplyMessage,
             tag: 106,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("questionReplyMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "questionReplyMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :questionReplyMessage,
             tag: 106,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:questionResponseMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "questionResponseMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :questionResponseMessage,
             tag: 107,
             type: {:message, WAWebProtobufsE2E.QuestionResponseMessage}
           }}
        end

        def field_def("questionResponseMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "questionResponseMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :questionResponseMessage,
             tag: 107,
             type: {:message, WAWebProtobufsE2E.QuestionResponseMessage}
           }}
        end

        []
      ),
      (
        def field_def(:statusQuotedMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusQuotedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusQuotedMessage,
             tag: 109,
             type: {:message, WAWebProtobufsE2E.StatusQuotedMessage}
           }}
        end

        def field_def("statusQuotedMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusQuotedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusQuotedMessage,
             tag: 109,
             type: {:message, WAWebProtobufsE2E.StatusQuotedMessage}
           }}
        end

        []
      ),
      (
        def field_def(:statusStickerInteractionMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusStickerInteractionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusStickerInteractionMessage,
             tag: 110,
             type: {:message, WAWebProtobufsE2E.StatusStickerInteractionMessage}
           }}
        end

        def field_def("statusStickerInteractionMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusStickerInteractionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusStickerInteractionMessage,
             tag: 110,
             type: {:message, WAWebProtobufsE2E.StatusStickerInteractionMessage}
           }}
        end

        []
      ),
      (
        def field_def(:pollCreationMessageV5) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollCreationMessageV5",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollCreationMessageV5,
             tag: 111,
             type: {:message, WAWebProtobufsE2E.PollCreationMessage}
           }}
        end

        def field_def("pollCreationMessageV5") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollCreationMessageV5",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollCreationMessageV5,
             tag: 111,
             type: {:message, WAWebProtobufsE2E.PollCreationMessage}
           }}
        end

        []
      ),
      (
        def field_def(:newsletterFollowerInviteMessageV2) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterFollowerInviteMessageV2",
             kind: {:scalar, nil},
             label: :optional,
             name: :newsletterFollowerInviteMessageV2,
             tag: 113,
             type: {:message, WAWebProtobufsE2E.NewsletterFollowerInviteMessage}
           }}
        end

        def field_def("newsletterFollowerInviteMessageV2") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterFollowerInviteMessageV2",
             kind: {:scalar, nil},
             label: :optional,
             name: :newsletterFollowerInviteMessageV2,
             tag: 113,
             type: {:message, WAWebProtobufsE2E.NewsletterFollowerInviteMessage}
           }}
        end

        []
      ),
      (
        def field_def(:pollResultSnapshotMessageV3) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollResultSnapshotMessageV3",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollResultSnapshotMessageV3,
             tag: 115,
             type: {:message, WAWebProtobufsE2E.PollResultSnapshotMessage}
           }}
        end

        def field_def("pollResultSnapshotMessageV3") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollResultSnapshotMessageV3",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollResultSnapshotMessageV3,
             tag: 115,
             type: {:message, WAWebProtobufsE2E.PollResultSnapshotMessage}
           }}
        end

        []
      ),
      (
        def field_def(:newsletterAdminProfileMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterAdminProfileMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :newsletterAdminProfileMessage,
             tag: 116,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("newsletterAdminProfileMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterAdminProfileMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :newsletterAdminProfileMessage,
             tag: 116,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:newsletterAdminProfileMessageV2) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterAdminProfileMessageV2",
             kind: {:scalar, nil},
             label: :optional,
             name: :newsletterAdminProfileMessageV2,
             tag: 117,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("newsletterAdminProfileMessageV2") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterAdminProfileMessageV2",
             kind: {:scalar, nil},
             label: :optional,
             name: :newsletterAdminProfileMessageV2,
             tag: 117,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:spoilerMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "spoilerMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :spoilerMessage,
             tag: 118,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("spoilerMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "spoilerMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :spoilerMessage,
             tag: 118,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:pollCreationMessageV6) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollCreationMessageV6",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollCreationMessageV6,
             tag: 119,
             type: {:message, WAWebProtobufsE2E.PollCreationMessage}
           }}
        end

        def field_def("pollCreationMessageV6") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollCreationMessageV6",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollCreationMessageV6,
             tag: 119,
             type: {:message, WAWebProtobufsE2E.PollCreationMessage}
           }}
        end

        []
      ),
      (
        def field_def(:conditionalRevealMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conditionalRevealMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :conditionalRevealMessage,
             tag: 120,
             type: {:message, WAWebProtobufsE2E.ConditionalRevealMessage}
           }}
        end

        def field_def("conditionalRevealMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conditionalRevealMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :conditionalRevealMessage,
             tag: 120,
             type: {:message, WAWebProtobufsE2E.ConditionalRevealMessage}
           }}
        end

        []
      ),
      (
        def field_def(:pollAddOptionMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollAddOptionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollAddOptionMessage,
             tag: 121,
             type: {:message, WAWebProtobufsE2E.PollAddOptionMessage}
           }}
        end

        def field_def("pollAddOptionMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollAddOptionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollAddOptionMessage,
             tag: 121,
             type: {:message, WAWebProtobufsE2E.PollAddOptionMessage}
           }}
        end

        []
      ),
      (
        def field_def(:eventInviteMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eventInviteMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :eventInviteMessage,
             tag: 122,
             type: {:message, WAWebProtobufsE2E.EventInviteMessage}
           }}
        end

        def field_def("eventInviteMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eventInviteMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :eventInviteMessage,
             tag: 122,
             type: {:message, WAWebProtobufsE2E.EventInviteMessage}
           }}
        end

        []
      ),
      (
        def field_def(:groupRootKeyShare) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupRootKeyShare",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupRootKeyShare,
             tag: 123,
             type: {:message, WAWebProtobufsE2E.GroupRootKeyShare}
           }}
        end

        def field_def("groupRootKeyShare") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupRootKeyShare",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupRootKeyShare,
             tag: 123,
             type: {:message, WAWebProtobufsE2E.GroupRootKeyShare}
           }}
        end

        []
      ),
      (
        def field_def(:paymentReminderMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentReminderMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentReminderMessage,
             tag: 124,
             type: {:message, WAWebProtobufsE2E.PaymentReminderMessage}
           }}
        end

        def field_def("paymentReminderMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentReminderMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentReminderMessage,
             tag: 124,
             type: {:message, WAWebProtobufsE2E.PaymentReminderMessage}
           }}
        end

        []
      ),
      (
        def field_def(:splitPaymentMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "splitPaymentMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :splitPaymentMessage,
             tag: 125,
             type: {:message, WAWebProtobufsE2E.SplitPaymentMessage}
           }}
        end

        def field_def("splitPaymentMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "splitPaymentMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :splitPaymentMessage,
             tag: 125,
             type: {:message, WAWebProtobufsE2E.SplitPaymentMessage}
           }}
        end

        []
      ),
      (
        def field_def(:newsletterAdminProfileStatusMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterAdminProfileStatusMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :newsletterAdminProfileStatusMessage,
             tag: 126,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        def field_def("newsletterAdminProfileStatusMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterAdminProfileStatusMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :newsletterAdminProfileStatusMessage,
             tag: 126,
             type: {:message, WAWebProtobufsE2E.FutureProofMessage}
           }}
        end

        []
      ),
      (
        def field_def(:rootSecretDistributeMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "rootSecretDistributeMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :rootSecretDistributeMessage,
             tag: 127,
             type: {:message, WAWebProtobufsE2E.RootSecretDistributeMessage}
           }}
        end

        def field_def("rootSecretDistributeMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "rootSecretDistributeMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :rootSecretDistributeMessage,
             tag: 127,
             type: {:message, WAWebProtobufsE2E.RootSecretDistributeMessage}
           }}
        end

        []
      ),
      (
        def field_def(:splitPaymentUpdateMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "splitPaymentUpdateMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :splitPaymentUpdateMessage,
             tag: 128,
             type: {:message, WAWebProtobufsE2E.SplitPaymentUpdateMessage}
           }}
        end

        def field_def("splitPaymentUpdateMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "splitPaymentUpdateMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :splitPaymentUpdateMessage,
             tag: 128,
             type: {:message, WAWebProtobufsE2E.SplitPaymentUpdateMessage}
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
    def default(:conversation) do
      {:ok, ""}
    end,
    def default(:senderKeyDistributionMessage) do
      {:ok, nil}
    end,
    def default(:imageMessage) do
      {:ok, nil}
    end,
    def default(:contactMessage) do
      {:ok, nil}
    end,
    def default(:locationMessage) do
      {:ok, nil}
    end,
    def default(:extendedTextMessage) do
      {:ok, nil}
    end,
    def default(:documentMessage) do
      {:ok, nil}
    end,
    def default(:audioMessage) do
      {:ok, nil}
    end,
    def default(:videoMessage) do
      {:ok, nil}
    end,
    def default(:call) do
      {:ok, nil}
    end,
    def default(:chat) do
      {:ok, nil}
    end,
    def default(:protocolMessage) do
      {:ok, nil}
    end,
    def default(:contactsArrayMessage) do
      {:ok, nil}
    end,
    def default(:highlyStructuredMessage) do
      {:ok, nil}
    end,
    def default(:fastRatchetKeySenderKeyDistributionMessage) do
      {:ok, nil}
    end,
    def default(:sendPaymentMessage) do
      {:ok, nil}
    end,
    def default(:liveLocationMessage) do
      {:ok, nil}
    end,
    def default(:requestPaymentMessage) do
      {:ok, nil}
    end,
    def default(:declinePaymentRequestMessage) do
      {:ok, nil}
    end,
    def default(:cancelPaymentRequestMessage) do
      {:ok, nil}
    end,
    def default(:templateMessage) do
      {:ok, nil}
    end,
    def default(:stickerMessage) do
      {:ok, nil}
    end,
    def default(:groupInviteMessage) do
      {:ok, nil}
    end,
    def default(:templateButtonReplyMessage) do
      {:ok, nil}
    end,
    def default(:productMessage) do
      {:ok, nil}
    end,
    def default(:deviceSentMessage) do
      {:ok, nil}
    end,
    def default(:messageContextInfo) do
      {:ok, nil}
    end,
    def default(:listMessage) do
      {:ok, nil}
    end,
    def default(:viewOnceMessage) do
      {:ok, nil}
    end,
    def default(:orderMessage) do
      {:ok, nil}
    end,
    def default(:listResponseMessage) do
      {:ok, nil}
    end,
    def default(:ephemeralMessage) do
      {:ok, nil}
    end,
    def default(:invoiceMessage) do
      {:ok, nil}
    end,
    def default(:buttonsMessage) do
      {:ok, nil}
    end,
    def default(:buttonsResponseMessage) do
      {:ok, nil}
    end,
    def default(:paymentInviteMessage) do
      {:ok, nil}
    end,
    def default(:interactiveMessage) do
      {:ok, nil}
    end,
    def default(:reactionMessage) do
      {:ok, nil}
    end,
    def default(:stickerSyncRmrMessage) do
      {:ok, nil}
    end,
    def default(:interactiveResponseMessage) do
      {:ok, nil}
    end,
    def default(:pollCreationMessage) do
      {:ok, nil}
    end,
    def default(:pollUpdateMessage) do
      {:ok, nil}
    end,
    def default(:keepInChatMessage) do
      {:ok, nil}
    end,
    def default(:documentWithCaptionMessage) do
      {:ok, nil}
    end,
    def default(:requestPhoneNumberMessage) do
      {:ok, nil}
    end,
    def default(:viewOnceMessageV2) do
      {:ok, nil}
    end,
    def default(:encReactionMessage) do
      {:ok, nil}
    end,
    def default(:editedMessage) do
      {:ok, nil}
    end,
    def default(:viewOnceMessageV2Extension) do
      {:ok, nil}
    end,
    def default(:pollCreationMessageV2) do
      {:ok, nil}
    end,
    def default(:scheduledCallCreationMessage) do
      {:ok, nil}
    end,
    def default(:groupMentionedMessage) do
      {:ok, nil}
    end,
    def default(:pinInChatMessage) do
      {:ok, nil}
    end,
    def default(:pollCreationMessageV3) do
      {:ok, nil}
    end,
    def default(:scheduledCallEditMessage) do
      {:ok, nil}
    end,
    def default(:ptvMessage) do
      {:ok, nil}
    end,
    def default(:botInvokeMessage) do
      {:ok, nil}
    end,
    def default(:callLogMesssage) do
      {:ok, nil}
    end,
    def default(:messageHistoryBundle) do
      {:ok, nil}
    end,
    def default(:encCommentMessage) do
      {:ok, nil}
    end,
    def default(:bcallMessage) do
      {:ok, nil}
    end,
    def default(:lottieStickerMessage) do
      {:ok, nil}
    end,
    def default(:eventMessage) do
      {:ok, nil}
    end,
    def default(:encEventResponseMessage) do
      {:ok, nil}
    end,
    def default(:commentMessage) do
      {:ok, nil}
    end,
    def default(:newsletterAdminInviteMessage) do
      {:ok, nil}
    end,
    def default(:placeholderMessage) do
      {:ok, nil}
    end,
    def default(:secretEncryptedMessage) do
      {:ok, nil}
    end,
    def default(:albumMessage) do
      {:ok, nil}
    end,
    def default(:eventCoverImage) do
      {:ok, nil}
    end,
    def default(:stickerPackMessage) do
      {:ok, nil}
    end,
    def default(:statusMentionMessage) do
      {:ok, nil}
    end,
    def default(:pollResultSnapshotMessage) do
      {:ok, nil}
    end,
    def default(:pollCreationOptionImageMessage) do
      {:ok, nil}
    end,
    def default(:associatedChildMessage) do
      {:ok, nil}
    end,
    def default(:groupStatusMentionMessage) do
      {:ok, nil}
    end,
    def default(:pollCreationMessageV4) do
      {:ok, nil}
    end,
    def default(:statusAddYours) do
      {:ok, nil}
    end,
    def default(:groupStatusMessage) do
      {:ok, nil}
    end,
    def default(:richResponseMessage) do
      {:ok, nil}
    end,
    def default(:statusNotificationMessage) do
      {:ok, nil}
    end,
    def default(:limitSharingMessage) do
      {:ok, nil}
    end,
    def default(:botTaskMessage) do
      {:ok, nil}
    end,
    def default(:questionMessage) do
      {:ok, nil}
    end,
    def default(:messageHistoryNotice) do
      {:ok, nil}
    end,
    def default(:groupStatusMessageV2) do
      {:ok, nil}
    end,
    def default(:botForwardedMessage) do
      {:ok, nil}
    end,
    def default(:statusQuestionAnswerMessage) do
      {:ok, nil}
    end,
    def default(:questionReplyMessage) do
      {:ok, nil}
    end,
    def default(:questionResponseMessage) do
      {:ok, nil}
    end,
    def default(:statusQuotedMessage) do
      {:ok, nil}
    end,
    def default(:statusStickerInteractionMessage) do
      {:ok, nil}
    end,
    def default(:pollCreationMessageV5) do
      {:ok, nil}
    end,
    def default(:newsletterFollowerInviteMessageV2) do
      {:ok, nil}
    end,
    def default(:pollResultSnapshotMessageV3) do
      {:ok, nil}
    end,
    def default(:newsletterAdminProfileMessage) do
      {:ok, nil}
    end,
    def default(:newsletterAdminProfileMessageV2) do
      {:ok, nil}
    end,
    def default(:spoilerMessage) do
      {:ok, nil}
    end,
    def default(:pollCreationMessageV6) do
      {:ok, nil}
    end,
    def default(:conditionalRevealMessage) do
      {:ok, nil}
    end,
    def default(:pollAddOptionMessage) do
      {:ok, nil}
    end,
    def default(:eventInviteMessage) do
      {:ok, nil}
    end,
    def default(:groupRootKeyShare) do
      {:ok, nil}
    end,
    def default(:paymentReminderMessage) do
      {:ok, nil}
    end,
    def default(:splitPaymentMessage) do
      {:ok, nil}
    end,
    def default(:newsletterAdminProfileStatusMessage) do
      {:ok, nil}
    end,
    def default(:rootSecretDistributeMessage) do
      {:ok, nil}
    end,
    def default(:splitPaymentUpdateMessage) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waE2E",
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
