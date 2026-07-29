# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.CallLogMessage.CallOutcome do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :CONNECTED
      def default() do
        :CONNECTED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:CONNECTED) do
          0
        end

        def encode("CONNECTED") do
          0
        end
      ),
      (
        def encode(:MISSED) do
          1
        end

        def encode("MISSED") do
          1
        end
      ),
      (
        def encode(:FAILED) do
          2
        end

        def encode("FAILED") do
          2
        end
      ),
      (
        def encode(:REJECTED) do
          3
        end

        def encode("REJECTED") do
          3
        end
      ),
      (
        def encode(:ACCEPTED_ELSEWHERE) do
          4
        end

        def encode("ACCEPTED_ELSEWHERE") do
          4
        end
      ),
      (
        def encode(:ONGOING) do
          5
        end

        def encode("ONGOING") do
          5
        end
      ),
      (
        def encode(:SILENCED_BY_DND) do
          6
        end

        def encode("SILENCED_BY_DND") do
          6
        end
      ),
      (
        def encode(:SILENCED_UNKNOWN_CALLER) do
          7
        end

        def encode("SILENCED_UNKNOWN_CALLER") do
          7
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :CONNECTED
      end,
      def decode(1) do
        :MISSED
      end,
      def decode(2) do
        :FAILED
      end,
      def decode(3) do
        :REJECTED
      end,
      def decode(4) do
        :ACCEPTED_ELSEWHERE
      end,
      def decode(5) do
        :ONGOING
      end,
      def decode(6) do
        :SILENCED_BY_DND
      end,
      def decode(7) do
        :SILENCED_UNKNOWN_CALLER
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :CONNECTED},
        {1, :MISSED},
        {2, :FAILED},
        {3, :REJECTED},
        {4, :ACCEPTED_ELSEWHERE},
        {5, :ONGOING},
        {6, :SILENCED_BY_DND},
        {7, :SILENCED_UNKNOWN_CALLER}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:CONNECTED) do
          true
        end,
        def has_constant?(:MISSED) do
          true
        end,
        def has_constant?(:FAILED) do
          true
        end,
        def has_constant?(:REJECTED) do
          true
        end,
        def has_constant?(:ACCEPTED_ELSEWHERE) do
          true
        end,
        def has_constant?(:ONGOING) do
          true
        end,
        def has_constant?(:SILENCED_BY_DND) do
          true
        end,
        def has_constant?(:SILENCED_UNKNOWN_CALLER) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
