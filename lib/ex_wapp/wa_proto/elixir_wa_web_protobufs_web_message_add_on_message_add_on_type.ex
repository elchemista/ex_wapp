# credo:disable-for-this-file
defmodule WAWebProtobufsWeb.MessageAddOn.MessageAddOnType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNDEFINED
      def default() do
        :UNDEFINED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNDEFINED) do
          0
        end

        def encode("UNDEFINED") do
          0
        end
      ),
      (
        def encode(:REACTION) do
          1
        end

        def encode("REACTION") do
          1
        end
      ),
      (
        def encode(:EVENT_RESPONSE) do
          2
        end

        def encode("EVENT_RESPONSE") do
          2
        end
      ),
      (
        def encode(:POLL_UPDATE) do
          3
        end

        def encode("POLL_UPDATE") do
          3
        end
      ),
      (
        def encode(:PIN_IN_CHAT) do
          4
        end

        def encode("PIN_IN_CHAT") do
          4
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :UNDEFINED
      end,
      def decode(1) do
        :REACTION
      end,
      def decode(2) do
        :EVENT_RESPONSE
      end,
      def decode(3) do
        :POLL_UPDATE
      end,
      def decode(4) do
        :PIN_IN_CHAT
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNDEFINED},
        {1, :REACTION},
        {2, :EVENT_RESPONSE},
        {3, :POLL_UPDATE},
        {4, :PIN_IN_CHAT}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNDEFINED) do
          true
        end,
        def has_constant?(:REACTION) do
          true
        end,
        def has_constant?(:EVENT_RESPONSE) do
          true
        end,
        def has_constant?(:POLL_UPDATE) do
          true
        end,
        def has_constant?(:PIN_IN_CHAT) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
