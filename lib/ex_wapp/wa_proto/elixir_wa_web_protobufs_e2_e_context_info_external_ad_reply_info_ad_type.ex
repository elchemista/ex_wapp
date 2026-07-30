# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.AdType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :CTWA
      def default() do
        :CTWA
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:CTWA) do
          0
        end

        def encode("CTWA") do
          0
        end
      ),
      (
        def encode(:CAWC) do
          1
        end

        def encode("CAWC") do
          1
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :CTWA
      end,
      def decode(1) do
        :CAWC
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :CTWA}, {1, :CAWC}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:CTWA) do
          true
        end,
        def has_constant?(:CAWC) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
