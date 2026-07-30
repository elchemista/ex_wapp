# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PollCreationMessage do
  @moduledoc false
  defstruct encKey: nil,
            name: nil,
            options: [],
            selectableOptionsCount: nil,
            contextInfo: nil,
            pollContentType: nil,
            pollType: nil,
            correctAnswer: nil,
            endTime: nil,
            hideParticipantName: nil,
            allowAddOption: nil,
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
        |> encode_encKey(msg)
        |> encode_name(msg)
        |> encode_options(msg)
        |> encode_selectableOptionsCount(msg)
        |> encode_contextInfo(msg)
        |> encode_pollContentType(msg)
        |> encode_pollType(msg)
        |> encode_correctAnswer(msg)
        |> encode_endTime(msg)
        |> encode_hideParticipantName(msg)
        |> encode_allowAddOption(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_encKey(acc, msg) do
        try do
          case msg.encKey do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_bytes(msg.encKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:encKey, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_name(acc, msg) do
        try do
          case msg.name do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.name)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:name, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_options(acc, msg) do
        try do
          case msg.options do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\x1A", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:options, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_selectableOptionsCount(acc, msg) do
        try do
          case msg.selectableOptionsCount do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_uint32(msg.selectableOptionsCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:selectableOptionsCount, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_contextInfo(acc, msg) do
        try do
          case msg.contextInfo do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_message(msg.contextInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contextInfo, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pollContentType(acc, msg) do
        try do
          case msg.pollContentType do
            nil ->
              acc

            _ ->
              [
                acc,
                "0",
                msg.pollContentType
                |> WAWebProtobufsE2E.PollContentType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollContentType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pollType(acc, msg) do
        try do
          case msg.pollType do
            nil ->
              acc

            _ ->
              [
                acc,
                "8",
                msg.pollType |> WAWebProtobufsE2E.PollType.encode() |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_correctAnswer(acc, msg) do
        try do
          case msg.correctAnswer do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_message(msg.correctAnswer)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:correctAnswer, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_endTime(acc, msg) do
        try do
          case msg.endTime do
            nil -> acc
            _ -> [acc, "H", Protox.Encode.encode_int64(msg.endTime)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:endTime, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_hideParticipantName(acc, msg) do
        try do
          case msg.hideParticipantName do
            nil -> acc
            _ -> [acc, "P", Protox.Encode.encode_bool(msg.hideParticipantName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:hideParticipantName, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_allowAddOption(acc, msg) do
        try do
          case msg.allowAddOption do
            nil -> acc
            _ -> [acc, "X", Protox.Encode.encode_bool(msg.allowAddOption)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:allowAddOption, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.PollCreationMessage))
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
              {[encKey: delimited], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[name: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 options:
                   msg.options ++
                     [WAWebProtobufsE2E.PollCreationMessage.Option.decode!(delimited)]
               ], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[selectableOptionsCount: value], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 contextInfo:
                   Protox.MergeMessage.merge(
                     msg.contextInfo,
                     WAWebProtobufsE2E.ContextInfo.decode!(delimited)
                   )
               ], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.PollContentType)
              {[pollContentType: value], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.PollType)
              {[pollType: value], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 correctAnswer:
                   Protox.MergeMessage.merge(
                     msg.correctAnswer,
                     WAWebProtobufsE2E.PollCreationMessage.Option.decode!(delimited)
                   )
               ], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[endTime: value], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[hideParticipantName: value], rest}

            {11, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[allowAddOption: value], rest}

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
        WAWebProtobufsE2E.PollCreationMessage,
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
        1 => {:encKey, {:scalar, ""}, :bytes},
        2 => {:name, {:scalar, ""}, :string},
        3 => {:options, :unpacked, {:message, WAWebProtobufsE2E.PollCreationMessage.Option}},
        4 => {:selectableOptionsCount, {:scalar, 0}, :uint32},
        5 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        6 =>
          {:pollContentType, {:scalar, :UNKNOWN_POLL_CONTENT_TYPE},
           {:enum, WAWebProtobufsE2E.PollContentType}},
        7 => {:pollType, {:scalar, :POLL}, {:enum, WAWebProtobufsE2E.PollType}},
        8 =>
          {:correctAnswer, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PollCreationMessage.Option}},
        9 => {:endTime, {:scalar, 0}, :int64},
        10 => {:hideParticipantName, {:scalar, false}, :bool},
        11 => {:allowAddOption, {:scalar, false}, :bool}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        allowAddOption: {11, {:scalar, false}, :bool},
        contextInfo: {5, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        correctAnswer:
          {8, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollCreationMessage.Option}},
        encKey: {1, {:scalar, ""}, :bytes},
        endTime: {9, {:scalar, 0}, :int64},
        hideParticipantName: {10, {:scalar, false}, :bool},
        name: {2, {:scalar, ""}, :string},
        options: {3, :unpacked, {:message, WAWebProtobufsE2E.PollCreationMessage.Option}},
        pollContentType:
          {6, {:scalar, :UNKNOWN_POLL_CONTENT_TYPE}, {:enum, WAWebProtobufsE2E.PollContentType}},
        pollType: {7, {:scalar, :POLL}, {:enum, WAWebProtobufsE2E.PollType}},
        selectableOptionsCount: {4, {:scalar, 0}, :uint32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "encKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :encKey,
          tag: 1,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "name",
          kind: {:scalar, ""},
          label: :optional,
          name: :name,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "options",
          kind: :unpacked,
          label: :repeated,
          name: :options,
          tag: 3,
          type: {:message, WAWebProtobufsE2E.PollCreationMessage.Option}
        },
        %{
          __struct__: Protox.Field,
          json_name: "selectableOptionsCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :selectableOptionsCount,
          tag: 4,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "contextInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :contextInfo,
          tag: 5,
          type: {:message, WAWebProtobufsE2E.ContextInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollContentType",
          kind: {:scalar, :UNKNOWN_POLL_CONTENT_TYPE},
          label: :optional,
          name: :pollContentType,
          tag: 6,
          type: {:enum, WAWebProtobufsE2E.PollContentType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pollType",
          kind: {:scalar, :POLL},
          label: :optional,
          name: :pollType,
          tag: 7,
          type: {:enum, WAWebProtobufsE2E.PollType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "correctAnswer",
          kind: {:scalar, nil},
          label: :optional,
          name: :correctAnswer,
          tag: 8,
          type: {:message, WAWebProtobufsE2E.PollCreationMessage.Option}
        },
        %{
          __struct__: Protox.Field,
          json_name: "endTime",
          kind: {:scalar, 0},
          label: :optional,
          name: :endTime,
          tag: 9,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "hideParticipantName",
          kind: {:scalar, false},
          label: :optional,
          name: :hideParticipantName,
          tag: 10,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "allowAddOption",
          kind: {:scalar, false},
          label: :optional,
          name: :allowAddOption,
          tag: 11,
          type: :bool
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:encKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "encKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :encKey,
             tag: 1,
             type: :bytes
           }}
        end

        def field_def("encKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "encKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :encKey,
             tag: 1,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:name) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "name",
             kind: {:scalar, ""},
             label: :optional,
             name: :name,
             tag: 2,
             type: :string
           }}
        end

        def field_def("name") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "name",
             kind: {:scalar, ""},
             label: :optional,
             name: :name,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:options) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "options",
             kind: :unpacked,
             label: :repeated,
             name: :options,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.PollCreationMessage.Option}
           }}
        end

        def field_def("options") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "options",
             kind: :unpacked,
             label: :repeated,
             name: :options,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.PollCreationMessage.Option}
           }}
        end

        []
      ),
      (
        def field_def(:selectableOptionsCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "selectableOptionsCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :selectableOptionsCount,
             tag: 4,
             type: :uint32
           }}
        end

        def field_def("selectableOptionsCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "selectableOptionsCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :selectableOptionsCount,
             tag: 4,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:contextInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contextInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :contextInfo,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.ContextInfo}
           }}
        end

        def field_def("contextInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contextInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :contextInfo,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.ContextInfo}
           }}
        end

        []
      ),
      (
        def field_def(:pollContentType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollContentType",
             kind: {:scalar, :UNKNOWN_POLL_CONTENT_TYPE},
             label: :optional,
             name: :pollContentType,
             tag: 6,
             type: {:enum, WAWebProtobufsE2E.PollContentType}
           }}
        end

        def field_def("pollContentType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollContentType",
             kind: {:scalar, :UNKNOWN_POLL_CONTENT_TYPE},
             label: :optional,
             name: :pollContentType,
             tag: 6,
             type: {:enum, WAWebProtobufsE2E.PollContentType}
           }}
        end

        []
      ),
      (
        def field_def(:pollType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollType",
             kind: {:scalar, :POLL},
             label: :optional,
             name: :pollType,
             tag: 7,
             type: {:enum, WAWebProtobufsE2E.PollType}
           }}
        end

        def field_def("pollType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollType",
             kind: {:scalar, :POLL},
             label: :optional,
             name: :pollType,
             tag: 7,
             type: {:enum, WAWebProtobufsE2E.PollType}
           }}
        end

        []
      ),
      (
        def field_def(:correctAnswer) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "correctAnswer",
             kind: {:scalar, nil},
             label: :optional,
             name: :correctAnswer,
             tag: 8,
             type: {:message, WAWebProtobufsE2E.PollCreationMessage.Option}
           }}
        end

        def field_def("correctAnswer") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "correctAnswer",
             kind: {:scalar, nil},
             label: :optional,
             name: :correctAnswer,
             tag: 8,
             type: {:message, WAWebProtobufsE2E.PollCreationMessage.Option}
           }}
        end

        []
      ),
      (
        def field_def(:endTime) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "endTime",
             kind: {:scalar, 0},
             label: :optional,
             name: :endTime,
             tag: 9,
             type: :int64
           }}
        end

        def field_def("endTime") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "endTime",
             kind: {:scalar, 0},
             label: :optional,
             name: :endTime,
             tag: 9,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:hideParticipantName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hideParticipantName",
             kind: {:scalar, false},
             label: :optional,
             name: :hideParticipantName,
             tag: 10,
             type: :bool
           }}
        end

        def field_def("hideParticipantName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hideParticipantName",
             kind: {:scalar, false},
             label: :optional,
             name: :hideParticipantName,
             tag: 10,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:allowAddOption) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "allowAddOption",
             kind: {:scalar, false},
             label: :optional,
             name: :allowAddOption,
             tag: 11,
             type: :bool
           }}
        end

        def field_def("allowAddOption") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "allowAddOption",
             kind: {:scalar, false},
             label: :optional,
             name: :allowAddOption,
             tag: 11,
             type: :bool
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
    def default(:encKey) do
      {:ok, ""}
    end,
    def default(:name) do
      {:ok, ""}
    end,
    def default(:options) do
      {:error, :no_default_value}
    end,
    def default(:selectableOptionsCount) do
      {:ok, 0}
    end,
    def default(:contextInfo) do
      {:ok, nil}
    end,
    def default(:pollContentType) do
      {:ok, :UNKNOWN_POLL_CONTENT_TYPE}
    end,
    def default(:pollType) do
      {:ok, :POLL}
    end,
    def default(:correctAnswer) do
      {:ok, nil}
    end,
    def default(:endTime) do
      {:ok, 0}
    end,
    def default(:hideParticipantName) do
      {:ok, false}
    end,
    def default(:allowAddOption) do
      {:ok, false}
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
        go_package: "go.mau.fi/whatsmeow/proto/waE2E",
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
