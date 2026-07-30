# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.InteractiveResponseMessage.Body.Format do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :DEFAULT
      def default() do
        :DEFAULT
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:DEFAULT) do
          0
        end

        def encode("DEFAULT") do
          0
        end
      ),
      (
        def encode(:EXTENSIONS_1) do
          1
        end

        def encode("EXTENSIONS_1") do
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
        :DEFAULT
      end,
      def decode(1) do
        :EXTENSIONS_1
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :DEFAULT}, {1, :EXTENSIONS_1}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:DEFAULT) do
          true
        end,
        def has_constant?(:EXTENSIONS_1) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
