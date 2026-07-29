# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotFeedbackMessage.BotFeedbackKind do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :BOT_FEEDBACK_POSITIVE
      def default() do
        :BOT_FEEDBACK_POSITIVE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:BOT_FEEDBACK_POSITIVE) do
          0
        end

        def encode("BOT_FEEDBACK_POSITIVE") do
          0
        end
      ),
      (
        def encode(:BOT_FEEDBACK_NEGATIVE_GENERIC) do
          1
        end

        def encode("BOT_FEEDBACK_NEGATIVE_GENERIC") do
          1
        end
      ),
      (
        def encode(:BOT_FEEDBACK_NEGATIVE_HELPFUL) do
          2
        end

        def encode("BOT_FEEDBACK_NEGATIVE_HELPFUL") do
          2
        end
      ),
      (
        def encode(:BOT_FEEDBACK_NEGATIVE_INTERESTING) do
          3
        end

        def encode("BOT_FEEDBACK_NEGATIVE_INTERESTING") do
          3
        end
      ),
      (
        def encode(:BOT_FEEDBACK_NEGATIVE_ACCURATE) do
          4
        end

        def encode("BOT_FEEDBACK_NEGATIVE_ACCURATE") do
          4
        end
      ),
      (
        def encode(:BOT_FEEDBACK_NEGATIVE_SAFE) do
          5
        end

        def encode("BOT_FEEDBACK_NEGATIVE_SAFE") do
          5
        end
      ),
      (
        def encode(:BOT_FEEDBACK_NEGATIVE_OTHER) do
          6
        end

        def encode("BOT_FEEDBACK_NEGATIVE_OTHER") do
          6
        end
      ),
      (
        def encode(:BOT_FEEDBACK_NEGATIVE_REFUSED) do
          7
        end

        def encode("BOT_FEEDBACK_NEGATIVE_REFUSED") do
          7
        end
      ),
      (
        def encode(:BOT_FEEDBACK_NEGATIVE_NOT_VISUALLY_APPEALING) do
          8
        end

        def encode("BOT_FEEDBACK_NEGATIVE_NOT_VISUALLY_APPEALING") do
          8
        end
      ),
      (
        def encode(:BOT_FEEDBACK_NEGATIVE_NOT_RELEVANT_TO_TEXT) do
          9
        end

        def encode("BOT_FEEDBACK_NEGATIVE_NOT_RELEVANT_TO_TEXT") do
          9
        end
      ),
      (
        def encode(:BOT_FEEDBACK_NEGATIVE_PERSONALIZED) do
          10
        end

        def encode("BOT_FEEDBACK_NEGATIVE_PERSONALIZED") do
          10
        end
      ),
      (
        def encode(:BOT_FEEDBACK_NEGATIVE_CLARITY) do
          11
        end

        def encode("BOT_FEEDBACK_NEGATIVE_CLARITY") do
          11
        end
      ),
      (
        def encode(:BOT_FEEDBACK_NEGATIVE_DOESNT_LOOK_LIKE_THE_PERSON) do
          12
        end

        def encode("BOT_FEEDBACK_NEGATIVE_DOESNT_LOOK_LIKE_THE_PERSON") do
          12
        end
      ),
      (
        def encode(:BOT_FEEDBACK_NEGATIVE_HALLUCINATION_INTERNAL_ONLY) do
          13
        end

        def encode("BOT_FEEDBACK_NEGATIVE_HALLUCINATION_INTERNAL_ONLY") do
          13
        end
      ),
      (
        def encode(:BOT_FEEDBACK_NEGATIVE) do
          14
        end

        def encode("BOT_FEEDBACK_NEGATIVE") do
          14
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :BOT_FEEDBACK_POSITIVE
      end,
      def decode(1) do
        :BOT_FEEDBACK_NEGATIVE_GENERIC
      end,
      def decode(2) do
        :BOT_FEEDBACK_NEGATIVE_HELPFUL
      end,
      def decode(3) do
        :BOT_FEEDBACK_NEGATIVE_INTERESTING
      end,
      def decode(4) do
        :BOT_FEEDBACK_NEGATIVE_ACCURATE
      end,
      def decode(5) do
        :BOT_FEEDBACK_NEGATIVE_SAFE
      end,
      def decode(6) do
        :BOT_FEEDBACK_NEGATIVE_OTHER
      end,
      def decode(7) do
        :BOT_FEEDBACK_NEGATIVE_REFUSED
      end,
      def decode(8) do
        :BOT_FEEDBACK_NEGATIVE_NOT_VISUALLY_APPEALING
      end,
      def decode(9) do
        :BOT_FEEDBACK_NEGATIVE_NOT_RELEVANT_TO_TEXT
      end,
      def decode(10) do
        :BOT_FEEDBACK_NEGATIVE_PERSONALIZED
      end,
      def decode(11) do
        :BOT_FEEDBACK_NEGATIVE_CLARITY
      end,
      def decode(12) do
        :BOT_FEEDBACK_NEGATIVE_DOESNT_LOOK_LIKE_THE_PERSON
      end,
      def decode(13) do
        :BOT_FEEDBACK_NEGATIVE_HALLUCINATION_INTERNAL_ONLY
      end,
      def decode(14) do
        :BOT_FEEDBACK_NEGATIVE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :BOT_FEEDBACK_POSITIVE},
        {1, :BOT_FEEDBACK_NEGATIVE_GENERIC},
        {2, :BOT_FEEDBACK_NEGATIVE_HELPFUL},
        {3, :BOT_FEEDBACK_NEGATIVE_INTERESTING},
        {4, :BOT_FEEDBACK_NEGATIVE_ACCURATE},
        {5, :BOT_FEEDBACK_NEGATIVE_SAFE},
        {6, :BOT_FEEDBACK_NEGATIVE_OTHER},
        {7, :BOT_FEEDBACK_NEGATIVE_REFUSED},
        {8, :BOT_FEEDBACK_NEGATIVE_NOT_VISUALLY_APPEALING},
        {9, :BOT_FEEDBACK_NEGATIVE_NOT_RELEVANT_TO_TEXT},
        {10, :BOT_FEEDBACK_NEGATIVE_PERSONALIZED},
        {11, :BOT_FEEDBACK_NEGATIVE_CLARITY},
        {12, :BOT_FEEDBACK_NEGATIVE_DOESNT_LOOK_LIKE_THE_PERSON},
        {13, :BOT_FEEDBACK_NEGATIVE_HALLUCINATION_INTERNAL_ONLY},
        {14, :BOT_FEEDBACK_NEGATIVE}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:BOT_FEEDBACK_POSITIVE) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_NEGATIVE_GENERIC) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_NEGATIVE_HELPFUL) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_NEGATIVE_INTERESTING) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_NEGATIVE_ACCURATE) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_NEGATIVE_SAFE) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_NEGATIVE_OTHER) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_NEGATIVE_REFUSED) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_NEGATIVE_NOT_VISUALLY_APPEALING) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_NEGATIVE_NOT_RELEVANT_TO_TEXT) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_NEGATIVE_PERSONALIZED) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_NEGATIVE_CLARITY) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_NEGATIVE_DOESNT_LOOK_LIKE_THE_PERSON) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_NEGATIVE_HALLUCINATION_INTERNAL_ONLY) do
          true
        end,
        def has_constant?(:BOT_FEEDBACK_NEGATIVE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
