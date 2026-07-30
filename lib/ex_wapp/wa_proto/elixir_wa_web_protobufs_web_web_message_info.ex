# credo:disable-for-this-file
defmodule WAWebProtobufsWeb.WebMessageInfo do
  @moduledoc false
  defstruct key: nil,
            message: nil,
            messageTimestamp: nil,
            status: nil,
            participant: nil,
            messageC2STimestamp: nil,
            ignore: nil,
            starred: nil,
            broadcast: nil,
            pushName: nil,
            mediaCiphertextSHA256: nil,
            multicast: nil,
            urlText: nil,
            urlNumber: nil,
            messageStubType: nil,
            clearMedia: nil,
            messageStubParameters: [],
            duration: nil,
            labels: [],
            paymentInfo: nil,
            finalLiveLocation: nil,
            quotedPaymentInfo: nil,
            ephemeralStartTimestamp: nil,
            ephemeralDuration: nil,
            ephemeralOffToOn: nil,
            ephemeralOutOfSync: nil,
            bizPrivacyStatus: nil,
            verifiedBizName: nil,
            mediaData: nil,
            photoChange: nil,
            userReceipt: [],
            reactions: [],
            quotedStickerData: nil,
            futureproofData: nil,
            statusPsa: nil,
            pollUpdates: [],
            pollAdditionalMetadata: nil,
            agentID: nil,
            statusAlreadyViewed: nil,
            messageSecret: nil,
            keepInChat: nil,
            originalSelfAuthorUserJIDString: nil,
            revokeMessageTimestamp: nil,
            pinInChat: nil,
            premiumMessageInfo: nil,
            is1PBizBotMessage: nil,
            isGroupHistoryMessage: nil,
            botMessageInvokerJID: nil,
            commentMetadata: nil,
            eventResponses: [],
            reportingTokenInfo: nil,
            newsletterServerID: nil,
            eventAdditionalMetadata: nil,
            isMentionedInStatus: nil,
            statusMentions: [],
            targetMessageID: nil,
            messageAddOns: [],
            statusMentionMessageInfo: nil,
            isSupportAiMessage: nil,
            statusMentionSources: [],
            supportAiCitations: [],
            botTargetID: nil,
            groupHistoryIndividualMessageInfo: nil,
            groupHistoryBundleInfo: nil,
            interactiveMessageAdditionalMetadata: nil,
            quarantinedMessage: nil,
            nonJIDMentions: nil,
            hsmTag: nil,
            ephemeralExpirationTimestamp: nil,
            scheduledMessageMetadata: nil,
            decisionID: nil,
            decisionSources: [],
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
        |> encode_key(msg)
        |> encode_message(msg)
        |> encode_messageTimestamp(msg)
        |> encode_status(msg)
        |> encode_participant(msg)
        |> encode_messageC2STimestamp(msg)
        |> encode_ignore(msg)
        |> encode_starred(msg)
        |> encode_broadcast(msg)
        |> encode_pushName(msg)
        |> encode_mediaCiphertextSHA256(msg)
        |> encode_multicast(msg)
        |> encode_urlText(msg)
        |> encode_urlNumber(msg)
        |> encode_messageStubType(msg)
        |> encode_clearMedia(msg)
        |> encode_messageStubParameters(msg)
        |> encode_duration(msg)
        |> encode_labels(msg)
        |> encode_paymentInfo(msg)
        |> encode_finalLiveLocation(msg)
        |> encode_quotedPaymentInfo(msg)
        |> encode_ephemeralStartTimestamp(msg)
        |> encode_ephemeralDuration(msg)
        |> encode_ephemeralOffToOn(msg)
        |> encode_ephemeralOutOfSync(msg)
        |> encode_bizPrivacyStatus(msg)
        |> encode_verifiedBizName(msg)
        |> encode_mediaData(msg)
        |> encode_photoChange(msg)
        |> encode_userReceipt(msg)
        |> encode_reactions(msg)
        |> encode_quotedStickerData(msg)
        |> encode_futureproofData(msg)
        |> encode_statusPsa(msg)
        |> encode_pollUpdates(msg)
        |> encode_pollAdditionalMetadata(msg)
        |> encode_agentID(msg)
        |> encode_statusAlreadyViewed(msg)
        |> encode_messageSecret(msg)
        |> encode_keepInChat(msg)
        |> encode_originalSelfAuthorUserJIDString(msg)
        |> encode_revokeMessageTimestamp(msg)
        |> encode_pinInChat(msg)
        |> encode_premiumMessageInfo(msg)
        |> encode_is1PBizBotMessage(msg)
        |> encode_isGroupHistoryMessage(msg)
        |> encode_botMessageInvokerJID(msg)
        |> encode_commentMetadata(msg)
        |> encode_eventResponses(msg)
        |> encode_reportingTokenInfo(msg)
        |> encode_newsletterServerID(msg)
        |> encode_eventAdditionalMetadata(msg)
        |> encode_isMentionedInStatus(msg)
        |> encode_statusMentions(msg)
        |> encode_targetMessageID(msg)
        |> encode_messageAddOns(msg)
        |> encode_statusMentionMessageInfo(msg)
        |> encode_isSupportAiMessage(msg)
        |> encode_statusMentionSources(msg)
        |> encode_supportAiCitations(msg)
        |> encode_botTargetID(msg)
        |> encode_groupHistoryIndividualMessageInfo(msg)
        |> encode_groupHistoryBundleInfo(msg)
        |> encode_interactiveMessageAdditionalMetadata(msg)
        |> encode_quarantinedMessage(msg)
        |> encode_nonJIDMentions(msg)
        |> encode_hsmTag(msg)
        |> encode_ephemeralExpirationTimestamp(msg)
        |> encode_scheduledMessageMetadata(msg)
        |> encode_decisionID(msg)
        |> encode_decisionSources(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_key(acc, msg) do
        try do
          case msg.key do
            nil -> raise Protox.RequiredFieldsError.new([:key])
            _ -> [acc, "\n", Protox.Encode.encode_message(msg.key)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:key, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_message(acc, msg) do
        try do
          case msg.message do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_message(msg.message)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:message, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_messageTimestamp(acc, msg) do
        try do
          case msg.messageTimestamp do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_uint64(msg.messageTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_status(acc, msg) do
        try do
          case msg.status do
            nil ->
              acc

            _ ->
              [
                acc,
                " ",
                msg.status
                |> WAWebProtobufsWeb.WebMessageInfo.Status.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:status, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_participant(acc, msg) do
        try do
          case msg.participant do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.participant)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:participant, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_messageC2STimestamp(acc, msg) do
        try do
          case msg.messageC2STimestamp do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_uint64(msg.messageC2STimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageC2STimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ignore(acc, msg) do
        try do
          case msg.ignore do
            nil -> acc
            _ -> [acc, "\x80\x01", Protox.Encode.encode_bool(msg.ignore)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ignore, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_starred(acc, msg) do
        try do
          case msg.starred do
            nil -> acc
            _ -> [acc, "\x88\x01", Protox.Encode.encode_bool(msg.starred)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:starred, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_broadcast(acc, msg) do
        try do
          case msg.broadcast do
            nil -> acc
            _ -> [acc, "\x90\x01", Protox.Encode.encode_bool(msg.broadcast)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:broadcast, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pushName(acc, msg) do
        try do
          case msg.pushName do
            nil -> acc
            _ -> [acc, "\x9A\x01", Protox.Encode.encode_string(msg.pushName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pushName, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaCiphertextSHA256(acc, msg) do
        try do
          case msg.mediaCiphertextSHA256 do
            nil -> acc
            _ -> [acc, "\xA2\x01", Protox.Encode.encode_bytes(msg.mediaCiphertextSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaCiphertextSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_multicast(acc, msg) do
        try do
          case msg.multicast do
            nil -> acc
            _ -> [acc, "\xA8\x01", Protox.Encode.encode_bool(msg.multicast)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:multicast, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_urlText(acc, msg) do
        try do
          case msg.urlText do
            nil -> acc
            _ -> [acc, "\xB0\x01", Protox.Encode.encode_bool(msg.urlText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:urlText, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_urlNumber(acc, msg) do
        try do
          case msg.urlNumber do
            nil -> acc
            _ -> [acc, "\xB8\x01", Protox.Encode.encode_bool(msg.urlNumber)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:urlNumber, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_messageStubType(acc, msg) do
        try do
          case msg.messageStubType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xC0\x01",
                msg.messageStubType
                |> WAWebProtobufsWeb.WebMessageInfo.StubType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageStubType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_clearMedia(acc, msg) do
        try do
          case msg.clearMedia do
            nil -> acc
            _ -> [acc, "\xC8\x01", Protox.Encode.encode_bool(msg.clearMedia)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:clearMedia, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_messageStubParameters(acc, msg) do
        try do
          case msg.messageStubParameters do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xD2\x01", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageStubParameters, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_duration(acc, msg) do
        try do
          case msg.duration do
            nil -> acc
            _ -> [acc, "\xD8\x01", Protox.Encode.encode_uint32(msg.duration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:duration, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_labels(acc, msg) do
        try do
          case msg.labels do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xE2\x01", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:labels, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_paymentInfo(acc, msg) do
        try do
          case msg.paymentInfo do
            nil -> acc
            _ -> [acc, "\xEA\x01", Protox.Encode.encode_message(msg.paymentInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:paymentInfo, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_finalLiveLocation(acc, msg) do
        try do
          case msg.finalLiveLocation do
            nil -> acc
            _ -> [acc, "\xF2\x01", Protox.Encode.encode_message(msg.finalLiveLocation)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:finalLiveLocation, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_quotedPaymentInfo(acc, msg) do
        try do
          case msg.quotedPaymentInfo do
            nil -> acc
            _ -> [acc, "\xFA\x01", Protox.Encode.encode_message(msg.quotedPaymentInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:quotedPaymentInfo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ephemeralStartTimestamp(acc, msg) do
        try do
          case msg.ephemeralStartTimestamp do
            nil -> acc
            _ -> [acc, "\x80\x02", Protox.Encode.encode_uint64(msg.ephemeralStartTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeralStartTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ephemeralDuration(acc, msg) do
        try do
          case msg.ephemeralDuration do
            nil -> acc
            _ -> [acc, "\x88\x02", Protox.Encode.encode_uint32(msg.ephemeralDuration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeralDuration, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ephemeralOffToOn(acc, msg) do
        try do
          case msg.ephemeralOffToOn do
            nil -> acc
            _ -> [acc, "\x90\x02", Protox.Encode.encode_bool(msg.ephemeralOffToOn)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeralOffToOn, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ephemeralOutOfSync(acc, msg) do
        try do
          case msg.ephemeralOutOfSync do
            nil -> acc
            _ -> [acc, "\x98\x02", Protox.Encode.encode_bool(msg.ephemeralOutOfSync)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeralOutOfSync, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_bizPrivacyStatus(acc, msg) do
        try do
          case msg.bizPrivacyStatus do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xA0\x02",
                msg.bizPrivacyStatus
                |> WAWebProtobufsWeb.WebMessageInfo.BizPrivacyStatus.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:bizPrivacyStatus, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_verifiedBizName(acc, msg) do
        try do
          case msg.verifiedBizName do
            nil -> acc
            _ -> [acc, "\xAA\x02", Protox.Encode.encode_string(msg.verifiedBizName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:verifiedBizName, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_mediaData(acc, msg) do
        try do
          case msg.mediaData do
            nil -> acc
            _ -> [acc, "\xB2\x02", Protox.Encode.encode_message(msg.mediaData)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaData, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_photoChange(acc, msg) do
        try do
          case msg.photoChange do
            nil -> acc
            _ -> [acc, "\xBA\x02", Protox.Encode.encode_message(msg.photoChange)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:photoChange, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_userReceipt(acc, msg) do
        try do
          case msg.userReceipt do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xC2\x02", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:userReceipt, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_reactions(acc, msg) do
        try do
          case msg.reactions do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xCA\x02", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:reactions, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_quotedStickerData(acc, msg) do
        try do
          case msg.quotedStickerData do
            nil -> acc
            _ -> [acc, "\xD2\x02", Protox.Encode.encode_message(msg.quotedStickerData)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:quotedStickerData, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_futureproofData(acc, msg) do
        try do
          case msg.futureproofData do
            nil -> acc
            _ -> [acc, "\xDA\x02", Protox.Encode.encode_bytes(msg.futureproofData)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:futureproofData, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusPsa(acc, msg) do
        try do
          case msg.statusPsa do
            nil -> acc
            _ -> [acc, "\xE2\x02", Protox.Encode.encode_message(msg.statusPsa)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusPsa, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pollUpdates(acc, msg) do
        try do
          case msg.pollUpdates do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xEA\x02", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollUpdates, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pollAdditionalMetadata(acc, msg) do
        try do
          case msg.pollAdditionalMetadata do
            nil -> acc
            _ -> [acc, "\xF2\x02", Protox.Encode.encode_message(msg.pollAdditionalMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollAdditionalMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_agentID(acc, msg) do
        try do
          case msg.agentID do
            nil -> acc
            _ -> [acc, "\xFA\x02", Protox.Encode.encode_string(msg.agentID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:agentID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_statusAlreadyViewed(acc, msg) do
        try do
          case msg.statusAlreadyViewed do
            nil -> acc
            _ -> [acc, "\x80\x03", Protox.Encode.encode_bool(msg.statusAlreadyViewed)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusAlreadyViewed, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messageSecret(acc, msg) do
        try do
          case msg.messageSecret do
            nil -> acc
            _ -> [acc, "\x8A\x03", Protox.Encode.encode_bytes(msg.messageSecret)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageSecret, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_keepInChat(acc, msg) do
        try do
          case msg.keepInChat do
            nil -> acc
            _ -> [acc, "\x92\x03", Protox.Encode.encode_message(msg.keepInChat)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:keepInChat, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_originalSelfAuthorUserJIDString(acc, msg) do
        try do
          case msg.originalSelfAuthorUserJIDString do
            nil ->
              acc

            _ ->
              [acc, "\x9A\x03", Protox.Encode.encode_string(msg.originalSelfAuthorUserJIDString)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :originalSelfAuthorUserJIDString,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_revokeMessageTimestamp(acc, msg) do
        try do
          case msg.revokeMessageTimestamp do
            nil -> acc
            _ -> [acc, "\xA0\x03", Protox.Encode.encode_uint64(msg.revokeMessageTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:revokeMessageTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pinInChat(acc, msg) do
        try do
          case msg.pinInChat do
            nil -> acc
            _ -> [acc, "\xB2\x03", Protox.Encode.encode_message(msg.pinInChat)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pinInChat, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_premiumMessageInfo(acc, msg) do
        try do
          case msg.premiumMessageInfo do
            nil -> acc
            _ -> [acc, "\xBA\x03", Protox.Encode.encode_message(msg.premiumMessageInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:premiumMessageInfo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_is1PBizBotMessage(acc, msg) do
        try do
          case msg.is1PBizBotMessage do
            nil -> acc
            _ -> [acc, "\xC0\x03", Protox.Encode.encode_bool(msg.is1PBizBotMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:is1PBizBotMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isGroupHistoryMessage(acc, msg) do
        try do
          case msg.isGroupHistoryMessage do
            nil -> acc
            _ -> [acc, "\xC8\x03", Protox.Encode.encode_bool(msg.isGroupHistoryMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isGroupHistoryMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botMessageInvokerJID(acc, msg) do
        try do
          case msg.botMessageInvokerJID do
            nil -> acc
            _ -> [acc, "\xD2\x03", Protox.Encode.encode_string(msg.botMessageInvokerJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botMessageInvokerJID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_commentMetadata(acc, msg) do
        try do
          case msg.commentMetadata do
            nil -> acc
            _ -> [acc, "\xDA\x03", Protox.Encode.encode_message(msg.commentMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:commentMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_eventResponses(acc, msg) do
        try do
          case msg.eventResponses do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xEA\x03", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:eventResponses, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_reportingTokenInfo(acc, msg) do
        try do
          case msg.reportingTokenInfo do
            nil -> acc
            _ -> [acc, "\xF2\x03", Protox.Encode.encode_message(msg.reportingTokenInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:reportingTokenInfo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_newsletterServerID(acc, msg) do
        try do
          case msg.newsletterServerID do
            nil -> acc
            _ -> [acc, "\xF8\x03", Protox.Encode.encode_uint64(msg.newsletterServerID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:newsletterServerID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_eventAdditionalMetadata(acc, msg) do
        try do
          case msg.eventAdditionalMetadata do
            nil -> acc
            _ -> [acc, "\x82\x04", Protox.Encode.encode_message(msg.eventAdditionalMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:eventAdditionalMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isMentionedInStatus(acc, msg) do
        try do
          case msg.isMentionedInStatus do
            nil -> acc
            _ -> [acc, "\x88\x04", Protox.Encode.encode_bool(msg.isMentionedInStatus)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isMentionedInStatus, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusMentions(acc, msg) do
        try do
          case msg.statusMentions do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\x92\x04", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusMentions, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_targetMessageID(acc, msg) do
        try do
          case msg.targetMessageID do
            nil -> acc
            _ -> [acc, "\x9A\x04", Protox.Encode.encode_message(msg.targetMessageID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:targetMessageID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messageAddOns(acc, msg) do
        try do
          case msg.messageAddOns do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xA2\x04", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageAddOns, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusMentionMessageInfo(acc, msg) do
        try do
          case msg.statusMentionMessageInfo do
            nil -> acc
            _ -> [acc, "\xAA\x04", Protox.Encode.encode_message(msg.statusMentionMessageInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusMentionMessageInfo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isSupportAiMessage(acc, msg) do
        try do
          case msg.isSupportAiMessage do
            nil -> acc
            _ -> [acc, "\xB0\x04", Protox.Encode.encode_bool(msg.isSupportAiMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isSupportAiMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusMentionSources(acc, msg) do
        try do
          case msg.statusMentionSources do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xBA\x04", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusMentionSources, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportAiCitations(acc, msg) do
        try do
          case msg.supportAiCitations do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xC2\x04", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportAiCitations, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botTargetID(acc, msg) do
        try do
          case msg.botTargetID do
            nil -> acc
            _ -> [acc, "\xCA\x04", Protox.Encode.encode_string(msg.botTargetID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botTargetID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_groupHistoryIndividualMessageInfo(acc, msg) do
        try do
          case msg.groupHistoryIndividualMessageInfo do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xD2\x04",
                Protox.Encode.encode_message(msg.groupHistoryIndividualMessageInfo)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :groupHistoryIndividualMessageInfo,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_groupHistoryBundleInfo(acc, msg) do
        try do
          case msg.groupHistoryBundleInfo do
            nil -> acc
            _ -> [acc, "\xDA\x04", Protox.Encode.encode_message(msg.groupHistoryBundleInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupHistoryBundleInfo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_interactiveMessageAdditionalMetadata(acc, msg) do
        try do
          case msg.interactiveMessageAdditionalMetadata do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xE2\x04",
                Protox.Encode.encode_message(msg.interactiveMessageAdditionalMetadata)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :interactiveMessageAdditionalMetadata,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_quarantinedMessage(acc, msg) do
        try do
          case msg.quarantinedMessage do
            nil -> acc
            _ -> [acc, "\xEA\x04", Protox.Encode.encode_message(msg.quarantinedMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:quarantinedMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_nonJIDMentions(acc, msg) do
        try do
          case msg.nonJIDMentions do
            nil -> acc
            _ -> [acc, "\xF0\x04", Protox.Encode.encode_uint32(msg.nonJIDMentions)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:nonJIDMentions, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_hsmTag(acc, msg) do
        try do
          case msg.hsmTag do
            nil -> acc
            _ -> [acc, "\xFA\x04", Protox.Encode.encode_string(msg.hsmTag)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:hsmTag, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_ephemeralExpirationTimestamp(acc, msg) do
        try do
          case msg.ephemeralExpirationTimestamp do
            nil -> acc
            _ -> [acc, "\x80\x05", Protox.Encode.encode_uint64(msg.ephemeralExpirationTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :ephemeralExpirationTimestamp,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_scheduledMessageMetadata(acc, msg) do
        try do
          case msg.scheduledMessageMetadata do
            nil -> acc
            _ -> [acc, "\x8A\x05", Protox.Encode.encode_message(msg.scheduledMessageMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:scheduledMessageMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_decisionID(acc, msg) do
        try do
          case msg.decisionID do
            nil -> acc
            _ -> [acc, "\x92\x05", Protox.Encode.encode_string(msg.decisionID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:decisionID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_decisionSources(acc, msg) do
        try do
          case msg.decisionSources do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\x9A\x05", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:decisionSources, "invalid field value"),
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
          {msg, set_fields} = parse_key_value([], bytes, struct(WAWebProtobufsWeb.WebMessageInfo))

          case [:key] -- set_fields do
            [] -> msg
            missing_fields -> raise Protox.RequiredFieldsError.new(missing_fields)
          end
        end
      )
    )

    (
      @spec parse_key_value([atom], binary, struct) :: {struct, [atom]}
      defp parse_key_value(set_fields, <<>>, msg) do
        {msg, set_fields}
      end

      defp parse_key_value(set_fields, bytes, msg) do
        {new_set_fields, field, rest} =
          case Protox.Decode.parse_key(bytes) do
            {0, _, _} ->
              raise %Protox.IllegalTagError{}

            {1, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:key | set_fields],
               [key: Protox.MergeMessage.merge(msg.key, WACommon.MessageKey.decode!(delimited))],
               rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:message | set_fields],
               [
                 message:
                   Protox.MergeMessage.merge(
                     msg.message,
                     WAWebProtobufsE2E.Message.decode!(delimited)
                   )
               ], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[:messageTimestamp | set_fields], [messageTimestamp: value], rest}

            {4, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebMessageInfo.Status)

              {[:status | set_fields], [status: value], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:participant | set_fields],
               [participant: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[:messageC2STimestamp | set_fields], [messageC2STimestamp: value], rest}

            {16, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:ignore | set_fields], [ignore: value], rest}

            {17, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:starred | set_fields], [starred: value], rest}

            {18, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:broadcast | set_fields], [broadcast: value], rest}

            {19, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:pushName | set_fields], [pushName: Protox.Decode.validate_string!(delimited)],
               rest}

            {20, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:mediaCiphertextSHA256 | set_fields], [mediaCiphertextSHA256: delimited], rest}

            {21, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:multicast | set_fields], [multicast: value], rest}

            {22, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:urlText | set_fields], [urlText: value], rest}

            {23, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:urlNumber | set_fields], [urlNumber: value], rest}

            {24, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebMessageInfo.StubType)

              {[:messageStubType | set_fields], [messageStubType: value], rest}

            {25, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:clearMedia | set_fields], [clearMedia: value], rest}

            {26, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:messageStubParameters | set_fields],
               [
                 messageStubParameters:
                   msg.messageStubParameters ++ [Protox.Decode.validate_string!(delimited)]
               ], rest}

            {27, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[:duration | set_fields], [duration: value], rest}

            {28, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:labels | set_fields],
               [labels: msg.labels ++ [Protox.Decode.validate_string!(delimited)]], rest}

            {29, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:paymentInfo | set_fields],
               [
                 paymentInfo:
                   Protox.MergeMessage.merge(
                     msg.paymentInfo,
                     WAWebProtobufsWeb.PaymentInfo.decode!(delimited)
                   )
               ], rest}

            {30, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:finalLiveLocation | set_fields],
               [
                 finalLiveLocation:
                   Protox.MergeMessage.merge(
                     msg.finalLiveLocation,
                     WAWebProtobufsE2E.LiveLocationMessage.decode!(delimited)
                   )
               ], rest}

            {31, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:quotedPaymentInfo | set_fields],
               [
                 quotedPaymentInfo:
                   Protox.MergeMessage.merge(
                     msg.quotedPaymentInfo,
                     WAWebProtobufsWeb.PaymentInfo.decode!(delimited)
                   )
               ], rest}

            {32, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[:ephemeralStartTimestamp | set_fields], [ephemeralStartTimestamp: value], rest}

            {33, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[:ephemeralDuration | set_fields], [ephemeralDuration: value], rest}

            {34, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:ephemeralOffToOn | set_fields], [ephemeralOffToOn: value], rest}

            {35, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:ephemeralOutOfSync | set_fields], [ephemeralOutOfSync: value], rest}

            {36, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.WebMessageInfo.BizPrivacyStatus)

              {[:bizPrivacyStatus | set_fields], [bizPrivacyStatus: value], rest}

            {37, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:verifiedBizName | set_fields],
               [verifiedBizName: Protox.Decode.validate_string!(delimited)], rest}

            {38, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:mediaData | set_fields],
               [
                 mediaData:
                   Protox.MergeMessage.merge(
                     msg.mediaData,
                     WAWebProtobufsWeb.MediaData.decode!(delimited)
                   )
               ], rest}

            {39, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:photoChange | set_fields],
               [
                 photoChange:
                   Protox.MergeMessage.merge(
                     msg.photoChange,
                     WAWebProtobufsWeb.PhotoChange.decode!(delimited)
                   )
               ], rest}

            {40, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:userReceipt | set_fields],
               [
                 userReceipt:
                   msg.userReceipt ++ [WAWebProtobufsWeb.UserReceipt.decode!(delimited)]
               ], rest}

            {41, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:reactions | set_fields],
               [reactions: msg.reactions ++ [WAWebProtobufsWeb.Reaction.decode!(delimited)]],
               rest}

            {42, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:quotedStickerData | set_fields],
               [
                 quotedStickerData:
                   Protox.MergeMessage.merge(
                     msg.quotedStickerData,
                     WAWebProtobufsWeb.MediaData.decode!(delimited)
                   )
               ], rest}

            {43, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:futureproofData | set_fields], [futureproofData: delimited], rest}

            {44, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:statusPsa | set_fields],
               [
                 statusPsa:
                   Protox.MergeMessage.merge(
                     msg.statusPsa,
                     WAWebProtobufsWeb.StatusPSA.decode!(delimited)
                   )
               ], rest}

            {45, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:pollUpdates | set_fields],
               [
                 pollUpdates: msg.pollUpdates ++ [WAWebProtobufsWeb.PollUpdate.decode!(delimited)]
               ], rest}

            {46, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:pollAdditionalMetadata | set_fields],
               [
                 pollAdditionalMetadata:
                   Protox.MergeMessage.merge(
                     msg.pollAdditionalMetadata,
                     WAWebProtobufsWeb.PollAdditionalMetadata.decode!(delimited)
                   )
               ], rest}

            {47, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:agentID | set_fields], [agentID: Protox.Decode.validate_string!(delimited)],
               rest}

            {48, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:statusAlreadyViewed | set_fields], [statusAlreadyViewed: value], rest}

            {49, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:messageSecret | set_fields], [messageSecret: delimited], rest}

            {50, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:keepInChat | set_fields],
               [
                 keepInChat:
                   Protox.MergeMessage.merge(
                     msg.keepInChat,
                     WAWebProtobufsWeb.KeepInChat.decode!(delimited)
                   )
               ], rest}

            {51, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:originalSelfAuthorUserJIDString | set_fields],
               [originalSelfAuthorUserJIDString: Protox.Decode.validate_string!(delimited)], rest}

            {52, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[:revokeMessageTimestamp | set_fields], [revokeMessageTimestamp: value], rest}

            {54, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:pinInChat | set_fields],
               [
                 pinInChat:
                   Protox.MergeMessage.merge(
                     msg.pinInChat,
                     WAWebProtobufsWeb.PinInChat.decode!(delimited)
                   )
               ], rest}

            {55, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:premiumMessageInfo | set_fields],
               [
                 premiumMessageInfo:
                   Protox.MergeMessage.merge(
                     msg.premiumMessageInfo,
                     WAWebProtobufsWeb.PremiumMessageInfo.decode!(delimited)
                   )
               ], rest}

            {56, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:is1PBizBotMessage | set_fields], [is1PBizBotMessage: value], rest}

            {57, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:isGroupHistoryMessage | set_fields], [isGroupHistoryMessage: value], rest}

            {58, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:botMessageInvokerJID | set_fields],
               [botMessageInvokerJID: Protox.Decode.validate_string!(delimited)], rest}

            {59, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:commentMetadata | set_fields],
               [
                 commentMetadata:
                   Protox.MergeMessage.merge(
                     msg.commentMetadata,
                     WAWebProtobufsWeb.CommentMetadata.decode!(delimited)
                   )
               ], rest}

            {61, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:eventResponses | set_fields],
               [
                 eventResponses:
                   msg.eventResponses ++ [WAWebProtobufsWeb.EventResponse.decode!(delimited)]
               ], rest}

            {62, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:reportingTokenInfo | set_fields],
               [
                 reportingTokenInfo:
                   Protox.MergeMessage.merge(
                     msg.reportingTokenInfo,
                     WAWebProtobufsWeb.ReportingTokenInfo.decode!(delimited)
                   )
               ], rest}

            {63, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[:newsletterServerID | set_fields], [newsletterServerID: value], rest}

            {64, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:eventAdditionalMetadata | set_fields],
               [
                 eventAdditionalMetadata:
                   Protox.MergeMessage.merge(
                     msg.eventAdditionalMetadata,
                     WAWebProtobufsWeb.EventAdditionalMetadata.decode!(delimited)
                   )
               ], rest}

            {65, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:isMentionedInStatus | set_fields], [isMentionedInStatus: value], rest}

            {66, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:statusMentions | set_fields],
               [
                 statusMentions: msg.statusMentions ++ [Protox.Decode.validate_string!(delimited)]
               ], rest}

            {67, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:targetMessageID | set_fields],
               [
                 targetMessageID:
                   Protox.MergeMessage.merge(
                     msg.targetMessageID,
                     WACommon.MessageKey.decode!(delimited)
                   )
               ], rest}

            {68, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:messageAddOns | set_fields],
               [
                 messageAddOns:
                   msg.messageAddOns ++ [WAWebProtobufsWeb.MessageAddOn.decode!(delimited)]
               ], rest}

            {69, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:statusMentionMessageInfo | set_fields],
               [
                 statusMentionMessageInfo:
                   Protox.MergeMessage.merge(
                     msg.statusMentionMessageInfo,
                     WAWebProtobufsWeb.StatusMentionMessage.decode!(delimited)
                   )
               ], rest}

            {70, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:isSupportAiMessage | set_fields], [isSupportAiMessage: value], rest}

            {71, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:statusMentionSources | set_fields],
               [
                 statusMentionSources:
                   msg.statusMentionSources ++ [Protox.Decode.validate_string!(delimited)]
               ], rest}

            {72, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:supportAiCitations | set_fields],
               [
                 supportAiCitations:
                   msg.supportAiCitations ++ [WAWebProtobufsWeb.Citation.decode!(delimited)]
               ], rest}

            {73, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:botTargetID | set_fields],
               [botTargetID: Protox.Decode.validate_string!(delimited)], rest}

            {74, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:groupHistoryIndividualMessageInfo | set_fields],
               [
                 groupHistoryIndividualMessageInfo:
                   Protox.MergeMessage.merge(
                     msg.groupHistoryIndividualMessageInfo,
                     WAWebProtobufsWeb.GroupHistoryIndividualMessageInfo.decode!(delimited)
                   )
               ], rest}

            {75, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:groupHistoryBundleInfo | set_fields],
               [
                 groupHistoryBundleInfo:
                   Protox.MergeMessage.merge(
                     msg.groupHistoryBundleInfo,
                     WAWebProtobufsWeb.GroupHistoryBundleInfo.decode!(delimited)
                   )
               ], rest}

            {76, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:interactiveMessageAdditionalMetadata | set_fields],
               [
                 interactiveMessageAdditionalMetadata:
                   Protox.MergeMessage.merge(
                     msg.interactiveMessageAdditionalMetadata,
                     WAWebProtobufsWeb.InteractiveMessageAdditionalMetadata.decode!(delimited)
                   )
               ], rest}

            {77, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:quarantinedMessage | set_fields],
               [
                 quarantinedMessage:
                   Protox.MergeMessage.merge(
                     msg.quarantinedMessage,
                     WAWebProtobufsWeb.QuarantinedMessage.decode!(delimited)
                   )
               ], rest}

            {78, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[:nonJIDMentions | set_fields], [nonJIDMentions: value], rest}

            {79, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:hsmTag | set_fields], [hsmTag: Protox.Decode.validate_string!(delimited)], rest}

            {80, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)

              {[:ephemeralExpirationTimestamp | set_fields],
               [ephemeralExpirationTimestamp: value], rest}

            {81, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:scheduledMessageMetadata | set_fields],
               [
                 scheduledMessageMetadata:
                   Protox.MergeMessage.merge(
                     msg.scheduledMessageMetadata,
                     WAWebProtobufsWeb.ScheduledMessageMetadata.decode!(delimited)
                   )
               ], rest}

            {82, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:decisionID | set_fields],
               [decisionID: Protox.Decode.validate_string!(delimited)], rest}

            {83, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:decisionSources | set_fields],
               [
                 decisionSources:
                   msg.decisionSources ++ [Protox.Decode.validate_string!(delimited)]
               ], rest}

            {tag, wire_type, rest} ->
              {value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

              {set_fields,
               [
                 {msg.__struct__.unknown_fields_name(),
                  [value | msg.__struct__.unknown_fields(msg)]}
               ], rest}
          end

        msg_updated = struct(msg, field)
        parse_key_value(new_set_fields, rest, msg_updated)
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
        WAWebProtobufsWeb.WebMessageInfo,
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
        1 => {:key, {:scalar, nil}, {:message, WACommon.MessageKey}},
        2 => {:message, {:scalar, nil}, {:message, WAWebProtobufsE2E.Message}},
        3 => {:messageTimestamp, {:scalar, 0}, :uint64},
        4 => {:status, {:scalar, :ERROR}, {:enum, WAWebProtobufsWeb.WebMessageInfo.Status}},
        5 => {:participant, {:scalar, ""}, :string},
        6 => {:messageC2STimestamp, {:scalar, 0}, :uint64},
        16 => {:ignore, {:scalar, false}, :bool},
        17 => {:starred, {:scalar, false}, :bool},
        18 => {:broadcast, {:scalar, false}, :bool},
        19 => {:pushName, {:scalar, ""}, :string},
        20 => {:mediaCiphertextSHA256, {:scalar, ""}, :bytes},
        21 => {:multicast, {:scalar, false}, :bool},
        22 => {:urlText, {:scalar, false}, :bool},
        23 => {:urlNumber, {:scalar, false}, :bool},
        24 =>
          {:messageStubType, {:scalar, :UNKNOWN},
           {:enum, WAWebProtobufsWeb.WebMessageInfo.StubType}},
        25 => {:clearMedia, {:scalar, false}, :bool},
        26 => {:messageStubParameters, :unpacked, :string},
        27 => {:duration, {:scalar, 0}, :uint32},
        28 => {:labels, :unpacked, :string},
        29 => {:paymentInfo, {:scalar, nil}, {:message, WAWebProtobufsWeb.PaymentInfo}},
        30 =>
          {:finalLiveLocation, {:scalar, nil}, {:message, WAWebProtobufsE2E.LiveLocationMessage}},
        31 => {:quotedPaymentInfo, {:scalar, nil}, {:message, WAWebProtobufsWeb.PaymentInfo}},
        32 => {:ephemeralStartTimestamp, {:scalar, 0}, :uint64},
        33 => {:ephemeralDuration, {:scalar, 0}, :uint32},
        34 => {:ephemeralOffToOn, {:scalar, false}, :bool},
        35 => {:ephemeralOutOfSync, {:scalar, false}, :bool},
        36 =>
          {:bizPrivacyStatus, {:scalar, :E2EE},
           {:enum, WAWebProtobufsWeb.WebMessageInfo.BizPrivacyStatus}},
        37 => {:verifiedBizName, {:scalar, ""}, :string},
        38 => {:mediaData, {:scalar, nil}, {:message, WAWebProtobufsWeb.MediaData}},
        39 => {:photoChange, {:scalar, nil}, {:message, WAWebProtobufsWeb.PhotoChange}},
        40 => {:userReceipt, :unpacked, {:message, WAWebProtobufsWeb.UserReceipt}},
        41 => {:reactions, :unpacked, {:message, WAWebProtobufsWeb.Reaction}},
        42 => {:quotedStickerData, {:scalar, nil}, {:message, WAWebProtobufsWeb.MediaData}},
        43 => {:futureproofData, {:scalar, ""}, :bytes},
        44 => {:statusPsa, {:scalar, nil}, {:message, WAWebProtobufsWeb.StatusPSA}},
        45 => {:pollUpdates, :unpacked, {:message, WAWebProtobufsWeb.PollUpdate}},
        46 =>
          {:pollAdditionalMetadata, {:scalar, nil},
           {:message, WAWebProtobufsWeb.PollAdditionalMetadata}},
        47 => {:agentID, {:scalar, ""}, :string},
        48 => {:statusAlreadyViewed, {:scalar, false}, :bool},
        49 => {:messageSecret, {:scalar, ""}, :bytes},
        50 => {:keepInChat, {:scalar, nil}, {:message, WAWebProtobufsWeb.KeepInChat}},
        51 => {:originalSelfAuthorUserJIDString, {:scalar, ""}, :string},
        52 => {:revokeMessageTimestamp, {:scalar, 0}, :uint64},
        54 => {:pinInChat, {:scalar, nil}, {:message, WAWebProtobufsWeb.PinInChat}},
        55 =>
          {:premiumMessageInfo, {:scalar, nil}, {:message, WAWebProtobufsWeb.PremiumMessageInfo}},
        56 => {:is1PBizBotMessage, {:scalar, false}, :bool},
        57 => {:isGroupHistoryMessage, {:scalar, false}, :bool},
        58 => {:botMessageInvokerJID, {:scalar, ""}, :string},
        59 => {:commentMetadata, {:scalar, nil}, {:message, WAWebProtobufsWeb.CommentMetadata}},
        61 => {:eventResponses, :unpacked, {:message, WAWebProtobufsWeb.EventResponse}},
        62 =>
          {:reportingTokenInfo, {:scalar, nil}, {:message, WAWebProtobufsWeb.ReportingTokenInfo}},
        63 => {:newsletterServerID, {:scalar, 0}, :uint64},
        64 =>
          {:eventAdditionalMetadata, {:scalar, nil},
           {:message, WAWebProtobufsWeb.EventAdditionalMetadata}},
        65 => {:isMentionedInStatus, {:scalar, false}, :bool},
        66 => {:statusMentions, :unpacked, :string},
        67 => {:targetMessageID, {:scalar, nil}, {:message, WACommon.MessageKey}},
        68 => {:messageAddOns, :unpacked, {:message, WAWebProtobufsWeb.MessageAddOn}},
        69 =>
          {:statusMentionMessageInfo, {:scalar, nil},
           {:message, WAWebProtobufsWeb.StatusMentionMessage}},
        70 => {:isSupportAiMessage, {:scalar, false}, :bool},
        71 => {:statusMentionSources, :unpacked, :string},
        72 => {:supportAiCitations, :unpacked, {:message, WAWebProtobufsWeb.Citation}},
        73 => {:botTargetID, {:scalar, ""}, :string},
        74 =>
          {:groupHistoryIndividualMessageInfo, {:scalar, nil},
           {:message, WAWebProtobufsWeb.GroupHistoryIndividualMessageInfo}},
        75 =>
          {:groupHistoryBundleInfo, {:scalar, nil},
           {:message, WAWebProtobufsWeb.GroupHistoryBundleInfo}},
        76 =>
          {:interactiveMessageAdditionalMetadata, {:scalar, nil},
           {:message, WAWebProtobufsWeb.InteractiveMessageAdditionalMetadata}},
        77 =>
          {:quarantinedMessage, {:scalar, nil}, {:message, WAWebProtobufsWeb.QuarantinedMessage}},
        78 => {:nonJIDMentions, {:scalar, 0}, :uint32},
        79 => {:hsmTag, {:scalar, ""}, :string},
        80 => {:ephemeralExpirationTimestamp, {:scalar, 0}, :uint64},
        81 =>
          {:scheduledMessageMetadata, {:scalar, nil},
           {:message, WAWebProtobufsWeb.ScheduledMessageMetadata}},
        82 => {:decisionID, {:scalar, ""}, :string},
        83 => {:decisionSources, :unpacked, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        agentID: {47, {:scalar, ""}, :string},
        bizPrivacyStatus:
          {36, {:scalar, :E2EE}, {:enum, WAWebProtobufsWeb.WebMessageInfo.BizPrivacyStatus}},
        botMessageInvokerJID: {58, {:scalar, ""}, :string},
        botTargetID: {73, {:scalar, ""}, :string},
        broadcast: {18, {:scalar, false}, :bool},
        clearMedia: {25, {:scalar, false}, :bool},
        commentMetadata: {59, {:scalar, nil}, {:message, WAWebProtobufsWeb.CommentMetadata}},
        decisionID: {82, {:scalar, ""}, :string},
        decisionSources: {83, :unpacked, :string},
        duration: {27, {:scalar, 0}, :uint32},
        ephemeralDuration: {33, {:scalar, 0}, :uint32},
        ephemeralExpirationTimestamp: {80, {:scalar, 0}, :uint64},
        ephemeralOffToOn: {34, {:scalar, false}, :bool},
        ephemeralOutOfSync: {35, {:scalar, false}, :bool},
        ephemeralStartTimestamp: {32, {:scalar, 0}, :uint64},
        eventAdditionalMetadata:
          {64, {:scalar, nil}, {:message, WAWebProtobufsWeb.EventAdditionalMetadata}},
        eventResponses: {61, :unpacked, {:message, WAWebProtobufsWeb.EventResponse}},
        finalLiveLocation:
          {30, {:scalar, nil}, {:message, WAWebProtobufsE2E.LiveLocationMessage}},
        futureproofData: {43, {:scalar, ""}, :bytes},
        groupHistoryBundleInfo:
          {75, {:scalar, nil}, {:message, WAWebProtobufsWeb.GroupHistoryBundleInfo}},
        groupHistoryIndividualMessageInfo:
          {74, {:scalar, nil}, {:message, WAWebProtobufsWeb.GroupHistoryIndividualMessageInfo}},
        hsmTag: {79, {:scalar, ""}, :string},
        ignore: {16, {:scalar, false}, :bool},
        interactiveMessageAdditionalMetadata:
          {76, {:scalar, nil}, {:message, WAWebProtobufsWeb.InteractiveMessageAdditionalMetadata}},
        is1PBizBotMessage: {56, {:scalar, false}, :bool},
        isGroupHistoryMessage: {57, {:scalar, false}, :bool},
        isMentionedInStatus: {65, {:scalar, false}, :bool},
        isSupportAiMessage: {70, {:scalar, false}, :bool},
        keepInChat: {50, {:scalar, nil}, {:message, WAWebProtobufsWeb.KeepInChat}},
        key: {1, {:scalar, nil}, {:message, WACommon.MessageKey}},
        labels: {28, :unpacked, :string},
        mediaCiphertextSHA256: {20, {:scalar, ""}, :bytes},
        mediaData: {38, {:scalar, nil}, {:message, WAWebProtobufsWeb.MediaData}},
        message: {2, {:scalar, nil}, {:message, WAWebProtobufsE2E.Message}},
        messageAddOns: {68, :unpacked, {:message, WAWebProtobufsWeb.MessageAddOn}},
        messageC2STimestamp: {6, {:scalar, 0}, :uint64},
        messageSecret: {49, {:scalar, ""}, :bytes},
        messageStubParameters: {26, :unpacked, :string},
        messageStubType:
          {24, {:scalar, :UNKNOWN}, {:enum, WAWebProtobufsWeb.WebMessageInfo.StubType}},
        messageTimestamp: {3, {:scalar, 0}, :uint64},
        multicast: {21, {:scalar, false}, :bool},
        newsletterServerID: {63, {:scalar, 0}, :uint64},
        nonJIDMentions: {78, {:scalar, 0}, :uint32},
        originalSelfAuthorUserJIDString: {51, {:scalar, ""}, :string},
        participant: {5, {:scalar, ""}, :string},
        paymentInfo: {29, {:scalar, nil}, {:message, WAWebProtobufsWeb.PaymentInfo}},
        photoChange: {39, {:scalar, nil}, {:message, WAWebProtobufsWeb.PhotoChange}},
        pinInChat: {54, {:scalar, nil}, {:message, WAWebProtobufsWeb.PinInChat}},
        pollAdditionalMetadata:
          {46, {:scalar, nil}, {:message, WAWebProtobufsWeb.PollAdditionalMetadata}},
        pollUpdates: {45, :unpacked, {:message, WAWebProtobufsWeb.PollUpdate}},
        premiumMessageInfo:
          {55, {:scalar, nil}, {:message, WAWebProtobufsWeb.PremiumMessageInfo}},
        pushName: {19, {:scalar, ""}, :string},
        quarantinedMessage:
          {77, {:scalar, nil}, {:message, WAWebProtobufsWeb.QuarantinedMessage}},
        quotedPaymentInfo: {31, {:scalar, nil}, {:message, WAWebProtobufsWeb.PaymentInfo}},
        quotedStickerData: {42, {:scalar, nil}, {:message, WAWebProtobufsWeb.MediaData}},
        reactions: {41, :unpacked, {:message, WAWebProtobufsWeb.Reaction}},
        reportingTokenInfo:
          {62, {:scalar, nil}, {:message, WAWebProtobufsWeb.ReportingTokenInfo}},
        revokeMessageTimestamp: {52, {:scalar, 0}, :uint64},
        scheduledMessageMetadata:
          {81, {:scalar, nil}, {:message, WAWebProtobufsWeb.ScheduledMessageMetadata}},
        starred: {17, {:scalar, false}, :bool},
        status: {4, {:scalar, :ERROR}, {:enum, WAWebProtobufsWeb.WebMessageInfo.Status}},
        statusAlreadyViewed: {48, {:scalar, false}, :bool},
        statusMentionMessageInfo:
          {69, {:scalar, nil}, {:message, WAWebProtobufsWeb.StatusMentionMessage}},
        statusMentionSources: {71, :unpacked, :string},
        statusMentions: {66, :unpacked, :string},
        statusPsa: {44, {:scalar, nil}, {:message, WAWebProtobufsWeb.StatusPSA}},
        supportAiCitations: {72, :unpacked, {:message, WAWebProtobufsWeb.Citation}},
        targetMessageID: {67, {:scalar, nil}, {:message, WACommon.MessageKey}},
        urlNumber: {23, {:scalar, false}, :bool},
        urlText: {22, {:scalar, false}, :bool},
        userReceipt: {40, :unpacked, {:message, WAWebProtobufsWeb.UserReceipt}},
        verifiedBizName: {37, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "key",
          kind: {:scalar, nil},
          label: :required,
          name: :key,
          tag: 1,
          type: {:message, WACommon.MessageKey}
        },
        %{
          __struct__: Protox.Field,
          json_name: "message",
          kind: {:scalar, nil},
          label: :optional,
          name: :message,
          tag: 2,
          type: {:message, WAWebProtobufsE2E.Message}
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :messageTimestamp,
          tag: 3,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "status",
          kind: {:scalar, :ERROR},
          label: :optional,
          name: :status,
          tag: 4,
          type: {:enum, WAWebProtobufsWeb.WebMessageInfo.Status}
        },
        %{
          __struct__: Protox.Field,
          json_name: "participant",
          kind: {:scalar, ""},
          label: :optional,
          name: :participant,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageC2STimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :messageC2STimestamp,
          tag: 6,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "ignore",
          kind: {:scalar, false},
          label: :optional,
          name: :ignore,
          tag: 16,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "starred",
          kind: {:scalar, false},
          label: :optional,
          name: :starred,
          tag: 17,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "broadcast",
          kind: {:scalar, false},
          label: :optional,
          name: :broadcast,
          tag: 18,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "pushName",
          kind: {:scalar, ""},
          label: :optional,
          name: :pushName,
          tag: 19,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaCiphertextSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :mediaCiphertextSHA256,
          tag: 20,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "multicast",
          kind: {:scalar, false},
          label: :optional,
          name: :multicast,
          tag: 21,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "urlText",
          kind: {:scalar, false},
          label: :optional,
          name: :urlText,
          tag: 22,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "urlNumber",
          kind: {:scalar, false},
          label: :optional,
          name: :urlNumber,
          tag: 23,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageStubType",
          kind: {:scalar, :UNKNOWN},
          label: :optional,
          name: :messageStubType,
          tag: 24,
          type: {:enum, WAWebProtobufsWeb.WebMessageInfo.StubType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "clearMedia",
          kind: {:scalar, false},
          label: :optional,
          name: :clearMedia,
          tag: 25,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageStubParameters",
          kind: :unpacked,
          label: :repeated,
          name: :messageStubParameters,
          tag: 26,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "duration",
          kind: {:scalar, 0},
          label: :optional,
          name: :duration,
          tag: 27,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "labels",
          kind: :unpacked,
          label: :repeated,
          name: :labels,
          tag: 28,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "paymentInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :paymentInfo,
          tag: 29,
          type: {:message, WAWebProtobufsWeb.PaymentInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "finalLiveLocation",
          kind: {:scalar, nil},
          label: :optional,
          name: :finalLiveLocation,
          tag: 30,
          type: {:message, WAWebProtobufsE2E.LiveLocationMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "quotedPaymentInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :quotedPaymentInfo,
          tag: 31,
          type: {:message, WAWebProtobufsWeb.PaymentInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeralStartTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :ephemeralStartTimestamp,
          tag: 32,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeralDuration",
          kind: {:scalar, 0},
          label: :optional,
          name: :ephemeralDuration,
          tag: 33,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeralOffToOn",
          kind: {:scalar, false},
          label: :optional,
          name: :ephemeralOffToOn,
          tag: 34,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeralOutOfSync",
          kind: {:scalar, false},
          label: :optional,
          name: :ephemeralOutOfSync,
          tag: 35,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "bizPrivacyStatus",
          kind: {:scalar, :E2EE},
          label: :optional,
          name: :bizPrivacyStatus,
          tag: 36,
          type: {:enum, WAWebProtobufsWeb.WebMessageInfo.BizPrivacyStatus}
        },
        %{
          __struct__: Protox.Field,
          json_name: "verifiedBizName",
          kind: {:scalar, ""},
          label: :optional,
          name: :verifiedBizName,
          tag: 37,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaData",
          kind: {:scalar, nil},
          label: :optional,
          name: :mediaData,
          tag: 38,
          type: {:message, WAWebProtobufsWeb.MediaData}
        },
        %{
          __struct__: Protox.Field,
          json_name: "photoChange",
          kind: {:scalar, nil},
          label: :optional,
          name: :photoChange,
          tag: 39,
          type: {:message, WAWebProtobufsWeb.PhotoChange}
        },
        %{
          __struct__: Protox.Field,
          json_name: "userReceipt",
          kind: :unpacked,
          label: :repeated,
          name: :userReceipt,
          tag: 40,
          type: {:message, WAWebProtobufsWeb.UserReceipt}
        },
        %{
          __struct__: Protox.Field,
          json_name: "reactions",
          kind: :unpacked,
          label: :repeated,
          name: :reactions,
          tag: 41,
          type: {:message, WAWebProtobufsWeb.Reaction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "quotedStickerData",
          kind: {:scalar, nil},
          label: :optional,
          name: :quotedStickerData,
          tag: 42,
          type: {:message, WAWebProtobufsWeb.MediaData}
        },
        %{
          __struct__: Protox.Field,
          json_name: "futureproofData",
          kind: {:scalar, ""},
          label: :optional,
          name: :futureproofData,
          tag: 43,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusPsa",
          kind: {:scalar, nil},
          label: :optional,
          name: :statusPsa,
          tag: 44,
          type: {:message, WAWebProtobufsWeb.StatusPSA}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollUpdates",
          kind: :unpacked,
          label: :repeated,
          name: :pollUpdates,
          tag: 45,
          type: {:message, WAWebProtobufsWeb.PollUpdate}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollAdditionalMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :pollAdditionalMetadata,
          tag: 46,
          type: {:message, WAWebProtobufsWeb.PollAdditionalMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "agentID",
          kind: {:scalar, ""},
          label: :optional,
          name: :agentID,
          tag: 47,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusAlreadyViewed",
          kind: {:scalar, false},
          label: :optional,
          name: :statusAlreadyViewed,
          tag: 48,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageSecret",
          kind: {:scalar, ""},
          label: :optional,
          name: :messageSecret,
          tag: 49,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "keepInChat",
          kind: {:scalar, nil},
          label: :optional,
          name: :keepInChat,
          tag: 50,
          type: {:message, WAWebProtobufsWeb.KeepInChat}
        },
        %{
          __struct__: Protox.Field,
          json_name: "originalSelfAuthorUserJIDString",
          kind: {:scalar, ""},
          label: :optional,
          name: :originalSelfAuthorUserJIDString,
          tag: 51,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "revokeMessageTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :revokeMessageTimestamp,
          tag: 52,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "pinInChat",
          kind: {:scalar, nil},
          label: :optional,
          name: :pinInChat,
          tag: 54,
          type: {:message, WAWebProtobufsWeb.PinInChat}
        },
        %{
          __struct__: Protox.Field,
          json_name: "premiumMessageInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :premiumMessageInfo,
          tag: 55,
          type: {:message, WAWebProtobufsWeb.PremiumMessageInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "is1PBizBotMessage",
          kind: {:scalar, false},
          label: :optional,
          name: :is1PBizBotMessage,
          tag: 56,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isGroupHistoryMessage",
          kind: {:scalar, false},
          label: :optional,
          name: :isGroupHistoryMessage,
          tag: 57,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "botMessageInvokerJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :botMessageInvokerJID,
          tag: 58,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "commentMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :commentMetadata,
          tag: 59,
          type: {:message, WAWebProtobufsWeb.CommentMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "eventResponses",
          kind: :unpacked,
          label: :repeated,
          name: :eventResponses,
          tag: 61,
          type: {:message, WAWebProtobufsWeb.EventResponse}
        },
        %{
          __struct__: Protox.Field,
          json_name: "reportingTokenInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :reportingTokenInfo,
          tag: 62,
          type: {:message, WAWebProtobufsWeb.ReportingTokenInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "newsletterServerID",
          kind: {:scalar, 0},
          label: :optional,
          name: :newsletterServerID,
          tag: 63,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "eventAdditionalMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :eventAdditionalMetadata,
          tag: 64,
          type: {:message, WAWebProtobufsWeb.EventAdditionalMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "isMentionedInStatus",
          kind: {:scalar, false},
          label: :optional,
          name: :isMentionedInStatus,
          tag: 65,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusMentions",
          kind: :unpacked,
          label: :repeated,
          name: :statusMentions,
          tag: 66,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "targetMessageID",
          kind: {:scalar, nil},
          label: :optional,
          name: :targetMessageID,
          tag: 67,
          type: {:message, WACommon.MessageKey}
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageAddOns",
          kind: :unpacked,
          label: :repeated,
          name: :messageAddOns,
          tag: 68,
          type: {:message, WAWebProtobufsWeb.MessageAddOn}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusMentionMessageInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :statusMentionMessageInfo,
          tag: 69,
          type: {:message, WAWebProtobufsWeb.StatusMentionMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "isSupportAiMessage",
          kind: {:scalar, false},
          label: :optional,
          name: :isSupportAiMessage,
          tag: 70,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusMentionSources",
          kind: :unpacked,
          label: :repeated,
          name: :statusMentionSources,
          tag: 71,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportAiCitations",
          kind: :unpacked,
          label: :repeated,
          name: :supportAiCitations,
          tag: 72,
          type: {:message, WAWebProtobufsWeb.Citation}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botTargetID",
          kind: {:scalar, ""},
          label: :optional,
          name: :botTargetID,
          tag: 73,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupHistoryIndividualMessageInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :groupHistoryIndividualMessageInfo,
          tag: 74,
          type: {:message, WAWebProtobufsWeb.GroupHistoryIndividualMessageInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupHistoryBundleInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :groupHistoryBundleInfo,
          tag: 75,
          type: {:message, WAWebProtobufsWeb.GroupHistoryBundleInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "interactiveMessageAdditionalMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :interactiveMessageAdditionalMetadata,
          tag: 76,
          type: {:message, WAWebProtobufsWeb.InteractiveMessageAdditionalMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "quarantinedMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :quarantinedMessage,
          tag: 77,
          type: {:message, WAWebProtobufsWeb.QuarantinedMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "nonJIDMentions",
          kind: {:scalar, 0},
          label: :optional,
          name: :nonJIDMentions,
          tag: 78,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "hsmTag",
          kind: {:scalar, ""},
          label: :optional,
          name: :hsmTag,
          tag: 79,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeralExpirationTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :ephemeralExpirationTimestamp,
          tag: 80,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "scheduledMessageMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :scheduledMessageMetadata,
          tag: 81,
          type: {:message, WAWebProtobufsWeb.ScheduledMessageMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "decisionID",
          kind: {:scalar, ""},
          label: :optional,
          name: :decisionID,
          tag: 82,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "decisionSources",
          kind: :unpacked,
          label: :repeated,
          name: :decisionSources,
          tag: 83,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:key) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "key",
             kind: {:scalar, nil},
             label: :required,
             name: :key,
             tag: 1,
             type: {:message, WACommon.MessageKey}
           }}
        end

        def field_def("key") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "key",
             kind: {:scalar, nil},
             label: :required,
             name: :key,
             tag: 1,
             type: {:message, WACommon.MessageKey}
           }}
        end

        []
      ),
      (
        def field_def(:message) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "message",
             kind: {:scalar, nil},
             label: :optional,
             name: :message,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.Message}
           }}
        end

        def field_def("message") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "message",
             kind: {:scalar, nil},
             label: :optional,
             name: :message,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.Message}
           }}
        end

        []
      ),
      (
        def field_def(:messageTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :messageTimestamp,
             tag: 3,
             type: :uint64
           }}
        end

        def field_def("messageTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :messageTimestamp,
             tag: 3,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:status) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "status",
             kind: {:scalar, :ERROR},
             label: :optional,
             name: :status,
             tag: 4,
             type: {:enum, WAWebProtobufsWeb.WebMessageInfo.Status}
           }}
        end

        def field_def("status") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "status",
             kind: {:scalar, :ERROR},
             label: :optional,
             name: :status,
             tag: 4,
             type: {:enum, WAWebProtobufsWeb.WebMessageInfo.Status}
           }}
        end

        []
      ),
      (
        def field_def(:participant) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "participant",
             kind: {:scalar, ""},
             label: :optional,
             name: :participant,
             tag: 5,
             type: :string
           }}
        end

        def field_def("participant") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "participant",
             kind: {:scalar, ""},
             label: :optional,
             name: :participant,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:messageC2STimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageC2STimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :messageC2STimestamp,
             tag: 6,
             type: :uint64
           }}
        end

        def field_def("messageC2STimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageC2STimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :messageC2STimestamp,
             tag: 6,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:ignore) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ignore",
             kind: {:scalar, false},
             label: :optional,
             name: :ignore,
             tag: 16,
             type: :bool
           }}
        end

        def field_def("ignore") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ignore",
             kind: {:scalar, false},
             label: :optional,
             name: :ignore,
             tag: 16,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:starred) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "starred",
             kind: {:scalar, false},
             label: :optional,
             name: :starred,
             tag: 17,
             type: :bool
           }}
        end

        def field_def("starred") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "starred",
             kind: {:scalar, false},
             label: :optional,
             name: :starred,
             tag: 17,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:broadcast) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "broadcast",
             kind: {:scalar, false},
             label: :optional,
             name: :broadcast,
             tag: 18,
             type: :bool
           }}
        end

        def field_def("broadcast") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "broadcast",
             kind: {:scalar, false},
             label: :optional,
             name: :broadcast,
             tag: 18,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:pushName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pushName",
             kind: {:scalar, ""},
             label: :optional,
             name: :pushName,
             tag: 19,
             type: :string
           }}
        end

        def field_def("pushName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pushName",
             kind: {:scalar, ""},
             label: :optional,
             name: :pushName,
             tag: 19,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:mediaCiphertextSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaCiphertextSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :mediaCiphertextSHA256,
             tag: 20,
             type: :bytes
           }}
        end

        def field_def("mediaCiphertextSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaCiphertextSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :mediaCiphertextSHA256,
             tag: 20,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:multicast) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "multicast",
             kind: {:scalar, false},
             label: :optional,
             name: :multicast,
             tag: 21,
             type: :bool
           }}
        end

        def field_def("multicast") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "multicast",
             kind: {:scalar, false},
             label: :optional,
             name: :multicast,
             tag: 21,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:urlText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "urlText",
             kind: {:scalar, false},
             label: :optional,
             name: :urlText,
             tag: 22,
             type: :bool
           }}
        end

        def field_def("urlText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "urlText",
             kind: {:scalar, false},
             label: :optional,
             name: :urlText,
             tag: 22,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:urlNumber) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "urlNumber",
             kind: {:scalar, false},
             label: :optional,
             name: :urlNumber,
             tag: 23,
             type: :bool
           }}
        end

        def field_def("urlNumber") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "urlNumber",
             kind: {:scalar, false},
             label: :optional,
             name: :urlNumber,
             tag: 23,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:messageStubType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageStubType",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :messageStubType,
             tag: 24,
             type: {:enum, WAWebProtobufsWeb.WebMessageInfo.StubType}
           }}
        end

        def field_def("messageStubType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageStubType",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :messageStubType,
             tag: 24,
             type: {:enum, WAWebProtobufsWeb.WebMessageInfo.StubType}
           }}
        end

        []
      ),
      (
        def field_def(:clearMedia) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "clearMedia",
             kind: {:scalar, false},
             label: :optional,
             name: :clearMedia,
             tag: 25,
             type: :bool
           }}
        end

        def field_def("clearMedia") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "clearMedia",
             kind: {:scalar, false},
             label: :optional,
             name: :clearMedia,
             tag: 25,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:messageStubParameters) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageStubParameters",
             kind: :unpacked,
             label: :repeated,
             name: :messageStubParameters,
             tag: 26,
             type: :string
           }}
        end

        def field_def("messageStubParameters") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageStubParameters",
             kind: :unpacked,
             label: :repeated,
             name: :messageStubParameters,
             tag: 26,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:duration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "duration",
             kind: {:scalar, 0},
             label: :optional,
             name: :duration,
             tag: 27,
             type: :uint32
           }}
        end

        def field_def("duration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "duration",
             kind: {:scalar, 0},
             label: :optional,
             name: :duration,
             tag: 27,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:labels) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "labels",
             kind: :unpacked,
             label: :repeated,
             name: :labels,
             tag: 28,
             type: :string
           }}
        end

        def field_def("labels") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "labels",
             kind: :unpacked,
             label: :repeated,
             name: :labels,
             tag: 28,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:paymentInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentInfo,
             tag: 29,
             type: {:message, WAWebProtobufsWeb.PaymentInfo}
           }}
        end

        def field_def("paymentInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentInfo,
             tag: 29,
             type: {:message, WAWebProtobufsWeb.PaymentInfo}
           }}
        end

        []
      ),
      (
        def field_def(:finalLiveLocation) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "finalLiveLocation",
             kind: {:scalar, nil},
             label: :optional,
             name: :finalLiveLocation,
             tag: 30,
             type: {:message, WAWebProtobufsE2E.LiveLocationMessage}
           }}
        end

        def field_def("finalLiveLocation") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "finalLiveLocation",
             kind: {:scalar, nil},
             label: :optional,
             name: :finalLiveLocation,
             tag: 30,
             type: {:message, WAWebProtobufsE2E.LiveLocationMessage}
           }}
        end

        []
      ),
      (
        def field_def(:quotedPaymentInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quotedPaymentInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :quotedPaymentInfo,
             tag: 31,
             type: {:message, WAWebProtobufsWeb.PaymentInfo}
           }}
        end

        def field_def("quotedPaymentInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quotedPaymentInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :quotedPaymentInfo,
             tag: 31,
             type: {:message, WAWebProtobufsWeb.PaymentInfo}
           }}
        end

        []
      ),
      (
        def field_def(:ephemeralStartTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralStartTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :ephemeralStartTimestamp,
             tag: 32,
             type: :uint64
           }}
        end

        def field_def("ephemeralStartTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralStartTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :ephemeralStartTimestamp,
             tag: 32,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:ephemeralDuration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralDuration",
             kind: {:scalar, 0},
             label: :optional,
             name: :ephemeralDuration,
             tag: 33,
             type: :uint32
           }}
        end

        def field_def("ephemeralDuration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralDuration",
             kind: {:scalar, 0},
             label: :optional,
             name: :ephemeralDuration,
             tag: 33,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:ephemeralOffToOn) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralOffToOn",
             kind: {:scalar, false},
             label: :optional,
             name: :ephemeralOffToOn,
             tag: 34,
             type: :bool
           }}
        end

        def field_def("ephemeralOffToOn") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralOffToOn",
             kind: {:scalar, false},
             label: :optional,
             name: :ephemeralOffToOn,
             tag: 34,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:ephemeralOutOfSync) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralOutOfSync",
             kind: {:scalar, false},
             label: :optional,
             name: :ephemeralOutOfSync,
             tag: 35,
             type: :bool
           }}
        end

        def field_def("ephemeralOutOfSync") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralOutOfSync",
             kind: {:scalar, false},
             label: :optional,
             name: :ephemeralOutOfSync,
             tag: 35,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:bizPrivacyStatus) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bizPrivacyStatus",
             kind: {:scalar, :E2EE},
             label: :optional,
             name: :bizPrivacyStatus,
             tag: 36,
             type: {:enum, WAWebProtobufsWeb.WebMessageInfo.BizPrivacyStatus}
           }}
        end

        def field_def("bizPrivacyStatus") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bizPrivacyStatus",
             kind: {:scalar, :E2EE},
             label: :optional,
             name: :bizPrivacyStatus,
             tag: 36,
             type: {:enum, WAWebProtobufsWeb.WebMessageInfo.BizPrivacyStatus}
           }}
        end

        []
      ),
      (
        def field_def(:verifiedBizName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "verifiedBizName",
             kind: {:scalar, ""},
             label: :optional,
             name: :verifiedBizName,
             tag: 37,
             type: :string
           }}
        end

        def field_def("verifiedBizName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "verifiedBizName",
             kind: {:scalar, ""},
             label: :optional,
             name: :verifiedBizName,
             tag: 37,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:mediaData) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaData",
             kind: {:scalar, nil},
             label: :optional,
             name: :mediaData,
             tag: 38,
             type: {:message, WAWebProtobufsWeb.MediaData}
           }}
        end

        def field_def("mediaData") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaData",
             kind: {:scalar, nil},
             label: :optional,
             name: :mediaData,
             tag: 38,
             type: {:message, WAWebProtobufsWeb.MediaData}
           }}
        end

        []
      ),
      (
        def field_def(:photoChange) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "photoChange",
             kind: {:scalar, nil},
             label: :optional,
             name: :photoChange,
             tag: 39,
             type: {:message, WAWebProtobufsWeb.PhotoChange}
           }}
        end

        def field_def("photoChange") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "photoChange",
             kind: {:scalar, nil},
             label: :optional,
             name: :photoChange,
             tag: 39,
             type: {:message, WAWebProtobufsWeb.PhotoChange}
           }}
        end

        []
      ),
      (
        def field_def(:userReceipt) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "userReceipt",
             kind: :unpacked,
             label: :repeated,
             name: :userReceipt,
             tag: 40,
             type: {:message, WAWebProtobufsWeb.UserReceipt}
           }}
        end

        def field_def("userReceipt") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "userReceipt",
             kind: :unpacked,
             label: :repeated,
             name: :userReceipt,
             tag: 40,
             type: {:message, WAWebProtobufsWeb.UserReceipt}
           }}
        end

        []
      ),
      (
        def field_def(:reactions) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reactions",
             kind: :unpacked,
             label: :repeated,
             name: :reactions,
             tag: 41,
             type: {:message, WAWebProtobufsWeb.Reaction}
           }}
        end

        def field_def("reactions") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reactions",
             kind: :unpacked,
             label: :repeated,
             name: :reactions,
             tag: 41,
             type: {:message, WAWebProtobufsWeb.Reaction}
           }}
        end

        []
      ),
      (
        def field_def(:quotedStickerData) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quotedStickerData",
             kind: {:scalar, nil},
             label: :optional,
             name: :quotedStickerData,
             tag: 42,
             type: {:message, WAWebProtobufsWeb.MediaData}
           }}
        end

        def field_def("quotedStickerData") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quotedStickerData",
             kind: {:scalar, nil},
             label: :optional,
             name: :quotedStickerData,
             tag: 42,
             type: {:message, WAWebProtobufsWeb.MediaData}
           }}
        end

        []
      ),
      (
        def field_def(:futureproofData) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "futureproofData",
             kind: {:scalar, ""},
             label: :optional,
             name: :futureproofData,
             tag: 43,
             type: :bytes
           }}
        end

        def field_def("futureproofData") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "futureproofData",
             kind: {:scalar, ""},
             label: :optional,
             name: :futureproofData,
             tag: 43,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:statusPsa) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusPsa",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusPsa,
             tag: 44,
             type: {:message, WAWebProtobufsWeb.StatusPSA}
           }}
        end

        def field_def("statusPsa") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusPsa",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusPsa,
             tag: 44,
             type: {:message, WAWebProtobufsWeb.StatusPSA}
           }}
        end

        []
      ),
      (
        def field_def(:pollUpdates) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollUpdates",
             kind: :unpacked,
             label: :repeated,
             name: :pollUpdates,
             tag: 45,
             type: {:message, WAWebProtobufsWeb.PollUpdate}
           }}
        end

        def field_def("pollUpdates") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollUpdates",
             kind: :unpacked,
             label: :repeated,
             name: :pollUpdates,
             tag: 45,
             type: {:message, WAWebProtobufsWeb.PollUpdate}
           }}
        end

        []
      ),
      (
        def field_def(:pollAdditionalMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollAdditionalMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollAdditionalMetadata,
             tag: 46,
             type: {:message, WAWebProtobufsWeb.PollAdditionalMetadata}
           }}
        end

        def field_def("pollAdditionalMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollAdditionalMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollAdditionalMetadata,
             tag: 46,
             type: {:message, WAWebProtobufsWeb.PollAdditionalMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:agentID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "agentID",
             kind: {:scalar, ""},
             label: :optional,
             name: :agentID,
             tag: 47,
             type: :string
           }}
        end

        def field_def("agentID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "agentID",
             kind: {:scalar, ""},
             label: :optional,
             name: :agentID,
             tag: 47,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:statusAlreadyViewed) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusAlreadyViewed",
             kind: {:scalar, false},
             label: :optional,
             name: :statusAlreadyViewed,
             tag: 48,
             type: :bool
           }}
        end

        def field_def("statusAlreadyViewed") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusAlreadyViewed",
             kind: {:scalar, false},
             label: :optional,
             name: :statusAlreadyViewed,
             tag: 48,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:messageSecret) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageSecret",
             kind: {:scalar, ""},
             label: :optional,
             name: :messageSecret,
             tag: 49,
             type: :bytes
           }}
        end

        def field_def("messageSecret") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageSecret",
             kind: {:scalar, ""},
             label: :optional,
             name: :messageSecret,
             tag: 49,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:keepInChat) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "keepInChat",
             kind: {:scalar, nil},
             label: :optional,
             name: :keepInChat,
             tag: 50,
             type: {:message, WAWebProtobufsWeb.KeepInChat}
           }}
        end

        def field_def("keepInChat") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "keepInChat",
             kind: {:scalar, nil},
             label: :optional,
             name: :keepInChat,
             tag: 50,
             type: {:message, WAWebProtobufsWeb.KeepInChat}
           }}
        end

        []
      ),
      (
        def field_def(:originalSelfAuthorUserJIDString) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "originalSelfAuthorUserJIDString",
             kind: {:scalar, ""},
             label: :optional,
             name: :originalSelfAuthorUserJIDString,
             tag: 51,
             type: :string
           }}
        end

        def field_def("originalSelfAuthorUserJIDString") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "originalSelfAuthorUserJIDString",
             kind: {:scalar, ""},
             label: :optional,
             name: :originalSelfAuthorUserJIDString,
             tag: 51,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:revokeMessageTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "revokeMessageTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :revokeMessageTimestamp,
             tag: 52,
             type: :uint64
           }}
        end

        def field_def("revokeMessageTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "revokeMessageTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :revokeMessageTimestamp,
             tag: 52,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:pinInChat) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pinInChat",
             kind: {:scalar, nil},
             label: :optional,
             name: :pinInChat,
             tag: 54,
             type: {:message, WAWebProtobufsWeb.PinInChat}
           }}
        end

        def field_def("pinInChat") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pinInChat",
             kind: {:scalar, nil},
             label: :optional,
             name: :pinInChat,
             tag: 54,
             type: {:message, WAWebProtobufsWeb.PinInChat}
           }}
        end

        []
      ),
      (
        def field_def(:premiumMessageInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "premiumMessageInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :premiumMessageInfo,
             tag: 55,
             type: {:message, WAWebProtobufsWeb.PremiumMessageInfo}
           }}
        end

        def field_def("premiumMessageInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "premiumMessageInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :premiumMessageInfo,
             tag: 55,
             type: {:message, WAWebProtobufsWeb.PremiumMessageInfo}
           }}
        end

        []
      ),
      (
        def field_def(:is1PBizBotMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "is1PBizBotMessage",
             kind: {:scalar, false},
             label: :optional,
             name: :is1PBizBotMessage,
             tag: 56,
             type: :bool
           }}
        end

        def field_def("is1PBizBotMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "is1PBizBotMessage",
             kind: {:scalar, false},
             label: :optional,
             name: :is1PBizBotMessage,
             tag: 56,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isGroupHistoryMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isGroupHistoryMessage",
             kind: {:scalar, false},
             label: :optional,
             name: :isGroupHistoryMessage,
             tag: 57,
             type: :bool
           }}
        end

        def field_def("isGroupHistoryMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isGroupHistoryMessage",
             kind: {:scalar, false},
             label: :optional,
             name: :isGroupHistoryMessage,
             tag: 57,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:botMessageInvokerJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botMessageInvokerJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :botMessageInvokerJID,
             tag: 58,
             type: :string
           }}
        end

        def field_def("botMessageInvokerJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botMessageInvokerJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :botMessageInvokerJID,
             tag: 58,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:commentMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "commentMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :commentMetadata,
             tag: 59,
             type: {:message, WAWebProtobufsWeb.CommentMetadata}
           }}
        end

        def field_def("commentMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "commentMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :commentMetadata,
             tag: 59,
             type: {:message, WAWebProtobufsWeb.CommentMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:eventResponses) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eventResponses",
             kind: :unpacked,
             label: :repeated,
             name: :eventResponses,
             tag: 61,
             type: {:message, WAWebProtobufsWeb.EventResponse}
           }}
        end

        def field_def("eventResponses") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eventResponses",
             kind: :unpacked,
             label: :repeated,
             name: :eventResponses,
             tag: 61,
             type: {:message, WAWebProtobufsWeb.EventResponse}
           }}
        end

        []
      ),
      (
        def field_def(:reportingTokenInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reportingTokenInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :reportingTokenInfo,
             tag: 62,
             type: {:message, WAWebProtobufsWeb.ReportingTokenInfo}
           }}
        end

        def field_def("reportingTokenInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reportingTokenInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :reportingTokenInfo,
             tag: 62,
             type: {:message, WAWebProtobufsWeb.ReportingTokenInfo}
           }}
        end

        []
      ),
      (
        def field_def(:newsletterServerID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterServerID",
             kind: {:scalar, 0},
             label: :optional,
             name: :newsletterServerID,
             tag: 63,
             type: :uint64
           }}
        end

        def field_def("newsletterServerID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterServerID",
             kind: {:scalar, 0},
             label: :optional,
             name: :newsletterServerID,
             tag: 63,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:eventAdditionalMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eventAdditionalMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :eventAdditionalMetadata,
             tag: 64,
             type: {:message, WAWebProtobufsWeb.EventAdditionalMetadata}
           }}
        end

        def field_def("eventAdditionalMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eventAdditionalMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :eventAdditionalMetadata,
             tag: 64,
             type: {:message, WAWebProtobufsWeb.EventAdditionalMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:isMentionedInStatus) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isMentionedInStatus",
             kind: {:scalar, false},
             label: :optional,
             name: :isMentionedInStatus,
             tag: 65,
             type: :bool
           }}
        end

        def field_def("isMentionedInStatus") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isMentionedInStatus",
             kind: {:scalar, false},
             label: :optional,
             name: :isMentionedInStatus,
             tag: 65,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:statusMentions) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusMentions",
             kind: :unpacked,
             label: :repeated,
             name: :statusMentions,
             tag: 66,
             type: :string
           }}
        end

        def field_def("statusMentions") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusMentions",
             kind: :unpacked,
             label: :repeated,
             name: :statusMentions,
             tag: 66,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:targetMessageID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "targetMessageID",
             kind: {:scalar, nil},
             label: :optional,
             name: :targetMessageID,
             tag: 67,
             type: {:message, WACommon.MessageKey}
           }}
        end

        def field_def("targetMessageID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "targetMessageID",
             kind: {:scalar, nil},
             label: :optional,
             name: :targetMessageID,
             tag: 67,
             type: {:message, WACommon.MessageKey}
           }}
        end

        []
      ),
      (
        def field_def(:messageAddOns) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageAddOns",
             kind: :unpacked,
             label: :repeated,
             name: :messageAddOns,
             tag: 68,
             type: {:message, WAWebProtobufsWeb.MessageAddOn}
           }}
        end

        def field_def("messageAddOns") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageAddOns",
             kind: :unpacked,
             label: :repeated,
             name: :messageAddOns,
             tag: 68,
             type: {:message, WAWebProtobufsWeb.MessageAddOn}
           }}
        end

        []
      ),
      (
        def field_def(:statusMentionMessageInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusMentionMessageInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusMentionMessageInfo,
             tag: 69,
             type: {:message, WAWebProtobufsWeb.StatusMentionMessage}
           }}
        end

        def field_def("statusMentionMessageInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusMentionMessageInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusMentionMessageInfo,
             tag: 69,
             type: {:message, WAWebProtobufsWeb.StatusMentionMessage}
           }}
        end

        []
      ),
      (
        def field_def(:isSupportAiMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSupportAiMessage",
             kind: {:scalar, false},
             label: :optional,
             name: :isSupportAiMessage,
             tag: 70,
             type: :bool
           }}
        end

        def field_def("isSupportAiMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSupportAiMessage",
             kind: {:scalar, false},
             label: :optional,
             name: :isSupportAiMessage,
             tag: 70,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:statusMentionSources) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusMentionSources",
             kind: :unpacked,
             label: :repeated,
             name: :statusMentionSources,
             tag: 71,
             type: :string
           }}
        end

        def field_def("statusMentionSources") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusMentionSources",
             kind: :unpacked,
             label: :repeated,
             name: :statusMentionSources,
             tag: 71,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:supportAiCitations) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportAiCitations",
             kind: :unpacked,
             label: :repeated,
             name: :supportAiCitations,
             tag: 72,
             type: {:message, WAWebProtobufsWeb.Citation}
           }}
        end

        def field_def("supportAiCitations") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportAiCitations",
             kind: :unpacked,
             label: :repeated,
             name: :supportAiCitations,
             tag: 72,
             type: {:message, WAWebProtobufsWeb.Citation}
           }}
        end

        []
      ),
      (
        def field_def(:botTargetID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botTargetID",
             kind: {:scalar, ""},
             label: :optional,
             name: :botTargetID,
             tag: 73,
             type: :string
           }}
        end

        def field_def("botTargetID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botTargetID",
             kind: {:scalar, ""},
             label: :optional,
             name: :botTargetID,
             tag: 73,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:groupHistoryIndividualMessageInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupHistoryIndividualMessageInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupHistoryIndividualMessageInfo,
             tag: 74,
             type: {:message, WAWebProtobufsWeb.GroupHistoryIndividualMessageInfo}
           }}
        end

        def field_def("groupHistoryIndividualMessageInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupHistoryIndividualMessageInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupHistoryIndividualMessageInfo,
             tag: 74,
             type: {:message, WAWebProtobufsWeb.GroupHistoryIndividualMessageInfo}
           }}
        end

        []
      ),
      (
        def field_def(:groupHistoryBundleInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupHistoryBundleInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupHistoryBundleInfo,
             tag: 75,
             type: {:message, WAWebProtobufsWeb.GroupHistoryBundleInfo}
           }}
        end

        def field_def("groupHistoryBundleInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupHistoryBundleInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupHistoryBundleInfo,
             tag: 75,
             type: {:message, WAWebProtobufsWeb.GroupHistoryBundleInfo}
           }}
        end

        []
      ),
      (
        def field_def(:interactiveMessageAdditionalMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "interactiveMessageAdditionalMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :interactiveMessageAdditionalMetadata,
             tag: 76,
             type: {:message, WAWebProtobufsWeb.InteractiveMessageAdditionalMetadata}
           }}
        end

        def field_def("interactiveMessageAdditionalMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "interactiveMessageAdditionalMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :interactiveMessageAdditionalMetadata,
             tag: 76,
             type: {:message, WAWebProtobufsWeb.InteractiveMessageAdditionalMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:quarantinedMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quarantinedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :quarantinedMessage,
             tag: 77,
             type: {:message, WAWebProtobufsWeb.QuarantinedMessage}
           }}
        end

        def field_def("quarantinedMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quarantinedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :quarantinedMessage,
             tag: 77,
             type: {:message, WAWebProtobufsWeb.QuarantinedMessage}
           }}
        end

        []
      ),
      (
        def field_def(:nonJIDMentions) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nonJIDMentions",
             kind: {:scalar, 0},
             label: :optional,
             name: :nonJIDMentions,
             tag: 78,
             type: :uint32
           }}
        end

        def field_def("nonJIDMentions") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nonJIDMentions",
             kind: {:scalar, 0},
             label: :optional,
             name: :nonJIDMentions,
             tag: 78,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:hsmTag) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hsmTag",
             kind: {:scalar, ""},
             label: :optional,
             name: :hsmTag,
             tag: 79,
             type: :string
           }}
        end

        def field_def("hsmTag") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hsmTag",
             kind: {:scalar, ""},
             label: :optional,
             name: :hsmTag,
             tag: 79,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:ephemeralExpirationTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralExpirationTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :ephemeralExpirationTimestamp,
             tag: 80,
             type: :uint64
           }}
        end

        def field_def("ephemeralExpirationTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralExpirationTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :ephemeralExpirationTimestamp,
             tag: 80,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:scheduledMessageMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "scheduledMessageMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :scheduledMessageMetadata,
             tag: 81,
             type: {:message, WAWebProtobufsWeb.ScheduledMessageMetadata}
           }}
        end

        def field_def("scheduledMessageMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "scheduledMessageMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :scheduledMessageMetadata,
             tag: 81,
             type: {:message, WAWebProtobufsWeb.ScheduledMessageMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:decisionID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "decisionID",
             kind: {:scalar, ""},
             label: :optional,
             name: :decisionID,
             tag: 82,
             type: :string
           }}
        end

        def field_def("decisionID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "decisionID",
             kind: {:scalar, ""},
             label: :optional,
             name: :decisionID,
             tag: 82,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:decisionSources) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "decisionSources",
             kind: :unpacked,
             label: :repeated,
             name: :decisionSources,
             tag: 83,
             type: :string
           }}
        end

        def field_def("decisionSources") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "decisionSources",
             kind: :unpacked,
             label: :repeated,
             name: :decisionSources,
             tag: 83,
             type: :string
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
    @spec required_fields() :: [:key]
    def required_fields() do
      [:key]
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
    def default(:key) do
      {:ok, nil}
    end,
    def default(:message) do
      {:ok, nil}
    end,
    def default(:messageTimestamp) do
      {:ok, 0}
    end,
    def default(:status) do
      {:ok, :ERROR}
    end,
    def default(:participant) do
      {:ok, ""}
    end,
    def default(:messageC2STimestamp) do
      {:ok, 0}
    end,
    def default(:ignore) do
      {:ok, false}
    end,
    def default(:starred) do
      {:ok, false}
    end,
    def default(:broadcast) do
      {:ok, false}
    end,
    def default(:pushName) do
      {:ok, ""}
    end,
    def default(:mediaCiphertextSHA256) do
      {:ok, ""}
    end,
    def default(:multicast) do
      {:ok, false}
    end,
    def default(:urlText) do
      {:ok, false}
    end,
    def default(:urlNumber) do
      {:ok, false}
    end,
    def default(:messageStubType) do
      {:ok, :UNKNOWN}
    end,
    def default(:clearMedia) do
      {:ok, false}
    end,
    def default(:messageStubParameters) do
      {:error, :no_default_value}
    end,
    def default(:duration) do
      {:ok, 0}
    end,
    def default(:labels) do
      {:error, :no_default_value}
    end,
    def default(:paymentInfo) do
      {:ok, nil}
    end,
    def default(:finalLiveLocation) do
      {:ok, nil}
    end,
    def default(:quotedPaymentInfo) do
      {:ok, nil}
    end,
    def default(:ephemeralStartTimestamp) do
      {:ok, 0}
    end,
    def default(:ephemeralDuration) do
      {:ok, 0}
    end,
    def default(:ephemeralOffToOn) do
      {:ok, false}
    end,
    def default(:ephemeralOutOfSync) do
      {:ok, false}
    end,
    def default(:bizPrivacyStatus) do
      {:ok, :E2EE}
    end,
    def default(:verifiedBizName) do
      {:ok, ""}
    end,
    def default(:mediaData) do
      {:ok, nil}
    end,
    def default(:photoChange) do
      {:ok, nil}
    end,
    def default(:userReceipt) do
      {:error, :no_default_value}
    end,
    def default(:reactions) do
      {:error, :no_default_value}
    end,
    def default(:quotedStickerData) do
      {:ok, nil}
    end,
    def default(:futureproofData) do
      {:ok, ""}
    end,
    def default(:statusPsa) do
      {:ok, nil}
    end,
    def default(:pollUpdates) do
      {:error, :no_default_value}
    end,
    def default(:pollAdditionalMetadata) do
      {:ok, nil}
    end,
    def default(:agentID) do
      {:ok, ""}
    end,
    def default(:statusAlreadyViewed) do
      {:ok, false}
    end,
    def default(:messageSecret) do
      {:ok, ""}
    end,
    def default(:keepInChat) do
      {:ok, nil}
    end,
    def default(:originalSelfAuthorUserJIDString) do
      {:ok, ""}
    end,
    def default(:revokeMessageTimestamp) do
      {:ok, 0}
    end,
    def default(:pinInChat) do
      {:ok, nil}
    end,
    def default(:premiumMessageInfo) do
      {:ok, nil}
    end,
    def default(:is1PBizBotMessage) do
      {:ok, false}
    end,
    def default(:isGroupHistoryMessage) do
      {:ok, false}
    end,
    def default(:botMessageInvokerJID) do
      {:ok, ""}
    end,
    def default(:commentMetadata) do
      {:ok, nil}
    end,
    def default(:eventResponses) do
      {:error, :no_default_value}
    end,
    def default(:reportingTokenInfo) do
      {:ok, nil}
    end,
    def default(:newsletterServerID) do
      {:ok, 0}
    end,
    def default(:eventAdditionalMetadata) do
      {:ok, nil}
    end,
    def default(:isMentionedInStatus) do
      {:ok, false}
    end,
    def default(:statusMentions) do
      {:error, :no_default_value}
    end,
    def default(:targetMessageID) do
      {:ok, nil}
    end,
    def default(:messageAddOns) do
      {:error, :no_default_value}
    end,
    def default(:statusMentionMessageInfo) do
      {:ok, nil}
    end,
    def default(:isSupportAiMessage) do
      {:ok, false}
    end,
    def default(:statusMentionSources) do
      {:error, :no_default_value}
    end,
    def default(:supportAiCitations) do
      {:error, :no_default_value}
    end,
    def default(:botTargetID) do
      {:ok, ""}
    end,
    def default(:groupHistoryIndividualMessageInfo) do
      {:ok, nil}
    end,
    def default(:groupHistoryBundleInfo) do
      {:ok, nil}
    end,
    def default(:interactiveMessageAdditionalMetadata) do
      {:ok, nil}
    end,
    def default(:quarantinedMessage) do
      {:ok, nil}
    end,
    def default(:nonJIDMentions) do
      {:ok, 0}
    end,
    def default(:hsmTag) do
      {:ok, ""}
    end,
    def default(:ephemeralExpirationTimestamp) do
      {:ok, 0}
    end,
    def default(:scheduledMessageMetadata) do
      {:ok, nil}
    end,
    def default(:decisionID) do
      {:ok, ""}
    end,
    def default(:decisionSources) do
      {:error, :no_default_value}
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
