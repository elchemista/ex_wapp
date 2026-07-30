# credo:disable-for-this-file
defmodule WAWebProtobufsHistorySync.Conversation.EndOfHistoryTransferType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :COMPLETE_BUT_MORE_MESSAGES_REMAIN_ON_PRIMARY
      def default() do
        :COMPLETE_BUT_MORE_MESSAGES_REMAIN_ON_PRIMARY
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:COMPLETE_BUT_MORE_MESSAGES_REMAIN_ON_PRIMARY) do
          0
        end

        def encode("COMPLETE_BUT_MORE_MESSAGES_REMAIN_ON_PRIMARY") do
          0
        end
      ),
      (
        def encode(:COMPLETE_AND_NO_MORE_MESSAGE_REMAIN_ON_PRIMARY) do
          1
        end

        def encode("COMPLETE_AND_NO_MORE_MESSAGE_REMAIN_ON_PRIMARY") do
          1
        end
      ),
      (
        def encode(:COMPLETE_ON_DEMAND_SYNC_BUT_MORE_MSG_REMAIN_ON_PRIMARY) do
          2
        end

        def encode("COMPLETE_ON_DEMAND_SYNC_BUT_MORE_MSG_REMAIN_ON_PRIMARY") do
          2
        end
      ),
      (
        def encode(:COMPLETE_ON_DEMAND_SYNC_WITH_MORE_MSG_ON_PRIMARY_BUT_NO_ACCESS) do
          3
        end

        def encode("COMPLETE_ON_DEMAND_SYNC_WITH_MORE_MSG_ON_PRIMARY_BUT_NO_ACCESS") do
          3
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :COMPLETE_BUT_MORE_MESSAGES_REMAIN_ON_PRIMARY
      end,
      def decode(1) do
        :COMPLETE_AND_NO_MORE_MESSAGE_REMAIN_ON_PRIMARY
      end,
      def decode(2) do
        :COMPLETE_ON_DEMAND_SYNC_BUT_MORE_MSG_REMAIN_ON_PRIMARY
      end,
      def decode(3) do
        :COMPLETE_ON_DEMAND_SYNC_WITH_MORE_MSG_ON_PRIMARY_BUT_NO_ACCESS
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :COMPLETE_BUT_MORE_MESSAGES_REMAIN_ON_PRIMARY},
        {1, :COMPLETE_AND_NO_MORE_MESSAGE_REMAIN_ON_PRIMARY},
        {2, :COMPLETE_ON_DEMAND_SYNC_BUT_MORE_MSG_REMAIN_ON_PRIMARY},
        {3, :COMPLETE_ON_DEMAND_SYNC_WITH_MORE_MSG_ON_PRIMARY_BUT_NO_ACCESS}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:COMPLETE_BUT_MORE_MESSAGES_REMAIN_ON_PRIMARY) do
          true
        end,
        def has_constant?(:COMPLETE_AND_NO_MORE_MESSAGE_REMAIN_ON_PRIMARY) do
          true
        end,
        def has_constant?(:COMPLETE_ON_DEMAND_SYNC_BUT_MORE_MSG_REMAIN_ON_PRIMARY) do
          true
        end,
        def has_constant?(:COMPLETE_ON_DEMAND_SYNC_WITH_MORE_MSG_ON_PRIMARY_BUT_NO_ACCESS) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
