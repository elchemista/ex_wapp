# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo.ContentType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UPDATE
      def default() do
        :UPDATE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UPDATE) do
          1
        end

        def encode("UPDATE") do
          1
        end
      ),
      (
        def encode(:UPDATE_CARD) do
          2
        end

        def encode("UPDATE_CARD") do
          2
        end
      ),
      (
        def encode(:LINK_CARD) do
          3
        end

        def encode("LINK_CARD") do
          3
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :UPDATE
      end,
      def decode(2) do
        :UPDATE_CARD
      end,
      def decode(3) do
        :LINK_CARD
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :UPDATE}, {2, :UPDATE_CARD}, {3, :LINK_CARD}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UPDATE) do
          true
        end,
        def has_constant?(:UPDATE_CARD) do
          true
        end,
        def has_constant?(:LINK_CARD) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
