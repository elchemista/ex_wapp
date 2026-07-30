# credo:disable-for-this-file
defmodule WAWebProtobufsWeb.PaymentInfo.Currency do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN_CURRENCY
      def default() do
        :UNKNOWN_CURRENCY
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN_CURRENCY) do
          0
        end

        def encode("UNKNOWN_CURRENCY") do
          0
        end
      ),
      (
        def encode(:INR) do
          1
        end

        def encode("INR") do
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
        :UNKNOWN_CURRENCY
      end,
      def decode(1) do
        :INR
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN_CURRENCY}, {1, :INR}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN_CURRENCY) do
          true
        end,
        def has_constant?(:INR) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
