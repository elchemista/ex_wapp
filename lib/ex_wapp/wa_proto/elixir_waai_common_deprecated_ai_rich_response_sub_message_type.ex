# credo:disable-for-this-file
defmodule WAAICommonDeprecated.AIRichResponseSubMessageType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :AI_RICH_RESPONSE_UNKNOWN
      def default() do
        :AI_RICH_RESPONSE_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:AI_RICH_RESPONSE_UNKNOWN) do
          0
        end

        def encode("AI_RICH_RESPONSE_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_GRID_IMAGE) do
          1
        end

        def encode("AI_RICH_RESPONSE_GRID_IMAGE") do
          1
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_TEXT) do
          2
        end

        def encode("AI_RICH_RESPONSE_TEXT") do
          2
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_INLINE_IMAGE) do
          3
        end

        def encode("AI_RICH_RESPONSE_INLINE_IMAGE") do
          3
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_TABLE) do
          4
        end

        def encode("AI_RICH_RESPONSE_TABLE") do
          4
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_CODE) do
          5
        end

        def encode("AI_RICH_RESPONSE_CODE") do
          5
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_DYNAMIC) do
          6
        end

        def encode("AI_RICH_RESPONSE_DYNAMIC") do
          6
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_MAP) do
          7
        end

        def encode("AI_RICH_RESPONSE_MAP") do
          7
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_LATEX) do
          8
        end

        def encode("AI_RICH_RESPONSE_LATEX") do
          8
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_CONTENT_ITEMS) do
          9
        end

        def encode("AI_RICH_RESPONSE_CONTENT_ITEMS") do
          9
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :AI_RICH_RESPONSE_UNKNOWN
      end,
      def decode(1) do
        :AI_RICH_RESPONSE_GRID_IMAGE
      end,
      def decode(2) do
        :AI_RICH_RESPONSE_TEXT
      end,
      def decode(3) do
        :AI_RICH_RESPONSE_INLINE_IMAGE
      end,
      def decode(4) do
        :AI_RICH_RESPONSE_TABLE
      end,
      def decode(5) do
        :AI_RICH_RESPONSE_CODE
      end,
      def decode(6) do
        :AI_RICH_RESPONSE_DYNAMIC
      end,
      def decode(7) do
        :AI_RICH_RESPONSE_MAP
      end,
      def decode(8) do
        :AI_RICH_RESPONSE_LATEX
      end,
      def decode(9) do
        :AI_RICH_RESPONSE_CONTENT_ITEMS
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :AI_RICH_RESPONSE_UNKNOWN},
        {1, :AI_RICH_RESPONSE_GRID_IMAGE},
        {2, :AI_RICH_RESPONSE_TEXT},
        {3, :AI_RICH_RESPONSE_INLINE_IMAGE},
        {4, :AI_RICH_RESPONSE_TABLE},
        {5, :AI_RICH_RESPONSE_CODE},
        {6, :AI_RICH_RESPONSE_DYNAMIC},
        {7, :AI_RICH_RESPONSE_MAP},
        {8, :AI_RICH_RESPONSE_LATEX},
        {9, :AI_RICH_RESPONSE_CONTENT_ITEMS}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:AI_RICH_RESPONSE_UNKNOWN) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_GRID_IMAGE) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_TEXT) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_INLINE_IMAGE) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_TABLE) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_CODE) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_DYNAMIC) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_MAP) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_LATEX) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_CONTENT_ITEMS) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
