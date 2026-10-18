# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.EventInviteMessage.EventStatus do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN
      def default() do
        :UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN) do
          0
        end

        def encode("UNKNOWN") do
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
      ),
      (
        def encode(:CANCELED) do
          2
        end

        def encode("CANCELED") do
          2
        end
      ),
      (
        def encode(:SUSPENDED) do
          3
        end

        def encode("SUSPENDED") do
          3
        end
      ),
      (
        def encode(:DELETED) do
          4
        end

        def encode("DELETED") do
          4
        end
      ),
      (
        def encode(:LEFT_EVENT) do
          5
        end

        def encode("LEFT_EVENT") do
          5
        end
      ),
      (
        def encode(:REMOVED_FROM_INVITE_LIST) do
          6
        end

        def encode("REMOVED_FROM_INVITE_LIST") do
          6
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :UNKNOWN
      end,
      def decode(1) do
        :ACTIVE
      end,
      def decode(2) do
        :CANCELED
      end,
      def decode(3) do
        :SUSPENDED
      end,
      def decode(4) do
        :DELETED
      end,
      def decode(5) do
        :LEFT_EVENT
      end,
      def decode(6) do
        :REMOVED_FROM_INVITE_LIST
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :ACTIVE},
        {2, :CANCELED},
        {3, :SUSPENDED},
        {4, :DELETED},
        {5, :LEFT_EVENT},
        {6, :REMOVED_FROM_INVITE_LIST}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:ACTIVE) do
          true
        end,
        def has_constant?(:CANCELED) do
          true
        end,
        def has_constant?(:SUSPENDED) do
          true
        end,
        def has_constant?(:DELETED) do
          true
        end,
        def has_constant?(:LEFT_EVENT) do
          true
        end,
        def has_constant?(:REMOVED_FROM_INVITE_LIST) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
