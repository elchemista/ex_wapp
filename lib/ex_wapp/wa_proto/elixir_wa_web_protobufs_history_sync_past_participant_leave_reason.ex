# credo:disable-for-this-file
defmodule WAWebProtobufsHistorySync.PastParticipant.LeaveReason do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :LEFT
      def default() do
        :LEFT
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:LEFT) do
          0
        end

        def encode("LEFT") do
          0
        end
      ),
      (
        def encode(:REMOVED) do
          1
        end

        def encode("REMOVED") do
          1
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :LEFT
      end,
      def decode(1) do
        :REMOVED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :LEFT}, {1, :REMOVED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:LEFT) do
          true
        end,
        def has_constant?(:REMOVED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
