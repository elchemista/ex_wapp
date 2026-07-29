# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotSourcesMetadata.BotSourceItem.SourceProvider do
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
        def encode(:BING) do
          1
        end

        def encode("BING") do
          1
        end
      ),
      (
        def encode(:GOOGLE) do
          2
        end

        def encode("GOOGLE") do
          2
        end
      ),
      (
        def encode(:SUPPORT) do
          3
        end

        def encode("SUPPORT") do
          3
        end
      ),
      (
        def encode(:OTHER) do
          4
        end

        def encode("OTHER") do
          4
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :UNKNOWN
      end,
      def decode(1) do
        :BING
      end,
      def decode(2) do
        :GOOGLE
      end,
      def decode(3) do
        :SUPPORT
      end,
      def decode(4) do
        :OTHER
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN}, {1, :BING}, {2, :GOOGLE}, {3, :SUPPORT}, {4, :OTHER}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:BING) do
          true
        end,
        def has_constant?(:GOOGLE) do
          true
        end,
        def has_constant?(:SUPPORT) do
          true
        end,
        def has_constant?(:OTHER) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
