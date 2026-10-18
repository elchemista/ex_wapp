# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.CommunityNestingStateAction.NestingState do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :NESTING_STATE_UNKNOWN
      def default() do
        :NESTING_STATE_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:NESTING_STATE_UNKNOWN) do
          0
        end

        def encode("NESTING_STATE_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:NESTING_STATE_NESTED) do
          1
        end

        def encode("NESTING_STATE_NESTED") do
          1
        end
      ),
      (
        def encode(:NESTING_STATE_UNNESTED) do
          2
        end

        def encode("NESTING_STATE_UNNESTED") do
          2
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :NESTING_STATE_UNKNOWN
      end,
      def decode(1) do
        :NESTING_STATE_NESTED
      end,
      def decode(2) do
        :NESTING_STATE_UNNESTED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :NESTING_STATE_UNKNOWN}, {1, :NESTING_STATE_NESTED}, {2, :NESTING_STATE_UNNESTED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NESTING_STATE_UNKNOWN) do
          true
        end,
        def has_constant?(:NESTING_STATE_NESTED) do
          true
        end,
        def has_constant?(:NESTING_STATE_UNNESTED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
