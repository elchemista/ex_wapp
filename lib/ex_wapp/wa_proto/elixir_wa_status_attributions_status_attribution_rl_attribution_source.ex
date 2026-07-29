# credo:disable-for-this-file
defmodule WAStatusAttributions.StatusAttribution.RLAttribution.Source do
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
        def encode(:RAY_BAN_META_GLASSES) do
          1
        end

        def encode("RAY_BAN_META_GLASSES") do
          1
        end
      ),
      (
        def encode(:OAKLEY_META_GLASSES) do
          2
        end

        def encode("OAKLEY_META_GLASSES") do
          2
        end
      ),
      (
        def encode(:HYPERNOVA_GLASSES) do
          3
        end

        def encode("HYPERNOVA_GLASSES") do
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
        :RAY_BAN_META_GLASSES
      end,
      def decode(2) do
        :OAKLEY_META_GLASSES
      end,
      def decode(3) do
        :HYPERNOVA_GLASSES
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :RAY_BAN_META_GLASSES},
        {2, :OAKLEY_META_GLASSES},
        {3, :HYPERNOVA_GLASSES}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:RAY_BAN_META_GLASSES) do
          true
        end,
        def has_constant?(:OAKLEY_META_GLASSES) do
          true
        end,
        def has_constant?(:HYPERNOVA_GLASSES) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
