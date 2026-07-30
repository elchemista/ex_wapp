# credo:disable-for-this-file
defmodule WAWebProtobufsWeb.WebMessageInfo.BizPrivacyStatus do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :E2EE
      def default() do
        :E2EE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:E2EE) do
          0
        end

        def encode("E2EE") do
          0
        end
      ),
      (
        def encode(:FB) do
          2
        end

        def encode("FB") do
          2
        end
      ),
      (
        def encode(:BSP) do
          1
        end

        def encode("BSP") do
          1
        end
      ),
      (
        def encode(:BSP_AND_FB) do
          3
        end

        def encode("BSP_AND_FB") do
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
        :E2EE
      end,
      def decode(1) do
        :BSP
      end,
      def decode(2) do
        :FB
      end,
      def decode(3) do
        :BSP_AND_FB
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :E2EE}, {2, :FB}, {1, :BSP}, {3, :BSP_AND_FB}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:E2EE) do
          true
        end,
        def has_constant?(:FB) do
          true
        end,
        def has_constant?(:BSP) do
          true
        end,
        def has_constant?(:BSP_AND_FB) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
