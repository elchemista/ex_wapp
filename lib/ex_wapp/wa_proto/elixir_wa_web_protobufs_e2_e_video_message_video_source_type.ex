# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.VideoMessage.VideoSourceType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :USER_VIDEO
      def default() do
        :USER_VIDEO
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:USER_VIDEO) do
          0
        end

        def encode("USER_VIDEO") do
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
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :USER_VIDEO
      end,
      def decode(1) do
        :AI_GENERATED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :USER_VIDEO}, {1, :AI_GENERATED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:USER_VIDEO) do
          true
        end,
        def has_constant?(:AI_GENERATED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
