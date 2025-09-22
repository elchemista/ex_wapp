# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.ConnectType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :CELLULAR_UNKNOWN
      def default() do
        :CELLULAR_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:CELLULAR_UNKNOWN) do
          0
        end

        def encode("CELLULAR_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:WIFI_UNKNOWN) do
          1
        end

        def encode("WIFI_UNKNOWN") do
          1
        end
      ),
      (
        def encode(:CELLULAR_EDGE) do
          100
        end

        def encode("CELLULAR_EDGE") do
          100
        end
      ),
      (
        def encode(:CELLULAR_IDEN) do
          101
        end

        def encode("CELLULAR_IDEN") do
          101
        end
      ),
      (
        def encode(:CELLULAR_UMTS) do
          102
        end

        def encode("CELLULAR_UMTS") do
          102
        end
      ),
      (
        def encode(:CELLULAR_EVDO) do
          103
        end

        def encode("CELLULAR_EVDO") do
          103
        end
      ),
      (
        def encode(:CELLULAR_GPRS) do
          104
        end

        def encode("CELLULAR_GPRS") do
          104
        end
      ),
      (
        def encode(:CELLULAR_HSDPA) do
          105
        end

        def encode("CELLULAR_HSDPA") do
          105
        end
      ),
      (
        def encode(:CELLULAR_HSUPA) do
          106
        end

        def encode("CELLULAR_HSUPA") do
          106
        end
      ),
      (
        def encode(:CELLULAR_HSPA) do
          107
        end

        def encode("CELLULAR_HSPA") do
          107
        end
      ),
      (
        def encode(:CELLULAR_CDMA) do
          108
        end

        def encode("CELLULAR_CDMA") do
          108
        end
      ),
      (
        def encode(:CELLULAR_1XRTT) do
          109
        end

        def encode("CELLULAR_1XRTT") do
          109
        end
      ),
      (
        def encode(:CELLULAR_EHRPD) do
          110
        end

        def encode("CELLULAR_EHRPD") do
          110
        end
      ),
      (
        def encode(:CELLULAR_LTE) do
          111
        end

        def encode("CELLULAR_LTE") do
          111
        end
      ),
      (
        def encode(:CELLULAR_HSPAP) do
          112
        end

        def encode("CELLULAR_HSPAP") do
          112
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :CELLULAR_UNKNOWN
      end,
      def decode(1) do
        :WIFI_UNKNOWN
      end,
      def decode(100) do
        :CELLULAR_EDGE
      end,
      def decode(101) do
        :CELLULAR_IDEN
      end,
      def decode(102) do
        :CELLULAR_UMTS
      end,
      def decode(103) do
        :CELLULAR_EVDO
      end,
      def decode(104) do
        :CELLULAR_GPRS
      end,
      def decode(105) do
        :CELLULAR_HSDPA
      end,
      def decode(106) do
        :CELLULAR_HSUPA
      end,
      def decode(107) do
        :CELLULAR_HSPA
      end,
      def decode(108) do
        :CELLULAR_CDMA
      end,
      def decode(109) do
        :CELLULAR_1XRTT
      end,
      def decode(110) do
        :CELLULAR_EHRPD
      end,
      def decode(111) do
        :CELLULAR_LTE
      end,
      def decode(112) do
        :CELLULAR_HSPAP
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :CELLULAR_UNKNOWN},
        {1, :WIFI_UNKNOWN},
        {100, :CELLULAR_EDGE},
        {101, :CELLULAR_IDEN},
        {102, :CELLULAR_UMTS},
        {103, :CELLULAR_EVDO},
        {104, :CELLULAR_GPRS},
        {105, :CELLULAR_HSDPA},
        {106, :CELLULAR_HSUPA},
        {107, :CELLULAR_HSPA},
        {108, :CELLULAR_CDMA},
        {109, :CELLULAR_1XRTT},
        {110, :CELLULAR_EHRPD},
        {111, :CELLULAR_LTE},
        {112, :CELLULAR_HSPAP}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:CELLULAR_UNKNOWN) do
          true
        end,
        def has_constant?(:WIFI_UNKNOWN) do
          true
        end,
        def has_constant?(:CELLULAR_EDGE) do
          true
        end,
        def has_constant?(:CELLULAR_IDEN) do
          true
        end,
        def has_constant?(:CELLULAR_UMTS) do
          true
        end,
        def has_constant?(:CELLULAR_EVDO) do
          true
        end,
        def has_constant?(:CELLULAR_GPRS) do
          true
        end,
        def has_constant?(:CELLULAR_HSDPA) do
          true
        end,
        def has_constant?(:CELLULAR_HSUPA) do
          true
        end,
        def has_constant?(:CELLULAR_HSPA) do
          true
        end,
        def has_constant?(:CELLULAR_CDMA) do
          true
        end,
        def has_constant?(:CELLULAR_1XRTT) do
          true
        end,
        def has_constant?(:CELLULAR_EHRPD) do
          true
        end,
        def has_constant?(:CELLULAR_LTE) do
          true
        end,
        def has_constant?(:CELLULAR_HSPAP) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
