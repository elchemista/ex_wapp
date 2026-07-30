# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.CustomPaymentMethod do
  @moduledoc false
  defstruct credentialID: nil, country: nil, type: nil, metadata: [], __uf__: []

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
        |> encode_credentialID(msg)
        |> encode_country(msg)
        |> encode_type(msg)
        |> encode_metadata(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_credentialID(acc, msg) do
        try do
          case msg.credentialID do
            nil -> raise Protox.RequiredFieldsError.new([:credentialID])
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.credentialID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:credentialID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_country(acc, msg) do
        try do
          case msg.country do
            nil -> raise Protox.RequiredFieldsError.new([:country])
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.country)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:country, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_type(acc, msg) do
        try do
          case msg.type do
            nil -> raise Protox.RequiredFieldsError.new([:type])
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.type)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:type, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_metadata(acc, msg) do
        try do
          case msg.metadata do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\"", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:metadata, "invalid field value"), __STACKTRACE__
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
          {msg, set_fields} =
            parse_key_value([], bytes, struct(WAWebProtobufSyncAction.CustomPaymentMethod))

          case [:credentialID, :country, :type] -- set_fields do
            [] -> msg
            missing_fields -> raise Protox.RequiredFieldsError.new(missing_fields)
          end
        end
      )
    )

    (
      @spec parse_key_value([atom], binary, struct) :: {struct, [atom]}
      defp parse_key_value(set_fields, <<>>, msg) do
        {msg, set_fields}
      end

      defp parse_key_value(set_fields, bytes, msg) do
        {new_set_fields, field, rest} =
          case Protox.Decode.parse_key(bytes) do
            {0, _, _} ->
              raise %Protox.IllegalTagError{}

            {1, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:credentialID | set_fields],
               [credentialID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:country | set_fields], [country: Protox.Decode.validate_string!(delimited)],
               rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:type | set_fields], [type: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:metadata | set_fields],
               [
                 metadata:
                   msg.metadata ++
                     [WAWebProtobufSyncAction.CustomPaymentMethodMetadata.decode!(delimited)]
               ], rest}

            {tag, wire_type, rest} ->
              {value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

              {set_fields,
               [
                 {msg.__struct__.unknown_fields_name(),
                  [value | msg.__struct__.unknown_fields(msg)]}
               ], rest}
          end

        msg_updated = struct(msg, field)
        parse_key_value(new_set_fields, rest, msg_updated)
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
        WAWebProtobufSyncAction.CustomPaymentMethod,
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
        1 => {:credentialID, {:scalar, ""}, :string},
        2 => {:country, {:scalar, ""}, :string},
        3 => {:type, {:scalar, ""}, :string},
        4 =>
          {:metadata, :unpacked, {:message, WAWebProtobufSyncAction.CustomPaymentMethodMetadata}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        country: {2, {:scalar, ""}, :string},
        credentialID: {1, {:scalar, ""}, :string},
        metadata: {4, :unpacked, {:message, WAWebProtobufSyncAction.CustomPaymentMethodMetadata}},
        type: {3, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "credentialID",
          kind: {:scalar, ""},
          label: :required,
          name: :credentialID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "country",
          kind: {:scalar, ""},
          label: :required,
          name: :country,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "type",
          kind: {:scalar, ""},
          label: :required,
          name: :type,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "metadata",
          kind: :unpacked,
          label: :repeated,
          name: :metadata,
          tag: 4,
          type: {:message, WAWebProtobufSyncAction.CustomPaymentMethodMetadata}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:credentialID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "credentialID",
             kind: {:scalar, ""},
             label: :required,
             name: :credentialID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("credentialID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "credentialID",
             kind: {:scalar, ""},
             label: :required,
             name: :credentialID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:country) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "country",
             kind: {:scalar, ""},
             label: :required,
             name: :country,
             tag: 2,
             type: :string
           }}
        end

        def field_def("country") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "country",
             kind: {:scalar, ""},
             label: :required,
             name: :country,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:type) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "type",
             kind: {:scalar, ""},
             label: :required,
             name: :type,
             tag: 3,
             type: :string
           }}
        end

        def field_def("type") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "type",
             kind: {:scalar, ""},
             label: :required,
             name: :type,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:metadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "metadata",
             kind: :unpacked,
             label: :repeated,
             name: :metadata,
             tag: 4,
             type: {:message, WAWebProtobufSyncAction.CustomPaymentMethodMetadata}
           }}
        end

        def field_def("metadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "metadata",
             kind: :unpacked,
             label: :repeated,
             name: :metadata,
             tag: 4,
             type: {:message, WAWebProtobufSyncAction.CustomPaymentMethodMetadata}
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
    @spec required_fields() :: [(:credentialID | :country) | :type]
    def required_fields() do
      [:credentialID, :country, :type]
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
    def default(:credentialID) do
      {:ok, ""}
    end,
    def default(:country) do
      {:ok, ""}
    end,
    def default(:type) do
      {:ok, ""}
    end,
    def default(:metadata) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waSyncAction",
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
