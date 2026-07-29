# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.WebLinkRenderConfig do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :WEBVIEW
      def default() do
        :WEBVIEW
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:WEBVIEW) do
          0
        end

        def encode("WEBVIEW") do
          0
        end
      ),
      (
        def encode(:SYSTEM) do
          1
        end

        def encode("SYSTEM") do
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
        :WEBVIEW
      end,
      def decode(1) do
        :SYSTEM
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :WEBVIEW}, {1, :SYSTEM}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:WEBVIEW) do
          true
        end,
        def has_constant?(:SYSTEM) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
