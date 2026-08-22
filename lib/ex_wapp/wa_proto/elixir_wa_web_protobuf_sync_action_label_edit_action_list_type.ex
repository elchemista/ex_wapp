# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.LabelEditAction.ListType do
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
        def encode(:UNREAD) do
          1
        end

        def encode("UNREAD") do
          1
        end
      ),
      (
        def encode(:GROUPS) do
          2
        end

        def encode("GROUPS") do
          2
        end
      ),
      (
        def encode(:FAVORITES) do
          3
        end

        def encode("FAVORITES") do
          3
        end
      ),
      (
        def encode(:PREDEFINED) do
          4
        end

        def encode("PREDEFINED") do
          4
        end
      ),
      (
        def encode(:CUSTOM) do
          5
        end

        def encode("CUSTOM") do
          5
        end
      ),
      (
        def encode(:COMMUNITY) do
          6
        end

        def encode("COMMUNITY") do
          6
        end
      ),
      (
        def encode(:SERVER_ASSIGNED) do
          7
        end

        def encode("SERVER_ASSIGNED") do
          7
        end
      ),
      (
        def encode(:DRAFTED) do
          8
        end

        def encode("DRAFTED") do
          8
        end
      ),
      (
        def encode(:AI_HANDOFF) do
          9
        end

        def encode("AI_HANDOFF") do
          9
        end
      ),
      (
        def encode(:CHANNELS) do
          10
        end

        def encode("CHANNELS") do
          10
        end
      ),
      (
        def encode(:AI_RESPONDING) do
          11
        end

        def encode("AI_RESPONDING") do
          11
        end
      ),
      (
        def encode(:ARCHIVED) do
          12
        end

        def encode("ARCHIVED") do
          12
        end
      ),
      (
        def encode(:LOCKED) do
          13
        end

        def encode("LOCKED") do
          13
        end
      ),
      (
        def encode(:INVITES) do
          14
        end

        def encode("INVITES") do
          14
        end
      ),
      (
        def encode(:THIRD_PARTY) do
          15
        end

        def encode("THIRD_PARTY") do
          15
        end
      ),
      (
        def encode(:LEAD) do
          16
        end

        def encode("LEAD") do
          16
        end
      ),
      (
        def encode(:MENTIONS_AND_REPLIES) do
          17
        end

        def encode("MENTIONS_AND_REPLIES") do
          17
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
        :UNREAD
      end,
      def decode(2) do
        :GROUPS
      end,
      def decode(3) do
        :FAVORITES
      end,
      def decode(4) do
        :PREDEFINED
      end,
      def decode(5) do
        :CUSTOM
      end,
      def decode(6) do
        :COMMUNITY
      end,
      def decode(7) do
        :SERVER_ASSIGNED
      end,
      def decode(8) do
        :DRAFTED
      end,
      def decode(9) do
        :AI_HANDOFF
      end,
      def decode(10) do
        :CHANNELS
      end,
      def decode(11) do
        :AI_RESPONDING
      end,
      def decode(12) do
        :ARCHIVED
      end,
      def decode(13) do
        :LOCKED
      end,
      def decode(14) do
        :INVITES
      end,
      def decode(15) do
        :THIRD_PARTY
      end,
      def decode(16) do
        :LEAD
      end,
      def decode(17) do
        :MENTIONS_AND_REPLIES
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :NONE},
        {1, :UNREAD},
        {2, :GROUPS},
        {3, :FAVORITES},
        {4, :PREDEFINED},
        {5, :CUSTOM},
        {6, :COMMUNITY},
        {7, :SERVER_ASSIGNED},
        {8, :DRAFTED},
        {9, :AI_HANDOFF},
        {10, :CHANNELS},
        {11, :AI_RESPONDING},
        {12, :ARCHIVED},
        {13, :LOCKED},
        {14, :INVITES},
        {15, :THIRD_PARTY},
        {16, :LEAD},
        {17, :MENTIONS_AND_REPLIES}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NONE) do
          true
        end,
        def has_constant?(:UNREAD) do
          true
        end,
        def has_constant?(:GROUPS) do
          true
        end,
        def has_constant?(:FAVORITES) do
          true
        end,
        def has_constant?(:PREDEFINED) do
          true
        end,
        def has_constant?(:CUSTOM) do
          true
        end,
        def has_constant?(:COMMUNITY) do
          true
        end,
        def has_constant?(:SERVER_ASSIGNED) do
          true
        end,
        def has_constant?(:DRAFTED) do
          true
        end,
        def has_constant?(:AI_HANDOFF) do
          true
        end,
        def has_constant?(:CHANNELS) do
          true
        end,
        def has_constant?(:AI_RESPONDING) do
          true
        end,
        def has_constant?(:ARCHIVED) do
          true
        end,
        def has_constant?(:LOCKED) do
          true
        end,
        def has_constant?(:INVITES) do
          true
        end,
        def has_constant?(:THIRD_PARTY) do
          true
        end,
        def has_constant?(:LEAD) do
          true
        end,
        def has_constant?(:MENTIONS_AND_REPLIES) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
