# credo:disable-for-this-file
defmodule WACompanionReg.DeviceProps.PlatformType do
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
        def encode(:CHROME) do
          1
        end

        def encode("CHROME") do
          1
        end
      ),
      (
        def encode(:FIREFOX) do
          2
        end

        def encode("FIREFOX") do
          2
        end
      ),
      (
        def encode(:IE) do
          3
        end

        def encode("IE") do
          3
        end
      ),
      (
        def encode(:OPERA) do
          4
        end

        def encode("OPERA") do
          4
        end
      ),
      (
        def encode(:SAFARI) do
          5
        end

        def encode("SAFARI") do
          5
        end
      ),
      (
        def encode(:EDGE) do
          6
        end

        def encode("EDGE") do
          6
        end
      ),
      (
        def encode(:DESKTOP) do
          7
        end

        def encode("DESKTOP") do
          7
        end
      ),
      (
        def encode(:IPAD) do
          8
        end

        def encode("IPAD") do
          8
        end
      ),
      (
        def encode(:ANDROID_TABLET) do
          9
        end

        def encode("ANDROID_TABLET") do
          9
        end
      ),
      (
        def encode(:OHANA) do
          10
        end

        def encode("OHANA") do
          10
        end
      ),
      (
        def encode(:ALOHA) do
          11
        end

        def encode("ALOHA") do
          11
        end
      ),
      (
        def encode(:CATALINA) do
          12
        end

        def encode("CATALINA") do
          12
        end
      ),
      (
        def encode(:TCL_TV) do
          13
        end

        def encode("TCL_TV") do
          13
        end
      ),
      (
        def encode(:IOS_PHONE) do
          14
        end

        def encode("IOS_PHONE") do
          14
        end
      ),
      (
        def encode(:IOS_CATALYST) do
          15
        end

        def encode("IOS_CATALYST") do
          15
        end
      ),
      (
        def encode(:ANDROID_PHONE) do
          16
        end

        def encode("ANDROID_PHONE") do
          16
        end
      ),
      (
        def encode(:ANDROID_AMBIGUOUS) do
          17
        end

        def encode("ANDROID_AMBIGUOUS") do
          17
        end
      ),
      (
        def encode(:WEAR_OS) do
          18
        end

        def encode("WEAR_OS") do
          18
        end
      ),
      (
        def encode(:AR_WRIST) do
          19
        end

        def encode("AR_WRIST") do
          19
        end
      ),
      (
        def encode(:AR_DEVICE) do
          20
        end

        def encode("AR_DEVICE") do
          20
        end
      ),
      (
        def encode(:UWP) do
          21
        end

        def encode("UWP") do
          21
        end
      ),
      (
        def encode(:VR) do
          22
        end

        def encode("VR") do
          22
        end
      ),
      (
        def encode(:CLOUD_API) do
          23
        end

        def encode("CLOUD_API") do
          23
        end
      ),
      (
        def encode(:SMARTGLASSES) do
          24
        end

        def encode("SMARTGLASSES") do
          24
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
        :CHROME
      end,
      def decode(2) do
        :FIREFOX
      end,
      def decode(3) do
        :IE
      end,
      def decode(4) do
        :OPERA
      end,
      def decode(5) do
        :SAFARI
      end,
      def decode(6) do
        :EDGE
      end,
      def decode(7) do
        :DESKTOP
      end,
      def decode(8) do
        :IPAD
      end,
      def decode(9) do
        :ANDROID_TABLET
      end,
      def decode(10) do
        :OHANA
      end,
      def decode(11) do
        :ALOHA
      end,
      def decode(12) do
        :CATALINA
      end,
      def decode(13) do
        :TCL_TV
      end,
      def decode(14) do
        :IOS_PHONE
      end,
      def decode(15) do
        :IOS_CATALYST
      end,
      def decode(16) do
        :ANDROID_PHONE
      end,
      def decode(17) do
        :ANDROID_AMBIGUOUS
      end,
      def decode(18) do
        :WEAR_OS
      end,
      def decode(19) do
        :AR_WRIST
      end,
      def decode(20) do
        :AR_DEVICE
      end,
      def decode(21) do
        :UWP
      end,
      def decode(22) do
        :VR
      end,
      def decode(23) do
        :CLOUD_API
      end,
      def decode(24) do
        :SMARTGLASSES
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :CHROME},
        {2, :FIREFOX},
        {3, :IE},
        {4, :OPERA},
        {5, :SAFARI},
        {6, :EDGE},
        {7, :DESKTOP},
        {8, :IPAD},
        {9, :ANDROID_TABLET},
        {10, :OHANA},
        {11, :ALOHA},
        {12, :CATALINA},
        {13, :TCL_TV},
        {14, :IOS_PHONE},
        {15, :IOS_CATALYST},
        {16, :ANDROID_PHONE},
        {17, :ANDROID_AMBIGUOUS},
        {18, :WEAR_OS},
        {19, :AR_WRIST},
        {20, :AR_DEVICE},
        {21, :UWP},
        {22, :VR},
        {23, :CLOUD_API},
        {24, :SMARTGLASSES}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:CHROME) do
          true
        end,
        def has_constant?(:FIREFOX) do
          true
        end,
        def has_constant?(:IE) do
          true
        end,
        def has_constant?(:OPERA) do
          true
        end,
        def has_constant?(:SAFARI) do
          true
        end,
        def has_constant?(:EDGE) do
          true
        end,
        def has_constant?(:DESKTOP) do
          true
        end,
        def has_constant?(:IPAD) do
          true
        end,
        def has_constant?(:ANDROID_TABLET) do
          true
        end,
        def has_constant?(:OHANA) do
          true
        end,
        def has_constant?(:ALOHA) do
          true
        end,
        def has_constant?(:CATALINA) do
          true
        end,
        def has_constant?(:TCL_TV) do
          true
        end,
        def has_constant?(:IOS_PHONE) do
          true
        end,
        def has_constant?(:IOS_CATALYST) do
          true
        end,
        def has_constant?(:ANDROID_PHONE) do
          true
        end,
        def has_constant?(:ANDROID_AMBIGUOUS) do
          true
        end,
        def has_constant?(:WEAR_OS) do
          true
        end,
        def has_constant?(:AR_WRIST) do
          true
        end,
        def has_constant?(:AR_DEVICE) do
          true
        end,
        def has_constant?(:UWP) do
          true
        end,
        def has_constant?(:VR) do
          true
        end,
        def has_constant?(:CLOUD_API) do
          true
        end,
        def has_constant?(:SMARTGLASSES) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
