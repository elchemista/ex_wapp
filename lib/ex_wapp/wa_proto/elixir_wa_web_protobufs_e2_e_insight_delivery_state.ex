# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.InsightDeliveryState do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :SENT
      def default() do
        :SENT
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:SENT) do
          0
        end

        def encode("SENT") do
          0
        end
      ),
      (
        def encode(:DELIVERED) do
          1
        end

        def encode("DELIVERED") do
          1
        end
      ),
      (
        def encode(:READ) do
          2
        end

        def encode("READ") do
          2
        end
      ),
      (
        def encode(:REPLIED) do
          3
        end

        def encode("REPLIED") do
          3
        end
      ),
      (
        def encode(:QUICK_REPLIED) do
          4
        end

        def encode("QUICK_REPLIED") do
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
        :SENT
      end,
      def decode(1) do
        :DELIVERED
      end,
      def decode(2) do
        :READ
      end,
      def decode(3) do
        :REPLIED
      end,
      def decode(4) do
        :QUICK_REPLIED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :SENT}, {1, :DELIVERED}, {2, :READ}, {3, :REPLIED}, {4, :QUICK_REPLIED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:SENT) do
          true
        end,
        def has_constant?(:DELIVERED) do
          true
        end,
        def has_constant?(:READ) do
          true
        end,
        def has_constant?(:REPLIED) do
          true
        end,
        def has_constant?(:QUICK_REPLIED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
