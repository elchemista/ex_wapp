# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotMetricsThreadEntryPoint do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :AI_TAB_THREAD
      def default() do
        :AI_TAB_THREAD
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:AI_TAB_THREAD) do
          1
        end

        def encode("AI_TAB_THREAD") do
          1
        end
      ),
      (
        def encode(:AI_HOME_THREAD) do
          2
        end

        def encode("AI_HOME_THREAD") do
          2
        end
      ),
      (
        def encode(:AI_DEEPLINK_IMMERSIVE_THREAD) do
          3
        end

        def encode("AI_DEEPLINK_IMMERSIVE_THREAD") do
          3
        end
      ),
      (
        def encode(:AI_DEEPLINK_THREAD) do
          4
        end

        def encode("AI_DEEPLINK_THREAD") do
          4
        end
      ),
      (
        def encode(:ASK_META_AI_CONTEXT_MENU_THREAD) do
          5
        end

        def encode("ASK_META_AI_CONTEXT_MENU_THREAD") do
          5
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :AI_TAB_THREAD
      end,
      def decode(2) do
        :AI_HOME_THREAD
      end,
      def decode(3) do
        :AI_DEEPLINK_IMMERSIVE_THREAD
      end,
      def decode(4) do
        :AI_DEEPLINK_THREAD
      end,
      def decode(5) do
        :ASK_META_AI_CONTEXT_MENU_THREAD
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {1, :AI_TAB_THREAD},
        {2, :AI_HOME_THREAD},
        {3, :AI_DEEPLINK_IMMERSIVE_THREAD},
        {4, :AI_DEEPLINK_THREAD},
        {5, :ASK_META_AI_CONTEXT_MENU_THREAD}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:AI_TAB_THREAD) do
          true
        end,
        def has_constant?(:AI_HOME_THREAD) do
          true
        end,
        def has_constant?(:AI_DEEPLINK_IMMERSIVE_THREAD) do
          true
        end,
        def has_constant?(:AI_DEEPLINK_THREAD) do
          true
        end,
        def has_constant?(:ASK_META_AI_CONTEXT_MENU_THREAD) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
