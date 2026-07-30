# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotReminderMetadata.ReminderFrequency do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :ONCE
      def default() do
        :ONCE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:ONCE) do
          1
        end

        def encode("ONCE") do
          1
        end
      ),
      (
        def encode(:DAILY) do
          2
        end

        def encode("DAILY") do
          2
        end
      ),
      (
        def encode(:WEEKLY) do
          3
        end

        def encode("WEEKLY") do
          3
        end
      ),
      (
        def encode(:BIWEEKLY) do
          4
        end

        def encode("BIWEEKLY") do
          4
        end
      ),
      (
        def encode(:MONTHLY) do
          5
        end

        def encode("MONTHLY") do
          5
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :ONCE
      end,
      def decode(2) do
        :DAILY
      end,
      def decode(3) do
        :WEEKLY
      end,
      def decode(4) do
        :BIWEEKLY
      end,
      def decode(5) do
        :MONTHLY
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :ONCE}, {2, :DAILY}, {3, :WEEKLY}, {4, :BIWEEKLY}, {5, :MONTHLY}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:ONCE) do
          true
        end,
        def has_constant?(:DAILY) do
          true
        end,
        def has_constant?(:WEEKLY) do
          true
        end,
        def has_constant?(:BIWEEKLY) do
          true
        end,
        def has_constant?(:MONTHLY) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
