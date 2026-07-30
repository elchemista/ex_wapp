# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.WaffleAccountLinkStateAction.AccountLinkState do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :ACTIVE
      def default() do
        :ACTIVE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:ACTIVE) do
          0
        end

        def encode("ACTIVE") do
          0
        end
      ),
      (
        def encode(:PAUSED) do
          1
        end

        def encode("PAUSED") do
          1
        end
      ),
      (
        def encode(:UNLINKED) do
          2
        end

        def encode("UNLINKED") do
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
        :ACTIVE
      end,
      def decode(1) do
        :PAUSED
      end,
      def decode(2) do
        :UNLINKED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :ACTIVE}, {1, :PAUSED}, {2, :UNLINKED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:ACTIVE) do
          true
        end,
        def has_constant?(:PAUSED) do
          true
        end,
        def has_constant?(:UNLINKED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
