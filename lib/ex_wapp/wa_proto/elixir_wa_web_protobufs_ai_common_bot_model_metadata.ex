# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotModelMetadata do
  @moduledoc false
  defstruct modelType: nil, premiumModelStatus: nil, modelNameOverride: nil, __uf__: []

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
        |> encode_modelType(msg)
        |> encode_premiumModelStatus(msg)
        |> encode_modelNameOverride(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_modelType(acc, msg) do
        try do
          case msg.modelType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.modelType
                |> WAWebProtobufsAICommon.BotModelMetadata.ModelType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:modelType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_premiumModelStatus(acc, msg) do
        try do
          case msg.premiumModelStatus do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x10",
                msg.premiumModelStatus
                |> WAWebProtobufsAICommon.BotModelMetadata.PremiumModelStatus.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:premiumModelStatus, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_modelNameOverride(acc, msg) do
        try do
          case msg.modelNameOverride do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.modelNameOverride)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:modelNameOverride, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsAICommon.BotModelMetadata))
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
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsAICommon.BotModelMetadata.ModelType)

              {[modelType: value], rest}

            {2, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsAICommon.BotModelMetadata.PremiumModelStatus
                )

              {[premiumModelStatus: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[modelNameOverride: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufsAICommon.BotModelMetadata,
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
        1 =>
          {:modelType, {:scalar, :UNKNOWN_TYPE},
           {:enum, WAWebProtobufsAICommon.BotModelMetadata.ModelType}},
        2 =>
          {:premiumModelStatus, {:scalar, :UNKNOWN_STATUS},
           {:enum, WAWebProtobufsAICommon.BotModelMetadata.PremiumModelStatus}},
        3 => {:modelNameOverride, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        modelNameOverride: {3, {:scalar, ""}, :string},
        modelType:
          {1, {:scalar, :UNKNOWN_TYPE},
           {:enum, WAWebProtobufsAICommon.BotModelMetadata.ModelType}},
        premiumModelStatus:
          {2, {:scalar, :UNKNOWN_STATUS},
           {:enum, WAWebProtobufsAICommon.BotModelMetadata.PremiumModelStatus}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "modelType",
          kind: {:scalar, :UNKNOWN_TYPE},
          label: :optional,
          name: :modelType,
          tag: 1,
          type: {:enum, WAWebProtobufsAICommon.BotModelMetadata.ModelType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "premiumModelStatus",
          kind: {:scalar, :UNKNOWN_STATUS},
          label: :optional,
          name: :premiumModelStatus,
          tag: 2,
          type: {:enum, WAWebProtobufsAICommon.BotModelMetadata.PremiumModelStatus}
        },
        %{
          __struct__: Protox.Field,
          json_name: "modelNameOverride",
          kind: {:scalar, ""},
          label: :optional,
          name: :modelNameOverride,
          tag: 3,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:modelType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "modelType",
             kind: {:scalar, :UNKNOWN_TYPE},
             label: :optional,
             name: :modelType,
             tag: 1,
             type: {:enum, WAWebProtobufsAICommon.BotModelMetadata.ModelType}
           }}
        end

        def field_def("modelType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "modelType",
             kind: {:scalar, :UNKNOWN_TYPE},
             label: :optional,
             name: :modelType,
             tag: 1,
             type: {:enum, WAWebProtobufsAICommon.BotModelMetadata.ModelType}
           }}
        end

        []
      ),
      (
        def field_def(:premiumModelStatus) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "premiumModelStatus",
             kind: {:scalar, :UNKNOWN_STATUS},
             label: :optional,
             name: :premiumModelStatus,
             tag: 2,
             type: {:enum, WAWebProtobufsAICommon.BotModelMetadata.PremiumModelStatus}
           }}
        end

        def field_def("premiumModelStatus") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "premiumModelStatus",
             kind: {:scalar, :UNKNOWN_STATUS},
             label: :optional,
             name: :premiumModelStatus,
             tag: 2,
             type: {:enum, WAWebProtobufsAICommon.BotModelMetadata.PremiumModelStatus}
           }}
        end

        []
      ),
      (
        def field_def(:modelNameOverride) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "modelNameOverride",
             kind: {:scalar, ""},
             label: :optional,
             name: :modelNameOverride,
             tag: 3,
             type: :string
           }}
        end

        def field_def("modelNameOverride") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "modelNameOverride",
             kind: {:scalar, ""},
             label: :optional,
             name: :modelNameOverride,
             tag: 3,
             type: :string
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
    def default(:modelType) do
      {:ok, :UNKNOWN_TYPE}
    end,
    def default(:premiumModelStatus) do
      {:ok, :UNKNOWN_STATUS}
    end,
    def default(:modelNameOverride) do
      {:ok, ""}
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
