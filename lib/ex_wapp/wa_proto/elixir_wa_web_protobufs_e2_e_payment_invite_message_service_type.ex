# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PaymentInviteMessage.ServiceType do
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
        def encode(:FBPAY) do
          1
        end

        def encode("FBPAY") do
          1
        end
      ),
      (
        def encode(:NOVI) do
          2
        end

        def encode("NOVI") do
          2
        end
      ),
      (
        def encode(:UPI) do
          3
        end

        def encode("UPI") do
          3
        end
      ),
      (
        def encode(:PIX) do
          4
        end

        def encode("PIX") do
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
        :FBPAY
      end,
      def decode(2) do
        :NOVI
      end,
      def decode(3) do
        :UPI
      end,
      def decode(4) do
        :PIX
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN}, {1, :FBPAY}, {2, :NOVI}, {3, :UPI}, {4, :PIX}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:FBPAY) do
          true
        end,
        def has_constant?(:NOVI) do
          true
        end,
        def has_constant?(:UPI) do
          true
        end,
        def has_constant?(:PIX) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
