# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FlowResponsesCsvBundle do
  @moduledoc false
  defstruct flowID: nil,
            galaxyFlowDownloadRequestID: nil,
            fileName: nil,
            mimetype: nil,
            fileSHA256: nil,
            mediaKey: nil,
            fileEncSHA256: nil,
            directPath: nil,
            mediaKeyTimestamp: nil,
            fileLength: nil,
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
        |> encode_flowID(msg)
        |> encode_galaxyFlowDownloadRequestID(msg)
        |> encode_fileName(msg)
        |> encode_mimetype(msg)
        |> encode_fileSHA256(msg)
        |> encode_mediaKey(msg)
        |> encode_fileEncSHA256(msg)
        |> encode_directPath(msg)
        |> encode_mediaKeyTimestamp(msg)
        |> encode_fileLength(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_flowID(acc, msg) do
        try do
          case msg.flowID do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.flowID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:flowID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_galaxyFlowDownloadRequestID(acc, msg) do
        try do
          case msg.galaxyFlowDownloadRequestID do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.galaxyFlowDownloadRequestID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:galaxyFlowDownloadRequestID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_fileName(acc, msg) do
        try do
          case msg.fileName do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.fileName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileName, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mimetype(acc, msg) do
        try do
          case msg.mimetype do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.mimetype)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mimetype, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fileSHA256(acc, msg) do
        try do
          case msg.fileSHA256 do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_bytes(msg.fileSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileSHA256, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaKey(acc, msg) do
        try do
          case msg.mediaKey do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_bytes(msg.mediaKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaKey, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fileEncSHA256(acc, msg) do
        try do
          case msg.fileEncSHA256 do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_bytes(msg.fileEncSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileEncSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_directPath(acc, msg) do
        try do
          case msg.directPath do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_string(msg.directPath)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:directPath, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaKeyTimestamp(acc, msg) do
        try do
          case msg.mediaKeyTimestamp do
            nil -> acc
            _ -> [acc, "H", Protox.Encode.encode_int64(msg.mediaKeyTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaKeyTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_fileLength(acc, msg) do
        try do
          case msg.fileLength do
            nil -> acc
            _ -> [acc, "P", Protox.Encode.encode_uint64(msg.fileLength)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileLength, "invalid field value"), __STACKTRACE__
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
            struct(
              WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FlowResponsesCsvBundle
            )
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
              {[flowID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[galaxyFlowDownloadRequestID: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fileName: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mimetype: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fileSHA256: delimited], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mediaKey: delimited], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fileEncSHA256: delimited], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[directPath: Protox.Decode.validate_string!(delimited)], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[mediaKeyTimestamp: value], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[fileLength: value], rest}

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
        WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FlowResponsesCsvBundle,
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
        1 => {:flowID, {:scalar, ""}, :string},
        2 => {:galaxyFlowDownloadRequestID, {:scalar, ""}, :string},
        3 => {:fileName, {:scalar, ""}, :string},
        4 => {:mimetype, {:scalar, ""}, :string},
        5 => {:fileSHA256, {:scalar, ""}, :bytes},
        6 => {:mediaKey, {:scalar, ""}, :bytes},
        7 => {:fileEncSHA256, {:scalar, ""}, :bytes},
        8 => {:directPath, {:scalar, ""}, :string},
        9 => {:mediaKeyTimestamp, {:scalar, 0}, :int64},
        10 => {:fileLength, {:scalar, 0}, :uint64}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        directPath: {8, {:scalar, ""}, :string},
        fileEncSHA256: {7, {:scalar, ""}, :bytes},
        fileLength: {10, {:scalar, 0}, :uint64},
        fileName: {3, {:scalar, ""}, :string},
        fileSHA256: {5, {:scalar, ""}, :bytes},
        flowID: {1, {:scalar, ""}, :string},
        galaxyFlowDownloadRequestID: {2, {:scalar, ""}, :string},
        mediaKey: {6, {:scalar, ""}, :bytes},
        mediaKeyTimestamp: {9, {:scalar, 0}, :int64},
        mimetype: {4, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "flowID",
          kind: {:scalar, ""},
          label: :optional,
          name: :flowID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "galaxyFlowDownloadRequestID",
          kind: {:scalar, ""},
          label: :optional,
          name: :galaxyFlowDownloadRequestID,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileName",
          kind: {:scalar, ""},
          label: :optional,
          name: :fileName,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "mimetype",
          kind: {:scalar, ""},
          label: :optional,
          name: :mimetype,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :fileSHA256,
          tag: 5,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :mediaKey,
          tag: 6,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileEncSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :fileEncSHA256,
          tag: 7,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "directPath",
          kind: {:scalar, ""},
          label: :optional,
          name: :directPath,
          tag: 8,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaKeyTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :mediaKeyTimestamp,
          tag: 9,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileLength",
          kind: {:scalar, 0},
          label: :optional,
          name: :fileLength,
          tag: 10,
          type: :uint64
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:flowID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "flowID",
             kind: {:scalar, ""},
             label: :optional,
             name: :flowID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("flowID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "flowID",
             kind: {:scalar, ""},
             label: :optional,
             name: :flowID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:galaxyFlowDownloadRequestID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "galaxyFlowDownloadRequestID",
             kind: {:scalar, ""},
             label: :optional,
             name: :galaxyFlowDownloadRequestID,
             tag: 2,
             type: :string
           }}
        end

        def field_def("galaxyFlowDownloadRequestID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "galaxyFlowDownloadRequestID",
             kind: {:scalar, ""},
             label: :optional,
             name: :galaxyFlowDownloadRequestID,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:fileName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileName",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileName,
             tag: 3,
             type: :string
           }}
        end

        def field_def("fileName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileName",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileName,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:mimetype) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mimetype",
             kind: {:scalar, ""},
             label: :optional,
             name: :mimetype,
             tag: 4,
             type: :string
           }}
        end

        def field_def("mimetype") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mimetype",
             kind: {:scalar, ""},
             label: :optional,
             name: :mimetype,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:fileSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileSHA256,
             tag: 5,
             type: :bytes
           }}
        end

        def field_def("fileSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileSHA256,
             tag: 5,
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
             tag: 6,
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
             tag: 6,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:fileEncSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileEncSHA256,
             tag: 7,
             type: :bytes
           }}
        end

        def field_def("fileEncSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileEncSHA256,
             tag: 7,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:directPath) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "directPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :directPath,
             tag: 8,
             type: :string
           }}
        end

        def field_def("directPath") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "directPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :directPath,
             tag: 8,
             type: :string
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
             tag: 9,
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
             tag: 9,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:fileLength) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileLength",
             kind: {:scalar, 0},
             label: :optional,
             name: :fileLength,
             tag: 10,
             type: :uint64
           }}
        end

        def field_def("fileLength") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileLength",
             kind: {:scalar, 0},
             label: :optional,
             name: :fileLength,
             tag: 10,
             type: :uint64
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
    def default(:flowID) do
      {:ok, ""}
    end,
    def default(:galaxyFlowDownloadRequestID) do
      {:ok, ""}
    end,
    def default(:fileName) do
      {:ok, ""}
    end,
    def default(:mimetype) do
      {:ok, ""}
    end,
    def default(:fileSHA256) do
      {:ok, ""}
    end,
    def default(:mediaKey) do
      {:ok, ""}
    end,
    def default(:fileEncSHA256) do
      {:ok, ""}
    end,
    def default(:directPath) do
      {:ok, ""}
    end,
    def default(:mediaKeyTimestamp) do
      {:ok, 0}
    end,
    def default(:fileLength) do
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
