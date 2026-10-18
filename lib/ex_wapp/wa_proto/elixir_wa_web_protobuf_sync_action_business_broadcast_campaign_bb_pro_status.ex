# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.BusinessBroadcastCampaignBBProStatus do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :BB_PRO_ACTIVE
      def default() do
        :BB_PRO_ACTIVE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:BB_PRO_ACTIVE) do
          1
        end

        def encode("BB_PRO_ACTIVE") do
          1
        end
      ),
      (
        def encode(:BB_PRO_COMPLETED) do
          2
        end

        def encode("BB_PRO_COMPLETED") do
          2
        end
      ),
      (
        def encode(:BB_PRO_IN_DRAFT) do
          3
        end

        def encode("BB_PRO_IN_DRAFT") do
          3
        end
      ),
      (
        def encode(:BB_PRO_IN_REVIEW) do
          4
        end

        def encode("BB_PRO_IN_REVIEW") do
          4
        end
      ),
      (
        def encode(:BB_PRO_NOT_SENDING) do
          5
        end

        def encode("BB_PRO_NOT_SENDING") do
          5
        end
      ),
      (
        def encode(:BB_PRO_OFF) do
          6
        end

        def encode("BB_PRO_OFF") do
          6
        end
      ),
      (
        def encode(:BB_PRO_REJECTED) do
          7
        end

        def encode("BB_PRO_REJECTED") do
          7
        end
      ),
      (
        def encode(:BB_PRO_SCHEDULED) do
          8
        end

        def encode("BB_PRO_SCHEDULED") do
          8
        end
      ),
      (
        def encode(:BB_PRO_SENDING_LIMITED) do
          9
        end

        def encode("BB_PRO_SENDING_LIMITED") do
          9
        end
      ),
      (
        def encode(:BB_PRO_PROCESSING) do
          10
        end

        def encode("BB_PRO_PROCESSING") do
          10
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :BB_PRO_ACTIVE
      end,
      def decode(2) do
        :BB_PRO_COMPLETED
      end,
      def decode(3) do
        :BB_PRO_IN_DRAFT
      end,
      def decode(4) do
        :BB_PRO_IN_REVIEW
      end,
      def decode(5) do
        :BB_PRO_NOT_SENDING
      end,
      def decode(6) do
        :BB_PRO_OFF
      end,
      def decode(7) do
        :BB_PRO_REJECTED
      end,
      def decode(8) do
        :BB_PRO_SCHEDULED
      end,
      def decode(9) do
        :BB_PRO_SENDING_LIMITED
      end,
      def decode(10) do
        :BB_PRO_PROCESSING
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {1, :BB_PRO_ACTIVE},
        {2, :BB_PRO_COMPLETED},
        {3, :BB_PRO_IN_DRAFT},
        {4, :BB_PRO_IN_REVIEW},
        {5, :BB_PRO_NOT_SENDING},
        {6, :BB_PRO_OFF},
        {7, :BB_PRO_REJECTED},
        {8, :BB_PRO_SCHEDULED},
        {9, :BB_PRO_SENDING_LIMITED},
        {10, :BB_PRO_PROCESSING}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:BB_PRO_ACTIVE) do
          true
        end,
        def has_constant?(:BB_PRO_COMPLETED) do
          true
        end,
        def has_constant?(:BB_PRO_IN_DRAFT) do
          true
        end,
        def has_constant?(:BB_PRO_IN_REVIEW) do
          true
        end,
        def has_constant?(:BB_PRO_NOT_SENDING) do
          true
        end,
        def has_constant?(:BB_PRO_OFF) do
          true
        end,
        def has_constant?(:BB_PRO_REJECTED) do
          true
        end,
        def has_constant?(:BB_PRO_SCHEDULED) do
          true
        end,
        def has_constant?(:BB_PRO_SENDING_LIMITED) do
          true
        end,
        def has_constant?(:BB_PRO_PROCESSING) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
