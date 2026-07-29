# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ContextInfo.DataSharingContext.DataSharingFlags do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :SHOW_MM_DISCLOSURE_ON_CLICK
      def default() do
        :SHOW_MM_DISCLOSURE_ON_CLICK
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:SHOW_MM_DISCLOSURE_ON_CLICK) do
          1
        end

        def encode("SHOW_MM_DISCLOSURE_ON_CLICK") do
          1
        end
      ),
      (
        def encode(:SHOW_MM_DISCLOSURE_ON_READ) do
          2
        end

        def encode("SHOW_MM_DISCLOSURE_ON_READ") do
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
        :SHOW_MM_DISCLOSURE_ON_CLICK
      end,
      def decode(2) do
        :SHOW_MM_DISCLOSURE_ON_READ
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :SHOW_MM_DISCLOSURE_ON_CLICK}, {2, :SHOW_MM_DISCLOSURE_ON_READ}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:SHOW_MM_DISCLOSURE_ON_CLICK) do
          true
        end,
        def has_constant?(:SHOW_MM_DISCLOSURE_ON_READ) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
