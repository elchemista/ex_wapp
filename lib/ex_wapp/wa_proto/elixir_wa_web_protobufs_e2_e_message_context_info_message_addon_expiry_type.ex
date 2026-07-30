# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.MessageContextInfo.MessageAddonExpiryType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :STATIC
      def default() do
        :STATIC
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:STATIC) do
          1
        end

        def encode("STATIC") do
          1
        end
      ),
      (
        def encode(:DEPENDENT_ON_PARENT) do
          2
        end

        def encode("DEPENDENT_ON_PARENT") do
          2
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :STATIC
      end,
      def decode(2) do
        :DEPENDENT_ON_PARENT
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :STATIC}, {2, :DEPENDENT_ON_PARENT}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:STATIC) do
          true
        end,
        def has_constant?(:DEPENDENT_ON_PARENT) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
