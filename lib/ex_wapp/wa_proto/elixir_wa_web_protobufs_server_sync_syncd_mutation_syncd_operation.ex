# credo:disable-for-this-file
defmodule WAWebProtobufsServerSync.SyncdMutation.SyncdOperation do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :SET
      def default() do
        :SET
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:SET) do
          0
        end

        def encode("SET") do
          0
        end
      ),
      (
        def encode(:REMOVE) do
          1
        end

        def encode("REMOVE") do
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
        :SET
      end,
      def decode(1) do
        :REMOVE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :SET}, {1, :REMOVE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:SET) do
          true
        end,
        def has_constant?(:REMOVE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
