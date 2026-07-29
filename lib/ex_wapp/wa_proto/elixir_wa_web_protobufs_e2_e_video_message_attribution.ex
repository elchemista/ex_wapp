# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.VideoMessage.Attribution do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :NONE
      def default() do
        :NONE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:NONE) do
          0
        end

        def encode("NONE") do
          0
        end
      ),
      (
        def encode(:GIPHY) do
          1
        end

        def encode("GIPHY") do
          1
        end
      ),
      (
        def encode(:TENOR) do
          2
        end

        def encode("TENOR") do
          2
        end
      ),
      (
        def encode(:KLIPY) do
          3
        end

        def encode("KLIPY") do
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
        :NONE
      end,
      def decode(1) do
        :GIPHY
      end,
      def decode(2) do
        :TENOR
      end,
      def decode(3) do
        :KLIPY
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :NONE}, {1, :GIPHY}, {2, :TENOR}, {3, :KLIPY}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NONE) do
          true
        end,
        def has_constant?(:GIPHY) do
          true
        end,
        def has_constant?(:TENOR) do
          true
        end,
        def has_constant?(:KLIPY) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
