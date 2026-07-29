# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotPluginMetadata.PluginType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN_PLUGIN
      def default() do
        :UNKNOWN_PLUGIN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN_PLUGIN) do
          0
        end

        def encode("UNKNOWN_PLUGIN") do
          0
        end
      ),
      (
        def encode(:REELS) do
          1
        end

        def encode("REELS") do
          1
        end
      ),
      (
        def encode(:SEARCH) do
          2
        end

        def encode("SEARCH") do
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
        :UNKNOWN_PLUGIN
      end,
      def decode(1) do
        :REELS
      end,
      def decode(2) do
        :SEARCH
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN_PLUGIN}, {1, :REELS}, {2, :SEARCH}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN_PLUGIN) do
          true
        end,
        def has_constant?(:REELS) do
          true
        end,
        def has_constant?(:SEARCH) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
