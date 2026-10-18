# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.MessageAssociation.AssociationType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN
      def default() do
        :UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN) do
          0
        end

        def encode("UNKNOWN") do
          0
        end
      ),
      (
        def encode(:MEDIA_ALBUM) do
          1
        end

        def encode("MEDIA_ALBUM") do
          1
        end
      ),
      (
        def encode(:BOT_PLUGIN) do
          2
        end

        def encode("BOT_PLUGIN") do
          2
        end
      ),
      (
        def encode(:EVENT_COVER_IMAGE) do
          3
        end

        def encode("EVENT_COVER_IMAGE") do
          3
        end
      ),
      (
        def encode(:STATUS_POLL) do
          4
        end

        def encode("STATUS_POLL") do
          4
        end
      ),
      (
        def encode(:HD_VIDEO_DUAL_UPLOAD) do
          5
        end

        def encode("HD_VIDEO_DUAL_UPLOAD") do
          5
        end
      ),
      (
        def encode(:STATUS_EXTERNAL_RESHARE) do
          6
        end

        def encode("STATUS_EXTERNAL_RESHARE") do
          6
        end
      ),
      (
        def encode(:MEDIA_POLL) do
          7
        end

        def encode("MEDIA_POLL") do
          7
        end
      ),
      (
        def encode(:STATUS_ADD_YOURS) do
          8
        end

        def encode("STATUS_ADD_YOURS") do
          8
        end
      ),
      (
        def encode(:STATUS_NOTIFICATION) do
          9
        end

        def encode("STATUS_NOTIFICATION") do
          9
        end
      ),
      (
        def encode(:HD_IMAGE_DUAL_UPLOAD) do
          10
        end

        def encode("HD_IMAGE_DUAL_UPLOAD") do
          10
        end
      ),
      (
        def encode(:STICKER_ANNOTATION) do
          11
        end

        def encode("STICKER_ANNOTATION") do
          11
        end
      ),
      (
        def encode(:MOTION_PHOTO) do
          12
        end

        def encode("MOTION_PHOTO") do
          12
        end
      ),
      (
        def encode(:STATUS_LINK_ACTION) do
          13
        end

        def encode("STATUS_LINK_ACTION") do
          13
        end
      ),
      (
        def encode(:VIEW_ALL_REPLIES) do
          14
        end

        def encode("VIEW_ALL_REPLIES") do
          14
        end
      ),
      (
        def encode(:STATUS_ADD_YOURS_AI_IMAGINE) do
          15
        end

        def encode("STATUS_ADD_YOURS_AI_IMAGINE") do
          15
        end
      ),
      (
        def encode(:STATUS_QUESTION) do
          16
        end

        def encode("STATUS_QUESTION") do
          16
        end
      ),
      (
        def encode(:STATUS_ADD_YOURS_DIWALI) do
          17
        end

        def encode("STATUS_ADD_YOURS_DIWALI") do
          17
        end
      ),
      (
        def encode(:STATUS_REACTION) do
          18
        end

        def encode("STATUS_REACTION") do
          18
        end
      ),
      (
        def encode(:HEVC_VIDEO_DUAL_UPLOAD) do
          19
        end

        def encode("HEVC_VIDEO_DUAL_UPLOAD") do
          19
        end
      ),
      (
        def encode(:POLL_ADD_OPTION) do
          20
        end

        def encode("POLL_ADD_OPTION") do
          20
        end
      ),
      (
        def encode(:AV1_VIDEO_DUAL_UPLOAD) do
          21
        end

        def encode("AV1_VIDEO_DUAL_UPLOAD") do
          21
        end
      ),
      (
        def encode(:STREAMED_HD_VIDEO_DUAL_UPLOAD) do
          22
        end

        def encode("STREAMED_HD_VIDEO_DUAL_UPLOAD") do
          22
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :UNKNOWN
      end,
      def decode(1) do
        :MEDIA_ALBUM
      end,
      def decode(2) do
        :BOT_PLUGIN
      end,
      def decode(3) do
        :EVENT_COVER_IMAGE
      end,
      def decode(4) do
        :STATUS_POLL
      end,
      def decode(5) do
        :HD_VIDEO_DUAL_UPLOAD
      end,
      def decode(6) do
        :STATUS_EXTERNAL_RESHARE
      end,
      def decode(7) do
        :MEDIA_POLL
      end,
      def decode(8) do
        :STATUS_ADD_YOURS
      end,
      def decode(9) do
        :STATUS_NOTIFICATION
      end,
      def decode(10) do
        :HD_IMAGE_DUAL_UPLOAD
      end,
      def decode(11) do
        :STICKER_ANNOTATION
      end,
      def decode(12) do
        :MOTION_PHOTO
      end,
      def decode(13) do
        :STATUS_LINK_ACTION
      end,
      def decode(14) do
        :VIEW_ALL_REPLIES
      end,
      def decode(15) do
        :STATUS_ADD_YOURS_AI_IMAGINE
      end,
      def decode(16) do
        :STATUS_QUESTION
      end,
      def decode(17) do
        :STATUS_ADD_YOURS_DIWALI
      end,
      def decode(18) do
        :STATUS_REACTION
      end,
      def decode(19) do
        :HEVC_VIDEO_DUAL_UPLOAD
      end,
      def decode(20) do
        :POLL_ADD_OPTION
      end,
      def decode(21) do
        :AV1_VIDEO_DUAL_UPLOAD
      end,
      def decode(22) do
        :STREAMED_HD_VIDEO_DUAL_UPLOAD
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :MEDIA_ALBUM},
        {2, :BOT_PLUGIN},
        {3, :EVENT_COVER_IMAGE},
        {4, :STATUS_POLL},
        {5, :HD_VIDEO_DUAL_UPLOAD},
        {6, :STATUS_EXTERNAL_RESHARE},
        {7, :MEDIA_POLL},
        {8, :STATUS_ADD_YOURS},
        {9, :STATUS_NOTIFICATION},
        {10, :HD_IMAGE_DUAL_UPLOAD},
        {11, :STICKER_ANNOTATION},
        {12, :MOTION_PHOTO},
        {13, :STATUS_LINK_ACTION},
        {14, :VIEW_ALL_REPLIES},
        {15, :STATUS_ADD_YOURS_AI_IMAGINE},
        {16, :STATUS_QUESTION},
        {17, :STATUS_ADD_YOURS_DIWALI},
        {18, :STATUS_REACTION},
        {19, :HEVC_VIDEO_DUAL_UPLOAD},
        {20, :POLL_ADD_OPTION},
        {21, :AV1_VIDEO_DUAL_UPLOAD},
        {22, :STREAMED_HD_VIDEO_DUAL_UPLOAD}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:MEDIA_ALBUM) do
          true
        end,
        def has_constant?(:BOT_PLUGIN) do
          true
        end,
        def has_constant?(:EVENT_COVER_IMAGE) do
          true
        end,
        def has_constant?(:STATUS_POLL) do
          true
        end,
        def has_constant?(:HD_VIDEO_DUAL_UPLOAD) do
          true
        end,
        def has_constant?(:STATUS_EXTERNAL_RESHARE) do
          true
        end,
        def has_constant?(:MEDIA_POLL) do
          true
        end,
        def has_constant?(:STATUS_ADD_YOURS) do
          true
        end,
        def has_constant?(:STATUS_NOTIFICATION) do
          true
        end,
        def has_constant?(:HD_IMAGE_DUAL_UPLOAD) do
          true
        end,
        def has_constant?(:STICKER_ANNOTATION) do
          true
        end,
        def has_constant?(:MOTION_PHOTO) do
          true
        end,
        def has_constant?(:STATUS_LINK_ACTION) do
          true
        end,
        def has_constant?(:VIEW_ALL_REPLIES) do
          true
        end,
        def has_constant?(:STATUS_ADD_YOURS_AI_IMAGINE) do
          true
        end,
        def has_constant?(:STATUS_QUESTION) do
          true
        end,
        def has_constant?(:STATUS_ADD_YOURS_DIWALI) do
          true
        end,
        def has_constant?(:STATUS_REACTION) do
          true
        end,
        def has_constant?(:HEVC_VIDEO_DUAL_UPLOAD) do
          true
        end,
        def has_constant?(:POLL_ADD_OPTION) do
          true
        end,
        def has_constant?(:AV1_VIDEO_DUAL_UPLOAD) do
          true
        end,
        def has_constant?(:STREAMED_HD_VIDEO_DUAL_UPLOAD) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
