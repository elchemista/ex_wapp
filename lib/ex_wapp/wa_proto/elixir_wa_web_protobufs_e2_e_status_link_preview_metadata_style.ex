# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.StatusLinkPreviewMetadata.Style do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :AUTO
      def default() do
        :AUTO
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:AUTO) do
          0
        end

        def encode("AUTO") do
          0
        end
      ),
      (
        def encode(:COMPACT) do
          1
        end

        def encode("COMPACT") do
          1
        end
      ),
      (
        def encode(:FULL) do
          2
        end

        def encode("FULL") do
          2
        end
      ),
      (
        def encode(:IMMERSIVE) do
          3
        end

        def encode("IMMERSIVE") do
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
        :AUTO
      end,
      def decode(1) do
        :COMPACT
      end,
      def decode(2) do
        :FULL
      end,
      def decode(3) do
        :IMMERSIVE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :AUTO}, {1, :COMPACT}, {2, :FULL}, {3, :IMMERSIVE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:AUTO) do
          true
        end,
        def has_constant?(:COMPACT) do
          true
        end,
        def has_constant?(:FULL) do
          true
        end,
        def has_constant?(:IMMERSIVE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
