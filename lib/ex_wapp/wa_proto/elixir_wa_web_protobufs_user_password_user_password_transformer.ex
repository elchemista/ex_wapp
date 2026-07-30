# credo:disable-for-this-file
defmodule WAWebProtobufsUserPassword.UserPassword.Transformer do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :NONE
      def default() do
        :NONE
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:NONE) do
          0
        end

        def encode("NONE") do
          0
        end
      ),
      (
        def encode(:PBKDF2_HMAC_SHA512) do
          1
        end

        def encode("PBKDF2_HMAC_SHA512") do
          1
        end
      ),
      (
        def encode(:PBKDF2_HMAC_SHA384) do
          2
        end

        def encode("PBKDF2_HMAC_SHA384") do
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
        :NONE
      end,
      def decode(1) do
        :PBKDF2_HMAC_SHA512
      end,
      def decode(2) do
        :PBKDF2_HMAC_SHA384
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :NONE}, {1, :PBKDF2_HMAC_SHA512}, {2, :PBKDF2_HMAC_SHA384}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:NONE) do
          true
        end,
        def has_constant?(:PBKDF2_HMAC_SHA512) do
          true
        end,
        def has_constant?(:PBKDF2_HMAC_SHA384) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
