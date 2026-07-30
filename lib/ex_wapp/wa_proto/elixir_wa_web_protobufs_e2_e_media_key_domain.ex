# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.MediaKeyDomain do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :MEDIA_KEY_DOMAIN_UNKNOWN
      def default() do
        :MEDIA_KEY_DOMAIN_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:MEDIA_KEY_DOMAIN_UNKNOWN) do
          0
        end

        def encode("MEDIA_KEY_DOMAIN_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:MEDIA_KEY_DOMAIN_E2EE) do
          1
        end

        def encode("MEDIA_KEY_DOMAIN_E2EE") do
          1
        end
      ),
      (
        def encode(:MEDIA_KEY_DOMAIN_NON_E2EE) do
          2
        end

        def encode("MEDIA_KEY_DOMAIN_NON_E2EE") do
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
        :MEDIA_KEY_DOMAIN_UNKNOWN
      end,
      def decode(1) do
        :MEDIA_KEY_DOMAIN_E2EE
      end,
      def decode(2) do
        :MEDIA_KEY_DOMAIN_NON_E2EE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :MEDIA_KEY_DOMAIN_UNKNOWN},
        {1, :MEDIA_KEY_DOMAIN_E2EE},
        {2, :MEDIA_KEY_DOMAIN_NON_E2EE}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:MEDIA_KEY_DOMAIN_UNKNOWN) do
          true
        end,
        def has_constant?(:MEDIA_KEY_DOMAIN_E2EE) do
          true
        end,
        def has_constant?(:MEDIA_KEY_DOMAIN_NON_E2EE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
