# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotModelMetadata.PremiumModelStatus do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN_STATUS
      def default() do
        :UNKNOWN_STATUS
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN_STATUS) do
          0
        end

        def encode("UNKNOWN_STATUS") do
          0
        end
      ),
      (
        def encode(:AVAILABLE) do
          1
        end

        def encode("AVAILABLE") do
          1
        end
      ),
      (
        def encode(:QUOTA_EXCEED_LIMIT) do
          2
        end

        def encode("QUOTA_EXCEED_LIMIT") do
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
        :UNKNOWN_STATUS
      end,
      def decode(1) do
        :AVAILABLE
      end,
      def decode(2) do
        :QUOTA_EXCEED_LIMIT
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN_STATUS}, {1, :AVAILABLE}, {2, :QUOTA_EXCEED_LIMIT}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN_STATUS) do
          true
        end,
        def has_constant?(:AVAILABLE) do
          true
        end,
        def has_constant?(:QUOTA_EXCEED_LIMIT) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
