# credo:disable-for-this-file
defmodule WAWebProtobufsHistorySync.Conversation.GroupAppealStatus do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :NO_APPEAL
      def default() do
        :NO_APPEAL
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:NO_APPEAL) do
          0
        end

        def encode("NO_APPEAL") do
          0
        end
      ),
      (
        def encode(:APPEAL_IN_REVIEW) do
          1
        end

        def encode("APPEAL_IN_REVIEW") do
          1
        end
      ),
      (
        def encode(:APPEAL_APPROVED) do
          2
        end

        def encode("APPEAL_APPROVED") do
          2
        end
      ),
      (
        def encode(:APPEAL_REJECTED) do
          3
        end

        def encode("APPEAL_REJECTED") do
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
        :NO_APPEAL
      end,
      def decode(1) do
        :APPEAL_IN_REVIEW
      end,
      def decode(2) do
        :APPEAL_APPROVED
      end,
      def decode(3) do
        :APPEAL_REJECTED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :NO_APPEAL}, {1, :APPEAL_IN_REVIEW}, {2, :APPEAL_APPROVED}, {3, :APPEAL_REJECTED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NO_APPEAL) do
          true
        end,
        def has_constant?(:APPEAL_IN_REVIEW) do
          true
        end,
        def has_constant?(:APPEAL_APPROVED) do
          true
        end,
        def has_constant?(:APPEAL_REJECTED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
