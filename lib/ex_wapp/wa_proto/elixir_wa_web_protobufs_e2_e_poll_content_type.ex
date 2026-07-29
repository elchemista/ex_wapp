# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PollContentType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN_POLL_CONTENT_TYPE
      def default() do
        :UNKNOWN_POLL_CONTENT_TYPE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN_POLL_CONTENT_TYPE) do
          0
        end

        def encode("UNKNOWN_POLL_CONTENT_TYPE") do
          0
        end
      ),
      (
        def encode(:TEXT) do
          1
        end

        def encode("TEXT") do
          1
        end
      ),
      (
        def encode(:IMAGE) do
          2
        end

        def encode("IMAGE") do
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
        :UNKNOWN_POLL_CONTENT_TYPE
      end,
      def decode(1) do
        :TEXT
      end,
      def decode(2) do
        :IMAGE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :UNKNOWN_POLL_CONTENT_TYPE}, {1, :TEXT}, {2, :IMAGE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN_POLL_CONTENT_TYPE) do
          true
        end,
        def has_constant?(:TEXT) do
          true
        end,
        def has_constant?(:IMAGE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
