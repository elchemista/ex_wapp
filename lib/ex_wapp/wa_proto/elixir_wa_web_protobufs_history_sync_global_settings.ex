# credo:disable-for-this-file
defmodule WAWebProtobufsHistorySync.GlobalSettings do
  @moduledoc false
  defstruct lightThemeWallpaper: nil,
            mediaVisibility: nil,
            darkThemeWallpaper: nil,
            autoDownloadWiFi: nil,
            autoDownloadCellular: nil,
            autoDownloadRoaming: nil,
            showIndividualNotificationsPreview: nil,
            showGroupNotificationsPreview: nil,
            disappearingModeDuration: nil,
            disappearingModeTimestamp: nil,
            avatarUserSettings: nil,
            fontSize: nil,
            securityNotifications: nil,
            autoUnarchiveChats: nil,
            videoQualityMode: nil,
            photoQualityMode: nil,
            individualNotificationSettings: nil,
            groupNotificationSettings: nil,
            chatLockSettings: nil,
            chatDbLidMigrationTimestamp: nil,
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
        |> encode_lightThemeWallpaper(msg)
        |> encode_mediaVisibility(msg)
        |> encode_darkThemeWallpaper(msg)
        |> encode_autoDownloadWiFi(msg)
        |> encode_autoDownloadCellular(msg)
        |> encode_autoDownloadRoaming(msg)
        |> encode_showIndividualNotificationsPreview(msg)
        |> encode_showGroupNotificationsPreview(msg)
        |> encode_disappearingModeDuration(msg)
        |> encode_disappearingModeTimestamp(msg)
        |> encode_avatarUserSettings(msg)
        |> encode_fontSize(msg)
        |> encode_securityNotifications(msg)
        |> encode_autoUnarchiveChats(msg)
        |> encode_videoQualityMode(msg)
        |> encode_photoQualityMode(msg)
        |> encode_individualNotificationSettings(msg)
        |> encode_groupNotificationSettings(msg)
        |> encode_chatLockSettings(msg)
        |> encode_chatDbLidMigrationTimestamp(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_lightThemeWallpaper(acc, msg) do
        try do
          case msg.lightThemeWallpaper do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_message(msg.lightThemeWallpaper)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:lightThemeWallpaper, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_mediaVisibility(acc, msg) do
        try do
          case msg.mediaVisibility do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x10",
                msg.mediaVisibility
                |> WAWebProtobufsHistorySync.MediaVisibility.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaVisibility, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_darkThemeWallpaper(acc, msg) do
        try do
          case msg.darkThemeWallpaper do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_message(msg.darkThemeWallpaper)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:darkThemeWallpaper, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_autoDownloadWiFi(acc, msg) do
        try do
          case msg.autoDownloadWiFi do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_message(msg.autoDownloadWiFi)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:autoDownloadWiFi, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_autoDownloadCellular(acc, msg) do
        try do
          case msg.autoDownloadCellular do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_message(msg.autoDownloadCellular)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:autoDownloadCellular, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_autoDownloadRoaming(acc, msg) do
        try do
          case msg.autoDownloadRoaming do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_message(msg.autoDownloadRoaming)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:autoDownloadRoaming, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_showIndividualNotificationsPreview(acc, msg) do
        try do
          case msg.showIndividualNotificationsPreview do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_bool(msg.showIndividualNotificationsPreview)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :showIndividualNotificationsPreview,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_showGroupNotificationsPreview(acc, msg) do
        try do
          case msg.showGroupNotificationsPreview do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_bool(msg.showGroupNotificationsPreview)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :showGroupNotificationsPreview,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_disappearingModeDuration(acc, msg) do
        try do
          case msg.disappearingModeDuration do
            nil -> acc
            _ -> [acc, "H", Protox.Encode.encode_int32(msg.disappearingModeDuration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:disappearingModeDuration, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_disappearingModeTimestamp(acc, msg) do
        try do
          case msg.disappearingModeTimestamp do
            nil -> acc
            _ -> [acc, "P", Protox.Encode.encode_int64(msg.disappearingModeTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:disappearingModeTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_avatarUserSettings(acc, msg) do
        try do
          case msg.avatarUserSettings do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_message(msg.avatarUserSettings)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:avatarUserSettings, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_fontSize(acc, msg) do
        try do
          case msg.fontSize do
            nil -> acc
            _ -> [acc, "`", Protox.Encode.encode_int32(msg.fontSize)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fontSize, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_securityNotifications(acc, msg) do
        try do
          case msg.securityNotifications do
            nil -> acc
            _ -> [acc, "h", Protox.Encode.encode_bool(msg.securityNotifications)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:securityNotifications, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_autoUnarchiveChats(acc, msg) do
        try do
          case msg.autoUnarchiveChats do
            nil -> acc
            _ -> [acc, "p", Protox.Encode.encode_bool(msg.autoUnarchiveChats)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:autoUnarchiveChats, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_videoQualityMode(acc, msg) do
        try do
          case msg.videoQualityMode do
            nil -> acc
            _ -> [acc, "x", Protox.Encode.encode_int32(msg.videoQualityMode)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:videoQualityMode, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_photoQualityMode(acc, msg) do
        try do
          case msg.photoQualityMode do
            nil -> acc
            _ -> [acc, "\x80\x01", Protox.Encode.encode_int32(msg.photoQualityMode)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:photoQualityMode, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_individualNotificationSettings(acc, msg) do
        try do
          case msg.individualNotificationSettings do
            nil ->
              acc

            _ ->
              [acc, "\x8A\x01", Protox.Encode.encode_message(msg.individualNotificationSettings)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :individualNotificationSettings,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_groupNotificationSettings(acc, msg) do
        try do
          case msg.groupNotificationSettings do
            nil -> acc
            _ -> [acc, "\x92\x01", Protox.Encode.encode_message(msg.groupNotificationSettings)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupNotificationSettings, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_chatLockSettings(acc, msg) do
        try do
          case msg.chatLockSettings do
            nil -> acc
            _ -> [acc, "\x9A\x01", Protox.Encode.encode_message(msg.chatLockSettings)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:chatLockSettings, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_chatDbLidMigrationTimestamp(acc, msg) do
        try do
          case msg.chatDbLidMigrationTimestamp do
            nil -> acc
            _ -> [acc, "\xA0\x01", Protox.Encode.encode_int64(msg.chatDbLidMigrationTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:chatDbLidMigrationTimestamp, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsHistorySync.GlobalSettings))
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

              {[
                 lightThemeWallpaper:
                   Protox.MergeMessage.merge(
                     msg.lightThemeWallpaper,
                     WAWebProtobufsHistorySync.WallpaperSettings.decode!(delimited)
                   )
               ], rest}

            {2, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsHistorySync.MediaVisibility)

              {[mediaVisibility: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 darkThemeWallpaper:
                   Protox.MergeMessage.merge(
                     msg.darkThemeWallpaper,
                     WAWebProtobufsHistorySync.WallpaperSettings.decode!(delimited)
                   )
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 autoDownloadWiFi:
                   Protox.MergeMessage.merge(
                     msg.autoDownloadWiFi,
                     WAWebProtobufsHistorySync.AutoDownloadSettings.decode!(delimited)
                   )
               ], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 autoDownloadCellular:
                   Protox.MergeMessage.merge(
                     msg.autoDownloadCellular,
                     WAWebProtobufsHistorySync.AutoDownloadSettings.decode!(delimited)
                   )
               ], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 autoDownloadRoaming:
                   Protox.MergeMessage.merge(
                     msg.autoDownloadRoaming,
                     WAWebProtobufsHistorySync.AutoDownloadSettings.decode!(delimited)
                   )
               ], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[showIndividualNotificationsPreview: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[showGroupNotificationsPreview: value], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[disappearingModeDuration: value], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[disappearingModeTimestamp: value], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 avatarUserSettings:
                   Protox.MergeMessage.merge(
                     msg.avatarUserSettings,
                     WAWebProtobufsHistorySync.AvatarUserSettings.decode!(delimited)
                   )
               ], rest}

            {12, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[fontSize: value], rest}

            {13, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[securityNotifications: value], rest}

            {14, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[autoUnarchiveChats: value], rest}

            {15, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[videoQualityMode: value], rest}

            {16, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[photoQualityMode: value], rest}

            {17, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 individualNotificationSettings:
                   Protox.MergeMessage.merge(
                     msg.individualNotificationSettings,
                     WAWebProtobufsHistorySync.NotificationSettings.decode!(delimited)
                   )
               ], rest}

            {18, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 groupNotificationSettings:
                   Protox.MergeMessage.merge(
                     msg.groupNotificationSettings,
                     WAWebProtobufsHistorySync.NotificationSettings.decode!(delimited)
                   )
               ], rest}

            {19, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 chatLockSettings:
                   Protox.MergeMessage.merge(
                     msg.chatLockSettings,
                     WAWebProtobufsChatLockSettings.ChatLockSettings.decode!(delimited)
                   )
               ], rest}

            {20, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[chatDbLidMigrationTimestamp: value], rest}

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
        WAWebProtobufsHistorySync.GlobalSettings,
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
          {:lightThemeWallpaper, {:scalar, nil},
           {:message, WAWebProtobufsHistorySync.WallpaperSettings}},
        2 =>
          {:mediaVisibility, {:scalar, :DEFAULT},
           {:enum, WAWebProtobufsHistorySync.MediaVisibility}},
        3 =>
          {:darkThemeWallpaper, {:scalar, nil},
           {:message, WAWebProtobufsHistorySync.WallpaperSettings}},
        4 =>
          {:autoDownloadWiFi, {:scalar, nil},
           {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}},
        5 =>
          {:autoDownloadCellular, {:scalar, nil},
           {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}},
        6 =>
          {:autoDownloadRoaming, {:scalar, nil},
           {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}},
        7 => {:showIndividualNotificationsPreview, {:scalar, false}, :bool},
        8 => {:showGroupNotificationsPreview, {:scalar, false}, :bool},
        9 => {:disappearingModeDuration, {:scalar, 0}, :int32},
        10 => {:disappearingModeTimestamp, {:scalar, 0}, :int64},
        11 =>
          {:avatarUserSettings, {:scalar, nil},
           {:message, WAWebProtobufsHistorySync.AvatarUserSettings}},
        12 => {:fontSize, {:scalar, 0}, :int32},
        13 => {:securityNotifications, {:scalar, false}, :bool},
        14 => {:autoUnarchiveChats, {:scalar, false}, :bool},
        15 => {:videoQualityMode, {:scalar, 0}, :int32},
        16 => {:photoQualityMode, {:scalar, 0}, :int32},
        17 =>
          {:individualNotificationSettings, {:scalar, nil},
           {:message, WAWebProtobufsHistorySync.NotificationSettings}},
        18 =>
          {:groupNotificationSettings, {:scalar, nil},
           {:message, WAWebProtobufsHistorySync.NotificationSettings}},
        19 =>
          {:chatLockSettings, {:scalar, nil},
           {:message, WAWebProtobufsChatLockSettings.ChatLockSettings}},
        20 => {:chatDbLidMigrationTimestamp, {:scalar, 0}, :int64}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        autoDownloadCellular:
          {5, {:scalar, nil}, {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}},
        autoDownloadRoaming:
          {6, {:scalar, nil}, {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}},
        autoDownloadWiFi:
          {4, {:scalar, nil}, {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}},
        autoUnarchiveChats: {14, {:scalar, false}, :bool},
        avatarUserSettings:
          {11, {:scalar, nil}, {:message, WAWebProtobufsHistorySync.AvatarUserSettings}},
        chatDbLidMigrationTimestamp: {20, {:scalar, 0}, :int64},
        chatLockSettings:
          {19, {:scalar, nil}, {:message, WAWebProtobufsChatLockSettings.ChatLockSettings}},
        darkThemeWallpaper:
          {3, {:scalar, nil}, {:message, WAWebProtobufsHistorySync.WallpaperSettings}},
        disappearingModeDuration: {9, {:scalar, 0}, :int32},
        disappearingModeTimestamp: {10, {:scalar, 0}, :int64},
        fontSize: {12, {:scalar, 0}, :int32},
        groupNotificationSettings:
          {18, {:scalar, nil}, {:message, WAWebProtobufsHistorySync.NotificationSettings}},
        individualNotificationSettings:
          {17, {:scalar, nil}, {:message, WAWebProtobufsHistorySync.NotificationSettings}},
        lightThemeWallpaper:
          {1, {:scalar, nil}, {:message, WAWebProtobufsHistorySync.WallpaperSettings}},
        mediaVisibility:
          {2, {:scalar, :DEFAULT}, {:enum, WAWebProtobufsHistorySync.MediaVisibility}},
        photoQualityMode: {16, {:scalar, 0}, :int32},
        securityNotifications: {13, {:scalar, false}, :bool},
        showGroupNotificationsPreview: {8, {:scalar, false}, :bool},
        showIndividualNotificationsPreview: {7, {:scalar, false}, :bool},
        videoQualityMode: {15, {:scalar, 0}, :int32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "lightThemeWallpaper",
          kind: {:scalar, nil},
          label: :optional,
          name: :lightThemeWallpaper,
          tag: 1,
          type: {:message, WAWebProtobufsHistorySync.WallpaperSettings}
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaVisibility",
          kind: {:scalar, :DEFAULT},
          label: :optional,
          name: :mediaVisibility,
          tag: 2,
          type: {:enum, WAWebProtobufsHistorySync.MediaVisibility}
        },
        %{
          __struct__: Protox.Field,
          json_name: "darkThemeWallpaper",
          kind: {:scalar, nil},
          label: :optional,
          name: :darkThemeWallpaper,
          tag: 3,
          type: {:message, WAWebProtobufsHistorySync.WallpaperSettings}
        },
        %{
          __struct__: Protox.Field,
          json_name: "autoDownloadWiFi",
          kind: {:scalar, nil},
          label: :optional,
          name: :autoDownloadWiFi,
          tag: 4,
          type: {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}
        },
        %{
          __struct__: Protox.Field,
          json_name: "autoDownloadCellular",
          kind: {:scalar, nil},
          label: :optional,
          name: :autoDownloadCellular,
          tag: 5,
          type: {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}
        },
        %{
          __struct__: Protox.Field,
          json_name: "autoDownloadRoaming",
          kind: {:scalar, nil},
          label: :optional,
          name: :autoDownloadRoaming,
          tag: 6,
          type: {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}
        },
        %{
          __struct__: Protox.Field,
          json_name: "showIndividualNotificationsPreview",
          kind: {:scalar, false},
          label: :optional,
          name: :showIndividualNotificationsPreview,
          tag: 7,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "showGroupNotificationsPreview",
          kind: {:scalar, false},
          label: :optional,
          name: :showGroupNotificationsPreview,
          tag: 8,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "disappearingModeDuration",
          kind: {:scalar, 0},
          label: :optional,
          name: :disappearingModeDuration,
          tag: 9,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "disappearingModeTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :disappearingModeTimestamp,
          tag: 10,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "avatarUserSettings",
          kind: {:scalar, nil},
          label: :optional,
          name: :avatarUserSettings,
          tag: 11,
          type: {:message, WAWebProtobufsHistorySync.AvatarUserSettings}
        },
        %{
          __struct__: Protox.Field,
          json_name: "fontSize",
          kind: {:scalar, 0},
          label: :optional,
          name: :fontSize,
          tag: 12,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "securityNotifications",
          kind: {:scalar, false},
          label: :optional,
          name: :securityNotifications,
          tag: 13,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "autoUnarchiveChats",
          kind: {:scalar, false},
          label: :optional,
          name: :autoUnarchiveChats,
          tag: 14,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "videoQualityMode",
          kind: {:scalar, 0},
          label: :optional,
          name: :videoQualityMode,
          tag: 15,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "photoQualityMode",
          kind: {:scalar, 0},
          label: :optional,
          name: :photoQualityMode,
          tag: 16,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "individualNotificationSettings",
          kind: {:scalar, nil},
          label: :optional,
          name: :individualNotificationSettings,
          tag: 17,
          type: {:message, WAWebProtobufsHistorySync.NotificationSettings}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupNotificationSettings",
          kind: {:scalar, nil},
          label: :optional,
          name: :groupNotificationSettings,
          tag: 18,
          type: {:message, WAWebProtobufsHistorySync.NotificationSettings}
        },
        %{
          __struct__: Protox.Field,
          json_name: "chatLockSettings",
          kind: {:scalar, nil},
          label: :optional,
          name: :chatLockSettings,
          tag: 19,
          type: {:message, WAWebProtobufsChatLockSettings.ChatLockSettings}
        },
        %{
          __struct__: Protox.Field,
          json_name: "chatDbLidMigrationTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :chatDbLidMigrationTimestamp,
          tag: 20,
          type: :int64
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:lightThemeWallpaper) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lightThemeWallpaper",
             kind: {:scalar, nil},
             label: :optional,
             name: :lightThemeWallpaper,
             tag: 1,
             type: {:message, WAWebProtobufsHistorySync.WallpaperSettings}
           }}
        end

        def field_def("lightThemeWallpaper") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lightThemeWallpaper",
             kind: {:scalar, nil},
             label: :optional,
             name: :lightThemeWallpaper,
             tag: 1,
             type: {:message, WAWebProtobufsHistorySync.WallpaperSettings}
           }}
        end

        []
      ),
      (
        def field_def(:mediaVisibility) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaVisibility",
             kind: {:scalar, :DEFAULT},
             label: :optional,
             name: :mediaVisibility,
             tag: 2,
             type: {:enum, WAWebProtobufsHistorySync.MediaVisibility}
           }}
        end

        def field_def("mediaVisibility") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaVisibility",
             kind: {:scalar, :DEFAULT},
             label: :optional,
             name: :mediaVisibility,
             tag: 2,
             type: {:enum, WAWebProtobufsHistorySync.MediaVisibility}
           }}
        end

        []
      ),
      (
        def field_def(:darkThemeWallpaper) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "darkThemeWallpaper",
             kind: {:scalar, nil},
             label: :optional,
             name: :darkThemeWallpaper,
             tag: 3,
             type: {:message, WAWebProtobufsHistorySync.WallpaperSettings}
           }}
        end

        def field_def("darkThemeWallpaper") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "darkThemeWallpaper",
             kind: {:scalar, nil},
             label: :optional,
             name: :darkThemeWallpaper,
             tag: 3,
             type: {:message, WAWebProtobufsHistorySync.WallpaperSettings}
           }}
        end

        []
      ),
      (
        def field_def(:autoDownloadWiFi) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "autoDownloadWiFi",
             kind: {:scalar, nil},
             label: :optional,
             name: :autoDownloadWiFi,
             tag: 4,
             type: {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}
           }}
        end

        def field_def("autoDownloadWiFi") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "autoDownloadWiFi",
             kind: {:scalar, nil},
             label: :optional,
             name: :autoDownloadWiFi,
             tag: 4,
             type: {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}
           }}
        end

        []
      ),
      (
        def field_def(:autoDownloadCellular) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "autoDownloadCellular",
             kind: {:scalar, nil},
             label: :optional,
             name: :autoDownloadCellular,
             tag: 5,
             type: {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}
           }}
        end

        def field_def("autoDownloadCellular") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "autoDownloadCellular",
             kind: {:scalar, nil},
             label: :optional,
             name: :autoDownloadCellular,
             tag: 5,
             type: {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}
           }}
        end

        []
      ),
      (
        def field_def(:autoDownloadRoaming) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "autoDownloadRoaming",
             kind: {:scalar, nil},
             label: :optional,
             name: :autoDownloadRoaming,
             tag: 6,
             type: {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}
           }}
        end

        def field_def("autoDownloadRoaming") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "autoDownloadRoaming",
             kind: {:scalar, nil},
             label: :optional,
             name: :autoDownloadRoaming,
             tag: 6,
             type: {:message, WAWebProtobufsHistorySync.AutoDownloadSettings}
           }}
        end

        []
      ),
      (
        def field_def(:showIndividualNotificationsPreview) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "showIndividualNotificationsPreview",
             kind: {:scalar, false},
             label: :optional,
             name: :showIndividualNotificationsPreview,
             tag: 7,
             type: :bool
           }}
        end

        def field_def("showIndividualNotificationsPreview") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "showIndividualNotificationsPreview",
             kind: {:scalar, false},
             label: :optional,
             name: :showIndividualNotificationsPreview,
             tag: 7,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:showGroupNotificationsPreview) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "showGroupNotificationsPreview",
             kind: {:scalar, false},
             label: :optional,
             name: :showGroupNotificationsPreview,
             tag: 8,
             type: :bool
           }}
        end

        def field_def("showGroupNotificationsPreview") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "showGroupNotificationsPreview",
             kind: {:scalar, false},
             label: :optional,
             name: :showGroupNotificationsPreview,
             tag: 8,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:disappearingModeDuration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "disappearingModeDuration",
             kind: {:scalar, 0},
             label: :optional,
             name: :disappearingModeDuration,
             tag: 9,
             type: :int32
           }}
        end

        def field_def("disappearingModeDuration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "disappearingModeDuration",
             kind: {:scalar, 0},
             label: :optional,
             name: :disappearingModeDuration,
             tag: 9,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:disappearingModeTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "disappearingModeTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :disappearingModeTimestamp,
             tag: 10,
             type: :int64
           }}
        end

        def field_def("disappearingModeTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "disappearingModeTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :disappearingModeTimestamp,
             tag: 10,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:avatarUserSettings) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "avatarUserSettings",
             kind: {:scalar, nil},
             label: :optional,
             name: :avatarUserSettings,
             tag: 11,
             type: {:message, WAWebProtobufsHistorySync.AvatarUserSettings}
           }}
        end

        def field_def("avatarUserSettings") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "avatarUserSettings",
             kind: {:scalar, nil},
             label: :optional,
             name: :avatarUserSettings,
             tag: 11,
             type: {:message, WAWebProtobufsHistorySync.AvatarUserSettings}
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
             tag: 12,
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
             tag: 12,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:securityNotifications) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "securityNotifications",
             kind: {:scalar, false},
             label: :optional,
             name: :securityNotifications,
             tag: 13,
             type: :bool
           }}
        end

        def field_def("securityNotifications") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "securityNotifications",
             kind: {:scalar, false},
             label: :optional,
             name: :securityNotifications,
             tag: 13,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:autoUnarchiveChats) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "autoUnarchiveChats",
             kind: {:scalar, false},
             label: :optional,
             name: :autoUnarchiveChats,
             tag: 14,
             type: :bool
           }}
        end

        def field_def("autoUnarchiveChats") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "autoUnarchiveChats",
             kind: {:scalar, false},
             label: :optional,
             name: :autoUnarchiveChats,
             tag: 14,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:videoQualityMode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoQualityMode",
             kind: {:scalar, 0},
             label: :optional,
             name: :videoQualityMode,
             tag: 15,
             type: :int32
           }}
        end

        def field_def("videoQualityMode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoQualityMode",
             kind: {:scalar, 0},
             label: :optional,
             name: :videoQualityMode,
             tag: 15,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:photoQualityMode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "photoQualityMode",
             kind: {:scalar, 0},
             label: :optional,
             name: :photoQualityMode,
             tag: 16,
             type: :int32
           }}
        end

        def field_def("photoQualityMode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "photoQualityMode",
             kind: {:scalar, 0},
             label: :optional,
             name: :photoQualityMode,
             tag: 16,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:individualNotificationSettings) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "individualNotificationSettings",
             kind: {:scalar, nil},
             label: :optional,
             name: :individualNotificationSettings,
             tag: 17,
             type: {:message, WAWebProtobufsHistorySync.NotificationSettings}
           }}
        end

        def field_def("individualNotificationSettings") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "individualNotificationSettings",
             kind: {:scalar, nil},
             label: :optional,
             name: :individualNotificationSettings,
             tag: 17,
             type: {:message, WAWebProtobufsHistorySync.NotificationSettings}
           }}
        end

        []
      ),
      (
        def field_def(:groupNotificationSettings) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupNotificationSettings",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupNotificationSettings,
             tag: 18,
             type: {:message, WAWebProtobufsHistorySync.NotificationSettings}
           }}
        end

        def field_def("groupNotificationSettings") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupNotificationSettings",
             kind: {:scalar, nil},
             label: :optional,
             name: :groupNotificationSettings,
             tag: 18,
             type: {:message, WAWebProtobufsHistorySync.NotificationSettings}
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
             tag: 19,
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
             tag: 19,
             type: {:message, WAWebProtobufsChatLockSettings.ChatLockSettings}
           }}
        end

        []
      ),
      (
        def field_def(:chatDbLidMigrationTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatDbLidMigrationTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :chatDbLidMigrationTimestamp,
             tag: 20,
             type: :int64
           }}
        end

        def field_def("chatDbLidMigrationTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatDbLidMigrationTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :chatDbLidMigrationTimestamp,
             tag: 20,
             type: :int64
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
    def default(:lightThemeWallpaper) do
      {:ok, nil}
    end,
    def default(:mediaVisibility) do
      {:ok, :DEFAULT}
    end,
    def default(:darkThemeWallpaper) do
      {:ok, nil}
    end,
    def default(:autoDownloadWiFi) do
      {:ok, nil}
    end,
    def default(:autoDownloadCellular) do
      {:ok, nil}
    end,
    def default(:autoDownloadRoaming) do
      {:ok, nil}
    end,
    def default(:showIndividualNotificationsPreview) do
      {:ok, false}
    end,
    def default(:showGroupNotificationsPreview) do
      {:ok, false}
    end,
    def default(:disappearingModeDuration) do
      {:ok, 0}
    end,
    def default(:disappearingModeTimestamp) do
      {:ok, 0}
    end,
    def default(:avatarUserSettings) do
      {:ok, nil}
    end,
    def default(:fontSize) do
      {:ok, 0}
    end,
    def default(:securityNotifications) do
      {:ok, false}
    end,
    def default(:autoUnarchiveChats) do
      {:ok, false}
    end,
    def default(:videoQualityMode) do
      {:ok, 0}
    end,
    def default(:photoQualityMode) do
      {:ok, 0}
    end,
    def default(:individualNotificationSettings) do
      {:ok, nil}
    end,
    def default(:groupNotificationSettings) do
      {:ok, nil}
    end,
    def default(:chatLockSettings) do
      {:ok, nil}
    end,
    def default(:chatDbLidMigrationTimestamp) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waHistorySync",
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
