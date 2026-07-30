# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.InteractiveMessage.ShopMessage.Surface do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN_SURFACE
      def default() do
        :UNKNOWN_SURFACE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN_SURFACE) do
          0
        end

        def encode("UNKNOWN_SURFACE") do
          0
        end
      ),
      (
        def encode(:FB) do
          1
        end

        def encode("FB") do
          1
        end
      ),
      (
        def encode(:IG) do
          2
        end

        def encode("IG") do
          2
        end
      ),
      (
        def encode(:WA) do
          3
        end

        def encode("WA") do
          3
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :UNKNOWN_SURFACE
      end,
      def decode(1) do
        :FB
      end,
      def decode(2) do
        :IG
      end,
      def decode(3) do
        :WA
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN_SURFACE}, {1, :FB}, {2, :IG}, {3, :WA}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN_SURFACE) do
          true
        end,
        def has_constant?(:FB) do
          true
        end,
        def has_constant?(:IG) do
          true
        end,
        def has_constant?(:WA) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
