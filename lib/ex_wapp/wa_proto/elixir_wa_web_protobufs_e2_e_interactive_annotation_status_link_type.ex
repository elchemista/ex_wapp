# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.InteractiveAnnotation.StatusLinkType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :RASTERIZED_LINK_PREVIEW
      def default() do
        :RASTERIZED_LINK_PREVIEW
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:RASTERIZED_LINK_PREVIEW) do
          1
        end

        def encode("RASTERIZED_LINK_PREVIEW") do
          1
        end
      ),
      (
        def encode(:RASTERIZED_LINK_TRUNCATED) do
          2
        end

        def encode("RASTERIZED_LINK_TRUNCATED") do
          2
        end
      ),
      (
        def encode(:RASTERIZED_LINK_FULL_URL) do
          3
        end

        def encode("RASTERIZED_LINK_FULL_URL") do
          3
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :RASTERIZED_LINK_PREVIEW
      end,
      def decode(2) do
        :RASTERIZED_LINK_TRUNCATED
      end,
      def decode(3) do
        :RASTERIZED_LINK_FULL_URL
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {1, :RASTERIZED_LINK_PREVIEW},
        {2, :RASTERIZED_LINK_TRUNCATED},
        {3, :RASTERIZED_LINK_FULL_URL}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:RASTERIZED_LINK_PREVIEW) do
          true
        end,
        def has_constant?(:RASTERIZED_LINK_TRUNCATED) do
          true
        end,
        def has_constant?(:RASTERIZED_LINK_FULL_URL) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
