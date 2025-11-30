# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.IOSAppExtension do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :SHARE_EXTENSION
      def default() do
        :SHARE_EXTENSION
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:SHARE_EXTENSION) do
          0
        end

        def encode("SHARE_EXTENSION") do
          0
        end
      ),
      (
        def encode(:SERVICE_EXTENSION) do
          1
        end

        def encode("SERVICE_EXTENSION") do
          1
        end
      ),
      (
        def encode(:INTENTS_EXTENSION) do
          2
        end

        def encode("INTENTS_EXTENSION") do
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
        :SHARE_EXTENSION
      end,
      def decode(1) do
        :SERVICE_EXTENSION
      end,
      def decode(2) do
        :INTENTS_EXTENSION
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :SHARE_EXTENSION}, {1, :SERVICE_EXTENSION}, {2, :INTENTS_EXTENSION}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:SHARE_EXTENSION) do
          true
        end,
        def has_constant?(:SERVICE_EXTENSION) do
          true
        end,
        def has_constant?(:INTENTS_EXTENSION) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
