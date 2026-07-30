# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.PatchDebugData.Platform do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :ANDROID
      def default() do
        :ANDROID
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:ANDROID) do
          0
        end

        def encode("ANDROID") do
          0
        end
      ),
      (
        def encode(:SMBA) do
          1
        end

        def encode("SMBA") do
          1
        end
      ),
      (
        def encode(:IPHONE) do
          2
        end

        def encode("IPHONE") do
          2
        end
      ),
      (
        def encode(:SMBI) do
          3
        end

        def encode("SMBI") do
          3
        end
      ),
      (
        def encode(:WEB) do
          4
        end

        def encode("WEB") do
          4
        end
      ),
      (
        def encode(:UWP) do
          5
        end

        def encode("UWP") do
          5
        end
      ),
      (
        def encode(:DARWIN) do
          6
        end

        def encode("DARWIN") do
          6
        end
      ),
      (
        def encode(:IPAD) do
          7
        end

        def encode("IPAD") do
          7
        end
      ),
      (
        def encode(:WEAROS) do
          8
        end

        def encode("WEAROS") do
          8
        end
      ),
      (
        def encode(:WASG) do
          9
        end

        def encode("WASG") do
          9
        end
      ),
      (
        def encode(:WEARM) do
          10
        end

        def encode("WEARM") do
          10
        end
      ),
      (
        def encode(:CAPI) do
          11
        end

        def encode("CAPI") do
          11
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :ANDROID
      end,
      def decode(1) do
        :SMBA
      end,
      def decode(2) do
        :IPHONE
      end,
      def decode(3) do
        :SMBI
      end,
      def decode(4) do
        :WEB
      end,
      def decode(5) do
        :UWP
      end,
      def decode(6) do
        :DARWIN
      end,
      def decode(7) do
        :IPAD
      end,
      def decode(8) do
        :WEAROS
      end,
      def decode(9) do
        :WASG
      end,
      def decode(10) do
        :WEARM
      end,
      def decode(11) do
        :CAPI
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :ANDROID},
        {1, :SMBA},
        {2, :IPHONE},
        {3, :SMBI},
        {4, :WEB},
        {5, :UWP},
        {6, :DARWIN},
        {7, :IPAD},
        {8, :WEAROS},
        {9, :WASG},
        {10, :WEARM},
        {11, :CAPI}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:ANDROID) do
          true
        end,
        def has_constant?(:SMBA) do
          true
        end,
        def has_constant?(:IPHONE) do
          true
        end,
        def has_constant?(:SMBI) do
          true
        end,
        def has_constant?(:WEB) do
          true
        end,
        def has_constant?(:UWP) do
          true
        end,
        def has_constant?(:DARWIN) do
          true
        end,
        def has_constant?(:IPAD) do
          true
        end,
        def has_constant?(:WEAROS) do
          true
        end,
        def has_constant?(:WASG) do
          true
        end,
        def has_constant?(:WEARM) do
          true
        end,
        def has_constant?(:CAPI) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
