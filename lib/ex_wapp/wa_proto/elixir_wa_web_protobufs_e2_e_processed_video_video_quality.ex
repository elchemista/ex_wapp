# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ProcessedVideo.VideoQuality do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNDEFINED
      def default() do
        :UNDEFINED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNDEFINED) do
          0
        end

        def encode("UNDEFINED") do
          0
        end
      ),
      (
        def encode(:LOW) do
          1
        end

        def encode("LOW") do
          1
        end
      ),
      (
        def encode(:MID) do
          2
        end

        def encode("MID") do
          2
        end
      ),
      (
        def encode(:HIGH) do
          3
        end

        def encode("HIGH") do
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
        :UNDEFINED
      end,
      def decode(1) do
        :LOW
      end,
      def decode(2) do
        :MID
      end,
      def decode(3) do
        :HIGH
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNDEFINED}, {1, :LOW}, {2, :MID}, {3, :HIGH}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNDEFINED) do
          true
        end,
        def has_constant?(:LOW) do
          true
        end,
        def has_constant?(:MID) do
          true
        end,
        def has_constant?(:HIGH) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
