# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ContextInfo do
  @moduledoc false
  defstruct stanzaID: nil,
            participant: nil,
            quotedMessage: nil,
            remoteJID: nil,
            mentionedJID: [],
            conversionSource: nil,
            conversionData: nil,
            conversionDelaySeconds: nil,
            forwardingScore: nil,
            isForwarded: nil,
            quotedAd: nil,
            placeholderKey: nil,
            expiration: nil,
            ephemeralSettingTimestamp: nil,
            ephemeralSharedSecret: nil,
            externalAdReply: nil,
            entryPointConversionSource: nil,
            entryPointConversionApp: nil,
            entryPointConversionDelaySeconds: nil,
            disappearingMode: nil,
            actionLink: nil,
            groupSubject: nil,
            parentGroupJID: nil,
            trustBannerType: nil,
            trustBannerAction: nil,
            isSampled: nil,
            groupMentions: [],
            utm: nil,
            forwardedNewsletterMessageInfo: nil,
            businessMessageForwardInfo: nil,
            smbClientCampaignID: nil,
            smbServerCampaignID: nil,
            dataSharingContext: nil,
            alwaysShowAdAttribution: nil,
            featureEligibilities: nil,
            entryPointConversionExternalSource: nil,
            entryPointConversionExternalMedium: nil,
            ctwaSignals: nil,
            ctwaPayload: nil,
            forwardedAiBotMessageInfo: nil,
            statusAttributionType: nil,
            urlTrackingMap: nil,
            pairedMediaType: nil,
            rankingVersion: nil,
            memberLabel: nil,
            isQuestion: nil,
            statusSourceType: nil,
            statusAttributions: [],
            isGroupStatus: nil,
            forwardOrigin: nil,
            questionReplyQuotedMessage: nil,
            statusAudienceMetadata: nil,
            nonJIDMentions: nil,
            quotedType: nil,
            botMessageSharingInfo: nil,
            isSpoiler: nil,
            mediaDomainInfo: nil,
            partiallySelectedContent: nil,
            afterReadDuration: nil,
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
        |> encode_stanzaID(msg)
        |> encode_participant(msg)
        |> encode_quotedMessage(msg)
        |> encode_remoteJID(msg)
        |> encode_mentionedJID(msg)
        |> encode_conversionSource(msg)
        |> encode_conversionData(msg)
        |> encode_conversionDelaySeconds(msg)
        |> encode_forwardingScore(msg)
        |> encode_isForwarded(msg)
        |> encode_quotedAd(msg)
        |> encode_placeholderKey(msg)
        |> encode_expiration(msg)
        |> encode_ephemeralSettingTimestamp(msg)
        |> encode_ephemeralSharedSecret(msg)
        |> encode_externalAdReply(msg)
        |> encode_entryPointConversionSource(msg)
        |> encode_entryPointConversionApp(msg)
        |> encode_entryPointConversionDelaySeconds(msg)
        |> encode_disappearingMode(msg)
        |> encode_actionLink(msg)
        |> encode_groupSubject(msg)
        |> encode_parentGroupJID(msg)
        |> encode_trustBannerType(msg)
        |> encode_trustBannerAction(msg)
        |> encode_isSampled(msg)
        |> encode_groupMentions(msg)
        |> encode_utm(msg)
        |> encode_forwardedNewsletterMessageInfo(msg)
        |> encode_businessMessageForwardInfo(msg)
        |> encode_smbClientCampaignID(msg)
        |> encode_smbServerCampaignID(msg)
        |> encode_dataSharingContext(msg)
        |> encode_alwaysShowAdAttribution(msg)
        |> encode_featureEligibilities(msg)
        |> encode_entryPointConversionExternalSource(msg)
        |> encode_entryPointConversionExternalMedium(msg)
        |> encode_ctwaSignals(msg)
        |> encode_ctwaPayload(msg)
        |> encode_forwardedAiBotMessageInfo(msg)
        |> encode_statusAttributionType(msg)
        |> encode_urlTrackingMap(msg)
        |> encode_pairedMediaType(msg)
        |> encode_rankingVersion(msg)
        |> encode_memberLabel(msg)
        |> encode_isQuestion(msg)
        |> encode_statusSourceType(msg)
        |> encode_statusAttributions(msg)
        |> encode_isGroupStatus(msg)
        |> encode_forwardOrigin(msg)
        |> encode_questionReplyQuotedMessage(msg)
        |> encode_statusAudienceMetadata(msg)
        |> encode_nonJIDMentions(msg)
        |> encode_quotedType(msg)
        |> encode_botMessageSharingInfo(msg)
        |> encode_isSpoiler(msg)
        |> encode_mediaDomainInfo(msg)
        |> encode_partiallySelectedContent(msg)
        |> encode_afterReadDuration(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_stanzaID(acc, msg) do
        try do
          case msg.stanzaID do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.stanzaID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:stanzaID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_participant(acc, msg) do
        try do
          case msg.participant do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.participant)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:participant, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_quotedMessage(acc, msg) do
        try do
          case msg.quotedMessage do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_message(msg.quotedMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:quotedMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_remoteJID(acc, msg) do
        try do
          case msg.remoteJID do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.remoteJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:remoteJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mentionedJID(acc, msg) do
        try do
          case msg.mentionedJID do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "z", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mentionedJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_conversionSource(acc, msg) do
        try do
          case msg.conversionSource do
            nil -> acc
            _ -> [acc, "\x92\x01", Protox.Encode.encode_string(msg.conversionSource)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:conversionSource, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_conversionData(acc, msg) do
        try do
          case msg.conversionData do
            nil -> acc
            _ -> [acc, "\x9A\x01", Protox.Encode.encode_bytes(msg.conversionData)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:conversionData, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_conversionDelaySeconds(acc, msg) do
        try do
          case msg.conversionDelaySeconds do
            nil -> acc
            _ -> [acc, "\xA0\x01", Protox.Encode.encode_uint32(msg.conversionDelaySeconds)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:conversionDelaySeconds, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_forwardingScore(acc, msg) do
        try do
          case msg.forwardingScore do
            nil -> acc
            _ -> [acc, "\xA8\x01", Protox.Encode.encode_uint32(msg.forwardingScore)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:forwardingScore, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isForwarded(acc, msg) do
        try do
          case msg.isForwarded do
            nil -> acc
            _ -> [acc, "\xB0\x01", Protox.Encode.encode_bool(msg.isForwarded)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isForwarded, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_quotedAd(acc, msg) do
        try do
          case msg.quotedAd do
            nil -> acc
            _ -> [acc, "\xBA\x01", Protox.Encode.encode_message(msg.quotedAd)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:quotedAd, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_placeholderKey(acc, msg) do
        try do
          case msg.placeholderKey do
            nil -> acc
            _ -> [acc, "\xC2\x01", Protox.Encode.encode_message(msg.placeholderKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:placeholderKey, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_expiration(acc, msg) do
        try do
          case msg.expiration do
            nil -> acc
            _ -> [acc, "\xC8\x01", Protox.Encode.encode_uint32(msg.expiration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:expiration, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_ephemeralSettingTimestamp(acc, msg) do
        try do
          case msg.ephemeralSettingTimestamp do
            nil -> acc
            _ -> [acc, "\xD0\x01", Protox.Encode.encode_int64(msg.ephemeralSettingTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeralSettingTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ephemeralSharedSecret(acc, msg) do
        try do
          case msg.ephemeralSharedSecret do
            nil -> acc
            _ -> [acc, "\xDA\x01", Protox.Encode.encode_bytes(msg.ephemeralSharedSecret)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeralSharedSecret, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_externalAdReply(acc, msg) do
        try do
          case msg.externalAdReply do
            nil -> acc
            _ -> [acc, "\xE2\x01", Protox.Encode.encode_message(msg.externalAdReply)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:externalAdReply, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_entryPointConversionSource(acc, msg) do
        try do
          case msg.entryPointConversionSource do
            nil -> acc
            _ -> [acc, "\xEA\x01", Protox.Encode.encode_string(msg.entryPointConversionSource)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:entryPointConversionSource, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_entryPointConversionApp(acc, msg) do
        try do
          case msg.entryPointConversionApp do
            nil -> acc
            _ -> [acc, "\xF2\x01", Protox.Encode.encode_string(msg.entryPointConversionApp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:entryPointConversionApp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_entryPointConversionDelaySeconds(acc, msg) do
        try do
          case msg.entryPointConversionDelaySeconds do
            nil ->
              acc

            _ ->
              [acc, "\xF8\x01", Protox.Encode.encode_uint32(msg.entryPointConversionDelaySeconds)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :entryPointConversionDelaySeconds,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_disappearingMode(acc, msg) do
        try do
          case msg.disappearingMode do
            nil -> acc
            _ -> [acc, "\x82\x02", Protox.Encode.encode_message(msg.disappearingMode)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:disappearingMode, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_actionLink(acc, msg) do
        try do
          case msg.actionLink do
            nil -> acc
            _ -> [acc, "\x8A\x02", Protox.Encode.encode_message(msg.actionLink)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:actionLink, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_groupSubject(acc, msg) do
        try do
          case msg.groupSubject do
            nil -> acc
            _ -> [acc, "\x92\x02", Protox.Encode.encode_string(msg.groupSubject)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupSubject, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_parentGroupJID(acc, msg) do
        try do
          case msg.parentGroupJID do
            nil -> acc
            _ -> [acc, "\x9A\x02", Protox.Encode.encode_string(msg.parentGroupJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:parentGroupJID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_trustBannerType(acc, msg) do
        try do
          case msg.trustBannerType do
            nil -> acc
            _ -> [acc, "\xAA\x02", Protox.Encode.encode_string(msg.trustBannerType)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:trustBannerType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_trustBannerAction(acc, msg) do
        try do
          case msg.trustBannerAction do
            nil -> acc
            _ -> [acc, "\xB0\x02", Protox.Encode.encode_uint32(msg.trustBannerAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:trustBannerAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isSampled(acc, msg) do
        try do
          case msg.isSampled do
            nil -> acc
            _ -> [acc, "\xB8\x02", Protox.Encode.encode_bool(msg.isSampled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isSampled, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_groupMentions(acc, msg) do
        try do
          case msg.groupMentions do
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
            reraise Protox.EncodingError.new(:groupMentions, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_utm(acc, msg) do
        try do
          case msg.utm do
            nil -> acc
            _ -> [acc, "\xCA\x02", Protox.Encode.encode_message(msg.utm)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:utm, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_forwardedNewsletterMessageInfo(acc, msg) do
        try do
          case msg.forwardedNewsletterMessageInfo do
            nil ->
              acc

            _ ->
              [acc, "\xDA\x02", Protox.Encode.encode_message(msg.forwardedNewsletterMessageInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :forwardedNewsletterMessageInfo,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_businessMessageForwardInfo(acc, msg) do
        try do
          case msg.businessMessageForwardInfo do
            nil -> acc
            _ -> [acc, "\xE2\x02", Protox.Encode.encode_message(msg.businessMessageForwardInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:businessMessageForwardInfo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_smbClientCampaignID(acc, msg) do
        try do
          case msg.smbClientCampaignID do
            nil -> acc
            _ -> [acc, "\xEA\x02", Protox.Encode.encode_string(msg.smbClientCampaignID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:smbClientCampaignID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_smbServerCampaignID(acc, msg) do
        try do
          case msg.smbServerCampaignID do
            nil -> acc
            _ -> [acc, "\xF2\x02", Protox.Encode.encode_string(msg.smbServerCampaignID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:smbServerCampaignID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_dataSharingContext(acc, msg) do
        try do
          case msg.dataSharingContext do
            nil -> acc
            _ -> [acc, "\xFA\x02", Protox.Encode.encode_message(msg.dataSharingContext)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:dataSharingContext, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_alwaysShowAdAttribution(acc, msg) do
        try do
          case msg.alwaysShowAdAttribution do
            nil -> acc
            _ -> [acc, "\x80\x03", Protox.Encode.encode_bool(msg.alwaysShowAdAttribution)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:alwaysShowAdAttribution, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_featureEligibilities(acc, msg) do
        try do
          case msg.featureEligibilities do
            nil -> acc
            _ -> [acc, "\x8A\x03", Protox.Encode.encode_message(msg.featureEligibilities)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:featureEligibilities, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_entryPointConversionExternalSource(acc, msg) do
        try do
          case msg.entryPointConversionExternalSource do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x92\x03",
                Protox.Encode.encode_string(msg.entryPointConversionExternalSource)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :entryPointConversionExternalSource,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_entryPointConversionExternalMedium(acc, msg) do
        try do
          case msg.entryPointConversionExternalMedium do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x9A\x03",
                Protox.Encode.encode_string(msg.entryPointConversionExternalMedium)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :entryPointConversionExternalMedium,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_ctwaSignals(acc, msg) do
        try do
          case msg.ctwaSignals do
            nil -> acc
            _ -> [acc, "\xB2\x03", Protox.Encode.encode_string(msg.ctwaSignals)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ctwaSignals, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_ctwaPayload(acc, msg) do
        try do
          case msg.ctwaPayload do
            nil -> acc
            _ -> [acc, "\xBA\x03", Protox.Encode.encode_bytes(msg.ctwaPayload)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ctwaPayload, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_forwardedAiBotMessageInfo(acc, msg) do
        try do
          case msg.forwardedAiBotMessageInfo do
            nil -> acc
            _ -> [acc, "\xC2\x03", Protox.Encode.encode_message(msg.forwardedAiBotMessageInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:forwardedAiBotMessageInfo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusAttributionType(acc, msg) do
        try do
          case msg.statusAttributionType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xC8\x03",
                msg.statusAttributionType
                |> WAWebProtobufsE2E.ContextInfo.StatusAttributionType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusAttributionType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_urlTrackingMap(acc, msg) do
        try do
          case msg.urlTrackingMap do
            nil -> acc
            _ -> [acc, "\xD2\x03", Protox.Encode.encode_message(msg.urlTrackingMap)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:urlTrackingMap, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pairedMediaType(acc, msg) do
        try do
          case msg.pairedMediaType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xD8\x03",
                msg.pairedMediaType
                |> WAWebProtobufsE2E.ContextInfo.PairedMediaType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pairedMediaType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_rankingVersion(acc, msg) do
        try do
          case msg.rankingVersion do
            nil -> acc
            _ -> [acc, "\xE0\x03", Protox.Encode.encode_uint32(msg.rankingVersion)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:rankingVersion, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_memberLabel(acc, msg) do
        try do
          case msg.memberLabel do
            nil -> acc
            _ -> [acc, "\xF2\x03", Protox.Encode.encode_message(msg.memberLabel)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:memberLabel, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isQuestion(acc, msg) do
        try do
          case msg.isQuestion do
            nil -> acc
            _ -> [acc, "\xF8\x03", Protox.Encode.encode_bool(msg.isQuestion)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isQuestion, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_statusSourceType(acc, msg) do
        try do
          case msg.statusSourceType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x80\x04",
                msg.statusSourceType
                |> WAWebProtobufsE2E.ContextInfo.StatusSourceType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusSourceType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusAttributions(acc, msg) do
        try do
          case msg.statusAttributions do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\x8A\x04", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusAttributions, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isGroupStatus(acc, msg) do
        try do
          case msg.isGroupStatus do
            nil -> acc
            _ -> [acc, "\x90\x04", Protox.Encode.encode_bool(msg.isGroupStatus)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isGroupStatus, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_forwardOrigin(acc, msg) do
        try do
          case msg.forwardOrigin do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x98\x04",
                msg.forwardOrigin
                |> WAWebProtobufsE2E.ContextInfo.ForwardOrigin.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:forwardOrigin, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_questionReplyQuotedMessage(acc, msg) do
        try do
          case msg.questionReplyQuotedMessage do
            nil -> acc
            _ -> [acc, "\xA2\x04", Protox.Encode.encode_message(msg.questionReplyQuotedMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:questionReplyQuotedMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusAudienceMetadata(acc, msg) do
        try do
          case msg.statusAudienceMetadata do
            nil -> acc
            _ -> [acc, "\xAA\x04", Protox.Encode.encode_message(msg.statusAudienceMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusAudienceMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_nonJIDMentions(acc, msg) do
        try do
          case msg.nonJIDMentions do
            nil -> acc
            _ -> [acc, "\xB0\x04", Protox.Encode.encode_uint32(msg.nonJIDMentions)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:nonJIDMentions, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_quotedType(acc, msg) do
        try do
          case msg.quotedType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xB8\x04",
                msg.quotedType
                |> WAWebProtobufsE2E.ContextInfo.QuotedType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:quotedType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_botMessageSharingInfo(acc, msg) do
        try do
          case msg.botMessageSharingInfo do
            nil -> acc
            _ -> [acc, "\xC2\x04", Protox.Encode.encode_message(msg.botMessageSharingInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botMessageSharingInfo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isSpoiler(acc, msg) do
        try do
          case msg.isSpoiler do
            nil -> acc
            _ -> [acc, "\xC8\x04", Protox.Encode.encode_bool(msg.isSpoiler)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isSpoiler, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaDomainInfo(acc, msg) do
        try do
          case msg.mediaDomainInfo do
            nil -> acc
            _ -> [acc, "\xD2\x04", Protox.Encode.encode_message(msg.mediaDomainInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaDomainInfo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_partiallySelectedContent(acc, msg) do
        try do
          case msg.partiallySelectedContent do
            nil -> acc
            _ -> [acc, "\xDA\x04", Protox.Encode.encode_message(msg.partiallySelectedContent)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:partiallySelectedContent, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_afterReadDuration(acc, msg) do
        try do
          case msg.afterReadDuration do
            nil -> acc
            _ -> [acc, "\xE0\x04", Protox.Encode.encode_uint32(msg.afterReadDuration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:afterReadDuration, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.ContextInfo))
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
              {[stanzaID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[participant: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 quotedMessage:
                   Protox.MergeMessage.merge(
                     msg.quotedMessage,
                     WAWebProtobufsE2E.Message.decode!(delimited)
                   )
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[remoteJID: Protox.Decode.validate_string!(delimited)], rest}

            {15, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[mentionedJID: msg.mentionedJID ++ [Protox.Decode.validate_string!(delimited)]],
               rest}

            {18, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[conversionSource: Protox.Decode.validate_string!(delimited)], rest}

            {19, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[conversionData: delimited], rest}

            {20, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[conversionDelaySeconds: value], rest}

            {21, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[forwardingScore: value], rest}

            {22, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isForwarded: value], rest}

            {23, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 quotedAd:
                   Protox.MergeMessage.merge(
                     msg.quotedAd,
                     WAWebProtobufsE2E.ContextInfo.AdReplyInfo.decode!(delimited)
                   )
               ], rest}

            {24, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 placeholderKey:
                   Protox.MergeMessage.merge(
                     msg.placeholderKey,
                     WACommon.MessageKey.decode!(delimited)
                   )
               ], rest}

            {25, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[expiration: value], rest}

            {26, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[ephemeralSettingTimestamp: value], rest}

            {27, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[ephemeralSharedSecret: delimited], rest}

            {28, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 externalAdReply:
                   Protox.MergeMessage.merge(
                     msg.externalAdReply,
                     WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.decode!(delimited)
                   )
               ], rest}

            {29, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[entryPointConversionSource: Protox.Decode.validate_string!(delimited)], rest}

            {30, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[entryPointConversionApp: Protox.Decode.validate_string!(delimited)], rest}

            {31, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[entryPointConversionDelaySeconds: value], rest}

            {32, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 disappearingMode:
                   Protox.MergeMessage.merge(
                     msg.disappearingMode,
                     WAWebProtobufsE2E.DisappearingMode.decode!(delimited)
                   )
               ], rest}

            {33, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 actionLink:
                   Protox.MergeMessage.merge(
                     msg.actionLink,
                     WAWebProtobufsE2E.ActionLink.decode!(delimited)
                   )
               ], rest}

            {34, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[groupSubject: Protox.Decode.validate_string!(delimited)], rest}

            {35, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[parentGroupJID: Protox.Decode.validate_string!(delimited)], rest}

            {37, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[trustBannerType: Protox.Decode.validate_string!(delimited)], rest}

            {38, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[trustBannerAction: value], rest}

            {39, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isSampled: value], rest}

            {40, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 groupMentions:
                   msg.groupMentions ++ [WAWebProtobufsE2E.GroupMention.decode!(delimited)]
               ], rest}

            {41, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 utm:
                   Protox.MergeMessage.merge(
                     msg.utm,
                     WAWebProtobufsE2E.ContextInfo.UTMInfo.decode!(delimited)
                   )
               ], rest}

            {43, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 forwardedNewsletterMessageInfo:
                   Protox.MergeMessage.merge(
                     msg.forwardedNewsletterMessageInfo,
                     WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo.decode!(
                       delimited
                     )
                   )
               ], rest}

            {44, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 businessMessageForwardInfo:
                   Protox.MergeMessage.merge(
                     msg.businessMessageForwardInfo,
                     WAWebProtobufsE2E.ContextInfo.BusinessMessageForwardInfo.decode!(delimited)
                   )
               ], rest}

            {45, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[smbClientCampaignID: Protox.Decode.validate_string!(delimited)], rest}

            {46, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[smbServerCampaignID: Protox.Decode.validate_string!(delimited)], rest}

            {47, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 dataSharingContext:
                   Protox.MergeMessage.merge(
                     msg.dataSharingContext,
                     WAWebProtobufsE2E.ContextInfo.DataSharingContext.decode!(delimited)
                   )
               ], rest}

            {48, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[alwaysShowAdAttribution: value], rest}

            {49, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 featureEligibilities:
                   Protox.MergeMessage.merge(
                     msg.featureEligibilities,
                     WAWebProtobufsE2E.ContextInfo.FeatureEligibilities.decode!(delimited)
                   )
               ], rest}

            {50, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[entryPointConversionExternalSource: Protox.Decode.validate_string!(delimited)],
               rest}

            {51, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[entryPointConversionExternalMedium: Protox.Decode.validate_string!(delimited)],
               rest}

            {54, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[ctwaSignals: Protox.Decode.validate_string!(delimited)], rest}

            {55, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[ctwaPayload: delimited], rest}

            {56, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 forwardedAiBotMessageInfo:
                   Protox.MergeMessage.merge(
                     msg.forwardedAiBotMessageInfo,
                     WAWebProtobufsAICommon.ForwardedAIBotMessageInfo.decode!(delimited)
                   )
               ], rest}

            {57, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.ContextInfo.StatusAttributionType
                )

              {[statusAttributionType: value], rest}

            {58, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 urlTrackingMap:
                   Protox.MergeMessage.merge(
                     msg.urlTrackingMap,
                     WAWebProtobufsE2E.UrlTrackingMap.decode!(delimited)
                   )
               ], rest}

            {59, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.ContextInfo.PairedMediaType)

              {[pairedMediaType: value], rest}

            {60, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[rankingVersion: value], rest}

            {62, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 memberLabel:
                   Protox.MergeMessage.merge(
                     msg.memberLabel,
                     WAWebProtobufsE2E.MemberLabel.decode!(delimited)
                   )
               ], rest}

            {63, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isQuestion: value], rest}

            {64, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.ContextInfo.StatusSourceType)

              {[statusSourceType: value], rest}

            {65, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 statusAttributions:
                   msg.statusAttributions ++
                     [WAStatusAttributions.StatusAttribution.decode!(delimited)]
               ], rest}

            {66, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isGroupStatus: value], rest}

            {67, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.ContextInfo.ForwardOrigin)

              {[forwardOrigin: value], rest}

            {68, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 questionReplyQuotedMessage:
                   Protox.MergeMessage.merge(
                     msg.questionReplyQuotedMessage,
                     WAWebProtobufsE2E.ContextInfo.QuestionReplyQuotedMessage.decode!(delimited)
                   )
               ], rest}

            {69, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 statusAudienceMetadata:
                   Protox.MergeMessage.merge(
                     msg.statusAudienceMetadata,
                     WAWebProtobufsE2E.ContextInfo.StatusAudienceMetadata.decode!(delimited)
                   )
               ], rest}

            {70, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[nonJIDMentions: value], rest}

            {71, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.ContextInfo.QuotedType)

              {[quotedType: value], rest}

            {72, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botMessageSharingInfo:
                   Protox.MergeMessage.merge(
                     msg.botMessageSharingInfo,
                     WAWebProtobufsAICommon.BotMessageSharingInfo.decode!(delimited)
                   )
               ], rest}

            {73, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isSpoiler: value], rest}

            {74, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 mediaDomainInfo:
                   Protox.MergeMessage.merge(
                     msg.mediaDomainInfo,
                     WAWebProtobufsE2E.MediaDomainInfo.decode!(delimited)
                   )
               ], rest}

            {75, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 partiallySelectedContent:
                   Protox.MergeMessage.merge(
                     msg.partiallySelectedContent,
                     WAWebProtobufsE2E.ContextInfo.PartiallySelectedContent.decode!(delimited)
                   )
               ], rest}

            {76, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[afterReadDuration: value], rest}

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
        WAWebProtobufsE2E.ContextInfo,
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
        1 => {:stanzaID, {:scalar, ""}, :string},
        2 => {:participant, {:scalar, ""}, :string},
        3 => {:quotedMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.Message}},
        4 => {:remoteJID, {:scalar, ""}, :string},
        15 => {:mentionedJID, :unpacked, :string},
        18 => {:conversionSource, {:scalar, ""}, :string},
        19 => {:conversionData, {:scalar, ""}, :bytes},
        20 => {:conversionDelaySeconds, {:scalar, 0}, :uint32},
        21 => {:forwardingScore, {:scalar, 0}, :uint32},
        22 => {:isForwarded, {:scalar, false}, :bool},
        23 => {:quotedAd, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo.AdReplyInfo}},
        24 => {:placeholderKey, {:scalar, nil}, {:message, WACommon.MessageKey}},
        25 => {:expiration, {:scalar, 0}, :uint32},
        26 => {:ephemeralSettingTimestamp, {:scalar, 0}, :int64},
        27 => {:ephemeralSharedSecret, {:scalar, ""}, :bytes},
        28 =>
          {:externalAdReply, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo}},
        29 => {:entryPointConversionSource, {:scalar, ""}, :string},
        30 => {:entryPointConversionApp, {:scalar, ""}, :string},
        31 => {:entryPointConversionDelaySeconds, {:scalar, 0}, :uint32},
        32 => {:disappearingMode, {:scalar, nil}, {:message, WAWebProtobufsE2E.DisappearingMode}},
        33 => {:actionLink, {:scalar, nil}, {:message, WAWebProtobufsE2E.ActionLink}},
        34 => {:groupSubject, {:scalar, ""}, :string},
        35 => {:parentGroupJID, {:scalar, ""}, :string},
        37 => {:trustBannerType, {:scalar, ""}, :string},
        38 => {:trustBannerAction, {:scalar, 0}, :uint32},
        39 => {:isSampled, {:scalar, false}, :bool},
        40 => {:groupMentions, :unpacked, {:message, WAWebProtobufsE2E.GroupMention}},
        41 => {:utm, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo.UTMInfo}},
        43 =>
          {:forwardedNewsletterMessageInfo, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo}},
        44 =>
          {:businessMessageForwardInfo, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ContextInfo.BusinessMessageForwardInfo}},
        45 => {:smbClientCampaignID, {:scalar, ""}, :string},
        46 => {:smbServerCampaignID, {:scalar, ""}, :string},
        47 =>
          {:dataSharingContext, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ContextInfo.DataSharingContext}},
        48 => {:alwaysShowAdAttribution, {:scalar, false}, :bool},
        49 =>
          {:featureEligibilities, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ContextInfo.FeatureEligibilities}},
        50 => {:entryPointConversionExternalSource, {:scalar, ""}, :string},
        51 => {:entryPointConversionExternalMedium, {:scalar, ""}, :string},
        54 => {:ctwaSignals, {:scalar, ""}, :string},
        55 => {:ctwaPayload, {:scalar, ""}, :bytes},
        56 =>
          {:forwardedAiBotMessageInfo, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.ForwardedAIBotMessageInfo}},
        57 =>
          {:statusAttributionType, {:scalar, :NONE},
           {:enum, WAWebProtobufsE2E.ContextInfo.StatusAttributionType}},
        58 => {:urlTrackingMap, {:scalar, nil}, {:message, WAWebProtobufsE2E.UrlTrackingMap}},
        59 =>
          {:pairedMediaType, {:scalar, :NOT_PAIRED_MEDIA},
           {:enum, WAWebProtobufsE2E.ContextInfo.PairedMediaType}},
        60 => {:rankingVersion, {:scalar, 0}, :uint32},
        62 => {:memberLabel, {:scalar, nil}, {:message, WAWebProtobufsE2E.MemberLabel}},
        63 => {:isQuestion, {:scalar, false}, :bool},
        64 =>
          {:statusSourceType, {:scalar, :IMAGE},
           {:enum, WAWebProtobufsE2E.ContextInfo.StatusSourceType}},
        65 =>
          {:statusAttributions, :unpacked, {:message, WAStatusAttributions.StatusAttribution}},
        66 => {:isGroupStatus, {:scalar, false}, :bool},
        67 =>
          {:forwardOrigin, {:scalar, :UNKNOWN},
           {:enum, WAWebProtobufsE2E.ContextInfo.ForwardOrigin}},
        68 =>
          {:questionReplyQuotedMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ContextInfo.QuestionReplyQuotedMessage}},
        69 =>
          {:statusAudienceMetadata, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ContextInfo.StatusAudienceMetadata}},
        70 => {:nonJIDMentions, {:scalar, 0}, :uint32},
        71 =>
          {:quotedType, {:scalar, :EXPLICIT}, {:enum, WAWebProtobufsE2E.ContextInfo.QuotedType}},
        72 =>
          {:botMessageSharingInfo, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotMessageSharingInfo}},
        73 => {:isSpoiler, {:scalar, false}, :bool},
        74 => {:mediaDomainInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.MediaDomainInfo}},
        75 =>
          {:partiallySelectedContent, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ContextInfo.PartiallySelectedContent}},
        76 => {:afterReadDuration, {:scalar, 0}, :uint32}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        actionLink: {33, {:scalar, nil}, {:message, WAWebProtobufsE2E.ActionLink}},
        afterReadDuration: {76, {:scalar, 0}, :uint32},
        alwaysShowAdAttribution: {48, {:scalar, false}, :bool},
        botMessageSharingInfo:
          {72, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotMessageSharingInfo}},
        businessMessageForwardInfo:
          {44, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ContextInfo.BusinessMessageForwardInfo}},
        conversionData: {19, {:scalar, ""}, :bytes},
        conversionDelaySeconds: {20, {:scalar, 0}, :uint32},
        conversionSource: {18, {:scalar, ""}, :string},
        ctwaPayload: {55, {:scalar, ""}, :bytes},
        ctwaSignals: {54, {:scalar, ""}, :string},
        dataSharingContext:
          {47, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo.DataSharingContext}},
        disappearingMode: {32, {:scalar, nil}, {:message, WAWebProtobufsE2E.DisappearingMode}},
        entryPointConversionApp: {30, {:scalar, ""}, :string},
        entryPointConversionDelaySeconds: {31, {:scalar, 0}, :uint32},
        entryPointConversionExternalMedium: {51, {:scalar, ""}, :string},
        entryPointConversionExternalSource: {50, {:scalar, ""}, :string},
        entryPointConversionSource: {29, {:scalar, ""}, :string},
        ephemeralSettingTimestamp: {26, {:scalar, 0}, :int64},
        ephemeralSharedSecret: {27, {:scalar, ""}, :bytes},
        expiration: {25, {:scalar, 0}, :uint32},
        externalAdReply:
          {28, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo}},
        featureEligibilities:
          {49, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo.FeatureEligibilities}},
        forwardOrigin:
          {67, {:scalar, :UNKNOWN}, {:enum, WAWebProtobufsE2E.ContextInfo.ForwardOrigin}},
        forwardedAiBotMessageInfo:
          {56, {:scalar, nil}, {:message, WAWebProtobufsAICommon.ForwardedAIBotMessageInfo}},
        forwardedNewsletterMessageInfo:
          {43, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo}},
        forwardingScore: {21, {:scalar, 0}, :uint32},
        groupMentions: {40, :unpacked, {:message, WAWebProtobufsE2E.GroupMention}},
        groupSubject: {34, {:scalar, ""}, :string},
        isForwarded: {22, {:scalar, false}, :bool},
        isGroupStatus: {66, {:scalar, false}, :bool},
        isQuestion: {63, {:scalar, false}, :bool},
        isSampled: {39, {:scalar, false}, :bool},
        isSpoiler: {73, {:scalar, false}, :bool},
        mediaDomainInfo: {74, {:scalar, nil}, {:message, WAWebProtobufsE2E.MediaDomainInfo}},
        memberLabel: {62, {:scalar, nil}, {:message, WAWebProtobufsE2E.MemberLabel}},
        mentionedJID: {15, :unpacked, :string},
        nonJIDMentions: {70, {:scalar, 0}, :uint32},
        pairedMediaType:
          {59, {:scalar, :NOT_PAIRED_MEDIA},
           {:enum, WAWebProtobufsE2E.ContextInfo.PairedMediaType}},
        parentGroupJID: {35, {:scalar, ""}, :string},
        partiallySelectedContent:
          {75, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo.PartiallySelectedContent}},
        participant: {2, {:scalar, ""}, :string},
        placeholderKey: {24, {:scalar, nil}, {:message, WACommon.MessageKey}},
        questionReplyQuotedMessage:
          {68, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ContextInfo.QuestionReplyQuotedMessage}},
        quotedAd: {23, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo.AdReplyInfo}},
        quotedMessage: {3, {:scalar, nil}, {:message, WAWebProtobufsE2E.Message}},
        quotedType: {71, {:scalar, :EXPLICIT}, {:enum, WAWebProtobufsE2E.ContextInfo.QuotedType}},
        rankingVersion: {60, {:scalar, 0}, :uint32},
        remoteJID: {4, {:scalar, ""}, :string},
        smbClientCampaignID: {45, {:scalar, ""}, :string},
        smbServerCampaignID: {46, {:scalar, ""}, :string},
        stanzaID: {1, {:scalar, ""}, :string},
        statusAttributionType:
          {57, {:scalar, :NONE}, {:enum, WAWebProtobufsE2E.ContextInfo.StatusAttributionType}},
        statusAttributions: {65, :unpacked, {:message, WAStatusAttributions.StatusAttribution}},
        statusAudienceMetadata:
          {69, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo.StatusAudienceMetadata}},
        statusSourceType:
          {64, {:scalar, :IMAGE}, {:enum, WAWebProtobufsE2E.ContextInfo.StatusSourceType}},
        trustBannerAction: {38, {:scalar, 0}, :uint32},
        trustBannerType: {37, {:scalar, ""}, :string},
        urlTrackingMap: {58, {:scalar, nil}, {:message, WAWebProtobufsE2E.UrlTrackingMap}},
        utm: {41, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo.UTMInfo}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "stanzaID",
          kind: {:scalar, ""},
          label: :optional,
          name: :stanzaID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "participant",
          kind: {:scalar, ""},
          label: :optional,
          name: :participant,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "quotedMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :quotedMessage,
          tag: 3,
          type: {:message, WAWebProtobufsE2E.Message}
        },
        %{
          __struct__: Protox.Field,
          json_name: "remoteJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :remoteJID,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "mentionedJID",
          kind: :unpacked,
          label: :repeated,
          name: :mentionedJID,
          tag: 15,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "conversionSource",
          kind: {:scalar, ""},
          label: :optional,
          name: :conversionSource,
          tag: 18,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "conversionData",
          kind: {:scalar, ""},
          label: :optional,
          name: :conversionData,
          tag: 19,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "conversionDelaySeconds",
          kind: {:scalar, 0},
          label: :optional,
          name: :conversionDelaySeconds,
          tag: 20,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "forwardingScore",
          kind: {:scalar, 0},
          label: :optional,
          name: :forwardingScore,
          tag: 21,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "isForwarded",
          kind: {:scalar, false},
          label: :optional,
          name: :isForwarded,
          tag: 22,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "quotedAd",
          kind: {:scalar, nil},
          label: :optional,
          name: :quotedAd,
          tag: 23,
          type: {:message, WAWebProtobufsE2E.ContextInfo.AdReplyInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "placeholderKey",
          kind: {:scalar, nil},
          label: :optional,
          name: :placeholderKey,
          tag: 24,
          type: {:message, WACommon.MessageKey}
        },
        %{
          __struct__: Protox.Field,
          json_name: "expiration",
          kind: {:scalar, 0},
          label: :optional,
          name: :expiration,
          tag: 25,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeralSettingTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :ephemeralSettingTimestamp,
          tag: 26,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeralSharedSecret",
          kind: {:scalar, ""},
          label: :optional,
          name: :ephemeralSharedSecret,
          tag: 27,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "externalAdReply",
          kind: {:scalar, nil},
          label: :optional,
          name: :externalAdReply,
          tag: 28,
          type: {:message, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "entryPointConversionSource",
          kind: {:scalar, ""},
          label: :optional,
          name: :entryPointConversionSource,
          tag: 29,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "entryPointConversionApp",
          kind: {:scalar, ""},
          label: :optional,
          name: :entryPointConversionApp,
          tag: 30,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "entryPointConversionDelaySeconds",
          kind: {:scalar, 0},
          label: :optional,
          name: :entryPointConversionDelaySeconds,
          tag: 31,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "disappearingMode",
          kind: {:scalar, nil},
          label: :optional,
          name: :disappearingMode,
          tag: 32,
          type: {:message, WAWebProtobufsE2E.DisappearingMode}
        },
        %{
          __struct__: Protox.Field,
          json_name: "actionLink",
          kind: {:scalar, nil},
          label: :optional,
          name: :actionLink,
          tag: 33,
          type: {:message, WAWebProtobufsE2E.ActionLink}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupSubject",
          kind: {:scalar, ""},
          label: :optional,
          name: :groupSubject,
          tag: 34,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "parentGroupJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :parentGroupJID,
          tag: 35,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "trustBannerType",
          kind: {:scalar, ""},
          label: :optional,
          name: :trustBannerType,
          tag: 37,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "trustBannerAction",
          kind: {:scalar, 0},
          label: :optional,
          name: :trustBannerAction,
          tag: 38,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "isSampled",
          kind: {:scalar, false},
          label: :optional,
          name: :isSampled,
          tag: 39,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupMentions",
          kind: :unpacked,
          label: :repeated,
          name: :groupMentions,
          tag: 40,
          type: {:message, WAWebProtobufsE2E.GroupMention}
        },
        %{
          __struct__: Protox.Field,
          json_name: "utm",
          kind: {:scalar, nil},
          label: :optional,
          name: :utm,
          tag: 41,
          type: {:message, WAWebProtobufsE2E.ContextInfo.UTMInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "forwardedNewsletterMessageInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :forwardedNewsletterMessageInfo,
          tag: 43,
          type: {:message, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "businessMessageForwardInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :businessMessageForwardInfo,
          tag: 44,
          type: {:message, WAWebProtobufsE2E.ContextInfo.BusinessMessageForwardInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "smbClientCampaignID",
          kind: {:scalar, ""},
          label: :optional,
          name: :smbClientCampaignID,
          tag: 45,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "smbServerCampaignID",
          kind: {:scalar, ""},
          label: :optional,
          name: :smbServerCampaignID,
          tag: 46,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "dataSharingContext",
          kind: {:scalar, nil},
          label: :optional,
          name: :dataSharingContext,
          tag: 47,
          type: {:message, WAWebProtobufsE2E.ContextInfo.DataSharingContext}
        },
        %{
          __struct__: Protox.Field,
          json_name: "alwaysShowAdAttribution",
          kind: {:scalar, false},
          label: :optional,
          name: :alwaysShowAdAttribution,
          tag: 48,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "featureEligibilities",
          kind: {:scalar, nil},
          label: :optional,
          name: :featureEligibilities,
          tag: 49,
          type: {:message, WAWebProtobufsE2E.ContextInfo.FeatureEligibilities}
        },
        %{
          __struct__: Protox.Field,
          json_name: "entryPointConversionExternalSource",
          kind: {:scalar, ""},
          label: :optional,
          name: :entryPointConversionExternalSource,
          tag: 50,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "entryPointConversionExternalMedium",
          kind: {:scalar, ""},
          label: :optional,
          name: :entryPointConversionExternalMedium,
          tag: 51,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "ctwaSignals",
          kind: {:scalar, ""},
          label: :optional,
          name: :ctwaSignals,
          tag: 54,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "ctwaPayload",
          kind: {:scalar, ""},
          label: :optional,
          name: :ctwaPayload,
          tag: 55,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "forwardedAiBotMessageInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :forwardedAiBotMessageInfo,
          tag: 56,
          type: {:message, WAWebProtobufsAICommon.ForwardedAIBotMessageInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusAttributionType",
          kind: {:scalar, :NONE},
          label: :optional,
          name: :statusAttributionType,
          tag: 57,
          type: {:enum, WAWebProtobufsE2E.ContextInfo.StatusAttributionType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "urlTrackingMap",
          kind: {:scalar, nil},
          label: :optional,
          name: :urlTrackingMap,
          tag: 58,
          type: {:message, WAWebProtobufsE2E.UrlTrackingMap}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pairedMediaType",
          kind: {:scalar, :NOT_PAIRED_MEDIA},
          label: :optional,
          name: :pairedMediaType,
          tag: 59,
          type: {:enum, WAWebProtobufsE2E.ContextInfo.PairedMediaType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "rankingVersion",
          kind: {:scalar, 0},
          label: :optional,
          name: :rankingVersion,
          tag: 60,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "memberLabel",
          kind: {:scalar, nil},
          label: :optional,
          name: :memberLabel,
          tag: 62,
          type: {:message, WAWebProtobufsE2E.MemberLabel}
        },
        %{
          __struct__: Protox.Field,
          json_name: "isQuestion",
          kind: {:scalar, false},
          label: :optional,
          name: :isQuestion,
          tag: 63,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusSourceType",
          kind: {:scalar, :IMAGE},
          label: :optional,
          name: :statusSourceType,
          tag: 64,
          type: {:enum, WAWebProtobufsE2E.ContextInfo.StatusSourceType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusAttributions",
          kind: :unpacked,
          label: :repeated,
          name: :statusAttributions,
          tag: 65,
          type: {:message, WAStatusAttributions.StatusAttribution}
        },
        %{
          __struct__: Protox.Field,
          json_name: "isGroupStatus",
          kind: {:scalar, false},
          label: :optional,
          name: :isGroupStatus,
          tag: 66,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "forwardOrigin",
          kind: {:scalar, :UNKNOWN},
          label: :optional,
          name: :forwardOrigin,
          tag: 67,
          type: {:enum, WAWebProtobufsE2E.ContextInfo.ForwardOrigin}
        },
        %{
          __struct__: Protox.Field,
          json_name: "questionReplyQuotedMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :questionReplyQuotedMessage,
          tag: 68,
          type: {:message, WAWebProtobufsE2E.ContextInfo.QuestionReplyQuotedMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusAudienceMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :statusAudienceMetadata,
          tag: 69,
          type: {:message, WAWebProtobufsE2E.ContextInfo.StatusAudienceMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "nonJIDMentions",
          kind: {:scalar, 0},
          label: :optional,
          name: :nonJIDMentions,
          tag: 70,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "quotedType",
          kind: {:scalar, :EXPLICIT},
          label: :optional,
          name: :quotedType,
          tag: 71,
          type: {:enum, WAWebProtobufsE2E.ContextInfo.QuotedType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botMessageSharingInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :botMessageSharingInfo,
          tag: 72,
          type: {:message, WAWebProtobufsAICommon.BotMessageSharingInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "isSpoiler",
          kind: {:scalar, false},
          label: :optional,
          name: :isSpoiler,
          tag: 73,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaDomainInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :mediaDomainInfo,
          tag: 74,
          type: {:message, WAWebProtobufsE2E.MediaDomainInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "partiallySelectedContent",
          kind: {:scalar, nil},
          label: :optional,
          name: :partiallySelectedContent,
          tag: 75,
          type: {:message, WAWebProtobufsE2E.ContextInfo.PartiallySelectedContent}
        },
        %{
          __struct__: Protox.Field,
          json_name: "afterReadDuration",
          kind: {:scalar, 0},
          label: :optional,
          name: :afterReadDuration,
          tag: 76,
          type: :uint32
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:stanzaID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stanzaID",
             kind: {:scalar, ""},
             label: :optional,
             name: :stanzaID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("stanzaID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stanzaID",
             kind: {:scalar, ""},
             label: :optional,
             name: :stanzaID,
             tag: 1,
             type: :string
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
             tag: 2,
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
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:quotedMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quotedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :quotedMessage,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.Message}
           }}
        end

        def field_def("quotedMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quotedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :quotedMessage,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.Message}
           }}
        end

        []
      ),
      (
        def field_def(:remoteJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "remoteJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :remoteJID,
             tag: 4,
             type: :string
           }}
        end

        def field_def("remoteJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "remoteJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :remoteJID,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:mentionedJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mentionedJID",
             kind: :unpacked,
             label: :repeated,
             name: :mentionedJID,
             tag: 15,
             type: :string
           }}
        end

        def field_def("mentionedJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mentionedJID",
             kind: :unpacked,
             label: :repeated,
             name: :mentionedJID,
             tag: 15,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:conversionSource) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversionSource",
             kind: {:scalar, ""},
             label: :optional,
             name: :conversionSource,
             tag: 18,
             type: :string
           }}
        end

        def field_def("conversionSource") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversionSource",
             kind: {:scalar, ""},
             label: :optional,
             name: :conversionSource,
             tag: 18,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:conversionData) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversionData",
             kind: {:scalar, ""},
             label: :optional,
             name: :conversionData,
             tag: 19,
             type: :bytes
           }}
        end

        def field_def("conversionData") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversionData",
             kind: {:scalar, ""},
             label: :optional,
             name: :conversionData,
             tag: 19,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:conversionDelaySeconds) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversionDelaySeconds",
             kind: {:scalar, 0},
             label: :optional,
             name: :conversionDelaySeconds,
             tag: 20,
             type: :uint32
           }}
        end

        def field_def("conversionDelaySeconds") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversionDelaySeconds",
             kind: {:scalar, 0},
             label: :optional,
             name: :conversionDelaySeconds,
             tag: 20,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:forwardingScore) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "forwardingScore",
             kind: {:scalar, 0},
             label: :optional,
             name: :forwardingScore,
             tag: 21,
             type: :uint32
           }}
        end

        def field_def("forwardingScore") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "forwardingScore",
             kind: {:scalar, 0},
             label: :optional,
             name: :forwardingScore,
             tag: 21,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:isForwarded) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isForwarded",
             kind: {:scalar, false},
             label: :optional,
             name: :isForwarded,
             tag: 22,
             type: :bool
           }}
        end

        def field_def("isForwarded") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isForwarded",
             kind: {:scalar, false},
             label: :optional,
             name: :isForwarded,
             tag: 22,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:quotedAd) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quotedAd",
             kind: {:scalar, nil},
             label: :optional,
             name: :quotedAd,
             tag: 23,
             type: {:message, WAWebProtobufsE2E.ContextInfo.AdReplyInfo}
           }}
        end

        def field_def("quotedAd") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quotedAd",
             kind: {:scalar, nil},
             label: :optional,
             name: :quotedAd,
             tag: 23,
             type: {:message, WAWebProtobufsE2E.ContextInfo.AdReplyInfo}
           }}
        end

        []
      ),
      (
        def field_def(:placeholderKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "placeholderKey",
             kind: {:scalar, nil},
             label: :optional,
             name: :placeholderKey,
             tag: 24,
             type: {:message, WACommon.MessageKey}
           }}
        end

        def field_def("placeholderKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "placeholderKey",
             kind: {:scalar, nil},
             label: :optional,
             name: :placeholderKey,
             tag: 24,
             type: {:message, WACommon.MessageKey}
           }}
        end

        []
      ),
      (
        def field_def(:expiration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "expiration",
             kind: {:scalar, 0},
             label: :optional,
             name: :expiration,
             tag: 25,
             type: :uint32
           }}
        end

        def field_def("expiration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "expiration",
             kind: {:scalar, 0},
             label: :optional,
             name: :expiration,
             tag: 25,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:ephemeralSettingTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralSettingTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :ephemeralSettingTimestamp,
             tag: 26,
             type: :int64
           }}
        end

        def field_def("ephemeralSettingTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralSettingTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :ephemeralSettingTimestamp,
             tag: 26,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:ephemeralSharedSecret) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralSharedSecret",
             kind: {:scalar, ""},
             label: :optional,
             name: :ephemeralSharedSecret,
             tag: 27,
             type: :bytes
           }}
        end

        def field_def("ephemeralSharedSecret") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralSharedSecret",
             kind: {:scalar, ""},
             label: :optional,
             name: :ephemeralSharedSecret,
             tag: 27,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:externalAdReply) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "externalAdReply",
             kind: {:scalar, nil},
             label: :optional,
             name: :externalAdReply,
             tag: 28,
             type: {:message, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo}
           }}
        end

        def field_def("externalAdReply") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "externalAdReply",
             kind: {:scalar, nil},
             label: :optional,
             name: :externalAdReply,
             tag: 28,
             type: {:message, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo}
           }}
        end

        []
      ),
      (
        def field_def(:entryPointConversionSource) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "entryPointConversionSource",
             kind: {:scalar, ""},
             label: :optional,
             name: :entryPointConversionSource,
             tag: 29,
             type: :string
           }}
        end

        def field_def("entryPointConversionSource") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "entryPointConversionSource",
             kind: {:scalar, ""},
             label: :optional,
             name: :entryPointConversionSource,
             tag: 29,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:entryPointConversionApp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "entryPointConversionApp",
             kind: {:scalar, ""},
             label: :optional,
             name: :entryPointConversionApp,
             tag: 30,
             type: :string
           }}
        end

        def field_def("entryPointConversionApp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "entryPointConversionApp",
             kind: {:scalar, ""},
             label: :optional,
             name: :entryPointConversionApp,
             tag: 30,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:entryPointConversionDelaySeconds) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "entryPointConversionDelaySeconds",
             kind: {:scalar, 0},
             label: :optional,
             name: :entryPointConversionDelaySeconds,
             tag: 31,
             type: :uint32
           }}
        end

        def field_def("entryPointConversionDelaySeconds") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "entryPointConversionDelaySeconds",
             kind: {:scalar, 0},
             label: :optional,
             name: :entryPointConversionDelaySeconds,
             tag: 31,
             type: :uint32
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
             kind: {:scalar, nil},
             label: :optional,
             name: :disappearingMode,
             tag: 32,
             type: {:message, WAWebProtobufsE2E.DisappearingMode}
           }}
        end

        def field_def("disappearingMode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "disappearingMode",
             kind: {:scalar, nil},
             label: :optional,
             name: :disappearingMode,
             tag: 32,
             type: {:message, WAWebProtobufsE2E.DisappearingMode}
           }}
        end

        []
      ),
      (
        def field_def(:actionLink) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "actionLink",
             kind: {:scalar, nil},
             label: :optional,
             name: :actionLink,
             tag: 33,
             type: {:message, WAWebProtobufsE2E.ActionLink}
           }}
        end

        def field_def("actionLink") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "actionLink",
             kind: {:scalar, nil},
             label: :optional,
             name: :actionLink,
             tag: 33,
             type: {:message, WAWebProtobufsE2E.ActionLink}
           }}
        end

        []
      ),
      (
        def field_def(:groupSubject) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupSubject",
             kind: {:scalar, ""},
             label: :optional,
             name: :groupSubject,
             tag: 34,
             type: :string
           }}
        end

        def field_def("groupSubject") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupSubject",
             kind: {:scalar, ""},
             label: :optional,
             name: :groupSubject,
             tag: 34,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:parentGroupJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "parentGroupJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :parentGroupJID,
             tag: 35,
             type: :string
           }}
        end

        def field_def("parentGroupJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "parentGroupJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :parentGroupJID,
             tag: 35,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:trustBannerType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "trustBannerType",
             kind: {:scalar, ""},
             label: :optional,
             name: :trustBannerType,
             tag: 37,
             type: :string
           }}
        end

        def field_def("trustBannerType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "trustBannerType",
             kind: {:scalar, ""},
             label: :optional,
             name: :trustBannerType,
             tag: 37,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:trustBannerAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "trustBannerAction",
             kind: {:scalar, 0},
             label: :optional,
             name: :trustBannerAction,
             tag: 38,
             type: :uint32
           }}
        end

        def field_def("trustBannerAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "trustBannerAction",
             kind: {:scalar, 0},
             label: :optional,
             name: :trustBannerAction,
             tag: 38,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:isSampled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSampled",
             kind: {:scalar, false},
             label: :optional,
             name: :isSampled,
             tag: 39,
             type: :bool
           }}
        end

        def field_def("isSampled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSampled",
             kind: {:scalar, false},
             label: :optional,
             name: :isSampled,
             tag: 39,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:groupMentions) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupMentions",
             kind: :unpacked,
             label: :repeated,
             name: :groupMentions,
             tag: 40,
             type: {:message, WAWebProtobufsE2E.GroupMention}
           }}
        end

        def field_def("groupMentions") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupMentions",
             kind: :unpacked,
             label: :repeated,
             name: :groupMentions,
             tag: 40,
             type: {:message, WAWebProtobufsE2E.GroupMention}
           }}
        end

        []
      ),
      (
        def field_def(:utm) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "utm",
             kind: {:scalar, nil},
             label: :optional,
             name: :utm,
             tag: 41,
             type: {:message, WAWebProtobufsE2E.ContextInfo.UTMInfo}
           }}
        end

        def field_def("utm") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "utm",
             kind: {:scalar, nil},
             label: :optional,
             name: :utm,
             tag: 41,
             type: {:message, WAWebProtobufsE2E.ContextInfo.UTMInfo}
           }}
        end

        []
      ),
      (
        def field_def(:forwardedNewsletterMessageInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "forwardedNewsletterMessageInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :forwardedNewsletterMessageInfo,
             tag: 43,
             type: {:message, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo}
           }}
        end

        def field_def("forwardedNewsletterMessageInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "forwardedNewsletterMessageInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :forwardedNewsletterMessageInfo,
             tag: 43,
             type: {:message, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo}
           }}
        end

        []
      ),
      (
        def field_def(:businessMessageForwardInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "businessMessageForwardInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :businessMessageForwardInfo,
             tag: 44,
             type: {:message, WAWebProtobufsE2E.ContextInfo.BusinessMessageForwardInfo}
           }}
        end

        def field_def("businessMessageForwardInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "businessMessageForwardInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :businessMessageForwardInfo,
             tag: 44,
             type: {:message, WAWebProtobufsE2E.ContextInfo.BusinessMessageForwardInfo}
           }}
        end

        []
      ),
      (
        def field_def(:smbClientCampaignID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "smbClientCampaignID",
             kind: {:scalar, ""},
             label: :optional,
             name: :smbClientCampaignID,
             tag: 45,
             type: :string
           }}
        end

        def field_def("smbClientCampaignID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "smbClientCampaignID",
             kind: {:scalar, ""},
             label: :optional,
             name: :smbClientCampaignID,
             tag: 45,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:smbServerCampaignID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "smbServerCampaignID",
             kind: {:scalar, ""},
             label: :optional,
             name: :smbServerCampaignID,
             tag: 46,
             type: :string
           }}
        end

        def field_def("smbServerCampaignID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "smbServerCampaignID",
             kind: {:scalar, ""},
             label: :optional,
             name: :smbServerCampaignID,
             tag: 46,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:dataSharingContext) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "dataSharingContext",
             kind: {:scalar, nil},
             label: :optional,
             name: :dataSharingContext,
             tag: 47,
             type: {:message, WAWebProtobufsE2E.ContextInfo.DataSharingContext}
           }}
        end

        def field_def("dataSharingContext") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "dataSharingContext",
             kind: {:scalar, nil},
             label: :optional,
             name: :dataSharingContext,
             tag: 47,
             type: {:message, WAWebProtobufsE2E.ContextInfo.DataSharingContext}
           }}
        end

        []
      ),
      (
        def field_def(:alwaysShowAdAttribution) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "alwaysShowAdAttribution",
             kind: {:scalar, false},
             label: :optional,
             name: :alwaysShowAdAttribution,
             tag: 48,
             type: :bool
           }}
        end

        def field_def("alwaysShowAdAttribution") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "alwaysShowAdAttribution",
             kind: {:scalar, false},
             label: :optional,
             name: :alwaysShowAdAttribution,
             tag: 48,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:featureEligibilities) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "featureEligibilities",
             kind: {:scalar, nil},
             label: :optional,
             name: :featureEligibilities,
             tag: 49,
             type: {:message, WAWebProtobufsE2E.ContextInfo.FeatureEligibilities}
           }}
        end

        def field_def("featureEligibilities") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "featureEligibilities",
             kind: {:scalar, nil},
             label: :optional,
             name: :featureEligibilities,
             tag: 49,
             type: {:message, WAWebProtobufsE2E.ContextInfo.FeatureEligibilities}
           }}
        end

        []
      ),
      (
        def field_def(:entryPointConversionExternalSource) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "entryPointConversionExternalSource",
             kind: {:scalar, ""},
             label: :optional,
             name: :entryPointConversionExternalSource,
             tag: 50,
             type: :string
           }}
        end

        def field_def("entryPointConversionExternalSource") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "entryPointConversionExternalSource",
             kind: {:scalar, ""},
             label: :optional,
             name: :entryPointConversionExternalSource,
             tag: 50,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:entryPointConversionExternalMedium) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "entryPointConversionExternalMedium",
             kind: {:scalar, ""},
             label: :optional,
             name: :entryPointConversionExternalMedium,
             tag: 51,
             type: :string
           }}
        end

        def field_def("entryPointConversionExternalMedium") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "entryPointConversionExternalMedium",
             kind: {:scalar, ""},
             label: :optional,
             name: :entryPointConversionExternalMedium,
             tag: 51,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:ctwaSignals) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctwaSignals",
             kind: {:scalar, ""},
             label: :optional,
             name: :ctwaSignals,
             tag: 54,
             type: :string
           }}
        end

        def field_def("ctwaSignals") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctwaSignals",
             kind: {:scalar, ""},
             label: :optional,
             name: :ctwaSignals,
             tag: 54,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:ctwaPayload) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctwaPayload",
             kind: {:scalar, ""},
             label: :optional,
             name: :ctwaPayload,
             tag: 55,
             type: :bytes
           }}
        end

        def field_def("ctwaPayload") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctwaPayload",
             kind: {:scalar, ""},
             label: :optional,
             name: :ctwaPayload,
             tag: 55,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:forwardedAiBotMessageInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "forwardedAiBotMessageInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :forwardedAiBotMessageInfo,
             tag: 56,
             type: {:message, WAWebProtobufsAICommon.ForwardedAIBotMessageInfo}
           }}
        end

        def field_def("forwardedAiBotMessageInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "forwardedAiBotMessageInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :forwardedAiBotMessageInfo,
             tag: 56,
             type: {:message, WAWebProtobufsAICommon.ForwardedAIBotMessageInfo}
           }}
        end

        []
      ),
      (
        def field_def(:statusAttributionType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusAttributionType",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :statusAttributionType,
             tag: 57,
             type: {:enum, WAWebProtobufsE2E.ContextInfo.StatusAttributionType}
           }}
        end

        def field_def("statusAttributionType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusAttributionType",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :statusAttributionType,
             tag: 57,
             type: {:enum, WAWebProtobufsE2E.ContextInfo.StatusAttributionType}
           }}
        end

        []
      ),
      (
        def field_def(:urlTrackingMap) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "urlTrackingMap",
             kind: {:scalar, nil},
             label: :optional,
             name: :urlTrackingMap,
             tag: 58,
             type: {:message, WAWebProtobufsE2E.UrlTrackingMap}
           }}
        end

        def field_def("urlTrackingMap") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "urlTrackingMap",
             kind: {:scalar, nil},
             label: :optional,
             name: :urlTrackingMap,
             tag: 58,
             type: {:message, WAWebProtobufsE2E.UrlTrackingMap}
           }}
        end

        []
      ),
      (
        def field_def(:pairedMediaType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pairedMediaType",
             kind: {:scalar, :NOT_PAIRED_MEDIA},
             label: :optional,
             name: :pairedMediaType,
             tag: 59,
             type: {:enum, WAWebProtobufsE2E.ContextInfo.PairedMediaType}
           }}
        end

        def field_def("pairedMediaType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pairedMediaType",
             kind: {:scalar, :NOT_PAIRED_MEDIA},
             label: :optional,
             name: :pairedMediaType,
             tag: 59,
             type: {:enum, WAWebProtobufsE2E.ContextInfo.PairedMediaType}
           }}
        end

        []
      ),
      (
        def field_def(:rankingVersion) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "rankingVersion",
             kind: {:scalar, 0},
             label: :optional,
             name: :rankingVersion,
             tag: 60,
             type: :uint32
           }}
        end

        def field_def("rankingVersion") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "rankingVersion",
             kind: {:scalar, 0},
             label: :optional,
             name: :rankingVersion,
             tag: 60,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:memberLabel) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "memberLabel",
             kind: {:scalar, nil},
             label: :optional,
             name: :memberLabel,
             tag: 62,
             type: {:message, WAWebProtobufsE2E.MemberLabel}
           }}
        end

        def field_def("memberLabel") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "memberLabel",
             kind: {:scalar, nil},
             label: :optional,
             name: :memberLabel,
             tag: 62,
             type: {:message, WAWebProtobufsE2E.MemberLabel}
           }}
        end

        []
      ),
      (
        def field_def(:isQuestion) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isQuestion",
             kind: {:scalar, false},
             label: :optional,
             name: :isQuestion,
             tag: 63,
             type: :bool
           }}
        end

        def field_def("isQuestion") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isQuestion",
             kind: {:scalar, false},
             label: :optional,
             name: :isQuestion,
             tag: 63,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:statusSourceType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusSourceType",
             kind: {:scalar, :IMAGE},
             label: :optional,
             name: :statusSourceType,
             tag: 64,
             type: {:enum, WAWebProtobufsE2E.ContextInfo.StatusSourceType}
           }}
        end

        def field_def("statusSourceType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusSourceType",
             kind: {:scalar, :IMAGE},
             label: :optional,
             name: :statusSourceType,
             tag: 64,
             type: {:enum, WAWebProtobufsE2E.ContextInfo.StatusSourceType}
           }}
        end

        []
      ),
      (
        def field_def(:statusAttributions) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusAttributions",
             kind: :unpacked,
             label: :repeated,
             name: :statusAttributions,
             tag: 65,
             type: {:message, WAStatusAttributions.StatusAttribution}
           }}
        end

        def field_def("statusAttributions") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusAttributions",
             kind: :unpacked,
             label: :repeated,
             name: :statusAttributions,
             tag: 65,
             type: {:message, WAStatusAttributions.StatusAttribution}
           }}
        end

        []
      ),
      (
        def field_def(:isGroupStatus) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isGroupStatus",
             kind: {:scalar, false},
             label: :optional,
             name: :isGroupStatus,
             tag: 66,
             type: :bool
           }}
        end

        def field_def("isGroupStatus") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isGroupStatus",
             kind: {:scalar, false},
             label: :optional,
             name: :isGroupStatus,
             tag: 66,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:forwardOrigin) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "forwardOrigin",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :forwardOrigin,
             tag: 67,
             type: {:enum, WAWebProtobufsE2E.ContextInfo.ForwardOrigin}
           }}
        end

        def field_def("forwardOrigin") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "forwardOrigin",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :forwardOrigin,
             tag: 67,
             type: {:enum, WAWebProtobufsE2E.ContextInfo.ForwardOrigin}
           }}
        end

        []
      ),
      (
        def field_def(:questionReplyQuotedMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "questionReplyQuotedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :questionReplyQuotedMessage,
             tag: 68,
             type: {:message, WAWebProtobufsE2E.ContextInfo.QuestionReplyQuotedMessage}
           }}
        end

        def field_def("questionReplyQuotedMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "questionReplyQuotedMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :questionReplyQuotedMessage,
             tag: 68,
             type: {:message, WAWebProtobufsE2E.ContextInfo.QuestionReplyQuotedMessage}
           }}
        end

        []
      ),
      (
        def field_def(:statusAudienceMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusAudienceMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusAudienceMetadata,
             tag: 69,
             type: {:message, WAWebProtobufsE2E.ContextInfo.StatusAudienceMetadata}
           }}
        end

        def field_def("statusAudienceMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusAudienceMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :statusAudienceMetadata,
             tag: 69,
             type: {:message, WAWebProtobufsE2E.ContextInfo.StatusAudienceMetadata}
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
             tag: 70,
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
             tag: 70,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:quotedType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quotedType",
             kind: {:scalar, :EXPLICIT},
             label: :optional,
             name: :quotedType,
             tag: 71,
             type: {:enum, WAWebProtobufsE2E.ContextInfo.QuotedType}
           }}
        end

        def field_def("quotedType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quotedType",
             kind: {:scalar, :EXPLICIT},
             label: :optional,
             name: :quotedType,
             tag: 71,
             type: {:enum, WAWebProtobufsE2E.ContextInfo.QuotedType}
           }}
        end

        []
      ),
      (
        def field_def(:botMessageSharingInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botMessageSharingInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :botMessageSharingInfo,
             tag: 72,
             type: {:message, WAWebProtobufsAICommon.BotMessageSharingInfo}
           }}
        end

        def field_def("botMessageSharingInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botMessageSharingInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :botMessageSharingInfo,
             tag: 72,
             type: {:message, WAWebProtobufsAICommon.BotMessageSharingInfo}
           }}
        end

        []
      ),
      (
        def field_def(:isSpoiler) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSpoiler",
             kind: {:scalar, false},
             label: :optional,
             name: :isSpoiler,
             tag: 73,
             type: :bool
           }}
        end

        def field_def("isSpoiler") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSpoiler",
             kind: {:scalar, false},
             label: :optional,
             name: :isSpoiler,
             tag: 73,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:mediaDomainInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaDomainInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :mediaDomainInfo,
             tag: 74,
             type: {:message, WAWebProtobufsE2E.MediaDomainInfo}
           }}
        end

        def field_def("mediaDomainInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaDomainInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :mediaDomainInfo,
             tag: 74,
             type: {:message, WAWebProtobufsE2E.MediaDomainInfo}
           }}
        end

        []
      ),
      (
        def field_def(:partiallySelectedContent) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "partiallySelectedContent",
             kind: {:scalar, nil},
             label: :optional,
             name: :partiallySelectedContent,
             tag: 75,
             type: {:message, WAWebProtobufsE2E.ContextInfo.PartiallySelectedContent}
           }}
        end

        def field_def("partiallySelectedContent") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "partiallySelectedContent",
             kind: {:scalar, nil},
             label: :optional,
             name: :partiallySelectedContent,
             tag: 75,
             type: {:message, WAWebProtobufsE2E.ContextInfo.PartiallySelectedContent}
           }}
        end

        []
      ),
      (
        def field_def(:afterReadDuration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "afterReadDuration",
             kind: {:scalar, 0},
             label: :optional,
             name: :afterReadDuration,
             tag: 76,
             type: :uint32
           }}
        end

        def field_def("afterReadDuration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "afterReadDuration",
             kind: {:scalar, 0},
             label: :optional,
             name: :afterReadDuration,
             tag: 76,
             type: :uint32
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
    def default(:stanzaID) do
      {:ok, ""}
    end,
    def default(:participant) do
      {:ok, ""}
    end,
    def default(:quotedMessage) do
      {:ok, nil}
    end,
    def default(:remoteJID) do
      {:ok, ""}
    end,
    def default(:mentionedJID) do
      {:error, :no_default_value}
    end,
    def default(:conversionSource) do
      {:ok, ""}
    end,
    def default(:conversionData) do
      {:ok, ""}
    end,
    def default(:conversionDelaySeconds) do
      {:ok, 0}
    end,
    def default(:forwardingScore) do
      {:ok, 0}
    end,
    def default(:isForwarded) do
      {:ok, false}
    end,
    def default(:quotedAd) do
      {:ok, nil}
    end,
    def default(:placeholderKey) do
      {:ok, nil}
    end,
    def default(:expiration) do
      {:ok, 0}
    end,
    def default(:ephemeralSettingTimestamp) do
      {:ok, 0}
    end,
    def default(:ephemeralSharedSecret) do
      {:ok, ""}
    end,
    def default(:externalAdReply) do
      {:ok, nil}
    end,
    def default(:entryPointConversionSource) do
      {:ok, ""}
    end,
    def default(:entryPointConversionApp) do
      {:ok, ""}
    end,
    def default(:entryPointConversionDelaySeconds) do
      {:ok, 0}
    end,
    def default(:disappearingMode) do
      {:ok, nil}
    end,
    def default(:actionLink) do
      {:ok, nil}
    end,
    def default(:groupSubject) do
      {:ok, ""}
    end,
    def default(:parentGroupJID) do
      {:ok, ""}
    end,
    def default(:trustBannerType) do
      {:ok, ""}
    end,
    def default(:trustBannerAction) do
      {:ok, 0}
    end,
    def default(:isSampled) do
      {:ok, false}
    end,
    def default(:groupMentions) do
      {:error, :no_default_value}
    end,
    def default(:utm) do
      {:ok, nil}
    end,
    def default(:forwardedNewsletterMessageInfo) do
      {:ok, nil}
    end,
    def default(:businessMessageForwardInfo) do
      {:ok, nil}
    end,
    def default(:smbClientCampaignID) do
      {:ok, ""}
    end,
    def default(:smbServerCampaignID) do
      {:ok, ""}
    end,
    def default(:dataSharingContext) do
      {:ok, nil}
    end,
    def default(:alwaysShowAdAttribution) do
      {:ok, false}
    end,
    def default(:featureEligibilities) do
      {:ok, nil}
    end,
    def default(:entryPointConversionExternalSource) do
      {:ok, ""}
    end,
    def default(:entryPointConversionExternalMedium) do
      {:ok, ""}
    end,
    def default(:ctwaSignals) do
      {:ok, ""}
    end,
    def default(:ctwaPayload) do
      {:ok, ""}
    end,
    def default(:forwardedAiBotMessageInfo) do
      {:ok, nil}
    end,
    def default(:statusAttributionType) do
      {:ok, :NONE}
    end,
    def default(:urlTrackingMap) do
      {:ok, nil}
    end,
    def default(:pairedMediaType) do
      {:ok, :NOT_PAIRED_MEDIA}
    end,
    def default(:rankingVersion) do
      {:ok, 0}
    end,
    def default(:memberLabel) do
      {:ok, nil}
    end,
    def default(:isQuestion) do
      {:ok, false}
    end,
    def default(:statusSourceType) do
      {:ok, :IMAGE}
    end,
    def default(:statusAttributions) do
      {:error, :no_default_value}
    end,
    def default(:isGroupStatus) do
      {:ok, false}
    end,
    def default(:forwardOrigin) do
      {:ok, :UNKNOWN}
    end,
    def default(:questionReplyQuotedMessage) do
      {:ok, nil}
    end,
    def default(:statusAudienceMetadata) do
      {:ok, nil}
    end,
    def default(:nonJIDMentions) do
      {:ok, 0}
    end,
    def default(:quotedType) do
      {:ok, :EXPLICIT}
    end,
    def default(:botMessageSharingInfo) do
      {:ok, nil}
    end,
    def default(:isSpoiler) do
      {:ok, false}
    end,
    def default(:mediaDomainInfo) do
      {:ok, nil}
    end,
    def default(:partiallySelectedContent) do
      {:ok, nil}
    end,
    def default(:afterReadDuration) do
      {:ok, 0}
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
