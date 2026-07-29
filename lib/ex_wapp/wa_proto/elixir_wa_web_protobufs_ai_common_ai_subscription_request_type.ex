# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.AISubscriptionRequestType do
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
        def encode(:THINK_HARD) do
          1
        end

        def encode("THINK_HARD") do
          1
        end
      ),
      (
        def encode(:IMAGE_GEN) do
          2
        end

        def encode("IMAGE_GEN") do
          2
        end
      ),
      (
        def encode(:VIDEO_GEN) do
          3
        end

        def encode("VIDEO_GEN") do
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
        :UNSPECIFIED
      end,
      def decode(1) do
        :THINK_HARD
      end,
      def decode(2) do
        :IMAGE_GEN
      end,
      def decode(3) do
        :VIDEO_GEN
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNSPECIFIED}, {1, :THINK_HARD}, {2, :IMAGE_GEN}, {3, :VIDEO_GEN}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNSPECIFIED) do
          true
        end,
        def has_constant?(:THINK_HARD) do
          true
        end,
        def has_constant?(:IMAGE_GEN) do
          true
        end,
        def has_constant?(:VIDEO_GEN) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
