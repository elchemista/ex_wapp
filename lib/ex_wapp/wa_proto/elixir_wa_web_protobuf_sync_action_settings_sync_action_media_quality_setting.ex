# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.SettingsSyncAction.MediaQualitySetting do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :MEDIA_QUALITY_UNKNOWN
      def default() do
        :MEDIA_QUALITY_UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:MEDIA_QUALITY_UNKNOWN) do
          0
        end

        def encode("MEDIA_QUALITY_UNKNOWN") do
          0
        end
      ),
      (
        def encode(:STANDARD) do
          1
        end

        def encode("STANDARD") do
          1
        end
      ),
      (
        def encode(:HD) do
          2
        end

        def encode("HD") do
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
        :MEDIA_QUALITY_UNKNOWN
      end,
      def decode(1) do
        :STANDARD
      end,
      def decode(2) do
        :HD
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [{0, :MEDIA_QUALITY_UNKNOWN}, {1, :STANDARD}, {2, :HD}]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:MEDIA_QUALITY_UNKNOWN) do
          true
        end,
        def has_constant?(:STANDARD) do
          true
        end,
        def has_constant?(:HD) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
