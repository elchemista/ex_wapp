# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ContextInfo.PairedMediaType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :NOT_PAIRED_MEDIA
      def default() do
        :NOT_PAIRED_MEDIA
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:NOT_PAIRED_MEDIA) do
          0
        end

        def encode("NOT_PAIRED_MEDIA") do
          0
        end
      ),
      (
        def encode(:SD_VIDEO_PARENT) do
          1
        end

        def encode("SD_VIDEO_PARENT") do
          1
        end
      ),
      (
        def encode(:HD_VIDEO_CHILD) do
          2
        end

        def encode("HD_VIDEO_CHILD") do
          2
        end
      ),
      (
        def encode(:SD_IMAGE_PARENT) do
          3
        end

        def encode("SD_IMAGE_PARENT") do
          3
        end
      ),
      (
        def encode(:HD_IMAGE_CHILD) do
          4
        end

        def encode("HD_IMAGE_CHILD") do
          4
        end
      ),
      (
        def encode(:MOTION_PHOTO_PARENT) do
          5
        end

        def encode("MOTION_PHOTO_PARENT") do
          5
        end
      ),
      (
        def encode(:MOTION_PHOTO_CHILD) do
          6
        end

        def encode("MOTION_PHOTO_CHILD") do
          6
        end
      ),
      (
        def encode(:HEVC_VIDEO_PARENT) do
          7
        end

        def encode("HEVC_VIDEO_PARENT") do
          7
        end
      ),
      (
        def encode(:HEVC_VIDEO_CHILD) do
          8
        end

        def encode("HEVC_VIDEO_CHILD") do
          8
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :NOT_PAIRED_MEDIA
      end,
      def decode(1) do
        :SD_VIDEO_PARENT
      end,
      def decode(2) do
        :HD_VIDEO_CHILD
      end,
      def decode(3) do
        :SD_IMAGE_PARENT
      end,
      def decode(4) do
        :HD_IMAGE_CHILD
      end,
      def decode(5) do
        :MOTION_PHOTO_PARENT
      end,
      def decode(6) do
        :MOTION_PHOTO_CHILD
      end,
      def decode(7) do
        :HEVC_VIDEO_PARENT
      end,
      def decode(8) do
        :HEVC_VIDEO_CHILD
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :NOT_PAIRED_MEDIA},
        {1, :SD_VIDEO_PARENT},
        {2, :HD_VIDEO_CHILD},
        {3, :SD_IMAGE_PARENT},
        {4, :HD_IMAGE_CHILD},
        {5, :MOTION_PHOTO_PARENT},
        {6, :MOTION_PHOTO_CHILD},
        {7, :HEVC_VIDEO_PARENT},
        {8, :HEVC_VIDEO_CHILD}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NOT_PAIRED_MEDIA) do
          true
        end,
        def has_constant?(:SD_VIDEO_PARENT) do
          true
        end,
        def has_constant?(:HD_VIDEO_CHILD) do
          true
        end,
        def has_constant?(:SD_IMAGE_PARENT) do
          true
        end,
        def has_constant?(:HD_IMAGE_CHILD) do
          true
        end,
        def has_constant?(:MOTION_PHOTO_PARENT) do
          true
        end,
        def has_constant?(:MOTION_PHOTO_CHILD) do
          true
        end,
        def has_constant?(:HEVC_VIDEO_PARENT) do
          true
        end,
        def has_constant?(:HEVC_VIDEO_CHILD) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
