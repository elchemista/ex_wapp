# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.UserAgent.DistributionChannel do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :APPSTORE
      def default() do
        :APPSTORE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:APPSTORE) do
          0
        end

        def encode("APPSTORE") do
          0
        end
      ),
      (
        def encode(:WEBSITE) do
          1
        end

        def encode("WEBSITE") do
          1
        end
      ),
      (
        def encode(:TESTFLIGHT) do
          2
        end

        def encode("TESTFLIGHT") do
          2
        end
      ),
      (
        def encode(:INTERNAL) do
          3
        end

        def encode("INTERNAL") do
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
        :APPSTORE
      end,
      def decode(1) do
        :WEBSITE
      end,
      def decode(2) do
        :TESTFLIGHT
      end,
      def decode(3) do
        :INTERNAL
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :APPSTORE}, {1, :WEBSITE}, {2, :TESTFLIGHT}, {3, :INTERNAL}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:APPSTORE) do
          true
        end,
        def has_constant?(:WEBSITE) do
          true
        end,
        def has_constant?(:TESTFLIGHT) do
          true
        end,
        def has_constant?(:INTERNAL) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
