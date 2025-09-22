# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.TrafficAnonymization do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :OFF
      def default() do
        :OFF
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:OFF) do
          0
        end

        def encode("OFF") do
          0
        end
      ),
      (
        def encode(:STANDARD) do
          1
        end

        def encode("STANDARD") do
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
        :OFF
      end,
      def decode(1) do
        :STANDARD
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :OFF}, {1, :STANDARD}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:OFF) do
          true
        end,
        def has_constant?(:STANDARD) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
