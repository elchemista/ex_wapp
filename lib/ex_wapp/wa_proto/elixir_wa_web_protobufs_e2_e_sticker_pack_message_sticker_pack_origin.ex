# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.StickerPackMessage.StickerPackOrigin do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :FIRST_PARTY
      def default() do
        :FIRST_PARTY
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:FIRST_PARTY) do
          0
        end

        def encode("FIRST_PARTY") do
          0
        end
      ),
      (
        def encode(:THIRD_PARTY) do
          1
        end

        def encode("THIRD_PARTY") do
          1
        end
      ),
      (
        def encode(:USER_CREATED) do
          2
        end

        def encode("USER_CREATED") do
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
        :FIRST_PARTY
      end,
      def decode(1) do
        :THIRD_PARTY
      end,
      def decode(2) do
        :USER_CREATED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :FIRST_PARTY}, {1, :THIRD_PARTY}, {2, :USER_CREATED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:FIRST_PARTY) do
          true
        end,
        def has_constant?(:THIRD_PARTY) do
          true
        end,
        def has_constant?(:USER_CREATED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
