# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ContextInfo.StatusAttributionType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :NONE
      def default() do
        :NONE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:NONE) do
          0
        end

        def encode("NONE") do
          0
        end
      ),
      (
        def encode(:RESHARED_FROM_MENTION) do
          1
        end

        def encode("RESHARED_FROM_MENTION") do
          1
        end
      ),
      (
        def encode(:RESHARED_FROM_POST) do
          2
        end

        def encode("RESHARED_FROM_POST") do
          2
        end
      ),
      (
        def encode(:RESHARED_FROM_POST_MANY_TIMES) do
          3
        end

        def encode("RESHARED_FROM_POST_MANY_TIMES") do
          3
        end
      ),
      (
        def encode(:FORWARDED_FROM_STATUS) do
          4
        end

        def encode("FORWARDED_FROM_STATUS") do
          4
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :NONE
      end,
      def decode(1) do
        :RESHARED_FROM_MENTION
      end,
      def decode(2) do
        :RESHARED_FROM_POST
      end,
      def decode(3) do
        :RESHARED_FROM_POST_MANY_TIMES
      end,
      def decode(4) do
        :FORWARDED_FROM_STATUS
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :NONE},
        {1, :RESHARED_FROM_MENTION},
        {2, :RESHARED_FROM_POST},
        {3, :RESHARED_FROM_POST_MANY_TIMES},
        {4, :FORWARDED_FROM_STATUS}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NONE) do
          true
        end,
        def has_constant?(:RESHARED_FROM_MENTION) do
          true
        end,
        def has_constant?(:RESHARED_FROM_POST) do
          true
        end,
        def has_constant?(:RESHARED_FROM_POST_MANY_TIMES) do
          true
        end,
        def has_constant?(:FORWARDED_FROM_STATUS) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
