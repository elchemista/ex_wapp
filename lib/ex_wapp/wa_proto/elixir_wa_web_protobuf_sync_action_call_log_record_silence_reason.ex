# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.CallLogRecord.SilenceReason do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :NONE
      def default() do
        :NONE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:NONE) do
          0
        end

        def encode("NONE") do
          0
        end
      ),
      (
        def encode(:SCHEDULED) do
          1
        end

        def encode("SCHEDULED") do
          1
        end
      ),
      (
        def encode(:PRIVACY) do
          2
        end

        def encode("PRIVACY") do
          2
        end
      ),
      (
        def encode(:LIGHTWEIGHT) do
          3
        end

        def encode("LIGHTWEIGHT") do
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
        :NONE
      end,
      def decode(1) do
        :SCHEDULED
      end,
      def decode(2) do
        :PRIVACY
      end,
      def decode(3) do
        :LIGHTWEIGHT
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :NONE}, {1, :SCHEDULED}, {2, :PRIVACY}, {3, :LIGHTWEIGHT}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NONE) do
          true
        end,
        def has_constant?(:SCHEDULED) do
          true
        end,
        def has_constant?(:PRIVACY) do
          true
        end,
        def has_constant?(:LIGHTWEIGHT) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
