# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.SplitPaymentParticipant.SplitPaymentStatus do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :PENDING
      def default() do
        :PENDING
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:PENDING) do
          0
        end

        def encode("PENDING") do
          0
        end
      ),
      (
        def encode(:PAID) do
          1
        end

        def encode("PAID") do
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
        :PENDING
      end,
      def decode(1) do
        :PAID
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :PENDING}, {1, :PAID}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:PENDING) do
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
