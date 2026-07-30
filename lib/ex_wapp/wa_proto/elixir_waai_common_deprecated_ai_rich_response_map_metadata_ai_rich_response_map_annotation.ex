# credo:disable-for-this-file
defmodule WAAICommonDeprecated.AIRichResponseMapMetadata.AIRichResponseMapAnnotation do
  @moduledoc false
  defstruct annotationNumber: nil,
            latitude: nil,
            longitude: nil,
            title: nil,
            body: nil,
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
        |> encode_annotationNumber(msg)
        |> encode_latitude(msg)
        |> encode_longitude(msg)
        |> encode_title(msg)
        |> encode_body(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_annotationNumber(acc, msg) do
        try do
          case msg.annotationNumber do
            nil -> acc
            _ -> [acc, "\b", Protox.Encode.encode_uint32(msg.annotationNumber)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:annotationNumber, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_latitude(acc, msg) do
        try do
          case msg.latitude do
            nil -> acc
            _ -> [acc, "\x11", Protox.Encode.encode_double(msg.latitude)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:latitude, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_longitude(acc, msg) do
        try do
          case msg.longitude do
            nil -> acc
            _ -> [acc, "\x19", Protox.Encode.encode_double(msg.longitude)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:longitude, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_title(acc, msg) do
        try do
          case msg.title do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.title)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:title, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_body(acc, msg) do
        try do
          case msg.body do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.body)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:body, "invalid field value"), __STACKTRACE__
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
            struct(WAAICommonDeprecated.AIRichResponseMapMetadata.AIRichResponseMapAnnotation)
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
              {[annotationNumber: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[latitude: value], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[longitude: value], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[title: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[body: Protox.Decode.validate_string!(delimited)], rest}

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
        WAAICommonDeprecated.AIRichResponseMapMetadata.AIRichResponseMapAnnotation,
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
        1 => {:annotationNumber, {:scalar, 0}, :uint32},
        2 => {:latitude, {:scalar, 0.0}, :double},
        3 => {:longitude, {:scalar, 0.0}, :double},
        4 => {:title, {:scalar, ""}, :string},
        5 => {:body, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        annotationNumber: {1, {:scalar, 0}, :uint32},
        body: {5, {:scalar, ""}, :string},
        latitude: {2, {:scalar, 0.0}, :double},
        longitude: {3, {:scalar, 0.0}, :double},
        title: {4, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "annotationNumber",
          kind: {:scalar, 0},
          label: :optional,
          name: :annotationNumber,
          tag: 1,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "latitude",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :latitude,
          tag: 2,
          type: :double
        },
        %{
          __struct__: Protox.Field,
          json_name: "longitude",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :longitude,
          tag: 3,
          type: :double
        },
        %{
          __struct__: Protox.Field,
          json_name: "title",
          kind: {:scalar, ""},
          label: :optional,
          name: :title,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "body",
          kind: {:scalar, ""},
          label: :optional,
          name: :body,
          tag: 5,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:annotationNumber) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "annotationNumber",
             kind: {:scalar, 0},
             label: :optional,
             name: :annotationNumber,
             tag: 1,
             type: :uint32
           }}
        end

        def field_def("annotationNumber") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "annotationNumber",
             kind: {:scalar, 0},
             label: :optional,
             name: :annotationNumber,
             tag: 1,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:latitude) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "latitude",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :latitude,
             tag: 2,
             type: :double
           }}
        end

        def field_def("latitude") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "latitude",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :latitude,
             tag: 2,
             type: :double
           }}
        end

        []
      ),
      (
        def field_def(:longitude) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "longitude",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :longitude,
             tag: 3,
             type: :double
           }}
        end

        def field_def("longitude") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "longitude",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :longitude,
             tag: 3,
             type: :double
           }}
        end

        []
      ),
      (
        def field_def(:title) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "title",
             kind: {:scalar, ""},
             label: :optional,
             name: :title,
             tag: 4,
             type: :string
           }}
        end

        def field_def("title") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "title",
             kind: {:scalar, ""},
             label: :optional,
             name: :title,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:body) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "body",
             kind: {:scalar, ""},
             label: :optional,
             name: :body,
             tag: 5,
             type: :string
           }}
        end

        def field_def("body") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "body",
             kind: {:scalar, ""},
             label: :optional,
             name: :body,
             tag: 5,
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
    def default(:annotationNumber) do
      {:ok, 0}
    end,
    def default(:latitude) do
      {:ok, 0.0}
    end,
    def default(:longitude) do
      {:ok, 0.0}
    end,
    def default(:title) do
      {:ok, ""}
    end,
    def default(:body) do
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
