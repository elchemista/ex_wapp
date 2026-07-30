# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.BizAISettingsNudgeAction.BizAISettingsCategory do
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
        def encode(:INSTRUCTIONS) do
          1
        end

        def encode("INSTRUCTIONS") do
          1
        end
      ),
      (
        def encode(:RESPONSE_SETTINGS) do
          2
        end

        def encode("RESPONSE_SETTINGS") do
          2
        end
      ),
      (
        def encode(:EXAMPLE_RESPONSES) do
          3
        end

        def encode("EXAMPLE_RESPONSES") do
          3
        end
      ),
      (
        def encode(:KNOWLEDGE) do
          4
        end

        def encode("KNOWLEDGE") do
          4
        end
      ),
      (
        def encode(:LEAD_GEN) do
          5
        end

        def encode("LEAD_GEN") do
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
        :INSTRUCTIONS
      end,
      def decode(2) do
        :RESPONSE_SETTINGS
      end,
      def decode(3) do
        :EXAMPLE_RESPONSES
      end,
      def decode(4) do
        :KNOWLEDGE
      end,
      def decode(5) do
        :LEAD_GEN
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :INSTRUCTIONS},
        {2, :RESPONSE_SETTINGS},
        {3, :EXAMPLE_RESPONSES},
        {4, :KNOWLEDGE},
        {5, :LEAD_GEN}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:INSTRUCTIONS) do
          true
        end,
        def has_constant?(:RESPONSE_SETTINGS) do
          true
        end,
        def has_constant?(:EXAMPLE_RESPONSES) do
          true
        end,
        def has_constant?(:KNOWLEDGE) do
          true
        end,
        def has_constant?(:LEAD_GEN) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
