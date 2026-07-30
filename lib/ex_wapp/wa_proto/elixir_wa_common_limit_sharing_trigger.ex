# credo:disable-for-this-file
defmodule WACommon.LimitSharing.Trigger do
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
        def encode(:BIZ_SUPPORTS_FB_HOSTING) do
          2
        end

        def encode("BIZ_SUPPORTS_FB_HOSTING") do
          2
        end
      ),
      (
        def encode(:UNKNOWN_GROUP) do
          3
        end

        def encode("UNKNOWN_GROUP") do
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
        :UNKNOWN
      end,
      def decode(1) do
        :CHAT_SETTING
      end,
      def decode(2) do
        :BIZ_SUPPORTS_FB_HOSTING
      end,
      def decode(3) do
        :UNKNOWN_GROUP
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN}, {1, :CHAT_SETTING}, {2, :BIZ_SUPPORTS_FB_HOSTING}, {3, :UNKNOWN_GROUP}]
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
        def has_constant?(:BIZ_SUPPORTS_FB_HOSTING) do
          true
        end,
        def has_constant?(:UNKNOWN_GROUP) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
