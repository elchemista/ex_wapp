# credo:disable-for-this-file
defmodule WAStatusAttributions.StatusAttribution.ExternalShare.Source do
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
        def encode(:INSTAGRAM) do
          1
        end

        def encode("INSTAGRAM") do
          1
        end
      ),
      (
        def encode(:FACEBOOK) do
          2
        end

        def encode("FACEBOOK") do
          2
        end
      ),
      (
        def encode(:MESSENGER) do
          3
        end

        def encode("MESSENGER") do
          3
        end
      ),
      (
        def encode(:SPOTIFY) do
          4
        end

        def encode("SPOTIFY") do
          4
        end
      ),
      (
        def encode(:YOUTUBE) do
          5
        end

        def encode("YOUTUBE") do
          5
        end
      ),
      (
        def encode(:PINTEREST) do
          6
        end

        def encode("PINTEREST") do
          6
        end
      ),
      (
        def encode(:THREADS) do
          7
        end

        def encode("THREADS") do
          7
        end
      ),
      (
        def encode(:APPLE_MUSIC) do
          8
        end

        def encode("APPLE_MUSIC") do
          8
        end
      ),
      (
        def encode(:SHARECHAT) do
          9
        end

        def encode("SHARECHAT") do
          9
        end
      ),
      (
        def encode(:GOOGLE_PHOTOS) do
          10
        end

        def encode("GOOGLE_PHOTOS") do
          10
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
        :INSTAGRAM
      end,
      def decode(2) do
        :FACEBOOK
      end,
      def decode(3) do
        :MESSENGER
      end,
      def decode(4) do
        :SPOTIFY
      end,
      def decode(5) do
        :YOUTUBE
      end,
      def decode(6) do
        :PINTEREST
      end,
      def decode(7) do
        :THREADS
      end,
      def decode(8) do
        :APPLE_MUSIC
      end,
      def decode(9) do
        :SHARECHAT
      end,
      def decode(10) do
        :GOOGLE_PHOTOS
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :INSTAGRAM},
        {2, :FACEBOOK},
        {3, :MESSENGER},
        {4, :SPOTIFY},
        {5, :YOUTUBE},
        {6, :PINTEREST},
        {7, :THREADS},
        {8, :APPLE_MUSIC},
        {9, :SHARECHAT},
        {10, :GOOGLE_PHOTOS}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:INSTAGRAM) do
          true
        end,
        def has_constant?(:FACEBOOK) do
          true
        end,
        def has_constant?(:MESSENGER) do
          true
        end,
        def has_constant?(:SPOTIFY) do
          true
        end,
        def has_constant?(:YOUTUBE) do
          true
        end,
        def has_constant?(:PINTEREST) do
          true
        end,
        def has_constant?(:THREADS) do
          true
        end,
        def has_constant?(:APPLE_MUSIC) do
          true
        end,
        def has_constant?(:SHARECHAT) do
          true
        end,
        def has_constant?(:GOOGLE_PHOTOS) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
