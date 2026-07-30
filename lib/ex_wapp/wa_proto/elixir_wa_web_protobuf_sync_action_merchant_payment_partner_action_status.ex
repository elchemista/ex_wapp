# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.MerchantPaymentPartnerAction.Status do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :ACTIVE
      def default() do
        :ACTIVE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:ACTIVE) do
          0
        end

        def encode("ACTIVE") do
          0
        end
      ),
      (
        def encode(:INACTIVE) do
          1
        end

        def encode("INACTIVE") do
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
        :ACTIVE
      end,
      def decode(1) do
        :INACTIVE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :ACTIVE}, {1, :INACTIVE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:ACTIVE) do
          true
        end,
        def has_constant?(:INACTIVE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
