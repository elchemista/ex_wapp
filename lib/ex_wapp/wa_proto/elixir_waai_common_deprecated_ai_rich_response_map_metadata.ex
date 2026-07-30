# credo:disable-for-this-file
defmodule WAAICommonDeprecated.AIRichResponseMapMetadata do
  @moduledoc false
  defstruct centerLatitude: nil,
            centerLongitude: nil,
            latitudeDelta: nil,
            longitudeDelta: nil,
            annotations: [],
            showInfoList: nil,
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
        |> encode_centerLatitude(msg)
        |> encode_centerLongitude(msg)
        |> encode_latitudeDelta(msg)
        |> encode_longitudeDelta(msg)
        |> encode_annotations(msg)
        |> encode_showInfoList(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_centerLatitude(acc, msg) do
        try do
          case msg.centerLatitude do
            nil -> acc
            _ -> [acc, "\t", Protox.Encode.encode_double(msg.centerLatitude)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:centerLatitude, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_centerLongitude(acc, msg) do
        try do
          case msg.centerLongitude do
            nil -> acc
            _ -> [acc, "\x11", Protox.Encode.encode_double(msg.centerLongitude)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:centerLongitude, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_latitudeDelta(acc, msg) do
        try do
          case msg.latitudeDelta do
            nil -> acc
            _ -> [acc, "\x19", Protox.Encode.encode_double(msg.latitudeDelta)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:latitudeDelta, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_longitudeDelta(acc, msg) do
        try do
          case msg.longitudeDelta do
            nil -> acc
            _ -> [acc, "!", Protox.Encode.encode_double(msg.longitudeDelta)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:longitudeDelta, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_annotations(acc, msg) do
        try do
          case msg.annotations do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "*", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:annotations, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_showInfoList(acc, msg) do
        try do
          case msg.showInfoList do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_bool(msg.showInfoList)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:showInfoList, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAAICommonDeprecated.AIRichResponseMapMetadata))
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
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[centerLatitude: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[centerLongitude: value], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[latitudeDelta: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[longitudeDelta: value], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 annotations:
                   msg.annotations ++
                     [
                       WAAICommonDeprecated.AIRichResponseMapMetadata.AIRichResponseMapAnnotation.decode!(
                         delimited
                       )
                     ]
               ], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[showInfoList: value], rest}

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
        WAAICommonDeprecated.AIRichResponseMapMetadata,
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
        1 => {:centerLatitude, {:scalar, 0.0}, :double},
        2 => {:centerLongitude, {:scalar, 0.0}, :double},
        3 => {:latitudeDelta, {:scalar, 0.0}, :double},
        4 => {:longitudeDelta, {:scalar, 0.0}, :double},
        5 =>
          {:annotations, :unpacked,
           {:message, WAAICommonDeprecated.AIRichResponseMapMetadata.AIRichResponseMapAnnotation}},
        6 => {:showInfoList, {:scalar, false}, :bool}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        annotations:
          {5, :unpacked,
           {:message, WAAICommonDeprecated.AIRichResponseMapMetadata.AIRichResponseMapAnnotation}},
        centerLatitude: {1, {:scalar, 0.0}, :double},
        centerLongitude: {2, {:scalar, 0.0}, :double},
        latitudeDelta: {3, {:scalar, 0.0}, :double},
        longitudeDelta: {4, {:scalar, 0.0}, :double},
        showInfoList: {6, {:scalar, false}, :bool}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "centerLatitude",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :centerLatitude,
          tag: 1,
          type: :double
        },
        %{
          __struct__: Protox.Field,
          json_name: "centerLongitude",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :centerLongitude,
          tag: 2,
          type: :double
        },
        %{
          __struct__: Protox.Field,
          json_name: "latitudeDelta",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :latitudeDelta,
          tag: 3,
          type: :double
        },
        %{
          __struct__: Protox.Field,
          json_name: "longitudeDelta",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :longitudeDelta,
          tag: 4,
          type: :double
        },
        %{
          __struct__: Protox.Field,
          json_name: "annotations",
          kind: :unpacked,
          label: :repeated,
          name: :annotations,
          tag: 5,
          type:
            {:message, WAAICommonDeprecated.AIRichResponseMapMetadata.AIRichResponseMapAnnotation}
        },
        %{
          __struct__: Protox.Field,
          json_name: "showInfoList",
          kind: {:scalar, false},
          label: :optional,
          name: :showInfoList,
          tag: 6,
          type: :bool
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:centerLatitude) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "centerLatitude",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :centerLatitude,
             tag: 1,
             type: :double
           }}
        end

        def field_def("centerLatitude") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "centerLatitude",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :centerLatitude,
             tag: 1,
             type: :double
           }}
        end

        []
      ),
      (
        def field_def(:centerLongitude) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "centerLongitude",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :centerLongitude,
             tag: 2,
             type: :double
           }}
        end

        def field_def("centerLongitude") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "centerLongitude",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :centerLongitude,
             tag: 2,
             type: :double
           }}
        end

        []
      ),
      (
        def field_def(:latitudeDelta) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "latitudeDelta",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :latitudeDelta,
             tag: 3,
             type: :double
           }}
        end

        def field_def("latitudeDelta") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "latitudeDelta",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :latitudeDelta,
             tag: 3,
             type: :double
           }}
        end

        []
      ),
      (
        def field_def(:longitudeDelta) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "longitudeDelta",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :longitudeDelta,
             tag: 4,
             type: :double
           }}
        end

        def field_def("longitudeDelta") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "longitudeDelta",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :longitudeDelta,
             tag: 4,
             type: :double
           }}
        end

        []
      ),
      (
        def field_def(:annotations) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "annotations",
             kind: :unpacked,
             label: :repeated,
             name: :annotations,
             tag: 5,
             type:
               {:message,
                WAAICommonDeprecated.AIRichResponseMapMetadata.AIRichResponseMapAnnotation}
           }}
        end

        def field_def("annotations") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "annotations",
             kind: :unpacked,
             label: :repeated,
             name: :annotations,
             tag: 5,
             type:
               {:message,
                WAAICommonDeprecated.AIRichResponseMapMetadata.AIRichResponseMapAnnotation}
           }}
        end

        []
      ),
      (
        def field_def(:showInfoList) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "showInfoList",
             kind: {:scalar, false},
             label: :optional,
             name: :showInfoList,
             tag: 6,
             type: :bool
           }}
        end

        def field_def("showInfoList") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "showInfoList",
             kind: {:scalar, false},
             label: :optional,
             name: :showInfoList,
             tag: 6,
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
    def default(:centerLatitude) do
      {:ok, 0.0}
    end,
    def default(:centerLongitude) do
      {:ok, 0.0}
    end,
    def default(:latitudeDelta) do
      {:ok, 0.0}
    end,
    def default(:longitudeDelta) do
      {:ok, 0.0}
    end,
    def default(:annotations) do
      {:error, :no_default_value}
    end,
    def default(:showInfoList) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waAICommonDeprecated",
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
