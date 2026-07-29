# credo:disable-for-this-file
defmodule WAStatusAttributions.StatusAttribution.Type do
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
        def encode(:RESHARE) do
          1
        end

        def encode("RESHARE") do
          1
        end
      ),
      (
        def encode(:EXTERNAL_SHARE) do
          2
        end

        def encode("EXTERNAL_SHARE") do
          2
        end
      ),
      (
        def encode(:MUSIC) do
          3
        end

        def encode("MUSIC") do
          3
        end
      ),
      (
        def encode(:STATUS_MENTION) do
          4
        end

        def encode("STATUS_MENTION") do
          4
        end
      ),
      (
        def encode(:GROUP_STATUS) do
          5
        end

        def encode("GROUP_STATUS") do
          5
        end
      ),
      (
        def encode(:RL_ATTRIBUTION) do
          6
        end

        def encode("RL_ATTRIBUTION") do
          6
        end
      ),
      (
        def encode(:AI_CREATED) do
          7
        end

        def encode("AI_CREATED") do
          7
        end
      ),
      (
        def encode(:LAYOUTS) do
          8
        end

        def encode("LAYOUTS") do
          8
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
        :RESHARE
      end,
      def decode(2) do
        :EXTERNAL_SHARE
      end,
      def decode(3) do
        :MUSIC
      end,
      def decode(4) do
        :STATUS_MENTION
      end,
      def decode(5) do
        :GROUP_STATUS
      end,
      def decode(6) do
        :RL_ATTRIBUTION
      end,
      def decode(7) do
        :AI_CREATED
      end,
      def decode(8) do
        :LAYOUTS
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :RESHARE},
        {2, :EXTERNAL_SHARE},
        {3, :MUSIC},
        {4, :STATUS_MENTION},
        {5, :GROUP_STATUS},
        {6, :RL_ATTRIBUTION},
        {7, :AI_CREATED},
        {8, :LAYOUTS}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:RESHARE) do
          true
        end,
        def has_constant?(:EXTERNAL_SHARE) do
          true
        end,
        def has_constant?(:MUSIC) do
          true
        end,
        def has_constant?(:STATUS_MENTION) do
          true
        end,
        def has_constant?(:GROUP_STATUS) do
          true
        end,
        def has_constant?(:RL_ATTRIBUTION) do
          true
        end,
        def has_constant?(:AI_CREATED) do
          true
        end,
        def has_constant?(:LAYOUTS) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
