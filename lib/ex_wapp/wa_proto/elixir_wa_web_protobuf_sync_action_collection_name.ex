# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.CollectionName do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :COLLECTION_NAME_UNKNOWN
      def default() do
        :COLLECTION_NAME_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:COLLECTION_NAME_UNKNOWN) do
          0
        end

        def encode("COLLECTION_NAME_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:REGULAR) do
          1
        end

        def encode("REGULAR") do
          1
        end
      ),
      (
        def encode(:REGULAR_LOW) do
          2
        end

        def encode("REGULAR_LOW") do
          2
        end
      ),
      (
        def encode(:REGULAR_HIGH) do
          3
        end

        def encode("REGULAR_HIGH") do
          3
        end
      ),
      (
        def encode(:CRITICAL_BLOCK) do
          4
        end

        def encode("CRITICAL_BLOCK") do
          4
        end
      ),
      (
        def encode(:CRITICAL_UNBLOCK_LOW) do
          5
        end

        def encode("CRITICAL_UNBLOCK_LOW") do
          5
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :COLLECTION_NAME_UNKNOWN
      end,
      def decode(1) do
        :REGULAR
      end,
      def decode(2) do
        :REGULAR_LOW
      end,
      def decode(3) do
        :REGULAR_HIGH
      end,
      def decode(4) do
        :CRITICAL_BLOCK
      end,
      def decode(5) do
        :CRITICAL_UNBLOCK_LOW
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :COLLECTION_NAME_UNKNOWN},
        {1, :REGULAR},
        {2, :REGULAR_LOW},
        {3, :REGULAR_HIGH},
        {4, :CRITICAL_BLOCK},
        {5, :CRITICAL_UNBLOCK_LOW}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:COLLECTION_NAME_UNKNOWN) do
          true
        end,
        def has_constant?(:REGULAR) do
          true
        end,
        def has_constant?(:REGULAR_LOW) do
          true
        end,
        def has_constant?(:REGULAR_HIGH) do
          true
        end,
        def has_constant?(:CRITICAL_BLOCK) do
          true
        end,
        def has_constant?(:CRITICAL_UNBLOCK_LOW) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
