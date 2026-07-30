# credo:disable-for-this-file
defmodule WAAICommonDeprecated.AIRichResponseInlineImageMetadata.AIRichResponseImageAlignment do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :AI_RICH_RESPONSE_IMAGE_LAYOUT_LEADING_ALIGNED
      def default() do
        :AI_RICH_RESPONSE_IMAGE_LAYOUT_LEADING_ALIGNED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:AI_RICH_RESPONSE_IMAGE_LAYOUT_LEADING_ALIGNED) do
          0
        end

        def encode("AI_RICH_RESPONSE_IMAGE_LAYOUT_LEADING_ALIGNED") do
          0
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_IMAGE_LAYOUT_TRAILING_ALIGNED) do
          1
        end

        def encode("AI_RICH_RESPONSE_IMAGE_LAYOUT_TRAILING_ALIGNED") do
          1
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_IMAGE_LAYOUT_CENTER_ALIGNED) do
          2
        end

        def encode("AI_RICH_RESPONSE_IMAGE_LAYOUT_CENTER_ALIGNED") do
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
        :AI_RICH_RESPONSE_IMAGE_LAYOUT_LEADING_ALIGNED
      end,
      def decode(1) do
        :AI_RICH_RESPONSE_IMAGE_LAYOUT_TRAILING_ALIGNED
      end,
      def decode(2) do
        :AI_RICH_RESPONSE_IMAGE_LAYOUT_CENTER_ALIGNED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :AI_RICH_RESPONSE_IMAGE_LAYOUT_LEADING_ALIGNED},
        {1, :AI_RICH_RESPONSE_IMAGE_LAYOUT_TRAILING_ALIGNED},
        {2, :AI_RICH_RESPONSE_IMAGE_LAYOUT_CENTER_ALIGNED}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:AI_RICH_RESPONSE_IMAGE_LAYOUT_LEADING_ALIGNED) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_IMAGE_LAYOUT_TRAILING_ALIGNED) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_IMAGE_LAYOUT_CENTER_ALIGNED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
