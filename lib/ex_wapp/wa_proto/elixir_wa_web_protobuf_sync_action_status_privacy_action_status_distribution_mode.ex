# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :ALLOW_LIST
      def default() do
        :ALLOW_LIST
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:ALLOW_LIST) do
          0
        end

        def encode("ALLOW_LIST") do
          0
        end
      ),
      (
        def encode(:DENY_LIST) do
          1
        end

        def encode("DENY_LIST") do
          1
        end
      ),
      (
        def encode(:CONTACTS) do
          2
        end

        def encode("CONTACTS") do
          2
        end
      ),
      (
        def encode(:CLOSE_FRIENDS) do
          3
        end

        def encode("CLOSE_FRIENDS") do
          3
        end
      ),
      (
        def encode(:CUSTOM_LIST) do
          4
        end

        def encode("CUSTOM_LIST") do
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
        :ALLOW_LIST
      end,
      def decode(1) do
        :DENY_LIST
      end,
      def decode(2) do
        :CONTACTS
      end,
      def decode(3) do
        :CLOSE_FRIENDS
      end,
      def decode(4) do
        :CUSTOM_LIST
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :ALLOW_LIST}, {1, :DENY_LIST}, {2, :CONTACTS}, {3, :CLOSE_FRIENDS}, {4, :CUSTOM_LIST}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:ALLOW_LIST) do
          true
        end,
        def has_constant?(:DENY_LIST) do
          true
        end,
        def has_constant?(:CONTACTS) do
          true
        end,
        def has_constant?(:CLOSE_FRIENDS) do
          true
        end,
        def has_constant?(:CUSTOM_LIST) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
