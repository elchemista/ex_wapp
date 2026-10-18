# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ProtocolMessage.Type do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :REVOKE
      def default() do
        :REVOKE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:REVOKE) do
          0
        end

        def encode("REVOKE") do
          0
        end
      ),
      (
        def encode(:EPHEMERAL_SETTING) do
          3
        end

        def encode("EPHEMERAL_SETTING") do
          3
        end
      ),
      (
        def encode(:EPHEMERAL_SYNC_RESPONSE) do
          4
        end

        def encode("EPHEMERAL_SYNC_RESPONSE") do
          4
        end
      ),
      (
        def encode(:HISTORY_SYNC_NOTIFICATION) do
          5
        end

        def encode("HISTORY_SYNC_NOTIFICATION") do
          5
        end
      ),
      (
        def encode(:APP_STATE_SYNC_KEY_SHARE) do
          6
        end

        def encode("APP_STATE_SYNC_KEY_SHARE") do
          6
        end
      ),
      (
        def encode(:APP_STATE_SYNC_KEY_REQUEST) do
          7
        end

        def encode("APP_STATE_SYNC_KEY_REQUEST") do
          7
        end
      ),
      (
        def encode(:MSG_FANOUT_BACKFILL_REQUEST) do
          8
        end

        def encode("MSG_FANOUT_BACKFILL_REQUEST") do
          8
        end
      ),
      (
        def encode(:INITIAL_SECURITY_NOTIFICATION_SETTING_SYNC) do
          9
        end

        def encode("INITIAL_SECURITY_NOTIFICATION_SETTING_SYNC") do
          9
        end
      ),
      (
        def encode(:APP_STATE_FATAL_EXCEPTION_NOTIFICATION) do
          10
        end

        def encode("APP_STATE_FATAL_EXCEPTION_NOTIFICATION") do
          10
        end
      ),
      (
        def encode(:SHARE_PHONE_NUMBER) do
          11
        end

        def encode("SHARE_PHONE_NUMBER") do
          11
        end
      ),
      (
        def encode(:MESSAGE_EDIT) do
          14
        end

        def encode("MESSAGE_EDIT") do
          14
        end
      ),
      (
        def encode(:PEER_DATA_OPERATION_REQUEST_MESSAGE) do
          16
        end

        def encode("PEER_DATA_OPERATION_REQUEST_MESSAGE") do
          16
        end
      ),
      (
        def encode(:PEER_DATA_OPERATION_REQUEST_RESPONSE_MESSAGE) do
          17
        end

        def encode("PEER_DATA_OPERATION_REQUEST_RESPONSE_MESSAGE") do
          17
        end
      ),
      (
        def encode(:REQUEST_WELCOME_MESSAGE) do
          18
        end

        def encode("REQUEST_WELCOME_MESSAGE") do
          18
        end
      ),
      (
        def encode(:BOT_FEEDBACK_MESSAGE) do
          19
        end

        def encode("BOT_FEEDBACK_MESSAGE") do
          19
        end
      ),
      (
        def encode(:MEDIA_NOTIFY_MESSAGE) do
          20
        end

        def encode("MEDIA_NOTIFY_MESSAGE") do
          20
        end
      ),
      (
        def encode(:CLOUD_API_THREAD_CONTROL_NOTIFICATION) do
          21
        end

        def encode("CLOUD_API_THREAD_CONTROL_NOTIFICATION") do
          21
        end
      ),
      (
        def encode(:LID_MIGRATION_MAPPING_SYNC) do
          22
        end

        def encode("LID_MIGRATION_MAPPING_SYNC") do
          22
        end
      ),
      (
        def encode(:REMINDER_MESSAGE) do
          23
        end

        def encode("REMINDER_MESSAGE") do
          23
        end
      ),
      (
        def encode(:BOT_MEMU_ONBOARDING_MESSAGE) do
          24
        end

        def encode("BOT_MEMU_ONBOARDING_MESSAGE") do
          24
        end
      ),
      (
        def encode(:STATUS_MENTION_MESSAGE) do
          25
        end

        def encode("STATUS_MENTION_MESSAGE") do
          25
        end
      ),
      (
        def encode(:STOP_GENERATION_MESSAGE) do
          26
        end

        def encode("STOP_GENERATION_MESSAGE") do
          26
        end
      ),
      (
        def encode(:LIMIT_SHARING) do
          27
        end

        def encode("LIMIT_SHARING") do
          27
        end
      ),
      (
        def encode(:AI_PSI_METADATA) do
          28
        end

        def encode("AI_PSI_METADATA") do
          28
        end
      ),
      (
        def encode(:AI_QUERY_FANOUT) do
          29
        end

        def encode("AI_QUERY_FANOUT") do
          29
        end
      ),
      (
        def encode(:GROUP_MEMBER_LABEL_CHANGE) do
          30
        end

        def encode("GROUP_MEMBER_LABEL_CHANGE") do
          30
        end
      ),
      (
        def encode(:AI_MEDIA_COLLECTION_MESSAGE) do
          31
        end

        def encode("AI_MEDIA_COLLECTION_MESSAGE") do
          31
        end
      ),
      (
        def encode(:MESSAGE_UNSCHEDULE) do
          32
        end

        def encode("MESSAGE_UNSCHEDULE") do
          32
        end
      ),
      (
        def encode(:CHAT_THEME_SETTING) do
          34
        end

        def encode("CHAT_THEME_SETTING") do
          34
        end
      ),
      (
        def encode(:AI_METADATA_OPERATION) do
          35
        end

        def encode("AI_METADATA_OPERATION") do
          35
        end
      ),
      (
        def encode(:MARK_AS_VERIFIED_ACTION) do
          36
        end

        def encode("MARK_AS_VERIFIED_ACTION") do
          36
        end
      ),
      (
        def encode(:COEX_STATE_SYNC) do
          37
        end

        def encode("COEX_STATE_SYNC") do
          37
        end
      ),
      (
        def encode(:ACP2_SETTING) do
          39
        end

        def encode("ACP2_SETTING") do
          39
        end
      ),
      (
        def encode(:SHARED_DEVICE_CONTACT_HASH_KEY_SHARE) do
          40
        end

        def encode("SHARED_DEVICE_CONTACT_HASH_KEY_SHARE") do
          40
        end
      ),
      (
        def encode(:SHARED_DEVICE_CONTACT_HASH_KEY_REQUEST) do
          41
        end

        def encode("SHARED_DEVICE_CONTACT_HASH_KEY_REQUEST") do
          41
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(18) do
        :REQUEST_WELCOME_MESSAGE
      end,
      def decode(4) do
        :EPHEMERAL_SYNC_RESPONSE
      end,
      def decode(34) do
        :CHAT_THEME_SETTING
      end,
      def decode(19) do
        :BOT_FEEDBACK_MESSAGE
      end,
      def decode(41) do
        :SHARED_DEVICE_CONTACT_HASH_KEY_REQUEST
      end,
      def decode(29) do
        :AI_QUERY_FANOUT
      end,
      def decode(7) do
        :APP_STATE_SYNC_KEY_REQUEST
      end,
      def decode(31) do
        :AI_MEDIA_COLLECTION_MESSAGE
      end,
      def decode(8) do
        :MSG_FANOUT_BACKFILL_REQUEST
      end,
      def decode(10) do
        :APP_STATE_FATAL_EXCEPTION_NOTIFICATION
      end,
      def decode(23) do
        :REMINDER_MESSAGE
      end,
      def decode(9) do
        :INITIAL_SECURITY_NOTIFICATION_SETTING_SYNC
      end,
      def decode(35) do
        :AI_METADATA_OPERATION
      end,
      def decode(36) do
        :MARK_AS_VERIFIED_ACTION
      end,
      def decode(32) do
        :MESSAGE_UNSCHEDULE
      end,
      def decode(25) do
        :STATUS_MENTION_MESSAGE
      end,
      def decode(28) do
        :AI_PSI_METADATA
      end,
      def decode(20) do
        :MEDIA_NOTIFY_MESSAGE
      end,
      def decode(6) do
        :APP_STATE_SYNC_KEY_SHARE
      end,
      def decode(11) do
        :SHARE_PHONE_NUMBER
      end,
      def decode(17) do
        :PEER_DATA_OPERATION_REQUEST_RESPONSE_MESSAGE
      end,
      def decode(24) do
        :BOT_MEMU_ONBOARDING_MESSAGE
      end,
      def decode(37) do
        :COEX_STATE_SYNC
      end,
      def decode(40) do
        :SHARED_DEVICE_CONTACT_HASH_KEY_SHARE
      end,
      def decode(14) do
        :MESSAGE_EDIT
      end,
      def decode(3) do
        :EPHEMERAL_SETTING
      end,
      def decode(16) do
        :PEER_DATA_OPERATION_REQUEST_MESSAGE
      end,
      def decode(30) do
        :GROUP_MEMBER_LABEL_CHANGE
      end,
      def decode(21) do
        :CLOUD_API_THREAD_CONTROL_NOTIFICATION
      end,
      def decode(5) do
        :HISTORY_SYNC_NOTIFICATION
      end,
      def decode(0) do
        :REVOKE
      end,
      def decode(27) do
        :LIMIT_SHARING
      end,
      def decode(26) do
        :STOP_GENERATION_MESSAGE
      end,
      def decode(22) do
        :LID_MIGRATION_MAPPING_SYNC
      end,
      def decode(39) do
        :ACP2_SETTING
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :REVOKE},
        {3, :EPHEMERAL_SETTING},
        {4, :EPHEMERAL_SYNC_RESPONSE},
        {5, :HISTORY_SYNC_NOTIFICATION},
        {6, :APP_STATE_SYNC_KEY_SHARE},
        {7, :APP_STATE_SYNC_KEY_REQUEST},
        {8, :MSG_FANOUT_BACKFILL_REQUEST},
        {9, :INITIAL_SECURITY_NOTIFICATION_SETTING_SYNC},
        {10, :APP_STATE_FATAL_EXCEPTION_NOTIFICATION},
        {11, :SHARE_PHONE_NUMBER},
        {14, :MESSAGE_EDIT},
        {16, :PEER_DATA_OPERATION_REQUEST_MESSAGE},
        {17, :PEER_DATA_OPERATION_REQUEST_RESPONSE_MESSAGE},
        {18, :REQUEST_WELCOME_MESSAGE},
        {19, :BOT_FEEDBACK_MESSAGE},
        {20, :MEDIA_NOTIFY_MESSAGE},
        {21, :CLOUD_API_THREAD_CONTROL_NOTIFICATION},
        {22, :LID_MIGRATION_MAPPING_SYNC},
        {23, :REMINDER_MESSAGE},
        {24, :BOT_MEMU_ONBOARDING_MESSAGE},
        {25, :STATUS_MENTION_MESSAGE},
        {26, :STOP_GENERATION_MESSAGE},
        {27, :LIMIT_SHARING},
        {28, :AI_PSI_METADATA},
        {29, :AI_QUERY_FANOUT},
        {30, :GROUP_MEMBER_LABEL_CHANGE},
        {31, :AI_MEDIA_COLLECTION_MESSAGE},
        {32, :MESSAGE_UNSCHEDULE},
        {34, :CHAT_THEME_SETTING},
        {35, :AI_METADATA_OPERATION},
        {36, :MARK_AS_VERIFIED_ACTION},
        {37, :COEX_STATE_SYNC},
        {39, :ACP2_SETTING},
        {40, :SHARED_DEVICE_CONTACT_HASH_KEY_SHARE},
        {41, :SHARED_DEVICE_CONTACT_HASH_KEY_REQUEST}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:REVOKE) do
          true
        end,
        def has_constant?(:EPHEMERAL_SETTING) do
          true
        end,
        def has_constant?(:EPHEMERAL_SYNC_RESPONSE) do
          true
        end,
        def has_constant?(:HISTORY_SYNC_NOTIFICATION) do
          true
        end,
        def has_constant?(:APP_STATE_SYNC_KEY_SHARE) do
          true
        end,
        def has_constant?(:APP_STATE_SYNC_KEY_REQUEST) do
          true
        end,
        def has_constant?(:MSG_FANOUT_BACKFILL_REQUEST) do
          true
        end,
        def has_constant?(:INITIAL_SECURITY_NOTIFICATION_SETTING_SYNC) do
          true
        end,
        def has_constant?(:APP_STATE_FATAL_EXCEPTION_NOTIFICATION) do
          true
        end,
        def has_constant?(:SHARE_PHONE_NUMBER) do
          true
        end,
        def has_constant?(:MESSAGE_EDIT) do
          true
        end,
        def has_constant?(:PEER_DATA_OPERATION_REQUEST_MESSAGE) do
          true
        end,
        def has_constant?(:PEER_DATA_OPERATION_REQUEST_RESPONSE_MESSAGE) do
          true
        end,
        def has_constant?(:REQUEST_WELCOME_MESSAGE) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_MESSAGE) do
          true
        end,
        def has_constant?(:MEDIA_NOTIFY_MESSAGE) do
          true
        end,
        def has_constant?(:CLOUD_API_THREAD_CONTROL_NOTIFICATION) do
          true
        end,
        def has_constant?(:LID_MIGRATION_MAPPING_SYNC) do
          true
        end,
        def has_constant?(:REMINDER_MESSAGE) do
          true
        end,
        def has_constant?(:BOT_MEMU_ONBOARDING_MESSAGE) do
          true
        end,
        def has_constant?(:STATUS_MENTION_MESSAGE) do
          true
        end,
        def has_constant?(:STOP_GENERATION_MESSAGE) do
          true
        end,
        def has_constant?(:LIMIT_SHARING) do
          true
        end,
        def has_constant?(:AI_PSI_METADATA) do
          true
        end,
        def has_constant?(:AI_QUERY_FANOUT) do
          true
        end,
        def has_constant?(:GROUP_MEMBER_LABEL_CHANGE) do
          true
        end,
        def has_constant?(:AI_MEDIA_COLLECTION_MESSAGE) do
          true
        end,
        def has_constant?(:MESSAGE_UNSCHEDULE) do
          true
        end,
        def has_constant?(:CHAT_THEME_SETTING) do
          true
        end,
        def has_constant?(:AI_METADATA_OPERATION) do
          true
        end,
        def has_constant?(:MARK_AS_VERIFIED_ACTION) do
          true
        end,
        def has_constant?(:COEX_STATE_SYNC) do
          true
        end,
        def has_constant?(:ACP2_SETTING) do
          true
        end,
        def has_constant?(:SHARED_DEVICE_CONTACT_HASH_KEY_SHARE) do
          true
        end,
        def has_constant?(:SHARED_DEVICE_CONTACT_HASH_KEY_REQUEST) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
