# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.UserAgent.Platform do
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
        def encode(:IOS) do
          1
        end

        def encode("IOS") do
          1
        end
      ),
      (
        def encode(:WINDOWS_PHONE) do
          2
        end

        def encode("WINDOWS_PHONE") do
          2
        end
      ),
      (
        def encode(:BLACKBERRY) do
          3
        end

        def encode("BLACKBERRY") do
          3
        end
      ),
      (
        def encode(:BLACKBERRYX) do
          4
        end

        def encode("BLACKBERRYX") do
          4
        end
      ),
      (
        def encode(:S40) do
          5
        end

        def encode("S40") do
          5
        end
      ),
      (
        def encode(:S60) do
          6
        end

        def encode("S60") do
          6
        end
      ),
      (
        def encode(:PYTHON_CLIENT) do
          7
        end

        def encode("PYTHON_CLIENT") do
          7
        end
      ),
      (
        def encode(:TIZEN) do
          8
        end

        def encode("TIZEN") do
          8
        end
      ),
      (
        def encode(:ENTERPRISE) do
          9
        end

        def encode("ENTERPRISE") do
          9
        end
      ),
      (
        def encode(:SMB_ANDROID) do
          10
        end

        def encode("SMB_ANDROID") do
          10
        end
      ),
      (
        def encode(:KAIOS) do
          11
        end

        def encode("KAIOS") do
          11
        end
      ),
      (
        def encode(:SMB_IOS) do
          12
        end

        def encode("SMB_IOS") do
          12
        end
      ),
      (
        def encode(:WINDOWS) do
          13
        end

        def encode("WINDOWS") do
          13
        end
      ),
      (
        def encode(:WEB) do
          14
        end

        def encode("WEB") do
          14
        end
      ),
      (
        def encode(:PORTAL) do
          15
        end

        def encode("PORTAL") do
          15
        end
      ),
      (
        def encode(:GREEN_ANDROID) do
          16
        end

        def encode("GREEN_ANDROID") do
          16
        end
      ),
      (
        def encode(:GREEN_IPHONE) do
          17
        end

        def encode("GREEN_IPHONE") do
          17
        end
      ),
      (
        def encode(:BLUE_ANDROID) do
          18
        end

        def encode("BLUE_ANDROID") do
          18
        end
      ),
      (
        def encode(:BLUE_IPHONE) do
          19
        end

        def encode("BLUE_IPHONE") do
          19
        end
      ),
      (
        def encode(:FBLITE_ANDROID) do
          20
        end

        def encode("FBLITE_ANDROID") do
          20
        end
      ),
      (
        def encode(:MLITE_ANDROID) do
          21
        end

        def encode("MLITE_ANDROID") do
          21
        end
      ),
      (
        def encode(:IGLITE_ANDROID) do
          22
        end

        def encode("IGLITE_ANDROID") do
          22
        end
      ),
      (
        def encode(:PAGE) do
          23
        end

        def encode("PAGE") do
          23
        end
      ),
      (
        def encode(:MACOS) do
          24
        end

        def encode("MACOS") do
          24
        end
      ),
      (
        def encode(:OCULUS_MSG) do
          25
        end

        def encode("OCULUS_MSG") do
          25
        end
      ),
      (
        def encode(:OCULUS_CALL) do
          26
        end

        def encode("OCULUS_CALL") do
          26
        end
      ),
      (
        def encode(:MILAN) do
          27
        end

        def encode("MILAN") do
          27
        end
      ),
      (
        def encode(:CAPI) do
          28
        end

        def encode("CAPI") do
          28
        end
      ),
      (
        def encode(:WEAROS) do
          29
        end

        def encode("WEAROS") do
          29
        end
      ),
      (
        def encode(:ARDEVICE) do
          30
        end

        def encode("ARDEVICE") do
          30
        end
      ),
      (
        def encode(:VRDEVICE) do
          31
        end

        def encode("VRDEVICE") do
          31
        end
      ),
      (
        def encode(:BLUE_WEB) do
          32
        end

        def encode("BLUE_WEB") do
          32
        end
      ),
      (
        def encode(:IPAD) do
          33
        end

        def encode("IPAD") do
          33
        end
      ),
      (
        def encode(:TEST) do
          34
        end

        def encode("TEST") do
          34
        end
      ),
      (
        def encode(:SMART_GLASSES) do
          35
        end

        def encode("SMART_GLASSES") do
          35
        end
      ),
      (
        def encode(:BLUE_VR) do
          36
        end

        def encode("BLUE_VR") do
          36
        end
      ),
      (
        def encode(:AR_WRIST) do
          37
        end

        def encode("AR_WRIST") do
          37
        end
      ),
      (
        def encode(:WAIL) do
          38
        end

        def encode("WAIL") do
          38
        end
      ),
      (
        def encode(:WORK_ANDROID) do
          39
        end

        def encode("WORK_ANDROID") do
          39
        end
      ),
      (
        def encode(:WORK_IOS) do
          40
        end

        def encode("WORK_IOS") do
          40
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(18) do
        :BLUE_ANDROID
      end,
      def decode(4) do
        :BLACKBERRYX
      end,
      def decode(34) do
        :TEST
      end,
      def decode(12) do
        :SMB_IOS
      end,
      def decode(19) do
        :BLUE_IPHONE
      end,
      def decode(29) do
        :WEAROS
      end,
      def decode(13) do
        :WINDOWS
      end,
      def decode(2) do
        :WINDOWS_PHONE
      end,
      def decode(7) do
        :PYTHON_CLIENT
      end,
      def decode(38) do
        :WAIL
      end,
      def decode(31) do
        :VRDEVICE
      end,
      def decode(8) do
        :TIZEN
      end,
      def decode(10) do
        :SMB_ANDROID
      end,
      def decode(23) do
        :PAGE
      end,
      def decode(9) do
        :ENTERPRISE
      end,
      def decode(15) do
        :PORTAL
      end,
      def decode(35) do
        :SMART_GLASSES
      end,
      def decode(36) do
        :BLUE_VR
      end,
      def decode(32) do
        :BLUE_WEB
      end,
      def decode(1) do
        :IOS
      end,
      def decode(25) do
        :OCULUS_MSG
      end,
      def decode(28) do
        :CAPI
      end,
      def decode(20) do
        :FBLITE_ANDROID
      end,
      def decode(6) do
        :S60
      end,
      def decode(11) do
        :KAIOS
      end,
      def decode(17) do
        :GREEN_IPHONE
      end,
      def decode(24) do
        :MACOS
      end,
      def decode(37) do
        :AR_WRIST
      end,
      def decode(40) do
        :WORK_IOS
      end,
      def decode(14) do
        :WEB
      end,
      def decode(33) do
        :IPAD
      end,
      def decode(3) do
        :BLACKBERRY
      end,
      def decode(16) do
        :GREEN_ANDROID
      end,
      def decode(30) do
        :ARDEVICE
      end,
      def decode(21) do
        :MLITE_ANDROID
      end,
      def decode(5) do
        :S40
      end,
      def decode(0) do
        :ANDROID
      end,
      def decode(27) do
        :MILAN
      end,
      def decode(26) do
        :OCULUS_CALL
      end,
      def decode(22) do
        :IGLITE_ANDROID
      end,
      def decode(39) do
        :WORK_ANDROID
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :ANDROID},
        {1, :IOS},
        {2, :WINDOWS_PHONE},
        {3, :BLACKBERRY},
        {4, :BLACKBERRYX},
        {5, :S40},
        {6, :S60},
        {7, :PYTHON_CLIENT},
        {8, :TIZEN},
        {9, :ENTERPRISE},
        {10, :SMB_ANDROID},
        {11, :KAIOS},
        {12, :SMB_IOS},
        {13, :WINDOWS},
        {14, :WEB},
        {15, :PORTAL},
        {16, :GREEN_ANDROID},
        {17, :GREEN_IPHONE},
        {18, :BLUE_ANDROID},
        {19, :BLUE_IPHONE},
        {20, :FBLITE_ANDROID},
        {21, :MLITE_ANDROID},
        {22, :IGLITE_ANDROID},
        {23, :PAGE},
        {24, :MACOS},
        {25, :OCULUS_MSG},
        {26, :OCULUS_CALL},
        {27, :MILAN},
        {28, :CAPI},
        {29, :WEAROS},
        {30, :ARDEVICE},
        {31, :VRDEVICE},
        {32, :BLUE_WEB},
        {33, :IPAD},
        {34, :TEST},
        {35, :SMART_GLASSES},
        {36, :BLUE_VR},
        {37, :AR_WRIST},
        {38, :WAIL},
        {39, :WORK_ANDROID},
        {40, :WORK_IOS}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:ANDROID) do
          true
        end,
        def has_constant?(:IOS) do
          true
        end,
        def has_constant?(:WINDOWS_PHONE) do
          true
        end,
        def has_constant?(:BLACKBERRY) do
          true
        end,
        def has_constant?(:BLACKBERRYX) do
          true
        end,
        def has_constant?(:S40) do
          true
        end,
        def has_constant?(:S60) do
          true
        end,
        def has_constant?(:PYTHON_CLIENT) do
          true
        end,
        def has_constant?(:TIZEN) do
          true
        end,
        def has_constant?(:ENTERPRISE) do
          true
        end,
        def has_constant?(:SMB_ANDROID) do
          true
        end,
        def has_constant?(:KAIOS) do
          true
        end,
        def has_constant?(:SMB_IOS) do
          true
        end,
        def has_constant?(:WINDOWS) do
          true
        end,
        def has_constant?(:WEB) do
          true
        end,
        def has_constant?(:PORTAL) do
          true
        end,
        def has_constant?(:GREEN_ANDROID) do
          true
        end,
        def has_constant?(:GREEN_IPHONE) do
          true
        end,
        def has_constant?(:BLUE_ANDROID) do
          true
        end,
        def has_constant?(:BLUE_IPHONE) do
          true
        end,
        def has_constant?(:FBLITE_ANDROID) do
          true
        end,
        def has_constant?(:MLITE_ANDROID) do
          true
        end,
        def has_constant?(:IGLITE_ANDROID) do
          true
        end,
        def has_constant?(:PAGE) do
          true
        end,
        def has_constant?(:MACOS) do
          true
        end,
        def has_constant?(:OCULUS_MSG) do
          true
        end,
        def has_constant?(:OCULUS_CALL) do
          true
        end,
        def has_constant?(:MILAN) do
          true
        end,
        def has_constant?(:CAPI) do
          true
        end,
        def has_constant?(:WEAROS) do
          true
        end,
        def has_constant?(:ARDEVICE) do
          true
        end,
        def has_constant?(:VRDEVICE) do
          true
        end,
        def has_constant?(:BLUE_WEB) do
          true
        end,
        def has_constant?(:IPAD) do
          true
        end,
        def has_constant?(:TEST) do
          true
        end,
        def has_constant?(:SMART_GLASSES) do
          true
        end,
        def has_constant?(:BLUE_VR) do
          true
        end,
        def has_constant?(:AR_WRIST) do
          true
        end,
        def has_constant?(:WAIL) do
          true
        end,
        def has_constant?(:WORK_ANDROID) do
          true
        end,
        def has_constant?(:WORK_IOS) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
