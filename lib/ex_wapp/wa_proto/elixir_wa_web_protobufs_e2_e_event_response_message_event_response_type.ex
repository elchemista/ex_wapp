# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.EventResponseMessage.EventResponseType do
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
        def encode(:GOING) do
          1
        end

        def encode("GOING") do
          1
        end
      ),
      (
        def encode(:NOT_GOING) do
          2
        end

        def encode("NOT_GOING") do
          2
        end
      ),
      (
        def encode(:MAYBE) do
          3
        end

        def encode("MAYBE") do
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
        :GOING
      end,
      def decode(2) do
        :NOT_GOING
      end,
      def decode(3) do
        :MAYBE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN}, {1, :GOING}, {2, :NOT_GOING}, {3, :MAYBE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:GOING) do
          true
        end,
        def has_constant?(:NOT_GOING) do
          true
        end,
        def has_constant?(:MAYBE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
