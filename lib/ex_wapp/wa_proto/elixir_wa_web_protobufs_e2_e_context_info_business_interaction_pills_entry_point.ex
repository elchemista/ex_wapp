# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ContextInfo.BusinessInteractionPills.EntryPoint do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :ENTRY_POINT_UNKNOWN
      def default() do
        :ENTRY_POINT_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:ENTRY_POINT_UNKNOWN) do
          0
        end

        def encode("ENTRY_POINT_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:P2P_LINK_SHARE) do
          1
        end

        def encode("P2P_LINK_SHARE") do
          1
        end
      ),
      (
        def encode(:CONTACT_CARD_SHARING) do
          2
        end

        def encode("CONTACT_CARD_SHARING") do
          2
        end
      ),
      (
        def encode(:PHONE_NUMBER) do
          3
        end

        def encode("PHONE_NUMBER") do
          3
        end
      ),
      (
        def encode(:STATUS) do
          4
        end

        def encode("STATUS") do
          4
        end
      ),
      (
        def encode(:IN_THREAD_CONTEXT_CARD) do
          5
        end

        def encode("IN_THREAD_CONTEXT_CARD") do
          5
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :ENTRY_POINT_UNKNOWN
      end,
      def decode(1) do
        :P2P_LINK_SHARE
      end,
      def decode(2) do
        :CONTACT_CARD_SHARING
      end,
      def decode(3) do
        :PHONE_NUMBER
      end,
      def decode(4) do
        :STATUS
      end,
      def decode(5) do
        :IN_THREAD_CONTEXT_CARD
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :ENTRY_POINT_UNKNOWN},
        {1, :P2P_LINK_SHARE},
        {2, :CONTACT_CARD_SHARING},
        {3, :PHONE_NUMBER},
        {4, :STATUS},
        {5, :IN_THREAD_CONTEXT_CARD}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:ENTRY_POINT_UNKNOWN) do
          true
        end,
        def has_constant?(:P2P_LINK_SHARE) do
          true
        end,
        def has_constant?(:CONTACT_CARD_SHARING) do
          true
        end,
        def has_constant?(:PHONE_NUMBER) do
          true
        end,
        def has_constant?(:STATUS) do
          true
        end,
        def has_constant?(:IN_THREAD_CONTEXT_CARD) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
