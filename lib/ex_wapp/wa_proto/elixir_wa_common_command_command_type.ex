# credo:disable-for-this-file
defmodule WACommon.Command.CommandType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :EVERYONE
      def default() do
        :EVERYONE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:EVERYONE) do
          1
        end

        def encode("EVERYONE") do
          1
        end
      ),
      (
        def encode(:SILENT) do
          2
        end

        def encode("SILENT") do
          2
        end
      ),
      (
        def encode(:AI) do
          3
        end

        def encode("AI") do
          3
        end
      ),
      (
        def encode(:AI_IMAGINE) do
          4
        end

        def encode("AI_IMAGINE") do
          4
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :EVERYONE
      end,
      def decode(2) do
        :SILENT
      end,
      def decode(3) do
        :AI
      end,
      def decode(4) do
        :AI_IMAGINE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :EVERYONE}, {2, :SILENT}, {3, :AI}, {4, :AI_IMAGINE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:EVERYONE) do
          true
        end,
        def has_constant?(:SILENT) do
          true
        end,
        def has_constant?(:AI) do
          true
        end,
        def has_constant?(:AI_IMAGINE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
