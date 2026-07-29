# credo:disable-for-this-file
defmodule WAWebProtobufsAICommonDeprecated.AIRichResponseDynamicMetadata.AIRichResponseDynamicMetadataType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_UNKNOWN
      def default() do
        :AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_UNKNOWN) do
          0
        end

        def encode("AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_IMAGE) do
          1
        end

        def encode("AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_IMAGE") do
          1
        end
      ),
      (
        def encode(:AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_GIF) do
          2
        end

        def encode("AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_GIF") do
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
        :AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_UNKNOWN
      end,
      def decode(1) do
        :AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_IMAGE
      end,
      def decode(2) do
        :AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_GIF
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_UNKNOWN},
        {1, :AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_IMAGE},
        {2, :AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_GIF}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_UNKNOWN) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_IMAGE) do
          true
        end,
        def has_constant?(:AI_RICH_RESPONSE_DYNAMIC_METADATA_TYPE_GIF) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
