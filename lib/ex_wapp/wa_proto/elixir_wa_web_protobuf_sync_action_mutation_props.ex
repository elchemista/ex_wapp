# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.MutationProps do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :STAR_ACTION
      def default() do
        :STAR_ACTION
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:STAR_ACTION) do
          2
        end

        def encode("STAR_ACTION") do
          2
        end
      ),
      (
        def encode(:CONTACT_ACTION) do
          3
        end

        def encode("CONTACT_ACTION") do
          3
        end
      ),
      (
        def encode(:MUTE_ACTION) do
          4
        end

        def encode("MUTE_ACTION") do
          4
        end
      ),
      (
        def encode(:PIN_ACTION) do
          5
        end

        def encode("PIN_ACTION") do
          5
        end
      ),
      (
        def encode(:SECURITY_NOTIFICATION_SETTING) do
          6
        end

        def encode("SECURITY_NOTIFICATION_SETTING") do
          6
        end
      ),
      (
        def encode(:PUSH_NAME_SETTING) do
          7
        end

        def encode("PUSH_NAME_SETTING") do
          7
        end
      ),
      (
        def encode(:QUICK_REPLY_ACTION) do
          8
        end

        def encode("QUICK_REPLY_ACTION") do
          8
        end
      ),
      (
        def encode(:RECENT_EMOJI_WEIGHTS_ACTION) do
          11
        end

        def encode("RECENT_EMOJI_WEIGHTS_ACTION") do
          11
        end
      ),
      (
        def encode(:LABEL_MESSAGE_ACTION) do
          13
        end

        def encode("LABEL_MESSAGE_ACTION") do
          13
        end
      ),
      (
        def encode(:LABEL_EDIT_ACTION) do
          14
        end

        def encode("LABEL_EDIT_ACTION") do
          14
        end
      ),
      (
        def encode(:LABEL_ASSOCIATION_ACTION) do
          15
        end

        def encode("LABEL_ASSOCIATION_ACTION") do
          15
        end
      ),
      (
        def encode(:LOCALE_SETTING) do
          16
        end

        def encode("LOCALE_SETTING") do
          16
        end
      ),
      (
        def encode(:ARCHIVE_CHAT_ACTION) do
          17
        end

        def encode("ARCHIVE_CHAT_ACTION") do
          17
        end
      ),
      (
        def encode(:DELETE_MESSAGE_FOR_ME_ACTION) do
          18
        end

        def encode("DELETE_MESSAGE_FOR_ME_ACTION") do
          18
        end
      ),
      (
        def encode(:KEY_EXPIRATION) do
          19
        end

        def encode("KEY_EXPIRATION") do
          19
        end
      ),
      (
        def encode(:MARK_CHAT_AS_READ_ACTION) do
          20
        end

        def encode("MARK_CHAT_AS_READ_ACTION") do
          20
        end
      ),
      (
        def encode(:CLEAR_CHAT_ACTION) do
          21
        end

        def encode("CLEAR_CHAT_ACTION") do
          21
        end
      ),
      (
        def encode(:DELETE_CHAT_ACTION) do
          22
        end

        def encode("DELETE_CHAT_ACTION") do
          22
        end
      ),
      (
        def encode(:UNARCHIVE_CHATS_SETTING) do
          23
        end

        def encode("UNARCHIVE_CHATS_SETTING") do
          23
        end
      ),
      (
        def encode(:PRIMARY_FEATURE) do
          24
        end

        def encode("PRIMARY_FEATURE") do
          24
        end
      ),
      (
        def encode(:ANDROID_UNSUPPORTED_ACTIONS) do
          26
        end

        def encode("ANDROID_UNSUPPORTED_ACTIONS") do
          26
        end
      ),
      (
        def encode(:AGENT_ACTION) do
          27
        end

        def encode("AGENT_ACTION") do
          27
        end
      ),
      (
        def encode(:SUBSCRIPTION_ACTION) do
          28
        end

        def encode("SUBSCRIPTION_ACTION") do
          28
        end
      ),
      (
        def encode(:USER_STATUS_MUTE_ACTION) do
          29
        end

        def encode("USER_STATUS_MUTE_ACTION") do
          29
        end
      ),
      (
        def encode(:TIME_FORMAT_ACTION) do
          30
        end

        def encode("TIME_FORMAT_ACTION") do
          30
        end
      ),
      (
        def encode(:NUX_ACTION) do
          31
        end

        def encode("NUX_ACTION") do
          31
        end
      ),
      (
        def encode(:PRIMARY_VERSION_ACTION) do
          32
        end

        def encode("PRIMARY_VERSION_ACTION") do
          32
        end
      ),
      (
        def encode(:STICKER_ACTION) do
          33
        end

        def encode("STICKER_ACTION") do
          33
        end
      ),
      (
        def encode(:REMOVE_RECENT_STICKER_ACTION) do
          34
        end

        def encode("REMOVE_RECENT_STICKER_ACTION") do
          34
        end
      ),
      (
        def encode(:CHAT_ASSIGNMENT) do
          35
        end

        def encode("CHAT_ASSIGNMENT") do
          35
        end
      ),
      (
        def encode(:CHAT_ASSIGNMENT_OPENED_STATUS) do
          36
        end

        def encode("CHAT_ASSIGNMENT_OPENED_STATUS") do
          36
        end
      ),
      (
        def encode(:PN_FOR_LID_CHAT_ACTION) do
          37
        end

        def encode("PN_FOR_LID_CHAT_ACTION") do
          37
        end
      ),
      (
        def encode(:MARKETING_MESSAGE_ACTION) do
          38
        end

        def encode("MARKETING_MESSAGE_ACTION") do
          38
        end
      ),
      (
        def encode(:MARKETING_MESSAGE_BROADCAST_ACTION) do
          39
        end

        def encode("MARKETING_MESSAGE_BROADCAST_ACTION") do
          39
        end
      ),
      (
        def encode(:EXTERNAL_WEB_BETA_ACTION) do
          40
        end

        def encode("EXTERNAL_WEB_BETA_ACTION") do
          40
        end
      ),
      (
        def encode(:PRIVACY_SETTING_RELAY_ALL_CALLS) do
          41
        end

        def encode("PRIVACY_SETTING_RELAY_ALL_CALLS") do
          41
        end
      ),
      (
        def encode(:CALL_LOG_ACTION) do
          42
        end

        def encode("CALL_LOG_ACTION") do
          42
        end
      ),
      (
        def encode(:UGC_BOT) do
          43
        end

        def encode("UGC_BOT") do
          43
        end
      ),
      (
        def encode(:STATUS_PRIVACY) do
          44
        end

        def encode("STATUS_PRIVACY") do
          44
        end
      ),
      (
        def encode(:BOT_WELCOME_REQUEST_ACTION) do
          45
        end

        def encode("BOT_WELCOME_REQUEST_ACTION") do
          45
        end
      ),
      (
        def encode(:DELETE_INDIVIDUAL_CALL_LOG) do
          46
        end

        def encode("DELETE_INDIVIDUAL_CALL_LOG") do
          46
        end
      ),
      (
        def encode(:LABEL_REORDERING_ACTION) do
          47
        end

        def encode("LABEL_REORDERING_ACTION") do
          47
        end
      ),
      (
        def encode(:PAYMENT_INFO_ACTION) do
          48
        end

        def encode("PAYMENT_INFO_ACTION") do
          48
        end
      ),
      (
        def encode(:CUSTOM_PAYMENT_METHODS_ACTION) do
          49
        end

        def encode("CUSTOM_PAYMENT_METHODS_ACTION") do
          49
        end
      ),
      (
        def encode(:LOCK_CHAT_ACTION) do
          50
        end

        def encode("LOCK_CHAT_ACTION") do
          50
        end
      ),
      (
        def encode(:CHAT_LOCK_SETTINGS) do
          51
        end

        def encode("CHAT_LOCK_SETTINGS") do
          51
        end
      ),
      (
        def encode(:WAMO_USER_IDENTIFIER_ACTION) do
          52
        end

        def encode("WAMO_USER_IDENTIFIER_ACTION") do
          52
        end
      ),
      (
        def encode(:PRIVACY_SETTING_DISABLE_LINK_PREVIEWS_ACTION) do
          53
        end

        def encode("PRIVACY_SETTING_DISABLE_LINK_PREVIEWS_ACTION") do
          53
        end
      ),
      (
        def encode(:DEVICE_CAPABILITIES) do
          54
        end

        def encode("DEVICE_CAPABILITIES") do
          54
        end
      ),
      (
        def encode(:NOTE_EDIT_ACTION) do
          55
        end

        def encode("NOTE_EDIT_ACTION") do
          55
        end
      ),
      (
        def encode(:FAVORITES_ACTION) do
          56
        end

        def encode("FAVORITES_ACTION") do
          56
        end
      ),
      (
        def encode(:MERCHANT_PAYMENT_PARTNER_ACTION) do
          57
        end

        def encode("MERCHANT_PAYMENT_PARTNER_ACTION") do
          57
        end
      ),
      (
        def encode(:WAFFLE_ACCOUNT_LINK_STATE_ACTION) do
          58
        end

        def encode("WAFFLE_ACCOUNT_LINK_STATE_ACTION") do
          58
        end
      ),
      (
        def encode(:USERNAME_CHAT_START_MODE) do
          59
        end

        def encode("USERNAME_CHAT_START_MODE") do
          59
        end
      ),
      (
        def encode(:NOTIFICATION_ACTIVITY_SETTING_ACTION) do
          60
        end

        def encode("NOTIFICATION_ACTIVITY_SETTING_ACTION") do
          60
        end
      ),
      (
        def encode(:LID_CONTACT_ACTION) do
          61
        end

        def encode("LID_CONTACT_ACTION") do
          61
        end
      ),
      (
        def encode(:CTWA_PER_CUSTOMER_DATA_SHARING_ACTION) do
          62
        end

        def encode("CTWA_PER_CUSTOMER_DATA_SHARING_ACTION") do
          62
        end
      ),
      (
        def encode(:PAYMENT_TOS_ACTION) do
          63
        end

        def encode("PAYMENT_TOS_ACTION") do
          63
        end
      ),
      (
        def encode(:PRIVACY_SETTING_CHANNELS_PERSONALISED_RECOMMENDATION_ACTION) do
          64
        end

        def encode("PRIVACY_SETTING_CHANNELS_PERSONALISED_RECOMMENDATION_ACTION") do
          64
        end
      ),
      (
        def encode(:BUSINESS_BROADCAST_ASSOCIATION_ACTION) do
          65
        end

        def encode("BUSINESS_BROADCAST_ASSOCIATION_ACTION") do
          65
        end
      ),
      (
        def encode(:DETECTED_OUTCOMES_STATUS_ACTION) do
          66
        end

        def encode("DETECTED_OUTCOMES_STATUS_ACTION") do
          66
        end
      ),
      (
        def encode(:MAIBA_AI_FEATURES_CONTROL_ACTION) do
          68
        end

        def encode("MAIBA_AI_FEATURES_CONTROL_ACTION") do
          68
        end
      ),
      (
        def encode(:BUSINESS_BROADCAST_LIST_ACTION) do
          69
        end

        def encode("BUSINESS_BROADCAST_LIST_ACTION") do
          69
        end
      ),
      (
        def encode(:MUSIC_USER_ID_ACTION) do
          70
        end

        def encode("MUSIC_USER_ID_ACTION") do
          70
        end
      ),
      (
        def encode(:STATUS_POST_OPT_IN_NOTIFICATION_PREFERENCES_ACTION) do
          71
        end

        def encode("STATUS_POST_OPT_IN_NOTIFICATION_PREFERENCES_ACTION") do
          71
        end
      ),
      (
        def encode(:AVATAR_UPDATED_ACTION) do
          72
        end

        def encode("AVATAR_UPDATED_ACTION") do
          72
        end
      ),
      (
        def encode(:GALAXY_FLOW_ACTION) do
          73
        end

        def encode("GALAXY_FLOW_ACTION") do
          73
        end
      ),
      (
        def encode(:PRIVATE_PROCESSING_SETTING_ACTION) do
          74
        end

        def encode("PRIVATE_PROCESSING_SETTING_ACTION") do
          74
        end
      ),
      (
        def encode(:NEWSLETTER_SAVED_INTERESTS_ACTION) do
          75
        end

        def encode("NEWSLETTER_SAVED_INTERESTS_ACTION") do
          75
        end
      ),
      (
        def encode(:AI_THREAD_RENAME_ACTION) do
          76
        end

        def encode("AI_THREAD_RENAME_ACTION") do
          76
        end
      ),
      (
        def encode(:INTERACTIVE_MESSAGE_ACTION) do
          77
        end

        def encode("INTERACTIVE_MESSAGE_ACTION") do
          77
        end
      ),
      (
        def encode(:SETTINGS_SYNC_ACTION) do
          78
        end

        def encode("SETTINGS_SYNC_ACTION") do
          78
        end
      ),
      (
        def encode(:OUT_CONTACT_ACTION) do
          79
        end

        def encode("OUT_CONTACT_ACTION") do
          79
        end
      ),
      (
        def encode(:NCT_SALT_SYNC_ACTION) do
          80
        end

        def encode("NCT_SALT_SYNC_ACTION") do
          80
        end
      ),
      (
        def encode(:BUSINESS_BROADCAST_CAMPAIGN_ACTION) do
          81
        end

        def encode("BUSINESS_BROADCAST_CAMPAIGN_ACTION") do
          81
        end
      ),
      (
        def encode(:BUSINESS_BROADCAST_INSIGHTS_ACTION) do
          82
        end

        def encode("BUSINESS_BROADCAST_INSIGHTS_ACTION") do
          82
        end
      ),
      (
        def encode(:CUSTOMER_DATA_ACTION) do
          83
        end

        def encode("CUSTOMER_DATA_ACTION") do
          83
        end
      ),
      (
        def encode(:SUBSCRIPTIONS_SYNC_V2_ACTION) do
          84
        end

        def encode("SUBSCRIPTIONS_SYNC_V2_ACTION") do
          84
        end
      ),
      (
        def encode(:THREAD_PIN_ACTION) do
          85
        end

        def encode("THREAD_PIN_ACTION") do
          85
        end
      ),
      (
        def encode(:AUTO_ORGANIZE_BUSINESS_CHAT_SETTING) do
          86
        end

        def encode("AUTO_ORGANIZE_BUSINESS_CHAT_SETTING") do
          86
        end
      ),
      (
        def encode(:BIZ_AI_SETTINGS_NUDGE_ACTION) do
          87
        end

        def encode("BIZ_AI_SETTINGS_NUDGE_ACTION") do
          87
        end
      ),
      (
        def encode(:COEX_V2_VERSION_ACTION) do
          88
        end

        def encode("COEX_V2_VERSION_ACTION") do
          88
        end
      ),
      (
        def encode(:WASA_ROOT_SECRET_ACTION) do
          89
        end

        def encode("WASA_ROOT_SECRET_ACTION") do
          89
        end
      ),
      (
        def encode(:BUBBLE_LOCK_MESSAGE_ACTION) do
          90
        end

        def encode("BUBBLE_LOCK_MESSAGE_ACTION") do
          90
        end
      ),
      (
        def encode(:LABEL_SUBLIST_ACTION) do
          91
        end

        def encode("LABEL_SUBLIST_ACTION") do
          91
        end
      ),
      (
        def encode(:DEVICE_CAPABILITIES_V2) do
          92
        end

        def encode("DEVICE_CAPABILITIES_V2") do
          92
        end
      ),
      (
        def encode(:CTWA_MESSAGE_RECEIVED_ACTION) do
          93
        end

        def encode("CTWA_MESSAGE_RECEIVED_ACTION") do
          93
        end
      ),
      (
        def encode(:SHARED_DEVICE_ALLOWLIST_ACTION) do
          94
        end

        def encode("SHARED_DEVICE_ALLOWLIST_ACTION") do
          94
        end
      ),
      (
        def encode(:CONTACT_MANAGER_METADATA_ACTION) do
          95
        end

        def encode("CONTACT_MANAGER_METADATA_ACTION") do
          95
        end
      ),
      (
        def encode(:BUSINESS_FOLDER_ACTIVATION_ACTION) do
          96
        end

        def encode("BUSINESS_FOLDER_ACTIVATION_ACTION") do
          96
        end
      ),
      (
        def encode(:GROUP_HISTORY_TOGGLE_ACTION) do
          97
        end

        def encode("GROUP_HISTORY_TOGGLE_ACTION") do
          97
        end
      ),
      (
        def encode(:BB_PRO_PENDING_CUSTOMER_BASE_ACTION) do
          98
        end

        def encode("BB_PRO_PENDING_CUSTOMER_BASE_ACTION") do
          98
        end
      ),
      (
        def encode(:COMMUNITY_NESTING_STATE_ACTION) do
          99
        end

        def encode("COMMUNITY_NESTING_STATE_ACTION") do
          99
        end
      ),
      (
        def encode(:SHARED_DEVICE_SECRET_ACTION) do
          100
        end

        def encode("SHARED_DEVICE_SECRET_ACTION") do
          100
        end
      ),
      (
        def encode(:SHARE_OWN_PN) do
          10001
        end

        def encode("SHARE_OWN_PN") do
          10001
        end
      ),
      (
        def encode(:BUSINESS_BROADCAST_ACTION) do
          10002
        end

        def encode("BUSINESS_BROADCAST_ACTION") do
          10002
        end
      ),
      (
        def encode(:AI_THREAD_DELETE_ACTION) do
          10003
        end

        def encode("AI_THREAD_DELETE_ACTION") do
          10003
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(54) do
        :DEVICE_CAPABILITIES
      end,
      def decode(18) do
        :DELETE_MESSAGE_FOR_ME_ACTION
      end,
      def decode(96) do
        :BUSINESS_FOLDER_ACTIVATION_ACTION
      end,
      def decode(94) do
        :SHARED_DEVICE_ALLOWLIST_ACTION
      end,
      def decode(84) do
        :SUBSCRIPTIONS_SYNC_V2_ACTION
      end,
      def decode(4) do
        :MUTE_ACTION
      end,
      def decode(72) do
        :AVATAR_UPDATED_ACTION
      end,
      def decode(68) do
        :MAIBA_AI_FEATURES_CONTROL_ACTION
      end,
      def decode(93) do
        :CTWA_MESSAGE_RECEIVED_ACTION
      end,
      def decode(34) do
        :REMOVE_RECENT_STICKER_ACTION
      end,
      def decode(46) do
        :DELETE_INDIVIDUAL_CALL_LOG
      end,
      def decode(52) do
        :WAMO_USER_IDENTIFIER_ACTION
      end,
      def decode(92) do
        :DEVICE_CAPABILITIES_V2
      end,
      def decode(19) do
        :KEY_EXPIRATION
      end,
      def decode(91) do
        :LABEL_SUBLIST_ACTION
      end,
      def decode(41) do
        :PRIVACY_SETTING_RELAY_ALL_CALLS
      end,
      def decode(100) do
        :SHARED_DEVICE_SECRET_ACTION
      end,
      def decode(29) do
        :USER_STATUS_MUTE_ACTION
      end,
      def decode(10001) do
        :SHARE_OWN_PN
      end,
      def decode(13) do
        :LABEL_MESSAGE_ACTION
      end,
      def decode(42) do
        :CALL_LOG_ACTION
      end,
      def decode(55) do
        :NOTE_EDIT_ACTION
      end,
      def decode(2) do
        :STAR_ACTION
      end,
      def decode(98) do
        :BB_PRO_PENDING_CUSTOMER_BASE_ACTION
      end,
      def decode(7) do
        :PUSH_NAME_SETTING
      end,
      def decode(90) do
        :BUBBLE_LOCK_MESSAGE_ACTION
      end,
      def decode(38) do
        :MARKETING_MESSAGE_ACTION
      end,
      def decode(56) do
        :FAVORITES_ACTION
      end,
      def decode(61) do
        :LID_CONTACT_ACTION
      end,
      def decode(99) do
        :COMMUNITY_NESTING_STATE_ACTION
      end,
      def decode(65) do
        :BUSINESS_BROADCAST_ASSOCIATION_ACTION
      end,
      def decode(31) do
        :NUX_ACTION
      end,
      def decode(70) do
        :MUSIC_USER_ID_ACTION
      end,
      def decode(8) do
        :QUICK_REPLY_ACTION
      end,
      def decode(44) do
        :STATUS_PRIVACY
      end,
      def decode(23) do
        :UNARCHIVE_CHATS_SETTING
      end,
      def decode(10003) do
        :AI_THREAD_DELETE_ACTION
      end,
      def decode(82) do
        :BUSINESS_BROADCAST_INSIGHTS_ACTION
      end,
      def decode(49) do
        :CUSTOM_PAYMENT_METHODS_ACTION
      end,
      def decode(79) do
        :OUT_CONTACT_ACTION
      end,
      def decode(71) do
        :STATUS_POST_OPT_IN_NOTIFICATION_PREFERENCES_ACTION
      end,
      def decode(66) do
        :DETECTED_OUTCOMES_STATUS_ACTION
      end,
      def decode(75) do
        :NEWSLETTER_SAVED_INTERESTS_ACTION
      end,
      def decode(10002) do
        :BUSINESS_BROADCAST_ACTION
      end,
      def decode(64) do
        :PRIVACY_SETTING_CHANNELS_PERSONALISED_RECOMMENDATION_ACTION
      end,
      def decode(78) do
        :SETTINGS_SYNC_ACTION
      end,
      def decode(80) do
        :NCT_SALT_SYNC_ACTION
      end,
      def decode(15) do
        :LABEL_ASSOCIATION_ACTION
      end,
      def decode(35) do
        :CHAT_ASSIGNMENT
      end,
      def decode(36) do
        :CHAT_ASSIGNMENT_OPENED_STATUS
      end,
      def decode(76) do
        :AI_THREAD_RENAME_ACTION
      end,
      def decode(97) do
        :GROUP_HISTORY_TOGGLE_ACTION
      end,
      def decode(32) do
        :PRIMARY_VERSION_ACTION
      end,
      def decode(58) do
        :WAFFLE_ACCOUNT_LINK_STATE_ACTION
      end,
      def decode(28) do
        :SUBSCRIPTION_ACTION
      end,
      def decode(60) do
        :NOTIFICATION_ACTIVITY_SETTING_ACTION
      end,
      def decode(20) do
        :MARK_CHAT_AS_READ_ACTION
      end,
      def decode(87) do
        :BIZ_AI_SETTINGS_NUDGE_ACTION
      end,
      def decode(6) do
        :SECURITY_NOTIFICATION_SETTING
      end,
      def decode(95) do
        :CONTACT_MANAGER_METADATA_ACTION
      end,
      def decode(83) do
        :CUSTOMER_DATA_ACTION
      end,
      def decode(43) do
        :UGC_BOT
      end,
      def decode(57) do
        :MERCHANT_PAYMENT_PARTNER_ACTION
      end,
      def decode(11) do
        :RECENT_EMOJI_WEIGHTS_ACTION
      end,
      def decode(81) do
        :BUSINESS_BROADCAST_CAMPAIGN_ACTION
      end,
      def decode(73) do
        :GALAXY_FLOW_ACTION
      end,
      def decode(89) do
        :WASA_ROOT_SECRET_ACTION
      end,
      def decode(88) do
        :COEX_V2_VERSION_ACTION
      end,
      def decode(48) do
        :PAYMENT_INFO_ACTION
      end,
      def decode(17) do
        :ARCHIVE_CHAT_ACTION
      end,
      def decode(24) do
        :PRIMARY_FEATURE
      end,
      def decode(37) do
        :PN_FOR_LID_CHAT_ACTION
      end,
      def decode(40) do
        :EXTERNAL_WEB_BETA_ACTION
      end,
      def decode(14) do
        :LABEL_EDIT_ACTION
      end,
      def decode(33) do
        :STICKER_ACTION
      end,
      def decode(53) do
        :PRIVACY_SETTING_DISABLE_LINK_PREVIEWS_ACTION
      end,
      def decode(3) do
        :CONTACT_ACTION
      end,
      def decode(16) do
        :LOCALE_SETTING
      end,
      def decode(30) do
        :TIME_FORMAT_ACTION
      end,
      def decode(62) do
        :CTWA_PER_CUSTOMER_DATA_SHARING_ACTION
      end,
      def decode(86) do
        :AUTO_ORGANIZE_BUSINESS_CHAT_SETTING
      end,
      def decode(21) do
        :CLEAR_CHAT_ACTION
      end,
      def decode(5) do
        :PIN_ACTION
      end,
      def decode(77) do
        :INTERACTIVE_MESSAGE_ACTION
      end,
      def decode(27) do
        :AGENT_ACTION
      end,
      def decode(85) do
        :THREAD_PIN_ACTION
      end,
      def decode(47) do
        :LABEL_REORDERING_ACTION
      end,
      def decode(63) do
        :PAYMENT_TOS_ACTION
      end,
      def decode(26) do
        :ANDROID_UNSUPPORTED_ACTIONS
      end,
      def decode(51) do
        :CHAT_LOCK_SETTINGS
      end,
      def decode(22) do
        :DELETE_CHAT_ACTION
      end,
      def decode(50) do
        :LOCK_CHAT_ACTION
      end,
      def decode(45) do
        :BOT_WELCOME_REQUEST_ACTION
      end,
      def decode(69) do
        :BUSINESS_BROADCAST_LIST_ACTION
      end,
      def decode(59) do
        :USERNAME_CHAT_START_MODE
      end,
      def decode(74) do
        :PRIVATE_PROCESSING_SETTING_ACTION
      end,
      def decode(39) do
        :MARKETING_MESSAGE_BROADCAST_ACTION
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {2, :STAR_ACTION},
        {3, :CONTACT_ACTION},
        {4, :MUTE_ACTION},
        {5, :PIN_ACTION},
        {6, :SECURITY_NOTIFICATION_SETTING},
        {7, :PUSH_NAME_SETTING},
        {8, :QUICK_REPLY_ACTION},
        {11, :RECENT_EMOJI_WEIGHTS_ACTION},
        {13, :LABEL_MESSAGE_ACTION},
        {14, :LABEL_EDIT_ACTION},
        {15, :LABEL_ASSOCIATION_ACTION},
        {16, :LOCALE_SETTING},
        {17, :ARCHIVE_CHAT_ACTION},
        {18, :DELETE_MESSAGE_FOR_ME_ACTION},
        {19, :KEY_EXPIRATION},
        {20, :MARK_CHAT_AS_READ_ACTION},
        {21, :CLEAR_CHAT_ACTION},
        {22, :DELETE_CHAT_ACTION},
        {23, :UNARCHIVE_CHATS_SETTING},
        {24, :PRIMARY_FEATURE},
        {26, :ANDROID_UNSUPPORTED_ACTIONS},
        {27, :AGENT_ACTION},
        {28, :SUBSCRIPTION_ACTION},
        {29, :USER_STATUS_MUTE_ACTION},
        {30, :TIME_FORMAT_ACTION},
        {31, :NUX_ACTION},
        {32, :PRIMARY_VERSION_ACTION},
        {33, :STICKER_ACTION},
        {34, :REMOVE_RECENT_STICKER_ACTION},
        {35, :CHAT_ASSIGNMENT},
        {36, :CHAT_ASSIGNMENT_OPENED_STATUS},
        {37, :PN_FOR_LID_CHAT_ACTION},
        {38, :MARKETING_MESSAGE_ACTION},
        {39, :MARKETING_MESSAGE_BROADCAST_ACTION},
        {40, :EXTERNAL_WEB_BETA_ACTION},
        {41, :PRIVACY_SETTING_RELAY_ALL_CALLS},
        {42, :CALL_LOG_ACTION},
        {43, :UGC_BOT},
        {44, :STATUS_PRIVACY},
        {45, :BOT_WELCOME_REQUEST_ACTION},
        {46, :DELETE_INDIVIDUAL_CALL_LOG},
        {47, :LABEL_REORDERING_ACTION},
        {48, :PAYMENT_INFO_ACTION},
        {49, :CUSTOM_PAYMENT_METHODS_ACTION},
        {50, :LOCK_CHAT_ACTION},
        {51, :CHAT_LOCK_SETTINGS},
        {52, :WAMO_USER_IDENTIFIER_ACTION},
        {53, :PRIVACY_SETTING_DISABLE_LINK_PREVIEWS_ACTION},
        {54, :DEVICE_CAPABILITIES},
        {55, :NOTE_EDIT_ACTION},
        {56, :FAVORITES_ACTION},
        {57, :MERCHANT_PAYMENT_PARTNER_ACTION},
        {58, :WAFFLE_ACCOUNT_LINK_STATE_ACTION},
        {59, :USERNAME_CHAT_START_MODE},
        {60, :NOTIFICATION_ACTIVITY_SETTING_ACTION},
        {61, :LID_CONTACT_ACTION},
        {62, :CTWA_PER_CUSTOMER_DATA_SHARING_ACTION},
        {63, :PAYMENT_TOS_ACTION},
        {64, :PRIVACY_SETTING_CHANNELS_PERSONALISED_RECOMMENDATION_ACTION},
        {65, :BUSINESS_BROADCAST_ASSOCIATION_ACTION},
        {66, :DETECTED_OUTCOMES_STATUS_ACTION},
        {68, :MAIBA_AI_FEATURES_CONTROL_ACTION},
        {69, :BUSINESS_BROADCAST_LIST_ACTION},
        {70, :MUSIC_USER_ID_ACTION},
        {71, :STATUS_POST_OPT_IN_NOTIFICATION_PREFERENCES_ACTION},
        {72, :AVATAR_UPDATED_ACTION},
        {73, :GALAXY_FLOW_ACTION},
        {74, :PRIVATE_PROCESSING_SETTING_ACTION},
        {75, :NEWSLETTER_SAVED_INTERESTS_ACTION},
        {76, :AI_THREAD_RENAME_ACTION},
        {77, :INTERACTIVE_MESSAGE_ACTION},
        {78, :SETTINGS_SYNC_ACTION},
        {79, :OUT_CONTACT_ACTION},
        {80, :NCT_SALT_SYNC_ACTION},
        {81, :BUSINESS_BROADCAST_CAMPAIGN_ACTION},
        {82, :BUSINESS_BROADCAST_INSIGHTS_ACTION},
        {83, :CUSTOMER_DATA_ACTION},
        {84, :SUBSCRIPTIONS_SYNC_V2_ACTION},
        {85, :THREAD_PIN_ACTION},
        {86, :AUTO_ORGANIZE_BUSINESS_CHAT_SETTING},
        {87, :BIZ_AI_SETTINGS_NUDGE_ACTION},
        {88, :COEX_V2_VERSION_ACTION},
        {89, :WASA_ROOT_SECRET_ACTION},
        {90, :BUBBLE_LOCK_MESSAGE_ACTION},
        {91, :LABEL_SUBLIST_ACTION},
        {92, :DEVICE_CAPABILITIES_V2},
        {93, :CTWA_MESSAGE_RECEIVED_ACTION},
        {94, :SHARED_DEVICE_ALLOWLIST_ACTION},
        {95, :CONTACT_MANAGER_METADATA_ACTION},
        {96, :BUSINESS_FOLDER_ACTIVATION_ACTION},
        {97, :GROUP_HISTORY_TOGGLE_ACTION},
        {98, :BB_PRO_PENDING_CUSTOMER_BASE_ACTION},
        {99, :COMMUNITY_NESTING_STATE_ACTION},
        {100, :SHARED_DEVICE_SECRET_ACTION},
        {10001, :SHARE_OWN_PN},
        {10002, :BUSINESS_BROADCAST_ACTION},
        {10003, :AI_THREAD_DELETE_ACTION}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:STAR_ACTION) do
          true
        end,
        def has_constant?(:CONTACT_ACTION) do
          true
        end,
        def has_constant?(:MUTE_ACTION) do
          true
        end,
        def has_constant?(:PIN_ACTION) do
          true
        end,
        def has_constant?(:SECURITY_NOTIFICATION_SETTING) do
          true
        end,
        def has_constant?(:PUSH_NAME_SETTING) do
          true
        end,
        def has_constant?(:QUICK_REPLY_ACTION) do
          true
        end,
        def has_constant?(:RECENT_EMOJI_WEIGHTS_ACTION) do
          true
        end,
        def has_constant?(:LABEL_MESSAGE_ACTION) do
          true
        end,
        def has_constant?(:LABEL_EDIT_ACTION) do
          true
        end,
        def has_constant?(:LABEL_ASSOCIATION_ACTION) do
          true
        end,
        def has_constant?(:LOCALE_SETTING) do
          true
        end,
        def has_constant?(:ARCHIVE_CHAT_ACTION) do
          true
        end,
        def has_constant?(:DELETE_MESSAGE_FOR_ME_ACTION) do
          true
        end,
        def has_constant?(:KEY_EXPIRATION) do
          true
        end,
        def has_constant?(:MARK_CHAT_AS_READ_ACTION) do
          true
        end,
        def has_constant?(:CLEAR_CHAT_ACTION) do
          true
        end,
        def has_constant?(:DELETE_CHAT_ACTION) do
          true
        end,
        def has_constant?(:UNARCHIVE_CHATS_SETTING) do
          true
        end,
        def has_constant?(:PRIMARY_FEATURE) do
          true
        end,
        def has_constant?(:ANDROID_UNSUPPORTED_ACTIONS) do
          true
        end,
        def has_constant?(:AGENT_ACTION) do
          true
        end,
        def has_constant?(:SUBSCRIPTION_ACTION) do
          true
        end,
        def has_constant?(:USER_STATUS_MUTE_ACTION) do
          true
        end,
        def has_constant?(:TIME_FORMAT_ACTION) do
          true
        end,
        def has_constant?(:NUX_ACTION) do
          true
        end,
        def has_constant?(:PRIMARY_VERSION_ACTION) do
          true
        end,
        def has_constant?(:STICKER_ACTION) do
          true
        end,
        def has_constant?(:REMOVE_RECENT_STICKER_ACTION) do
          true
        end,
        def has_constant?(:CHAT_ASSIGNMENT) do
          true
        end,
        def has_constant?(:CHAT_ASSIGNMENT_OPENED_STATUS) do
          true
        end,
        def has_constant?(:PN_FOR_LID_CHAT_ACTION) do
          true
        end,
        def has_constant?(:MARKETING_MESSAGE_ACTION) do
          true
        end,
        def has_constant?(:MARKETING_MESSAGE_BROADCAST_ACTION) do
          true
        end,
        def has_constant?(:EXTERNAL_WEB_BETA_ACTION) do
          true
        end,
        def has_constant?(:PRIVACY_SETTING_RELAY_ALL_CALLS) do
          true
        end,
        def has_constant?(:CALL_LOG_ACTION) do
          true
        end,
        def has_constant?(:UGC_BOT) do
          true
        end,
        def has_constant?(:STATUS_PRIVACY) do
          true
        end,
        def has_constant?(:BOT_WELCOME_REQUEST_ACTION) do
          true
        end,
        def has_constant?(:DELETE_INDIVIDUAL_CALL_LOG) do
          true
        end,
        def has_constant?(:LABEL_REORDERING_ACTION) do
          true
        end,
        def has_constant?(:PAYMENT_INFO_ACTION) do
          true
        end,
        def has_constant?(:CUSTOM_PAYMENT_METHODS_ACTION) do
          true
        end,
        def has_constant?(:LOCK_CHAT_ACTION) do
          true
        end,
        def has_constant?(:CHAT_LOCK_SETTINGS) do
          true
        end,
        def has_constant?(:WAMO_USER_IDENTIFIER_ACTION) do
          true
        end,
        def has_constant?(:PRIVACY_SETTING_DISABLE_LINK_PREVIEWS_ACTION) do
          true
        end,
        def has_constant?(:DEVICE_CAPABILITIES) do
          true
        end,
        def has_constant?(:NOTE_EDIT_ACTION) do
          true
        end,
        def has_constant?(:FAVORITES_ACTION) do
          true
        end,
        def has_constant?(:MERCHANT_PAYMENT_PARTNER_ACTION) do
          true
        end,
        def has_constant?(:WAFFLE_ACCOUNT_LINK_STATE_ACTION) do
          true
        end,
        def has_constant?(:USERNAME_CHAT_START_MODE) do
          true
        end,
        def has_constant?(:NOTIFICATION_ACTIVITY_SETTING_ACTION) do
          true
        end,
        def has_constant?(:LID_CONTACT_ACTION) do
          true
        end,
        def has_constant?(:CTWA_PER_CUSTOMER_DATA_SHARING_ACTION) do
          true
        end,
        def has_constant?(:PAYMENT_TOS_ACTION) do
          true
        end,
        def has_constant?(:PRIVACY_SETTING_CHANNELS_PERSONALISED_RECOMMENDATION_ACTION) do
          true
        end,
        def has_constant?(:BUSINESS_BROADCAST_ASSOCIATION_ACTION) do
          true
        end,
        def has_constant?(:DETECTED_OUTCOMES_STATUS_ACTION) do
          true
        end,
        def has_constant?(:MAIBA_AI_FEATURES_CONTROL_ACTION) do
          true
        end,
        def has_constant?(:BUSINESS_BROADCAST_LIST_ACTION) do
          true
        end,
        def has_constant?(:MUSIC_USER_ID_ACTION) do
          true
        end,
        def has_constant?(:STATUS_POST_OPT_IN_NOTIFICATION_PREFERENCES_ACTION) do
          true
        end,
        def has_constant?(:AVATAR_UPDATED_ACTION) do
          true
        end,
        def has_constant?(:GALAXY_FLOW_ACTION) do
          true
        end,
        def has_constant?(:PRIVATE_PROCESSING_SETTING_ACTION) do
          true
        end,
        def has_constant?(:NEWSLETTER_SAVED_INTERESTS_ACTION) do
          true
        end,
        def has_constant?(:AI_THREAD_RENAME_ACTION) do
          true
        end,
        def has_constant?(:INTERACTIVE_MESSAGE_ACTION) do
          true
        end,
        def has_constant?(:SETTINGS_SYNC_ACTION) do
          true
        end,
        def has_constant?(:OUT_CONTACT_ACTION) do
          true
        end,
        def has_constant?(:NCT_SALT_SYNC_ACTION) do
          true
        end,
        def has_constant?(:BUSINESS_BROADCAST_CAMPAIGN_ACTION) do
          true
        end,
        def has_constant?(:BUSINESS_BROADCAST_INSIGHTS_ACTION) do
          true
        end,
        def has_constant?(:CUSTOMER_DATA_ACTION) do
          true
        end,
        def has_constant?(:SUBSCRIPTIONS_SYNC_V2_ACTION) do
          true
        end,
        def has_constant?(:THREAD_PIN_ACTION) do
          true
        end,
        def has_constant?(:AUTO_ORGANIZE_BUSINESS_CHAT_SETTING) do
          true
        end,
        def has_constant?(:BIZ_AI_SETTINGS_NUDGE_ACTION) do
          true
        end,
        def has_constant?(:COEX_V2_VERSION_ACTION) do
          true
        end,
        def has_constant?(:WASA_ROOT_SECRET_ACTION) do
          true
        end,
        def has_constant?(:BUBBLE_LOCK_MESSAGE_ACTION) do
          true
        end,
        def has_constant?(:LABEL_SUBLIST_ACTION) do
          true
        end,
        def has_constant?(:DEVICE_CAPABILITIES_V2) do
          true
        end,
        def has_constant?(:CTWA_MESSAGE_RECEIVED_ACTION) do
          true
        end,
        def has_constant?(:SHARED_DEVICE_ALLOWLIST_ACTION) do
          true
        end,
        def has_constant?(:CONTACT_MANAGER_METADATA_ACTION) do
          true
        end,
        def has_constant?(:BUSINESS_FOLDER_ACTIVATION_ACTION) do
          true
        end,
        def has_constant?(:GROUP_HISTORY_TOGGLE_ACTION) do
          true
        end,
        def has_constant?(:BB_PRO_PENDING_CUSTOMER_BASE_ACTION) do
          true
        end,
        def has_constant?(:COMMUNITY_NESTING_STATE_ACTION) do
          true
        end,
        def has_constant?(:SHARED_DEVICE_SECRET_ACTION) do
          true
        end,
        def has_constant?(:SHARE_OWN_PN) do
          true
        end,
        def has_constant?(:BUSINESS_BROADCAST_ACTION) do
          true
        end,
        def has_constant?(:AI_THREAD_DELETE_ACTION) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
