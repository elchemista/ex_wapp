# credo:disable-for-this-file
defmodule WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ChatLockSupportLevel do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :NONE
      def default() do
        :NONE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:NONE) do
          0
        end

        def encode("NONE") do
          0
        end
      ),
      (
        def encode(:MINIMAL) do
          1
        end

        def encode("MINIMAL") do
          1
        end
      ),
      (
        def encode(:FULL) do
          2
        end

        def encode("FULL") do
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
        :NONE
      end,
      def decode(1) do
        :MINIMAL
      end,
      def decode(2) do
        :FULL
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :NONE}, {1, :MINIMAL}, {2, :FULL}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NONE) do
          true
        end,
        def has_constant?(:MINIMAL) do
          true
        end,
        def has_constant?(:FULL) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
