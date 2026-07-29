# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PaymentLinkMetadata.PaymentLinkHeader.PaymentLinkHeaderType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :LINK_PREVIEW
      def default() do
        :LINK_PREVIEW
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:LINK_PREVIEW) do
          0
        end

        def encode("LINK_PREVIEW") do
          0
        end
      ),
      (
        def encode(:ORDER) do
          1
        end

        def encode("ORDER") do
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
        :LINK_PREVIEW
      end,
      def decode(1) do
        :ORDER
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :LINK_PREVIEW}, {1, :ORDER}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:LINK_PREVIEW) do
          true
        end,
        def has_constant?(:ORDER) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
