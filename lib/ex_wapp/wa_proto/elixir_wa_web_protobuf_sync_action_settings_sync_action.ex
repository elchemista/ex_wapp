# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.SettingsSyncAction do
  @moduledoc false
  defstruct startAtLogin: nil,
            minimizeToTray: nil,
            language: nil,
            replaceTextWithEmoji: nil,
            bannerNotificationDisplayMode: nil,
            unreadCounterBadgeDisplayMode: nil,
            isMessagesNotificationEnabled: nil,
            isCallsNotificationEnabled: nil,
            isReactionsNotificationEnabled: nil,
            isStatusReactionsNotificationEnabled: nil,
            isTextPreviewForNotificationEnabled: nil,
            defaultNotificationToneID: nil,
            groupDefaultNotificationToneID: nil,
            appTheme: nil,
            wallpaperID: nil,
            isDoodleWallpaperEnabled: nil,
            fontSize: nil,
            isPhotosAutodownloadEnabled: nil,
            isAudiosAutodownloadEnabled: nil,
            isVideosAutodownloadEnabled: nil,
            isDocumentsAutodownloadEnabled: nil,
            disableLinkPreviews: nil,
            notificationToneID: nil,
            mediaUploadQuality: nil,
            isSpellCheckEnabled: nil,
            isEnterToSendEnabled: nil,
            isGroupMessageNotificationEnabled: nil,
            isGroupReactionsNotificationEnabled: nil,
            isStatusNotificationEnabled: nil,
            statusNotificationToneID: nil,
            shouldPlaySoundForCallNotification: nil,
            chatThemeID: nil,
            colorSchemeID: nil,
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
        |> encode_startAtLogin(msg)
        |> encode_minimizeToTray(msg)
        |> encode_language(msg)
        |> encode_replaceTextWithEmoji(msg)
        |> encode_bannerNotificationDisplayMode(msg)
        |> encode_unreadCounterBadgeDisplayMode(msg)
        |> encode_isMessagesNotificationEnabled(msg)
        |> encode_isCallsNotificationEnabled(msg)
        |> encode_isReactionsNotificationEnabled(msg)
        |> encode_isStatusReactionsNotificationEnabled(msg)
        |> encode_isTextPreviewForNotificationEnabled(msg)
        |> encode_defaultNotificationToneID(msg)
        |> encode_groupDefaultNotificationToneID(msg)
        |> encode_appTheme(msg)
        |> encode_wallpaperID(msg)
        |> encode_isDoodleWallpaperEnabled(msg)
        |> encode_fontSize(msg)
        |> encode_isPhotosAutodownloadEnabled(msg)
        |> encode_isAudiosAutodownloadEnabled(msg)
        |> encode_isVideosAutodownloadEnabled(msg)
        |> encode_isDocumentsAutodownloadEnabled(msg)
        |> encode_disableLinkPreviews(msg)
        |> encode_notificationToneID(msg)
        |> encode_mediaUploadQuality(msg)
        |> encode_isSpellCheckEnabled(msg)
        |> encode_isEnterToSendEnabled(msg)
        |> encode_isGroupMessageNotificationEnabled(msg)
        |> encode_isGroupReactionsNotificationEnabled(msg)
        |> encode_isStatusNotificationEnabled(msg)
        |> encode_statusNotificationToneID(msg)
        |> encode_shouldPlaySoundForCallNotification(msg)
        |> encode_chatThemeID(msg)
        |> encode_colorSchemeID(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_startAtLogin(acc, msg) do
        try do
          case msg.startAtLogin do
            nil -> acc
            _ -> [acc, "\b", Protox.Encode.encode_bool(msg.startAtLogin)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:startAtLogin, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_minimizeToTray(acc, msg) do
        try do
          case msg.minimizeToTray do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_bool(msg.minimizeToTray)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:minimizeToTray, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_language(acc, msg) do
        try do
          case msg.language do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.language)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:language, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_replaceTextWithEmoji(acc, msg) do
        try do
          case msg.replaceTextWithEmoji do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_bool(msg.replaceTextWithEmoji)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:replaceTextWithEmoji, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_bannerNotificationDisplayMode(acc, msg) do
        try do
          case msg.bannerNotificationDisplayMode do
            nil ->
              acc

            _ ->
              [
                acc,
                "(",
                msg.bannerNotificationDisplayMode
                |> WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :bannerNotificationDisplayMode,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_unreadCounterBadgeDisplayMode(acc, msg) do
        try do
          case msg.unreadCounterBadgeDisplayMode do
            nil ->
              acc

            _ ->
              [
                acc,
                "0",
                msg.unreadCounterBadgeDisplayMode
                |> WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :unreadCounterBadgeDisplayMode,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_isMessagesNotificationEnabled(acc, msg) do
        try do
          case msg.isMessagesNotificationEnabled do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_bool(msg.isMessagesNotificationEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :isMessagesNotificationEnabled,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_isCallsNotificationEnabled(acc, msg) do
        try do
          case msg.isCallsNotificationEnabled do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_bool(msg.isCallsNotificationEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isCallsNotificationEnabled, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isReactionsNotificationEnabled(acc, msg) do
        try do
          case msg.isReactionsNotificationEnabled do
            nil -> acc
            _ -> [acc, "H", Protox.Encode.encode_bool(msg.isReactionsNotificationEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :isReactionsNotificationEnabled,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_isStatusReactionsNotificationEnabled(acc, msg) do
        try do
          case msg.isStatusReactionsNotificationEnabled do
            nil -> acc
            _ -> [acc, "P", Protox.Encode.encode_bool(msg.isStatusReactionsNotificationEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :isStatusReactionsNotificationEnabled,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_isTextPreviewForNotificationEnabled(acc, msg) do
        try do
          case msg.isTextPreviewForNotificationEnabled do
            nil -> acc
            _ -> [acc, "X", Protox.Encode.encode_bool(msg.isTextPreviewForNotificationEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :isTextPreviewForNotificationEnabled,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_defaultNotificationToneID(acc, msg) do
        try do
          case msg.defaultNotificationToneID do
            nil -> acc
            _ -> [acc, "`", Protox.Encode.encode_int32(msg.defaultNotificationToneID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:defaultNotificationToneID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_groupDefaultNotificationToneID(acc, msg) do
        try do
          case msg.groupDefaultNotificationToneID do
            nil -> acc
            _ -> [acc, "h", Protox.Encode.encode_int32(msg.groupDefaultNotificationToneID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :groupDefaultNotificationToneID,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_appTheme(acc, msg) do
        try do
          case msg.appTheme do
            nil -> acc
            _ -> [acc, "p", Protox.Encode.encode_int32(msg.appTheme)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:appTheme, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_wallpaperID(acc, msg) do
        try do
          case msg.wallpaperID do
            nil -> acc
            _ -> [acc, "x", Protox.Encode.encode_int32(msg.wallpaperID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:wallpaperID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isDoodleWallpaperEnabled(acc, msg) do
        try do
          case msg.isDoodleWallpaperEnabled do
            nil -> acc
            _ -> [acc, "\x80\x01", Protox.Encode.encode_bool(msg.isDoodleWallpaperEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isDoodleWallpaperEnabled, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_fontSize(acc, msg) do
        try do
          case msg.fontSize do
            nil -> acc
            _ -> [acc, "\x88\x01", Protox.Encode.encode_int32(msg.fontSize)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fontSize, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isPhotosAutodownloadEnabled(acc, msg) do
        try do
          case msg.isPhotosAutodownloadEnabled do
            nil -> acc
            _ -> [acc, "\x90\x01", Protox.Encode.encode_bool(msg.isPhotosAutodownloadEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isPhotosAutodownloadEnabled, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isAudiosAutodownloadEnabled(acc, msg) do
        try do
          case msg.isAudiosAutodownloadEnabled do
            nil -> acc
            _ -> [acc, "\x98\x01", Protox.Encode.encode_bool(msg.isAudiosAutodownloadEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isAudiosAutodownloadEnabled, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isVideosAutodownloadEnabled(acc, msg) do
        try do
          case msg.isVideosAutodownloadEnabled do
            nil -> acc
            _ -> [acc, "\xA0\x01", Protox.Encode.encode_bool(msg.isVideosAutodownloadEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isVideosAutodownloadEnabled, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isDocumentsAutodownloadEnabled(acc, msg) do
        try do
          case msg.isDocumentsAutodownloadEnabled do
            nil -> acc
            _ -> [acc, "\xA8\x01", Protox.Encode.encode_bool(msg.isDocumentsAutodownloadEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :isDocumentsAutodownloadEnabled,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_disableLinkPreviews(acc, msg) do
        try do
          case msg.disableLinkPreviews do
            nil -> acc
            _ -> [acc, "\xB0\x01", Protox.Encode.encode_bool(msg.disableLinkPreviews)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:disableLinkPreviews, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_notificationToneID(acc, msg) do
        try do
          case msg.notificationToneID do
            nil -> acc
            _ -> [acc, "\xB8\x01", Protox.Encode.encode_int32(msg.notificationToneID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:notificationToneID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_mediaUploadQuality(acc, msg) do
        try do
          case msg.mediaUploadQuality do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xC0\x01",
                msg.mediaUploadQuality
                |> WAWebProtobufSyncAction.SettingsSyncAction.MediaQualitySetting.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaUploadQuality, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isSpellCheckEnabled(acc, msg) do
        try do
          case msg.isSpellCheckEnabled do
            nil -> acc
            _ -> [acc, "\xC8\x01", Protox.Encode.encode_bool(msg.isSpellCheckEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isSpellCheckEnabled, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isEnterToSendEnabled(acc, msg) do
        try do
          case msg.isEnterToSendEnabled do
            nil -> acc
            _ -> [acc, "\xD0\x01", Protox.Encode.encode_bool(msg.isEnterToSendEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isEnterToSendEnabled, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isGroupMessageNotificationEnabled(acc, msg) do
        try do
          case msg.isGroupMessageNotificationEnabled do
            nil ->
              acc

            _ ->
              [acc, "\xD8\x01", Protox.Encode.encode_bool(msg.isGroupMessageNotificationEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :isGroupMessageNotificationEnabled,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_isGroupReactionsNotificationEnabled(acc, msg) do
        try do
          case msg.isGroupReactionsNotificationEnabled do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xE0\x01",
                Protox.Encode.encode_bool(msg.isGroupReactionsNotificationEnabled)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :isGroupReactionsNotificationEnabled,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_isStatusNotificationEnabled(acc, msg) do
        try do
          case msg.isStatusNotificationEnabled do
            nil -> acc
            _ -> [acc, "\xE8\x01", Protox.Encode.encode_bool(msg.isStatusNotificationEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isStatusNotificationEnabled, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusNotificationToneID(acc, msg) do
        try do
          case msg.statusNotificationToneID do
            nil -> acc
            _ -> [acc, "\xF0\x01", Protox.Encode.encode_int32(msg.statusNotificationToneID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusNotificationToneID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_shouldPlaySoundForCallNotification(acc, msg) do
        try do
          case msg.shouldPlaySoundForCallNotification do
            nil ->
              acc

            _ ->
              [acc, "\xF8\x01", Protox.Encode.encode_bool(msg.shouldPlaySoundForCallNotification)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :shouldPlaySoundForCallNotification,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_chatThemeID(acc, msg) do
        try do
          case msg.chatThemeID do
            nil -> acc
            _ -> [acc, "\x82\x02", Protox.Encode.encode_string(msg.chatThemeID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:chatThemeID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_colorSchemeID(acc, msg) do
        try do
          case msg.colorSchemeID do
            nil -> acc
            _ -> [acc, "\x8A\x02", Protox.Encode.encode_string(msg.colorSchemeID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:colorSchemeID, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufSyncAction.SettingsSyncAction))
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
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[startAtLogin: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[minimizeToTray: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[language: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[replaceTextWithEmoji: value], rest}

            {5, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode
                )

              {[bannerNotificationDisplayMode: value], rest}

            {6, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode
                )

              {[unreadCounterBadgeDisplayMode: value], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isMessagesNotificationEnabled: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isCallsNotificationEnabled: value], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isReactionsNotificationEnabled: value], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isStatusReactionsNotificationEnabled: value], rest}

            {11, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isTextPreviewForNotificationEnabled: value], rest}

            {12, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[defaultNotificationToneID: value], rest}

            {13, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[groupDefaultNotificationToneID: value], rest}

            {14, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[appTheme: value], rest}

            {15, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[wallpaperID: value], rest}

            {16, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isDoodleWallpaperEnabled: value], rest}

            {17, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[fontSize: value], rest}

            {18, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isPhotosAutodownloadEnabled: value], rest}

            {19, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isAudiosAutodownloadEnabled: value], rest}

            {20, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isVideosAutodownloadEnabled: value], rest}

            {21, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isDocumentsAutodownloadEnabled: value], rest}

            {22, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[disableLinkPreviews: value], rest}

            {23, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[notificationToneID: value], rest}

            {24, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufSyncAction.SettingsSyncAction.MediaQualitySetting
                )

              {[mediaUploadQuality: value], rest}

            {25, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isSpellCheckEnabled: value], rest}

            {26, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isEnterToSendEnabled: value], rest}

            {27, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isGroupMessageNotificationEnabled: value], rest}

            {28, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isGroupReactionsNotificationEnabled: value], rest}

            {29, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isStatusNotificationEnabled: value], rest}

            {30, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[statusNotificationToneID: value], rest}

            {31, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[shouldPlaySoundForCallNotification: value], rest}

            {32, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[chatThemeID: Protox.Decode.validate_string!(delimited)], rest}

            {33, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[colorSchemeID: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufSyncAction.SettingsSyncAction,
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
        1 => {:startAtLogin, {:scalar, false}, :bool},
        2 => {:minimizeToTray, {:scalar, false}, :bool},
        3 => {:language, {:scalar, ""}, :string},
        4 => {:replaceTextWithEmoji, {:scalar, false}, :bool},
        5 =>
          {:bannerNotificationDisplayMode, {:scalar, :DISPLAY_MODE_UNKNOWN},
           {:enum, WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode}},
        6 =>
          {:unreadCounterBadgeDisplayMode, {:scalar, :DISPLAY_MODE_UNKNOWN},
           {:enum, WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode}},
        7 => {:isMessagesNotificationEnabled, {:scalar, false}, :bool},
        8 => {:isCallsNotificationEnabled, {:scalar, false}, :bool},
        9 => {:isReactionsNotificationEnabled, {:scalar, false}, :bool},
        10 => {:isStatusReactionsNotificationEnabled, {:scalar, false}, :bool},
        11 => {:isTextPreviewForNotificationEnabled, {:scalar, false}, :bool},
        12 => {:defaultNotificationToneID, {:scalar, 0}, :int32},
        13 => {:groupDefaultNotificationToneID, {:scalar, 0}, :int32},
        14 => {:appTheme, {:scalar, 0}, :int32},
        15 => {:wallpaperID, {:scalar, 0}, :int32},
        16 => {:isDoodleWallpaperEnabled, {:scalar, false}, :bool},
        17 => {:fontSize, {:scalar, 0}, :int32},
        18 => {:isPhotosAutodownloadEnabled, {:scalar, false}, :bool},
        19 => {:isAudiosAutodownloadEnabled, {:scalar, false}, :bool},
        20 => {:isVideosAutodownloadEnabled, {:scalar, false}, :bool},
        21 => {:isDocumentsAutodownloadEnabled, {:scalar, false}, :bool},
        22 => {:disableLinkPreviews, {:scalar, false}, :bool},
        23 => {:notificationToneID, {:scalar, 0}, :int32},
        24 =>
          {:mediaUploadQuality, {:scalar, :MEDIA_QUALITY_UNKNOWN},
           {:enum, WAWebProtobufSyncAction.SettingsSyncAction.MediaQualitySetting}},
        25 => {:isSpellCheckEnabled, {:scalar, false}, :bool},
        26 => {:isEnterToSendEnabled, {:scalar, false}, :bool},
        27 => {:isGroupMessageNotificationEnabled, {:scalar, false}, :bool},
        28 => {:isGroupReactionsNotificationEnabled, {:scalar, false}, :bool},
        29 => {:isStatusNotificationEnabled, {:scalar, false}, :bool},
        30 => {:statusNotificationToneID, {:scalar, 0}, :int32},
        31 => {:shouldPlaySoundForCallNotification, {:scalar, false}, :bool},
        32 => {:chatThemeID, {:scalar, ""}, :string},
        33 => {:colorSchemeID, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        appTheme: {14, {:scalar, 0}, :int32},
        bannerNotificationDisplayMode:
          {5, {:scalar, :DISPLAY_MODE_UNKNOWN},
           {:enum, WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode}},
        chatThemeID: {32, {:scalar, ""}, :string},
        colorSchemeID: {33, {:scalar, ""}, :string},
        defaultNotificationToneID: {12, {:scalar, 0}, :int32},
        disableLinkPreviews: {22, {:scalar, false}, :bool},
        fontSize: {17, {:scalar, 0}, :int32},
        groupDefaultNotificationToneID: {13, {:scalar, 0}, :int32},
        isAudiosAutodownloadEnabled: {19, {:scalar, false}, :bool},
        isCallsNotificationEnabled: {8, {:scalar, false}, :bool},
        isDocumentsAutodownloadEnabled: {21, {:scalar, false}, :bool},
        isDoodleWallpaperEnabled: {16, {:scalar, false}, :bool},
        isEnterToSendEnabled: {26, {:scalar, false}, :bool},
        isGroupMessageNotificationEnabled: {27, {:scalar, false}, :bool},
        isGroupReactionsNotificationEnabled: {28, {:scalar, false}, :bool},
        isMessagesNotificationEnabled: {7, {:scalar, false}, :bool},
        isPhotosAutodownloadEnabled: {18, {:scalar, false}, :bool},
        isReactionsNotificationEnabled: {9, {:scalar, false}, :bool},
        isSpellCheckEnabled: {25, {:scalar, false}, :bool},
        isStatusNotificationEnabled: {29, {:scalar, false}, :bool},
        isStatusReactionsNotificationEnabled: {10, {:scalar, false}, :bool},
        isTextPreviewForNotificationEnabled: {11, {:scalar, false}, :bool},
        isVideosAutodownloadEnabled: {20, {:scalar, false}, :bool},
        language: {3, {:scalar, ""}, :string},
        mediaUploadQuality:
          {24, {:scalar, :MEDIA_QUALITY_UNKNOWN},
           {:enum, WAWebProtobufSyncAction.SettingsSyncAction.MediaQualitySetting}},
        minimizeToTray: {2, {:scalar, false}, :bool},
        notificationToneID: {23, {:scalar, 0}, :int32},
        replaceTextWithEmoji: {4, {:scalar, false}, :bool},
        shouldPlaySoundForCallNotification: {31, {:scalar, false}, :bool},
        startAtLogin: {1, {:scalar, false}, :bool},
        statusNotificationToneID: {30, {:scalar, 0}, :int32},
        unreadCounterBadgeDisplayMode:
          {6, {:scalar, :DISPLAY_MODE_UNKNOWN},
           {:enum, WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode}},
        wallpaperID: {15, {:scalar, 0}, :int32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "startAtLogin",
          kind: {:scalar, false},
          label: :optional,
          name: :startAtLogin,
          tag: 1,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "minimizeToTray",
          kind: {:scalar, false},
          label: :optional,
          name: :minimizeToTray,
          tag: 2,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "language",
          kind: {:scalar, ""},
          label: :optional,
          name: :language,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "replaceTextWithEmoji",
          kind: {:scalar, false},
          label: :optional,
          name: :replaceTextWithEmoji,
          tag: 4,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "bannerNotificationDisplayMode",
          kind: {:scalar, :DISPLAY_MODE_UNKNOWN},
          label: :optional,
          name: :bannerNotificationDisplayMode,
          tag: 5,
          type: {:enum, WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode}
        },
        %{
          __struct__: Protox.Field,
          json_name: "unreadCounterBadgeDisplayMode",
          kind: {:scalar, :DISPLAY_MODE_UNKNOWN},
          label: :optional,
          name: :unreadCounterBadgeDisplayMode,
          tag: 6,
          type: {:enum, WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode}
        },
        %{
          __struct__: Protox.Field,
          json_name: "isMessagesNotificationEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isMessagesNotificationEnabled,
          tag: 7,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isCallsNotificationEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isCallsNotificationEnabled,
          tag: 8,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isReactionsNotificationEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isReactionsNotificationEnabled,
          tag: 9,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isStatusReactionsNotificationEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isStatusReactionsNotificationEnabled,
          tag: 10,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isTextPreviewForNotificationEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isTextPreviewForNotificationEnabled,
          tag: 11,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "defaultNotificationToneID",
          kind: {:scalar, 0},
          label: :optional,
          name: :defaultNotificationToneID,
          tag: 12,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupDefaultNotificationToneID",
          kind: {:scalar, 0},
          label: :optional,
          name: :groupDefaultNotificationToneID,
          tag: 13,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "appTheme",
          kind: {:scalar, 0},
          label: :optional,
          name: :appTheme,
          tag: 14,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "wallpaperID",
          kind: {:scalar, 0},
          label: :optional,
          name: :wallpaperID,
          tag: 15,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "isDoodleWallpaperEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isDoodleWallpaperEnabled,
          tag: 16,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "fontSize",
          kind: {:scalar, 0},
          label: :optional,
          name: :fontSize,
          tag: 17,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "isPhotosAutodownloadEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isPhotosAutodownloadEnabled,
          tag: 18,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isAudiosAutodownloadEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isAudiosAutodownloadEnabled,
          tag: 19,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isVideosAutodownloadEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isVideosAutodownloadEnabled,
          tag: 20,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isDocumentsAutodownloadEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isDocumentsAutodownloadEnabled,
          tag: 21,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "disableLinkPreviews",
          kind: {:scalar, false},
          label: :optional,
          name: :disableLinkPreviews,
          tag: 22,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "notificationToneID",
          kind: {:scalar, 0},
          label: :optional,
          name: :notificationToneID,
          tag: 23,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaUploadQuality",
          kind: {:scalar, :MEDIA_QUALITY_UNKNOWN},
          label: :optional,
          name: :mediaUploadQuality,
          tag: 24,
          type: {:enum, WAWebProtobufSyncAction.SettingsSyncAction.MediaQualitySetting}
        },
        %{
          __struct__: Protox.Field,
          json_name: "isSpellCheckEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isSpellCheckEnabled,
          tag: 25,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isEnterToSendEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isEnterToSendEnabled,
          tag: 26,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isGroupMessageNotificationEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isGroupMessageNotificationEnabled,
          tag: 27,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isGroupReactionsNotificationEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isGroupReactionsNotificationEnabled,
          tag: 28,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isStatusNotificationEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isStatusNotificationEnabled,
          tag: 29,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusNotificationToneID",
          kind: {:scalar, 0},
          label: :optional,
          name: :statusNotificationToneID,
          tag: 30,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "shouldPlaySoundForCallNotification",
          kind: {:scalar, false},
          label: :optional,
          name: :shouldPlaySoundForCallNotification,
          tag: 31,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "chatThemeID",
          kind: {:scalar, ""},
          label: :optional,
          name: :chatThemeID,
          tag: 32,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "colorSchemeID",
          kind: {:scalar, ""},
          label: :optional,
          name: :colorSchemeID,
          tag: 33,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:startAtLogin) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "startAtLogin",
             kind: {:scalar, false},
             label: :optional,
             name: :startAtLogin,
             tag: 1,
             type: :bool
           }}
        end

        def field_def("startAtLogin") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "startAtLogin",
             kind: {:scalar, false},
             label: :optional,
             name: :startAtLogin,
             tag: 1,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:minimizeToTray) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "minimizeToTray",
             kind: {:scalar, false},
             label: :optional,
             name: :minimizeToTray,
             tag: 2,
             type: :bool
           }}
        end

        def field_def("minimizeToTray") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "minimizeToTray",
             kind: {:scalar, false},
             label: :optional,
             name: :minimizeToTray,
             tag: 2,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:language) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "language",
             kind: {:scalar, ""},
             label: :optional,
             name: :language,
             tag: 3,
             type: :string
           }}
        end

        def field_def("language") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "language",
             kind: {:scalar, ""},
             label: :optional,
             name: :language,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:replaceTextWithEmoji) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "replaceTextWithEmoji",
             kind: {:scalar, false},
             label: :optional,
             name: :replaceTextWithEmoji,
             tag: 4,
             type: :bool
           }}
        end

        def field_def("replaceTextWithEmoji") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "replaceTextWithEmoji",
             kind: {:scalar, false},
             label: :optional,
             name: :replaceTextWithEmoji,
             tag: 4,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:bannerNotificationDisplayMode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bannerNotificationDisplayMode",
             kind: {:scalar, :DISPLAY_MODE_UNKNOWN},
             label: :optional,
             name: :bannerNotificationDisplayMode,
             tag: 5,
             type: {:enum, WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode}
           }}
        end

        def field_def("bannerNotificationDisplayMode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bannerNotificationDisplayMode",
             kind: {:scalar, :DISPLAY_MODE_UNKNOWN},
             label: :optional,
             name: :bannerNotificationDisplayMode,
             tag: 5,
             type: {:enum, WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode}
           }}
        end

        []
      ),
      (
        def field_def(:unreadCounterBadgeDisplayMode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "unreadCounterBadgeDisplayMode",
             kind: {:scalar, :DISPLAY_MODE_UNKNOWN},
             label: :optional,
             name: :unreadCounterBadgeDisplayMode,
             tag: 6,
             type: {:enum, WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode}
           }}
        end

        def field_def("unreadCounterBadgeDisplayMode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "unreadCounterBadgeDisplayMode",
             kind: {:scalar, :DISPLAY_MODE_UNKNOWN},
             label: :optional,
             name: :unreadCounterBadgeDisplayMode,
             tag: 6,
             type: {:enum, WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode}
           }}
        end

        []
      ),
      (
        def field_def(:isMessagesNotificationEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isMessagesNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isMessagesNotificationEnabled,
             tag: 7,
             type: :bool
           }}
        end

        def field_def("isMessagesNotificationEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isMessagesNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isMessagesNotificationEnabled,
             tag: 7,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isCallsNotificationEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isCallsNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isCallsNotificationEnabled,
             tag: 8,
             type: :bool
           }}
        end

        def field_def("isCallsNotificationEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isCallsNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isCallsNotificationEnabled,
             tag: 8,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isReactionsNotificationEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isReactionsNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isReactionsNotificationEnabled,
             tag: 9,
             type: :bool
           }}
        end

        def field_def("isReactionsNotificationEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isReactionsNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isReactionsNotificationEnabled,
             tag: 9,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isStatusReactionsNotificationEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isStatusReactionsNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isStatusReactionsNotificationEnabled,
             tag: 10,
             type: :bool
           }}
        end

        def field_def("isStatusReactionsNotificationEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isStatusReactionsNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isStatusReactionsNotificationEnabled,
             tag: 10,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isTextPreviewForNotificationEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isTextPreviewForNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isTextPreviewForNotificationEnabled,
             tag: 11,
             type: :bool
           }}
        end

        def field_def("isTextPreviewForNotificationEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isTextPreviewForNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isTextPreviewForNotificationEnabled,
             tag: 11,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:defaultNotificationToneID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "defaultNotificationToneID",
             kind: {:scalar, 0},
             label: :optional,
             name: :defaultNotificationToneID,
             tag: 12,
             type: :int32
           }}
        end

        def field_def("defaultNotificationToneID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "defaultNotificationToneID",
             kind: {:scalar, 0},
             label: :optional,
             name: :defaultNotificationToneID,
             tag: 12,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:groupDefaultNotificationToneID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupDefaultNotificationToneID",
             kind: {:scalar, 0},
             label: :optional,
             name: :groupDefaultNotificationToneID,
             tag: 13,
             type: :int32
           }}
        end

        def field_def("groupDefaultNotificationToneID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupDefaultNotificationToneID",
             kind: {:scalar, 0},
             label: :optional,
             name: :groupDefaultNotificationToneID,
             tag: 13,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:appTheme) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "appTheme",
             kind: {:scalar, 0},
             label: :optional,
             name: :appTheme,
             tag: 14,
             type: :int32
           }}
        end

        def field_def("appTheme") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "appTheme",
             kind: {:scalar, 0},
             label: :optional,
             name: :appTheme,
             tag: 14,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:wallpaperID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "wallpaperID",
             kind: {:scalar, 0},
             label: :optional,
             name: :wallpaperID,
             tag: 15,
             type: :int32
           }}
        end

        def field_def("wallpaperID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "wallpaperID",
             kind: {:scalar, 0},
             label: :optional,
             name: :wallpaperID,
             tag: 15,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:isDoodleWallpaperEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isDoodleWallpaperEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isDoodleWallpaperEnabled,
             tag: 16,
             type: :bool
           }}
        end

        def field_def("isDoodleWallpaperEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isDoodleWallpaperEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isDoodleWallpaperEnabled,
             tag: 16,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:fontSize) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fontSize",
             kind: {:scalar, 0},
             label: :optional,
             name: :fontSize,
             tag: 17,
             type: :int32
           }}
        end

        def field_def("fontSize") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fontSize",
             kind: {:scalar, 0},
             label: :optional,
             name: :fontSize,
             tag: 17,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:isPhotosAutodownloadEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isPhotosAutodownloadEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isPhotosAutodownloadEnabled,
             tag: 18,
             type: :bool
           }}
        end

        def field_def("isPhotosAutodownloadEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isPhotosAutodownloadEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isPhotosAutodownloadEnabled,
             tag: 18,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isAudiosAutodownloadEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isAudiosAutodownloadEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isAudiosAutodownloadEnabled,
             tag: 19,
             type: :bool
           }}
        end

        def field_def("isAudiosAutodownloadEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isAudiosAutodownloadEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isAudiosAutodownloadEnabled,
             tag: 19,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isVideosAutodownloadEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isVideosAutodownloadEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isVideosAutodownloadEnabled,
             tag: 20,
             type: :bool
           }}
        end

        def field_def("isVideosAutodownloadEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isVideosAutodownloadEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isVideosAutodownloadEnabled,
             tag: 20,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isDocumentsAutodownloadEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isDocumentsAutodownloadEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isDocumentsAutodownloadEnabled,
             tag: 21,
             type: :bool
           }}
        end

        def field_def("isDocumentsAutodownloadEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isDocumentsAutodownloadEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isDocumentsAutodownloadEnabled,
             tag: 21,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:disableLinkPreviews) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "disableLinkPreviews",
             kind: {:scalar, false},
             label: :optional,
             name: :disableLinkPreviews,
             tag: 22,
             type: :bool
           }}
        end

        def field_def("disableLinkPreviews") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "disableLinkPreviews",
             kind: {:scalar, false},
             label: :optional,
             name: :disableLinkPreviews,
             tag: 22,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:notificationToneID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "notificationToneID",
             kind: {:scalar, 0},
             label: :optional,
             name: :notificationToneID,
             tag: 23,
             type: :int32
           }}
        end

        def field_def("notificationToneID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "notificationToneID",
             kind: {:scalar, 0},
             label: :optional,
             name: :notificationToneID,
             tag: 23,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:mediaUploadQuality) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaUploadQuality",
             kind: {:scalar, :MEDIA_QUALITY_UNKNOWN},
             label: :optional,
             name: :mediaUploadQuality,
             tag: 24,
             type: {:enum, WAWebProtobufSyncAction.SettingsSyncAction.MediaQualitySetting}
           }}
        end

        def field_def("mediaUploadQuality") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaUploadQuality",
             kind: {:scalar, :MEDIA_QUALITY_UNKNOWN},
             label: :optional,
             name: :mediaUploadQuality,
             tag: 24,
             type: {:enum, WAWebProtobufSyncAction.SettingsSyncAction.MediaQualitySetting}
           }}
        end

        []
      ),
      (
        def field_def(:isSpellCheckEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSpellCheckEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isSpellCheckEnabled,
             tag: 25,
             type: :bool
           }}
        end

        def field_def("isSpellCheckEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSpellCheckEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isSpellCheckEnabled,
             tag: 25,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isEnterToSendEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isEnterToSendEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isEnterToSendEnabled,
             tag: 26,
             type: :bool
           }}
        end

        def field_def("isEnterToSendEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isEnterToSendEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isEnterToSendEnabled,
             tag: 26,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isGroupMessageNotificationEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isGroupMessageNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isGroupMessageNotificationEnabled,
             tag: 27,
             type: :bool
           }}
        end

        def field_def("isGroupMessageNotificationEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isGroupMessageNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isGroupMessageNotificationEnabled,
             tag: 27,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isGroupReactionsNotificationEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isGroupReactionsNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isGroupReactionsNotificationEnabled,
             tag: 28,
             type: :bool
           }}
        end

        def field_def("isGroupReactionsNotificationEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isGroupReactionsNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isGroupReactionsNotificationEnabled,
             tag: 28,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isStatusNotificationEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isStatusNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isStatusNotificationEnabled,
             tag: 29,
             type: :bool
           }}
        end

        def field_def("isStatusNotificationEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isStatusNotificationEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isStatusNotificationEnabled,
             tag: 29,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:statusNotificationToneID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusNotificationToneID",
             kind: {:scalar, 0},
             label: :optional,
             name: :statusNotificationToneID,
             tag: 30,
             type: :int32
           }}
        end

        def field_def("statusNotificationToneID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusNotificationToneID",
             kind: {:scalar, 0},
             label: :optional,
             name: :statusNotificationToneID,
             tag: 30,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:shouldPlaySoundForCallNotification) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shouldPlaySoundForCallNotification",
             kind: {:scalar, false},
             label: :optional,
             name: :shouldPlaySoundForCallNotification,
             tag: 31,
             type: :bool
           }}
        end

        def field_def("shouldPlaySoundForCallNotification") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shouldPlaySoundForCallNotification",
             kind: {:scalar, false},
             label: :optional,
             name: :shouldPlaySoundForCallNotification,
             tag: 31,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:chatThemeID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatThemeID",
             kind: {:scalar, ""},
             label: :optional,
             name: :chatThemeID,
             tag: 32,
             type: :string
           }}
        end

        def field_def("chatThemeID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatThemeID",
             kind: {:scalar, ""},
             label: :optional,
             name: :chatThemeID,
             tag: 32,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:colorSchemeID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "colorSchemeID",
             kind: {:scalar, ""},
             label: :optional,
             name: :colorSchemeID,
             tag: 33,
             type: :string
           }}
        end

        def field_def("colorSchemeID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "colorSchemeID",
             kind: {:scalar, ""},
             label: :optional,
             name: :colorSchemeID,
             tag: 33,
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
    def default(:startAtLogin) do
      {:ok, false}
    end,
    def default(:minimizeToTray) do
      {:ok, false}
    end,
    def default(:language) do
      {:ok, ""}
    end,
    def default(:replaceTextWithEmoji) do
      {:ok, false}
    end,
    def default(:bannerNotificationDisplayMode) do
      {:ok, :DISPLAY_MODE_UNKNOWN}
    end,
    def default(:unreadCounterBadgeDisplayMode) do
      {:ok, :DISPLAY_MODE_UNKNOWN}
    end,
    def default(:isMessagesNotificationEnabled) do
      {:ok, false}
    end,
    def default(:isCallsNotificationEnabled) do
      {:ok, false}
    end,
    def default(:isReactionsNotificationEnabled) do
      {:ok, false}
    end,
    def default(:isStatusReactionsNotificationEnabled) do
      {:ok, false}
    end,
    def default(:isTextPreviewForNotificationEnabled) do
      {:ok, false}
    end,
    def default(:defaultNotificationToneID) do
      {:ok, 0}
    end,
    def default(:groupDefaultNotificationToneID) do
      {:ok, 0}
    end,
    def default(:appTheme) do
      {:ok, 0}
    end,
    def default(:wallpaperID) do
      {:ok, 0}
    end,
    def default(:isDoodleWallpaperEnabled) do
      {:ok, false}
    end,
    def default(:fontSize) do
      {:ok, 0}
    end,
    def default(:isPhotosAutodownloadEnabled) do
      {:ok, false}
    end,
    def default(:isAudiosAutodownloadEnabled) do
      {:ok, false}
    end,
    def default(:isVideosAutodownloadEnabled) do
      {:ok, false}
    end,
    def default(:isDocumentsAutodownloadEnabled) do
      {:ok, false}
    end,
    def default(:disableLinkPreviews) do
      {:ok, false}
    end,
    def default(:notificationToneID) do
      {:ok, 0}
    end,
    def default(:mediaUploadQuality) do
      {:ok, :MEDIA_QUALITY_UNKNOWN}
    end,
    def default(:isSpellCheckEnabled) do
      {:ok, false}
    end,
    def default(:isEnterToSendEnabled) do
      {:ok, false}
    end,
    def default(:isGroupMessageNotificationEnabled) do
      {:ok, false}
    end,
    def default(:isGroupReactionsNotificationEnabled) do
      {:ok, false}
    end,
    def default(:isStatusNotificationEnabled) do
      {:ok, false}
    end,
    def default(:statusNotificationToneID) do
      {:ok, 0}
    end,
    def default(:shouldPlaySoundForCallNotification) do
      {:ok, false}
    end,
    def default(:chatThemeID) do
      {:ok, ""}
    end,
    def default(:colorSchemeID) do
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
