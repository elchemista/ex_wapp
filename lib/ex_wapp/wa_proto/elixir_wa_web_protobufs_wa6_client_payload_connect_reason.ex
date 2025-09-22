# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.ConnectReason do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :PUSH
      def default() do
        :PUSH
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:PUSH) do
          0
        end

        def encode("PUSH") do
          0
        end
      ),
      (
        def encode(:USER_ACTIVATED) do
          1
        end

        def encode("USER_ACTIVATED") do
          1
        end
      ),
      (
        def encode(:SCHEDULED) do
          2
        end

        def encode("SCHEDULED") do
          2
        end
      ),
      (
        def encode(:ERROR_RECONNECT) do
          3
        end

        def encode("ERROR_RECONNECT") do
          3
        end
      ),
      (
        def encode(:NETWORK_SWITCH) do
          4
        end

        def encode("NETWORK_SWITCH") do
          4
        end
      ),
      (
        def encode(:PING_RECONNECT) do
          5
        end

        def encode("PING_RECONNECT") do
          5
        end
      ),
      (
        def encode(:UNKNOWN) do
          6
        end

        def encode("UNKNOWN") do
          6
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :PUSH
      end,
      def decode(1) do
        :USER_ACTIVATED
      end,
      def decode(2) do
        :SCHEDULED
      end,
      def decode(3) do
        :ERROR_RECONNECT
      end,
      def decode(4) do
        :NETWORK_SWITCH
      end,
      def decode(5) do
        :PING_RECONNECT
      end,
      def decode(6) do
        :UNKNOWN
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :PUSH},
        {1, :USER_ACTIVATED},
        {2, :SCHEDULED},
        {3, :ERROR_RECONNECT},
        {4, :NETWORK_SWITCH},
        {5, :PING_RECONNECT},
        {6, :UNKNOWN}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:PUSH) do
          true
        end,
        def has_constant?(:USER_ACTIVATED) do
          true
        end,
        def has_constant?(:SCHEDULED) do
          true
        end,
        def has_constant?(:ERROR_RECONNECT) do
          true
        end,
        def has_constant?(:NETWORK_SWITCH) do
          true
        end,
        def has_constant?(:PING_RECONNECT) do
          true
        end,
        def has_constant?(:UNKNOWN) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
