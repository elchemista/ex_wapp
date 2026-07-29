# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ImageMessage.ImageSourceType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :USER_IMAGE
      def default() do
        :USER_IMAGE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:USER_IMAGE) do
          0
        end

        def encode("USER_IMAGE") do
          0
        end
      ),
      (
        def encode(:AI_GENERATED) do
          1
        end

        def encode("AI_GENERATED") do
          1
        end
      ),
      (
        def encode(:AI_MODIFIED) do
          2
        end

        def encode("AI_MODIFIED") do
          2
        end
      ),
      (
        def encode(:RASTERIZED_TEXT_STATUS) do
          3
        end

        def encode("RASTERIZED_TEXT_STATUS") do
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
        :USER_IMAGE
      end,
      def decode(1) do
        :AI_GENERATED
      end,
      def decode(2) do
        :AI_MODIFIED
      end,
      def decode(3) do
        :RASTERIZED_TEXT_STATUS
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :USER_IMAGE}, {1, :AI_GENERATED}, {2, :AI_MODIFIED}, {3, :RASTERIZED_TEXT_STATUS}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:USER_IMAGE) do
          true
        end,
        def has_constant?(:AI_GENERATED) do
          true
        end,
        def has_constant?(:AI_MODIFIED) do
          true
        end,
        def has_constant?(:RASTERIZED_TEXT_STATUS) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
