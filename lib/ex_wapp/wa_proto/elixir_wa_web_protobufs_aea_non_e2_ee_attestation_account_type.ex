# credo:disable-for-this-file
defmodule WAWebProtobufsAea.NonE2EEAttestation.AccountType do
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
        def encode(:HYBRID_E2EE) do
          1
        end

        def encode("HYBRID_E2EE") do
          1
        end
      ),
      (
        def encode(:NON_E2EE) do
          2
        end

        def encode("NON_E2EE") do
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
        :E2EE
      end,
      def decode(1) do
        :HYBRID_E2EE
      end,
      def decode(2) do
        :NON_E2EE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :E2EE}, {1, :HYBRID_E2EE}, {2, :NON_E2EE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:E2EE) do
          true
        end,
        def has_constant?(:HYBRID_E2EE) do
          true
        end,
        def has_constant?(:NON_E2EE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
