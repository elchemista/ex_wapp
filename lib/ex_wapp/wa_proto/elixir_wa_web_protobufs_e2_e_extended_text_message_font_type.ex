# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ExtendedTextMessage.FontType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :SYSTEM
      def default() do
        :SYSTEM
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:SYSTEM) do
          0
        end

        def encode("SYSTEM") do
          0
        end
      ),
      (
        def encode(:SYSTEM_TEXT) do
          1
        end

        def encode("SYSTEM_TEXT") do
          1
        end
      ),
      (
        def encode(:FB_SCRIPT) do
          2
        end

        def encode("FB_SCRIPT") do
          2
        end
      ),
      (
        def encode(:SYSTEM_BOLD) do
          6
        end

        def encode("SYSTEM_BOLD") do
          6
        end
      ),
      (
        def encode(:MORNINGBREEZE_REGULAR) do
          7
        end

        def encode("MORNINGBREEZE_REGULAR") do
          7
        end
      ),
      (
        def encode(:CALISTOGA_REGULAR) do
          8
        end

        def encode("CALISTOGA_REGULAR") do
          8
        end
      ),
      (
        def encode(:EXO2_EXTRABOLD) do
          9
        end

        def encode("EXO2_EXTRABOLD") do
          9
        end
      ),
      (
        def encode(:COURIERPRIME_BOLD) do
          10
        end

        def encode("COURIERPRIME_BOLD") do
          10
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :SYSTEM
      end,
      def decode(1) do
        :SYSTEM_TEXT
      end,
      def decode(2) do
        :FB_SCRIPT
      end,
      def decode(6) do
        :SYSTEM_BOLD
      end,
      def decode(7) do
        :MORNINGBREEZE_REGULAR
      end,
      def decode(8) do
        :CALISTOGA_REGULAR
      end,
      def decode(9) do
        :EXO2_EXTRABOLD
      end,
      def decode(10) do
        :COURIERPRIME_BOLD
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :SYSTEM},
        {1, :SYSTEM_TEXT},
        {2, :FB_SCRIPT},
        {6, :SYSTEM_BOLD},
        {7, :MORNINGBREEZE_REGULAR},
        {8, :CALISTOGA_REGULAR},
        {9, :EXO2_EXTRABOLD},
        {10, :COURIERPRIME_BOLD}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:SYSTEM) do
          true
        end,
        def has_constant?(:SYSTEM_TEXT) do
          true
        end,
        def has_constant?(:FB_SCRIPT) do
          true
        end,
        def has_constant?(:SYSTEM_BOLD) do
          true
        end,
        def has_constant?(:MORNINGBREEZE_REGULAR) do
          true
        end,
        def has_constant?(:CALISTOGA_REGULAR) do
          true
        end,
        def has_constant?(:EXO2_EXTRABOLD) do
          true
        end,
        def has_constant?(:COURIERPRIME_BOLD) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
