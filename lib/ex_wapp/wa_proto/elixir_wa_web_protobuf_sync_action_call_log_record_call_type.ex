# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.CallLogRecord.CallType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :REGULAR
      def default() do
        :REGULAR
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:REGULAR) do
          0
        end

        def encode("REGULAR") do
          0
        end
      ),
      (
        def encode(:SCHEDULED_CALL) do
          1
        end

        def encode("SCHEDULED_CALL") do
          1
        end
      ),
      (
        def encode(:VOICE_CHAT) do
          2
        end

        def encode("VOICE_CHAT") do
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
        :REGULAR
      end,
      def decode(1) do
        :SCHEDULED_CALL
      end,
      def decode(2) do
        :VOICE_CHAT
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :REGULAR}, {1, :SCHEDULED_CALL}, {2, :VOICE_CHAT}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:REGULAR) do
          true
        end,
        def has_constant?(:SCHEDULED_CALL) do
          true
        end,
        def has_constant?(:VOICE_CHAT) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
