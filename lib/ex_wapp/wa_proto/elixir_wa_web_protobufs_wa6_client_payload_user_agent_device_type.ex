# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.UserAgent.DeviceType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :PHONE
      def default() do
        :PHONE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:PHONE) do
          0
        end

        def encode("PHONE") do
          0
        end
      ),
      (
        def encode(:TABLET) do
          1
        end

        def encode("TABLET") do
          1
        end
      ),
      (
        def encode(:DESKTOP) do
          2
        end

        def encode("DESKTOP") do
          2
        end
      ),
      (
        def encode(:WEARABLE) do
          3
        end

        def encode("WEARABLE") do
          3
        end
      ),
      (
        def encode(:VR) do
          4
        end

        def encode("VR") do
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
        :PHONE
      end,
      def decode(1) do
        :TABLET
      end,
      def decode(2) do
        :DESKTOP
      end,
      def decode(3) do
        :WEARABLE
      end,
      def decode(4) do
        :VR
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :PHONE}, {1, :TABLET}, {2, :DESKTOP}, {3, :WEARABLE}, {4, :VR}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:PHONE) do
          true
        end,
        def has_constant?(:TABLET) do
          true
        end,
        def has_constant?(:DESKTOP) do
          true
        end,
        def has_constant?(:WEARABLE) do
          true
        end,
        def has_constant?(:VR) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
