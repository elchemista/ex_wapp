# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ButtonsMessage.HeaderType do
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
        def encode(:EMPTY) do
          1
        end

        def encode("EMPTY") do
          1
        end
      ),
      (
        def encode(:TEXT) do
          2
        end

        def encode("TEXT") do
          2
        end
      ),
      (
        def encode(:DOCUMENT) do
          3
        end

        def encode("DOCUMENT") do
          3
        end
      ),
      (
        def encode(:IMAGE) do
          4
        end

        def encode("IMAGE") do
          4
        end
      ),
      (
        def encode(:VIDEO) do
          5
        end

        def encode("VIDEO") do
          5
        end
      ),
      (
        def encode(:LOCATION) do
          6
        end

        def encode("LOCATION") do
          6
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
        :EMPTY
      end,
      def decode(2) do
        :TEXT
      end,
      def decode(3) do
        :DOCUMENT
      end,
      def decode(4) do
        :IMAGE
      end,
      def decode(5) do
        :VIDEO
      end,
      def decode(6) do
        :LOCATION
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :EMPTY},
        {2, :TEXT},
        {3, :DOCUMENT},
        {4, :IMAGE},
        {5, :VIDEO},
        {6, :LOCATION}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:EMPTY) do
          true
        end,
        def has_constant?(:TEXT) do
          true
        end,
        def has_constant?(:DOCUMENT) do
          true
        end,
        def has_constant?(:IMAGE) do
          true
        end,
        def has_constant?(:VIDEO) do
          true
        end,
        def has_constant?(:LOCATION) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
