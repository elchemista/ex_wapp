# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.OrderMessage.OrderStatus do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :INQUIRY
      def default() do
        :INQUIRY
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:INQUIRY) do
          1
        end

        def encode("INQUIRY") do
          1
        end
      ),
      (
        def encode(:ACCEPTED) do
          2
        end

        def encode("ACCEPTED") do
          2
        end
      ),
      (
        def encode(:DECLINED) do
          3
        end

        def encode("DECLINED") do
          3
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :INQUIRY
      end,
      def decode(2) do
        :ACCEPTED
      end,
      def decode(3) do
        :DECLINED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :INQUIRY}, {2, :ACCEPTED}, {3, :DECLINED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:INQUIRY) do
          true
        end,
        def has_constant?(:ACCEPTED) do
          true
        end,
        def has_constant?(:DECLINED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
