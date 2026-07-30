# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.PrivateProcessingSettingAction.PrivateProcessingStatus do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNDEFINED
      def default() do
        :UNDEFINED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNDEFINED) do
          0
        end

        def encode("UNDEFINED") do
          0
        end
      ),
      (
        def encode(:ENABLED) do
          1
        end

        def encode("ENABLED") do
          1
        end
      ),
      (
        def encode(:DISABLED) do
          2
        end

        def encode("DISABLED") do
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
        :UNDEFINED
      end,
      def decode(1) do
        :ENABLED
      end,
      def decode(2) do
        :DISABLED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNDEFINED}, {1, :ENABLED}, {2, :DISABLED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNDEFINED) do
          true
        end,
        def has_constant?(:ENABLED) do
          true
        end,
        def has_constant?(:DISABLED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
