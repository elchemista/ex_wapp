# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.DisappearingMode.Initiator do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :CHANGED_IN_CHAT
      def default() do
        :CHANGED_IN_CHAT
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:CHANGED_IN_CHAT) do
          0
        end

        def encode("CHANGED_IN_CHAT") do
          0
        end
      ),
      (
        def encode(:INITIATED_BY_ME) do
          1
        end

        def encode("INITIATED_BY_ME") do
          1
        end
      ),
      (
        def encode(:INITIATED_BY_OTHER) do
          2
        end

        def encode("INITIATED_BY_OTHER") do
          2
        end
      ),
      (
        def encode(:BIZ_UPGRADE_FB_HOSTING) do
          3
        end

        def encode("BIZ_UPGRADE_FB_HOSTING") do
          3
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :CHANGED_IN_CHAT
      end,
      def decode(1) do
        :INITIATED_BY_ME
      end,
      def decode(2) do
        :INITIATED_BY_OTHER
      end,
      def decode(3) do
        :BIZ_UPGRADE_FB_HOSTING
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :CHANGED_IN_CHAT},
        {1, :INITIATED_BY_ME},
        {2, :INITIATED_BY_OTHER},
        {3, :BIZ_UPGRADE_FB_HOSTING}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:CHANGED_IN_CHAT) do
          true
        end,
        def has_constant?(:INITIATED_BY_ME) do
          true
        end,
        def has_constant?(:INITIATED_BY_OTHER) do
          true
        end,
        def has_constant?(:BIZ_UPGRADE_FB_HOSTING) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
