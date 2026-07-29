# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotMediaMetadata.OrientationType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :CENTER
      def default() do
        :CENTER
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:CENTER) do
          1
        end

        def encode("CENTER") do
          1
        end
      ),
      (
        def encode(:LEFT) do
          2
        end

        def encode("LEFT") do
          2
        end
      ),
      (
        def encode(:RIGHT) do
          3
        end

        def encode("RIGHT") do
          3
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :CENTER
      end,
      def decode(2) do
        :LEFT
      end,
      def decode(3) do
        :RIGHT
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :CENTER}, {2, :LEFT}, {3, :RIGHT}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:CENTER) do
          true
        end,
        def has_constant?(:LEFT) do
          true
        end,
        def has_constant?(:RIGHT) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
