# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.GroupHistoryToggleAction.GroupHistoryToggleMode do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :GROUP_HISTORY_TOGGLE_MODE_UNKNOWN
      def default() do
        :GROUP_HISTORY_TOGGLE_MODE_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:GROUP_HISTORY_TOGGLE_MODE_UNKNOWN) do
          0
        end

        def encode("GROUP_HISTORY_TOGGLE_MODE_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:GROUP_HISTORY_TOGGLE_MODE_ON) do
          1
        end

        def encode("GROUP_HISTORY_TOGGLE_MODE_ON") do
          1
        end
      ),
      (
        def encode(:GROUP_HISTORY_TOGGLE_MODE_OFF) do
          2
        end

        def encode("GROUP_HISTORY_TOGGLE_MODE_OFF") do
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
        :GROUP_HISTORY_TOGGLE_MODE_UNKNOWN
      end,
      def decode(1) do
        :GROUP_HISTORY_TOGGLE_MODE_ON
      end,
      def decode(2) do
        :GROUP_HISTORY_TOGGLE_MODE_OFF
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :GROUP_HISTORY_TOGGLE_MODE_UNKNOWN},
        {1, :GROUP_HISTORY_TOGGLE_MODE_ON},
        {2, :GROUP_HISTORY_TOGGLE_MODE_OFF}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:GROUP_HISTORY_TOGGLE_MODE_UNKNOWN) do
          true
        end,
        def has_constant?(:GROUP_HISTORY_TOGGLE_MODE_ON) do
          true
        end,
        def has_constant?(:GROUP_HISTORY_TOGGLE_MODE_OFF) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
