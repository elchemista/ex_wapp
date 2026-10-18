# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.MusicMessage.MusicMessageStyle do
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
        def encode(:VINYL) do
          1
        end

        def encode("VINYL") do
          1
        end
      ),
      (
        def encode(:MESSAGE_BUBBLE) do
          2
        end

        def encode("MESSAGE_BUBBLE") do
          2
        end
      ),
      (
        def encode(:LYRICS) do
          3
        end

        def encode("LYRICS") do
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
        :UNKNOWN
      end,
      def decode(1) do
        :VINYL
      end,
      def decode(2) do
        :MESSAGE_BUBBLE
      end,
      def decode(3) do
        :LYRICS
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN}, {1, :VINYL}, {2, :MESSAGE_BUBBLE}, {3, :LYRICS}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:VINYL) do
          true
        end,
        def has_constant?(:MESSAGE_BUBBLE) do
          true
        end,
        def has_constant?(:LYRICS) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
