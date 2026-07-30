# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ContextInfo.BusinessInteractionPills.PillType do
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
        def encode(:VIEW_BUSINESS) do
          1
        end

        def encode("VIEW_BUSINESS") do
          1
        end
      ),
      (
        def encode(:CHAT) do
          2
        end

        def encode("CHAT") do
          2
        end
      ),
      (
        def encode(:CALL) do
          3
        end

        def encode("CALL") do
          3
        end
      ),
      (
        def encode(:CATALOG) do
          4
        end

        def encode("CATALOG") do
          4
        end
      ),
      (
        def encode(:CHANNEL) do
          5
        end

        def encode("CHANNEL") do
          5
        end
      ),
      (
        def encode(:BOOK_APPOINTMENT) do
          6
        end

        def encode("BOOK_APPOINTMENT") do
          6
        end
      ),
      (
        def encode(:OFFERS) do
          7
        end

        def encode("OFFERS") do
          7
        end
      ),
      (
        def encode(:BESTSELLERS) do
          8
        end

        def encode("BESTSELLERS") do
          8
        end
      ),
      (
        def encode(:MENU) do
          9
        end

        def encode("MENU") do
          9
        end
      ),
      (
        def encode(:ABOUT) do
          10
        end

        def encode("ABOUT") do
          10
        end
      ),
      (
        def encode(:SHOP) do
          11
        end

        def encode("SHOP") do
          11
        end
      ),
      (
        def encode(:ORDER) do
          12
        end

        def encode("ORDER") do
          12
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
        :VIEW_BUSINESS
      end,
      def decode(2) do
        :CHAT
      end,
      def decode(3) do
        :CALL
      end,
      def decode(4) do
        :CATALOG
      end,
      def decode(5) do
        :CHANNEL
      end,
      def decode(6) do
        :BOOK_APPOINTMENT
      end,
      def decode(7) do
        :OFFERS
      end,
      def decode(8) do
        :BESTSELLERS
      end,
      def decode(9) do
        :MENU
      end,
      def decode(10) do
        :ABOUT
      end,
      def decode(11) do
        :SHOP
      end,
      def decode(12) do
        :ORDER
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :VIEW_BUSINESS},
        {2, :CHAT},
        {3, :CALL},
        {4, :CATALOG},
        {5, :CHANNEL},
        {6, :BOOK_APPOINTMENT},
        {7, :OFFERS},
        {8, :BESTSELLERS},
        {9, :MENU},
        {10, :ABOUT},
        {11, :SHOP},
        {12, :ORDER}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:VIEW_BUSINESS) do
          true
        end,
        def has_constant?(:CHAT) do
          true
        end,
        def has_constant?(:CALL) do
          true
        end,
        def has_constant?(:CATALOG) do
          true
        end,
        def has_constant?(:CHANNEL) do
          true
        end,
        def has_constant?(:BOOK_APPOINTMENT) do
          true
        end,
        def has_constant?(:OFFERS) do
          true
        end,
        def has_constant?(:BESTSELLERS) do
          true
        end,
        def has_constant?(:MENU) do
          true
        end,
        def has_constant?(:ABOUT) do
          true
        end,
        def has_constant?(:SHOP) do
          true
        end,
        def has_constant?(:ORDER) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
