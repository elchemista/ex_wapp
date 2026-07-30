# credo:disable-for-this-file
defmodule WAWebProtobufsUserPassword.UserPassword.Encoding do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UTF8
      def default() do
        :UTF8
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UTF8) do
          0
        end

        def encode("UTF8") do
          0
        end
      ),
      (
        def encode(:UTF8_BROKEN) do
          1
        end

        def encode("UTF8_BROKEN") do
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
        :UTF8
      end,
      def decode(1) do
        :UTF8_BROKEN
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UTF8}, {1, :UTF8_BROKEN}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UTF8) do
          true
        end,
        def has_constant?(:UTF8_BROKEN) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
