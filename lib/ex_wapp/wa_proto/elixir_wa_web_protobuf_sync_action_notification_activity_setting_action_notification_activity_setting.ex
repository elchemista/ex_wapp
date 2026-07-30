# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.NotificationActivitySettingAction.NotificationActivitySetting do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :DEFAULT_ALL_MESSAGES
      def default() do
        :DEFAULT_ALL_MESSAGES
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:DEFAULT_ALL_MESSAGES) do
          0
        end

        def encode("DEFAULT_ALL_MESSAGES") do
          0
        end
      ),
      (
        def encode(:ALL_MESSAGES) do
          1
        end

        def encode("ALL_MESSAGES") do
          1
        end
      ),
      (
        def encode(:HIGHLIGHTS) do
          2
        end

        def encode("HIGHLIGHTS") do
          2
        end
      ),
      (
        def encode(:DEFAULT_HIGHLIGHTS) do
          3
        end

        def encode("DEFAULT_HIGHLIGHTS") do
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
        :DEFAULT_ALL_MESSAGES
      end,
      def decode(1) do
        :ALL_MESSAGES
      end,
      def decode(2) do
        :HIGHLIGHTS
      end,
      def decode(3) do
        :DEFAULT_HIGHLIGHTS
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :DEFAULT_ALL_MESSAGES}, {1, :ALL_MESSAGES}, {2, :HIGHLIGHTS}, {3, :DEFAULT_HIGHLIGHTS}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:DEFAULT_ALL_MESSAGES) do
          true
        end,
        def has_constant?(:ALL_MESSAGES) do
          true
        end,
        def has_constant?(:HIGHLIGHTS) do
          true
        end,
        def has_constant?(:DEFAULT_HIGHLIGHTS) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
