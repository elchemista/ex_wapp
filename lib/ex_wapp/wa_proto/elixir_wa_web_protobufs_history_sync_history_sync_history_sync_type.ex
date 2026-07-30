# credo:disable-for-this-file
defmodule WAWebProtobufsHistorySync.HistorySync.HistorySyncType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :INITIAL_BOOTSTRAP
      def default() do
        :INITIAL_BOOTSTRAP
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:INITIAL_BOOTSTRAP) do
          0
        end

        def encode("INITIAL_BOOTSTRAP") do
          0
        end
      ),
      (
        def encode(:INITIAL_STATUS_V3) do
          1
        end

        def encode("INITIAL_STATUS_V3") do
          1
        end
      ),
      (
        def encode(:FULL) do
          2
        end

        def encode("FULL") do
          2
        end
      ),
      (
        def encode(:RECENT) do
          3
        end

        def encode("RECENT") do
          3
        end
      ),
      (
        def encode(:PUSH_NAME) do
          4
        end

        def encode("PUSH_NAME") do
          4
        end
      ),
      (
        def encode(:NON_BLOCKING_DATA) do
          5
        end

        def encode("NON_BLOCKING_DATA") do
          5
        end
      ),
      (
        def encode(:ON_DEMAND) do
          6
        end

        def encode("ON_DEMAND") do
          6
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :INITIAL_BOOTSTRAP
      end,
      def decode(1) do
        :INITIAL_STATUS_V3
      end,
      def decode(2) do
        :FULL
      end,
      def decode(3) do
        :RECENT
      end,
      def decode(4) do
        :PUSH_NAME
      end,
      def decode(5) do
        :NON_BLOCKING_DATA
      end,
      def decode(6) do
        :ON_DEMAND
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :INITIAL_BOOTSTRAP},
        {1, :INITIAL_STATUS_V3},
        {2, :FULL},
        {3, :RECENT},
        {4, :PUSH_NAME},
        {5, :NON_BLOCKING_DATA},
        {6, :ON_DEMAND}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:INITIAL_BOOTSTRAP) do
          true
        end,
        def has_constant?(:INITIAL_STATUS_V3) do
          true
        end,
        def has_constant?(:FULL) do
          true
        end,
        def has_constant?(:RECENT) do
          true
        end,
        def has_constant?(:PUSH_NAME) do
          true
        end,
        def has_constant?(:NON_BLOCKING_DATA) do
          true
        end,
        def has_constant?(:ON_DEMAND) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
