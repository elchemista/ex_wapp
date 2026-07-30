# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.UsernameChatStartModeAction.ChatStartMode do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :LID
      def default() do
        :LID
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:LID) do
          1
        end

        def encode("LID") do
          1
        end
      ),
      (
        def encode(:PN) do
          2
        end

        def encode("PN") do
          2
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :LID
      end,
      def decode(2) do
        :PN
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :LID}, {2, :PN}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:LID) do
          true
        end,
        def has_constant?(:PN) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
