# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.AvatarUpdatedAction.AvatarEventType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UPDATED
      def default() do
        :UPDATED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UPDATED) do
          0
        end

        def encode("UPDATED") do
          0
        end
      ),
      (
        def encode(:CREATED) do
          1
        end

        def encode("CREATED") do
          1
        end
      ),
      (
        def encode(:DELETED) do
          2
        end

        def encode("DELETED") do
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
        :UPDATED
      end,
      def decode(1) do
        :CREATED
      end,
      def decode(2) do
        :DELETED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UPDATED}, {1, :CREATED}, {2, :DELETED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UPDATED) do
          true
        end,
        def has_constant?(:CREATED) do
          true
        end,
        def has_constant?(:DELETED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
