# credo:disable-for-this-file
defmodule WAWebProtobufsAICommonDeprecated.AIRichResponseCodeMetadata.AIRichResponseCodeHighlightType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :AI_RICH_RESPONSE_CODE_HIGHLIGHT_DEFAULT
      def default() do
        :AI_RICH_RESPONSE_CODE_HIGHLIGHT_DEFAULT
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:AI_RICH_RESPONSE_CODE_HIGHLIGHT_DEFAULT) do
          0
        end

        def encode("AI_RICH_RESPONSE_CODE_HIGHLIGHT_DEFAULT") do
          0
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_CODE_HIGHLIGHT_KEYWORD) do
          1
        end

        def encode("AI_RICH_RESPONSE_CODE_HIGHLIGHT_KEYWORD") do
          1
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_CODE_HIGHLIGHT_METHOD) do
          2
        end

        def encode("AI_RICH_RESPONSE_CODE_HIGHLIGHT_METHOD") do
          2
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_CODE_HIGHLIGHT_STRING) do
          3
        end

        def encode("AI_RICH_RESPONSE_CODE_HIGHLIGHT_STRING") do
          3
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_CODE_HIGHLIGHT_NUMBER) do
          4
        end

        def encode("AI_RICH_RESPONSE_CODE_HIGHLIGHT_NUMBER") do
          4
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_CODE_HIGHLIGHT_COMMENT) do
          5
        end

        def encode("AI_RICH_RESPONSE_CODE_HIGHLIGHT_COMMENT") do
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
        :AI_RICH_RESPONSE_CODE_HIGHLIGHT_DEFAULT
      end,
      def decode(1) do
        :AI_RICH_RESPONSE_CODE_HIGHLIGHT_KEYWORD
      end,
      def decode(2) do
        :AI_RICH_RESPONSE_CODE_HIGHLIGHT_METHOD
      end,
      def decode(3) do
        :AI_RICH_RESPONSE_CODE_HIGHLIGHT_STRING
      end,
      def decode(4) do
        :AI_RICH_RESPONSE_CODE_HIGHLIGHT_NUMBER
      end,
      def decode(5) do
        :AI_RICH_RESPONSE_CODE_HIGHLIGHT_COMMENT
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :AI_RICH_RESPONSE_CODE_HIGHLIGHT_DEFAULT},
        {1, :AI_RICH_RESPONSE_CODE_HIGHLIGHT_KEYWORD},
        {2, :AI_RICH_RESPONSE_CODE_HIGHLIGHT_METHOD},
        {3, :AI_RICH_RESPONSE_CODE_HIGHLIGHT_STRING},
        {4, :AI_RICH_RESPONSE_CODE_HIGHLIGHT_NUMBER},
        {5, :AI_RICH_RESPONSE_CODE_HIGHLIGHT_COMMENT}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:AI_RICH_RESPONSE_CODE_HIGHLIGHT_DEFAULT) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_CODE_HIGHLIGHT_KEYWORD) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_CODE_HIGHLIGHT_METHOD) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_CODE_HIGHLIGHT_STRING) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_CODE_HIGHLIGHT_NUMBER) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_CODE_HIGHLIGHT_COMMENT) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
