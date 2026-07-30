# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.KeepType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN_KEEP_TYPE
      def default() do
        :UNKNOWN_KEEP_TYPE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN_KEEP_TYPE) do
          0
        end

        def encode("UNKNOWN_KEEP_TYPE") do
          0
        end
      ),
      (
        def encode(:KEEP_FOR_ALL) do
          1
        end

        def encode("KEEP_FOR_ALL") do
          1
        end
      ),
      (
        def encode(:UNDO_KEEP_FOR_ALL) do
          2
        end

        def encode("UNDO_KEEP_FOR_ALL") do
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
        :UNKNOWN_KEEP_TYPE
      end,
      def decode(1) do
        :KEEP_FOR_ALL
      end,
      def decode(2) do
        :UNDO_KEEP_FOR_ALL
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN_KEEP_TYPE}, {1, :KEEP_FOR_ALL}, {2, :UNDO_KEEP_FOR_ALL}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN_KEEP_TYPE) do
          true
        end,
        def has_constant?(:KEEP_FOR_ALL) do
          true
        end,
        def has_constant?(:UNDO_KEEP_FOR_ALL) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
