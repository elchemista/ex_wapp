# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotSessionSource do
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
        def encode(:NULL_STATE) do
          1
        end

        def encode("NULL_STATE") do
          1
        end
      ),
      (
        def encode(:TYPEAHEAD) do
          2
        end

        def encode("TYPEAHEAD") do
          2
        end
      ),
      (
        def encode(:USER_INPUT) do
          3
        end

        def encode("USER_INPUT") do
          3
        end
      ),
      (
        def encode(:EMU_FLASH) do
          4
        end

        def encode("EMU_FLASH") do
          4
        end
      ),
      (
        def encode(:EMU_FLASH_FOLLOWUP) do
          5
        end

        def encode("EMU_FLASH_FOLLOWUP") do
          5
        end
      ),
      (
        def encode(:VOICE) do
          6
        end

        def encode("VOICE") do
          6
        end
      ),
      (
        def encode(:AI_HOME_SESSION) do
          7
        end

        def encode("AI_HOME_SESSION") do
          7
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
        :NULL_STATE
      end,
      def decode(2) do
        :TYPEAHEAD
      end,
      def decode(3) do
        :USER_INPUT
      end,
      def decode(4) do
        :EMU_FLASH
      end,
      def decode(5) do
        :EMU_FLASH_FOLLOWUP
      end,
      def decode(6) do
        :VOICE
      end,
      def decode(7) do
        :AI_HOME_SESSION
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :NONE},
        {1, :NULL_STATE},
        {2, :TYPEAHEAD},
        {3, :USER_INPUT},
        {4, :EMU_FLASH},
        {5, :EMU_FLASH_FOLLOWUP},
        {6, :VOICE},
        {7, :AI_HOME_SESSION}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NONE) do
          true
        end,
        def has_constant?(:NULL_STATE) do
          true
        end,
        def has_constant?(:TYPEAHEAD) do
          true
        end,
        def has_constant?(:USER_INPUT) do
          true
        end,
        def has_constant?(:EMU_FLASH) do
          true
        end,
        def has_constant?(:EMU_FLASH_FOLLOWUP) do
          true
        end,
        def has_constant?(:VOICE) do
          true
        end,
        def has_constant?(:AI_HOME_SESSION) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
