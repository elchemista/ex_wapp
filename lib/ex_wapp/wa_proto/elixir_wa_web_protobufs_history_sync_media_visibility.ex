# credo:disable-for-this-file
defmodule WAWebProtobufsHistorySync.MediaVisibility do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :DEFAULT
      def default() do
        :DEFAULT
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:DEFAULT) do
          0
        end

        def encode("DEFAULT") do
          0
        end
      ),
      (
        def encode(:OFF) do
          1
        end

        def encode("OFF") do
          1
        end
      ),
      (
        def encode(:ON) do
          2
        end

        def encode("ON") do
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
        :DEFAULT
      end,
      def decode(1) do
        :OFF
      end,
      def decode(2) do
        :ON
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :DEFAULT}, {1, :OFF}, {2, :ON}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:DEFAULT) do
          true
        end,
        def has_constant?(:OFF) do
          true
        end,
        def has_constant?(:ON) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
