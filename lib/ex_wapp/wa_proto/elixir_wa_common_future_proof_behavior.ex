# credo:disable-for-this-file
defmodule WACommon.FutureProofBehavior do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :PLACEHOLDER
      def default() do
        :PLACEHOLDER
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:PLACEHOLDER) do
          0
        end

        def encode("PLACEHOLDER") do
          0
        end
      ),
      (
        def encode(:NO_PLACEHOLDER) do
          1
        end

        def encode("NO_PLACEHOLDER") do
          1
        end
      ),
      (
        def encode(:IGNORE) do
          2
        end

        def encode("IGNORE") do
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
        :PLACEHOLDER
      end,
      def decode(1) do
        :NO_PLACEHOLDER
      end,
      def decode(2) do
        :IGNORE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :PLACEHOLDER}, {1, :NO_PLACEHOLDER}, {2, :IGNORE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:PLACEHOLDER) do
          true
        end,
        def has_constant?(:NO_PLACEHOLDER) do
          true
        end,
        def has_constant?(:IGNORE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
