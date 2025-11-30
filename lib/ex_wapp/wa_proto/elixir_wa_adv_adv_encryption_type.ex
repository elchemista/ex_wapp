# credo:disable-for-this-file
defmodule WAAdv.ADVEncryptionType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :E2EE
      def default() do
        :E2EE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:E2EE) do
          0
        end

        def encode("E2EE") do
          0
        end
      ),
      (
        def encode(:HOSTED) do
          1
        end

        def encode("HOSTED") do
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
        :E2EE
      end,
      def decode(1) do
        :HOSTED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :E2EE}, {1, :HOSTED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:E2EE) do
          true
        end,
        def has_constant?(:HOSTED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
