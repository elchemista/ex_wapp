# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.DayOfWeekType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :MONDAY
      def default() do
        :MONDAY
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:MONDAY) do
          1
        end

        def encode("MONDAY") do
          1
        end
      ),
      (
        def encode(:TUESDAY) do
          2
        end

        def encode("TUESDAY") do
          2
        end
      ),
      (
        def encode(:WEDNESDAY) do
          3
        end

        def encode("WEDNESDAY") do
          3
        end
      ),
      (
        def encode(:THURSDAY) do
          4
        end

        def encode("THURSDAY") do
          4
        end
      ),
      (
        def encode(:FRIDAY) do
          5
        end

        def encode("FRIDAY") do
          5
        end
      ),
      (
        def encode(:SATURDAY) do
          6
        end

        def encode("SATURDAY") do
          6
        end
      ),
      (
        def encode(:SUNDAY) do
          7
        end

        def encode("SUNDAY") do
          7
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(1) do
        :MONDAY
      end,
      def decode(2) do
        :TUESDAY
      end,
      def decode(3) do
        :WEDNESDAY
      end,
      def decode(4) do
        :THURSDAY
      end,
      def decode(5) do
        :FRIDAY
      end,
      def decode(6) do
        :SATURDAY
      end,
      def decode(7) do
        :SUNDAY
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {1, :MONDAY},
        {2, :TUESDAY},
        {3, :WEDNESDAY},
        {4, :THURSDAY},
        {5, :FRIDAY},
        {6, :SATURDAY},
        {7, :SUNDAY}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:MONDAY) do
          true
        end,
        def has_constant?(:TUESDAY) do
          true
        end,
        def has_constant?(:WEDNESDAY) do
          true
        end,
        def has_constant?(:THURSDAY) do
          true
        end,
        def has_constant?(:FRIDAY) do
          true
        end,
        def has_constant?(:SATURDAY) do
          true
        end,
        def has_constant?(:SUNDAY) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
