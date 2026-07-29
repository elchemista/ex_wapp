# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.InvoiceMessage.AttachmentType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :IMAGE
      def default() do
        :IMAGE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:IMAGE) do
          0
        end

        def encode("IMAGE") do
          0
        end
      ),
      (
        def encode(:PDF) do
          1
        end

        def encode("PDF") do
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
        :IMAGE
      end,
      def decode(1) do
        :PDF
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :IMAGE}, {1, :PDF}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:IMAGE) do
          true
        end,
        def has_constant?(:PDF) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
