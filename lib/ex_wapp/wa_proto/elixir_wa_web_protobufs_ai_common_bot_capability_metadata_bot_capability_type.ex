# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotCapabilityMetadata.BotCapabilityType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN
      def default() do
        :UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN) do
          0
        end

        def encode("UNKNOWN") do
          0
        end
      ),
      (
        def encode(:PROGRESS_INDICATOR) do
          1
        end

        def encode("PROGRESS_INDICATOR") do
          1
        end
      ),
      (
        def encode(:RICH_RESPONSE_HEADING) do
          2
        end

        def encode("RICH_RESPONSE_HEADING") do
          2
        end
      ),
      (
        def encode(:RICH_RESPONSE_NESTED_LIST) do
          3
        end

        def encode("RICH_RESPONSE_NESTED_LIST") do
          3
        end
      ),
      (
        def encode(:AI_MEMORY) do
          4
        end

        def encode("AI_MEMORY") do
          4
        end
      ),
      (
        def encode(:RICH_RESPONSE_THREAD_SURFING) do
          5
        end

        def encode("RICH_RESPONSE_THREAD_SURFING") do
          5
        end
      ),
      (
        def encode(:RICH_RESPONSE_TABLE) do
          6
        end

        def encode("RICH_RESPONSE_TABLE") do
          6
        end
      ),
      (
        def encode(:RICH_RESPONSE_CODE) do
          7
        end

        def encode("RICH_RESPONSE_CODE") do
          7
        end
      ),
      (
        def encode(:RICH_RESPONSE_STRUCTURED_RESPONSE) do
          8
        end

        def encode("RICH_RESPONSE_STRUCTURED_RESPONSE") do
          8
        end
      ),
      (
        def encode(:RICH_RESPONSE_INLINE_IMAGE) do
          9
        end

        def encode("RICH_RESPONSE_INLINE_IMAGE") do
          9
        end
      ),
      (
        def encode(:WA_IG_1P_PLUGIN_RANKING_CONTROL) do
          10
        end

        def encode("WA_IG_1P_PLUGIN_RANKING_CONTROL") do
          10
        end
      ),
      (
        def encode(:WA_IG_1P_PLUGIN_RANKING_UPDATE_1) do
          11
        end

        def encode("WA_IG_1P_PLUGIN_RANKING_UPDATE_1") do
          11
        end
      ),
      (
        def encode(:WA_IG_1P_PLUGIN_RANKING_UPDATE_2) do
          12
        end

        def encode("WA_IG_1P_PLUGIN_RANKING_UPDATE_2") do
          12
        end
      ),
      (
        def encode(:WA_IG_1P_PLUGIN_RANKING_UPDATE_3) do
          13
        end

        def encode("WA_IG_1P_PLUGIN_RANKING_UPDATE_3") do
          13
        end
      ),
      (
        def encode(:WA_IG_1P_PLUGIN_RANKING_UPDATE_4) do
          14
        end

        def encode("WA_IG_1P_PLUGIN_RANKING_UPDATE_4") do
          14
        end
      ),
      (
        def encode(:WA_IG_1P_PLUGIN_RANKING_UPDATE_5) do
          15
        end

        def encode("WA_IG_1P_PLUGIN_RANKING_UPDATE_5") do
          15
        end
      ),
      (
        def encode(:WA_IG_1P_PLUGIN_RANKING_UPDATE_6) do
          16
        end

        def encode("WA_IG_1P_PLUGIN_RANKING_UPDATE_6") do
          16
        end
      ),
      (
        def encode(:WA_IG_1P_PLUGIN_RANKING_UPDATE_7) do
          17
        end

        def encode("WA_IG_1P_PLUGIN_RANKING_UPDATE_7") do
          17
        end
      ),
      (
        def encode(:WA_IG_1P_PLUGIN_RANKING_UPDATE_8) do
          18
        end

        def encode("WA_IG_1P_PLUGIN_RANKING_UPDATE_8") do
          18
        end
      ),
      (
        def encode(:WA_IG_1P_PLUGIN_RANKING_UPDATE_9) do
          19
        end

        def encode("WA_IG_1P_PLUGIN_RANKING_UPDATE_9") do
          19
        end
      ),
      (
        def encode(:WA_IG_1P_PLUGIN_RANKING_UPDATE_10) do
          20
        end

        def encode("WA_IG_1P_PLUGIN_RANKING_UPDATE_10") do
          20
        end
      ),
      (
        def encode(:RICH_RESPONSE_SUB_HEADING) do
          21
        end

        def encode("RICH_RESPONSE_SUB_HEADING") do
          21
        end
      ),
      (
        def encode(:RICH_RESPONSE_GRID_IMAGE) do
          22
        end

        def encode("RICH_RESPONSE_GRID_IMAGE") do
          22
        end
      ),
      (
        def encode(:AI_STUDIO_UGC_MEMORY) do
          23
        end

        def encode("AI_STUDIO_UGC_MEMORY") do
          23
        end
      ),
      (
        def encode(:RICH_RESPONSE_LATEX) do
          24
        end

        def encode("RICH_RESPONSE_LATEX") do
          24
        end
      ),
      (
        def encode(:RICH_RESPONSE_MAPS) do
          25
        end

        def encode("RICH_RESPONSE_MAPS") do
          25
        end
      ),
      (
        def encode(:RICH_RESPONSE_INLINE_REELS) do
          26
        end

        def encode("RICH_RESPONSE_INLINE_REELS") do
          26
        end
      ),
      (
        def encode(:AGENTIC_PLANNING) do
          27
        end

        def encode("AGENTIC_PLANNING") do
          27
        end
      ),
      (
        def encode(:ACCOUNT_LINKING) do
          28
        end

        def encode("ACCOUNT_LINKING") do
          28
        end
      ),
      (
        def encode(:STREAMING_DISAGGREGATION) do
          29
        end

        def encode("STREAMING_DISAGGREGATION") do
          29
        end
      ),
      (
        def encode(:RICH_RESPONSE_GRID_IMAGE_3P) do
          30
        end

        def encode("RICH_RESPONSE_GRID_IMAGE_3P") do
          30
        end
      ),
      (
        def encode(:RICH_RESPONSE_LATEX_INLINE) do
          31
        end

        def encode("RICH_RESPONSE_LATEX_INLINE") do
          31
        end
      ),
      (
        def encode(:QUERY_PLAN) do
          32
        end

        def encode("QUERY_PLAN") do
          32
        end
      ),
      (
        def encode(:PROACTIVE_MESSAGE) do
          33
        end

        def encode("PROACTIVE_MESSAGE") do
          33
        end
      ),
      (
        def encode(:RICH_RESPONSE_UNIFIED_RESPONSE) do
          34
        end

        def encode("RICH_RESPONSE_UNIFIED_RESPONSE") do
          34
        end
      ),
      (
        def encode(:PROMOTION_MESSAGE) do
          35
        end

        def encode("PROMOTION_MESSAGE") do
          35
        end
      ),
      (
        def encode(:SIMPLIFIED_PROFILE_PAGE) do
          36
        end

        def encode("SIMPLIFIED_PROFILE_PAGE") do
          36
        end
      ),
      (
        def encode(:RICH_RESPONSE_SOURCES_IN_MESSAGE) do
          37
        end

        def encode("RICH_RESPONSE_SOURCES_IN_MESSAGE") do
          37
        end
      ),
      (
        def encode(:RICH_RESPONSE_SIDE_BY_SIDE_SURVEY) do
          38
        end

        def encode("RICH_RESPONSE_SIDE_BY_SIDE_SURVEY") do
          38
        end
      ),
      (
        def encode(:RICH_RESPONSE_UNIFIED_TEXT_COMPONENT) do
          39
        end

        def encode("RICH_RESPONSE_UNIFIED_TEXT_COMPONENT") do
          39
        end
      ),
      (
        def encode(:AI_SHARED_MEMORY) do
          40
        end

        def encode("AI_SHARED_MEMORY") do
          40
        end
      ),
      (
        def encode(:RICH_RESPONSE_UNIFIED_SOURCES) do
          41
        end

        def encode("RICH_RESPONSE_UNIFIED_SOURCES") do
          41
        end
      ),
      (
        def encode(:RICH_RESPONSE_UNIFIED_DOMAIN_CITATIONS) do
          42
        end

        def encode("RICH_RESPONSE_UNIFIED_DOMAIN_CITATIONS") do
          42
        end
      ),
      (
        def encode(:RICH_RESPONSE_UR_INLINE_REELS_ENABLED) do
          43
        end

        def encode("RICH_RESPONSE_UR_INLINE_REELS_ENABLED") do
          43
        end
      ),
      (
        def encode(:RICH_RESPONSE_UR_MEDIA_GRID_ENABLED) do
          44
        end

        def encode("RICH_RESPONSE_UR_MEDIA_GRID_ENABLED") do
          44
        end
      ),
      (
        def encode(:RICH_RESPONSE_UR_TIMESTAMP_PLACEHOLDER) do
          45
        end

        def encode("RICH_RESPONSE_UR_TIMESTAMP_PLACEHOLDER") do
          45
        end
      ),
      (
        def encode(:RICH_RESPONSE_IN_APP_SURVEY) do
          46
        end

        def encode("RICH_RESPONSE_IN_APP_SURVEY") do
          46
        end
      ),
      (
        def encode(:AI_RESPONSE_MODEL_BRANDING) do
          47
        end

        def encode("AI_RESPONSE_MODEL_BRANDING") do
          47
        end
      ),
      (
        def encode(:SESSION_TRANSPARENCY_SYSTEM_MESSAGE) do
          48
        end

        def encode("SESSION_TRANSPARENCY_SYSTEM_MESSAGE") do
          48
        end
      ),
      (
        def encode(:RICH_RESPONSE_UR_REASONING) do
          49
        end

        def encode("RICH_RESPONSE_UR_REASONING") do
          49
        end
      ),
      (
        def encode(:RICH_RESPONSE_UR_ZEITGEIST_CITATIONS) do
          50
        end

        def encode("RICH_RESPONSE_UR_ZEITGEIST_CITATIONS") do
          50
        end
      ),
      (
        def encode(:RICH_RESPONSE_UR_ZEITGEIST_CAROUSEL) do
          51
        end

        def encode("RICH_RESPONSE_UR_ZEITGEIST_CAROUSEL") do
          51
        end
      ),
      (
        def encode(:AI_IMAGINE_LOADING_INDICATOR) do
          52
        end

        def encode("AI_IMAGINE_LOADING_INDICATOR") do
          52
        end
      ),
      (
        def encode(:RICH_RESPONSE_UR_IMAGINE) do
          53
        end

        def encode("RICH_RESPONSE_UR_IMAGINE") do
          53
        end
      ),
      (
        def encode(:AI_IMAGINE_UR_TO_NATIVE_LOADING_INDICATOR) do
          54
        end

        def encode("AI_IMAGINE_UR_TO_NATIVE_LOADING_INDICATOR") do
          54
        end
      ),
      (
        def encode(:RICH_RESPONSE_UR_BLOKS_ENABLED) do
          55
        end

        def encode("RICH_RESPONSE_UR_BLOKS_ENABLED") do
          55
        end
      ),
      (
        def encode(:RICH_RESPONSE_INLINE_LINKS_ENABLED) do
          56
        end

        def encode("RICH_RESPONSE_INLINE_LINKS_ENABLED") do
          56
        end
      ),
      (
        def encode(:RICH_RESPONSE_UR_IMAGINE_VIDEO) do
          57
        end

        def encode("RICH_RESPONSE_UR_IMAGINE_VIDEO") do
          57
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(54) do
        :AI_IMAGINE_UR_TO_NATIVE_LOADING_INDICATOR
      end,
      def decode(18) do
        :WA_IG_1P_PLUGIN_RANKING_UPDATE_8
      end,
      def decode(4) do
        :AI_MEMORY
      end,
      def decode(34) do
        :RICH_RESPONSE_UNIFIED_RESPONSE
      end,
      def decode(46) do
        :RICH_RESPONSE_IN_APP_SURVEY
      end,
      def decode(52) do
        :AI_IMAGINE_LOADING_INDICATOR
      end,
      def decode(12) do
        :WA_IG_1P_PLUGIN_RANKING_UPDATE_2
      end,
      def decode(19) do
        :WA_IG_1P_PLUGIN_RANKING_UPDATE_9
      end,
      def decode(41) do
        :RICH_RESPONSE_UNIFIED_SOURCES
      end,
      def decode(29) do
        :STREAMING_DISAGGREGATION
      end,
      def decode(13) do
        :WA_IG_1P_PLUGIN_RANKING_UPDATE_3
      end,
      def decode(42) do
        :RICH_RESPONSE_UNIFIED_DOMAIN_CITATIONS
      end,
      def decode(55) do
        :RICH_RESPONSE_UR_BLOKS_ENABLED
      end,
      def decode(2) do
        :RICH_RESPONSE_HEADING
      end,
      def decode(7) do
        :RICH_RESPONSE_CODE
      end,
      def decode(38) do
        :RICH_RESPONSE_SIDE_BY_SIDE_SURVEY
      end,
      def decode(56) do
        :RICH_RESPONSE_INLINE_LINKS_ENABLED
      end,
      def decode(31) do
        :RICH_RESPONSE_LATEX_INLINE
      end,
      def decode(8) do
        :RICH_RESPONSE_STRUCTURED_RESPONSE
      end,
      def decode(44) do
        :RICH_RESPONSE_UR_MEDIA_GRID_ENABLED
      end,
      def decode(10) do
        :WA_IG_1P_PLUGIN_RANKING_CONTROL
      end,
      def decode(23) do
        :AI_STUDIO_UGC_MEMORY
      end,
      def decode(9) do
        :RICH_RESPONSE_INLINE_IMAGE
      end,
      def decode(49) do
        :RICH_RESPONSE_UR_REASONING
      end,
      def decode(15) do
        :WA_IG_1P_PLUGIN_RANKING_UPDATE_5
      end,
      def decode(35) do
        :PROMOTION_MESSAGE
      end,
      def decode(36) do
        :SIMPLIFIED_PROFILE_PAGE
      end,
      def decode(32) do
        :QUERY_PLAN
      end,
      def decode(1) do
        :PROGRESS_INDICATOR
      end,
      def decode(25) do
        :RICH_RESPONSE_MAPS
      end,
      def decode(28) do
        :ACCOUNT_LINKING
      end,
      def decode(20) do
        :WA_IG_1P_PLUGIN_RANKING_UPDATE_10
      end,
      def decode(6) do
        :RICH_RESPONSE_TABLE
      end,
      def decode(43) do
        :RICH_RESPONSE_UR_INLINE_REELS_ENABLED
      end,
      def decode(57) do
        :RICH_RESPONSE_UR_IMAGINE_VIDEO
      end,
      def decode(11) do
        :WA_IG_1P_PLUGIN_RANKING_UPDATE_1
      end,
      def decode(48) do
        :SESSION_TRANSPARENCY_SYSTEM_MESSAGE
      end,
      def decode(17) do
        :WA_IG_1P_PLUGIN_RANKING_UPDATE_7
      end,
      def decode(24) do
        :RICH_RESPONSE_LATEX
      end,
      def decode(37) do
        :RICH_RESPONSE_SOURCES_IN_MESSAGE
      end,
      def decode(40) do
        :AI_SHARED_MEMORY
      end,
      def decode(14) do
        :WA_IG_1P_PLUGIN_RANKING_UPDATE_4
      end,
      def decode(33) do
        :PROACTIVE_MESSAGE
      end,
      def decode(53) do
        :RICH_RESPONSE_UR_IMAGINE
      end,
      def decode(3) do
        :RICH_RESPONSE_NESTED_LIST
      end,
      def decode(16) do
        :WA_IG_1P_PLUGIN_RANKING_UPDATE_6
      end,
      def decode(30) do
        :RICH_RESPONSE_GRID_IMAGE_3P
      end,
      def decode(21) do
        :RICH_RESPONSE_SUB_HEADING
      end,
      def decode(5) do
        :RICH_RESPONSE_THREAD_SURFING
      end,
      def decode(0) do
        :UNKNOWN
      end,
      def decode(27) do
        :AGENTIC_PLANNING
      end,
      def decode(47) do
        :AI_RESPONSE_MODEL_BRANDING
      end,
      def decode(26) do
        :RICH_RESPONSE_INLINE_REELS
      end,
      def decode(51) do
        :RICH_RESPONSE_UR_ZEITGEIST_CAROUSEL
      end,
      def decode(22) do
        :RICH_RESPONSE_GRID_IMAGE
      end,
      def decode(50) do
        :RICH_RESPONSE_UR_ZEITGEIST_CITATIONS
      end,
      def decode(45) do
        :RICH_RESPONSE_UR_TIMESTAMP_PLACEHOLDER
      end,
      def decode(39) do
        :RICH_RESPONSE_UNIFIED_TEXT_COMPONENT
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :PROGRESS_INDICATOR},
        {2, :RICH_RESPONSE_HEADING},
        {3, :RICH_RESPONSE_NESTED_LIST},
        {4, :AI_MEMORY},
        {5, :RICH_RESPONSE_THREAD_SURFING},
        {6, :RICH_RESPONSE_TABLE},
        {7, :RICH_RESPONSE_CODE},
        {8, :RICH_RESPONSE_STRUCTURED_RESPONSE},
        {9, :RICH_RESPONSE_INLINE_IMAGE},
        {10, :WA_IG_1P_PLUGIN_RANKING_CONTROL},
        {11, :WA_IG_1P_PLUGIN_RANKING_UPDATE_1},
        {12, :WA_IG_1P_PLUGIN_RANKING_UPDATE_2},
        {13, :WA_IG_1P_PLUGIN_RANKING_UPDATE_3},
        {14, :WA_IG_1P_PLUGIN_RANKING_UPDATE_4},
        {15, :WA_IG_1P_PLUGIN_RANKING_UPDATE_5},
        {16, :WA_IG_1P_PLUGIN_RANKING_UPDATE_6},
        {17, :WA_IG_1P_PLUGIN_RANKING_UPDATE_7},
        {18, :WA_IG_1P_PLUGIN_RANKING_UPDATE_8},
        {19, :WA_IG_1P_PLUGIN_RANKING_UPDATE_9},
        {20, :WA_IG_1P_PLUGIN_RANKING_UPDATE_10},
        {21, :RICH_RESPONSE_SUB_HEADING},
        {22, :RICH_RESPONSE_GRID_IMAGE},
        {23, :AI_STUDIO_UGC_MEMORY},
        {24, :RICH_RESPONSE_LATEX},
        {25, :RICH_RESPONSE_MAPS},
        {26, :RICH_RESPONSE_INLINE_REELS},
        {27, :AGENTIC_PLANNING},
        {28, :ACCOUNT_LINKING},
        {29, :STREAMING_DISAGGREGATION},
        {30, :RICH_RESPONSE_GRID_IMAGE_3P},
        {31, :RICH_RESPONSE_LATEX_INLINE},
        {32, :QUERY_PLAN},
        {33, :PROACTIVE_MESSAGE},
        {34, :RICH_RESPONSE_UNIFIED_RESPONSE},
        {35, :PROMOTION_MESSAGE},
        {36, :SIMPLIFIED_PROFILE_PAGE},
        {37, :RICH_RESPONSE_SOURCES_IN_MESSAGE},
        {38, :RICH_RESPONSE_SIDE_BY_SIDE_SURVEY},
        {39, :RICH_RESPONSE_UNIFIED_TEXT_COMPONENT},
        {40, :AI_SHARED_MEMORY},
        {41, :RICH_RESPONSE_UNIFIED_SOURCES},
        {42, :RICH_RESPONSE_UNIFIED_DOMAIN_CITATIONS},
        {43, :RICH_RESPONSE_UR_INLINE_REELS_ENABLED},
        {44, :RICH_RESPONSE_UR_MEDIA_GRID_ENABLED},
        {45, :RICH_RESPONSE_UR_TIMESTAMP_PLACEHOLDER},
        {46, :RICH_RESPONSE_IN_APP_SURVEY},
        {47, :AI_RESPONSE_MODEL_BRANDING},
        {48, :SESSION_TRANSPARENCY_SYSTEM_MESSAGE},
        {49, :RICH_RESPONSE_UR_REASONING},
        {50, :RICH_RESPONSE_UR_ZEITGEIST_CITATIONS},
        {51, :RICH_RESPONSE_UR_ZEITGEIST_CAROUSEL},
        {52, :AI_IMAGINE_LOADING_INDICATOR},
        {53, :RICH_RESPONSE_UR_IMAGINE},
        {54, :AI_IMAGINE_UR_TO_NATIVE_LOADING_INDICATOR},
        {55, :RICH_RESPONSE_UR_BLOKS_ENABLED},
        {56, :RICH_RESPONSE_INLINE_LINKS_ENABLED},
        {57, :RICH_RESPONSE_UR_IMAGINE_VIDEO}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:PROGRESS_INDICATOR) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_HEADING) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_NESTED_LIST) do
          true
        end,
        def has_constant?(:AI_MEMORY) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_THREAD_SURFING) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_TABLE) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_CODE) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_STRUCTURED_RESPONSE) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_INLINE_IMAGE) do
          true
        end,
        def has_constant?(:WA_IG_1P_PLUGIN_RANKING_CONTROL) do
          true
        end,
        def has_constant?(:WA_IG_1P_PLUGIN_RANKING_UPDATE_1) do
          true
        end,
        def has_constant?(:WA_IG_1P_PLUGIN_RANKING_UPDATE_2) do
          true
        end,
        def has_constant?(:WA_IG_1P_PLUGIN_RANKING_UPDATE_3) do
          true
        end,
        def has_constant?(:WA_IG_1P_PLUGIN_RANKING_UPDATE_4) do
          true
        end,
        def has_constant?(:WA_IG_1P_PLUGIN_RANKING_UPDATE_5) do
          true
        end,
        def has_constant?(:WA_IG_1P_PLUGIN_RANKING_UPDATE_6) do
          true
        end,
        def has_constant?(:WA_IG_1P_PLUGIN_RANKING_UPDATE_7) do
          true
        end,
        def has_constant?(:WA_IG_1P_PLUGIN_RANKING_UPDATE_8) do
          true
        end,
        def has_constant?(:WA_IG_1P_PLUGIN_RANKING_UPDATE_9) do
          true
        end,
        def has_constant?(:WA_IG_1P_PLUGIN_RANKING_UPDATE_10) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_SUB_HEADING) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_GRID_IMAGE) do
          true
        end,
        def has_constant?(:AI_STUDIO_UGC_MEMORY) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_LATEX) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_MAPS) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_INLINE_REELS) do
          true
        end,
        def has_constant?(:AGENTIC_PLANNING) do
          true
        end,
        def has_constant?(:ACCOUNT_LINKING) do
          true
        end,
        def has_constant?(:STREAMING_DISAGGREGATION) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_GRID_IMAGE_3P) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_LATEX_INLINE) do
          true
        end,
        def has_constant?(:QUERY_PLAN) do
          true
        end,
        def has_constant?(:PROACTIVE_MESSAGE) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_UNIFIED_RESPONSE) do
          true
        end,
        def has_constant?(:PROMOTION_MESSAGE) do
          true
        end,
        def has_constant?(:SIMPLIFIED_PROFILE_PAGE) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_SOURCES_IN_MESSAGE) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_SIDE_BY_SIDE_SURVEY) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_UNIFIED_TEXT_COMPONENT) do
          true
        end,
        def has_constant?(:AI_SHARED_MEMORY) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_UNIFIED_SOURCES) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_UNIFIED_DOMAIN_CITATIONS) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_UR_INLINE_REELS_ENABLED) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_UR_MEDIA_GRID_ENABLED) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_UR_TIMESTAMP_PLACEHOLDER) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_IN_APP_SURVEY) do
          true
        end,
        def has_constant?(:AI_RESPONSE_MODEL_BRANDING) do
          true
        end,
        def has_constant?(:SESSION_TRANSPARENCY_SYSTEM_MESSAGE) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_UR_REASONING) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_UR_ZEITGEIST_CITATIONS) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_UR_ZEITGEIST_CAROUSEL) do
          true
        end,
        def has_constant?(:AI_IMAGINE_LOADING_INDICATOR) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_UR_IMAGINE) do
          true
        end,
        def has_constant?(:AI_IMAGINE_UR_TO_NATIVE_LOADING_INDICATOR) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_UR_BLOKS_ENABLED) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_INLINE_LINKS_ENABLED) do
          true
        end,
        def has_constant?(:RICH_RESPONSE_UR_IMAGINE_VIDEO) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
