# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PaymentReminderMessage.ReminderFrequency do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :REMINDER_FREQUENCY_UNKNOWN
      def default() do
        :REMINDER_FREQUENCY_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:REMINDER_FREQUENCY_UNKNOWN) do
          0
        end

        def encode("REMINDER_FREQUENCY_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:WEEKLY) do
          1
        end

        def encode("WEEKLY") do
          1
        end
      ),
      (
        def encode(:BI_WEEKLY) do
          2
        end

        def encode("BI_WEEKLY") do
          2
        end
      ),
      (
        def encode(:MONTHLY) do
          3
        end

        def encode("MONTHLY") do
          3
        end
      ),
      (
        def encode(:QUARTERLY) do
          4
        end

        def encode("QUARTERLY") do
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
        :REMINDER_FREQUENCY_UNKNOWN
      end,
      def decode(1) do
        :WEEKLY
      end,
      def decode(2) do
        :BI_WEEKLY
      end,
      def decode(3) do
        :MONTHLY
      end,
      def decode(4) do
        :QUARTERLY
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :REMINDER_FREQUENCY_UNKNOWN},
        {1, :WEEKLY},
        {2, :BI_WEEKLY},
        {3, :MONTHLY},
        {4, :QUARTERLY}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:REMINDER_FREQUENCY_UNKNOWN) do
          true
        end,
        def has_constant?(:WEEKLY) do
          true
        end,
        def has_constant?(:BI_WEEKLY) do
          true
        end,
        def has_constant?(:MONTHLY) do
          true
        end,
        def has_constant?(:QUARTERLY) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
