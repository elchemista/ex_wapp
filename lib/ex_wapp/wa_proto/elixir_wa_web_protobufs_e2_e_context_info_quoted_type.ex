# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ContextInfo.QuotedType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :EXPLICIT
      def default() do
        :EXPLICIT
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:EXPLICIT) do
          0
        end

        def encode("EXPLICIT") do
          0
        end
      ),
      (
        def encode(:AUTO) do
          1
        end

        def encode("AUTO") do
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
        :EXPLICIT
      end,
      def decode(1) do
        :AUTO
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :EXPLICIT}, {1, :AUTO}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:EXPLICIT) do
          true
        end,
        def has_constant?(:AUTO) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
