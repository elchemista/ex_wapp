# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.CallLogRecord.CallResult do
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
        def encode(:REJECTED) do
          1
        end

        def encode("REJECTED") do
          1
        end
      ),
      (
        def encode(:CANCELLED) do
          2
        end

        def encode("CANCELLED") do
          2
        end
      ),
      (
        def encode(:ACCEPTEDELSEWHERE) do
          3
        end

        def encode("ACCEPTEDELSEWHERE") do
          3
        end
      ),
      (
        def encode(:MISSED) do
          4
        end

        def encode("MISSED") do
          4
        end
      ),
      (
        def encode(:INVALID) do
          5
        end

        def encode("INVALID") do
          5
        end
      ),
      (
        def encode(:UNAVAILABLE) do
          6
        end

        def encode("UNAVAILABLE") do
          6
        end
      ),
      (
        def encode(:UPCOMING) do
          7
        end

        def encode("UPCOMING") do
          7
        end
      ),
      (
        def encode(:FAILED) do
          8
        end

        def encode("FAILED") do
          8
        end
      ),
      (
        def encode(:ABANDONED) do
          9
        end

        def encode("ABANDONED") do
          9
        end
      ),
      (
        def encode(:ONGOING) do
          10
        end

        def encode("ONGOING") do
          10
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
        :REJECTED
      end,
      def decode(2) do
        :CANCELLED
      end,
      def decode(3) do
        :ACCEPTEDELSEWHERE
      end,
      def decode(4) do
        :MISSED
      end,
      def decode(5) do
        :INVALID
      end,
      def decode(6) do
        :UNAVAILABLE
      end,
      def decode(7) do
        :UPCOMING
      end,
      def decode(8) do
        :FAILED
      end,
      def decode(9) do
        :ABANDONED
      end,
      def decode(10) do
        :ONGOING
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :CONNECTED},
        {1, :REJECTED},
        {2, :CANCELLED},
        {3, :ACCEPTEDELSEWHERE},
        {4, :MISSED},
        {5, :INVALID},
        {6, :UNAVAILABLE},
        {7, :UPCOMING},
        {8, :FAILED},
        {9, :ABANDONED},
        {10, :ONGOING}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:CONNECTED) do
          true
        end,
        def has_constant?(:REJECTED) do
          true
        end,
        def has_constant?(:CANCELLED) do
          true
        end,
        def has_constant?(:ACCEPTEDELSEWHERE) do
          true
        end,
        def has_constant?(:MISSED) do
          true
        end,
        def has_constant?(:INVALID) do
          true
        end,
        def has_constant?(:UNAVAILABLE) do
          true
        end,
        def has_constant?(:UPCOMING) do
          true
        end,
        def has_constant?(:FAILED) do
          true
        end,
        def has_constant?(:ABANDONED) do
          true
        end,
        def has_constant?(:ONGOING) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
