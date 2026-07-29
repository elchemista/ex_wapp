# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.AIHomeState.AIHomeOption.AIHomeActionType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :PROMPT
      def default() do
        :PROMPT
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:PROMPT) do
          0
        end

        def encode("PROMPT") do
          0
        end
      ),
      (
        def encode(:CREATE_IMAGE) do
          1
        end

        def encode("CREATE_IMAGE") do
          1
        end
      ),
      (
        def encode(:ANIMATE_PHOTO) do
          2
        end

        def encode("ANIMATE_PHOTO") do
          2
        end
      ),
      (
        def encode(:ANALYZE_FILE) do
          3
        end

        def encode("ANALYZE_FILE") do
          3
        end
      ),
      (
        def encode(:COLLABORATE) do
          4
        end

        def encode("COLLABORATE") do
          4
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(0) do
        :PROMPT
      end,
      def decode(1) do
        :CREATE_IMAGE
      end,
      def decode(2) do
        :ANIMATE_PHOTO
      end,
      def decode(3) do
        :ANALYZE_FILE
      end,
      def decode(4) do
        :COLLABORATE
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :PROMPT},
        {1, :CREATE_IMAGE},
        {2, :ANIMATE_PHOTO},
        {3, :ANALYZE_FILE},
        {4, :COLLABORATE}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:PROMPT) do
          true
        end,
        def has_constant?(:CREATE_IMAGE) do
          true
        end,
        def has_constant?(:ANIMATE_PHOTO) do
          true
        end,
        def has_constant?(:ANALYZE_FILE) do
          true
        end,
        def has_constant?(:COLLABORATE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
