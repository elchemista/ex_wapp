# credo:disable-for-this-file
defmodule WAWebProtobufsWeb.PaymentInfo.TxnStatus do
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
        def encode(:PENDING_SETUP) do
          1
        end

        def encode("PENDING_SETUP") do
          1
        end
      ),
      (
        def encode(:PENDING_RECEIVER_SETUP) do
          2
        end

        def encode("PENDING_RECEIVER_SETUP") do
          2
        end
      ),
      (
        def encode(:INIT) do
          3
        end

        def encode("INIT") do
          3
        end
      ),
      (
        def encode(:SUCCESS) do
          4
        end

        def encode("SUCCESS") do
          4
        end
      ),
      (
        def encode(:COMPLETED) do
          5
        end

        def encode("COMPLETED") do
          5
        end
      ),
      (
        def encode(:FAILED) do
          6
        end

        def encode("FAILED") do
          6
        end
      ),
      (
        def encode(:FAILED_RISK) do
          7
        end

        def encode("FAILED_RISK") do
          7
        end
      ),
      (
        def encode(:FAILED_PROCESSING) do
          8
        end

        def encode("FAILED_PROCESSING") do
          8
        end
      ),
      (
        def encode(:FAILED_RECEIVER_PROCESSING) do
          9
        end

        def encode("FAILED_RECEIVER_PROCESSING") do
          9
        end
      ),
      (
        def encode(:FAILED_DA) do
          10
        end

        def encode("FAILED_DA") do
          10
        end
      ),
      (
        def encode(:FAILED_DA_FINAL) do
          11
        end

        def encode("FAILED_DA_FINAL") do
          11
        end
      ),
      (
        def encode(:REFUNDED_TXN) do
          12
        end

        def encode("REFUNDED_TXN") do
          12
        end
      ),
      (
        def encode(:REFUND_FAILED) do
          13
        end

        def encode("REFUND_FAILED") do
          13
        end
      ),
      (
        def encode(:REFUND_FAILED_PROCESSING) do
          14
        end

        def encode("REFUND_FAILED_PROCESSING") do
          14
        end
      ),
      (
        def encode(:REFUND_FAILED_DA) do
          15
        end

        def encode("REFUND_FAILED_DA") do
          15
        end
      ),
      (
        def encode(:EXPIRED_TXN) do
          16
        end

        def encode("EXPIRED_TXN") do
          16
        end
      ),
      (
        def encode(:AUTH_CANCELED) do
          17
        end

        def encode("AUTH_CANCELED") do
          17
        end
      ),
      (
        def encode(:AUTH_CANCEL_FAILED_PROCESSING) do
          18
        end

        def encode("AUTH_CANCEL_FAILED_PROCESSING") do
          18
        end
      ),
      (
        def encode(:AUTH_CANCEL_FAILED) do
          19
        end

        def encode("AUTH_CANCEL_FAILED") do
          19
        end
      ),
      (
        def encode(:COLLECT_INIT) do
          20
        end

        def encode("COLLECT_INIT") do
          20
        end
      ),
      (
        def encode(:COLLECT_SUCCESS) do
          21
        end

        def encode("COLLECT_SUCCESS") do
          21
        end
      ),
      (
        def encode(:COLLECT_FAILED) do
          22
        end

        def encode("COLLECT_FAILED") do
          22
        end
      ),
      (
        def encode(:COLLECT_FAILED_RISK) do
          23
        end

        def encode("COLLECT_FAILED_RISK") do
          23
        end
      ),
      (
        def encode(:COLLECT_REJECTED) do
          24
        end

        def encode("COLLECT_REJECTED") do
          24
        end
      ),
      (
        def encode(:COLLECT_EXPIRED) do
          25
        end

        def encode("COLLECT_EXPIRED") do
          25
        end
      ),
      (
        def encode(:COLLECT_CANCELED) do
          26
        end

        def encode("COLLECT_CANCELED") do
          26
        end
      ),
      (
        def encode(:COLLECT_CANCELLING) do
          27
        end

        def encode("COLLECT_CANCELLING") do
          27
        end
      ),
      (
        def encode(:IN_REVIEW) do
          28
        end

        def encode("IN_REVIEW") do
          28
        end
      ),
      (
        def encode(:REVERSAL_SUCCESS) do
          29
        end

        def encode("REVERSAL_SUCCESS") do
          29
        end
      ),
      (
        def encode(:REVERSAL_PENDING) do
          30
        end

        def encode("REVERSAL_PENDING") do
          30
        end
      ),
      (
        def encode(:REFUND_PENDING) do
          31
        end

        def encode("REFUND_PENDING") do
          31
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
        :PENDING_SETUP
      end,
      def decode(2) do
        :PENDING_RECEIVER_SETUP
      end,
      def decode(3) do
        :INIT
      end,
      def decode(4) do
        :SUCCESS
      end,
      def decode(5) do
        :COMPLETED
      end,
      def decode(6) do
        :FAILED
      end,
      def decode(7) do
        :FAILED_RISK
      end,
      def decode(8) do
        :FAILED_PROCESSING
      end,
      def decode(9) do
        :FAILED_RECEIVER_PROCESSING
      end,
      def decode(10) do
        :FAILED_DA
      end,
      def decode(11) do
        :FAILED_DA_FINAL
      end,
      def decode(12) do
        :REFUNDED_TXN
      end,
      def decode(13) do
        :REFUND_FAILED
      end,
      def decode(14) do
        :REFUND_FAILED_PROCESSING
      end,
      def decode(15) do
        :REFUND_FAILED_DA
      end,
      def decode(16) do
        :EXPIRED_TXN
      end,
      def decode(17) do
        :AUTH_CANCELED
      end,
      def decode(18) do
        :AUTH_CANCEL_FAILED_PROCESSING
      end,
      def decode(19) do
        :AUTH_CANCEL_FAILED
      end,
      def decode(20) do
        :COLLECT_INIT
      end,
      def decode(21) do
        :COLLECT_SUCCESS
      end,
      def decode(22) do
        :COLLECT_FAILED
      end,
      def decode(23) do
        :COLLECT_FAILED_RISK
      end,
      def decode(24) do
        :COLLECT_REJECTED
      end,
      def decode(25) do
        :COLLECT_EXPIRED
      end,
      def decode(26) do
        :COLLECT_CANCELED
      end,
      def decode(27) do
        :COLLECT_CANCELLING
      end,
      def decode(28) do
        :IN_REVIEW
      end,
      def decode(29) do
        :REVERSAL_SUCCESS
      end,
      def decode(30) do
        :REVERSAL_PENDING
      end,
      def decode(31) do
        :REFUND_PENDING
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :PENDING_SETUP},
        {2, :PENDING_RECEIVER_SETUP},
        {3, :INIT},
        {4, :SUCCESS},
        {5, :COMPLETED},
        {6, :FAILED},
        {7, :FAILED_RISK},
        {8, :FAILED_PROCESSING},
        {9, :FAILED_RECEIVER_PROCESSING},
        {10, :FAILED_DA},
        {11, :FAILED_DA_FINAL},
        {12, :REFUNDED_TXN},
        {13, :REFUND_FAILED},
        {14, :REFUND_FAILED_PROCESSING},
        {15, :REFUND_FAILED_DA},
        {16, :EXPIRED_TXN},
        {17, :AUTH_CANCELED},
        {18, :AUTH_CANCEL_FAILED_PROCESSING},
        {19, :AUTH_CANCEL_FAILED},
        {20, :COLLECT_INIT},
        {21, :COLLECT_SUCCESS},
        {22, :COLLECT_FAILED},
        {23, :COLLECT_FAILED_RISK},
        {24, :COLLECT_REJECTED},
        {25, :COLLECT_EXPIRED},
        {26, :COLLECT_CANCELED},
        {27, :COLLECT_CANCELLING},
        {28, :IN_REVIEW},
        {29, :REVERSAL_SUCCESS},
        {30, :REVERSAL_PENDING},
        {31, :REFUND_PENDING}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:PENDING_SETUP) do
          true
        end,
        def has_constant?(:PENDING_RECEIVER_SETUP) do
          true
        end,
        def has_constant?(:INIT) do
          true
        end,
        def has_constant?(:SUCCESS) do
          true
        end,
        def has_constant?(:COMPLETED) do
          true
        end,
        def has_constant?(:FAILED) do
          true
        end,
        def has_constant?(:FAILED_RISK) do
          true
        end,
        def has_constant?(:FAILED_PROCESSING) do
          true
        end,
        def has_constant?(:FAILED_RECEIVER_PROCESSING) do
          true
        end,
        def has_constant?(:FAILED_DA) do
          true
        end,
        def has_constant?(:FAILED_DA_FINAL) do
          true
        end,
        def has_constant?(:REFUNDED_TXN) do
          true
        end,
        def has_constant?(:REFUND_FAILED) do
          true
        end,
        def has_constant?(:REFUND_FAILED_PROCESSING) do
          true
        end,
        def has_constant?(:REFUND_FAILED_DA) do
          true
        end,
        def has_constant?(:EXPIRED_TXN) do
          true
        end,
        def has_constant?(:AUTH_CANCELED) do
          true
        end,
        def has_constant?(:AUTH_CANCEL_FAILED_PROCESSING) do
          true
        end,
        def has_constant?(:AUTH_CANCEL_FAILED) do
          true
        end,
        def has_constant?(:COLLECT_INIT) do
          true
        end,
        def has_constant?(:COLLECT_SUCCESS) do
          true
        end,
        def has_constant?(:COLLECT_FAILED) do
          true
        end,
        def has_constant?(:COLLECT_FAILED_RISK) do
          true
        end,
        def has_constant?(:COLLECT_REJECTED) do
          true
        end,
        def has_constant?(:COLLECT_EXPIRED) do
          true
        end,
        def has_constant?(:COLLECT_CANCELED) do
          true
        end,
        def has_constant?(:COLLECT_CANCELLING) do
          true
        end,
        def has_constant?(:IN_REVIEW) do
          true
        end,
        def has_constant?(:REVERSAL_SUCCESS) do
          true
        end,
        def has_constant?(:REVERSAL_PENDING) do
          true
        end,
        def has_constant?(:REFUND_PENDING) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
