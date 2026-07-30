# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.WASARootSecretAction.RootSecretEntry.Status do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :INACTIVE
      def default() do
        :INACTIVE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:INACTIVE) do
          0
        end

        def encode("INACTIVE") do
          0
        end
      ),
      (
        def encode(:ACTIVE) do
          1
        end

        def encode("ACTIVE") do
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
        :INACTIVE
      end,
      def decode(1) do
        :ACTIVE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :INACTIVE}, {1, :ACTIVE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:INACTIVE) do
          true
        end,
        def has_constant?(:ACTIVE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
