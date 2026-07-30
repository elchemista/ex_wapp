# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotAgeCollectionMetadata.AgeCollectionType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :O18_BINARY
      def default() do
        :O18_BINARY
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:O18_BINARY) do
          0
        end

        def encode("O18_BINARY") do
          0
        end
      ),
      (
        def encode(:WAFFLE) do
          1
        end

        def encode("WAFFLE") do
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
        :O18_BINARY
      end,
      def decode(1) do
        :WAFFLE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :O18_BINARY}, {1, :WAFFLE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:O18_BINARY) do
          true
        end,
        def has_constant?(:WAFFLE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
