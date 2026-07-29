# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.RequestWelcomeMessageMetadata.WelcomeTrigger do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :CHAT_OPEN
      def default() do
        :CHAT_OPEN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:CHAT_OPEN) do
          0
        end

        def encode("CHAT_OPEN") do
          0
        end
      ),
      (
        def encode(:COMPANION_PAIRING) do
          1
        end

        def encode("COMPANION_PAIRING") do
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
        :CHAT_OPEN
      end,
      def decode(1) do
        :COMPANION_PAIRING
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :CHAT_OPEN}, {1, :COMPANION_PAIRING}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:CHAT_OPEN) do
          true
        end,
        def has_constant?(:COMPANION_PAIRING) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
