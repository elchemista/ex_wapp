# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotInfrastructureDiagnostics.BotBackend do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :AAPI
      def default() do
        :AAPI
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:AAPI) do
          0
        end

        def encode("AAPI") do
          0
        end
      ),
      (
        def encode(:CLIPPY) do
          1
        end

        def encode("CLIPPY") do
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
        :AAPI
      end,
      def decode(1) do
        :CLIPPY
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :AAPI}, {1, :CLIPPY}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:AAPI) do
          true
        end,
        def has_constant?(:CLIPPY) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
