# credo:disable-for-this-file
defmodule WACommon.Mention.MentionType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :PROFILE
      def default() do
        :PROFILE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:PROFILE) do
          0
        end

        def encode("PROFILE") do
          0
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :PROFILE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :PROFILE}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:PROFILE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
