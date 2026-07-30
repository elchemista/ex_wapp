# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.StatusNotificationMessage.StatusNotificationType do
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
        def encode(:STATUS_ADD_YOURS) do
          1
        end

        def encode("STATUS_ADD_YOURS") do
          1
        end
      ),
      (
        def encode(:STATUS_RESHARE) do
          2
        end

        def encode("STATUS_RESHARE") do
          2
        end
      ),
      (
        def encode(:STATUS_QUESTION_ANSWER_RESHARE) do
          3
        end

        def encode("STATUS_QUESTION_ANSWER_RESHARE") do
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
        :UNKNOWN
      end,
      def decode(1) do
        :STATUS_ADD_YOURS
      end,
      def decode(2) do
        :STATUS_RESHARE
      end,
      def decode(3) do
        :STATUS_QUESTION_ANSWER_RESHARE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :STATUS_ADD_YOURS},
        {2, :STATUS_RESHARE},
        {3, :STATUS_QUESTION_ANSWER_RESHARE}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:STATUS_ADD_YOURS) do
          true
        end,
        def has_constant?(:STATUS_RESHARE) do
          true
        end,
        def has_constant?(:STATUS_QUESTION_ANSWER_RESHARE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
