# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.InteractiveMessage.CarouselMessage.CarouselCardType do
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
        def encode(:HSCROLL_CARDS) do
          1
        end

        def encode("HSCROLL_CARDS") do
          1
        end
      ),
      (
        def encode(:ALBUM_IMAGE) do
          2
        end

        def encode("ALBUM_IMAGE") do
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
        :HSCROLL_CARDS
      end,
      def decode(2) do
        :ALBUM_IMAGE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN}, {1, :HSCROLL_CARDS}, {2, :ALBUM_IMAGE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:HSCROLL_CARDS) do
          true
        end,
        def has_constant?(:ALBUM_IMAGE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
