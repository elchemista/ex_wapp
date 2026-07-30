# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotPromotionMessageMetadata.BotPromotionType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN_TYPE
      def default() do
        :UNKNOWN_TYPE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN_TYPE) do
          0
        end

        def encode("UNKNOWN_TYPE") do
          0
        end
      ),
      (
        def encode(:C50) do
          1
        end

        def encode("C50") do
          1
        end
      ),
      (
        def encode(:SURVEY_PLATFORM) do
          2
        end

        def encode("SURVEY_PLATFORM") do
          2
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :UNKNOWN_TYPE
      end,
      def decode(1) do
        :C50
      end,
      def decode(2) do
        :SURVEY_PLATFORM
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN_TYPE}, {1, :C50}, {2, :SURVEY_PLATFORM}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN_TYPE) do
          true
        end,
        def has_constant?(:C50) do
          true
        end,
        def has_constant?(:SURVEY_PLATFORM) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
