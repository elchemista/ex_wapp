# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.SettingsSyncAction.SettingPlatform do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :PLATFORM_UNKNOWN
      def default() do
        :PLATFORM_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:PLATFORM_UNKNOWN) do
          0
        end

        def encode("PLATFORM_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:WEB) do
          1
        end

        def encode("WEB") do
          1
        end
      ),
      (
        def encode(:HYBRID) do
          2
        end

        def encode("HYBRID") do
          2
        end
      ),
      (
        def encode(:WINDOWS) do
          3
        end

        def encode("WINDOWS") do
          3
        end
      ),
      (
        def encode(:MAC) do
          4
        end

        def encode("MAC") do
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
        :PLATFORM_UNKNOWN
      end,
      def decode(1) do
        :WEB
      end,
      def decode(2) do
        :HYBRID
      end,
      def decode(3) do
        :WINDOWS
      end,
      def decode(4) do
        :MAC
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :PLATFORM_UNKNOWN}, {1, :WEB}, {2, :HYBRID}, {3, :WINDOWS}, {4, :MAC}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:PLATFORM_UNKNOWN) do
          true
        end,
        def has_constant?(:WEB) do
          true
        end,
        def has_constant?(:HYBRID) do
          true
        end,
        def has_constant?(:WINDOWS) do
          true
        end,
        def has_constant?(:MAC) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
