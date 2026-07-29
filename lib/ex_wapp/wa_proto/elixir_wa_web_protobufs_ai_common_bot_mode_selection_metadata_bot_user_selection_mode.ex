# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotModeSelectionMetadata.BotUserSelectionMode do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :DEFAULT_MODE
      def default() do
        :DEFAULT_MODE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:DEFAULT_MODE) do
          0
        end

        def encode("DEFAULT_MODE") do
          0
        end
      ),
      (
        def encode(:THINK_HARD_MODE) do
          1
        end

        def encode("THINK_HARD_MODE") do
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
        :DEFAULT_MODE
      end,
      def decode(1) do
        :THINK_HARD_MODE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :DEFAULT_MODE}, {1, :THINK_HARD_MODE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:DEFAULT_MODE) do
          true
        end,
        def has_constant?(:THINK_HARD_MODE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
