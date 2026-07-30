# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ThreadID.ThreadType do
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
        def encode(:VIEW_REPLIES) do
          1
        end

        def encode("VIEW_REPLIES") do
          1
        end
      ),
      (
        def encode(:AI_THREAD) do
          2
        end

        def encode("AI_THREAD") do
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
        :UNKNOWN
      end,
      def decode(1) do
        :VIEW_REPLIES
      end,
      def decode(2) do
        :AI_THREAD
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN}, {1, :VIEW_REPLIES}, {2, :AI_THREAD}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:VIEW_REPLIES) do
          true
        end,
        def has_constant?(:AI_THREAD) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
