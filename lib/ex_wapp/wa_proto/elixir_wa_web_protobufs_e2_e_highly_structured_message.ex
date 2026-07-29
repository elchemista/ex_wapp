# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.HighlyStructuredMessage do
  @moduledoc false
  defstruct namespace: nil,
            elementName: nil,
            params: [],
            fallbackLg: nil,
            fallbackLc: nil,
            localizableParams: [],
            deterministicLg: nil,
            deterministicLc: nil,
            hydratedHsm: nil,
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
        |> encode_namespace(msg)
        |> encode_elementName(msg)
        |> encode_params(msg)
        |> encode_fallbackLg(msg)
        |> encode_fallbackLc(msg)
        |> encode_localizableParams(msg)
        |> encode_deterministicLg(msg)
        |> encode_deterministicLc(msg)
        |> encode_hydratedHsm(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_namespace(acc, msg) do
        try do
          case msg.namespace do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.namespace)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:namespace, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_elementName(acc, msg) do
        try do
          case msg.elementName do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.elementName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:elementName, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_params(acc, msg) do
        try do
          case msg.params do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\x1A", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:params, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fallbackLg(acc, msg) do
        try do
          case msg.fallbackLg do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.fallbackLg)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fallbackLg, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fallbackLc(acc, msg) do
        try do
          case msg.fallbackLc do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.fallbackLc)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fallbackLc, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_localizableParams(acc, msg) do
        try do
          case msg.localizableParams do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "2", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:localizableParams, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_deterministicLg(acc, msg) do
        try do
          case msg.deterministicLg do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_string(msg.deterministicLg)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deterministicLg, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_deterministicLc(acc, msg) do
        try do
          case msg.deterministicLc do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_string(msg.deterministicLc)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deterministicLc, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_hydratedHsm(acc, msg) do
        try do
          case msg.hydratedHsm do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_message(msg.hydratedHsm)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:hydratedHsm, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.HighlyStructuredMessage))
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
              {[namespace: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[elementName: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[params: msg.params ++ [Protox.Decode.validate_string!(delimited)]], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fallbackLg: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fallbackLc: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 localizableParams:
                   msg.localizableParams ++
                     [
                       WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.decode!(
                         delimited
                       )
                     ]
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[deterministicLg: Protox.Decode.validate_string!(delimited)], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[deterministicLc: Protox.Decode.validate_string!(delimited)], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 hydratedHsm:
                   Protox.MergeMessage.merge(
                     msg.hydratedHsm,
                     WAWebProtobufsE2E.TemplateMessage.decode!(delimited)
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
        WAWebProtobufsE2E.HighlyStructuredMessage,
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
        1 => {:namespace, {:scalar, ""}, :string},
        2 => {:elementName, {:scalar, ""}, :string},
        3 => {:params, :unpacked, :string},
        4 => {:fallbackLg, {:scalar, ""}, :string},
        5 => {:fallbackLc, {:scalar, ""}, :string},
        6 =>
          {:localizableParams, :unpacked,
           {:message, WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter}},
        7 => {:deterministicLg, {:scalar, ""}, :string},
        8 => {:deterministicLc, {:scalar, ""}, :string},
        9 => {:hydratedHsm, {:scalar, nil}, {:message, WAWebProtobufsE2E.TemplateMessage}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        deterministicLc: {8, {:scalar, ""}, :string},
        deterministicLg: {7, {:scalar, ""}, :string},
        elementName: {2, {:scalar, ""}, :string},
        fallbackLc: {5, {:scalar, ""}, :string},
        fallbackLg: {4, {:scalar, ""}, :string},
        hydratedHsm: {9, {:scalar, nil}, {:message, WAWebProtobufsE2E.TemplateMessage}},
        localizableParams:
          {6, :unpacked,
           {:message, WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter}},
        namespace: {1, {:scalar, ""}, :string},
        params: {3, :unpacked, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "namespace",
          kind: {:scalar, ""},
          label: :optional,
          name: :namespace,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "elementName",
          kind: {:scalar, ""},
          label: :optional,
          name: :elementName,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "params",
          kind: :unpacked,
          label: :repeated,
          name: :params,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "fallbackLg",
          kind: {:scalar, ""},
          label: :optional,
          name: :fallbackLg,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "fallbackLc",
          kind: {:scalar, ""},
          label: :optional,
          name: :fallbackLc,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "localizableParams",
          kind: :unpacked,
          label: :repeated,
          name: :localizableParams,
          tag: 6,
          type: {:message, WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter}
        },
        %{
          __struct__: Protox.Field,
          json_name: "deterministicLg",
          kind: {:scalar, ""},
          label: :optional,
          name: :deterministicLg,
          tag: 7,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "deterministicLc",
          kind: {:scalar, ""},
          label: :optional,
          name: :deterministicLc,
          tag: 8,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "hydratedHsm",
          kind: {:scalar, nil},
          label: :optional,
          name: :hydratedHsm,
          tag: 9,
          type: {:message, WAWebProtobufsE2E.TemplateMessage}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:namespace) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "namespace",
             kind: {:scalar, ""},
             label: :optional,
             name: :namespace,
             tag: 1,
             type: :string
           }}
        end

        def field_def("namespace") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "namespace",
             kind: {:scalar, ""},
             label: :optional,
             name: :namespace,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:elementName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "elementName",
             kind: {:scalar, ""},
             label: :optional,
             name: :elementName,
             tag: 2,
             type: :string
           }}
        end

        def field_def("elementName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "elementName",
             kind: {:scalar, ""},
             label: :optional,
             name: :elementName,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:params) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "params",
             kind: :unpacked,
             label: :repeated,
             name: :params,
             tag: 3,
             type: :string
           }}
        end

        def field_def("params") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "params",
             kind: :unpacked,
             label: :repeated,
             name: :params,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:fallbackLg) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fallbackLg",
             kind: {:scalar, ""},
             label: :optional,
             name: :fallbackLg,
             tag: 4,
             type: :string
           }}
        end

        def field_def("fallbackLg") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fallbackLg",
             kind: {:scalar, ""},
             label: :optional,
             name: :fallbackLg,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:fallbackLc) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fallbackLc",
             kind: {:scalar, ""},
             label: :optional,
             name: :fallbackLc,
             tag: 5,
             type: :string
           }}
        end

        def field_def("fallbackLc") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fallbackLc",
             kind: {:scalar, ""},
             label: :optional,
             name: :fallbackLc,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:localizableParams) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "localizableParams",
             kind: :unpacked,
             label: :repeated,
             name: :localizableParams,
             tag: 6,
             type: {:message, WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter}
           }}
        end

        def field_def("localizableParams") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "localizableParams",
             kind: :unpacked,
             label: :repeated,
             name: :localizableParams,
             tag: 6,
             type: {:message, WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter}
           }}
        end

        []
      ),
      (
        def field_def(:deterministicLg) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deterministicLg",
             kind: {:scalar, ""},
             label: :optional,
             name: :deterministicLg,
             tag: 7,
             type: :string
           }}
        end

        def field_def("deterministicLg") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deterministicLg",
             kind: {:scalar, ""},
             label: :optional,
             name: :deterministicLg,
             tag: 7,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:deterministicLc) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deterministicLc",
             kind: {:scalar, ""},
             label: :optional,
             name: :deterministicLc,
             tag: 8,
             type: :string
           }}
        end

        def field_def("deterministicLc") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deterministicLc",
             kind: {:scalar, ""},
             label: :optional,
             name: :deterministicLc,
             tag: 8,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:hydratedHsm) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hydratedHsm",
             kind: {:scalar, nil},
             label: :optional,
             name: :hydratedHsm,
             tag: 9,
             type: {:message, WAWebProtobufsE2E.TemplateMessage}
           }}
        end

        def field_def("hydratedHsm") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hydratedHsm",
             kind: {:scalar, nil},
             label: :optional,
             name: :hydratedHsm,
             tag: 9,
             type: {:message, WAWebProtobufsE2E.TemplateMessage}
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
    def default(:namespace) do
      {:ok, ""}
    end,
    def default(:elementName) do
      {:ok, ""}
    end,
    def default(:params) do
      {:error, :no_default_value}
    end,
    def default(:fallbackLg) do
      {:ok, ""}
    end,
    def default(:fallbackLc) do
      {:ok, ""}
    end,
    def default(:localizableParams) do
      {:error, :no_default_value}
    end,
    def default(:deterministicLg) do
      {:ok, ""}
    end,
    def default(:deterministicLc) do
      {:ok, ""}
    end,
    def default(:hydratedHsm) do
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
end
