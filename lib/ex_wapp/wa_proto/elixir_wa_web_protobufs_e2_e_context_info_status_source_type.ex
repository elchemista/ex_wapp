# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ContextInfo.StatusSourceType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :IMAGE
      def default() do
        :IMAGE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:IMAGE) do
          0
        end

        def encode("IMAGE") do
          0
        end
      ),
      (
        def encode(:VIDEO) do
          1
        end

        def encode("VIDEO") do
          1
        end
      ),
      (
        def encode(:GIF) do
          2
        end

        def encode("GIF") do
          2
        end
      ),
      (
        def encode(:AUDIO) do
          3
        end

        def encode("AUDIO") do
          3
        end
      ),
      (
        def encode(:TEXT) do
          4
        end

        def encode("TEXT") do
          4
        end
      ),
      (
        def encode(:MUSIC_STANDALONE) do
          5
        end

        def encode("MUSIC_STANDALONE") do
          5
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :IMAGE
      end,
      def decode(1) do
        :VIDEO
      end,
      def decode(2) do
        :GIF
      end,
      def decode(3) do
        :AUDIO
      end,
      def decode(4) do
        :TEXT
      end,
      def decode(5) do
        :MUSIC_STANDALONE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :IMAGE}, {1, :VIDEO}, {2, :GIF}, {3, :AUDIO}, {4, :TEXT}, {5, :MUSIC_STANDALONE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:IMAGE) do
          true
        end,
        def has_constant?(:VIDEO) do
          true
        end,
        def has_constant?(:GIF) do
          true
        end,
        def has_constant?(:AUDIO) do
          true
        end,
        def has_constant?(:TEXT) do
          true
        end,
        def has_constant?(:MUSIC_STANDALONE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
