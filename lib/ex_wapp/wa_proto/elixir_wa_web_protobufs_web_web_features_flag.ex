# credo:disable-for-this-file
defmodule WAWebProtobufsWeb.WebFeatures.Flag do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :NOT_STARTED
      def default() do
        :NOT_STARTED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:NOT_STARTED) do
          0
        end

        def encode("NOT_STARTED") do
          0
        end
      ),
      (
        def encode(:FORCE_UPGRADE) do
          1
        end

        def encode("FORCE_UPGRADE") do
          1
        end
      ),
      (
        def encode(:DEVELOPMENT) do
          2
        end

        def encode("DEVELOPMENT") do
          2
        end
      ),
      (
        def encode(:PRODUCTION) do
          3
        end

        def encode("PRODUCTION") do
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
        :NOT_STARTED
      end,
      def decode(1) do
        :FORCE_UPGRADE
      end,
      def decode(2) do
        :DEVELOPMENT
      end,
      def decode(3) do
        :PRODUCTION
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :NOT_STARTED}, {1, :FORCE_UPGRADE}, {2, :DEVELOPMENT}, {3, :PRODUCTION}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NOT_STARTED) do
          true
        end,
        def has_constant?(:FORCE_UPGRADE) do
          true
        end,
        def has_constant?(:DEVELOPMENT) do
          true
        end,
        def has_constant?(:PRODUCTION) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
