# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.HydratedTemplateButton.HydratedURLButton.WebviewPresentationType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :FULL
      def default() do
        :FULL
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:FULL) do
          1
        end

        def encode("FULL") do
          1
        end
      ),
      (
        def encode(:TALL) do
          2
        end

        def encode("TALL") do
          2
        end
      ),
      (
        def encode(:COMPACT) do
          3
        end

        def encode("COMPACT") do
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
        :FULL
      end,
      def decode(2) do
        :TALL
      end,
      def decode(3) do
        :COMPACT
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :FULL}, {2, :TALL}, {3, :COMPACT}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:FULL) do
          true
        end,
        def has_constant?(:TALL) do
          true
        end,
        def has_constant?(:COMPACT) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
