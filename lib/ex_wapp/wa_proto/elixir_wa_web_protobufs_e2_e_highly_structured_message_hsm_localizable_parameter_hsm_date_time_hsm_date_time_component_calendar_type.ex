# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.CalendarType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :GREGORIAN
      def default() do
        :GREGORIAN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:GREGORIAN) do
          1
        end

        def encode("GREGORIAN") do
          1
        end
      ),
      (
        def encode(:SOLAR_HIJRI) do
          2
        end

        def encode("SOLAR_HIJRI") do
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
        :GREGORIAN
      end,
      def decode(2) do
        :SOLAR_HIJRI
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{1, :GREGORIAN}, {2, :SOLAR_HIJRI}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:GREGORIAN) do
          true
        end,
        def has_constant?(:SOLAR_HIJRI) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
