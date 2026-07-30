# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata do
  @moduledoc false
  defstruct selectedRequestID: nil,
            surveyID: nil,
            simonSessionFbid: nil,
            responseOtid: nil,
            responseTimestampMSString: nil,
            isSelectedResponsePrimary: nil,
            messageIDToEdit: nil,
            analyticsData: nil,
            metaAiAnalyticsData: nil,
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
        |> encode_selectedRequestID(msg)
        |> encode_surveyID(msg)
        |> encode_simonSessionFbid(msg)
        |> encode_responseOtid(msg)
        |> encode_responseTimestampMSString(msg)
        |> encode_isSelectedResponsePrimary(msg)
        |> encode_messageIDToEdit(msg)
        |> encode_analyticsData(msg)
        |> encode_metaAiAnalyticsData(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_selectedRequestID(acc, msg) do
        try do
          case msg.selectedRequestID do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.selectedRequestID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:selectedRequestID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_surveyID(acc, msg) do
        try do
          case msg.surveyID do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_uint32(msg.surveyID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:surveyID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_simonSessionFbid(acc, msg) do
        try do
          case msg.simonSessionFbid do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.simonSessionFbid)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:simonSessionFbid, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_responseOtid(acc, msg) do
        try do
          case msg.responseOtid do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.responseOtid)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:responseOtid, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_responseTimestampMSString(acc, msg) do
        try do
          case msg.responseTimestampMSString do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.responseTimestampMSString)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:responseTimestampMSString, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isSelectedResponsePrimary(acc, msg) do
        try do
          case msg.isSelectedResponsePrimary do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_bool(msg.isSelectedResponsePrimary)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isSelectedResponsePrimary, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messageIDToEdit(acc, msg) do
        try do
          case msg.messageIDToEdit do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_string(msg.messageIDToEdit)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageIDToEdit, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_analyticsData(acc, msg) do
        try do
          case msg.analyticsData do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_message(msg.analyticsData)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:analyticsData, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_metaAiAnalyticsData(acc, msg) do
        try do
          case msg.metaAiAnalyticsData do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_message(msg.metaAiAnalyticsData)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:metaAiAnalyticsData, "invalid field value"),
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
          parse_key_value(
            bytes,
            struct(WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata)
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
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[selectedRequestID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[surveyID: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[simonSessionFbid: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[responseOtid: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[responseTimestampMSString: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isSelectedResponsePrimary: value], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[messageIDToEdit: Protox.Decode.validate_string!(delimited)], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 analyticsData:
                   Protox.MergeMessage.merge(
                     msg.analyticsData,
                     WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SideBySideSurveyAnalyticsData.decode!(
                       delimited
                     )
                   )
               ], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 metaAiAnalyticsData:
                   Protox.MergeMessage.merge(
                     msg.metaAiAnalyticsData,
                     WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData.decode!(
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
        WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata,
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
        1 => {:selectedRequestID, {:scalar, ""}, :string},
        2 => {:surveyID, {:scalar, 0}, :uint32},
        3 => {:simonSessionFbid, {:scalar, ""}, :string},
        4 => {:responseOtid, {:scalar, ""}, :string},
        5 => {:responseTimestampMSString, {:scalar, ""}, :string},
        6 => {:isSelectedResponsePrimary, {:scalar, false}, :bool},
        7 => {:messageIDToEdit, {:scalar, ""}, :string},
        8 =>
          {:analyticsData, {:scalar, nil},
           {:message,
            WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SideBySideSurveyAnalyticsData}},
        9 =>
          {:metaAiAnalyticsData, {:scalar, nil},
           {:message,
            WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        analyticsData:
          {8, {:scalar, nil},
           {:message,
            WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SideBySideSurveyAnalyticsData}},
        isSelectedResponsePrimary: {6, {:scalar, false}, :bool},
        messageIDToEdit: {7, {:scalar, ""}, :string},
        metaAiAnalyticsData:
          {9, {:scalar, nil},
           {:message,
            WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData}},
        responseOtid: {4, {:scalar, ""}, :string},
        responseTimestampMSString: {5, {:scalar, ""}, :string},
        selectedRequestID: {1, {:scalar, ""}, :string},
        simonSessionFbid: {3, {:scalar, ""}, :string},
        surveyID: {2, {:scalar, 0}, :uint32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "selectedRequestID",
          kind: {:scalar, ""},
          label: :optional,
          name: :selectedRequestID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "surveyID",
          kind: {:scalar, 0},
          label: :optional,
          name: :surveyID,
          tag: 2,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "simonSessionFbid",
          kind: {:scalar, ""},
          label: :optional,
          name: :simonSessionFbid,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "responseOtid",
          kind: {:scalar, ""},
          label: :optional,
          name: :responseOtid,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "responseTimestampMSString",
          kind: {:scalar, ""},
          label: :optional,
          name: :responseTimestampMSString,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "isSelectedResponsePrimary",
          kind: {:scalar, false},
          label: :optional,
          name: :isSelectedResponsePrimary,
          tag: 6,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageIDToEdit",
          kind: {:scalar, ""},
          label: :optional,
          name: :messageIDToEdit,
          tag: 7,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "analyticsData",
          kind: {:scalar, nil},
          label: :optional,
          name: :analyticsData,
          tag: 8,
          type:
            {:message,
             WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SideBySideSurveyAnalyticsData}
        },
        %{
          __struct__: Protox.Field,
          json_name: "metaAiAnalyticsData",
          kind: {:scalar, nil},
          label: :optional,
          name: :metaAiAnalyticsData,
          tag: 9,
          type:
            {:message,
             WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:selectedRequestID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "selectedRequestID",
             kind: {:scalar, ""},
             label: :optional,
             name: :selectedRequestID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("selectedRequestID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "selectedRequestID",
             kind: {:scalar, ""},
             label: :optional,
             name: :selectedRequestID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:surveyID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "surveyID",
             kind: {:scalar, 0},
             label: :optional,
             name: :surveyID,
             tag: 2,
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
             tag: 2,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:simonSessionFbid) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "simonSessionFbid",
             kind: {:scalar, ""},
             label: :optional,
             name: :simonSessionFbid,
             tag: 3,
             type: :string
           }}
        end

        def field_def("simonSessionFbid") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "simonSessionFbid",
             kind: {:scalar, ""},
             label: :optional,
             name: :simonSessionFbid,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:responseOtid) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "responseOtid",
             kind: {:scalar, ""},
             label: :optional,
             name: :responseOtid,
             tag: 4,
             type: :string
           }}
        end

        def field_def("responseOtid") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "responseOtid",
             kind: {:scalar, ""},
             label: :optional,
             name: :responseOtid,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:responseTimestampMSString) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "responseTimestampMSString",
             kind: {:scalar, ""},
             label: :optional,
             name: :responseTimestampMSString,
             tag: 5,
             type: :string
           }}
        end

        def field_def("responseTimestampMSString") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "responseTimestampMSString",
             kind: {:scalar, ""},
             label: :optional,
             name: :responseTimestampMSString,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:isSelectedResponsePrimary) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSelectedResponsePrimary",
             kind: {:scalar, false},
             label: :optional,
             name: :isSelectedResponsePrimary,
             tag: 6,
             type: :bool
           }}
        end

        def field_def("isSelectedResponsePrimary") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSelectedResponsePrimary",
             kind: {:scalar, false},
             label: :optional,
             name: :isSelectedResponsePrimary,
             tag: 6,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:messageIDToEdit) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageIDToEdit",
             kind: {:scalar, ""},
             label: :optional,
             name: :messageIDToEdit,
             tag: 7,
             type: :string
           }}
        end

        def field_def("messageIDToEdit") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageIDToEdit",
             kind: {:scalar, ""},
             label: :optional,
             name: :messageIDToEdit,
             tag: 7,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:analyticsData) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "analyticsData",
             kind: {:scalar, nil},
             label: :optional,
             name: :analyticsData,
             tag: 8,
             type:
               {:message,
                WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SideBySideSurveyAnalyticsData}
           }}
        end

        def field_def("analyticsData") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "analyticsData",
             kind: {:scalar, nil},
             label: :optional,
             name: :analyticsData,
             tag: 8,
             type:
               {:message,
                WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SideBySideSurveyAnalyticsData}
           }}
        end

        []
      ),
      (
        def field_def(:metaAiAnalyticsData) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "metaAiAnalyticsData",
             kind: {:scalar, nil},
             label: :optional,
             name: :metaAiAnalyticsData,
             tag: 9,
             type:
               {:message,
                WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData}
           }}
        end

        def field_def("metaAiAnalyticsData") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "metaAiAnalyticsData",
             kind: {:scalar, nil},
             label: :optional,
             name: :metaAiAnalyticsData,
             tag: 9,
             type:
               {:message,
                WAWebProtobufsAICommon.BotFeedbackMessage.SideBySideSurveyMetadata.SidebySideSurveyMetaAiAnalyticsData}
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
    def default(:selectedRequestID) do
      {:ok, ""}
    end,
    def default(:surveyID) do
      {:ok, 0}
    end,
    def default(:simonSessionFbid) do
      {:ok, ""}
    end,
    def default(:responseOtid) do
      {:ok, ""}
    end,
    def default(:responseTimestampMSString) do
      {:ok, ""}
    end,
    def default(:isSelectedResponsePrimary) do
      {:ok, false}
    end,
    def default(:messageIDToEdit) do
      {:ok, ""}
    end,
    def default(:analyticsData) do
      {:ok, nil}
    end,
    def default(:metaAiAnalyticsData) do
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
