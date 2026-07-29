# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PlaceholderMessage.PlaceholderType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :MASK_LINKED_DEVICES
      def default() do
        :MASK_LINKED_DEVICES
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:MASK_LINKED_DEVICES) do
          0
        end

        def encode("MASK_LINKED_DEVICES") do
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
        :MASK_LINKED_DEVICES
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :MASK_LINKED_DEVICES}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:MASK_LINKED_DEVICES) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
