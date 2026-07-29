# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FullHistorySyncOnDemandResponseCode do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :REQUEST_SUCCESS
      def default() do
        :REQUEST_SUCCESS
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:REQUEST_SUCCESS) do
          0
        end

        def encode("REQUEST_SUCCESS") do
          0
        end
      ),
      (
        def encode(:REQUEST_TIME_EXPIRED) do
          1
        end

        def encode("REQUEST_TIME_EXPIRED") do
          1
        end
      ),
      (
        def encode(:DECLINED_SHARING_HISTORY) do
          2
        end

        def encode("DECLINED_SHARING_HISTORY") do
          2
        end
      ),
      (
        def encode(:GENERIC_ERROR) do
          3
        end

        def encode("GENERIC_ERROR") do
          3
        end
      ),
      (
        def encode(:ERROR_REQUEST_ON_NON_SMB_PRIMARY) do
          4
        end

        def encode("ERROR_REQUEST_ON_NON_SMB_PRIMARY") do
          4
        end
      ),
      (
        def encode(:ERROR_HOSTED_DEVICE_NOT_CONNECTED) do
          5
        end

        def encode("ERROR_HOSTED_DEVICE_NOT_CONNECTED") do
          5
        end
      ),
      (
        def encode(:ERROR_HOSTED_DEVICE_LOGIN_TIME_NOT_SET) do
          6
        end

        def encode("ERROR_HOSTED_DEVICE_LOGIN_TIME_NOT_SET") do
          6
        end
      ),
      (
        def encode(:ERROR_MULTI_PROVIDER_NOT_CONFIGURED) do
          7
        end

        def encode("ERROR_MULTI_PROVIDER_NOT_CONFIGURED") do
          7
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :REQUEST_SUCCESS
      end,
      def decode(1) do
        :REQUEST_TIME_EXPIRED
      end,
      def decode(2) do
        :DECLINED_SHARING_HISTORY
      end,
      def decode(3) do
        :GENERIC_ERROR
      end,
      def decode(4) do
        :ERROR_REQUEST_ON_NON_SMB_PRIMARY
      end,
      def decode(5) do
        :ERROR_HOSTED_DEVICE_NOT_CONNECTED
      end,
      def decode(6) do
        :ERROR_HOSTED_DEVICE_LOGIN_TIME_NOT_SET
      end,
      def decode(7) do
        :ERROR_MULTI_PROVIDER_NOT_CONFIGURED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :REQUEST_SUCCESS},
        {1, :REQUEST_TIME_EXPIRED},
        {2, :DECLINED_SHARING_HISTORY},
        {3, :GENERIC_ERROR},
        {4, :ERROR_REQUEST_ON_NON_SMB_PRIMARY},
        {5, :ERROR_HOSTED_DEVICE_NOT_CONNECTED},
        {6, :ERROR_HOSTED_DEVICE_LOGIN_TIME_NOT_SET},
        {7, :ERROR_MULTI_PROVIDER_NOT_CONFIGURED}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:REQUEST_SUCCESS) do
          true
        end,
        def has_constant?(:REQUEST_TIME_EXPIRED) do
          true
        end,
        def has_constant?(:DECLINED_SHARING_HISTORY) do
          true
        end,
        def has_constant?(:GENERIC_ERROR) do
          true
        end,
        def has_constant?(:ERROR_REQUEST_ON_NON_SMB_PRIMARY) do
          true
        end,
        def has_constant?(:ERROR_HOSTED_DEVICE_NOT_CONNECTED) do
          true
        end,
        def has_constant?(:ERROR_HOSTED_DEVICE_LOGIN_TIME_NOT_SET) do
          true
        end,
        def has_constant?(:ERROR_MULTI_PROVIDER_NOT_CONFIGURED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
