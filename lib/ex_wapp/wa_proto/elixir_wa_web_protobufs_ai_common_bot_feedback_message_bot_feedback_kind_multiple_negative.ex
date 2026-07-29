# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotFeedbackMessage.BotFeedbackKindMultipleNegative do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :BOT_FEEDBACK_MULTIPLE_NEGATIVE_GENERIC
      def default() do
        :BOT_FEEDBACK_MULTIPLE_NEGATIVE_GENERIC
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_GENERIC) do
          1
        end

        def encode("BOT_FEEDBACK_MULTIPLE_NEGATIVE_GENERIC") do
          1
        end
      ),
      (
        def encode(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_HELPFUL) do
          2
        end

        def encode("BOT_FEEDBACK_MULTIPLE_NEGATIVE_HELPFUL") do
          2
        end
      ),
      (
        def encode(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_INTERESTING) do
          4
        end

        def encode("BOT_FEEDBACK_MULTIPLE_NEGATIVE_INTERESTING") do
          4
        end
      ),
      (
        def encode(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_ACCURATE) do
          8
        end

        def encode("BOT_FEEDBACK_MULTIPLE_NEGATIVE_ACCURATE") do
          8
        end
      ),
      (
        def encode(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_SAFE) do
          16
        end

        def encode("BOT_FEEDBACK_MULTIPLE_NEGATIVE_SAFE") do
          16
        end
      ),
      (
        def encode(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_OTHER) do
          32
        end

        def encode("BOT_FEEDBACK_MULTIPLE_NEGATIVE_OTHER") do
          32
        end
      ),
      (
        def encode(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_REFUSED) do
          64
        end

        def encode("BOT_FEEDBACK_MULTIPLE_NEGATIVE_REFUSED") do
          64
        end
      ),
      (
        def encode(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_NOT_VISUALLY_APPEALING) do
          128
        end

        def encode("BOT_FEEDBACK_MULTIPLE_NEGATIVE_NOT_VISUALLY_APPEALING") do
          128
        end
      ),
      (
        def encode(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_NOT_RELEVANT_TO_TEXT) do
          256
        end

        def encode("BOT_FEEDBACK_MULTIPLE_NEGATIVE_NOT_RELEVANT_TO_TEXT") do
          256
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :BOT_FEEDBACK_MULTIPLE_NEGATIVE_GENERIC
      end,
      def decode(2) do
        :BOT_FEEDBACK_MULTIPLE_NEGATIVE_HELPFUL
      end,
      def decode(4) do
        :BOT_FEEDBACK_MULTIPLE_NEGATIVE_INTERESTING
      end,
      def decode(8) do
        :BOT_FEEDBACK_MULTIPLE_NEGATIVE_ACCURATE
      end,
      def decode(16) do
        :BOT_FEEDBACK_MULTIPLE_NEGATIVE_SAFE
      end,
      def decode(32) do
        :BOT_FEEDBACK_MULTIPLE_NEGATIVE_OTHER
      end,
      def decode(64) do
        :BOT_FEEDBACK_MULTIPLE_NEGATIVE_REFUSED
      end,
      def decode(128) do
        :BOT_FEEDBACK_MULTIPLE_NEGATIVE_NOT_VISUALLY_APPEALING
      end,
      def decode(256) do
        :BOT_FEEDBACK_MULTIPLE_NEGATIVE_NOT_RELEVANT_TO_TEXT
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {1, :BOT_FEEDBACK_MULTIPLE_NEGATIVE_GENERIC},
        {2, :BOT_FEEDBACK_MULTIPLE_NEGATIVE_HELPFUL},
        {4, :BOT_FEEDBACK_MULTIPLE_NEGATIVE_INTERESTING},
        {8, :BOT_FEEDBACK_MULTIPLE_NEGATIVE_ACCURATE},
        {16, :BOT_FEEDBACK_MULTIPLE_NEGATIVE_SAFE},
        {32, :BOT_FEEDBACK_MULTIPLE_NEGATIVE_OTHER},
        {64, :BOT_FEEDBACK_MULTIPLE_NEGATIVE_REFUSED},
        {128, :BOT_FEEDBACK_MULTIPLE_NEGATIVE_NOT_VISUALLY_APPEALING},
        {256, :BOT_FEEDBACK_MULTIPLE_NEGATIVE_NOT_RELEVANT_TO_TEXT}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_GENERIC) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_HELPFUL) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_INTERESTING) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_ACCURATE) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_SAFE) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_OTHER) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_REFUSED) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_NOT_VISUALLY_APPEALING) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_MULTIPLE_NEGATIVE_NOT_RELEVANT_TO_TEXT) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
