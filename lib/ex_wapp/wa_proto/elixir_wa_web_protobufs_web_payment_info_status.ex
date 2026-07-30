# credo:disable-for-this-file
defmodule WAWebProtobufsWeb.PaymentInfo.Status do
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
        def encode(:PROCESSING) do
          1
        end

        def encode("PROCESSING") do
          1
        end
      ),
      (
        def encode(:SENT) do
          2
        end

        def encode("SENT") do
          2
        end
      ),
      (
        def encode(:NEED_TO_ACCEPT) do
          3
        end

        def encode("NEED_TO_ACCEPT") do
          3
        end
      ),
      (
        def encode(:COMPLETE) do
          4
        end

        def encode("COMPLETE") do
          4
        end
      ),
      (
        def encode(:COULD_NOT_COMPLETE) do
          5
        end

        def encode("COULD_NOT_COMPLETE") do
          5
        end
      ),
      (
        def encode(:REFUNDED) do
          6
        end

        def encode("REFUNDED") do
          6
        end
      ),
      (
        def encode(:EXPIRED) do
          7
        end

        def encode("EXPIRED") do
          7
        end
      ),
      (
        def encode(:REJECTED) do
          8
        end

        def encode("REJECTED") do
          8
        end
      ),
      (
        def encode(:CANCELLED) do
          9
        end

        def encode("CANCELLED") do
          9
        end
      ),
      (
        def encode(:WAITING_FOR_PAYER) do
          10
        end

        def encode("WAITING_FOR_PAYER") do
          10
        end
      ),
      (
        def encode(:WAITING) do
          11
        end

        def encode("WAITING") do
          11
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
        :PROCESSING
      end,
      def decode(2) do
        :SENT
      end,
      def decode(3) do
        :NEED_TO_ACCEPT
      end,
      def decode(4) do
        :COMPLETE
      end,
      def decode(5) do
        :COULD_NOT_COMPLETE
      end,
      def decode(6) do
        :REFUNDED
      end,
      def decode(7) do
        :EXPIRED
      end,
      def decode(8) do
        :REJECTED
      end,
      def decode(9) do
        :CANCELLED
      end,
      def decode(10) do
        :WAITING_FOR_PAYER
      end,
      def decode(11) do
        :WAITING
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN_STATUS},
        {1, :PROCESSING},
        {2, :SENT},
        {3, :NEED_TO_ACCEPT},
        {4, :COMPLETE},
        {5, :COULD_NOT_COMPLETE},
        {6, :REFUNDED},
        {7, :EXPIRED},
        {8, :REJECTED},
        {9, :CANCELLED},
        {10, :WAITING_FOR_PAYER},
        {11, :WAITING}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN_STATUS) do
          true
        end,
        def has_constant?(:PROCESSING) do
          true
        end,
        def has_constant?(:SENT) do
          true
        end,
        def has_constant?(:NEED_TO_ACCEPT) do
          true
        end,
        def has_constant?(:COMPLETE) do
          true
        end,
        def has_constant?(:COULD_NOT_COMPLETE) do
          true
        end,
        def has_constant?(:REFUNDED) do
          true
        end,
        def has_constant?(:EXPIRED) do
          true
        end,
        def has_constant?(:REJECTED) do
          true
        end,
        def has_constant?(:CANCELLED) do
          true
        end,
        def has_constant?(:WAITING_FOR_PAYER) do
          true
        end,
        def has_constant?(:WAITING) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
