# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :DEFAULT
      def default() do
        :DEFAULT
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:DEFAULT) do
          0
        end

        def encode("DEFAULT") do
          0
        end
      ),
      (
        def encode(:PARENT) do
          1
        end

        def encode("PARENT") do
          1
        end
      ),
      (
        def encode(:SUB) do
          2
        end

        def encode("SUB") do
          2
        end
      ),
      (
        def encode(:DEFAULT_SUB) do
          3
        end

        def encode("DEFAULT_SUB") do
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
        :DEFAULT
      end,
      def decode(1) do
        :PARENT
      end,
      def decode(2) do
        :SUB
      end,
      def decode(3) do
        :DEFAULT_SUB
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :DEFAULT}, {1, :PARENT}, {2, :SUB}, {3, :DEFAULT_SUB}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:DEFAULT) do
          true
        end,
        def has_constant?(:PARENT) do
          true
        end,
        def has_constant?(:SUB) do
          true
        end,
        def has_constant?(:DEFAULT_SUB) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
