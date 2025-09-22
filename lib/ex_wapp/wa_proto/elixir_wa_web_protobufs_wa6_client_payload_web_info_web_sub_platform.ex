# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.WebInfo.WebSubPlatform do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :WEB_BROWSER
      def default() do
        :WEB_BROWSER
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:WEB_BROWSER) do
          0
        end

        def encode("WEB_BROWSER") do
          0
        end
      ),
      (
        def encode(:APP_STORE) do
          1
        end

        def encode("APP_STORE") do
          1
        end
      ),
      (
        def encode(:WIN_STORE) do
          2
        end

        def encode("WIN_STORE") do
          2
        end
      ),
      (
        def encode(:DARWIN) do
          3
        end

        def encode("DARWIN") do
          3
        end
      ),
      (
        def encode(:WIN32) do
          4
        end

        def encode("WIN32") do
          4
        end
      ),
      (
        def encode(:WIN_HYBRID) do
          5
        end

        def encode("WIN_HYBRID") do
          5
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :WEB_BROWSER
      end,
      def decode(1) do
        :APP_STORE
      end,
      def decode(2) do
        :WIN_STORE
      end,
      def decode(3) do
        :DARWIN
      end,
      def decode(4) do
        :WIN32
      end,
      def decode(5) do
        :WIN_HYBRID
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :WEB_BROWSER},
        {1, :APP_STORE},
        {2, :WIN_STORE},
        {3, :DARWIN},
        {4, :WIN32},
        {5, :WIN_HYBRID}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:WEB_BROWSER) do
          true
        end,
        def has_constant?(:APP_STORE) do
          true
        end,
        def has_constant?(:WIN_STORE) do
          true
        end,
        def has_constant?(:DARWIN) do
          true
        end,
        def has_constant?(:WIN32) do
          true
        end,
        def has_constant?(:WIN_HYBRID) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
