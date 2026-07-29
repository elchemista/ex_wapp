# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.SecretEncryptedMessage.SecretEncType do
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
        def encode(:EVENT_EDIT) do
          1
        end

        def encode("EVENT_EDIT") do
          1
        end
      ),
      (
        def encode(:MESSAGE_EDIT) do
          2
        end

        def encode("MESSAGE_EDIT") do
          2
        end
      ),
      (
        def encode(:MESSAGE_SCHEDULE) do
          3
        end

        def encode("MESSAGE_SCHEDULE") do
          3
        end
      ),
      (
        def encode(:POLL_EDIT) do
          4
        end

        def encode("POLL_EDIT") do
          4
        end
      ),
      (
        def encode(:POLL_ADD_OPTION) do
          5
        end

        def encode("POLL_ADD_OPTION") do
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
        :UNKNOWN
      end,
      def decode(1) do
        :EVENT_EDIT
      end,
      def decode(2) do
        :MESSAGE_EDIT
      end,
      def decode(3) do
        :MESSAGE_SCHEDULE
      end,
      def decode(4) do
        :POLL_EDIT
      end,
      def decode(5) do
        :POLL_ADD_OPTION
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :EVENT_EDIT},
        {2, :MESSAGE_EDIT},
        {3, :MESSAGE_SCHEDULE},
        {4, :POLL_EDIT},
        {5, :POLL_ADD_OPTION}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:EVENT_EDIT) do
          true
        end,
        def has_constant?(:MESSAGE_EDIT) do
          true
        end,
        def has_constant?(:MESSAGE_SCHEDULE) do
          true
        end,
        def has_constant?(:POLL_EDIT) do
          true
        end,
        def has_constant?(:POLL_ADD_OPTION) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
