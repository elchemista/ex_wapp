# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.GroupInviteMessage.GroupType do
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
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :DEFAULT}, {1, :PARENT}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:DEFAULT) do
          true
        end,
        def has_constant?(:PARENT) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
