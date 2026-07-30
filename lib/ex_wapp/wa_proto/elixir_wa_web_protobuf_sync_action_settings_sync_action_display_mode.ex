# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.SettingsSyncAction.DisplayMode do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :DISPLAY_MODE_UNKNOWN
      def default() do
        :DISPLAY_MODE_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:DISPLAY_MODE_UNKNOWN) do
          0
        end

        def encode("DISPLAY_MODE_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:ALWAYS) do
          1
        end

        def encode("ALWAYS") do
          1
        end
      ),
      (
        def encode(:NEVER) do
          2
        end

        def encode("NEVER") do
          2
        end
      ),
      (
        def encode(:ONLY_WHEN_APP_IS_OPEN) do
          3
        end

        def encode("ONLY_WHEN_APP_IS_OPEN") do
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
        :DISPLAY_MODE_UNKNOWN
      end,
      def decode(1) do
        :ALWAYS
      end,
      def decode(2) do
        :NEVER
      end,
      def decode(3) do
        :ONLY_WHEN_APP_IS_OPEN
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :DISPLAY_MODE_UNKNOWN}, {1, :ALWAYS}, {2, :NEVER}, {3, :ONLY_WHEN_APP_IS_OPEN}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:DISPLAY_MODE_UNKNOWN) do
          true
        end,
        def has_constant?(:ALWAYS) do
          true
        end,
        def has_constant?(:NEVER) do
          true
        end,
        def has_constant?(:ONLY_WHEN_APP_IS_OPEN) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
