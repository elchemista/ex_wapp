# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.HandshakeMessage.HandshakePqMode do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :HANDSHAKE_PQ_MODE_UNKNOWN
      def default() do
        :HANDSHAKE_PQ_MODE_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:HANDSHAKE_PQ_MODE_UNKNOWN) do
          0
        end

        def encode("HANDSHAKE_PQ_MODE_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:XXKEM) do
          1
        end

        def encode("XXKEM") do
          1
        end
      ),
      (
        def encode(:XXKEM_FS) do
          2
        end

        def encode("XXKEM_FS") do
          2
        end
      ),
      (
        def encode(:WA_CLASSICAL) do
          3
        end

        def encode("WA_CLASSICAL") do
          3
        end
      ),
      (
        def encode(:WA_PQ) do
          4
        end

        def encode("WA_PQ") do
          4
        end
      ),
      (
        def encode(:IKKEM) do
          5
        end

        def encode("IKKEM") do
          5
        end
      ),
      (
        def encode(:IKKEM_FS) do
          6
        end

        def encode("IKKEM_FS") do
          6
        end
      ),
      (
        def encode(:XXKEM_2) do
          7
        end

        def encode("XXKEM_2") do
          7
        end
      ),
      (
        def encode(:IKKEM_2) do
          8
        end

        def encode("IKKEM_2") do
          8
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :HANDSHAKE_PQ_MODE_UNKNOWN
      end,
      def decode(1) do
        :XXKEM
      end,
      def decode(2) do
        :XXKEM_FS
      end,
      def decode(3) do
        :WA_CLASSICAL
      end,
      def decode(4) do
        :WA_PQ
      end,
      def decode(5) do
        :IKKEM
      end,
      def decode(6) do
        :IKKEM_FS
      end,
      def decode(7) do
        :XXKEM_2
      end,
      def decode(8) do
        :IKKEM_2
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :HANDSHAKE_PQ_MODE_UNKNOWN},
        {1, :XXKEM},
        {2, :XXKEM_FS},
        {3, :WA_CLASSICAL},
        {4, :WA_PQ},
        {5, :IKKEM},
        {6, :IKKEM_FS},
        {7, :XXKEM_2},
        {8, :IKKEM_2}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:HANDSHAKE_PQ_MODE_UNKNOWN) do
          true
        end,
        def has_constant?(:XXKEM) do
          true
        end,
        def has_constant?(:XXKEM_FS) do
          true
        end,
        def has_constant?(:WA_CLASSICAL) do
          true
        end,
        def has_constant?(:WA_PQ) do
          true
        end,
        def has_constant?(:IKKEM) do
          true
        end,
        def has_constant?(:IKKEM_FS) do
          true
        end,
        def has_constant?(:XXKEM_2) do
          true
        end,
        def has_constant?(:IKKEM_2) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
