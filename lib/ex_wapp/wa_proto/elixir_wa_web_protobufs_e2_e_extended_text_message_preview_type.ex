# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ExtendedTextMessage.PreviewType do
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
        def encode(:VIDEO) do
          1
        end

        def encode("VIDEO") do
          1
        end
      ),
      (
        def encode(:PLACEHOLDER) do
          4
        end

        def encode("PLACEHOLDER") do
          4
        end
      ),
      (
        def encode(:IMAGE) do
          5
        end

        def encode("IMAGE") do
          5
        end
      ),
      (
        def encode(:PAYMENT_LINKS) do
          6
        end

        def encode("PAYMENT_LINKS") do
          6
        end
      ),
      (
        def encode(:PROFILE) do
          7
        end

        def encode("PROFILE") do
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
        :VIDEO
      end,
      def decode(4) do
        :PLACEHOLDER
      end,
      def decode(5) do
        :IMAGE
      end,
      def decode(6) do
        :PAYMENT_LINKS
      end,
      def decode(7) do
        :PROFILE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :NONE},
        {1, :VIDEO},
        {4, :PLACEHOLDER},
        {5, :IMAGE},
        {6, :PAYMENT_LINKS},
        {7, :PROFILE}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NONE) do
          true
        end,
        def has_constant?(:VIDEO) do
          true
        end,
        def has_constant?(:PLACEHOLDER) do
          true
        end,
        def has_constant?(:IMAGE) do
          true
        end,
        def has_constant?(:PAYMENT_LINKS) do
          true
        end,
        def has_constant?(:PROFILE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
