# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.PlanningStepStatus do
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
        def encode(:PLANNED) do
          1
        end

        def encode("PLANNED") do
          1
        end
      ),
      (
        def encode(:EXECUTING) do
          2
        end

        def encode("EXECUTING") do
          2
        end
      ),
      (
        def encode(:FINISHED) do
          3
        end

        def encode("FINISHED") do
          3
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
        :PLANNED
      end,
      def decode(2) do
        :EXECUTING
      end,
      def decode(3) do
        :FINISHED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN}, {1, :PLANNED}, {2, :EXECUTING}, {3, :FINISHED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:PLANNED) do
          true
        end,
        def has_constant?(:EXECUTING) do
          true
        end,
        def has_constant?(:FINISHED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
