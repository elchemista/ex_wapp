# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.MaibaAIFeaturesControlAction.MaibaAIFeatureStatus do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :ENABLED
      def default() do
        :ENABLED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:ENABLED) do
          0
        end

        def encode("ENABLED") do
          0
        end
      ),
      (
        def encode(:ENABLED_HAS_LEARNING) do
          1
        end

        def encode("ENABLED_HAS_LEARNING") do
          1
        end
      ),
      (
        def encode(:DISABLED) do
          2
        end

        def encode("DISABLED") do
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
        :ENABLED
      end,
      def decode(1) do
        :ENABLED_HAS_LEARNING
      end,
      def decode(2) do
        :DISABLED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :ENABLED}, {1, :ENABLED_HAS_LEARNING}, {2, :DISABLED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:ENABLED) do
          true
        end,
        def has_constant?(:ENABLED_HAS_LEARNING) do
          true
        end,
        def has_constant?(:DISABLED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
