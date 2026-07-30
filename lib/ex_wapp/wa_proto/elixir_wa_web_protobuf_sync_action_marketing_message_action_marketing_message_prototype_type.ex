# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.MarketingMessageAction.MarketingMessagePrototypeType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :PERSONALIZED
      def default() do
        :PERSONALIZED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:PERSONALIZED) do
          0
        end

        def encode("PERSONALIZED") do
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
        :PERSONALIZED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :PERSONALIZED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:PERSONALIZED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
