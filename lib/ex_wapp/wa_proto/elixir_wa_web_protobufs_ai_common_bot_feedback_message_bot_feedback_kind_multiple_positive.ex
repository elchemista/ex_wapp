# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotFeedbackMessage.BotFeedbackKindMultiplePositive do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :BOT_FEEDBACK_MULTIPLE_POSITIVE_GENERIC
      def default() do
        :BOT_FEEDBACK_MULTIPLE_POSITIVE_GENERIC
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:BOT_FEEDBACK_MULTIPLE_POSITIVE_GENERIC) do
          1
        end

        def encode("BOT_FEEDBACK_MULTIPLE_POSITIVE_GENERIC") do
          1
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :BOT_FEEDBACK_MULTIPLE_POSITIVE_GENERIC
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :BOT_FEEDBACK_MULTIPLE_POSITIVE_GENERIC}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:BOT_FEEDBACK_MULTIPLE_POSITIVE_GENERIC) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
