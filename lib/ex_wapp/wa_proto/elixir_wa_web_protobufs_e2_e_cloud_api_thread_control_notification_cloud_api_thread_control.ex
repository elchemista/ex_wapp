# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.CloudAPIThreadControlNotification.CloudAPIThreadControl do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN
      def default() do
        :UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN) do
          0
        end

        def encode("UNKNOWN") do
          0
        end
      ),
      (
        def encode(:CONTROL_PASSED) do
          1
        end

        def encode("CONTROL_PASSED") do
          1
        end
      ),
      (
        def encode(:CONTROL_TAKEN) do
          2
        end

        def encode("CONTROL_TAKEN") do
          2
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :UNKNOWN
      end,
      def decode(1) do
        :CONTROL_PASSED
      end,
      def decode(2) do
        :CONTROL_TAKEN
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN}, {1, :CONTROL_PASSED}, {2, :CONTROL_TAKEN}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:CONTROL_PASSED) do
          true
        end,
        def has_constant?(:CONTROL_TAKEN) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
