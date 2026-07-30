# credo:disable-for-this-file
defmodule WAMmsRetry.MediaRetryNotification.ResultType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :GENERAL_ERROR
      def default() do
        :GENERAL_ERROR
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:GENERAL_ERROR) do
          0
        end

        def encode("GENERAL_ERROR") do
          0
        end
      ),
      (
        def encode(:SUCCESS) do
          1
        end

        def encode("SUCCESS") do
          1
        end
      ),
      (
        def encode(:NOT_FOUND) do
          2
        end

        def encode("NOT_FOUND") do
          2
        end
      ),
      (
        def encode(:DECRYPTION_ERROR) do
          3
        end

        def encode("DECRYPTION_ERROR") do
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
        :GENERAL_ERROR
      end,
      def decode(1) do
        :SUCCESS
      end,
      def decode(2) do
        :NOT_FOUND
      end,
      def decode(3) do
        :DECRYPTION_ERROR
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :GENERAL_ERROR}, {1, :SUCCESS}, {2, :NOT_FOUND}, {3, :DECRYPTION_ERROR}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:GENERAL_ERROR) do
          true
        end,
        def has_constant?(:SUCCESS) do
          true
        end,
        def has_constant?(:NOT_FOUND) do
          true
        end,
        def has_constant?(:DECRYPTION_ERROR) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
