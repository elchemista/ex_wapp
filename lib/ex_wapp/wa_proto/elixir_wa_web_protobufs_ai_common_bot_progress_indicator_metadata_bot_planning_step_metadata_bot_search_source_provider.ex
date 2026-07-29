# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.BotSearchSourceProvider do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN_PROVIDER
      def default() do
        :UNKNOWN_PROVIDER
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN_PROVIDER) do
          0
        end

        def encode("UNKNOWN_PROVIDER") do
          0
        end
      ),
      (
        def encode(:OTHER) do
          1
        end

        def encode("OTHER") do
          1
        end
      ),
      (
        def encode(:GOOGLE) do
          2
        end

        def encode("GOOGLE") do
          2
        end
      ),
      (
        def encode(:BING) do
          3
        end

        def encode("BING") do
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
        :UNKNOWN_PROVIDER
      end,
      def decode(1) do
        :OTHER
      end,
      def decode(2) do
        :GOOGLE
      end,
      def decode(3) do
        :BING
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN_PROVIDER}, {1, :OTHER}, {2, :GOOGLE}, {3, :BING}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN_PROVIDER) do
          true
        end,
        def has_constant?(:OTHER) do
          true
        end,
        def has_constant?(:GOOGLE) do
          true
        end,
        def has_constant?(:BING) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
