# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData do
  @moduledoc false
  defstruct surveyID: nil,
            primaryResponseID: nil,
            testArmName: nil,
            timestampMSString: nil,
            ctaImpressionEvent: nil,
            ctaClickEvent: nil,
            cardImpressionEvent: nil,
            responseEvent: nil,
            abandonEvent: nil,
            __uf__: []

  (
    (
      @spec encode(struct) :: {:ok, iodata} | {:error, any}
      def encode(msg) do
        try do
          {:ok, encode!(msg)}
        rescue
          e in [Protox.EncodingError, Protox.RequiredFieldsError] -> {:error, e}
        end
      end

      @spec encode!(struct) :: iodata | no_return
      def encode!(msg) do
        []
        |> encode_surveyID(msg)
        |> encode_primaryResponseID(msg)
        |> encode_testArmName(msg)
        |> encode_timestampMSString(msg)
        |> encode_ctaImpressionEvent(msg)
        |> encode_ctaClickEvent(msg)
        |> encode_cardImpressionEvent(msg)
        |> encode_responseEvent(msg)
        |> encode_abandonEvent(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_surveyID(acc, msg) do
        try do
          case msg.surveyID do
            nil -> acc
            _ -> [acc, "\b", Protox.Encode.encode_uint32(msg.surveyID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:surveyID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_primaryResponseID(acc, msg) do
        try do
          case msg.primaryResponseID do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.primaryResponseID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:primaryResponseID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_testArmName(acc, msg) do
        try do
          case msg.testArmName do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.testArmName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:testArmName, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_timestampMSString(acc, msg) do
        try do
          case msg.timestampMSString do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.timestampMSString)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:timestampMSString, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ctaImpressionEvent(acc, msg) do
        try do
          case msg.ctaImpressionEvent do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_message(msg.ctaImpressionEvent)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ctaImpressionEvent, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ctaClickEvent(acc, msg) do
        try do
          case msg.ctaClickEvent do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_message(msg.ctaClickEvent)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ctaClickEvent, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_cardImpressionEvent(acc, msg) do
        try do
          case msg.cardImpressionEvent do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_message(msg.cardImpressionEvent)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:cardImpressionEvent, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_responseEvent(acc, msg) do
        try do
          case msg.responseEvent do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_message(msg.responseEvent)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:responseEvent, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_abandonEvent(acc, msg) do
        try do
          case msg.abandonEvent do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_message(msg.abandonEvent)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:abandonEvent, "invalid field value"), __STACKTRACE__
        end
      end
    ]

    defp encode_unknown_fields(acc, msg) do
      Enum.reduce(msg.__struct__.unknown_fields(msg), acc, fn {tag, wire_type, bytes}, acc ->
        case wire_type do
          0 ->
            [acc, Protox.Encode.make_key_bytes(tag, :int32), bytes]

          1 ->
            [acc, Protox.Encode.make_key_bytes(tag, :double), bytes]

          2 ->
            len_bytes = bytes |> byte_size() |> Protox.Varint.encode()
            [acc, Protox.Encode.make_key_bytes(tag, :packed), len_bytes, bytes]

          5 ->
            [acc, Protox.Encode.make_key_bytes(tag, :float), bytes]
        end
      end)
    end
  )

  (
    (
      @spec decode(binary) :: {:ok, struct} | {:error, any}
      def decode(bytes) do
        try do
          {:ok, decode!(bytes)}
        rescue
          e in [Protox.DecodingError, Protox.IllegalTagError, Protox.RequiredFieldsError] ->
            {:error, e}
        end
      end

      (
        @spec decode!(binary) :: struct | no_return
        def decode!(bytes) do
          parse_key_value(
            bytes,
            struct(
              WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData
            )
          )
        end
      )
    )

    (
      @spec parse_key_value(binary, struct) :: struct
      defp parse_key_value(<<>>, msg) do
        msg
      end

      defp parse_key_value(bytes, msg) do
        {field, rest} =
          case Protox.Decode.parse_key(bytes) do
            {0, _, _} ->
              raise %Protox.IllegalTagError{}

            {1, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[surveyID: value], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[primaryResponseID: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[testArmName: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[timestampMSString: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 ctaImpressionEvent:
                   Protox.MergeMessage.merge(
                     msg.ctaImpressionEvent,
                     WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCTAImpressionEventData.decode!(
                       delimited
                     )
                   )
               ], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 ctaClickEvent:
                   Protox.MergeMessage.merge(
                     msg.ctaClickEvent,
                     WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCTAClickEventData.decode!(
                       delimited
                     )
                   )
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 cardImpressionEvent:
                   Protox.MergeMessage.merge(
                     msg.cardImpressionEvent,
                     WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCardImpressionEventData.decode!(
                       delimited
                     )
                   )
               ], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 responseEvent:
                   Protox.MergeMessage.merge(
                     msg.responseEvent,
                     WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyResponseEventData.decode!(
                       delimited
                     )
                   )
               ], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 abandonEvent:
                   Protox.MergeMessage.merge(
                     msg.abandonEvent,
                     WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyAbandonEventData.decode!(
                       delimited
                     )
                   )
               ], rest}

            {tag, wire_type, rest} ->
              {value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

              {[
                 {msg.__struct__.unknown_fields_name(),
                  [value | msg.__struct__.unknown_fields(msg)]}
               ], rest}
          end

        msg_updated = struct(msg, field)
        parse_key_value(rest, msg_updated)
      end
    )

    []
  )

  (
    @spec json_decode(iodata(), keyword()) :: {:ok, struct()} | {:error, any()}
    def json_decode(input, opts \\ []) do
      try do
        {:ok, json_decode!(input, opts)}
      rescue
        e in Protox.JsonDecodingError -> {:error, e}
      end
    end

    @spec json_decode!(iodata(), keyword()) :: struct() | no_return()
    def json_decode!(input, opts \\ []) do
      {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :decode)

      Protox.JsonDecode.decode!(
        input,
        WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData,
        &json_library_wrapper.decode!(json_library, &1)
      )
    end

    @spec json_encode(struct(), keyword()) :: {:ok, iodata()} | {:error, any()}
    def json_encode(msg, opts \\ []) do
      try do
        {:ok, json_encode!(msg, opts)}
      rescue
        e in Protox.JsonEncodingError -> {:error, e}
      end
    end

    @spec json_encode!(struct(), keyword()) :: iodata() | no_return()
    def json_encode!(msg, opts \\ []) do
      {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :encode)
      Protox.JsonEncode.encode!(msg, &json_library_wrapper.encode!(json_library, &1))
    end
  )

  (
    @deprecated "Use fields_defs()/0 instead"
    @spec defs() :: %{
            required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs() do
      %{
        1 => {:surveyID, {:scalar, 0}, :uint32},
        2 => {:primaryResponseID, {:scalar, ""}, :string},
        3 => {:testArmName, {:scalar, ""}, :string},
        4 => {:timestampMSString, {:scalar, ""}, :string},
        5 =>
          {:ctaImpressionEvent, {:scalar, nil},
           {:message,
            WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCTAImpressionEventData}},
        6 =>
          {:ctaClickEvent, {:scalar, nil},
           {:message,
            WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCTAClickEventData}},
        7 =>
          {:cardImpressionEvent, {:scalar, nil},
           {:message,
            WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCardImpressionEventData}},
        8 =>
          {:responseEvent, {:scalar, nil},
           {:message,
            WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyResponseEventData}},
        9 =>
          {:abandonEvent, {:scalar, nil},
           {:message,
            WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyAbandonEventData}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        abandonEvent:
          {9, {:scalar, nil},
           {:message,
            WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyAbandonEventData}},
        cardImpressionEvent:
          {7, {:scalar, nil},
           {:message,
            WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCardImpressionEventData}},
        ctaClickEvent:
          {6, {:scalar, nil},
           {:message,
            WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCTAClickEventData}},
        ctaImpressionEvent:
          {5, {:scalar, nil},
           {:message,
            WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCTAImpressionEventData}},
        primaryResponseID: {2, {:scalar, ""}, :string},
        responseEvent:
          {8, {:scalar, nil},
           {:message,
            WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyResponseEventData}},
        surveyID: {1, {:scalar, 0}, :uint32},
        testArmName: {3, {:scalar, ""}, :string},
        timestampMSString: {4, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "surveyID",
          kind: {:scalar, 0},
          label: :optional,
          name: :surveyID,
          tag: 1,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "primaryResponseID",
          kind: {:scalar, ""},
          label: :optional,
          name: :primaryResponseID,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "testArmName",
          kind: {:scalar, ""},
          label: :optional,
          name: :testArmName,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "timestampMSString",
          kind: {:scalar, ""},
          label: :optional,
          name: :timestampMSString,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "ctaImpressionEvent",
          kind: {:scalar, nil},
          label: :optional,
          name: :ctaImpressionEvent,
          tag: 5,
          type:
            {:message,
             WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCTAImpressionEventData}
        },
        %{
          __struct__: Protox.Field,
          json_name: "ctaClickEvent",
          kind: {:scalar, nil},
          label: :optional,
          name: :ctaClickEvent,
          tag: 6,
          type:
            {:message,
             WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCTAClickEventData}
        },
        %{
          __struct__: Protox.Field,
          json_name: "cardImpressionEvent",
          kind: {:scalar, nil},
          label: :optional,
          name: :cardImpressionEvent,
          tag: 7,
          type:
            {:message,
             WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCardImpressionEventData}
        },
        %{
          __struct__: Protox.Field,
          json_name: "responseEvent",
          kind: {:scalar, nil},
          label: :optional,
          name: :responseEvent,
          tag: 8,
          type:
            {:message,
             WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyResponseEventData}
        },
        %{
          __struct__: Protox.Field,
          json_name: "abandonEvent",
          kind: {:scalar, nil},
          label: :optional,
          name: :abandonEvent,
          tag: 9,
          type:
            {:message,
             WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyAbandonEventData}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:surveyID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "surveyID",
             kind: {:scalar, 0},
             label: :optional,
             name: :surveyID,
             tag: 1,
             type: :uint32
           }}
        end

        def field_def("surveyID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "surveyID",
             kind: {:scalar, 0},
             label: :optional,
             name: :surveyID,
             tag: 1,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:primaryResponseID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "primaryResponseID",
             kind: {:scalar, ""},
             label: :optional,
             name: :primaryResponseID,
             tag: 2,
             type: :string
           }}
        end

        def field_def("primaryResponseID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "primaryResponseID",
             kind: {:scalar, ""},
             label: :optional,
             name: :primaryResponseID,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:testArmName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "testArmName",
             kind: {:scalar, ""},
             label: :optional,
             name: :testArmName,
             tag: 3,
             type: :string
           }}
        end

        def field_def("testArmName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "testArmName",
             kind: {:scalar, ""},
             label: :optional,
             name: :testArmName,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:timestampMSString) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "timestampMSString",
             kind: {:scalar, ""},
             label: :optional,
             name: :timestampMSString,
             tag: 4,
             type: :string
           }}
        end

        def field_def("timestampMSString") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "timestampMSString",
             kind: {:scalar, ""},
             label: :optional,
             name: :timestampMSString,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:ctaImpressionEvent) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctaImpressionEvent",
             kind: {:scalar, nil},
             label: :optional,
             name: :ctaImpressionEvent,
             tag: 5,
             type:
               {:message,
                WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCTAImpressionEventData}
           }}
        end

        def field_def("ctaImpressionEvent") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctaImpressionEvent",
             kind: {:scalar, nil},
             label: :optional,
             name: :ctaImpressionEvent,
             tag: 5,
             type:
               {:message,
                WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCTAImpressionEventData}
           }}
        end

        []
      ),
      (
        def field_def(:ctaClickEvent) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctaClickEvent",
             kind: {:scalar, nil},
             label: :optional,
             name: :ctaClickEvent,
             tag: 6,
             type:
               {:message,
                WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCTAClickEventData}
           }}
        end

        def field_def("ctaClickEvent") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctaClickEvent",
             kind: {:scalar, nil},
             label: :optional,
             name: :ctaClickEvent,
             tag: 6,
             type:
               {:message,
                WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCTAClickEventData}
           }}
        end

        []
      ),
      (
        def field_def(:cardImpressionEvent) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "cardImpressionEvent",
             kind: {:scalar, nil},
             label: :optional,
             name: :cardImpressionEvent,
             tag: 7,
             type:
               {:message,
                WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCardImpressionEventData}
           }}
        end

        def field_def("cardImpressionEvent") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "cardImpressionEvent",
             kind: {:scalar, nil},
             label: :optional,
             name: :cardImpressionEvent,
             tag: 7,
             type:
               {:message,
                WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyCardImpressionEventData}
           }}
        end

        []
      ),
      (
        def field_def(:responseEvent) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "responseEvent",
             kind: {:scalar, nil},
             label: :optional,
             name: :responseEvent,
             tag: 8,
             type:
               {:message,
                WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyResponseEventData}
           }}
        end

        def field_def("responseEvent") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "responseEvent",
             kind: {:scalar, nil},
             label: :optional,
             name: :responseEvent,
             tag: 8,
             type:
               {:message,
                WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyResponseEventData}
           }}
        end

        []
      ),
      (
        def field_def(:abandonEvent) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "abandonEvent",
             kind: {:scalar, nil},
             label: :optional,
             name: :abandonEvent,
             tag: 9,
             type:
               {:message,
                WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyAbandonEventData}
           }}
        end

        def field_def("abandonEvent") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "abandonEvent",
             kind: {:scalar, nil},
             label: :optional,
             name: :abandonEvent,
             tag: 9,
             type:
               {:message,
                WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.SideBySideSurveyAbandonEventData}
           }}
        end

        []
      ),
      def field_def(_) do
        {:error, :no_such_field}
      end
    ]
  )

  (
    @spec unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
    def unknown_fields(msg) do
      msg.__uf__
    end

    @spec unknown_fields_name() :: :__uf__
    def unknown_fields_name() do
      :__uf__
    end

    @spec clear_unknown_fields(struct) :: struct
    def clear_unknown_fields(msg) do
      struct!(msg, [{unknown_fields_name(), []}])
    end
  )

  (
    @spec required_fields() :: []
    def required_fields() do
      []
    end
  )

  (
    @spec syntax() :: atom()
    def syntax() do
      :proto2
    end
  )

  [
    @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
    def default(:surveyID) do
      {:ok, 0}
    end,
    def default(:primaryResponseID) do
      {:ok, ""}
    end,
    def default(:testArmName) do
      {:ok, ""}
    end,
    def default(:timestampMSString) do
      {:ok, ""}
    end,
    def default(:ctaImpressionEvent) do
      {:ok, nil}
    end,
    def default(:ctaClickEvent) do
      {:ok, nil}
    end,
    def default(:cardImpressionEvent) do
      {:ok, nil}
    end,
    def default(:responseEvent) do
      {:ok, nil}
    end,
    def default(:abandonEvent) do
      {:ok, nil}
    end,
    def default(_) do
      {:error, :no_such_field}
    end
  ]

  (
    @spec file_options() :: struct()
    def file_options() do
      file_options = %{
        __struct__: Protox.Google.Protobuf.FileOptions,
        __uf__: [],
        cc_enable_arenas: nil,
        cc_generic_services: nil,
        csharp_namespace: nil,
        deprecated: nil,
        go_package: "go.mau.fi/whatsmeow/proto/waAICommon",
        java_generate_equals_and_hash: nil,
        java_generic_services: nil,
        java_multiple_files: nil,
        java_outer_classname: nil,
        java_package: nil,
        java_string_check_utf8: nil,
        objc_class_prefix: nil,
        optimize_for: nil,
        php_class_prefix: nil,
        php_generic_services: nil,
        php_metadata_namespace: nil,
        php_namespace: nil,
        py_generic_services: nil,
        ruby_package: nil,
        swift_prefix: nil,
        uninterpreted_option: []
      }

      case function_exported?(Google.Protobuf.FileOptions, :decode!, 1) do
        true ->
          bytes =
            file_options |> Protox.Google.Protobuf.FileOptions.encode!() |> :binary.list_to_bin()

          apply(Google.Protobuf.FileOptions, :decode!, [bytes])

        false ->
          file_options
      end
    end
  )

  @type t :: %__MODULE__{}
end
