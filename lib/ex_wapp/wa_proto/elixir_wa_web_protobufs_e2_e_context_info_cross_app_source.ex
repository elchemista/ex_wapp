# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ContextInfo.CrossAppSource do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :CROSS_APP_SOURCE_UNKNOWN
      def default() do
        :CROSS_APP_SOURCE_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:CROSS_APP_SOURCE_UNKNOWN) do
          0
        end

        def encode("CROSS_APP_SOURCE_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:CROSS_APP_SOURCE_INSTAGRAM) do
          1
        end

        def encode("CROSS_APP_SOURCE_INSTAGRAM") do
          1
        end
      ),
      (
        def encode(:CROSS_APP_SOURCE_FACEBOOK) do
          2
        end

        def encode("CROSS_APP_SOURCE_FACEBOOK") do
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
        :CROSS_APP_SOURCE_UNKNOWN
      end,
      def decode(1) do
        :CROSS_APP_SOURCE_INSTAGRAM
      end,
      def decode(2) do
        :CROSS_APP_SOURCE_FACEBOOK
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :CROSS_APP_SOURCE_UNKNOWN},
        {1, :CROSS_APP_SOURCE_INSTAGRAM},
        {2, :CROSS_APP_SOURCE_FACEBOOK}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:CROSS_APP_SOURCE_UNKNOWN) do
          true
        end,
        def has_constant?(:CROSS_APP_SOURCE_INSTAGRAM) do
          true
        end,
        def has_constant?(:CROSS_APP_SOURCE_FACEBOOK) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
