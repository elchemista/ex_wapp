# credo:disable-for-this-file
defmodule WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ReverseHistorySync.Product do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :PRODUCT_UNSPECIFIED
      def default() do
        :PRODUCT_UNSPECIFIED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:PRODUCT_UNSPECIFIED) do
          0
        end

        def encode("PRODUCT_UNSPECIFIED") do
          0
        end
      ),
      (
        def encode(:HATCH) do
          1
        end

        def encode("HATCH") do
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
        :PRODUCT_UNSPECIFIED
      end,
      def decode(1) do
        :HATCH
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :PRODUCT_UNSPECIFIED}, {1, :HATCH}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:PRODUCT_UNSPECIFIED) do
          true
        end,
        def has_constant?(:HATCH) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
