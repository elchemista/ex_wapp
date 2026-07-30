# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ProtocolMessage do
  @moduledoc false
  defstruct key: nil,
            type: nil,
            ephemeralExpiration: nil,
            ephemeralSettingTimestamp: nil,
            historySyncNotification: nil,
            appStateSyncKeyShare: nil,
            appStateSyncKeyRequest: nil,
            initialSecurityNotificationSettingSync: nil,
            appStateFatalExceptionNotification: nil,
            disappearingMode: nil,
            editedMessage: nil,
            timestampMS: nil,
            peerDataOperationRequestMessage: nil,
            peerDataOperationRequestResponseMessage: nil,
            botFeedbackMessage: nil,
            invokerJID: nil,
            requestWelcomeMessageMetadata: nil,
            mediaNotifyMessage: nil,
            cloudApiThreadControlNotification: nil,
            lidMigrationMappingSyncMessage: nil,
            limitSharing: nil,
            aiPsiMetadata: nil,
            aiQueryFanout: nil,
            memberLabel: nil,
            aiMediaCollectionMessage: nil,
            afterReadDuration: nil,
            chatThemeSetting: nil,
            aiMetadataOperation: nil,
            markAsVerifiedAction: nil,
            coexStateSync: nil,
            syncRequestMutationRetry: nil,
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
        |> encode_type(msg)
        |> encode_ephemeralExpiration(msg)
        |> encode_ephemeralSettingTimestamp(msg)
        |> encode_historySyncNotification(msg)
        |> encode_appStateSyncKeyShare(msg)
        |> encode_appStateSyncKeyRequest(msg)
        |> encode_initialSecurityNotificationSettingSync(msg)
        |> encode_appStateFatalExceptionNotification(msg)
        |> encode_disappearingMode(msg)
        |> encode_editedMessage(msg)
        |> encode_timestampMS(msg)
        |> encode_peerDataOperationRequestMessage(msg)
        |> encode_peerDataOperationRequestResponseMessage(msg)
        |> encode_botFeedbackMessage(msg)
        |> encode_invokerJID(msg)
        |> encode_requestWelcomeMessageMetadata(msg)
        |> encode_mediaNotifyMessage(msg)
        |> encode_cloudApiThreadControlNotification(msg)
        |> encode_lidMigrationMappingSyncMessage(msg)
        |> encode_limitSharing(msg)
        |> encode_aiPsiMetadata(msg)
        |> encode_aiQueryFanout(msg)
        |> encode_memberLabel(msg)
        |> encode_aiMediaCollectionMessage(msg)
        |> encode_afterReadDuration(msg)
        |> encode_chatThemeSetting(msg)
        |> encode_aiMetadataOperation(msg)
        |> encode_markAsVerifiedAction(msg)
        |> encode_coexStateSync(msg)
        |> encode_syncRequestMutationRetry(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_key(acc, msg) do
        try do
          case msg.key do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_message(msg.key)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:key, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_type(acc, msg) do
        try do
          case msg.type do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x10",
                msg.type
                |> WAWebProtobufsE2E.ProtocolMessage.Type.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:type, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_ephemeralExpiration(acc, msg) do
        try do
          case msg.ephemeralExpiration do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_uint32(msg.ephemeralExpiration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeralExpiration, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ephemeralSettingTimestamp(acc, msg) do
        try do
          case msg.ephemeralSettingTimestamp do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_int64(msg.ephemeralSettingTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeralSettingTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_historySyncNotification(acc, msg) do
        try do
          case msg.historySyncNotification do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_message(msg.historySyncNotification)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:historySyncNotification, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_appStateSyncKeyShare(acc, msg) do
        try do
          case msg.appStateSyncKeyShare do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_message(msg.appStateSyncKeyShare)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:appStateSyncKeyShare, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_appStateSyncKeyRequest(acc, msg) do
        try do
          case msg.appStateSyncKeyRequest do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_message(msg.appStateSyncKeyRequest)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:appStateSyncKeyRequest, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_initialSecurityNotificationSettingSync(acc, msg) do
        try do
          case msg.initialSecurityNotificationSettingSync do
            nil ->
              acc

            _ ->
              [acc, "J", Protox.Encode.encode_message(msg.initialSecurityNotificationSettingSync)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :initialSecurityNotificationSettingSync,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_appStateFatalExceptionNotification(acc, msg) do
        try do
          case msg.appStateFatalExceptionNotification do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_message(msg.appStateFatalExceptionNotification)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :appStateFatalExceptionNotification,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_disappearingMode(acc, msg) do
        try do
          case msg.disappearingMode do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_message(msg.disappearingMode)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:disappearingMode, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_editedMessage(acc, msg) do
        try do
          case msg.editedMessage do
            nil -> acc
            _ -> [acc, "r", Protox.Encode.encode_message(msg.editedMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:editedMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_timestampMS(acc, msg) do
        try do
          case msg.timestampMS do
            nil -> acc
            _ -> [acc, "x", Protox.Encode.encode_int64(msg.timestampMS)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:timestampMS, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_peerDataOperationRequestMessage(acc, msg) do
        try do
          case msg.peerDataOperationRequestMessage do
            nil ->
              acc

            _ ->
              [acc, "\x82\x01", Protox.Encode.encode_message(msg.peerDataOperationRequestMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :peerDataOperationRequestMessage,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_peerDataOperationRequestResponseMessage(acc, msg) do
        try do
          case msg.peerDataOperationRequestResponseMessage do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x8A\x01",
                Protox.Encode.encode_message(msg.peerDataOperationRequestResponseMessage)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :peerDataOperationRequestResponseMessage,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_botFeedbackMessage(acc, msg) do
        try do
          case msg.botFeedbackMessage do
            nil -> acc
            _ -> [acc, "\x92\x01", Protox.Encode.encode_message(msg.botFeedbackMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botFeedbackMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_invokerJID(acc, msg) do
        try do
          case msg.invokerJID do
            nil -> acc
            _ -> [acc, "\x9A\x01", Protox.Encode.encode_string(msg.invokerJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:invokerJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_requestWelcomeMessageMetadata(acc, msg) do
        try do
          case msg.requestWelcomeMessageMetadata do
            nil ->
              acc

            _ ->
              [acc, "\xA2\x01", Protox.Encode.encode_message(msg.requestWelcomeMessageMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :requestWelcomeMessageMetadata,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_mediaNotifyMessage(acc, msg) do
        try do
          case msg.mediaNotifyMessage do
            nil -> acc
            _ -> [acc, "\xAA\x01", Protox.Encode.encode_message(msg.mediaNotifyMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaNotifyMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_cloudApiThreadControlNotification(acc, msg) do
        try do
          case msg.cloudApiThreadControlNotification do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xB2\x01",
                Protox.Encode.encode_message(msg.cloudApiThreadControlNotification)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :cloudApiThreadControlNotification,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_lidMigrationMappingSyncMessage(acc, msg) do
        try do
          case msg.lidMigrationMappingSyncMessage do
            nil ->
              acc

            _ ->
              [acc, "\xBA\x01", Protox.Encode.encode_message(msg.lidMigrationMappingSyncMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :lidMigrationMappingSyncMessage,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_limitSharing(acc, msg) do
        try do
          case msg.limitSharing do
            nil -> acc
            _ -> [acc, "\xC2\x01", Protox.Encode.encode_message(msg.limitSharing)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:limitSharing, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_aiPsiMetadata(acc, msg) do
        try do
          case msg.aiPsiMetadata do
            nil -> acc
            _ -> [acc, "\xCA\x01", Protox.Encode.encode_bytes(msg.aiPsiMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:aiPsiMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_aiQueryFanout(acc, msg) do
        try do
          case msg.aiQueryFanout do
            nil -> acc
            _ -> [acc, "\xD2\x01", Protox.Encode.encode_message(msg.aiQueryFanout)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:aiQueryFanout, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_memberLabel(acc, msg) do
        try do
          case msg.memberLabel do
            nil -> acc
            _ -> [acc, "\xDA\x01", Protox.Encode.encode_message(msg.memberLabel)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:memberLabel, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_aiMediaCollectionMessage(acc, msg) do
        try do
          case msg.aiMediaCollectionMessage do
            nil -> acc
            _ -> [acc, "\xE2\x01", Protox.Encode.encode_message(msg.aiMediaCollectionMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:aiMediaCollectionMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_afterReadDuration(acc, msg) do
        try do
          case msg.afterReadDuration do
            nil -> acc
            _ -> [acc, "\xE8\x01", Protox.Encode.encode_uint32(msg.afterReadDuration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:afterReadDuration, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_chatThemeSetting(acc, msg) do
        try do
          case msg.chatThemeSetting do
            nil -> acc
            _ -> [acc, "\xF2\x01", Protox.Encode.encode_message(msg.chatThemeSetting)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:chatThemeSetting, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_aiMetadataOperation(acc, msg) do
        try do
          case msg.aiMetadataOperation do
            nil -> acc
            _ -> [acc, "\xFA\x01", Protox.Encode.encode_message(msg.aiMetadataOperation)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:aiMetadataOperation, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_markAsVerifiedAction(acc, msg) do
        try do
          case msg.markAsVerifiedAction do
            nil -> acc
            _ -> [acc, "\x82\x02", Protox.Encode.encode_message(msg.markAsVerifiedAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:markAsVerifiedAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_coexStateSync(acc, msg) do
        try do
          case msg.coexStateSync do
            nil -> acc
            _ -> [acc, "\x8A\x02", Protox.Encode.encode_message(msg.coexStateSync)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:coexStateSync, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_syncRequestMutationRetry(acc, msg) do
        try do
          case msg.syncRequestMutationRetry do
            nil -> acc
            _ -> [acc, "\x92\x02", Protox.Encode.encode_message(msg.syncRequestMutationRetry)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:syncRequestMutationRetry, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.ProtocolMessage))
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

              {[key: Protox.MergeMessage.merge(msg.key, WACommon.MessageKey.decode!(delimited))],
               rest}

            {2, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.ProtocolMessage.Type)

              {[type: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[ephemeralExpiration: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[ephemeralSettingTimestamp: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 historySyncNotification:
                   Protox.MergeMessage.merge(
                     msg.historySyncNotification,
                     WAWebProtobufsE2E.HistorySyncNotification.decode!(delimited)
                   )
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 appStateSyncKeyShare:
                   Protox.MergeMessage.merge(
                     msg.appStateSyncKeyShare,
                     WAWebProtobufsE2E.AppStateSyncKeyShare.decode!(delimited)
                   )
               ], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 appStateSyncKeyRequest:
                   Protox.MergeMessage.merge(
                     msg.appStateSyncKeyRequest,
                     WAWebProtobufsE2E.AppStateSyncKeyRequest.decode!(delimited)
                   )
               ], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 initialSecurityNotificationSettingSync:
                   Protox.MergeMessage.merge(
                     msg.initialSecurityNotificationSettingSync,
                     WAWebProtobufsE2E.InitialSecurityNotificationSettingSync.decode!(delimited)
                   )
               ], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 appStateFatalExceptionNotification:
                   Protox.MergeMessage.merge(
                     msg.appStateFatalExceptionNotification,
                     WAWebProtobufsE2E.AppStateFatalExceptionNotification.decode!(delimited)
                   )
               ], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 disappearingMode:
                   Protox.MergeMessage.merge(
                     msg.disappearingMode,
                     WAWebProtobufsE2E.DisappearingMode.decode!(delimited)
                   )
               ], rest}

            {14, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 editedMessage:
                   Protox.MergeMessage.merge(
                     msg.editedMessage,
                     WAWebProtobufsE2E.Message.decode!(delimited)
                   )
               ], rest}

            {15, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[timestampMS: value], rest}

            {16, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 peerDataOperationRequestMessage:
                   Protox.MergeMessage.merge(
                     msg.peerDataOperationRequestMessage,
                     WAWebProtobufsE2E.PeerDataOperationRequestMessage.decode!(delimited)
                   )
               ], rest}

            {17, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 peerDataOperationRequestResponseMessage:
                   Protox.MergeMessage.merge(
                     msg.peerDataOperationRequestResponseMessage,
                     WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.decode!(delimited)
                   )
               ], rest}

            {18, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botFeedbackMessage:
                   Protox.MergeMessage.merge(
                     msg.botFeedbackMessage,
                     WAWebProtobufsAICommon.BotFeedbackMessage.decode!(delimited)
                   )
               ], rest}

            {19, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[invokerJID: Protox.Decode.validate_string!(delimited)], rest}

            {20, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 requestWelcomeMessageMetadata:
                   Protox.MergeMessage.merge(
                     msg.requestWelcomeMessageMetadata,
                     WAWebProtobufsE2E.RequestWelcomeMessageMetadata.decode!(delimited)
                   )
               ], rest}

            {21, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 mediaNotifyMessage:
                   Protox.MergeMessage.merge(
                     msg.mediaNotifyMessage,
                     WAWebProtobufsE2E.MediaNotifyMessage.decode!(delimited)
                   )
               ], rest}

            {22, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 cloudApiThreadControlNotification:
                   Protox.MergeMessage.merge(
                     msg.cloudApiThreadControlNotification,
                     WAWebProtobufsE2E.CloudAPIThreadControlNotification.decode!(delimited)
                   )
               ], rest}

            {23, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 lidMigrationMappingSyncMessage:
                   Protox.MergeMessage.merge(
                     msg.lidMigrationMappingSyncMessage,
                     WAWebProtobufsE2E.LIDMigrationMappingSyncMessage.decode!(delimited)
                   )
               ], rest}

            {24, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 limitSharing:
                   Protox.MergeMessage.merge(
                     msg.limitSharing,
                     WACommon.LimitSharing.decode!(delimited)
                   )
               ], rest}

            {25, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[aiPsiMetadata: delimited], rest}

            {26, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 aiQueryFanout:
                   Protox.MergeMessage.merge(
                     msg.aiQueryFanout,
                     WAWebProtobufsE2E.AIQueryFanout.decode!(delimited)
                   )
               ], rest}

            {27, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 memberLabel:
                   Protox.MergeMessage.merge(
                     msg.memberLabel,
                     WAWebProtobufsE2E.MemberLabel.decode!(delimited)
                   )
               ], rest}

            {28, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 aiMediaCollectionMessage:
                   Protox.MergeMessage.merge(
                     msg.aiMediaCollectionMessage,
                     WAWebProtobufsAICommon.AIMediaCollectionMessage.decode!(delimited)
                   )
               ], rest}

            {29, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[afterReadDuration: value], rest}

            {30, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 chatThemeSetting:
                   Protox.MergeMessage.merge(
                     msg.chatThemeSetting,
                     WAWebProtobufsE2E.ChatThemeSetting.decode!(delimited)
                   )
               ], rest}

            {31, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 aiMetadataOperation:
                   Protox.MergeMessage.merge(
                     msg.aiMetadataOperation,
                     WAWebProtobufsAICommon.AIMetadataOperation.decode!(delimited)
                   )
               ], rest}

            {32, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 markAsVerifiedAction:
                   Protox.MergeMessage.merge(
                     msg.markAsVerifiedAction,
                     WAWebProtobufsE2E.MarkAsVerifiedAction.decode!(delimited)
                   )
               ], rest}

            {33, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 coexStateSync:
                   Protox.MergeMessage.merge(
                     msg.coexStateSync,
                     WAWebProtobufsServerSync.CoexStateSync.decode!(delimited)
                   )
               ], rest}

            {34, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 syncRequestMutationRetry:
                   Protox.MergeMessage.merge(
                     msg.syncRequestMutationRetry,
                     WAWebProtobufsE2E.SyncRequestMutationRetry.decode!(delimited)
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
        WAWebProtobufsE2E.ProtocolMessage,
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
        2 => {:type, {:scalar, :REVOKE}, {:enum, WAWebProtobufsE2E.ProtocolMessage.Type}},
        4 => {:ephemeralExpiration, {:scalar, 0}, :uint32},
        5 => {:ephemeralSettingTimestamp, {:scalar, 0}, :int64},
        6 =>
          {:historySyncNotification, {:scalar, nil},
           {:message, WAWebProtobufsE2E.HistorySyncNotification}},
        7 =>
          {:appStateSyncKeyShare, {:scalar, nil},
           {:message, WAWebProtobufsE2E.AppStateSyncKeyShare}},
        8 =>
          {:appStateSyncKeyRequest, {:scalar, nil},
           {:message, WAWebProtobufsE2E.AppStateSyncKeyRequest}},
        9 =>
          {:initialSecurityNotificationSettingSync, {:scalar, nil},
           {:message, WAWebProtobufsE2E.InitialSecurityNotificationSettingSync}},
        10 =>
          {:appStateFatalExceptionNotification, {:scalar, nil},
           {:message, WAWebProtobufsE2E.AppStateFatalExceptionNotification}},
        11 => {:disappearingMode, {:scalar, nil}, {:message, WAWebProtobufsE2E.DisappearingMode}},
        14 => {:editedMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.Message}},
        15 => {:timestampMS, {:scalar, 0}, :int64},
        16 =>
          {:peerDataOperationRequestMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage}},
        17 =>
          {:peerDataOperationRequestResponseMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage}},
        18 =>
          {:botFeedbackMessage, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.BotFeedbackMessage}},
        19 => {:invokerJID, {:scalar, ""}, :string},
        20 =>
          {:requestWelcomeMessageMetadata, {:scalar, nil},
           {:message, WAWebProtobufsE2E.RequestWelcomeMessageMetadata}},
        21 =>
          {:mediaNotifyMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.MediaNotifyMessage}},
        22 =>
          {:cloudApiThreadControlNotification, {:scalar, nil},
           {:message, WAWebProtobufsE2E.CloudAPIThreadControlNotification}},
        23 =>
          {:lidMigrationMappingSyncMessage, {:scalar, nil},
           {:message, WAWebProtobufsE2E.LIDMigrationMappingSyncMessage}},
        24 => {:limitSharing, {:scalar, nil}, {:message, WACommon.LimitSharing}},
        25 => {:aiPsiMetadata, {:scalar, ""}, :bytes},
        26 => {:aiQueryFanout, {:scalar, nil}, {:message, WAWebProtobufsE2E.AIQueryFanout}},
        27 => {:memberLabel, {:scalar, nil}, {:message, WAWebProtobufsE2E.MemberLabel}},
        28 =>
          {:aiMediaCollectionMessage, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.AIMediaCollectionMessage}},
        29 => {:afterReadDuration, {:scalar, 0}, :uint32},
        30 => {:chatThemeSetting, {:scalar, nil}, {:message, WAWebProtobufsE2E.ChatThemeSetting}},
        31 =>
          {:aiMetadataOperation, {:scalar, nil},
           {:message, WAWebProtobufsAICommon.AIMetadataOperation}},
        32 =>
          {:markAsVerifiedAction, {:scalar, nil},
           {:message, WAWebProtobufsE2E.MarkAsVerifiedAction}},
        33 =>
          {:coexStateSync, {:scalar, nil}, {:message, WAWebProtobufsServerSync.CoexStateSync}},
        34 =>
          {:syncRequestMutationRetry, {:scalar, nil},
           {:message, WAWebProtobufsE2E.SyncRequestMutationRetry}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        afterReadDuration: {29, {:scalar, 0}, :uint32},
        aiMediaCollectionMessage:
          {28, {:scalar, nil}, {:message, WAWebProtobufsAICommon.AIMediaCollectionMessage}},
        aiMetadataOperation:
          {31, {:scalar, nil}, {:message, WAWebProtobufsAICommon.AIMetadataOperation}},
        aiPsiMetadata: {25, {:scalar, ""}, :bytes},
        aiQueryFanout: {26, {:scalar, nil}, {:message, WAWebProtobufsE2E.AIQueryFanout}},
        appStateFatalExceptionNotification:
          {10, {:scalar, nil}, {:message, WAWebProtobufsE2E.AppStateFatalExceptionNotification}},
        appStateSyncKeyRequest:
          {8, {:scalar, nil}, {:message, WAWebProtobufsE2E.AppStateSyncKeyRequest}},
        appStateSyncKeyShare:
          {7, {:scalar, nil}, {:message, WAWebProtobufsE2E.AppStateSyncKeyShare}},
        botFeedbackMessage:
          {18, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotFeedbackMessage}},
        chatThemeSetting: {30, {:scalar, nil}, {:message, WAWebProtobufsE2E.ChatThemeSetting}},
        cloudApiThreadControlNotification:
          {22, {:scalar, nil}, {:message, WAWebProtobufsE2E.CloudAPIThreadControlNotification}},
        coexStateSync: {33, {:scalar, nil}, {:message, WAWebProtobufsServerSync.CoexStateSync}},
        disappearingMode: {11, {:scalar, nil}, {:message, WAWebProtobufsE2E.DisappearingMode}},
        editedMessage: {14, {:scalar, nil}, {:message, WAWebProtobufsE2E.Message}},
        ephemeralExpiration: {4, {:scalar, 0}, :uint32},
        ephemeralSettingTimestamp: {5, {:scalar, 0}, :int64},
        historySyncNotification:
          {6, {:scalar, nil}, {:message, WAWebProtobufsE2E.HistorySyncNotification}},
        initialSecurityNotificationSettingSync:
          {9, {:scalar, nil},
           {:message, WAWebProtobufsE2E.InitialSecurityNotificationSettingSync}},
        invokerJID: {19, {:scalar, ""}, :string},
        key: {1, {:scalar, nil}, {:message, WACommon.MessageKey}},
        lidMigrationMappingSyncMessage:
          {23, {:scalar, nil}, {:message, WAWebProtobufsE2E.LIDMigrationMappingSyncMessage}},
        limitSharing: {24, {:scalar, nil}, {:message, WACommon.LimitSharing}},
        markAsVerifiedAction:
          {32, {:scalar, nil}, {:message, WAWebProtobufsE2E.MarkAsVerifiedAction}},
        mediaNotifyMessage:
          {21, {:scalar, nil}, {:message, WAWebProtobufsE2E.MediaNotifyMessage}},
        memberLabel: {27, {:scalar, nil}, {:message, WAWebProtobufsE2E.MemberLabel}},
        peerDataOperationRequestMessage:
          {16, {:scalar, nil}, {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage}},
        peerDataOperationRequestResponseMessage:
          {17, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage}},
        requestWelcomeMessageMetadata:
          {20, {:scalar, nil}, {:message, WAWebProtobufsE2E.RequestWelcomeMessageMetadata}},
        syncRequestMutationRetry:
          {34, {:scalar, nil}, {:message, WAWebProtobufsE2E.SyncRequestMutationRetry}},
        timestampMS: {15, {:scalar, 0}, :int64},
        type: {2, {:scalar, :REVOKE}, {:enum, WAWebProtobufsE2E.ProtocolMessage.Type}}
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
          label: :optional,
          name: :key,
          tag: 1,
          type: {:message, WACommon.MessageKey}
        },
        %{
          __struct__: Protox.Field,
          json_name: "type",
          kind: {:scalar, :REVOKE},
          label: :optional,
          name: :type,
          tag: 2,
          type: {:enum, WAWebProtobufsE2E.ProtocolMessage.Type}
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeralExpiration",
          kind: {:scalar, 0},
          label: :optional,
          name: :ephemeralExpiration,
          tag: 4,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeralSettingTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :ephemeralSettingTimestamp,
          tag: 5,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "historySyncNotification",
          kind: {:scalar, nil},
          label: :optional,
          name: :historySyncNotification,
          tag: 6,
          type: {:message, WAWebProtobufsE2E.HistorySyncNotification}
        },
        %{
          __struct__: Protox.Field,
          json_name: "appStateSyncKeyShare",
          kind: {:scalar, nil},
          label: :optional,
          name: :appStateSyncKeyShare,
          tag: 7,
          type: {:message, WAWebProtobufsE2E.AppStateSyncKeyShare}
        },
        %{
          __struct__: Protox.Field,
          json_name: "appStateSyncKeyRequest",
          kind: {:scalar, nil},
          label: :optional,
          name: :appStateSyncKeyRequest,
          tag: 8,
          type: {:message, WAWebProtobufsE2E.AppStateSyncKeyRequest}
        },
        %{
          __struct__: Protox.Field,
          json_name: "initialSecurityNotificationSettingSync",
          kind: {:scalar, nil},
          label: :optional,
          name: :initialSecurityNotificationSettingSync,
          tag: 9,
          type: {:message, WAWebProtobufsE2E.InitialSecurityNotificationSettingSync}
        },
        %{
          __struct__: Protox.Field,
          json_name: "appStateFatalExceptionNotification",
          kind: {:scalar, nil},
          label: :optional,
          name: :appStateFatalExceptionNotification,
          tag: 10,
          type: {:message, WAWebProtobufsE2E.AppStateFatalExceptionNotification}
        },
        %{
          __struct__: Protox.Field,
          json_name: "disappearingMode",
          kind: {:scalar, nil},
          label: :optional,
          name: :disappearingMode,
          tag: 11,
          type: {:message, WAWebProtobufsE2E.DisappearingMode}
        },
        %{
          __struct__: Protox.Field,
          json_name: "editedMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :editedMessage,
          tag: 14,
          type: {:message, WAWebProtobufsE2E.Message}
        },
        %{
          __struct__: Protox.Field,
          json_name: "timestampMS",
          kind: {:scalar, 0},
          label: :optional,
          name: :timestampMS,
          tag: 15,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "peerDataOperationRequestMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :peerDataOperationRequestMessage,
          tag: 16,
          type: {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "peerDataOperationRequestResponseMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :peerDataOperationRequestResponseMessage,
          tag: 17,
          type: {:message, WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "botFeedbackMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :botFeedbackMessage,
          tag: 18,
          type: {:message, WAWebProtobufsAICommon.BotFeedbackMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "invokerJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :invokerJID,
          tag: 19,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "requestWelcomeMessageMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :requestWelcomeMessageMetadata,
          tag: 20,
          type: {:message, WAWebProtobufsE2E.RequestWelcomeMessageMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaNotifyMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :mediaNotifyMessage,
          tag: 21,
          type: {:message, WAWebProtobufsE2E.MediaNotifyMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "cloudApiThreadControlNotification",
          kind: {:scalar, nil},
          label: :optional,
          name: :cloudApiThreadControlNotification,
          tag: 22,
          type: {:message, WAWebProtobufsE2E.CloudAPIThreadControlNotification}
        },
        %{
          __struct__: Protox.Field,
          json_name: "lidMigrationMappingSyncMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :lidMigrationMappingSyncMessage,
          tag: 23,
          type: {:message, WAWebProtobufsE2E.LIDMigrationMappingSyncMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "limitSharing",
          kind: {:scalar, nil},
          label: :optional,
          name: :limitSharing,
          tag: 24,
          type: {:message, WACommon.LimitSharing}
        },
        %{
          __struct__: Protox.Field,
          json_name: "aiPsiMetadata",
          kind: {:scalar, ""},
          label: :optional,
          name: :aiPsiMetadata,
          tag: 25,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "aiQueryFanout",
          kind: {:scalar, nil},
          label: :optional,
          name: :aiQueryFanout,
          tag: 26,
          type: {:message, WAWebProtobufsE2E.AIQueryFanout}
        },
        %{
          __struct__: Protox.Field,
          json_name: "memberLabel",
          kind: {:scalar, nil},
          label: :optional,
          name: :memberLabel,
          tag: 27,
          type: {:message, WAWebProtobufsE2E.MemberLabel}
        },
        %{
          __struct__: Protox.Field,
          json_name: "aiMediaCollectionMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :aiMediaCollectionMessage,
          tag: 28,
          type: {:message, WAWebProtobufsAICommon.AIMediaCollectionMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "afterReadDuration",
          kind: {:scalar, 0},
          label: :optional,
          name: :afterReadDuration,
          tag: 29,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "chatThemeSetting",
          kind: {:scalar, nil},
          label: :optional,
          name: :chatThemeSetting,
          tag: 30,
          type: {:message, WAWebProtobufsE2E.ChatThemeSetting}
        },
        %{
          __struct__: Protox.Field,
          json_name: "aiMetadataOperation",
          kind: {:scalar, nil},
          label: :optional,
          name: :aiMetadataOperation,
          tag: 31,
          type: {:message, WAWebProtobufsAICommon.AIMetadataOperation}
        },
        %{
          __struct__: Protox.Field,
          json_name: "markAsVerifiedAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :markAsVerifiedAction,
          tag: 32,
          type: {:message, WAWebProtobufsE2E.MarkAsVerifiedAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "coexStateSync",
          kind: {:scalar, nil},
          label: :optional,
          name: :coexStateSync,
          tag: 33,
          type: {:message, WAWebProtobufsServerSync.CoexStateSync}
        },
        %{
          __struct__: Protox.Field,
          json_name: "syncRequestMutationRetry",
          kind: {:scalar, nil},
          label: :optional,
          name: :syncRequestMutationRetry,
          tag: 34,
          type: {:message, WAWebProtobufsE2E.SyncRequestMutationRetry}
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
             label: :optional,
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
             label: :optional,
             name: :key,
             tag: 1,
             type: {:message, WACommon.MessageKey}
           }}
        end

        []
      ),
      (
        def field_def(:type) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "type",
             kind: {:scalar, :REVOKE},
             label: :optional,
             name: :type,
             tag: 2,
             type: {:enum, WAWebProtobufsE2E.ProtocolMessage.Type}
           }}
        end

        def field_def("type") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "type",
             kind: {:scalar, :REVOKE},
             label: :optional,
             name: :type,
             tag: 2,
             type: {:enum, WAWebProtobufsE2E.ProtocolMessage.Type}
           }}
        end

        []
      ),
      (
        def field_def(:ephemeralExpiration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralExpiration",
             kind: {:scalar, 0},
             label: :optional,
             name: :ephemeralExpiration,
             tag: 4,
             type: :uint32
           }}
        end

        def field_def("ephemeralExpiration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralExpiration",
             kind: {:scalar, 0},
             label: :optional,
             name: :ephemeralExpiration,
             tag: 4,
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
             tag: 5,
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
             tag: 5,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:historySyncNotification) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "historySyncNotification",
             kind: {:scalar, nil},
             label: :optional,
             name: :historySyncNotification,
             tag: 6,
             type: {:message, WAWebProtobufsE2E.HistorySyncNotification}
           }}
        end

        def field_def("historySyncNotification") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "historySyncNotification",
             kind: {:scalar, nil},
             label: :optional,
             name: :historySyncNotification,
             tag: 6,
             type: {:message, WAWebProtobufsE2E.HistorySyncNotification}
           }}
        end

        []
      ),
      (
        def field_def(:appStateSyncKeyShare) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "appStateSyncKeyShare",
             kind: {:scalar, nil},
             label: :optional,
             name: :appStateSyncKeyShare,
             tag: 7,
             type: {:message, WAWebProtobufsE2E.AppStateSyncKeyShare}
           }}
        end

        def field_def("appStateSyncKeyShare") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "appStateSyncKeyShare",
             kind: {:scalar, nil},
             label: :optional,
             name: :appStateSyncKeyShare,
             tag: 7,
             type: {:message, WAWebProtobufsE2E.AppStateSyncKeyShare}
           }}
        end

        []
      ),
      (
        def field_def(:appStateSyncKeyRequest) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "appStateSyncKeyRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :appStateSyncKeyRequest,
             tag: 8,
             type: {:message, WAWebProtobufsE2E.AppStateSyncKeyRequest}
           }}
        end

        def field_def("appStateSyncKeyRequest") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "appStateSyncKeyRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :appStateSyncKeyRequest,
             tag: 8,
             type: {:message, WAWebProtobufsE2E.AppStateSyncKeyRequest}
           }}
        end

        []
      ),
      (
        def field_def(:initialSecurityNotificationSettingSync) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "initialSecurityNotificationSettingSync",
             kind: {:scalar, nil},
             label: :optional,
             name: :initialSecurityNotificationSettingSync,
             tag: 9,
             type: {:message, WAWebProtobufsE2E.InitialSecurityNotificationSettingSync}
           }}
        end

        def field_def("initialSecurityNotificationSettingSync") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "initialSecurityNotificationSettingSync",
             kind: {:scalar, nil},
             label: :optional,
             name: :initialSecurityNotificationSettingSync,
             tag: 9,
             type: {:message, WAWebProtobufsE2E.InitialSecurityNotificationSettingSync}
           }}
        end

        []
      ),
      (
        def field_def(:appStateFatalExceptionNotification) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "appStateFatalExceptionNotification",
             kind: {:scalar, nil},
             label: :optional,
             name: :appStateFatalExceptionNotification,
             tag: 10,
             type: {:message, WAWebProtobufsE2E.AppStateFatalExceptionNotification}
           }}
        end

        def field_def("appStateFatalExceptionNotification") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "appStateFatalExceptionNotification",
             kind: {:scalar, nil},
             label: :optional,
             name: :appStateFatalExceptionNotification,
             tag: 10,
             type: {:message, WAWebProtobufsE2E.AppStateFatalExceptionNotification}
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
             tag: 11,
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
             tag: 11,
             type: {:message, WAWebProtobufsE2E.DisappearingMode}
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
             tag: 14,
             type: {:message, WAWebProtobufsE2E.Message}
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
             tag: 14,
             type: {:message, WAWebProtobufsE2E.Message}
           }}
        end

        []
      ),
      (
        def field_def(:timestampMS) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "timestampMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :timestampMS,
             tag: 15,
             type: :int64
           }}
        end

        def field_def("timestampMS") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "timestampMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :timestampMS,
             tag: 15,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:peerDataOperationRequestMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "peerDataOperationRequestMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :peerDataOperationRequestMessage,
             tag: 16,
             type: {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage}
           }}
        end

        def field_def("peerDataOperationRequestMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "peerDataOperationRequestMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :peerDataOperationRequestMessage,
             tag: 16,
             type: {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage}
           }}
        end

        []
      ),
      (
        def field_def(:peerDataOperationRequestResponseMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "peerDataOperationRequestResponseMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :peerDataOperationRequestResponseMessage,
             tag: 17,
             type: {:message, WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage}
           }}
        end

        def field_def("peerDataOperationRequestResponseMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "peerDataOperationRequestResponseMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :peerDataOperationRequestResponseMessage,
             tag: 17,
             type: {:message, WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage}
           }}
        end

        []
      ),
      (
        def field_def(:botFeedbackMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botFeedbackMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :botFeedbackMessage,
             tag: 18,
             type: {:message, WAWebProtobufsAICommon.BotFeedbackMessage}
           }}
        end

        def field_def("botFeedbackMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botFeedbackMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :botFeedbackMessage,
             tag: 18,
             type: {:message, WAWebProtobufsAICommon.BotFeedbackMessage}
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
             tag: 19,
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
             tag: 19,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:requestWelcomeMessageMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestWelcomeMessageMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :requestWelcomeMessageMetadata,
             tag: 20,
             type: {:message, WAWebProtobufsE2E.RequestWelcomeMessageMetadata}
           }}
        end

        def field_def("requestWelcomeMessageMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestWelcomeMessageMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :requestWelcomeMessageMetadata,
             tag: 20,
             type: {:message, WAWebProtobufsE2E.RequestWelcomeMessageMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:mediaNotifyMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaNotifyMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :mediaNotifyMessage,
             tag: 21,
             type: {:message, WAWebProtobufsE2E.MediaNotifyMessage}
           }}
        end

        def field_def("mediaNotifyMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaNotifyMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :mediaNotifyMessage,
             tag: 21,
             type: {:message, WAWebProtobufsE2E.MediaNotifyMessage}
           }}
        end

        []
      ),
      (
        def field_def(:cloudApiThreadControlNotification) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "cloudApiThreadControlNotification",
             kind: {:scalar, nil},
             label: :optional,
             name: :cloudApiThreadControlNotification,
             tag: 22,
             type: {:message, WAWebProtobufsE2E.CloudAPIThreadControlNotification}
           }}
        end

        def field_def("cloudApiThreadControlNotification") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "cloudApiThreadControlNotification",
             kind: {:scalar, nil},
             label: :optional,
             name: :cloudApiThreadControlNotification,
             tag: 22,
             type: {:message, WAWebProtobufsE2E.CloudAPIThreadControlNotification}
           }}
        end

        []
      ),
      (
        def field_def(:lidMigrationMappingSyncMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lidMigrationMappingSyncMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :lidMigrationMappingSyncMessage,
             tag: 23,
             type: {:message, WAWebProtobufsE2E.LIDMigrationMappingSyncMessage}
           }}
        end

        def field_def("lidMigrationMappingSyncMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lidMigrationMappingSyncMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :lidMigrationMappingSyncMessage,
             tag: 23,
             type: {:message, WAWebProtobufsE2E.LIDMigrationMappingSyncMessage}
           }}
        end

        []
      ),
      (
        def field_def(:limitSharing) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharing",
             kind: {:scalar, nil},
             label: :optional,
             name: :limitSharing,
             tag: 24,
             type: {:message, WACommon.LimitSharing}
           }}
        end

        def field_def("limitSharing") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharing",
             kind: {:scalar, nil},
             label: :optional,
             name: :limitSharing,
             tag: 24,
             type: {:message, WACommon.LimitSharing}
           }}
        end

        []
      ),
      (
        def field_def(:aiPsiMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiPsiMetadata",
             kind: {:scalar, ""},
             label: :optional,
             name: :aiPsiMetadata,
             tag: 25,
             type: :bytes
           }}
        end

        def field_def("aiPsiMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiPsiMetadata",
             kind: {:scalar, ""},
             label: :optional,
             name: :aiPsiMetadata,
             tag: 25,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:aiQueryFanout) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiQueryFanout",
             kind: {:scalar, nil},
             label: :optional,
             name: :aiQueryFanout,
             tag: 26,
             type: {:message, WAWebProtobufsE2E.AIQueryFanout}
           }}
        end

        def field_def("aiQueryFanout") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiQueryFanout",
             kind: {:scalar, nil},
             label: :optional,
             name: :aiQueryFanout,
             tag: 26,
             type: {:message, WAWebProtobufsE2E.AIQueryFanout}
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
             tag: 27,
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
             tag: 27,
             type: {:message, WAWebProtobufsE2E.MemberLabel}
           }}
        end

        []
      ),
      (
        def field_def(:aiMediaCollectionMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiMediaCollectionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :aiMediaCollectionMessage,
             tag: 28,
             type: {:message, WAWebProtobufsAICommon.AIMediaCollectionMessage}
           }}
        end

        def field_def("aiMediaCollectionMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiMediaCollectionMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :aiMediaCollectionMessage,
             tag: 28,
             type: {:message, WAWebProtobufsAICommon.AIMediaCollectionMessage}
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
             tag: 29,
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
             tag: 29,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:chatThemeSetting) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatThemeSetting",
             kind: {:scalar, nil},
             label: :optional,
             name: :chatThemeSetting,
             tag: 30,
             type: {:message, WAWebProtobufsE2E.ChatThemeSetting}
           }}
        end

        def field_def("chatThemeSetting") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatThemeSetting",
             kind: {:scalar, nil},
             label: :optional,
             name: :chatThemeSetting,
             tag: 30,
             type: {:message, WAWebProtobufsE2E.ChatThemeSetting}
           }}
        end

        []
      ),
      (
        def field_def(:aiMetadataOperation) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiMetadataOperation",
             kind: {:scalar, nil},
             label: :optional,
             name: :aiMetadataOperation,
             tag: 31,
             type: {:message, WAWebProtobufsAICommon.AIMetadataOperation}
           }}
        end

        def field_def("aiMetadataOperation") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiMetadataOperation",
             kind: {:scalar, nil},
             label: :optional,
             name: :aiMetadataOperation,
             tag: 31,
             type: {:message, WAWebProtobufsAICommon.AIMetadataOperation}
           }}
        end

        []
      ),
      (
        def field_def(:markAsVerifiedAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "markAsVerifiedAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :markAsVerifiedAction,
             tag: 32,
             type: {:message, WAWebProtobufsE2E.MarkAsVerifiedAction}
           }}
        end

        def field_def("markAsVerifiedAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "markAsVerifiedAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :markAsVerifiedAction,
             tag: 32,
             type: {:message, WAWebProtobufsE2E.MarkAsVerifiedAction}
           }}
        end

        []
      ),
      (
        def field_def(:coexStateSync) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "coexStateSync",
             kind: {:scalar, nil},
             label: :optional,
             name: :coexStateSync,
             tag: 33,
             type: {:message, WAWebProtobufsServerSync.CoexStateSync}
           }}
        end

        def field_def("coexStateSync") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "coexStateSync",
             kind: {:scalar, nil},
             label: :optional,
             name: :coexStateSync,
             tag: 33,
             type: {:message, WAWebProtobufsServerSync.CoexStateSync}
           }}
        end

        []
      ),
      (
        def field_def(:syncRequestMutationRetry) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "syncRequestMutationRetry",
             kind: {:scalar, nil},
             label: :optional,
             name: :syncRequestMutationRetry,
             tag: 34,
             type: {:message, WAWebProtobufsE2E.SyncRequestMutationRetry}
           }}
        end

        def field_def("syncRequestMutationRetry") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "syncRequestMutationRetry",
             kind: {:scalar, nil},
             label: :optional,
             name: :syncRequestMutationRetry,
             tag: 34,
             type: {:message, WAWebProtobufsE2E.SyncRequestMutationRetry}
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
    def default(:key) do
      {:ok, nil}
    end,
    def default(:type) do
      {:ok, :REVOKE}
    end,
    def default(:ephemeralExpiration) do
      {:ok, 0}
    end,
    def default(:ephemeralSettingTimestamp) do
      {:ok, 0}
    end,
    def default(:historySyncNotification) do
      {:ok, nil}
    end,
    def default(:appStateSyncKeyShare) do
      {:ok, nil}
    end,
    def default(:appStateSyncKeyRequest) do
      {:ok, nil}
    end,
    def default(:initialSecurityNotificationSettingSync) do
      {:ok, nil}
    end,
    def default(:appStateFatalExceptionNotification) do
      {:ok, nil}
    end,
    def default(:disappearingMode) do
      {:ok, nil}
    end,
    def default(:editedMessage) do
      {:ok, nil}
    end,
    def default(:timestampMS) do
      {:ok, 0}
    end,
    def default(:peerDataOperationRequestMessage) do
      {:ok, nil}
    end,
    def default(:peerDataOperationRequestResponseMessage) do
      {:ok, nil}
    end,
    def default(:botFeedbackMessage) do
      {:ok, nil}
    end,
    def default(:invokerJID) do
      {:ok, ""}
    end,
    def default(:requestWelcomeMessageMetadata) do
      {:ok, nil}
    end,
    def default(:mediaNotifyMessage) do
      {:ok, nil}
    end,
    def default(:cloudApiThreadControlNotification) do
      {:ok, nil}
    end,
    def default(:lidMigrationMappingSyncMessage) do
      {:ok, nil}
    end,
    def default(:limitSharing) do
      {:ok, nil}
    end,
    def default(:aiPsiMetadata) do
      {:ok, ""}
    end,
    def default(:aiQueryFanout) do
      {:ok, nil}
    end,
    def default(:memberLabel) do
      {:ok, nil}
    end,
    def default(:aiMediaCollectionMessage) do
      {:ok, nil}
    end,
    def default(:afterReadDuration) do
      {:ok, 0}
    end,
    def default(:chatThemeSetting) do
      {:ok, nil}
    end,
    def default(:aiMetadataOperation) do
      {:ok, nil}
    end,
    def default(:markAsVerifiedAction) do
      {:ok, nil}
    end,
    def default(:coexStateSync) do
      {:ok, nil}
    end,
    def default(:syncRequestMutationRetry) do
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

  @type t :: %__MODULE__{}
end
