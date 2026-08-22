# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.SettingsSyncAction.SettingKey do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :SETTING_KEY_UNKNOWN
      def default() do
        :SETTING_KEY_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:SETTING_KEY_UNKNOWN) do
          0
        end

        def encode("SETTING_KEY_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:START_AT_LOGIN) do
          1
        end

        def encode("START_AT_LOGIN") do
          1
        end
      ),
      (
        def encode(:MINIMIZE_TO_TRAY) do
          2
        end

        def encode("MINIMIZE_TO_TRAY") do
          2
        end
      ),
      (
        def encode(:LANGUAGE) do
          3
        end

        def encode("LANGUAGE") do
          3
        end
      ),
      (
        def encode(:REPLACE_TEXT_WITH_EMOJI) do
          4
        end

        def encode("REPLACE_TEXT_WITH_EMOJI") do
          4
        end
      ),
      (
        def encode(:BANNER_NOTIFICATION_DISPLAY_MODE) do
          5
        end

        def encode("BANNER_NOTIFICATION_DISPLAY_MODE") do
          5
        end
      ),
      (
        def encode(:UNREAD_COUNTER_BADGE_DISPLAY_MODE) do
          6
        end

        def encode("UNREAD_COUNTER_BADGE_DISPLAY_MODE") do
          6
        end
      ),
      (
        def encode(:IS_MESSAGES_NOTIFICATION_ENABLED) do
          7
        end

        def encode("IS_MESSAGES_NOTIFICATION_ENABLED") do
          7
        end
      ),
      (
        def encode(:IS_CALLS_NOTIFICATION_ENABLED) do
          8
        end

        def encode("IS_CALLS_NOTIFICATION_ENABLED") do
          8
        end
      ),
      (
        def encode(:IS_REACTIONS_NOTIFICATION_ENABLED) do
          9
        end

        def encode("IS_REACTIONS_NOTIFICATION_ENABLED") do
          9
        end
      ),
      (
        def encode(:IS_STATUS_REACTIONS_NOTIFICATION_ENABLED) do
          10
        end

        def encode("IS_STATUS_REACTIONS_NOTIFICATION_ENABLED") do
          10
        end
      ),
      (
        def encode(:IS_TEXT_PREVIEW_FOR_NOTIFICATION_ENABLED) do
          11
        end

        def encode("IS_TEXT_PREVIEW_FOR_NOTIFICATION_ENABLED") do
          11
        end
      ),
      (
        def encode(:DEFAULT_NOTIFICATION_TONE_ID) do
          12
        end

        def encode("DEFAULT_NOTIFICATION_TONE_ID") do
          12
        end
      ),
      (
        def encode(:GROUP_DEFAULT_NOTIFICATION_TONE_ID) do
          13
        end

        def encode("GROUP_DEFAULT_NOTIFICATION_TONE_ID") do
          13
        end
      ),
      (
        def encode(:APP_THEME) do
          14
        end

        def encode("APP_THEME") do
          14
        end
      ),
      (
        def encode(:WALLPAPER_ID) do
          15
        end

        def encode("WALLPAPER_ID") do
          15
        end
      ),
      (
        def encode(:IS_DOODLE_WALLPAPER_ENABLED) do
          16
        end

        def encode("IS_DOODLE_WALLPAPER_ENABLED") do
          16
        end
      ),
      (
        def encode(:FONT_SIZE) do
          17
        end

        def encode("FONT_SIZE") do
          17
        end
      ),
      (
        def encode(:IS_PHOTOS_AUTODOWNLOAD_ENABLED) do
          18
        end

        def encode("IS_PHOTOS_AUTODOWNLOAD_ENABLED") do
          18
        end
      ),
      (
        def encode(:IS_AUDIOS_AUTODOWNLOAD_ENABLED) do
          19
        end

        def encode("IS_AUDIOS_AUTODOWNLOAD_ENABLED") do
          19
        end
      ),
      (
        def encode(:IS_VIDEOS_AUTODOWNLOAD_ENABLED) do
          20
        end

        def encode("IS_VIDEOS_AUTODOWNLOAD_ENABLED") do
          20
        end
      ),
      (
        def encode(:IS_DOCUMENTS_AUTODOWNLOAD_ENABLED) do
          21
        end

        def encode("IS_DOCUMENTS_AUTODOWNLOAD_ENABLED") do
          21
        end
      ),
      (
        def encode(:DISABLE_LINK_PREVIEWS) do
          22
        end

        def encode("DISABLE_LINK_PREVIEWS") do
          22
        end
      ),
      (
        def encode(:NOTIFICATION_TONE_ID) do
          23
        end

        def encode("NOTIFICATION_TONE_ID") do
          23
        end
      ),
      (
        def encode(:MEDIA_UPLOAD_QUALITY) do
          24
        end

        def encode("MEDIA_UPLOAD_QUALITY") do
          24
        end
      ),
      (
        def encode(:IS_SPELL_CHECK_ENABLED) do
          25
        end

        def encode("IS_SPELL_CHECK_ENABLED") do
          25
        end
      ),
      (
        def encode(:IS_ENTER_TO_SEND_ENABLED) do
          26
        end

        def encode("IS_ENTER_TO_SEND_ENABLED") do
          26
        end
      ),
      (
        def encode(:IS_GROUP_MESSAGE_NOTIFICATION_ENABLED) do
          27
        end

        def encode("IS_GROUP_MESSAGE_NOTIFICATION_ENABLED") do
          27
        end
      ),
      (
        def encode(:IS_GROUP_REACTIONS_NOTIFICATION_ENABLED) do
          28
        end

        def encode("IS_GROUP_REACTIONS_NOTIFICATION_ENABLED") do
          28
        end
      ),
      (
        def encode(:IS_STATUS_NOTIFICATION_ENABLED) do
          29
        end

        def encode("IS_STATUS_NOTIFICATION_ENABLED") do
          29
        end
      ),
      (
        def encode(:STATUS_NOTIFICATION_TONE_ID) do
          30
        end

        def encode("STATUS_NOTIFICATION_TONE_ID") do
          30
        end
      ),
      (
        def encode(:SHOULD_PLAY_SOUND_FOR_CALL_NOTIFICATION) do
          31
        end

        def encode("SHOULD_PLAY_SOUND_FOR_CALL_NOTIFICATION") do
          31
        end
      ),
      (
        def encode(:CHAT_THEME_ID) do
          32
        end

        def encode("CHAT_THEME_ID") do
          32
        end
      ),
      (
        def encode(:COLOR_SCHEME_ID) do
          33
        end

        def encode("COLOR_SCHEME_ID") do
          33
        end
      ),
      (
        def encode(:STOCK_WALLPAPER_IMAGE_ID) do
          34
        end

        def encode("STOCK_WALLPAPER_IMAGE_ID") do
          34
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(18) do
        :IS_PHOTOS_AUTODOWNLOAD_ENABLED
      end,
      def decode(4) do
        :REPLACE_TEXT_WITH_EMOJI
      end,
      def decode(34) do
        :STOCK_WALLPAPER_IMAGE_ID
      end,
      def decode(12) do
        :DEFAULT_NOTIFICATION_TONE_ID
      end,
      def decode(19) do
        :IS_AUDIOS_AUTODOWNLOAD_ENABLED
      end,
      def decode(29) do
        :IS_STATUS_NOTIFICATION_ENABLED
      end,
      def decode(13) do
        :GROUP_DEFAULT_NOTIFICATION_TONE_ID
      end,
      def decode(2) do
        :MINIMIZE_TO_TRAY
      end,
      def decode(7) do
        :IS_MESSAGES_NOTIFICATION_ENABLED
      end,
      def decode(31) do
        :SHOULD_PLAY_SOUND_FOR_CALL_NOTIFICATION
      end,
      def decode(8) do
        :IS_CALLS_NOTIFICATION_ENABLED
      end,
      def decode(10) do
        :IS_STATUS_REACTIONS_NOTIFICATION_ENABLED
      end,
      def decode(23) do
        :NOTIFICATION_TONE_ID
      end,
      def decode(9) do
        :IS_REACTIONS_NOTIFICATION_ENABLED
      end,
      def decode(15) do
        :WALLPAPER_ID
      end,
      def decode(32) do
        :CHAT_THEME_ID
      end,
      def decode(1) do
        :START_AT_LOGIN
      end,
      def decode(25) do
        :IS_SPELL_CHECK_ENABLED
      end,
      def decode(28) do
        :IS_GROUP_REACTIONS_NOTIFICATION_ENABLED
      end,
      def decode(20) do
        :IS_VIDEOS_AUTODOWNLOAD_ENABLED
      end,
      def decode(6) do
        :UNREAD_COUNTER_BADGE_DISPLAY_MODE
      end,
      def decode(11) do
        :IS_TEXT_PREVIEW_FOR_NOTIFICATION_ENABLED
      end,
      def decode(17) do
        :FONT_SIZE
      end,
      def decode(24) do
        :MEDIA_UPLOAD_QUALITY
      end,
      def decode(14) do
        :APP_THEME
      end,
      def decode(33) do
        :COLOR_SCHEME_ID
      end,
      def decode(3) do
        :LANGUAGE
      end,
      def decode(16) do
        :IS_DOODLE_WALLPAPER_ENABLED
      end,
      def decode(30) do
        :STATUS_NOTIFICATION_TONE_ID
      end,
      def decode(21) do
        :IS_DOCUMENTS_AUTODOWNLOAD_ENABLED
      end,
      def decode(5) do
        :BANNER_NOTIFICATION_DISPLAY_MODE
      end,
      def decode(0) do
        :SETTING_KEY_UNKNOWN
      end,
      def decode(27) do
        :IS_GROUP_MESSAGE_NOTIFICATION_ENABLED
      end,
      def decode(26) do
        :IS_ENTER_TO_SEND_ENABLED
      end,
      def decode(22) do
        :DISABLE_LINK_PREVIEWS
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :SETTING_KEY_UNKNOWN},
        {1, :START_AT_LOGIN},
        {2, :MINIMIZE_TO_TRAY},
        {3, :LANGUAGE},
        {4, :REPLACE_TEXT_WITH_EMOJI},
        {5, :BANNER_NOTIFICATION_DISPLAY_MODE},
        {6, :UNREAD_COUNTER_BADGE_DISPLAY_MODE},
        {7, :IS_MESSAGES_NOTIFICATION_ENABLED},
        {8, :IS_CALLS_NOTIFICATION_ENABLED},
        {9, :IS_REACTIONS_NOTIFICATION_ENABLED},
        {10, :IS_STATUS_REACTIONS_NOTIFICATION_ENABLED},
        {11, :IS_TEXT_PREVIEW_FOR_NOTIFICATION_ENABLED},
        {12, :DEFAULT_NOTIFICATION_TONE_ID},
        {13, :GROUP_DEFAULT_NOTIFICATION_TONE_ID},
        {14, :APP_THEME},
        {15, :WALLPAPER_ID},
        {16, :IS_DOODLE_WALLPAPER_ENABLED},
        {17, :FONT_SIZE},
        {18, :IS_PHOTOS_AUTODOWNLOAD_ENABLED},
        {19, :IS_AUDIOS_AUTODOWNLOAD_ENABLED},
        {20, :IS_VIDEOS_AUTODOWNLOAD_ENABLED},
        {21, :IS_DOCUMENTS_AUTODOWNLOAD_ENABLED},
        {22, :DISABLE_LINK_PREVIEWS},
        {23, :NOTIFICATION_TONE_ID},
        {24, :MEDIA_UPLOAD_QUALITY},
        {25, :IS_SPELL_CHECK_ENABLED},
        {26, :IS_ENTER_TO_SEND_ENABLED},
        {27, :IS_GROUP_MESSAGE_NOTIFICATION_ENABLED},
        {28, :IS_GROUP_REACTIONS_NOTIFICATION_ENABLED},
        {29, :IS_STATUS_NOTIFICATION_ENABLED},
        {30, :STATUS_NOTIFICATION_TONE_ID},
        {31, :SHOULD_PLAY_SOUND_FOR_CALL_NOTIFICATION},
        {32, :CHAT_THEME_ID},
        {33, :COLOR_SCHEME_ID},
        {34, :STOCK_WALLPAPER_IMAGE_ID}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:SETTING_KEY_UNKNOWN) do
          true
        end,
        def has_constant?(:START_AT_LOGIN) do
          true
        end,
        def has_constant?(:MINIMIZE_TO_TRAY) do
          true
        end,
        def has_constant?(:LANGUAGE) do
          true
        end,
        def has_constant?(:REPLACE_TEXT_WITH_EMOJI) do
          true
        end,
        def has_constant?(:BANNER_NOTIFICATION_DISPLAY_MODE) do
          true
        end,
        def has_constant?(:UNREAD_COUNTER_BADGE_DISPLAY_MODE) do
          true
        end,
        def has_constant?(:IS_MESSAGES_NOTIFICATION_ENABLED) do
          true
        end,
        def has_constant?(:IS_CALLS_NOTIFICATION_ENABLED) do
          true
        end,
        def has_constant?(:IS_REACTIONS_NOTIFICATION_ENABLED) do
          true
        end,
        def has_constant?(:IS_STATUS_REACTIONS_NOTIFICATION_ENABLED) do
          true
        end,
        def has_constant?(:IS_TEXT_PREVIEW_FOR_NOTIFICATION_ENABLED) do
          true
        end,
        def has_constant?(:DEFAULT_NOTIFICATION_TONE_ID) do
          true
        end,
        def has_constant?(:GROUP_DEFAULT_NOTIFICATION_TONE_ID) do
          true
        end,
        def has_constant?(:APP_THEME) do
          true
        end,
        def has_constant?(:WALLPAPER_ID) do
          true
        end,
        def has_constant?(:IS_DOODLE_WALLPAPER_ENABLED) do
          true
        end,
        def has_constant?(:FONT_SIZE) do
          true
        end,
        def has_constant?(:IS_PHOTOS_AUTODOWNLOAD_ENABLED) do
          true
        end,
        def has_constant?(:IS_AUDIOS_AUTODOWNLOAD_ENABLED) do
          true
        end,
        def has_constant?(:IS_VIDEOS_AUTODOWNLOAD_ENABLED) do
          true
        end,
        def has_constant?(:IS_DOCUMENTS_AUTODOWNLOAD_ENABLED) do
          true
        end,
        def has_constant?(:DISABLE_LINK_PREVIEWS) do
          true
        end,
        def has_constant?(:NOTIFICATION_TONE_ID) do
          true
        end,
        def has_constant?(:MEDIA_UPLOAD_QUALITY) do
          true
        end,
        def has_constant?(:IS_SPELL_CHECK_ENABLED) do
          true
        end,
        def has_constant?(:IS_ENTER_TO_SEND_ENABLED) do
          true
        end,
        def has_constant?(:IS_GROUP_MESSAGE_NOTIFICATION_ENABLED) do
          true
        end,
        def has_constant?(:IS_GROUP_REACTIONS_NOTIFICATION_ENABLED) do
          true
        end,
        def has_constant?(:IS_STATUS_NOTIFICATION_ENABLED) do
          true
        end,
        def has_constant?(:STATUS_NOTIFICATION_TONE_ID) do
          true
        end,
        def has_constant?(:SHOULD_PLAY_SOUND_FOR_CALL_NOTIFICATION) do
          true
        end,
        def has_constant?(:CHAT_THEME_ID) do
          true
        end,
        def has_constant?(:COLOR_SCHEME_ID) do
          true
        end,
        def has_constant?(:STOCK_WALLPAPER_IMAGE_ID) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
