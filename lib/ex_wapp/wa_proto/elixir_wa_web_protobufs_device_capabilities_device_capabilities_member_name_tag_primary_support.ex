# credo:disable-for-this-file
defmodule WAWebProtobufsDeviceCapabilities.DeviceCapabilities.MemberNameTagPrimarySupport do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :DISABLED
      def default() do
        :DISABLED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:DISABLED) do
          0
        end

        def encode("DISABLED") do
          0
        end
      ),
      (
        def encode(:RECEIVER_ENABLED) do
          1
        end

        def encode("RECEIVER_ENABLED") do
          1
        end
      ),
      (
        def encode(:SENDER_ENABLED) do
          2
        end

        def encode("SENDER_ENABLED") do
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
        :DISABLED
      end,
      def decode(1) do
        :RECEIVER_ENABLED
      end,
      def decode(2) do
        :SENDER_ENABLED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :DISABLED}, {1, :RECEIVER_ENABLED}, {2, :SENDER_ENABLED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:DISABLED) do
          true
        end,
        def has_constant?(:RECEIVER_ENABLED) do
          true
        end,
        def has_constant?(:SENDER_ENABLED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
