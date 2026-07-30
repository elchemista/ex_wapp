# credo:disable-for-this-file
defmodule WAWebProtobufsHistorySync.PrivacySystemMessage do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :E2EE_MSG
      def default() do
        :E2EE_MSG
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:E2EE_MSG) do
          1
        end

        def encode("E2EE_MSG") do
          1
        end
      ),
      (
        def encode(:NE2EE_SELF) do
          2
        end

        def encode("NE2EE_SELF") do
          2
        end
      ),
      (
        def encode(:NE2EE_OTHER) do
          3
        end

        def encode("NE2EE_OTHER") do
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
        :E2EE_MSG
      end,
      def decode(2) do
        :NE2EE_SELF
      end,
      def decode(3) do
        :NE2EE_OTHER
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :E2EE_MSG}, {2, :NE2EE_SELF}, {3, :NE2EE_OTHER}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:E2EE_MSG) do
          true
        end,
        def has_constant?(:NE2EE_SELF) do
          true
        end,
        def has_constant?(:NE2EE_OTHER) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
