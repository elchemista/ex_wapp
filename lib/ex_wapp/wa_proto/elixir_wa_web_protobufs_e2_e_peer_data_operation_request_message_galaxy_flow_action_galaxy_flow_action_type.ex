# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PeerDataOperationRequestMessage.GalaxyFlowAction.GalaxyFlowActionType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :NOTIFY_LAUNCH
      def default() do
        :NOTIFY_LAUNCH
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:NOTIFY_LAUNCH) do
          1
        end

        def encode("NOTIFY_LAUNCH") do
          1
        end
      ),
      (
        def encode(:DOWNLOAD_RESPONSES) do
          2
        end

        def encode("DOWNLOAD_RESPONSES") do
          2
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :NOTIFY_LAUNCH
      end,
      def decode(2) do
        :DOWNLOAD_RESPONSES
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :NOTIFY_LAUNCH}, {2, :DOWNLOAD_RESPONSES}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NOTIFY_LAUNCH) do
          true
        end,
        def has_constant?(:DOWNLOAD_RESPONSES) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
