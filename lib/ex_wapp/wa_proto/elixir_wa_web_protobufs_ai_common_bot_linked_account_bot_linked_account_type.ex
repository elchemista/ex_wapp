# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotLinkedAccount.BotLinkedAccountType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :BOT_LINKED_ACCOUNT_TYPE_1P
      def default() do
        :BOT_LINKED_ACCOUNT_TYPE_1P
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:BOT_LINKED_ACCOUNT_TYPE_1P) do
          0
        end

        def encode("BOT_LINKED_ACCOUNT_TYPE_1P") do
          0
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :BOT_LINKED_ACCOUNT_TYPE_1P
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :BOT_LINKED_ACCOUNT_TYPE_1P}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:BOT_LINKED_ACCOUNT_TYPE_1P) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
