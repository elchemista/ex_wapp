# credo:disable-for-this-file
defmodule WAWebProtobufsWeb.GroupHistoryBundleInfo.ProcessState do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :NOT_INJECTED
      def default() do
        :NOT_INJECTED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:NOT_INJECTED) do
          0
        end

        def encode("NOT_INJECTED") do
          0
        end
      ),
      (
        def encode(:INJECTED) do
          1
        end

        def encode("INJECTED") do
          1
        end
      ),
      (
        def encode(:INJECTED_PARTIAL) do
          2
        end

        def encode("INJECTED_PARTIAL") do
          2
        end
      ),
      (
        def encode(:INJECTION_FAILED) do
          3
        end

        def encode("INJECTION_FAILED") do
          3
        end
      ),
      (
        def encode(:INJECTION_FAILED_NO_RETRY) do
          4
        end

        def encode("INJECTION_FAILED_NO_RETRY") do
          4
        end
      ),
      (
        def encode(:DEDUPED) do
          5
        end

        def encode("DEDUPED") do
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
        :NOT_INJECTED
      end,
      def decode(1) do
        :INJECTED
      end,
      def decode(2) do
        :INJECTED_PARTIAL
      end,
      def decode(3) do
        :INJECTION_FAILED
      end,
      def decode(4) do
        :INJECTION_FAILED_NO_RETRY
      end,
      def decode(5) do
        :DEDUPED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :NOT_INJECTED},
        {1, :INJECTED},
        {2, :INJECTED_PARTIAL},
        {3, :INJECTION_FAILED},
        {4, :INJECTION_FAILED_NO_RETRY},
        {5, :DEDUPED}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NOT_INJECTED) do
          true
        end,
        def has_constant?(:INJECTED) do
          true
        end,
        def has_constant?(:INJECTED_PARTIAL) do
          true
        end,
        def has_constant?(:INJECTION_FAILED) do
          true
        end,
        def has_constant?(:INJECTION_FAILED_NO_RETRY) do
          true
        end,
        def has_constant?(:DEDUPED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
