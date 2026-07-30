# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotImagineMetadata.ImagineType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN
      def default() do
        :UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN) do
          0
        end

        def encode("UNKNOWN") do
          0
        end
      ),
      (
        def encode(:IMAGINE) do
          1
        end

        def encode("IMAGINE") do
          1
        end
      ),
      (
        def encode(:MEMU) do
          2
        end

        def encode("MEMU") do
          2
        end
      ),
      (
        def encode(:FLASH) do
          3
        end

        def encode("FLASH") do
          3
        end
      ),
      (
        def encode(:EDIT) do
          4
        end

        def encode("EDIT") do
          4
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :UNKNOWN
      end,
      def decode(1) do
        :IMAGINE
      end,
      def decode(2) do
        :MEMU
      end,
      def decode(3) do
        :FLASH
      end,
      def decode(4) do
        :EDIT
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN}, {1, :IMAGINE}, {2, :MEMU}, {3, :FLASH}, {4, :EDIT}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:IMAGINE) do
          true
        end,
        def has_constant?(:MEMU) do
          true
        end,
        def has_constant?(:FLASH) do
          true
        end,
        def has_constant?(:EDIT) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
