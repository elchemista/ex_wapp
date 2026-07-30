# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata do
  @moduledoc false
  defstruct statusTitle: nil,
            statusBody: nil,
            sourcesMetadata: [],
            status: nil,
            isReasoning: nil,
            isEnhancedSearch: nil,
            sections: [],
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
        |> encode_statusTitle(msg)
        |> encode_statusBody(msg)
        |> encode_sourcesMetadata(msg)
        |> encode_status(msg)
        |> encode_isReasoning(msg)
        |> encode_isEnhancedSearch(msg)
        |> encode_sections(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_statusTitle(acc, msg) do
        try do
          case msg.statusTitle do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.statusTitle)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusTitle, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_statusBody(acc, msg) do
        try do
          case msg.statusBody do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.statusBody)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusBody, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_sourcesMetadata(acc, msg) do
        try do
          case msg.sourcesMetadata do
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
            reraise Protox.EncodingError.new(:sourcesMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_status(acc, msg) do
        try do
          case msg.status do
            nil ->
              acc

            _ ->
              [
                acc,
                " ",
                msg.status
                |> WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.PlanningStepStatus.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:status, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isReasoning(acc, msg) do
        try do
          case msg.isReasoning do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_bool(msg.isReasoning)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isReasoning, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isEnhancedSearch(acc, msg) do
        try do
          case msg.isEnhancedSearch do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_bool(msg.isEnhancedSearch)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isEnhancedSearch, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_sections(acc, msg) do
        try do
          case msg.sections do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, ":", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:sections, "invalid field value"), __STACKTRACE__
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
            struct(WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata)
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
              {[statusTitle: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[statusBody: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 sourcesMetadata:
                   msg.sourcesMetadata ++
                     [
                       WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.BotPlanningSearchSourcesMetadata.decode!(
                         delimited
                       )
                     ]
               ], rest}

            {4, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.PlanningStepStatus
                )

              {[status: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isReasoning: value], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isEnhancedSearch: value], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 sections:
                   msg.sections ++
                     [
                       WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.BotPlanningStepSectionMetadata.decode!(
                         delimited
                       )
                     ]
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
        WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata,
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
        1 => {:statusTitle, {:scalar, ""}, :string},
        2 => {:statusBody, {:scalar, ""}, :string},
        3 =>
          {:sourcesMetadata, :unpacked,
           {:message,
            WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.BotPlanningSearchSourcesMetadata}},
        4 =>
          {:status, {:scalar, :UNKNOWN},
           {:enum,
            WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.PlanningStepStatus}},
        5 => {:isReasoning, {:scalar, false}, :bool},
        6 => {:isEnhancedSearch, {:scalar, false}, :bool},
        7 =>
          {:sections, :unpacked,
           {:message,
            WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.BotPlanningStepSectionMetadata}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        isEnhancedSearch: {6, {:scalar, false}, :bool},
        isReasoning: {5, {:scalar, false}, :bool},
        sections:
          {7, :unpacked,
           {:message,
            WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.BotPlanningStepSectionMetadata}},
        sourcesMetadata:
          {3, :unpacked,
           {:message,
            WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.BotPlanningSearchSourcesMetadata}},
        status:
          {4, {:scalar, :UNKNOWN},
           {:enum,
            WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.PlanningStepStatus}},
        statusBody: {2, {:scalar, ""}, :string},
        statusTitle: {1, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "statusTitle",
          kind: {:scalar, ""},
          label: :optional,
          name: :statusTitle,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusBody",
          kind: {:scalar, ""},
          label: :optional,
          name: :statusBody,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "sourcesMetadata",
          kind: :unpacked,
          label: :repeated,
          name: :sourcesMetadata,
          tag: 3,
          type:
            {:message,
             WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.BotPlanningSearchSourcesMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "status",
          kind: {:scalar, :UNKNOWN},
          label: :optional,
          name: :status,
          tag: 4,
          type:
            {:enum,
             WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.PlanningStepStatus}
        },
        %{
          __struct__: Protox.Field,
          json_name: "isReasoning",
          kind: {:scalar, false},
          label: :optional,
          name: :isReasoning,
          tag: 5,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isEnhancedSearch",
          kind: {:scalar, false},
          label: :optional,
          name: :isEnhancedSearch,
          tag: 6,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "sections",
          kind: :unpacked,
          label: :repeated,
          name: :sections,
          tag: 7,
          type:
            {:message,
             WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.BotPlanningStepSectionMetadata}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:statusTitle) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusTitle",
             kind: {:scalar, ""},
             label: :optional,
             name: :statusTitle,
             tag: 1,
             type: :string
           }}
        end

        def field_def("statusTitle") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusTitle",
             kind: {:scalar, ""},
             label: :optional,
             name: :statusTitle,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:statusBody) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusBody",
             kind: {:scalar, ""},
             label: :optional,
             name: :statusBody,
             tag: 2,
             type: :string
           }}
        end

        def field_def("statusBody") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusBody",
             kind: {:scalar, ""},
             label: :optional,
             name: :statusBody,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:sourcesMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sourcesMetadata",
             kind: :unpacked,
             label: :repeated,
             name: :sourcesMetadata,
             tag: 3,
             type:
               {:message,
                WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.BotPlanningSearchSourcesMetadata}
           }}
        end

        def field_def("sourcesMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sourcesMetadata",
             kind: :unpacked,
             label: :repeated,
             name: :sourcesMetadata,
             tag: 3,
             type:
               {:message,
                WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.BotPlanningSearchSourcesMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:status) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "status",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :status,
             tag: 4,
             type:
               {:enum,
                WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.PlanningStepStatus}
           }}
        end

        def field_def("status") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "status",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :status,
             tag: 4,
             type:
               {:enum,
                WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.PlanningStepStatus}
           }}
        end

        []
      ),
      (
        def field_def(:isReasoning) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isReasoning",
             kind: {:scalar, false},
             label: :optional,
             name: :isReasoning,
             tag: 5,
             type: :bool
           }}
        end

        def field_def("isReasoning") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isReasoning",
             kind: {:scalar, false},
             label: :optional,
             name: :isReasoning,
             tag: 5,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isEnhancedSearch) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isEnhancedSearch",
             kind: {:scalar, false},
             label: :optional,
             name: :isEnhancedSearch,
             tag: 6,
             type: :bool
           }}
        end

        def field_def("isEnhancedSearch") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isEnhancedSearch",
             kind: {:scalar, false},
             label: :optional,
             name: :isEnhancedSearch,
             tag: 6,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:sections) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sections",
             kind: :unpacked,
             label: :repeated,
             name: :sections,
             tag: 7,
             type:
               {:message,
                WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.BotPlanningStepSectionMetadata}
           }}
        end

        def field_def("sections") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sections",
             kind: :unpacked,
             label: :repeated,
             name: :sections,
             tag: 7,
             type:
               {:message,
                WAWebProtobufsAICommon.BotProgressIndicatorMetadata.BotPlanningStepMetadata.BotPlanningStepSectionMetadata}
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
    def default(:statusTitle) do
      {:ok, ""}
    end,
    def default(:statusBody) do
      {:ok, ""}
    end,
    def default(:sourcesMetadata) do
      {:error, :no_default_value}
    end,
    def default(:status) do
      {:ok, :UNKNOWN}
    end,
    def default(:isReasoning) do
      {:ok, false}
    end,
    def default(:isEnhancedSearch) do
      {:ok, false}
    end,
    def default(:sections) do
      {:error, :no_default_value}
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
