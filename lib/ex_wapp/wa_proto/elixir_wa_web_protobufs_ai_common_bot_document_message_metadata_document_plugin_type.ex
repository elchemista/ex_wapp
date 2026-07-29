# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotDocumentMessageMetadata.DocumentPluginType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :TEXT_EXTRACTION
      def default() do
        :TEXT_EXTRACTION
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:TEXT_EXTRACTION) do
          0
        end

        def encode("TEXT_EXTRACTION") do
          0
        end
      ),
      (
        def encode(:OCR_AND_IMAGES) do
          1
        end

        def encode("OCR_AND_IMAGES") do
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
        :TEXT_EXTRACTION
      end,
      def decode(1) do
        :OCR_AND_IMAGES
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :TEXT_EXTRACTION}, {1, :OCR_AND_IMAGES}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:TEXT_EXTRACTION) do
          true
        end,
        def has_constant?(:OCR_AND_IMAGES) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
