# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.LinkPreviewMetadata.SocialMediaPostType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :NONE
      def default() do
        :NONE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:NONE) do
          0
        end

        def encode("NONE") do
          0
        end
      ),
      (
        def encode(:REEL) do
          1
        end

        def encode("REEL") do
          1
        end
      ),
      (
        def encode(:LIVE_VIDEO) do
          2
        end

        def encode("LIVE_VIDEO") do
          2
        end
      ),
      (
        def encode(:LONG_VIDEO) do
          3
        end

        def encode("LONG_VIDEO") do
          3
        end
      ),
      (
        def encode(:SINGLE_IMAGE) do
          4
        end

        def encode("SINGLE_IMAGE") do
          4
        end
      ),
      (
        def encode(:CAROUSEL) do
          5
        end

        def encode("CAROUSEL") do
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
        :NONE
      end,
      def decode(1) do
        :REEL
      end,
      def decode(2) do
        :LIVE_VIDEO
      end,
      def decode(3) do
        :LONG_VIDEO
      end,
      def decode(4) do
        :SINGLE_IMAGE
      end,
      def decode(5) do
        :CAROUSEL
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :NONE},
        {1, :REEL},
        {2, :LIVE_VIDEO},
        {3, :LONG_VIDEO},
        {4, :SINGLE_IMAGE},
        {5, :CAROUSEL}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NONE) do
          true
        end,
        def has_constant?(:REEL) do
          true
        end,
        def has_constant?(:LIVE_VIDEO) do
          true
        end,
        def has_constant?(:LONG_VIDEO) do
          true
        end,
        def has_constant?(:SINGLE_IMAGE) do
          true
        end,
        def has_constant?(:CAROUSEL) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
