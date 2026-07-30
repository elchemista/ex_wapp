# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PeerDataOperationRequestType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UPLOAD_STICKER
      def default() do
        :UPLOAD_STICKER
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UPLOAD_STICKER) do
          0
        end

        def encode("UPLOAD_STICKER") do
          0
        end
      ),
      (
        def encode(:SEND_RECENT_STICKER_BOOTSTRAP) do
          1
        end

        def encode("SEND_RECENT_STICKER_BOOTSTRAP") do
          1
        end
      ),
      (
        def encode(:GENERATE_LINK_PREVIEW) do
          2
        end

        def encode("GENERATE_LINK_PREVIEW") do
          2
        end
      ),
      (
        def encode(:HISTORY_SYNC_ON_DEMAND) do
          3
        end

        def encode("HISTORY_SYNC_ON_DEMAND") do
          3
        end
      ),
      (
        def encode(:PLACEHOLDER_MESSAGE_RESEND) do
          4
        end

        def encode("PLACEHOLDER_MESSAGE_RESEND") do
          4
        end
      ),
      (
        def encode(:WAFFLE_LINKING_NONCE_FETCH) do
          5
        end

        def encode("WAFFLE_LINKING_NONCE_FETCH") do
          5
        end
      ),
      (
        def encode(:FULL_HISTORY_SYNC_ON_DEMAND) do
          6
        end

        def encode("FULL_HISTORY_SYNC_ON_DEMAND") do
          6
        end
      ),
      (
        def encode(:COMPANION_META_NONCE_FETCH) do
          7
        end

        def encode("COMPANION_META_NONCE_FETCH") do
          7
        end
      ),
      (
        def encode(:COMPANION_SYNCD_SNAPSHOT_FATAL_RECOVERY) do
          8
        end

        def encode("COMPANION_SYNCD_SNAPSHOT_FATAL_RECOVERY") do
          8
        end
      ),
      (
        def encode(:COMPANION_CANONICAL_USER_NONCE_FETCH) do
          9
        end

        def encode("COMPANION_CANONICAL_USER_NONCE_FETCH") do
          9
        end
      ),
      (
        def encode(:HISTORY_SYNC_CHUNK_RETRY) do
          10
        end

        def encode("HISTORY_SYNC_CHUNK_RETRY") do
          10
        end
      ),
      (
        def encode(:GALAXY_FLOW_ACTION) do
          11
        end

        def encode("GALAXY_FLOW_ACTION") do
          11
        end
      ),
      (
        def encode(:BUSINESS_BROADCAST_INSIGHTS_DELIVERED_TO) do
          12
        end

        def encode("BUSINESS_BROADCAST_INSIGHTS_DELIVERED_TO") do
          12
        end
      ),
      (
        def encode(:BUSINESS_BROADCAST_INSIGHTS_REFRESH) do
          13
        end

        def encode("BUSINESS_BROADCAST_INSIGHTS_REFRESH") do
          13
        end
      ),
      (
        def encode(:CONTACT_REFRESH_REQUEST) do
          14
        end

        def encode("CONTACT_REFRESH_REQUEST") do
          14
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :UPLOAD_STICKER
      end,
      def decode(1) do
        :SEND_RECENT_STICKER_BOOTSTRAP
      end,
      def decode(2) do
        :GENERATE_LINK_PREVIEW
      end,
      def decode(3) do
        :HISTORY_SYNC_ON_DEMAND
      end,
      def decode(4) do
        :PLACEHOLDER_MESSAGE_RESEND
      end,
      def decode(5) do
        :WAFFLE_LINKING_NONCE_FETCH
      end,
      def decode(6) do
        :FULL_HISTORY_SYNC_ON_DEMAND
      end,
      def decode(7) do
        :COMPANION_META_NONCE_FETCH
      end,
      def decode(8) do
        :COMPANION_SYNCD_SNAPSHOT_FATAL_RECOVERY
      end,
      def decode(9) do
        :COMPANION_CANONICAL_USER_NONCE_FETCH
      end,
      def decode(10) do
        :HISTORY_SYNC_CHUNK_RETRY
      end,
      def decode(11) do
        :GALAXY_FLOW_ACTION
      end,
      def decode(12) do
        :BUSINESS_BROADCAST_INSIGHTS_DELIVERED_TO
      end,
      def decode(13) do
        :BUSINESS_BROADCAST_INSIGHTS_REFRESH
      end,
      def decode(14) do
        :CONTACT_REFRESH_REQUEST
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UPLOAD_STICKER},
        {1, :SEND_RECENT_STICKER_BOOTSTRAP},
        {2, :GENERATE_LINK_PREVIEW},
        {3, :HISTORY_SYNC_ON_DEMAND},
        {4, :PLACEHOLDER_MESSAGE_RESEND},
        {5, :WAFFLE_LINKING_NONCE_FETCH},
        {6, :FULL_HISTORY_SYNC_ON_DEMAND},
        {7, :COMPANION_META_NONCE_FETCH},
        {8, :COMPANION_SYNCD_SNAPSHOT_FATAL_RECOVERY},
        {9, :COMPANION_CANONICAL_USER_NONCE_FETCH},
        {10, :HISTORY_SYNC_CHUNK_RETRY},
        {11, :GALAXY_FLOW_ACTION},
        {12, :BUSINESS_BROADCAST_INSIGHTS_DELIVERED_TO},
        {13, :BUSINESS_BROADCAST_INSIGHTS_REFRESH},
        {14, :CONTACT_REFRESH_REQUEST}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UPLOAD_STICKER) do
          true
        end,
        def has_constant?(:SEND_RECENT_STICKER_BOOTSTRAP) do
          true
        end,
        def has_constant?(:GENERATE_LINK_PREVIEW) do
          true
        end,
        def has_constant?(:HISTORY_SYNC_ON_DEMAND) do
          true
        end,
        def has_constant?(:PLACEHOLDER_MESSAGE_RESEND) do
          true
        end,
        def has_constant?(:WAFFLE_LINKING_NONCE_FETCH) do
          true
        end,
        def has_constant?(:FULL_HISTORY_SYNC_ON_DEMAND) do
          true
        end,
        def has_constant?(:COMPANION_META_NONCE_FETCH) do
          true
        end,
        def has_constant?(:COMPANION_SYNCD_SNAPSHOT_FATAL_RECOVERY) do
          true
        end,
        def has_constant?(:COMPANION_CANONICAL_USER_NONCE_FETCH) do
          true
        end,
        def has_constant?(:HISTORY_SYNC_CHUNK_RETRY) do
          true
        end,
        def has_constant?(:GALAXY_FLOW_ACTION) do
          true
        end,
        def has_constant?(:BUSINESS_BROADCAST_INSIGHTS_DELIVERED_TO) do
          true
        end,
        def has_constant?(:BUSINESS_BROADCAST_INSIGHTS_REFRESH) do
          true
        end,
        def has_constant?(:CONTACT_REFRESH_REQUEST) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
