# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.MMSThumbnailMetadata do
  @moduledoc false
  defstruct thumbnailDirectPath: nil,
            thumbnailSHA256: nil,
            thumbnailEncSHA256: nil,
            mediaKey: nil,
            mediaKeyTimestamp: nil,
            thumbnailHeight: nil,
            thumbnailWidth: nil,
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
        |> encode_thumbnailDirectPath(msg)
        |> encode_thumbnailSHA256(msg)
        |> encode_thumbnailEncSHA256(msg)
        |> encode_mediaKey(msg)
        |> encode_mediaKeyTimestamp(msg)
        |> encode_thumbnailHeight(msg)
        |> encode_thumbnailWidth(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_thumbnailDirectPath(acc, msg) do
        try do
          case msg.thumbnailDirectPath do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.thumbnailDirectPath)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailDirectPath, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailSHA256(acc, msg) do
        try do
          case msg.thumbnailSHA256 do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_bytes(msg.thumbnailSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailEncSHA256(acc, msg) do
        try do
          case msg.thumbnailEncSHA256 do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_bytes(msg.thumbnailEncSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailEncSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_mediaKey(acc, msg) do
        try do
          case msg.mediaKey do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_bytes(msg.mediaKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaKey, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaKeyTimestamp(acc, msg) do
        try do
          case msg.mediaKeyTimestamp do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_int64(msg.mediaKeyTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaKeyTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailHeight(acc, msg) do
        try do
          case msg.thumbnailHeight do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_uint32(msg.thumbnailHeight)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailHeight, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailWidth(acc, msg) do
        try do
          case msg.thumbnailWidth do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_uint32(msg.thumbnailWidth)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailWidth, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.MMSThumbnailMetadata))
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
              {[thumbnailDirectPath: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnailSHA256: delimited], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnailEncSHA256: delimited], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mediaKey: delimited], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[mediaKeyTimestamp: value], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[thumbnailHeight: value], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[thumbnailWidth: value], rest}

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
        WAWebProtobufsE2E.MMSThumbnailMetadata,
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
        1 => {:thumbnailDirectPath, {:scalar, ""}, :string},
        2 => {:thumbnailSHA256, {:scalar, ""}, :bytes},
        3 => {:thumbnailEncSHA256, {:scalar, ""}, :bytes},
        4 => {:mediaKey, {:scalar, ""}, :bytes},
        5 => {:mediaKeyTimestamp, {:scalar, 0}, :int64},
        6 => {:thumbnailHeight, {:scalar, 0}, :uint32},
        7 => {:thumbnailWidth, {:scalar, 0}, :uint32}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        mediaKey: {4, {:scalar, ""}, :bytes},
        mediaKeyTimestamp: {5, {:scalar, 0}, :int64},
        thumbnailDirectPath: {1, {:scalar, ""}, :string},
        thumbnailEncSHA256: {3, {:scalar, ""}, :bytes},
        thumbnailHeight: {6, {:scalar, 0}, :uint32},
        thumbnailSHA256: {2, {:scalar, ""}, :bytes},
        thumbnailWidth: {7, {:scalar, 0}, :uint32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailDirectPath",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnailDirectPath,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnailSHA256,
          tag: 2,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailEncSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnailEncSHA256,
          tag: 3,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :mediaKey,
          tag: 4,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaKeyTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :mediaKeyTimestamp,
          tag: 5,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailHeight",
          kind: {:scalar, 0},
          label: :optional,
          name: :thumbnailHeight,
          tag: 6,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailWidth",
          kind: {:scalar, 0},
          label: :optional,
          name: :thumbnailWidth,
          tag: 7,
          type: :uint32
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:thumbnailDirectPath) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailDirectPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailDirectPath,
             tag: 1,
             type: :string
           }}
        end

        def field_def("thumbnailDirectPath") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailDirectPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailDirectPath,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailSHA256,
             tag: 2,
             type: :bytes
           }}
        end

        def field_def("thumbnailSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailSHA256,
             tag: 2,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailEncSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailEncSHA256,
             tag: 3,
             type: :bytes
           }}
        end

        def field_def("thumbnailEncSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailEncSHA256,
             tag: 3,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:mediaKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :mediaKey,
             tag: 4,
             type: :bytes
           }}
        end

        def field_def("mediaKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :mediaKey,
             tag: 4,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:mediaKeyTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaKeyTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :mediaKeyTimestamp,
             tag: 5,
             type: :int64
           }}
        end

        def field_def("mediaKeyTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaKeyTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :mediaKeyTimestamp,
             tag: 5,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailHeight) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailHeight",
             kind: {:scalar, 0},
             label: :optional,
             name: :thumbnailHeight,
             tag: 6,
             type: :uint32
           }}
        end

        def field_def("thumbnailHeight") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailHeight",
             kind: {:scalar, 0},
             label: :optional,
             name: :thumbnailHeight,
             tag: 6,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailWidth) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailWidth",
             kind: {:scalar, 0},
             label: :optional,
             name: :thumbnailWidth,
             tag: 7,
             type: :uint32
           }}
        end

        def field_def("thumbnailWidth") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailWidth",
             kind: {:scalar, 0},
             label: :optional,
             name: :thumbnailWidth,
             tag: 7,
             type: :uint32
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
    def default(:thumbnailDirectPath) do
      {:ok, ""}
    end,
    def default(:thumbnailSHA256) do
      {:ok, ""}
    end,
    def default(:thumbnailEncSHA256) do
      {:ok, ""}
    end,
    def default(:mediaKey) do
      {:ok, ""}
    end,
    def default(:mediaKeyTimestamp) do
      {:ok, 0}
    end,
    def default(:thumbnailHeight) do
      {:ok, 0}
    end,
    def default(:thumbnailWidth) do
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
