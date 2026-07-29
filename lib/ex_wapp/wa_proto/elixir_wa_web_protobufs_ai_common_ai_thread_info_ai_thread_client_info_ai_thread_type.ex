# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.AIThreadInfo.AIThreadClientInfo.AIThreadType do
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
        def encode(:DEFAULT) do
          1
        end

        def encode("DEFAULT") do
          1
        end
      ),
      (
        def encode(:INCOGNITO) do
          2
        end

        def encode("INCOGNITO") do
          2
        end
      ),
      (
        def encode(:SIDE_CHAT) do
          3
        end

        def encode("SIDE_CHAT") do
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
        :DEFAULT
      end,
      def decode(2) do
        :INCOGNITO
      end,
      def decode(3) do
        :SIDE_CHAT
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN}, {1, :DEFAULT}, {2, :INCOGNITO}, {3, :SIDE_CHAT}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:DEFAULT) do
          true
        end,
        def has_constant?(:INCOGNITO) do
          true
        end,
        def has_constant?(:SIDE_CHAT) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
