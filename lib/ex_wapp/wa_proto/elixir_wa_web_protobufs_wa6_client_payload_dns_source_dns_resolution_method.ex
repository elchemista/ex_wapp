# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.DNSSource.DNSResolutionMethod do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :SYSTEM
      def default() do
        :SYSTEM
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:SYSTEM) do
          0
        end

        def encode("SYSTEM") do
          0
        end
      ),
      (
        def encode(:GOOGLE) do
          1
        end

        def encode("GOOGLE") do
          1
        end
      ),
      (
        def encode(:HARDCODED) do
          2
        end

        def encode("HARDCODED") do
          2
        end
      ),
      (
        def encode(:OVERRIDE) do
          3
        end

        def encode("OVERRIDE") do
          3
        end
      ),
      (
        def encode(:FALLBACK) do
          4
        end

        def encode("FALLBACK") do
          4
        end
      ),
      (
        def encode(:MNS) do
          5
        end

        def encode("MNS") do
          5
        end
      ),
      (
        def encode(:MNS_SECONDARY) do
          6
        end

        def encode("MNS_SECONDARY") do
          6
        end
      ),
      (
        def encode(:SOCKS_PROXY) do
          7
        end

        def encode("SOCKS_PROXY") do
          7
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :SYSTEM
      end,
      def decode(1) do
        :GOOGLE
      end,
      def decode(2) do
        :HARDCODED
      end,
      def decode(3) do
        :OVERRIDE
      end,
      def decode(4) do
        :FALLBACK
      end,
      def decode(5) do
        :MNS
      end,
      def decode(6) do
        :MNS_SECONDARY
      end,
      def decode(7) do
        :SOCKS_PROXY
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :SYSTEM},
        {1, :GOOGLE},
        {2, :HARDCODED},
        {3, :OVERRIDE},
        {4, :FALLBACK},
        {5, :MNS},
        {6, :MNS_SECONDARY},
        {7, :SOCKS_PROXY}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:SYSTEM) do
          true
        end,
        def has_constant?(:GOOGLE) do
          true
        end,
        def has_constant?(:HARDCODED) do
          true
        end,
        def has_constant?(:OVERRIDE) do
          true
        end,
        def has_constant?(:FALLBACK) do
          true
        end,
        def has_constant?(:MNS) do
          true
        end,
        def has_constant?(:MNS_SECONDARY) do
          true
        end,
        def has_constant?(:SOCKS_PROXY) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
