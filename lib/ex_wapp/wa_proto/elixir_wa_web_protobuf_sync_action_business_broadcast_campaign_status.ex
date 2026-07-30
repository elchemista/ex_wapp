# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.BusinessBroadcastCampaignStatus do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :DRAFT
      def default() do
        :DRAFT
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:DRAFT) do
          1
        end

        def encode("DRAFT") do
          1
        end
      ),
      (
        def encode(:SCHEDULED) do
          2
        end

        def encode("SCHEDULED") do
          2
        end
      ),
      (
        def encode(:PROCESSING) do
          3
        end

        def encode("PROCESSING") do
          3
        end
      ),
      (
        def encode(:FAILED) do
          4
        end

        def encode("FAILED") do
          4
        end
      ),
      (
        def encode(:SENT) do
          5
        end

        def encode("SENT") do
          5
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :DRAFT
      end,
      def decode(2) do
        :SCHEDULED
      end,
      def decode(3) do
        :PROCESSING
      end,
      def decode(4) do
        :FAILED
      end,
      def decode(5) do
        :SENT
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :DRAFT}, {2, :SCHEDULED}, {3, :PROCESSING}, {4, :FAILED}, {5, :SENT}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:DRAFT) do
          true
        end,
        def has_constant?(:SCHEDULED) do
          true
        end,
        def has_constant?(:PROCESSING) do
          true
        end,
        def has_constant?(:FAILED) do
          true
        end,
        def has_constant?(:SENT) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
