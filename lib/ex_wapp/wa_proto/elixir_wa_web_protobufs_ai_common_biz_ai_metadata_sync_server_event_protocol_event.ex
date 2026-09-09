# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BizAIMetadataSync.ServerEvent.ProtocolEvent do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNSPECIFIED
      def default() do
        :UNSPECIFIED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNSPECIFIED) do
          0
        end

        def encode("UNSPECIFIED") do
          0
        end
      ),
      (
        def encode(:AGENT_CHAT_READY) do
          1
        end

        def encode("AGENT_CHAT_READY") do
          1
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :UNSPECIFIED
      end,
      def decode(1) do
        :AGENT_CHAT_READY
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNSPECIFIED}, {1, :AGENT_CHAT_READY}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNSPECIFIED) do
          true
        end,
        def has_constant?(:AGENT_CHAT_READY) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
