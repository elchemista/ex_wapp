# credo:disable-for-this-file
defmodule WAWebProtobufsWeb.WebMessageInfo.Status do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :ERROR
      def default() do
        :ERROR
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:ERROR) do
          0
        end

        def encode("ERROR") do
          0
        end
      ),
      (
        def encode(:PENDING) do
          1
        end

        def encode("PENDING") do
          1
        end
      ),
      (
        def encode(:SERVER_ACK) do
          2
        end

        def encode("SERVER_ACK") do
          2
        end
      ),
      (
        def encode(:DELIVERY_ACK) do
          3
        end

        def encode("DELIVERY_ACK") do
          3
        end
      ),
      (
        def encode(:READ) do
          4
        end

        def encode("READ") do
          4
        end
      ),
      (
        def encode(:PLAYED) do
          5
        end

        def encode("PLAYED") do
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
        :ERROR
      end,
      def decode(1) do
        :PENDING
      end,
      def decode(2) do
        :SERVER_ACK
      end,
      def decode(3) do
        :DELIVERY_ACK
      end,
      def decode(4) do
        :READ
      end,
      def decode(5) do
        :PLAYED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :ERROR}, {1, :PENDING}, {2, :SERVER_ACK}, {3, :DELIVERY_ACK}, {4, :READ}, {5, :PLAYED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:ERROR) do
          true
        end,
        def has_constant?(:PENDING) do
          true
        end,
        def has_constant?(:SERVER_ACK) do
          true
        end,
        def has_constant?(:DELIVERY_ACK) do
          true
        end,
        def has_constant?(:READ) do
          true
        end,
        def has_constant?(:PLAYED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
