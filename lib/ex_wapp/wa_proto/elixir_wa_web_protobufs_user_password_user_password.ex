# credo:disable-for-this-file
defmodule WAWebProtobufsUserPassword.UserPassword do
  @moduledoc false
  defstruct encoding: nil, transformer: nil, transformerArg: [], transformedData: nil, __uf__: []

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
        |> encode_encoding(msg)
        |> encode_transformer(msg)
        |> encode_transformerArg(msg)
        |> encode_transformedData(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_encoding(acc, msg) do
        try do
          case msg.encoding do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.encoding
                |> WAWebProtobufsUserPassword.UserPassword.Encoding.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:encoding, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_transformer(acc, msg) do
        try do
          case msg.transformer do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x10",
                msg.transformer
                |> WAWebProtobufsUserPassword.UserPassword.Transformer.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:transformer, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_transformerArg(acc, msg) do
        try do
          case msg.transformerArg do
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
            reraise Protox.EncodingError.new(:transformerArg, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_transformedData(acc, msg) do
        try do
          case msg.transformedData do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_bytes(msg.transformedData)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:transformedData, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsUserPassword.UserPassword))
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
                Protox.Decode.parse_enum(bytes, WAWebProtobufsUserPassword.UserPassword.Encoding)

              {[encoding: value], rest}

            {2, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsUserPassword.UserPassword.Transformer
                )

              {[transformer: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 transformerArg:
                   msg.transformerArg ++
                     [WAWebProtobufsUserPassword.UserPassword.TransformerArg.decode!(delimited)]
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[transformedData: delimited], rest}

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
        WAWebProtobufsUserPassword.UserPassword,
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
          {:encoding, {:scalar, :UTF8}, {:enum, WAWebProtobufsUserPassword.UserPassword.Encoding}},
        2 =>
          {:transformer, {:scalar, :NONE},
           {:enum, WAWebProtobufsUserPassword.UserPassword.Transformer}},
        3 =>
          {:transformerArg, :unpacked,
           {:message, WAWebProtobufsUserPassword.UserPassword.TransformerArg}},
        4 => {:transformedData, {:scalar, ""}, :bytes}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        encoding:
          {1, {:scalar, :UTF8}, {:enum, WAWebProtobufsUserPassword.UserPassword.Encoding}},
        transformedData: {4, {:scalar, ""}, :bytes},
        transformer:
          {2, {:scalar, :NONE}, {:enum, WAWebProtobufsUserPassword.UserPassword.Transformer}},
        transformerArg:
          {3, :unpacked, {:message, WAWebProtobufsUserPassword.UserPassword.TransformerArg}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "encoding",
          kind: {:scalar, :UTF8},
          label: :optional,
          name: :encoding,
          tag: 1,
          type: {:enum, WAWebProtobufsUserPassword.UserPassword.Encoding}
        },
        %{
          __struct__: Protox.Field,
          json_name: "transformer",
          kind: {:scalar, :NONE},
          label: :optional,
          name: :transformer,
          tag: 2,
          type: {:enum, WAWebProtobufsUserPassword.UserPassword.Transformer}
        },
        %{
          __struct__: Protox.Field,
          json_name: "transformerArg",
          kind: :unpacked,
          label: :repeated,
          name: :transformerArg,
          tag: 3,
          type: {:message, WAWebProtobufsUserPassword.UserPassword.TransformerArg}
        },
        %{
          __struct__: Protox.Field,
          json_name: "transformedData",
          kind: {:scalar, ""},
          label: :optional,
          name: :transformedData,
          tag: 4,
          type: :bytes
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:encoding) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "encoding",
             kind: {:scalar, :UTF8},
             label: :optional,
             name: :encoding,
             tag: 1,
             type: {:enum, WAWebProtobufsUserPassword.UserPassword.Encoding}
           }}
        end

        def field_def("encoding") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "encoding",
             kind: {:scalar, :UTF8},
             label: :optional,
             name: :encoding,
             tag: 1,
             type: {:enum, WAWebProtobufsUserPassword.UserPassword.Encoding}
           }}
        end

        []
      ),
      (
        def field_def(:transformer) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "transformer",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :transformer,
             tag: 2,
             type: {:enum, WAWebProtobufsUserPassword.UserPassword.Transformer}
           }}
        end

        def field_def("transformer") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "transformer",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :transformer,
             tag: 2,
             type: {:enum, WAWebProtobufsUserPassword.UserPassword.Transformer}
           }}
        end

        []
      ),
      (
        def field_def(:transformerArg) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "transformerArg",
             kind: :unpacked,
             label: :repeated,
             name: :transformerArg,
             tag: 3,
             type: {:message, WAWebProtobufsUserPassword.UserPassword.TransformerArg}
           }}
        end

        def field_def("transformerArg") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "transformerArg",
             kind: :unpacked,
             label: :repeated,
             name: :transformerArg,
             tag: 3,
             type: {:message, WAWebProtobufsUserPassword.UserPassword.TransformerArg}
           }}
        end

        []
      ),
      (
        def field_def(:transformedData) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "transformedData",
             kind: {:scalar, ""},
             label: :optional,
             name: :transformedData,
             tag: 4,
             type: :bytes
           }}
        end

        def field_def("transformedData") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "transformedData",
             kind: {:scalar, ""},
             label: :optional,
             name: :transformedData,
             tag: 4,
             type: :bytes
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
    def default(:encoding) do
      {:ok, :UTF8}
    end,
    def default(:transformer) do
      {:ok, :NONE}
    end,
    def default(:transformerArg) do
      {:error, :no_default_value}
    end,
    def default(:transformedData) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waUserPassword",
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
end
