# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.StatusQuotedMessage.StatusQuotedMessageType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :QUESTION_ANSWER
      def default() do
        :QUESTION_ANSWER
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:QUESTION_ANSWER) do
          1
        end

        def encode("QUESTION_ANSWER") do
          1
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :QUESTION_ANSWER
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :QUESTION_ANSWER}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:QUESTION_ANSWER) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
