# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponseCode do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :GENERATION_ERROR
      def default() do
        :GENERATION_ERROR
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:GENERATION_ERROR) do
          1
        end

        def encode("GENERATION_ERROR") do
          1
        end
      ),
      (
        def encode(:CHUNK_CONSUMED) do
          2
        end

        def encode("CHUNK_CONSUMED") do
          2
        end
      ),
      (
        def encode(:TIMEOUT) do
          3
        end

        def encode("TIMEOUT") do
          3
        end
      ),
      (
        def encode(:SESSION_EXHAUSTED) do
          4
        end

        def encode("SESSION_EXHAUSTED") do
          4
        end
      ),
      (
        def encode(:CHUNK_EXHAUSTED) do
          5
        end

        def encode("CHUNK_EXHAUSTED") do
          5
        end
      ),
      (
        def encode(:DUPLICATED_REQUEST) do
          6
        end

        def encode("DUPLICATED_REQUEST") do
          6
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :GENERATION_ERROR
      end,
      def decode(2) do
        :CHUNK_CONSUMED
      end,
      def decode(3) do
        :TIMEOUT
      end,
      def decode(4) do
        :SESSION_EXHAUSTED
      end,
      def decode(5) do
        :CHUNK_EXHAUSTED
      end,
      def decode(6) do
        :DUPLICATED_REQUEST
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {1, :GENERATION_ERROR},
        {2, :CHUNK_CONSUMED},
        {3, :TIMEOUT},
        {4, :SESSION_EXHAUSTED},
        {5, :CHUNK_EXHAUSTED},
        {6, :DUPLICATED_REQUEST}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:GENERATION_ERROR) do
          true
        end,
        def has_constant?(:CHUNK_CONSUMED) do
          true
        end,
        def has_constant?(:TIMEOUT) do
          true
        end,
        def has_constant?(:SESSION_EXHAUSTED) do
          true
        end,
        def has_constant?(:CHUNK_EXHAUSTED) do
          true
        end,
        def has_constant?(:DUPLICATED_REQUEST) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
