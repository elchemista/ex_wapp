# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.UserAgent.ReleaseChannel do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :RELEASE
      def default() do
        :RELEASE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:RELEASE) do
          0
        end

        def encode("RELEASE") do
          0
        end
      ),
      (
        def encode(:BETA) do
          1
        end

        def encode("BETA") do
          1
        end
      ),
      (
        def encode(:ALPHA) do
          2
        end

        def encode("ALPHA") do
          2
        end
      ),
      (
        def encode(:DEBUG) do
          3
        end

        def encode("DEBUG") do
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
        :RELEASE
      end,
      def decode(1) do
        :BETA
      end,
      def decode(2) do
        :ALPHA
      end,
      def decode(3) do
        :DEBUG
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :RELEASE}, {1, :BETA}, {2, :ALPHA}, {3, :DEBUG}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:RELEASE) do
          true
        end,
        def has_constant?(:BETA) do
          true
        end,
        def has_constant?(:ALPHA) do
          true
        end,
        def has_constant?(:DEBUG) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
