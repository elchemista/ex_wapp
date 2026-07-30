# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.InThreadSurveyMetadata do
  @moduledoc false
  defstruct tessaSessionID: nil,
            simonSessionID: nil,
            simonSurveyID: nil,
            tessaRootID: nil,
            requestID: nil,
            tessaEvent: nil,
            invitationHeaderText: nil,
            invitationBodyText: nil,
            invitationCtaText: nil,
            invitationCtaURL: nil,
            surveyTitle: nil,
            questions: [],
            surveyContinueButtonText: nil,
            surveySubmitButtonText: nil,
            privacyStatementFull: nil,
            privacyStatementParts: [],
            feedbackToastText: nil,
            startQuestionIndex: nil,
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
        |> encode_tessaSessionID(msg)
        |> encode_simonSessionID(msg)
        |> encode_simonSurveyID(msg)
        |> encode_tessaRootID(msg)
        |> encode_requestID(msg)
        |> encode_tessaEvent(msg)
        |> encode_invitationHeaderText(msg)
        |> encode_invitationBodyText(msg)
        |> encode_invitationCtaText(msg)
        |> encode_invitationCtaURL(msg)
        |> encode_surveyTitle(msg)
        |> encode_questions(msg)
        |> encode_surveyContinueButtonText(msg)
        |> encode_surveySubmitButtonText(msg)
        |> encode_privacyStatementFull(msg)
        |> encode_privacyStatementParts(msg)
        |> encode_feedbackToastText(msg)
        |> encode_startQuestionIndex(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_tessaSessionID(acc, msg) do
        try do
          case msg.tessaSessionID do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.tessaSessionID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:tessaSessionID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_simonSessionID(acc, msg) do
        try do
          case msg.simonSessionID do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.simonSessionID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:simonSessionID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_simonSurveyID(acc, msg) do
        try do
          case msg.simonSurveyID do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.simonSurveyID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:simonSurveyID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_tessaRootID(acc, msg) do
        try do
          case msg.tessaRootID do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.tessaRootID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:tessaRootID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_requestID(acc, msg) do
        try do
          case msg.requestID do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.requestID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:requestID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_tessaEvent(acc, msg) do
        try do
          case msg.tessaEvent do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_string(msg.tessaEvent)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:tessaEvent, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_invitationHeaderText(acc, msg) do
        try do
          case msg.invitationHeaderText do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_string(msg.invitationHeaderText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:invitationHeaderText, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_invitationBodyText(acc, msg) do
        try do
          case msg.invitationBodyText do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_string(msg.invitationBodyText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:invitationBodyText, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_invitationCtaText(acc, msg) do
        try do
          case msg.invitationCtaText do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_string(msg.invitationCtaText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:invitationCtaText, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_invitationCtaURL(acc, msg) do
        try do
          case msg.invitationCtaURL do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_string(msg.invitationCtaURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:invitationCtaURL, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_surveyTitle(acc, msg) do
        try do
          case msg.surveyTitle do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_string(msg.surveyTitle)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:surveyTitle, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_questions(acc, msg) do
        try do
          case msg.questions do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "b", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:questions, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_surveyContinueButtonText(acc, msg) do
        try do
          case msg.surveyContinueButtonText do
            nil -> acc
            _ -> [acc, "j", Protox.Encode.encode_string(msg.surveyContinueButtonText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:surveyContinueButtonText, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_surveySubmitButtonText(acc, msg) do
        try do
          case msg.surveySubmitButtonText do
            nil -> acc
            _ -> [acc, "r", Protox.Encode.encode_string(msg.surveySubmitButtonText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:surveySubmitButtonText, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_privacyStatementFull(acc, msg) do
        try do
          case msg.privacyStatementFull do
            nil -> acc
            _ -> [acc, "z", Protox.Encode.encode_string(msg.privacyStatementFull)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:privacyStatementFull, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_privacyStatementParts(acc, msg) do
        try do
          case msg.privacyStatementParts do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\x82\x01", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:privacyStatementParts, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_feedbackToastText(acc, msg) do
        try do
          case msg.feedbackToastText do
            nil -> acc
            _ -> [acc, "\x8A\x01", Protox.Encode.encode_string(msg.feedbackToastText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:feedbackToastText, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_startQuestionIndex(acc, msg) do
        try do
          case msg.startQuestionIndex do
            nil -> acc
            _ -> [acc, "\x90\x01", Protox.Encode.encode_int32(msg.startQuestionIndex)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:startQuestionIndex, "invalid field value"),
                    __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsAICommon.InThreadSurveyMetadata))
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
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[tessaSessionID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[simonSessionID: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[simonSurveyID: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[tessaRootID: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[requestID: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[tessaEvent: Protox.Decode.validate_string!(delimited)], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[invitationHeaderText: Protox.Decode.validate_string!(delimited)], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[invitationBodyText: Protox.Decode.validate_string!(delimited)], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[invitationCtaText: Protox.Decode.validate_string!(delimited)], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[invitationCtaURL: Protox.Decode.validate_string!(delimited)], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[surveyTitle: Protox.Decode.validate_string!(delimited)], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 questions:
                   msg.questions ++
                     [
                       WAWebProtobufsAICommon.InThreadSurveyMetadata.InThreadSurveyQuestion.decode!(
                         delimited
                       )
                     ]
               ], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[surveyContinueButtonText: Protox.Decode.validate_string!(delimited)], rest}

            {14, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[surveySubmitButtonText: Protox.Decode.validate_string!(delimited)], rest}

            {15, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[privacyStatementFull: Protox.Decode.validate_string!(delimited)], rest}

            {16, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 privacyStatementParts:
                   msg.privacyStatementParts ++
                     [
                       WAWebProtobufsAICommon.InThreadSurveyMetadata.InThreadSurveyPrivacyStatementPart.decode!(
                         delimited
                       )
                     ]
               ], rest}

            {17, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[feedbackToastText: Protox.Decode.validate_string!(delimited)], rest}

            {18, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[startQuestionIndex: value], rest}

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
        WAWebProtobufsAICommon.InThreadSurveyMetadata,
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
        1 => {:tessaSessionID, {:scalar, ""}, :string},
        2 => {:simonSessionID, {:scalar, ""}, :string},
        3 => {:simonSurveyID, {:scalar, ""}, :string},
        4 => {:tessaRootID, {:scalar, ""}, :string},
        5 => {:requestID, {:scalar, ""}, :string},
        6 => {:tessaEvent, {:scalar, ""}, :string},
        7 => {:invitationHeaderText, {:scalar, ""}, :string},
        8 => {:invitationBodyText, {:scalar, ""}, :string},
        9 => {:invitationCtaText, {:scalar, ""}, :string},
        10 => {:invitationCtaURL, {:scalar, ""}, :string},
        11 => {:surveyTitle, {:scalar, ""}, :string},
        12 =>
          {:questions, :unpacked,
           {:message, WAWebProtobufsAICommon.InThreadSurveyMetadata.InThreadSurveyQuestion}},
        13 => {:surveyContinueButtonText, {:scalar, ""}, :string},
        14 => {:surveySubmitButtonText, {:scalar, ""}, :string},
        15 => {:privacyStatementFull, {:scalar, ""}, :string},
        16 =>
          {:privacyStatementParts, :unpacked,
           {:message,
            WAWebProtobufsAICommon.InThreadSurveyMetadata.InThreadSurveyPrivacyStatementPart}},
        17 => {:feedbackToastText, {:scalar, ""}, :string},
        18 => {:startQuestionIndex, {:scalar, 0}, :int32}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        feedbackToastText: {17, {:scalar, ""}, :string},
        invitationBodyText: {8, {:scalar, ""}, :string},
        invitationCtaText: {9, {:scalar, ""}, :string},
        invitationCtaURL: {10, {:scalar, ""}, :string},
        invitationHeaderText: {7, {:scalar, ""}, :string},
        privacyStatementFull: {15, {:scalar, ""}, :string},
        privacyStatementParts:
          {16, :unpacked,
           {:message,
            WAWebProtobufsAICommon.InThreadSurveyMetadata.InThreadSurveyPrivacyStatementPart}},
        questions:
          {12, :unpacked,
           {:message, WAWebProtobufsAICommon.InThreadSurveyMetadata.InThreadSurveyQuestion}},
        requestID: {5, {:scalar, ""}, :string},
        simonSessionID: {2, {:scalar, ""}, :string},
        simonSurveyID: {3, {:scalar, ""}, :string},
        startQuestionIndex: {18, {:scalar, 0}, :int32},
        surveyContinueButtonText: {13, {:scalar, ""}, :string},
        surveySubmitButtonText: {14, {:scalar, ""}, :string},
        surveyTitle: {11, {:scalar, ""}, :string},
        tessaEvent: {6, {:scalar, ""}, :string},
        tessaRootID: {4, {:scalar, ""}, :string},
        tessaSessionID: {1, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "tessaSessionID",
          kind: {:scalar, ""},
          label: :optional,
          name: :tessaSessionID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "simonSessionID",
          kind: {:scalar, ""},
          label: :optional,
          name: :simonSessionID,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "simonSurveyID",
          kind: {:scalar, ""},
          label: :optional,
          name: :simonSurveyID,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "tessaRootID",
          kind: {:scalar, ""},
          label: :optional,
          name: :tessaRootID,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "requestID",
          kind: {:scalar, ""},
          label: :optional,
          name: :requestID,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "tessaEvent",
          kind: {:scalar, ""},
          label: :optional,
          name: :tessaEvent,
          tag: 6,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "invitationHeaderText",
          kind: {:scalar, ""},
          label: :optional,
          name: :invitationHeaderText,
          tag: 7,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "invitationBodyText",
          kind: {:scalar, ""},
          label: :optional,
          name: :invitationBodyText,
          tag: 8,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "invitationCtaText",
          kind: {:scalar, ""},
          label: :optional,
          name: :invitationCtaText,
          tag: 9,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "invitationCtaURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :invitationCtaURL,
          tag: 10,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "surveyTitle",
          kind: {:scalar, ""},
          label: :optional,
          name: :surveyTitle,
          tag: 11,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "questions",
          kind: :unpacked,
          label: :repeated,
          name: :questions,
          tag: 12,
          type: {:message, WAWebProtobufsAICommon.InThreadSurveyMetadata.InThreadSurveyQuestion}
        },
        %{
          __struct__: Protox.Field,
          json_name: "surveyContinueButtonText",
          kind: {:scalar, ""},
          label: :optional,
          name: :surveyContinueButtonText,
          tag: 13,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "surveySubmitButtonText",
          kind: {:scalar, ""},
          label: :optional,
          name: :surveySubmitButtonText,
          tag: 14,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "privacyStatementFull",
          kind: {:scalar, ""},
          label: :optional,
          name: :privacyStatementFull,
          tag: 15,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "privacyStatementParts",
          kind: :unpacked,
          label: :repeated,
          name: :privacyStatementParts,
          tag: 16,
          type:
            {:message,
             WAWebProtobufsAICommon.InThreadSurveyMetadata.InThreadSurveyPrivacyStatementPart}
        },
        %{
          __struct__: Protox.Field,
          json_name: "feedbackToastText",
          kind: {:scalar, ""},
          label: :optional,
          name: :feedbackToastText,
          tag: 17,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "startQuestionIndex",
          kind: {:scalar, 0},
          label: :optional,
          name: :startQuestionIndex,
          tag: 18,
          type: :int32
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:tessaSessionID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tessaSessionID",
             kind: {:scalar, ""},
             label: :optional,
             name: :tessaSessionID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("tessaSessionID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tessaSessionID",
             kind: {:scalar, ""},
             label: :optional,
             name: :tessaSessionID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:simonSessionID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "simonSessionID",
             kind: {:scalar, ""},
             label: :optional,
             name: :simonSessionID,
             tag: 2,
             type: :string
           }}
        end

        def field_def("simonSessionID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "simonSessionID",
             kind: {:scalar, ""},
             label: :optional,
             name: :simonSessionID,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:simonSurveyID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "simonSurveyID",
             kind: {:scalar, ""},
             label: :optional,
             name: :simonSurveyID,
             tag: 3,
             type: :string
           }}
        end

        def field_def("simonSurveyID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "simonSurveyID",
             kind: {:scalar, ""},
             label: :optional,
             name: :simonSurveyID,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:tessaRootID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tessaRootID",
             kind: {:scalar, ""},
             label: :optional,
             name: :tessaRootID,
             tag: 4,
             type: :string
           }}
        end

        def field_def("tessaRootID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tessaRootID",
             kind: {:scalar, ""},
             label: :optional,
             name: :tessaRootID,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:requestID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestID",
             kind: {:scalar, ""},
             label: :optional,
             name: :requestID,
             tag: 5,
             type: :string
           }}
        end

        def field_def("requestID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestID",
             kind: {:scalar, ""},
             label: :optional,
             name: :requestID,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:tessaEvent) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tessaEvent",
             kind: {:scalar, ""},
             label: :optional,
             name: :tessaEvent,
             tag: 6,
             type: :string
           }}
        end

        def field_def("tessaEvent") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tessaEvent",
             kind: {:scalar, ""},
             label: :optional,
             name: :tessaEvent,
             tag: 6,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:invitationHeaderText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "invitationHeaderText",
             kind: {:scalar, ""},
             label: :optional,
             name: :invitationHeaderText,
             tag: 7,
             type: :string
           }}
        end

        def field_def("invitationHeaderText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "invitationHeaderText",
             kind: {:scalar, ""},
             label: :optional,
             name: :invitationHeaderText,
             tag: 7,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:invitationBodyText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "invitationBodyText",
             kind: {:scalar, ""},
             label: :optional,
             name: :invitationBodyText,
             tag: 8,
             type: :string
           }}
        end

        def field_def("invitationBodyText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "invitationBodyText",
             kind: {:scalar, ""},
             label: :optional,
             name: :invitationBodyText,
             tag: 8,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:invitationCtaText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "invitationCtaText",
             kind: {:scalar, ""},
             label: :optional,
             name: :invitationCtaText,
             tag: 9,
             type: :string
           }}
        end

        def field_def("invitationCtaText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "invitationCtaText",
             kind: {:scalar, ""},
             label: :optional,
             name: :invitationCtaText,
             tag: 9,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:invitationCtaURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "invitationCtaURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :invitationCtaURL,
             tag: 10,
             type: :string
           }}
        end

        def field_def("invitationCtaURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "invitationCtaURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :invitationCtaURL,
             tag: 10,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:surveyTitle) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "surveyTitle",
             kind: {:scalar, ""},
             label: :optional,
             name: :surveyTitle,
             tag: 11,
             type: :string
           }}
        end

        def field_def("surveyTitle") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "surveyTitle",
             kind: {:scalar, ""},
             label: :optional,
             name: :surveyTitle,
             tag: 11,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:questions) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "questions",
             kind: :unpacked,
             label: :repeated,
             name: :questions,
             tag: 12,
             type:
               {:message, WAWebProtobufsAICommon.InThreadSurveyMetadata.InThreadSurveyQuestion}
           }}
        end

        def field_def("questions") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "questions",
             kind: :unpacked,
             label: :repeated,
             name: :questions,
             tag: 12,
             type:
               {:message, WAWebProtobufsAICommon.InThreadSurveyMetadata.InThreadSurveyQuestion}
           }}
        end

        []
      ),
      (
        def field_def(:surveyContinueButtonText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "surveyContinueButtonText",
             kind: {:scalar, ""},
             label: :optional,
             name: :surveyContinueButtonText,
             tag: 13,
             type: :string
           }}
        end

        def field_def("surveyContinueButtonText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "surveyContinueButtonText",
             kind: {:scalar, ""},
             label: :optional,
             name: :surveyContinueButtonText,
             tag: 13,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:surveySubmitButtonText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "surveySubmitButtonText",
             kind: {:scalar, ""},
             label: :optional,
             name: :surveySubmitButtonText,
             tag: 14,
             type: :string
           }}
        end

        def field_def("surveySubmitButtonText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "surveySubmitButtonText",
             kind: {:scalar, ""},
             label: :optional,
             name: :surveySubmitButtonText,
             tag: 14,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:privacyStatementFull) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "privacyStatementFull",
             kind: {:scalar, ""},
             label: :optional,
             name: :privacyStatementFull,
             tag: 15,
             type: :string
           }}
        end

        def field_def("privacyStatementFull") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "privacyStatementFull",
             kind: {:scalar, ""},
             label: :optional,
             name: :privacyStatementFull,
             tag: 15,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:privacyStatementParts) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "privacyStatementParts",
             kind: :unpacked,
             label: :repeated,
             name: :privacyStatementParts,
             tag: 16,
             type:
               {:message,
                WAWebProtobufsAICommon.InThreadSurveyMetadata.InThreadSurveyPrivacyStatementPart}
           }}
        end

        def field_def("privacyStatementParts") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "privacyStatementParts",
             kind: :unpacked,
             label: :repeated,
             name: :privacyStatementParts,
             tag: 16,
             type:
               {:message,
                WAWebProtobufsAICommon.InThreadSurveyMetadata.InThreadSurveyPrivacyStatementPart}
           }}
        end

        []
      ),
      (
        def field_def(:feedbackToastText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "feedbackToastText",
             kind: {:scalar, ""},
             label: :optional,
             name: :feedbackToastText,
             tag: 17,
             type: :string
           }}
        end

        def field_def("feedbackToastText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "feedbackToastText",
             kind: {:scalar, ""},
             label: :optional,
             name: :feedbackToastText,
             tag: 17,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:startQuestionIndex) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "startQuestionIndex",
             kind: {:scalar, 0},
             label: :optional,
             name: :startQuestionIndex,
             tag: 18,
             type: :int32
           }}
        end

        def field_def("startQuestionIndex") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "startQuestionIndex",
             kind: {:scalar, 0},
             label: :optional,
             name: :startQuestionIndex,
             tag: 18,
             type: :int32
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
    def default(:tessaSessionID) do
      {:ok, ""}
    end,
    def default(:simonSessionID) do
      {:ok, ""}
    end,
    def default(:simonSurveyID) do
      {:ok, ""}
    end,
    def default(:tessaRootID) do
      {:ok, ""}
    end,
    def default(:requestID) do
      {:ok, ""}
    end,
    def default(:tessaEvent) do
      {:ok, ""}
    end,
    def default(:invitationHeaderText) do
      {:ok, ""}
    end,
    def default(:invitationBodyText) do
      {:ok, ""}
    end,
    def default(:invitationCtaText) do
      {:ok, ""}
    end,
    def default(:invitationCtaURL) do
      {:ok, ""}
    end,
    def default(:surveyTitle) do
      {:ok, ""}
    end,
    def default(:questions) do
      {:error, :no_default_value}
    end,
    def default(:surveyContinueButtonText) do
      {:ok, ""}
    end,
    def default(:surveySubmitButtonText) do
      {:ok, ""}
    end,
    def default(:privacyStatementFull) do
      {:ok, ""}
    end,
    def default(:privacyStatementParts) do
      {:error, :no_default_value}
    end,
    def default(:feedbackToastText) do
      {:ok, ""}
    end,
    def default(:startQuestionIndex) do
      {:ok, 0}
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
