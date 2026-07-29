# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.SessionTransparencyType do
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
        def encode(:NY_AI_SAFETY_DISCLAIMER) do
          1
        end

        def encode("NY_AI_SAFETY_DISCLAIMER") do
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
        :UNKNOWN_TYPE
      end,
      def decode(1) do
        :NY_AI_SAFETY_DISCLAIMER
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN_TYPE}, {1, :NY_AI_SAFETY_DISCLAIMER}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN_TYPE) do
          true
        end,
        def has_constant?(:NY_AI_SAFETY_DISCLAIMER) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
