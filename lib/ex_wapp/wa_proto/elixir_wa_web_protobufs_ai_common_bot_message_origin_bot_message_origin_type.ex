# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotMessageOrigin.BotMessageOriginType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :BOT_MESSAGE_ORIGIN_TYPE_AI_INITIATED
      def default() do
        :BOT_MESSAGE_ORIGIN_TYPE_AI_INITIATED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:BOT_MESSAGE_ORIGIN_TYPE_AI_INITIATED) do
          0
        end

        def encode("BOT_MESSAGE_ORIGIN_TYPE_AI_INITIATED") do
          0
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :BOT_MESSAGE_ORIGIN_TYPE_AI_INITIATED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :BOT_MESSAGE_ORIGIN_TYPE_AI_INITIATED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:BOT_MESSAGE_ORIGIN_TYPE_AI_INITIATED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
