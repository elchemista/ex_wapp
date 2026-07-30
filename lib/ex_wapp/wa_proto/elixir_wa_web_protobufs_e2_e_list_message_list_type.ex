# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ListMessage.ListType do
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
        def encode(:SINGLE_SELECT) do
          1
        end

        def encode("SINGLE_SELECT") do
          1
        end
      ),
      (
        def encode(:PRODUCT_LIST) do
          2
        end

        def encode("PRODUCT_LIST") do
          2
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
        :SINGLE_SELECT
      end,
      def decode(2) do
        :PRODUCT_LIST
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN}, {1, :SINGLE_SELECT}, {2, :PRODUCT_LIST}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:SINGLE_SELECT) do
          true
        end,
        def has_constant?(:PRODUCT_LIST) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
