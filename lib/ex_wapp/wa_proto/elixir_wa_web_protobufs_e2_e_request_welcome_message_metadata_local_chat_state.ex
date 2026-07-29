# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.RequestWelcomeMessageMetadata.LocalChatState do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :EMPTY
      def default() do
        :EMPTY
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:EMPTY) do
          0
        end

        def encode("EMPTY") do
          0
        end
      ),
      (
        def encode(:NON_EMPTY) do
          1
        end

        def encode("NON_EMPTY") do
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
        :EMPTY
      end,
      def decode(1) do
        :NON_EMPTY
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :EMPTY}, {1, :NON_EMPTY}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:EMPTY) do
          true
        end,
        def has_constant?(:NON_EMPTY) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
