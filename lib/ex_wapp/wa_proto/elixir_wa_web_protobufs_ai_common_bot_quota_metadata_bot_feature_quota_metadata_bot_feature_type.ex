# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotQuotaMetadata.BotFeatureQuotaMetadata.BotFeatureType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN_FEATURE
      def default() do
        :UNKNOWN_FEATURE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN_FEATURE) do
          0
        end

        def encode("UNKNOWN_FEATURE") do
          0
        end
      ),
      (
        def encode(:REASONING_FEATURE) do
          1
        end

        def encode("REASONING_FEATURE") do
          1
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :UNKNOWN_FEATURE
      end,
      def decode(1) do
        :REASONING_FEATURE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN_FEATURE}, {1, :REASONING_FEATURE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN_FEATURE) do
          true
        end,
        def has_constant?(:REASONING_FEATURE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
