# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotMetadata do
  @moduledoc false
  defstruct personaID: nil,
            pluginMetadata: nil,
            suggestedPromptMetadata: nil,
            invokerJID: nil,
            sessionMetadata: nil,
            memuMetadata: nil,
            timezone: nil,
            reminderMetadata: nil,
            modelMetadata: nil,
            messageDisclaimerText: nil,
            progressIndicatorMetadata: nil,
            capabilityMetadata: nil,
            imagineMetadata: nil,
            memoryMetadata: nil,
            renderingMetadata: nil,
            botMetricsMetadata: nil,
            botLinkedAccountsMetadata: nil,
            richResponseSourcesMetadata: nil,
            aiConversationContext: nil,
            botPromotionMessageMetadata: nil,
            botModeSelectionMetadata: nil,
            botQuotaMetadata: nil,
            botAgeCollectionMetadata: nil,
            conversationStarterPromptID: nil,
            botResponseID: nil,
            verificationMetadata: nil,
            unifiedResponseMutation: nil,
            botMessageOriginMetadata: nil,
            inThreadSurveyMetadata: nil,
            botThreadInfo: nil,
            regenerateMetadata: nil,
            sessionTransparencyMetadata: nil,
            botDocumentMessageMetadata: nil,
            botGroupMetadata: nil,
            botRenderingConfigMetadata: nil,
            botInfrastructureDiagnostics: nil,
            aiMediaCollectionMetadata: nil,
            commandMetadata: nil,
            resolvedToolCallMetadata: nil,
            subscriptionUpsellMetadata: nil,
            pttPromptMetadata: nil,
            botHistoryShareMetadata: nil,
            responseStoppedByUser: nil,
            internalMetadata: nil,
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
        |> encode_personaID(msg)
        |> encode_pluginMetadata(msg)
        |> encode_suggestedPromptMetadata(msg)
        |> encode_invokerJID(msg)
        |> encode_sessionMetadata(msg)
        |> encode_memuMetadata(msg)
        |> encode_timezone(msg)
        |> encode_reminderMetadata(msg)
        |> encode_modelMetadata(msg)
        |> encode_messageDisclaimerText(msg)
        |> encode_progressIndicatorMetadata(msg)
        |> encode_capabilityMetadata(msg)
        |> encode_imagineMetadata(msg)
        |> encode_memoryMetadata(msg)
        |> encode_renderingMetadata(msg)
        |> encode_botMetricsMetadata(msg)
        |> encode_botLinkedAccountsMetadata(msg)
        |> encode_richResponseSourcesMetadata(msg)
        |> encode_aiConversationContext(msg)
        |> encode_botPromotionMessageMetadata(msg)
        |> encode_botModeSelectionMetadata(msg)
        |> encode_botQuotaMetadata(msg)
        |> encode_botAgeCollectionMetadata(msg)
        |> encode_conversationStarterPromptID(msg)
        |> encode_botResponseID(msg)
        |> encode_verificationMetadata(msg)
        |> encode_unifiedResponseMutation(msg)
        |> encode_botMessageOriginMetadata(msg)
        |> encode_inThreadSurveyMetadata(msg)
        |> encode_botThreadInfo(msg)
        |> encode_regenerateMetadata(msg)
        |> encode_sessionTransparencyMetadata(msg)
        |> encode_botDocumentMessageMetadata(msg)
        |> encode_botGroupMetadata(msg)
        |> encode_botRenderingConfigMetadata(msg)
        |> encode_botInfrastructureDiagnostics(msg)
        |> encode_aiMediaCollectionMetadata(msg)
        |> encode_commandMetadata(msg)
        |> encode_resolvedToolCallMetadata(msg)
        |> encode_subscriptionUpsellMetadata(msg)
        |> encode_pttPromptMetadata(msg)
        |> encode_botHistoryShareMetadata(msg)
        |> encode_responseStoppedByUser(msg)
        |> encode_internalMetadata(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_personaID(acc, msg) do
        try do
          case msg.personaID do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.personaID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:personaID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pluginMetadata(acc, msg) do
        try do
          case msg.pluginMetadata do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_message(msg.pluginMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pluginMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_suggestedPromptMetadata(acc, msg) do
        try do
          case msg.suggestedPromptMetadata do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_message(msg.suggestedPromptMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:suggestedPromptMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_invokerJID(acc, msg) do
        try do
          case msg.invokerJID do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.invokerJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:invokerJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_sessionMetadata(acc, msg) do
        try do
          case msg.sessionMetadata do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_message(msg.sessionMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:sessionMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_memuMetadata(acc, msg) do
        try do
          case msg.memuMetadata do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_message(msg.memuMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:memuMetadata, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_timezone(acc, msg) do
        try do
          case msg.timezone do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_string(msg.timezone)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:timezone, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_reminderMetadata(acc, msg) do
        try do
          case msg.reminderMetadata do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_message(msg.reminderMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:reminderMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_modelMetadata(acc, msg) do
        try do
          case msg.modelMetadata do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_message(msg.modelMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:modelMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messageDisclaimerText(acc, msg) do
        try do
          case msg.messageDisclaimerText do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_string(msg.messageDisclaimerText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageDisclaimerText, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_progressIndicatorMetadata(acc, msg) do
        try do
          case msg.progressIndicatorMetadata do
            nil -> acc
            _ -> [acc, "b", Protox.Encode.encode_message(msg.progressIndicatorMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:progressIndicatorMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_capabilityMetadata(acc, msg) do
        try do
          case msg.capabilityMetadata do
            nil -> acc
            _ -> [acc, "j", Protox.Encode.encode_message(msg.capabilityMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:capabilityMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_imagineMetadata(acc, msg) do
        try do
          case msg.imagineMetadata do
            nil -> acc
            _ -> [acc, "r", Protox.Encode.encode_message(msg.imagineMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:imagineMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_memoryMetadata(acc, msg) do
        try do
          case msg.memoryMetadata do
            nil -> acc
            _ -> [acc, "z", Protox.Encode.encode_message(msg.memoryMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:memoryMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_renderingMetadata(acc, msg) do
        try do
          case msg.renderingMetadata do
            nil -> acc
            _ -> [acc, "\x82\x01", Protox.Encode.encode_message(msg.renderingMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:renderingMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botMetricsMetadata(acc, msg) do
        try do
          case msg.botMetricsMetadata do
            nil -> acc
            _ -> [acc, "\x8A\x01", Protox.Encode.encode_message(msg.botMetricsMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botMetricsMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botLinkedAccountsMetadata(acc, msg) do
        try do
          case msg.botLinkedAccountsMetadata do
            nil -> acc
            _ -> [acc, "\x92\x01", Protox.Encode.encode_message(msg.botLinkedAccountsMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botLinkedAccountsMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_richResponseSourcesMetadata(acc, msg) do
        try do
          case msg.richResponseSourcesMetadata do
            nil -> acc
            _ -> [acc, "\x9A\x01", Protox.Encode.encode_message(msg.richResponseSourcesMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:richResponseSourcesMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_aiConversationContext(acc, msg) do
        try do
          case msg.aiConversationContext do
            nil -> acc
            _ -> [acc, "\xA2\x01", Protox.Encode.encode_bytes(msg.aiConversationContext)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:aiConversationContext, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botPromotionMessageMetadata(acc, msg) do
        try do
          case msg.botPromotionMessageMetadata do
            nil -> acc
            _ -> [acc, "\xAA\x01", Protox.Encode.encode_message(msg.botPromotionMessageMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botPromotionMessageMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botModeSelectionMetadata(acc, msg) do
        try do
          case msg.botModeSelectionMetadata do
            nil -> acc
            _ -> [acc, "\xB2\x01", Protox.Encode.encode_message(msg.botModeSelectionMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botModeSelectionMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botQuotaMetadata(acc, msg) do
        try do
          case msg.botQuotaMetadata do
            nil -> acc
            _ -> [acc, "\xBA\x01", Protox.Encode.encode_message(msg.botQuotaMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botQuotaMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botAgeCollectionMetadata(acc, msg) do
        try do
          case msg.botAgeCollectionMetadata do
            nil -> acc
            _ -> [acc, "\xC2\x01", Protox.Encode.encode_message(msg.botAgeCollectionMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botAgeCollectionMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_conversationStarterPromptID(acc, msg) do
        try do
          case msg.conversationStarterPromptID do
            nil -> acc
            _ -> [acc, "\xCA\x01", Protox.Encode.encode_string(msg.conversationStarterPromptID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:conversationStarterPromptID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botResponseID(acc, msg) do
        try do
          case msg.botResponseID do
            nil -> acc
            _ -> [acc, "\xD2\x01", Protox.Encode.encode_string(msg.botResponseID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botResponseID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_verificationMetadata(acc, msg) do
        try do
          case msg.verificationMetadata do
            nil -> acc
            _ -> [acc, "\xDA\x01", Protox.Encode.encode_message(msg.verificationMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:verificationMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_unifiedResponseMutation(acc, msg) do
        try do
          case msg.unifiedResponseMutation do
            nil -> acc
            _ -> [acc, "\xE2\x01", Protox.Encode.encode_message(msg.unifiedResponseMutation)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:unifiedResponseMutation, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botMessageOriginMetadata(acc, msg) do
        try do
          case msg.botMessageOriginMetadata do
            nil -> acc
            _ -> [acc, "\xEA\x01", Protox.Encode.encode_message(msg.botMessageOriginMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botMessageOriginMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_inThreadSurveyMetadata(acc, msg) do
        try do
          case msg.inThreadSurveyMetadata do
            nil -> acc
            _ -> [acc, "\xF2\x01", Protox.Encode.encode_message(msg.inThreadSurveyMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:inThreadSurveyMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botThreadInfo(acc, msg) do
        try do
          case msg.botThreadInfo do
            nil -> acc
            _ -> [acc, "\xFA\x01", Protox.Encode.encode_message(msg.botThreadInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botThreadInfo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_regenerateMetadata(acc, msg) do
        try do
          case msg.regenerateMetadata do
            nil -> acc
            _ -> [acc, "\x82\x02", Protox.Encode.encode_message(msg.regenerateMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:regenerateMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_sessionTransparencyMetadata(acc, msg) do
        try do
          case msg.sessionTransparencyMetadata do
            nil -> acc
            _ -> [acc, "\x8A\x02", Protox.Encode.encode_message(msg.sessionTransparencyMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:sessionTransparencyMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botDocumentMessageMetadata(acc, msg) do
        try do
          case msg.botDocumentMessageMetadata do
            nil -> acc
            _ -> [acc, "\x92\x02", Protox.Encode.encode_message(msg.botDocumentMessageMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botDocumentMessageMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botGroupMetadata(acc, msg) do
        try do
          case msg.botGroupMetadata do
            nil -> acc
            _ -> [acc, "\x9A\x02", Protox.Encode.encode_message(msg.botGroupMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botGroupMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botRenderingConfigMetadata(acc, msg) do
        try do
          case msg.botRenderingConfigMetadata do
            nil -> acc
            _ -> [acc, "\xA2\x02", Protox.Encode.encode_message(msg.botRenderingConfigMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botRenderingConfigMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botInfrastructureDiagnostics(acc, msg) do
        try do
          case msg.botInfrastructureDiagnostics do
            nil -> acc
            _ -> [acc, "\xAA\x02", Protox.Encode.encode_message(msg.botInfrastructureDiagnostics)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :botInfrastructureDiagnostics,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_aiMediaCollectionMetadata(acc, msg) do
        try do
          case msg.aiMediaCollectionMetadata do
            nil -> acc
            _ -> [acc, "\xB2\x02", Protox.Encode.encode_message(msg.aiMediaCollectionMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:aiMediaCollectionMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_commandMetadata(acc, msg) do
        try do
          case msg.commandMetadata do
            nil -> acc
            _ -> [acc, "\xBA\x02", Protox.Encode.encode_message(msg.commandMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:commandMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_resolvedToolCallMetadata(acc, msg) do
        try do
          case msg.resolvedToolCallMetadata do
            nil -> acc
            _ -> [acc, "\xC2\x02", Protox.Encode.encode_message(msg.resolvedToolCallMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:resolvedToolCallMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_subscriptionUpsellMetadata(acc, msg) do
        try do
          case msg.subscriptionUpsellMetadata do
            nil -> acc
            _ -> [acc, "\xCA\x02", Protox.Encode.encode_message(msg.subscriptionUpsellMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:subscriptionUpsellMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pttPromptMetadata(acc, msg) do
        try do
          case msg.pttPromptMetadata do
            nil -> acc
            _ -> [acc, "\xD2\x02", Protox.Encode.encode_message(msg.pttPromptMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pttPromptMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botHistoryShareMetadata(acc, msg) do
        try do
          case msg.botHistoryShareMetadata do
            nil -> acc
            _ -> [acc, "\xDA\x02", Protox.Encode.encode_message(msg.botHistoryShareMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botHistoryShareMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_responseStoppedByUser(acc, msg) do
        try do
          case msg.responseStoppedByUser do
            nil -> acc
            _ -> [acc, "\xE0\x02", Protox.Encode.encode_bool(msg.responseStoppedByUser)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:responseStoppedByUser, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_internalMetadata(acc, msg) do
        try do
          case msg.internalMetadata do
            nil -> acc
            _ -> [acc, "\xBA>", Protox.Encode.encode_bytes(msg.internalMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:internalMetadata, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsAICommon.BotMetadata))
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

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[personaID: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pluginMetadata:
                   Protox.MergeMessage.merge(
                     msg.pluginMetadata,
                     WAWebProtobufsAICommon.BotPluginMetadata.decode!(delimited)
                   )
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 suggestedPromptMetadata:
                   Protox.MergeMessage.merge(
                     msg.suggestedPromptMetadata,
                     WAWebProtobufsAICommon.BotSuggestedPromptMetadata.decode!(delimited)
                   )
               ], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[invokerJID: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 sessionMetadata:
                   Protox.MergeMessage.merge(
                     msg.sessionMetadata,
                     WAWebProtobufsAICommon.BotSessionMetadata.decode!(delimited)
                   )
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 memuMetadata:
                   Protox.MergeMessage.merge(
                     msg.memuMetadata,
                     WAWebProtobufsAICommon.BotMemuMetadata.decode!(delimited)
                   )
               ], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[timezone: Protox.Decode.validate_string!(delimited)], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 reminderMetadata:
                   Protox.MergeMessage.merge(
                     msg.reminderMetadata,
                     WAWebProtobufsAICommon.BotReminderMetadata.decode!(delimited)
                   )
               ], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 modelMetadata:
                   Protox.MergeMessage.merge(
                     msg.modelMetadata,
                     WAWebProtobufsAICommon.BotModelMetadata.decode!(delimited)
                   )
               ], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[messageDisclaimerText: Protox.Decode.validate_string!(delimited)], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 progressIndicatorMetadata:
                   Protox.MergeMessage.merge(
                     msg.progressIndicatorMetadata,
                     WAWebProtobufsAICommon.BotProgressIndicatorMetadata.decode!(delimited)
                   )
               ], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 capabilityMetadata:
                   Protox.MergeMessage.merge(
                     msg.capabilityMetadata,
                     WAWebProtobufsAICommon.BotCapabilityMetadata.decode!(delimited)
                   )
               ], rest}

            {14, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 imagineMetadata:
                   Protox.MergeMessage.merge(
                     msg.imagineMetadata,
                     WAWebProtobufsAICommon.BotImagineMetadata.decode!(delimited)
                   )
               ], rest}

            {15, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 memoryMetadata:
                   Protox.MergeMessage.merge(
                     msg.memoryMetadata,
                     WAWebProtobufsAICommon.BotMemoryMetadata.decode!(delimited)
                   )
               ], rest}

            {16, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 renderingMetadata:
                   Protox.MergeMessage.merge(
                     msg.renderingMetadata,
                     WAWebProtobufsAICommon.BotRenderingMetadata.decode!(delimited)
                   )
               ], rest}

            {17, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botMetricsMetadata:
                   Protox.MergeMessage.merge(
                     msg.botMetricsMetadata,
                     WAWebProtobufsAICommon.BotMetricsMetadata.decode!(delimited)
                   )
               ], rest}

            {18, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botLinkedAccountsMetadata:
                   Protox.MergeMessage.merge(
                     msg.botLinkedAccountsMetadata,
                     WAWebProtobufsAICommon.BotLinkedAccountsMetadata.decode!(delimited)
                   )
               ], rest}

            {19, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 richResponseSourcesMetadata:
                   Protox.MergeMessage.merge(
                     msg.richResponseSourcesMetadata,
                     WAWebProtobufsAICommon.BotSourcesMetadata.decode!(delimited)
                   )
               ], rest}

            {20, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[aiConversationContext: delimited], rest}

            {21, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botPromotionMessageMetadata:
                   Protox.MergeMessage.merge(
                     msg.botPromotionMessageMetadata,
                     WAWebProtobufsAICommon.BotPromotionMessageMetadata.decode!(delimited)
                   )
               ], rest}

            {22, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botModeSelectionMetadata:
                   Protox.MergeMessage.merge(
                     msg.botModeSelectionMetadata,
                     WAWebProtobufsAICommon.BotModeSelectionMetadata.decode!(delimited)
                   )
               ], rest}

            {23, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botQuotaMetadata:
                   Protox.MergeMessage.merge(
                     msg.botQuotaMetadata,
                     WAWebProtobufsAICommon.BotQuotaMetadata.decode!(delimited)
                   )
               ], rest}

            {24, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botAgeCollectionMetadata:
                   Protox.MergeMessage.merge(
                     msg.botAgeCollectionMetadata,
                     WAWebProtobufsAICommon.BotAgeCollectionMetadata.decode!(delimited)
                   )
               ], rest}

            {25, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[conversationStarterPromptID: Protox.Decode.validate_string!(delimited)], rest}

            {26, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[botResponseID: Protox.Decode.validate_string!(delimited)], rest}

            {27, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 verificationMetadata:
                   Protox.MergeMessage.merge(
                     msg.verificationMetadata,
                     WAWebProtobufsAICommon.BotSignatureVerificationMetadata.decode!(delimited)
                   )
               ], rest}

            {28, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 unifiedResponseMutation:
                   Protox.MergeMessage.merge(
                     msg.unifiedResponseMutation,
                     WAWebProtobufsAICommon.BotUnifiedResponseMutation.decode!(delimited)
                   )
               ], rest}

            {29, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botMessageOriginMetadata:
                   Protox.MergeMessage.merge(
                     msg.botMessageOriginMetadata,
                     WAWebProtobufsAICommon.BotMessageOriginMetadata.decode!(delimited)
                   )
               ], rest}

            {30, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 inThreadSurveyMetadata:
                   Protox.MergeMessage.merge(
                     msg.inThreadSurveyMetadata,
                     WAWebProtobufsAICommon.InThreadSurveyMetadata.decode!(delimited)
                   )
               ], rest}

            {31, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botThreadInfo:
                   Protox.MergeMessage.merge(
                     msg.botThreadInfo,
                     WAWebProtobufsAICommon.AIThreadInfo.decode!(delimited)
                   )
               ], rest}

            {32, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 regenerateMetadata:
                   Protox.MergeMessage.merge(
                     msg.regenerateMetadata,
                     WAWebProtobufsAICommon.AIRegenerateMetadata.decode!(delimited)
                   )
               ], rest}

            {33, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 sessionTransparencyMetadata:
                   Protox.MergeMessage.merge(
                     msg.sessionTransparencyMetadata,
                     WAWebProtobufsAICommon.SessionTransparencyMetadata.decode!(delimited)
                   )
               ], rest}

            {34, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botDocumentMessageMetadata:
                   Protox.MergeMessage.merge(
                     msg.botDocumentMessageMetadata,
                     WAWebProtobufsAICommon.BotDocumentMessageMetadata.decode!(delimited)
                   )
               ], rest}

            {35, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botGroupMetadata:
                   Protox.MergeMessage.merge(
                     msg.botGroupMetadata,
                     WAWebProtobufsAICommon.BotGroupMetadata.decode!(delimited)
                   )
               ], rest}

            {36, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botRenderingConfigMetadata:
                   Protox.MergeMessage.merge(
                     msg.botRenderingConfigMetadata,
                     WAWebProtobufsAICommon.BotRenderingConfigMetadata.decode!(delimited)
                   )
               ], rest}

            {37, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botInfrastructureDiagnostics:
                   Protox.MergeMessage.merge(
                     msg.botInfrastructureDiagnostics,
                     WAWebProtobufsAICommon.BotInfrastructureDiagnostics.decode!(delimited)
                   )
               ], rest}

            {38, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 aiMediaCollectionMetadata:
                   Protox.MergeMessage.merge(
                     msg.aiMediaCollectionMetadata,
                     WAWebProtobufsAICommon.AIMediaCollectionMetadata.decode!(delimited)
                   )
               ], rest}

            {39, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 commandMetadata:
                   Protox.MergeMessage.merge(
                     msg.commandMetadata,
                     WAWebProtobufsAICommon.BotCommandMetadata.decode!(delimited)
                   )
               ], rest}

            {40, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 resolvedToolCallMetadata:
                   Protox.MergeMessage.merge(
                     msg.resolvedToolCallMetadata,
                     WAWebProtobufsAICommon.BotResolvedToolCallMetadata.decode!(delimited)
                   )
               ], rest}

            {41, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 subscriptionUpsellMetadata:
                   Protox.MergeMessage.merge(
                     msg.subscriptionUpsellMetadata,
                     WAWebProtobufsAICommon.AISubscriptionUpsellMetadata.decode!(delimited)
                   )
               ], rest}

            {42, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pttPromptMetadata:
                   Protox.MergeMessage.merge(
                     msg.pttPromptMetadata,
                     WAWebProtobufsAICommon.BotPttPromptMetadata.decode!(delimited)
                   )
               ], rest}

            {43, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botHistoryShareMetadata:
                   Protox.MergeMessage.merge(
                     msg.botHistoryShareMetadata,
                     WAWebProtobufsAICommon.BotHistoryShareMetadata.decode!(delimited)
                   )
               ], rest}

            {44, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[responseStoppedByUser: value], rest}

            {999, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[internalMetadata: delimited], rest}

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
        WAWebProtobufsAICommon.BotMetadata,
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
        2 => {:personaID, {:scalar, ""}, :string},
        3 =>
          {:pluginMetadata, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotPluginMetadata}},
        4 =>
          {:suggestedPromptMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotSuggestedPromptMetadata}},
        5 => {:invokerJID, {:scalar, ""}, :string},
        6 =>
          {:sessionMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotSessionMetadata}},
        7 => {:memuMetadata, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotMemuMetadata}},
        8 => {:timezone, {:scalar, ""}, :string},
        9 =>
          {:reminderMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotReminderMetadata}},
        10 =>
          {:modelMetadata, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotModelMetadata}},
        11 => {:messageDisclaimerText, {:scalar, ""}, :string},
        12 =>
          {:progressIndicatorMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotProgressIndicatorMetadata}},
        13 =>
          {:capabilityMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotCapabilityMetadata}},
        14 =>
          {:imagineMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotImagineMetadata}},
        15 =>
          {:memoryMetadata, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotMemoryMetadata}},
        16 =>
          {:renderingMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotRenderingMetadata}},
        17 =>
          {:botMetricsMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotMetricsMetadata}},
        18 =>
          {:botLinkedAccountsMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotLinkedAccountsMetadata}},
        19 =>
          {:richResponseSourcesMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotSourcesMetadata}},
        20 => {:aiConversationContext, {:scalar, ""}, :bytes},
        21 =>
          {:botPromotionMessageMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotPromotionMessageMetadata}},
        22 =>
          {:botModeSelectionMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotModeSelectionMetadata}},
        23 =>
          {:botQuotaMetadata, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotQuotaMetadata}},
        24 =>
          {:botAgeCollectionMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotAgeCollectionMetadata}},
        25 => {:conversationStarterPromptID, {:scalar, ""}, :string},
        26 => {:botResponseID, {:scalar, ""}, :string},
        27 =>
          {:verificationMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotSignatureVerificationMetadata}},
        28 =>
          {:unifiedResponseMutation, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotUnifiedResponseMutation}},
        29 =>
          {:botMessageOriginMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotMessageOriginMetadata}},
        30 =>
          {:inThreadSurveyMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.InThreadSurveyMetadata}},
        31 => {:botThreadInfo, {:scalar, nil}, {:message, WAWebProtobufsAICommon.AIThreadInfo}},
        32 =>
          {:regenerateMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.AIRegenerateMetadata}},
        33 =>
          {:sessionTransparencyMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.SessionTransparencyMetadata}},
        34 =>
          {:botDocumentMessageMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotDocumentMessageMetadata}},
        35 =>
          {:botGroupMetadata, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotGroupMetadata}},
        36 =>
          {:botRenderingConfigMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotRenderingConfigMetadata}},
        37 =>
          {:botInfrastructureDiagnostics, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotInfrastructureDiagnostics}},
        38 =>
          {:aiMediaCollectionMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.AIMediaCollectionMetadata}},
        39 =>
          {:commandMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotCommandMetadata}},
        40 =>
          {:resolvedToolCallMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotResolvedToolCallMetadata}},
        41 =>
          {:subscriptionUpsellMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.AISubscriptionUpsellMetadata}},
        42 =>
          {:pttPromptMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotPttPromptMetadata}},
        43 =>
          {:botHistoryShareMetadata, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotHistoryShareMetadata}},
        44 => {:responseStoppedByUser, {:scalar, false}, :bool},
        999 => {:internalMetadata, {:scalar, ""}, :bytes}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        aiConversationContext: {20, {:scalar, ""}, :bytes},
        aiMediaCollectionMetadata:
          {38, {:scalar, nil}, {:message, WAWebProtobufsAICommon.AIMediaCollectionMetadata}},
        botAgeCollectionMetadata:
          {24, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotAgeCollectionMetadata}},
        botDocumentMessageMetadata:
          {34, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotDocumentMessageMetadata}},
        botGroupMetadata:
          {35, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotGroupMetadata}},
        botHistoryShareMetadata:
          {43, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotHistoryShareMetadata}},
        botInfrastructureDiagnostics:
          {37, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotInfrastructureDiagnostics}},
        botLinkedAccountsMetadata:
          {18, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotLinkedAccountsMetadata}},
        botMessageOriginMetadata:
          {29, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotMessageOriginMetadata}},
        botMetricsMetadata:
          {17, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotMetricsMetadata}},
        botModeSelectionMetadata:
          {22, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotModeSelectionMetadata}},
        botPromotionMessageMetadata:
          {21, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotPromotionMessageMetadata}},
        botQuotaMetadata:
          {23, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotQuotaMetadata}},
        botRenderingConfigMetadata:
          {36, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotRenderingConfigMetadata}},
        botResponseID: {26, {:scalar, ""}, :string},
        botThreadInfo: {31, {:scalar, nil}, {:message, WAWebProtobufsAICommon.AIThreadInfo}},
        capabilityMetadata:
          {13, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotCapabilityMetadata}},
        commandMetadata:
          {39, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotCommandMetadata}},
        conversationStarterPromptID: {25, {:scalar, ""}, :string},
        imagineMetadata:
          {14, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotImagineMetadata}},
        inThreadSurveyMetadata:
          {30, {:scalar, nil}, {:message, WAWebProtobufsAICommon.InThreadSurveyMetadata}},
        internalMetadata: {999, {:scalar, ""}, :bytes},
        invokerJID: {5, {:scalar, ""}, :string},
        memoryMetadata:
          {15, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotMemoryMetadata}},
        memuMetadata: {7, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotMemuMetadata}},
        messageDisclaimerText: {11, {:scalar, ""}, :string},
        modelMetadata: {10, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotModelMetadata}},
        personaID: {2, {:scalar, ""}, :string},
        pluginMetadata: {3, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotPluginMetadata}},
        progressIndicatorMetadata:
          {12, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotProgressIndicatorMetadata}},
        pttPromptMetadata:
          {42, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotPttPromptMetadata}},
        regenerateMetadata:
          {32, {:scalar, nil}, {:message, WAWebProtobufsAICommon.AIRegenerateMetadata}},
        reminderMetadata:
          {9, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotReminderMetadata}},
        renderingMetadata:
          {16, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotRenderingMetadata}},
        resolvedToolCallMetadata:
          {40, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotResolvedToolCallMetadata}},
        responseStoppedByUser: {44, {:scalar, false}, :bool},
        richResponseSourcesMetadata:
          {19, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotSourcesMetadata}},
        sessionMetadata:
          {6, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotSessionMetadata}},
        sessionTransparencyMetadata:
          {33, {:scalar, nil}, {:message, WAWebProtobufsAICommon.SessionTransparencyMetadata}},
        subscriptionUpsellMetadata:
          {41, {:scalar, nil}, {:message, WAWebProtobufsAICommon.AISubscriptionUpsellMetadata}},
        suggestedPromptMetadata:
          {4, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotSuggestedPromptMetadata}},
        timezone: {8, {:scalar, ""}, :string},
        unifiedResponseMutation:
          {28, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotUnifiedResponseMutation}},
        verificationMetadata:
          {27, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotSignatureVerificationMetadata}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "personaID",
          kind: {:scalar, ""},
          label: :optional,
          name: :personaID,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "pluginMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :pluginMetadata,
          tag: 3,
          type: {:message, WAWebProtobufsAICommon.BotPluginMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "suggestedPromptMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :suggestedPromptMetadata,
          tag: 4,
          type: {:message, WAWebProtobufsAICommon.BotSuggestedPromptMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "invokerJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :invokerJID,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "sessionMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :sessionMetadata,
          tag: 6,
          type: {:message, WAWebProtobufsAICommon.BotSessionMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "memuMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :memuMetadata,
          tag: 7,
          type: {:message, WAWebProtobufsAICommon.BotMemuMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "timezone",
          kind: {:scalar, ""},
          label: :optional,
          name: :timezone,
          tag: 8,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "reminderMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :reminderMetadata,
          tag: 9,
          type: {:message, WAWebProtobufsAICommon.BotReminderMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "modelMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :modelMetadata,
          tag: 10,
          type: {:message, WAWebProtobufsAICommon.BotModelMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageDisclaimerText",
          kind: {:scalar, ""},
          label: :optional,
          name: :messageDisclaimerText,
          tag: 11,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "progressIndicatorMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :progressIndicatorMetadata,
          tag: 12,
          type: {:message, WAWebProtobufsAICommon.BotProgressIndicatorMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "capabilityMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :capabilityMetadata,
          tag: 13,
          type: {:message, WAWebProtobufsAICommon.BotCapabilityMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "imagineMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :imagineMetadata,
          tag: 14,
          type: {:message, WAWebProtobufsAICommon.BotImagineMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "memoryMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :memoryMetadata,
          tag: 15,
          type: {:message, WAWebProtobufsAICommon.BotMemoryMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "renderingMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :renderingMetadata,
          tag: 16,
          type: {:message, WAWebProtobufsAICommon.BotRenderingMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botMetricsMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :botMetricsMetadata,
          tag: 17,
          type: {:message, WAWebProtobufsAICommon.BotMetricsMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botLinkedAccountsMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :botLinkedAccountsMetadata,
          tag: 18,
          type: {:message, WAWebProtobufsAICommon.BotLinkedAccountsMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "richResponseSourcesMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :richResponseSourcesMetadata,
          tag: 19,
          type: {:message, WAWebProtobufsAICommon.BotSourcesMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "aiConversationContext",
          kind: {:scalar, ""},
          label: :optional,
          name: :aiConversationContext,
          tag: 20,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "botPromotionMessageMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :botPromotionMessageMetadata,
          tag: 21,
          type: {:message, WAWebProtobufsAICommon.BotPromotionMessageMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botModeSelectionMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :botModeSelectionMetadata,
          tag: 22,
          type: {:message, WAWebProtobufsAICommon.BotModeSelectionMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botQuotaMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :botQuotaMetadata,
          tag: 23,
          type: {:message, WAWebProtobufsAICommon.BotQuotaMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botAgeCollectionMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :botAgeCollectionMetadata,
          tag: 24,
          type: {:message, WAWebProtobufsAICommon.BotAgeCollectionMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "conversationStarterPromptID",
          kind: {:scalar, ""},
          label: :optional,
          name: :conversationStarterPromptID,
          tag: 25,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "botResponseID",
          kind: {:scalar, ""},
          label: :optional,
          name: :botResponseID,
          tag: 26,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "verificationMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :verificationMetadata,
          tag: 27,
          type: {:message, WAWebProtobufsAICommon.BotSignatureVerificationMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "unifiedResponseMutation",
          kind: {:scalar, nil},
          label: :optional,
          name: :unifiedResponseMutation,
          tag: 28,
          type: {:message, WAWebProtobufsAICommon.BotUnifiedResponseMutation}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botMessageOriginMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :botMessageOriginMetadata,
          tag: 29,
          type: {:message, WAWebProtobufsAICommon.BotMessageOriginMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "inThreadSurveyMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :inThreadSurveyMetadata,
          tag: 30,
          type: {:message, WAWebProtobufsAICommon.InThreadSurveyMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botThreadInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :botThreadInfo,
          tag: 31,
          type: {:message, WAWebProtobufsAICommon.AIThreadInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "regenerateMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :regenerateMetadata,
          tag: 32,
          type: {:message, WAWebProtobufsAICommon.AIRegenerateMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "sessionTransparencyMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :sessionTransparencyMetadata,
          tag: 33,
          type: {:message, WAWebProtobufsAICommon.SessionTransparencyMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botDocumentMessageMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :botDocumentMessageMetadata,
          tag: 34,
          type: {:message, WAWebProtobufsAICommon.BotDocumentMessageMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botGroupMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :botGroupMetadata,
          tag: 35,
          type: {:message, WAWebProtobufsAICommon.BotGroupMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botRenderingConfigMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :botRenderingConfigMetadata,
          tag: 36,
          type: {:message, WAWebProtobufsAICommon.BotRenderingConfigMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botInfrastructureDiagnostics",
          kind: {:scalar, nil},
          label: :optional,
          name: :botInfrastructureDiagnostics,
          tag: 37,
          type: {:message, WAWebProtobufsAICommon.BotInfrastructureDiagnostics}
        },
        %{
          __struct__: Protox.Field,
          json_name: "aiMediaCollectionMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :aiMediaCollectionMetadata,
          tag: 38,
          type: {:message, WAWebProtobufsAICommon.AIMediaCollectionMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "commandMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :commandMetadata,
          tag: 39,
          type: {:message, WAWebProtobufsAICommon.BotCommandMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "resolvedToolCallMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :resolvedToolCallMetadata,
          tag: 40,
          type: {:message, WAWebProtobufsAICommon.BotResolvedToolCallMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "subscriptionUpsellMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :subscriptionUpsellMetadata,
          tag: 41,
          type: {:message, WAWebProtobufsAICommon.AISubscriptionUpsellMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pttPromptMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :pttPromptMetadata,
          tag: 42,
          type: {:message, WAWebProtobufsAICommon.BotPttPromptMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botHistoryShareMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :botHistoryShareMetadata,
          tag: 43,
          type: {:message, WAWebProtobufsAICommon.BotHistoryShareMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "responseStoppedByUser",
          kind: {:scalar, false},
          label: :optional,
          name: :responseStoppedByUser,
          tag: 44,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "internalMetadata",
          kind: {:scalar, ""},
          label: :optional,
          name: :internalMetadata,
          tag: 999,
          type: :bytes
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:personaID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "personaID",
             kind: {:scalar, ""},
             label: :optional,
             name: :personaID,
             tag: 2,
             type: :string
           }}
        end

        def field_def("personaID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "personaID",
             kind: {:scalar, ""},
             label: :optional,
             name: :personaID,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:pluginMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pluginMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :pluginMetadata,
             tag: 3,
             type: {:message, WAWebProtobufsAICommon.BotPluginMetadata}
           }}
        end

        def field_def("pluginMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pluginMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :pluginMetadata,
             tag: 3,
             type: {:message, WAWebProtobufsAICommon.BotPluginMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:suggestedPromptMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "suggestedPromptMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :suggestedPromptMetadata,
             tag: 4,
             type: {:message, WAWebProtobufsAICommon.BotSuggestedPromptMetadata}
           }}
        end

        def field_def("suggestedPromptMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "suggestedPromptMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :suggestedPromptMetadata,
             tag: 4,
             type: {:message, WAWebProtobufsAICommon.BotSuggestedPromptMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:invokerJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "invokerJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :invokerJID,
             tag: 5,
             type: :string
           }}
        end

        def field_def("invokerJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "invokerJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :invokerJID,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:sessionMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sessionMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :sessionMetadata,
             tag: 6,
             type: {:message, WAWebProtobufsAICommon.BotSessionMetadata}
           }}
        end

        def field_def("sessionMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sessionMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :sessionMetadata,
             tag: 6,
             type: {:message, WAWebProtobufsAICommon.BotSessionMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:memuMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "memuMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :memuMetadata,
             tag: 7,
             type: {:message, WAWebProtobufsAICommon.BotMemuMetadata}
           }}
        end

        def field_def("memuMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "memuMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :memuMetadata,
             tag: 7,
             type: {:message, WAWebProtobufsAICommon.BotMemuMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:timezone) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "timezone",
             kind: {:scalar, ""},
             label: :optional,
             name: :timezone,
             tag: 8,
             type: :string
           }}
        end

        def field_def("timezone") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "timezone",
             kind: {:scalar, ""},
             label: :optional,
             name: :timezone,
             tag: 8,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:reminderMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reminderMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :reminderMetadata,
             tag: 9,
             type: {:message, WAWebProtobufsAICommon.BotReminderMetadata}
           }}
        end

        def field_def("reminderMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reminderMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :reminderMetadata,
             tag: 9,
             type: {:message, WAWebProtobufsAICommon.BotReminderMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:modelMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "modelMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :modelMetadata,
             tag: 10,
             type: {:message, WAWebProtobufsAICommon.BotModelMetadata}
           }}
        end

        def field_def("modelMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "modelMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :modelMetadata,
             tag: 10,
             type: {:message, WAWebProtobufsAICommon.BotModelMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:messageDisclaimerText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageDisclaimerText",
             kind: {:scalar, ""},
             label: :optional,
             name: :messageDisclaimerText,
             tag: 11,
             type: :string
           }}
        end

        def field_def("messageDisclaimerText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageDisclaimerText",
             kind: {:scalar, ""},
             label: :optional,
             name: :messageDisclaimerText,
             tag: 11,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:progressIndicatorMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "progressIndicatorMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :progressIndicatorMetadata,
             tag: 12,
             type: {:message, WAWebProtobufsAICommon.BotProgressIndicatorMetadata}
           }}
        end

        def field_def("progressIndicatorMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "progressIndicatorMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :progressIndicatorMetadata,
             tag: 12,
             type: {:message, WAWebProtobufsAICommon.BotProgressIndicatorMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:capabilityMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "capabilityMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :capabilityMetadata,
             tag: 13,
             type: {:message, WAWebProtobufsAICommon.BotCapabilityMetadata}
           }}
        end

        def field_def("capabilityMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "capabilityMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :capabilityMetadata,
             tag: 13,
             type: {:message, WAWebProtobufsAICommon.BotCapabilityMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:imagineMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imagineMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :imagineMetadata,
             tag: 14,
             type: {:message, WAWebProtobufsAICommon.BotImagineMetadata}
           }}
        end

        def field_def("imagineMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imagineMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :imagineMetadata,
             tag: 14,
             type: {:message, WAWebProtobufsAICommon.BotImagineMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:memoryMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "memoryMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :memoryMetadata,
             tag: 15,
             type: {:message, WAWebProtobufsAICommon.BotMemoryMetadata}
           }}
        end

        def field_def("memoryMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "memoryMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :memoryMetadata,
             tag: 15,
             type: {:message, WAWebProtobufsAICommon.BotMemoryMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:renderingMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "renderingMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :renderingMetadata,
             tag: 16,
             type: {:message, WAWebProtobufsAICommon.BotRenderingMetadata}
           }}
        end

        def field_def("renderingMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "renderingMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :renderingMetadata,
             tag: 16,
             type: {:message, WAWebProtobufsAICommon.BotRenderingMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:botMetricsMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botMetricsMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botMetricsMetadata,
             tag: 17,
             type: {:message, WAWebProtobufsAICommon.BotMetricsMetadata}
           }}
        end

        def field_def("botMetricsMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botMetricsMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botMetricsMetadata,
             tag: 17,
             type: {:message, WAWebProtobufsAICommon.BotMetricsMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:botLinkedAccountsMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botLinkedAccountsMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botLinkedAccountsMetadata,
             tag: 18,
             type: {:message, WAWebProtobufsAICommon.BotLinkedAccountsMetadata}
           }}
        end

        def field_def("botLinkedAccountsMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botLinkedAccountsMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botLinkedAccountsMetadata,
             tag: 18,
             type: {:message, WAWebProtobufsAICommon.BotLinkedAccountsMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:richResponseSourcesMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "richResponseSourcesMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :richResponseSourcesMetadata,
             tag: 19,
             type: {:message, WAWebProtobufsAICommon.BotSourcesMetadata}
           }}
        end

        def field_def("richResponseSourcesMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "richResponseSourcesMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :richResponseSourcesMetadata,
             tag: 19,
             type: {:message, WAWebProtobufsAICommon.BotSourcesMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:aiConversationContext) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiConversationContext",
             kind: {:scalar, ""},
             label: :optional,
             name: :aiConversationContext,
             tag: 20,
             type: :bytes
           }}
        end

        def field_def("aiConversationContext") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiConversationContext",
             kind: {:scalar, ""},
             label: :optional,
             name: :aiConversationContext,
             tag: 20,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:botPromotionMessageMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botPromotionMessageMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botPromotionMessageMetadata,
             tag: 21,
             type: {:message, WAWebProtobufsAICommon.BotPromotionMessageMetadata}
           }}
        end

        def field_def("botPromotionMessageMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botPromotionMessageMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botPromotionMessageMetadata,
             tag: 21,
             type: {:message, WAWebProtobufsAICommon.BotPromotionMessageMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:botModeSelectionMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botModeSelectionMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botModeSelectionMetadata,
             tag: 22,
             type: {:message, WAWebProtobufsAICommon.BotModeSelectionMetadata}
           }}
        end

        def field_def("botModeSelectionMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botModeSelectionMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botModeSelectionMetadata,
             tag: 22,
             type: {:message, WAWebProtobufsAICommon.BotModeSelectionMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:botQuotaMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botQuotaMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botQuotaMetadata,
             tag: 23,
             type: {:message, WAWebProtobufsAICommon.BotQuotaMetadata}
           }}
        end

        def field_def("botQuotaMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botQuotaMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botQuotaMetadata,
             tag: 23,
             type: {:message, WAWebProtobufsAICommon.BotQuotaMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:botAgeCollectionMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botAgeCollectionMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botAgeCollectionMetadata,
             tag: 24,
             type: {:message, WAWebProtobufsAICommon.BotAgeCollectionMetadata}
           }}
        end

        def field_def("botAgeCollectionMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botAgeCollectionMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botAgeCollectionMetadata,
             tag: 24,
             type: {:message, WAWebProtobufsAICommon.BotAgeCollectionMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:conversationStarterPromptID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversationStarterPromptID",
             kind: {:scalar, ""},
             label: :optional,
             name: :conversationStarterPromptID,
             tag: 25,
             type: :string
           }}
        end

        def field_def("conversationStarterPromptID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversationStarterPromptID",
             kind: {:scalar, ""},
             label: :optional,
             name: :conversationStarterPromptID,
             tag: 25,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:botResponseID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botResponseID",
             kind: {:scalar, ""},
             label: :optional,
             name: :botResponseID,
             tag: 26,
             type: :string
           }}
        end

        def field_def("botResponseID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botResponseID",
             kind: {:scalar, ""},
             label: :optional,
             name: :botResponseID,
             tag: 26,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:verificationMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "verificationMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :verificationMetadata,
             tag: 27,
             type: {:message, WAWebProtobufsAICommon.BotSignatureVerificationMetadata}
           }}
        end

        def field_def("verificationMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "verificationMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :verificationMetadata,
             tag: 27,
             type: {:message, WAWebProtobufsAICommon.BotSignatureVerificationMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:unifiedResponseMutation) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "unifiedResponseMutation",
             kind: {:scalar, nil},
             label: :optional,
             name: :unifiedResponseMutation,
             tag: 28,
             type: {:message, WAWebProtobufsAICommon.BotUnifiedResponseMutation}
           }}
        end

        def field_def("unifiedResponseMutation") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "unifiedResponseMutation",
             kind: {:scalar, nil},
             label: :optional,
             name: :unifiedResponseMutation,
             tag: 28,
             type: {:message, WAWebProtobufsAICommon.BotUnifiedResponseMutation}
           }}
        end

        []
      ),
      (
        def field_def(:botMessageOriginMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botMessageOriginMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botMessageOriginMetadata,
             tag: 29,
             type: {:message, WAWebProtobufsAICommon.BotMessageOriginMetadata}
           }}
        end

        def field_def("botMessageOriginMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botMessageOriginMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botMessageOriginMetadata,
             tag: 29,
             type: {:message, WAWebProtobufsAICommon.BotMessageOriginMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:inThreadSurveyMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inThreadSurveyMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :inThreadSurveyMetadata,
             tag: 30,
             type: {:message, WAWebProtobufsAICommon.InThreadSurveyMetadata}
           }}
        end

        def field_def("inThreadSurveyMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inThreadSurveyMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :inThreadSurveyMetadata,
             tag: 30,
             type: {:message, WAWebProtobufsAICommon.InThreadSurveyMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:botThreadInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botThreadInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :botThreadInfo,
             tag: 31,
             type: {:message, WAWebProtobufsAICommon.AIThreadInfo}
           }}
        end

        def field_def("botThreadInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botThreadInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :botThreadInfo,
             tag: 31,
             type: {:message, WAWebProtobufsAICommon.AIThreadInfo}
           }}
        end

        []
      ),
      (
        def field_def(:regenerateMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "regenerateMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :regenerateMetadata,
             tag: 32,
             type: {:message, WAWebProtobufsAICommon.AIRegenerateMetadata}
           }}
        end

        def field_def("regenerateMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "regenerateMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :regenerateMetadata,
             tag: 32,
             type: {:message, WAWebProtobufsAICommon.AIRegenerateMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:sessionTransparencyMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sessionTransparencyMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :sessionTransparencyMetadata,
             tag: 33,
             type: {:message, WAWebProtobufsAICommon.SessionTransparencyMetadata}
           }}
        end

        def field_def("sessionTransparencyMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sessionTransparencyMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :sessionTransparencyMetadata,
             tag: 33,
             type: {:message, WAWebProtobufsAICommon.SessionTransparencyMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:botDocumentMessageMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botDocumentMessageMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botDocumentMessageMetadata,
             tag: 34,
             type: {:message, WAWebProtobufsAICommon.BotDocumentMessageMetadata}
           }}
        end

        def field_def("botDocumentMessageMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botDocumentMessageMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botDocumentMessageMetadata,
             tag: 34,
             type: {:message, WAWebProtobufsAICommon.BotDocumentMessageMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:botGroupMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botGroupMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botGroupMetadata,
             tag: 35,
             type: {:message, WAWebProtobufsAICommon.BotGroupMetadata}
           }}
        end

        def field_def("botGroupMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botGroupMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botGroupMetadata,
             tag: 35,
             type: {:message, WAWebProtobufsAICommon.BotGroupMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:botRenderingConfigMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botRenderingConfigMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botRenderingConfigMetadata,
             tag: 36,
             type: {:message, WAWebProtobufsAICommon.BotRenderingConfigMetadata}
           }}
        end

        def field_def("botRenderingConfigMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botRenderingConfigMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botRenderingConfigMetadata,
             tag: 36,
             type: {:message, WAWebProtobufsAICommon.BotRenderingConfigMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:botInfrastructureDiagnostics) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botInfrastructureDiagnostics",
             kind: {:scalar, nil},
             label: :optional,
             name: :botInfrastructureDiagnostics,
             tag: 37,
             type: {:message, WAWebProtobufsAICommon.BotInfrastructureDiagnostics}
           }}
        end

        def field_def("botInfrastructureDiagnostics") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botInfrastructureDiagnostics",
             kind: {:scalar, nil},
             label: :optional,
             name: :botInfrastructureDiagnostics,
             tag: 37,
             type: {:message, WAWebProtobufsAICommon.BotInfrastructureDiagnostics}
           }}
        end

        []
      ),
      (
        def field_def(:aiMediaCollectionMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiMediaCollectionMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :aiMediaCollectionMetadata,
             tag: 38,
             type: {:message, WAWebProtobufsAICommon.AIMediaCollectionMetadata}
           }}
        end

        def field_def("aiMediaCollectionMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiMediaCollectionMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :aiMediaCollectionMetadata,
             tag: 38,
             type: {:message, WAWebProtobufsAICommon.AIMediaCollectionMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:commandMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "commandMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :commandMetadata,
             tag: 39,
             type: {:message, WAWebProtobufsAICommon.BotCommandMetadata}
           }}
        end

        def field_def("commandMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "commandMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :commandMetadata,
             tag: 39,
             type: {:message, WAWebProtobufsAICommon.BotCommandMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:resolvedToolCallMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "resolvedToolCallMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :resolvedToolCallMetadata,
             tag: 40,
             type: {:message, WAWebProtobufsAICommon.BotResolvedToolCallMetadata}
           }}
        end

        def field_def("resolvedToolCallMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "resolvedToolCallMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :resolvedToolCallMetadata,
             tag: 40,
             type: {:message, WAWebProtobufsAICommon.BotResolvedToolCallMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:subscriptionUpsellMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "subscriptionUpsellMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :subscriptionUpsellMetadata,
             tag: 41,
             type: {:message, WAWebProtobufsAICommon.AISubscriptionUpsellMetadata}
           }}
        end

        def field_def("subscriptionUpsellMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "subscriptionUpsellMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :subscriptionUpsellMetadata,
             tag: 41,
             type: {:message, WAWebProtobufsAICommon.AISubscriptionUpsellMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:pttPromptMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pttPromptMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :pttPromptMetadata,
             tag: 42,
             type: {:message, WAWebProtobufsAICommon.BotPttPromptMetadata}
           }}
        end

        def field_def("pttPromptMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pttPromptMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :pttPromptMetadata,
             tag: 42,
             type: {:message, WAWebProtobufsAICommon.BotPttPromptMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:botHistoryShareMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botHistoryShareMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botHistoryShareMetadata,
             tag: 43,
             type: {:message, WAWebProtobufsAICommon.BotHistoryShareMetadata}
           }}
        end

        def field_def("botHistoryShareMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botHistoryShareMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botHistoryShareMetadata,
             tag: 43,
             type: {:message, WAWebProtobufsAICommon.BotHistoryShareMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:responseStoppedByUser) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "responseStoppedByUser",
             kind: {:scalar, false},
             label: :optional,
             name: :responseStoppedByUser,
             tag: 44,
             type: :bool
           }}
        end

        def field_def("responseStoppedByUser") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "responseStoppedByUser",
             kind: {:scalar, false},
             label: :optional,
             name: :responseStoppedByUser,
             tag: 44,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:internalMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "internalMetadata",
             kind: {:scalar, ""},
             label: :optional,
             name: :internalMetadata,
             tag: 999,
             type: :bytes
           }}
        end

        def field_def("internalMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "internalMetadata",
             kind: {:scalar, ""},
             label: :optional,
             name: :internalMetadata,
             tag: 999,
             type: :bytes
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
    def default(:personaID) do
      {:ok, ""}
    end,
    def default(:pluginMetadata) do
      {:ok, nil}
    end,
    def default(:suggestedPromptMetadata) do
      {:ok, nil}
    end,
    def default(:invokerJID) do
      {:ok, ""}
    end,
    def default(:sessionMetadata) do
      {:ok, nil}
    end,
    def default(:memuMetadata) do
      {:ok, nil}
    end,
    def default(:timezone) do
      {:ok, ""}
    end,
    def default(:reminderMetadata) do
      {:ok, nil}
    end,
    def default(:modelMetadata) do
      {:ok, nil}
    end,
    def default(:messageDisclaimerText) do
      {:ok, ""}
    end,
    def default(:progressIndicatorMetadata) do
      {:ok, nil}
    end,
    def default(:capabilityMetadata) do
      {:ok, nil}
    end,
    def default(:imagineMetadata) do
      {:ok, nil}
    end,
    def default(:memoryMetadata) do
      {:ok, nil}
    end,
    def default(:renderingMetadata) do
      {:ok, nil}
    end,
    def default(:botMetricsMetadata) do
      {:ok, nil}
    end,
    def default(:botLinkedAccountsMetadata) do
      {:ok, nil}
    end,
    def default(:richResponseSourcesMetadata) do
      {:ok, nil}
    end,
    def default(:aiConversationContext) do
      {:ok, ""}
    end,
    def default(:botPromotionMessageMetadata) do
      {:ok, nil}
    end,
    def default(:botModeSelectionMetadata) do
      {:ok, nil}
    end,
    def default(:botQuotaMetadata) do
      {:ok, nil}
    end,
    def default(:botAgeCollectionMetadata) do
      {:ok, nil}
    end,
    def default(:conversationStarterPromptID) do
      {:ok, ""}
    end,
    def default(:botResponseID) do
      {:ok, ""}
    end,
    def default(:verificationMetadata) do
      {:ok, nil}
    end,
    def default(:unifiedResponseMutation) do
      {:ok, nil}
    end,
    def default(:botMessageOriginMetadata) do
      {:ok, nil}
    end,
    def default(:inThreadSurveyMetadata) do
      {:ok, nil}
    end,
    def default(:botThreadInfo) do
      {:ok, nil}
    end,
    def default(:regenerateMetadata) do
      {:ok, nil}
    end,
    def default(:sessionTransparencyMetadata) do
      {:ok, nil}
    end,
    def default(:botDocumentMessageMetadata) do
      {:ok, nil}
    end,
    def default(:botGroupMetadata) do
      {:ok, nil}
    end,
    def default(:botRenderingConfigMetadata) do
      {:ok, nil}
    end,
    def default(:botInfrastructureDiagnostics) do
      {:ok, nil}
    end,
    def default(:aiMediaCollectionMetadata) do
      {:ok, nil}
    end,
    def default(:commandMetadata) do
      {:ok, nil}
    end,
    def default(:resolvedToolCallMetadata) do
      {:ok, nil}
    end,
    def default(:subscriptionUpsellMetadata) do
      {:ok, nil}
    end,
    def default(:pttPromptMetadata) do
      {:ok, nil}
    end,
    def default(:botHistoryShareMetadata) do
      {:ok, nil}
    end,
    def default(:responseStoppedByUser) do
      {:ok, false}
    end,
    def default(:internalMetadata) do
      {:ok, ""}
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
        go_package: "go.mau.fi/whatsmeow/proto/waAICommon",
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

  @type t :: %__MODULE__{}
end
