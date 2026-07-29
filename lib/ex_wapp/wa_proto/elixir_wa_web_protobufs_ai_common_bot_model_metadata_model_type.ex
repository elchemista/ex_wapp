# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotModelMetadata.ModelType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN_TYPE
      def default() do
        :UNKNOWN_TYPE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN_TYPE) do
          0
        end

        def encode("UNKNOWN_TYPE") do
          0
        end
      ),
      (
        def encode(:LLAMA_PROD) do
          1
        end

        def encode("LLAMA_PROD") do
          1
        end
      ),
      (
        def encode(:LLAMA_PROD_PREMIUM) do
          2
        end

        def encode("LLAMA_PROD_PREMIUM") do
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
        :UNKNOWN_TYPE
      end,
      def decode(1) do
        :LLAMA_PROD
      end,
      def decode(2) do
        :LLAMA_PROD_PREMIUM
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN_TYPE}, {1, :LLAMA_PROD}, {2, :LLAMA_PROD_PREMIUM}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN_TYPE) do
          true
        end,
        def has_constant?(:LLAMA_PROD) do
          true
        end,
        def has_constant?(:LLAMA_PROD_PREMIUM) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
