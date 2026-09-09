# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotMetricsEntryPoint do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNDEFINED_ENTRY_POINT
      def default() do
        :UNDEFINED_ENTRY_POINT
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNDEFINED_ENTRY_POINT) do
          0
        end

        def encode("UNDEFINED_ENTRY_POINT") do
          0
        end
      ),
      (
        def encode(:FAVICON) do
          1
        end

        def encode("FAVICON") do
          1
        end
      ),
      (
        def encode(:CHATLIST) do
          2
        end

        def encode("CHATLIST") do
          2
        end
      ),
      (
        def encode(:AISEARCH_NULL_STATE_PAPER_PLANE) do
          3
        end

        def encode("AISEARCH_NULL_STATE_PAPER_PLANE") do
          3
        end
      ),
      (
        def encode(:AISEARCH_NULL_STATE_SUGGESTION) do
          4
        end

        def encode("AISEARCH_NULL_STATE_SUGGESTION") do
          4
        end
      ),
      (
        def encode(:AISEARCH_TYPE_AHEAD_SUGGESTION) do
          5
        end

        def encode("AISEARCH_TYPE_AHEAD_SUGGESTION") do
          5
        end
      ),
      (
        def encode(:AISEARCH_TYPE_AHEAD_PAPER_PLANE) do
          6
        end

        def encode("AISEARCH_TYPE_AHEAD_PAPER_PLANE") do
          6
        end
      ),
      (
        def encode(:AISEARCH_TYPE_AHEAD_RESULT_CHATLIST) do
          7
        end

        def encode("AISEARCH_TYPE_AHEAD_RESULT_CHATLIST") do
          7
        end
      ),
      (
        def encode(:AISEARCH_TYPE_AHEAD_RESULT_MESSAGES) do
          8
        end

        def encode("AISEARCH_TYPE_AHEAD_RESULT_MESSAGES") do
          8
        end
      ),
      (
        def encode(:AIVOICE_SEARCH_BAR) do
          9
        end

        def encode("AIVOICE_SEARCH_BAR") do
          9
        end
      ),
      (
        def encode(:AIVOICE_FAVICON) do
          10
        end

        def encode("AIVOICE_FAVICON") do
          10
        end
      ),
      (
        def encode(:AISTUDIO) do
          11
        end

        def encode("AISTUDIO") do
          11
        end
      ),
      (
        def encode(:DEEPLINK) do
          12
        end

        def encode("DEEPLINK") do
          12
        end
      ),
      (
        def encode(:NOTIFICATION) do
          13
        end

        def encode("NOTIFICATION") do
          13
        end
      ),
      (
        def encode(:PROFILE_MESSAGE_BUTTON) do
          14
        end

        def encode("PROFILE_MESSAGE_BUTTON") do
          14
        end
      ),
      (
        def encode(:FORWARD) do
          15
        end

        def encode("FORWARD") do
          15
        end
      ),
      (
        def encode(:APP_SHORTCUT) do
          16
        end

        def encode("APP_SHORTCUT") do
          16
        end
      ),
      (
        def encode(:FF_FAMILY) do
          17
        end

        def encode("FF_FAMILY") do
          17
        end
      ),
      (
        def encode(:AI_TAB) do
          18
        end

        def encode("AI_TAB") do
          18
        end
      ),
      (
        def encode(:AI_HOME) do
          19
        end

        def encode("AI_HOME") do
          19
        end
      ),
      (
        def encode(:AI_DEEPLINK_IMMERSIVE) do
          20
        end

        def encode("AI_DEEPLINK_IMMERSIVE") do
          20
        end
      ),
      (
        def encode(:AI_DEEPLINK) do
          21
        end

        def encode("AI_DEEPLINK") do
          21
        end
      ),
      (
        def encode(:META_AI_CHAT_SHORTCUT_AI_STUDIO) do
          22
        end

        def encode("META_AI_CHAT_SHORTCUT_AI_STUDIO") do
          22
        end
      ),
      (
        def encode(:UGC_CHAT_SHORTCUT_AI_STUDIO) do
          23
        end

        def encode("UGC_CHAT_SHORTCUT_AI_STUDIO") do
          23
        end
      ),
      (
        def encode(:NEW_CHAT_AI_STUDIO) do
          24
        end

        def encode("NEW_CHAT_AI_STUDIO") do
          24
        end
      ),
      (
        def encode(:AIVOICE_FAVICON_CALL_HISTORY) do
          25
        end

        def encode("AIVOICE_FAVICON_CALL_HISTORY") do
          25
        end
      ),
      (
        def encode(:ASK_META_AI_CONTEXT_MENU) do
          26
        end

        def encode("ASK_META_AI_CONTEXT_MENU") do
          26
        end
      ),
      (
        def encode(:ASK_META_AI_CONTEXT_MENU_1ON1) do
          27
        end

        def encode("ASK_META_AI_CONTEXT_MENU_1ON1") do
          27
        end
      ),
      (
        def encode(:ASK_META_AI_CONTEXT_MENU_GROUP) do
          28
        end

        def encode("ASK_META_AI_CONTEXT_MENU_GROUP") do
          28
        end
      ),
      (
        def encode(:INVOKE_META_AI_1ON1) do
          29
        end

        def encode("INVOKE_META_AI_1ON1") do
          29
        end
      ),
      (
        def encode(:INVOKE_META_AI_GROUP) do
          30
        end

        def encode("INVOKE_META_AI_GROUP") do
          30
        end
      ),
      (
        def encode(:META_AI_FORWARD) do
          31
        end

        def encode("META_AI_FORWARD") do
          31
        end
      ),
      (
        def encode(:NEW_CHAT_AI_CONTACT) do
          32
        end

        def encode("NEW_CHAT_AI_CONTACT") do
          32
        end
      ),
      (
        def encode(:MESSAGE_QUICK_ACTION_1_ON_1_CHAT) do
          33
        end

        def encode("MESSAGE_QUICK_ACTION_1_ON_1_CHAT") do
          33
        end
      ),
      (
        def encode(:MESSAGE_QUICK_ACTION_GROUP_CHAT) do
          34
        end

        def encode("MESSAGE_QUICK_ACTION_GROUP_CHAT") do
          34
        end
      ),
      (
        def encode(:ATTACHMENT_TRAY_1_ON_1_CHAT) do
          35
        end

        def encode("ATTACHMENT_TRAY_1_ON_1_CHAT") do
          35
        end
      ),
      (
        def encode(:ATTACHMENT_TRAY_GROUP_CHAT) do
          36
        end

        def encode("ATTACHMENT_TRAY_GROUP_CHAT") do
          36
        end
      ),
      (
        def encode(:ASK_META_AI_MEDIA_VIEWER_1ON1) do
          37
        end

        def encode("ASK_META_AI_MEDIA_VIEWER_1ON1") do
          37
        end
      ),
      (
        def encode(:ASK_META_AI_MEDIA_VIEWER_GROUP) do
          38
        end

        def encode("ASK_META_AI_MEDIA_VIEWER_GROUP") do
          38
        end
      ),
      (
        def encode(:MEDIA_PICKER_1_ON_1_CHAT) do
          39
        end

        def encode("MEDIA_PICKER_1_ON_1_CHAT") do
          39
        end
      ),
      (
        def encode(:MEDIA_PICKER_GROUP_CHAT) do
          40
        end

        def encode("MEDIA_PICKER_GROUP_CHAT") do
          40
        end
      ),
      (
        def encode(:ASK_META_AI_NO_SEARCH_RESULTS) do
          41
        end

        def encode("ASK_META_AI_NO_SEARCH_RESULTS") do
          41
        end
      ),
      (
        def encode(:META_AI_SETTINGS) do
          45
        end

        def encode("META_AI_SETTINGS") do
          45
        end
      ),
      (
        def encode(:WEB_INTRO_PANEL) do
          46
        end

        def encode("WEB_INTRO_PANEL") do
          46
        end
      ),
      (
        def encode(:WEB_NAVIGATION_BAR) do
          47
        end

        def encode("WEB_NAVIGATION_BAR") do
          47
        end
      ),
      (
        def encode(:GROUP_MEMBER) do
          54
        end

        def encode("GROUP_MEMBER") do
          54
        end
      ),
      (
        def encode(:CHATLIST_SEARCH) do
          55
        end

        def encode("CHATLIST_SEARCH") do
          55
        end
      ),
      (
        def encode(:NEW_CHAT_LIST) do
          56
        end

        def encode("NEW_CHAT_LIST") do
          56
        end
      ),
      (
        def encode(:CONTACTS_TAB) do
          57
        end

        def encode("CONTACTS_TAB") do
          57
        end
      ),
      (
        def encode(:NEW_3P_AGENT_CREATION) do
          58
        end

        def encode("NEW_3P_AGENT_CREATION") do
          58
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(54) do
        :GROUP_MEMBER
      end,
      def decode(18) do
        :AI_TAB
      end,
      def decode(4) do
        :AISEARCH_NULL_STATE_SUGGESTION
      end,
      def decode(34) do
        :MESSAGE_QUICK_ACTION_GROUP_CHAT
      end,
      def decode(46) do
        :WEB_INTRO_PANEL
      end,
      def decode(12) do
        :DEEPLINK
      end,
      def decode(19) do
        :AI_HOME
      end,
      def decode(41) do
        :ASK_META_AI_NO_SEARCH_RESULTS
      end,
      def decode(29) do
        :INVOKE_META_AI_1ON1
      end,
      def decode(13) do
        :NOTIFICATION
      end,
      def decode(55) do
        :CHATLIST_SEARCH
      end,
      def decode(2) do
        :CHATLIST
      end,
      def decode(7) do
        :AISEARCH_TYPE_AHEAD_RESULT_CHATLIST
      end,
      def decode(38) do
        :ASK_META_AI_MEDIA_VIEWER_GROUP
      end,
      def decode(56) do
        :NEW_CHAT_LIST
      end,
      def decode(31) do
        :META_AI_FORWARD
      end,
      def decode(8) do
        :AISEARCH_TYPE_AHEAD_RESULT_MESSAGES
      end,
      def decode(10) do
        :AIVOICE_FAVICON
      end,
      def decode(23) do
        :UGC_CHAT_SHORTCUT_AI_STUDIO
      end,
      def decode(9) do
        :AIVOICE_SEARCH_BAR
      end,
      def decode(15) do
        :FORWARD
      end,
      def decode(35) do
        :ATTACHMENT_TRAY_1_ON_1_CHAT
      end,
      def decode(36) do
        :ATTACHMENT_TRAY_GROUP_CHAT
      end,
      def decode(32) do
        :NEW_CHAT_AI_CONTACT
      end,
      def decode(58) do
        :NEW_3P_AGENT_CREATION
      end,
      def decode(1) do
        :FAVICON
      end,
      def decode(25) do
        :AIVOICE_FAVICON_CALL_HISTORY
      end,
      def decode(28) do
        :ASK_META_AI_CONTEXT_MENU_GROUP
      end,
      def decode(20) do
        :AI_DEEPLINK_IMMERSIVE
      end,
      def decode(6) do
        :AISEARCH_TYPE_AHEAD_PAPER_PLANE
      end,
      def decode(57) do
        :CONTACTS_TAB
      end,
      def decode(11) do
        :AISTUDIO
      end,
      def decode(17) do
        :FF_FAMILY
      end,
      def decode(24) do
        :NEW_CHAT_AI_STUDIO
      end,
      def decode(37) do
        :ASK_META_AI_MEDIA_VIEWER_1ON1
      end,
      def decode(40) do
        :MEDIA_PICKER_GROUP_CHAT
      end,
      def decode(14) do
        :PROFILE_MESSAGE_BUTTON
      end,
      def decode(33) do
        :MESSAGE_QUICK_ACTION_1_ON_1_CHAT
      end,
      def decode(3) do
        :AISEARCH_NULL_STATE_PAPER_PLANE
      end,
      def decode(16) do
        :APP_SHORTCUT
      end,
      def decode(30) do
        :INVOKE_META_AI_GROUP
      end,
      def decode(21) do
        :AI_DEEPLINK
      end,
      def decode(5) do
        :AISEARCH_TYPE_AHEAD_SUGGESTION
      end,
      def decode(0) do
        :UNDEFINED_ENTRY_POINT
      end,
      def decode(27) do
        :ASK_META_AI_CONTEXT_MENU_1ON1
      end,
      def decode(47) do
        :WEB_NAVIGATION_BAR
      end,
      def decode(26) do
        :ASK_META_AI_CONTEXT_MENU
      end,
      def decode(22) do
        :META_AI_CHAT_SHORTCUT_AI_STUDIO
      end,
      def decode(45) do
        :META_AI_SETTINGS
      end,
      def decode(39) do
        :MEDIA_PICKER_1_ON_1_CHAT
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNDEFINED_ENTRY_POINT},
        {1, :FAVICON},
        {2, :CHATLIST},
        {3, :AISEARCH_NULL_STATE_PAPER_PLANE},
        {4, :AISEARCH_NULL_STATE_SUGGESTION},
        {5, :AISEARCH_TYPE_AHEAD_SUGGESTION},
        {6, :AISEARCH_TYPE_AHEAD_PAPER_PLANE},
        {7, :AISEARCH_TYPE_AHEAD_RESULT_CHATLIST},
        {8, :AISEARCH_TYPE_AHEAD_RESULT_MESSAGES},
        {9, :AIVOICE_SEARCH_BAR},
        {10, :AIVOICE_FAVICON},
        {11, :AISTUDIO},
        {12, :DEEPLINK},
        {13, :NOTIFICATION},
        {14, :PROFILE_MESSAGE_BUTTON},
        {15, :FORWARD},
        {16, :APP_SHORTCUT},
        {17, :FF_FAMILY},
        {18, :AI_TAB},
        {19, :AI_HOME},
        {20, :AI_DEEPLINK_IMMERSIVE},
        {21, :AI_DEEPLINK},
        {22, :META_AI_CHAT_SHORTCUT_AI_STUDIO},
        {23, :UGC_CHAT_SHORTCUT_AI_STUDIO},
        {24, :NEW_CHAT_AI_STUDIO},
        {25, :AIVOICE_FAVICON_CALL_HISTORY},
        {26, :ASK_META_AI_CONTEXT_MENU},
        {27, :ASK_META_AI_CONTEXT_MENU_1ON1},
        {28, :ASK_META_AI_CONTEXT_MENU_GROUP},
        {29, :INVOKE_META_AI_1ON1},
        {30, :INVOKE_META_AI_GROUP},
        {31, :META_AI_FORWARD},
        {32, :NEW_CHAT_AI_CONTACT},
        {33, :MESSAGE_QUICK_ACTION_1_ON_1_CHAT},
        {34, :MESSAGE_QUICK_ACTION_GROUP_CHAT},
        {35, :ATTACHMENT_TRAY_1_ON_1_CHAT},
        {36, :ATTACHMENT_TRAY_GROUP_CHAT},
        {37, :ASK_META_AI_MEDIA_VIEWER_1ON1},
        {38, :ASK_META_AI_MEDIA_VIEWER_GROUP},
        {39, :MEDIA_PICKER_1_ON_1_CHAT},
        {40, :MEDIA_PICKER_GROUP_CHAT},
        {41, :ASK_META_AI_NO_SEARCH_RESULTS},
        {45, :META_AI_SETTINGS},
        {46, :WEB_INTRO_PANEL},
        {47, :WEB_NAVIGATION_BAR},
        {54, :GROUP_MEMBER},
        {55, :CHATLIST_SEARCH},
        {56, :NEW_CHAT_LIST},
        {57, :CONTACTS_TAB},
        {58, :NEW_3P_AGENT_CREATION}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNDEFINED_ENTRY_POINT) do
          true
        end,
        def has_constant?(:FAVICON) do
          true
        end,
        def has_constant?(:CHATLIST) do
          true
        end,
        def has_constant?(:AISEARCH_NULL_STATE_PAPER_PLANE) do
          true
        end,
        def has_constant?(:AISEARCH_NULL_STATE_SUGGESTION) do
          true
        end,
        def has_constant?(:AISEARCH_TYPE_AHEAD_SUGGESTION) do
          true
        end,
        def has_constant?(:AISEARCH_TYPE_AHEAD_PAPER_PLANE) do
          true
        end,
        def has_constant?(:AISEARCH_TYPE_AHEAD_RESULT_CHATLIST) do
          true
        end,
        def has_constant?(:AISEARCH_TYPE_AHEAD_RESULT_MESSAGES) do
          true
        end,
        def has_constant?(:AIVOICE_SEARCH_BAR) do
          true
        end,
        def has_constant?(:AIVOICE_FAVICON) do
          true
        end,
        def has_constant?(:AISTUDIO) do
          true
        end,
        def has_constant?(:DEEPLINK) do
          true
        end,
        def has_constant?(:NOTIFICATION) do
          true
        end,
        def has_constant?(:PROFILE_MESSAGE_BUTTON) do
          true
        end,
        def has_constant?(:FORWARD) do
          true
        end,
        def has_constant?(:APP_SHORTCUT) do
          true
        end,
        def has_constant?(:FF_FAMILY) do
          true
        end,
        def has_constant?(:AI_TAB) do
          true
        end,
        def has_constant?(:AI_HOME) do
          true
        end,
        def has_constant?(:AI_DEEPLINK_IMMERSIVE) do
          true
        end,
        def has_constant?(:AI_DEEPLINK) do
          true
        end,
        def has_constant?(:META_AI_CHAT_SHORTCUT_AI_STUDIO) do
          true
        end,
        def has_constant?(:UGC_CHAT_SHORTCUT_AI_STUDIO) do
          true
        end,
        def has_constant?(:NEW_CHAT_AI_STUDIO) do
          true
        end,
        def has_constant?(:AIVOICE_FAVICON_CALL_HISTORY) do
          true
        end,
        def has_constant?(:ASK_META_AI_CONTEXT_MENU) do
          true
        end,
        def has_constant?(:ASK_META_AI_CONTEXT_MENU_1ON1) do
          true
        end,
        def has_constant?(:ASK_META_AI_CONTEXT_MENU_GROUP) do
          true
        end,
        def has_constant?(:INVOKE_META_AI_1ON1) do
          true
        end,
        def has_constant?(:INVOKE_META_AI_GROUP) do
          true
        end,
        def has_constant?(:META_AI_FORWARD) do
          true
        end,
        def has_constant?(:NEW_CHAT_AI_CONTACT) do
          true
        end,
        def has_constant?(:MESSAGE_QUICK_ACTION_1_ON_1_CHAT) do
          true
        end,
        def has_constant?(:MESSAGE_QUICK_ACTION_GROUP_CHAT) do
          true
        end,
        def has_constant?(:ATTACHMENT_TRAY_1_ON_1_CHAT) do
          true
        end,
        def has_constant?(:ATTACHMENT_TRAY_GROUP_CHAT) do
          true
        end,
        def has_constant?(:ASK_META_AI_MEDIA_VIEWER_1ON1) do
          true
        end,
        def has_constant?(:ASK_META_AI_MEDIA_VIEWER_GROUP) do
          true
        end,
        def has_constant?(:MEDIA_PICKER_1_ON_1_CHAT) do
          true
        end,
        def has_constant?(:MEDIA_PICKER_GROUP_CHAT) do
          true
        end,
        def has_constant?(:ASK_META_AI_NO_SEARCH_RESULTS) do
          true
        end,
        def has_constant?(:META_AI_SETTINGS) do
          true
        end,
        def has_constant?(:WEB_INTRO_PANEL) do
          true
        end,
        def has_constant?(:WEB_NAVIGATION_BAR) do
          true
        end,
        def has_constant?(:GROUP_MEMBER) do
          true
        end,
        def has_constant?(:CHATLIST_SEARCH) do
          true
        end,
        def has_constant?(:NEW_CHAT_LIST) do
          true
        end,
        def has_constant?(:CONTACTS_TAB) do
          true
        end,
        def has_constant?(:NEW_3P_AGENT_CREATION) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
