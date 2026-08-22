# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotSignatureVerificationUseCaseProof.BotSignatureUseCase do
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
        def encode(:WA_BOT_MSG) do
          1
        end

        def encode("WA_BOT_MSG") do
          1
        end
      ),
      (
        def encode(:WA_TEE_BOT_MSG) do
          2
        end

        def encode("WA_TEE_BOT_MSG") do
          2
        end
      ),
      (
        def encode(:P2P_PILLS) do
          3
        end

        def encode("P2P_PILLS") do
          3
        end
      ),
      (
        def encode(:WA_WAFFLE) do
          4
        end

        def encode("WA_WAFFLE") do
          4
        end
      ),
      (
        def encode(:WA_FEATURE_PKI) do
          5
        end

        def encode("WA_FEATURE_PKI") do
          5
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
        :WA_BOT_MSG
      end,
      def decode(2) do
        :WA_TEE_BOT_MSG
      end,
      def decode(3) do
        :P2P_PILLS
      end,
      def decode(4) do
        :WA_WAFFLE
      end,
      def decode(5) do
        :WA_FEATURE_PKI
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNSPECIFIED},
        {1, :WA_BOT_MSG},
        {2, :WA_TEE_BOT_MSG},
        {3, :P2P_PILLS},
        {4, :WA_WAFFLE},
        {5, :WA_FEATURE_PKI}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNSPECIFIED) do
          true
        end,
        def has_constant?(:WA_BOT_MSG) do
          true
        end,
        def has_constant?(:WA_TEE_BOT_MSG) do
          true
        end,
        def has_constant?(:P2P_PILLS) do
          true
        end,
        def has_constant?(:WA_WAFFLE) do
          true
        end,
        def has_constant?(:WA_FEATURE_PKI) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
