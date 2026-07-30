# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.InteractiveMessageAction.InteractiveMessageActionMode do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :DISABLE_CTA
      def default() do
        :DISABLE_CTA
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:DISABLE_CTA) do
          1
        end

        def encode("DISABLE_CTA") do
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
        :DISABLE_CTA
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :DISABLE_CTA}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:DISABLE_CTA) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
