# credo:disable-for-this-file
defmodule WAStatusAttributions.StatusAttribution.StatusReshare.Source do
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
        def encode(:INTERNAL_RESHARE) do
          1
        end

        def encode("INTERNAL_RESHARE") do
          1
        end
      ),
      (
        def encode(:MENTION_RESHARE) do
          2
        end

        def encode("MENTION_RESHARE") do
          2
        end
      ),
      (
        def encode(:CHANNEL_RESHARE) do
          3
        end

        def encode("CHANNEL_RESHARE") do
          3
        end
      ),
      (
        def encode(:FORWARD) do
          4
        end

        def encode("FORWARD") do
          4
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
        :INTERNAL_RESHARE
      end,
      def decode(2) do
        :MENTION_RESHARE
      end,
      def decode(3) do
        :CHANNEL_RESHARE
      end,
      def decode(4) do
        :FORWARD
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :INTERNAL_RESHARE},
        {2, :MENTION_RESHARE},
        {3, :CHANNEL_RESHARE},
        {4, :FORWARD}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:INTERNAL_RESHARE) do
          true
        end,
        def has_constant?(:MENTION_RESHARE) do
          true
        end,
        def has_constant?(:CHANNEL_RESHARE) do
          true
        end,
        def has_constant?(:FORWARD) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
