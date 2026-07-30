# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.NoteEditAction.NoteType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNSTRUCTURED
      def default() do
        :UNSTRUCTURED
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNSTRUCTURED) do
          1
        end

        def encode("UNSTRUCTURED") do
          1
        end
      ),
      (
        def encode(:STRUCTURED) do
          2
        end

        def encode("STRUCTURED") do
          2
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :UNSTRUCTURED
      end,
      def decode(2) do
        :STRUCTURED
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :UNSTRUCTURED}, {2, :STRUCTURED}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNSTRUCTURED) do
          true
        end,
        def has_constant?(:STRUCTURED) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
