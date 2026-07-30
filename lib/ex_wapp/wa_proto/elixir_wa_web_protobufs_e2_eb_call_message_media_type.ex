# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.BCallMessage.MediaType do
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
        def encode(:AUDIO) do
          1
        end

        def encode("AUDIO") do
          1
        end
      ),
      (
        def encode(:VIDEO) do
          2
        end

        def encode("VIDEO") do
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
        :UNKNOWN
      end,
      def decode(1) do
        :AUDIO
      end,
      def decode(2) do
        :VIDEO
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN}, {1, :AUDIO}, {2, :VIDEO}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:AUDIO) do
          true
        end,
        def has_constant?(:VIDEO) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
