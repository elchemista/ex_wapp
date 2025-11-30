# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.Product do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :WHATSAPP
      def default() do
        :WHATSAPP
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:WHATSAPP) do
          0
        end

        def encode("WHATSAPP") do
          0
        end
      ),
      (
        def encode(:MESSENGER) do
          1
        end

        def encode("MESSENGER") do
          1
        end
      ),
      (
        def encode(:INTEROP) do
          2
        end

        def encode("INTEROP") do
          2
        end
      ),
      (
        def encode(:INTEROP_MSGR) do
          3
        end

        def encode("INTEROP_MSGR") do
          3
        end
      ),
      (
        def encode(:WHATSAPP_LID) do
          4
        end

        def encode("WHATSAPP_LID") do
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
        :WHATSAPP
      end,
      def decode(1) do
        :MESSENGER
      end,
      def decode(2) do
        :INTEROP
      end,
      def decode(3) do
        :INTEROP_MSGR
      end,
      def decode(4) do
        :WHATSAPP_LID
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :WHATSAPP}, {1, :MESSENGER}, {2, :INTEROP}, {3, :INTEROP_MSGR}, {4, :WHATSAPP_LID}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:WHATSAPP) do
          true
        end,
        def has_constant?(:MESSENGER) do
          true
        end,
        def has_constant?(:INTEROP) do
          true
        end,
        def has_constant?(:INTEROP_MSGR) do
          true
        end,
        def has_constant?(:WHATSAPP_LID) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
