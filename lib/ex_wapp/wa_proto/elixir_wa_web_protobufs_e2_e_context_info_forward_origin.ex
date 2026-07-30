# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ContextInfo.ForwardOrigin do
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
        def encode(:CHAT) do
          1
        end

        def encode("CHAT") do
          1
        end
      ),
      (
        def encode(:STATUS) do
          2
        end

        def encode("STATUS") do
          2
        end
      ),
      (
        def encode(:CHANNELS) do
          3
        end

        def encode("CHANNELS") do
          3
        end
      ),
      (
        def encode(:META_AI) do
          4
        end

        def encode("META_AI") do
          4
        end
      ),
      (
        def encode(:UGC) do
          5
        end

        def encode("UGC") do
          5
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
        :CHAT
      end,
      def decode(2) do
        :STATUS
      end,
      def decode(3) do
        :CHANNELS
      end,
      def decode(4) do
        :META_AI
      end,
      def decode(5) do
        :UGC
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN}, {1, :CHAT}, {2, :STATUS}, {3, :CHANNELS}, {4, :META_AI}, {5, :UGC}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:CHAT) do
          true
        end,
        def has_constant?(:STATUS) do
          true
        end,
        def has_constant?(:CHANNELS) do
          true
        end,
        def has_constant?(:META_AI) do
          true
        end,
        def has_constant?(:UGC) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
