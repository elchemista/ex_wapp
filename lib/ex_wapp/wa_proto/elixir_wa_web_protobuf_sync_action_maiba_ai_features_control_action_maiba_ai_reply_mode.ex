# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.MaibaAIFeaturesControlAction.MaibaAIReplyMode do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :MUTED
      def default() do
        :MUTED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:MUTED) do
          0
        end

        def encode("MUTED") do
          0
        end
      ),
      (
        def encode(:AI_AGENT) do
          1
        end

        def encode("AI_AGENT") do
          1
        end
      ),
      (
        def encode(:SUGGESTIONS) do
          2
        end

        def encode("SUGGESTIONS") do
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
        :MUTED
      end,
      def decode(1) do
        :AI_AGENT
      end,
      def decode(2) do
        :SUGGESTIONS
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :MUTED}, {1, :AI_AGENT}, {2, :SUGGESTIONS}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:MUTED) do
          true
        end,
        def has_constant?(:AI_AGENT) do
          true
        end,
        def has_constant?(:SUGGESTIONS) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
