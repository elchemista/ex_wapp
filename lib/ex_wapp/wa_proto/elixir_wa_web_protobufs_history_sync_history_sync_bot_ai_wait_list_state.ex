# credo:disable-for-this-file
defmodule WAWebProtobufsHistorySync.HistorySync.BotAIWaitListState do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :IN_WAITLIST
      def default() do
        :IN_WAITLIST
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:IN_WAITLIST) do
          0
        end

        def encode("IN_WAITLIST") do
          0
        end
      ),
      (
        def encode(:AI_AVAILABLE) do
          1
        end

        def encode("AI_AVAILABLE") do
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
        :IN_WAITLIST
      end,
      def decode(1) do
        :AI_AVAILABLE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :IN_WAITLIST}, {1, :AI_AVAILABLE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:IN_WAITLIST) do
          true
        end,
        def has_constant?(:AI_AVAILABLE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
