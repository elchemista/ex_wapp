# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PaymentReminderMessage.ReminderStatus do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :REMINDER_STATUS_UNKNOWN
      def default() do
        :REMINDER_STATUS_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:REMINDER_STATUS_UNKNOWN) do
          0
        end

        def encode("REMINDER_STATUS_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:ACTIVE) do
          1
        end

        def encode("ACTIVE") do
          1
        end
      ),
      (
        def encode(:CANCELLED_BY_CREATOR) do
          2
        end

        def encode("CANCELLED_BY_CREATOR") do
          2
        end
      ),
      (
        def encode(:STOPPED_BY_RECEIVER) do
          3
        end

        def encode("STOPPED_BY_RECEIVER") do
          3
        end
      ),
      (
        def encode(:EXPIRED) do
          4
        end

        def encode("EXPIRED") do
          4
        end
      ),
      (
        def encode(:PAID) do
          5
        end

        def encode("PAID") do
          5
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :REMINDER_STATUS_UNKNOWN
      end,
      def decode(1) do
        :ACTIVE
      end,
      def decode(2) do
        :CANCELLED_BY_CREATOR
      end,
      def decode(3) do
        :STOPPED_BY_RECEIVER
      end,
      def decode(4) do
        :EXPIRED
      end,
      def decode(5) do
        :PAID
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :REMINDER_STATUS_UNKNOWN},
        {1, :ACTIVE},
        {2, :CANCELLED_BY_CREATOR},
        {3, :STOPPED_BY_RECEIVER},
        {4, :EXPIRED},
        {5, :PAID}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:REMINDER_STATUS_UNKNOWN) do
          true
        end,
        def has_constant?(:ACTIVE) do
          true
        end,
        def has_constant?(:CANCELLED_BY_CREATOR) do
          true
        end,
        def has_constant?(:STOPPED_BY_RECEIVER) do
          true
        end,
        def has_constant?(:EXPIRED) do
          true
        end,
        def has_constant?(:PAID) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
