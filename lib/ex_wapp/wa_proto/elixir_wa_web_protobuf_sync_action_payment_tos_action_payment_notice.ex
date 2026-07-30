# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.PaymentTosAction.PaymentNotice do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :BR_PAY_PRIVACY_POLICY
      def default() do
        :BR_PAY_PRIVACY_POLICY
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:BR_PAY_PRIVACY_POLICY) do
          0
        end

        def encode("BR_PAY_PRIVACY_POLICY") do
          0
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :BR_PAY_PRIVACY_POLICY
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :BR_PAY_PRIVACY_POLICY}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:BR_PAY_PRIVACY_POLICY) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
