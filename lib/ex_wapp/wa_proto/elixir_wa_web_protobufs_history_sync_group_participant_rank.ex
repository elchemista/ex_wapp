# credo:disable-for-this-file
defmodule WAWebProtobufsHistorySync.GroupParticipant.Rank do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :REGULAR
      def default() do
        :REGULAR
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:REGULAR) do
          0
        end

        def encode("REGULAR") do
          0
        end
      ),
      (
        def encode(:ADMIN) do
          1
        end

        def encode("ADMIN") do
          1
        end
      ),
      (
        def encode(:SUPERADMIN) do
          2
        end

        def encode("SUPERADMIN") do
          2
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :REGULAR
      end,
      def decode(1) do
        :ADMIN
      end,
      def decode(2) do
        :SUPERADMIN
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :REGULAR}, {1, :ADMIN}, {2, :SUPERADMIN}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:REGULAR) do
          true
        end,
        def has_constant?(:ADMIN) do
          true
        end,
        def has_constant?(:SUPERADMIN) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
