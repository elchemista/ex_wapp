# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.DisappearingMode.Trigger do
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
        def encode(:CHAT_SETTING) do
          1
        end

        def encode("CHAT_SETTING") do
          1
        end
      ),
      (
        def encode(:ACCOUNT_SETTING) do
          2
        end

        def encode("ACCOUNT_SETTING") do
          2
        end
      ),
      (
        def encode(:BULK_CHANGE) do
          3
        end

        def encode("BULK_CHANGE") do
          3
        end
      ),
      (
        def encode(:BIZ_SUPPORTS_FB_HOSTING) do
          4
        end

        def encode("BIZ_SUPPORTS_FB_HOSTING") do
          4
        end
      ),
      (
        def encode(:UNKNOWN_GROUPS) do
          5
        end

        def encode("UNKNOWN_GROUPS") do
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
        :UNKNOWN
      end,
      def decode(1) do
        :CHAT_SETTING
      end,
      def decode(2) do
        :ACCOUNT_SETTING
      end,
      def decode(3) do
        :BULK_CHANGE
      end,
      def decode(4) do
        :BIZ_SUPPORTS_FB_HOSTING
      end,
      def decode(5) do
        :UNKNOWN_GROUPS
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :CHAT_SETTING},
        {2, :ACCOUNT_SETTING},
        {3, :BULK_CHANGE},
        {4, :BIZ_SUPPORTS_FB_HOSTING},
        {5, :UNKNOWN_GROUPS}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:CHAT_SETTING) do
          true
        end,
        def has_constant?(:ACCOUNT_SETTING) do
          true
        end,
        def has_constant?(:BULK_CHANGE) do
          true
        end,
        def has_constant?(:BIZ_SUPPORTS_FB_HOSTING) do
          true
        end,
        def has_constant?(:UNKNOWN_GROUPS) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
