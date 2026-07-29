# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotReminderMetadata.ReminderAction do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :NOTIFY
      def default() do
        :NOTIFY
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:NOTIFY) do
          1
        end

        def encode("NOTIFY") do
          1
        end
      ),
      (
        def encode(:CREATE) do
          2
        end

        def encode("CREATE") do
          2
        end
      ),
      (
        def encode(:DELETE) do
          3
        end

        def encode("DELETE") do
          3
        end
      ),
      (
        def encode(:UPDATE) do
          4
        end

        def encode("UPDATE") do
          4
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :NOTIFY
      end,
      def decode(2) do
        :CREATE
      end,
      def decode(3) do
        :DELETE
      end,
      def decode(4) do
        :UPDATE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :NOTIFY}, {2, :CREATE}, {3, :DELETE}, {4, :UPDATE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NOTIFY) do
          true
        end,
        def has_constant?(:CREATE) do
          true
        end,
        def has_constant?(:DELETE) do
          true
        end,
        def has_constant?(:UPDATE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
