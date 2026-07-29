# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PollType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :POLL
      def default() do
        :POLL
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:POLL) do
          0
        end

        def encode("POLL") do
          0
        end
      ),
      (
        def encode(:QUIZ) do
          1
        end

        def encode("QUIZ") do
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
        :POLL
      end,
      def decode(1) do
        :QUIZ
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :POLL}, {1, :QUIZ}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:POLL) do
          true
        end,
        def has_constant?(:QUIZ) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
