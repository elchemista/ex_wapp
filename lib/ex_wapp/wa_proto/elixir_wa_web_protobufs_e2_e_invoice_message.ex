# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.InvoiceMessage do
  @moduledoc false
  defstruct note: nil,
            token: nil,
            attachmentType: nil,
            attachmentMimetype: nil,
            attachmentMediaKey: nil,
            attachmentMediaKeyTimestamp: nil,
            attachmentFileSHA256: nil,
            attachmentFileEncSHA256: nil,
            attachmentDirectPath: nil,
            attachmentJPEGThumbnail: nil,
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
        |> encode_note(msg)
        |> encode_token(msg)
        |> encode_attachmentType(msg)
        |> encode_attachmentMimetype(msg)
        |> encode_attachmentMediaKey(msg)
        |> encode_attachmentMediaKeyTimestamp(msg)
        |> encode_attachmentFileSHA256(msg)
        |> encode_attachmentFileEncSHA256(msg)
        |> encode_attachmentDirectPath(msg)
        |> encode_attachmentJPEGThumbnail(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_note(acc, msg) do
        try do
          case msg.note do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.note)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:note, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_token(acc, msg) do
        try do
          case msg.token do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.token)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:token, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_attachmentType(acc, msg) do
        try do
          case msg.attachmentType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x18",
                msg.attachmentType
                |> WAWebProtobufsE2E.InvoiceMessage.AttachmentType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:attachmentType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_attachmentMimetype(acc, msg) do
        try do
          case msg.attachmentMimetype do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.attachmentMimetype)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:attachmentMimetype, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_attachmentMediaKey(acc, msg) do
        try do
          case msg.attachmentMediaKey do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_bytes(msg.attachmentMediaKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:attachmentMediaKey, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_attachmentMediaKeyTimestamp(acc, msg) do
        try do
          case msg.attachmentMediaKeyTimestamp do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_int64(msg.attachmentMediaKeyTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:attachmentMediaKeyTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_attachmentFileSHA256(acc, msg) do
        try do
          case msg.attachmentFileSHA256 do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_bytes(msg.attachmentFileSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:attachmentFileSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_attachmentFileEncSHA256(acc, msg) do
        try do
          case msg.attachmentFileEncSHA256 do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_bytes(msg.attachmentFileEncSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:attachmentFileEncSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_attachmentDirectPath(acc, msg) do
        try do
          case msg.attachmentDirectPath do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_string(msg.attachmentDirectPath)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:attachmentDirectPath, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_attachmentJPEGThumbnail(acc, msg) do
        try do
          case msg.attachmentJPEGThumbnail do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_bytes(msg.attachmentJPEGThumbnail)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:attachmentJPEGThumbnail, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.InvoiceMessage))
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
              {[note: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[token: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.InvoiceMessage.AttachmentType)

              {[attachmentType: value], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[attachmentMimetype: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[attachmentMediaKey: delimited], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[attachmentMediaKeyTimestamp: value], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[attachmentFileSHA256: delimited], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[attachmentFileEncSHA256: delimited], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[attachmentDirectPath: Protox.Decode.validate_string!(delimited)], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[attachmentJPEGThumbnail: delimited], rest}

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
        WAWebProtobufsE2E.InvoiceMessage,
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
        1 => {:note, {:scalar, ""}, :string},
        2 => {:token, {:scalar, ""}, :string},
        3 =>
          {:attachmentType, {:scalar, :IMAGE},
           {:enum, WAWebProtobufsE2E.InvoiceMessage.AttachmentType}},
        4 => {:attachmentMimetype, {:scalar, ""}, :string},
        5 => {:attachmentMediaKey, {:scalar, ""}, :bytes},
        6 => {:attachmentMediaKeyTimestamp, {:scalar, 0}, :int64},
        7 => {:attachmentFileSHA256, {:scalar, ""}, :bytes},
        8 => {:attachmentFileEncSHA256, {:scalar, ""}, :bytes},
        9 => {:attachmentDirectPath, {:scalar, ""}, :string},
        10 => {:attachmentJPEGThumbnail, {:scalar, ""}, :bytes}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        attachmentDirectPath: {9, {:scalar, ""}, :string},
        attachmentFileEncSHA256: {8, {:scalar, ""}, :bytes},
        attachmentFileSHA256: {7, {:scalar, ""}, :bytes},
        attachmentJPEGThumbnail: {10, {:scalar, ""}, :bytes},
        attachmentMediaKey: {5, {:scalar, ""}, :bytes},
        attachmentMediaKeyTimestamp: {6, {:scalar, 0}, :int64},
        attachmentMimetype: {4, {:scalar, ""}, :string},
        attachmentType:
          {3, {:scalar, :IMAGE}, {:enum, WAWebProtobufsE2E.InvoiceMessage.AttachmentType}},
        note: {1, {:scalar, ""}, :string},
        token: {2, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "note",
          kind: {:scalar, ""},
          label: :optional,
          name: :note,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "token",
          kind: {:scalar, ""},
          label: :optional,
          name: :token,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "attachmentType",
          kind: {:scalar, :IMAGE},
          label: :optional,
          name: :attachmentType,
          tag: 3,
          type: {:enum, WAWebProtobufsE2E.InvoiceMessage.AttachmentType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "attachmentMimetype",
          kind: {:scalar, ""},
          label: :optional,
          name: :attachmentMimetype,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "attachmentMediaKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :attachmentMediaKey,
          tag: 5,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "attachmentMediaKeyTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :attachmentMediaKeyTimestamp,
          tag: 6,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "attachmentFileSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :attachmentFileSHA256,
          tag: 7,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "attachmentFileEncSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :attachmentFileEncSHA256,
          tag: 8,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "attachmentDirectPath",
          kind: {:scalar, ""},
          label: :optional,
          name: :attachmentDirectPath,
          tag: 9,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "attachmentJPEGThumbnail",
          kind: {:scalar, ""},
          label: :optional,
          name: :attachmentJPEGThumbnail,
          tag: 10,
          type: :bytes
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:note) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "note",
             kind: {:scalar, ""},
             label: :optional,
             name: :note,
             tag: 1,
             type: :string
           }}
        end

        def field_def("note") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "note",
             kind: {:scalar, ""},
             label: :optional,
             name: :note,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:token) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "token",
             kind: {:scalar, ""},
             label: :optional,
             name: :token,
             tag: 2,
             type: :string
           }}
        end

        def field_def("token") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "token",
             kind: {:scalar, ""},
             label: :optional,
             name: :token,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:attachmentType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentType",
             kind: {:scalar, :IMAGE},
             label: :optional,
             name: :attachmentType,
             tag: 3,
             type: {:enum, WAWebProtobufsE2E.InvoiceMessage.AttachmentType}
           }}
        end

        def field_def("attachmentType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentType",
             kind: {:scalar, :IMAGE},
             label: :optional,
             name: :attachmentType,
             tag: 3,
             type: {:enum, WAWebProtobufsE2E.InvoiceMessage.AttachmentType}
           }}
        end

        []
      ),
      (
        def field_def(:attachmentMimetype) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentMimetype",
             kind: {:scalar, ""},
             label: :optional,
             name: :attachmentMimetype,
             tag: 4,
             type: :string
           }}
        end

        def field_def("attachmentMimetype") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentMimetype",
             kind: {:scalar, ""},
             label: :optional,
             name: :attachmentMimetype,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:attachmentMediaKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentMediaKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :attachmentMediaKey,
             tag: 5,
             type: :bytes
           }}
        end

        def field_def("attachmentMediaKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentMediaKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :attachmentMediaKey,
             tag: 5,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:attachmentMediaKeyTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentMediaKeyTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :attachmentMediaKeyTimestamp,
             tag: 6,
             type: :int64
           }}
        end

        def field_def("attachmentMediaKeyTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentMediaKeyTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :attachmentMediaKeyTimestamp,
             tag: 6,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:attachmentFileSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentFileSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :attachmentFileSHA256,
             tag: 7,
             type: :bytes
           }}
        end

        def field_def("attachmentFileSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentFileSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :attachmentFileSHA256,
             tag: 7,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:attachmentFileEncSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentFileEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :attachmentFileEncSHA256,
             tag: 8,
             type: :bytes
           }}
        end

        def field_def("attachmentFileEncSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentFileEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :attachmentFileEncSHA256,
             tag: 8,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:attachmentDirectPath) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentDirectPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :attachmentDirectPath,
             tag: 9,
             type: :string
           }}
        end

        def field_def("attachmentDirectPath") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentDirectPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :attachmentDirectPath,
             tag: 9,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:attachmentJPEGThumbnail) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentJPEGThumbnail",
             kind: {:scalar, ""},
             label: :optional,
             name: :attachmentJPEGThumbnail,
             tag: 10,
             type: :bytes
           }}
        end

        def field_def("attachmentJPEGThumbnail") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "attachmentJPEGThumbnail",
             kind: {:scalar, ""},
             label: :optional,
             name: :attachmentJPEGThumbnail,
             tag: 10,
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
    def default(:note) do
      {:ok, ""}
    end,
    def default(:token) do
      {:ok, ""}
    end,
    def default(:attachmentType) do
      {:ok, :IMAGE}
    end,
    def default(:attachmentMimetype) do
      {:ok, ""}
    end,
    def default(:attachmentMediaKey) do
      {:ok, ""}
    end,
    def default(:attachmentMediaKeyTimestamp) do
      {:ok, 0}
    end,
    def default(:attachmentFileSHA256) do
      {:ok, ""}
    end,
    def default(:attachmentFileEncSHA256) do
      {:ok, ""}
    end,
    def default(:attachmentDirectPath) do
      {:ok, ""}
    end,
    def default(:attachmentJPEGThumbnail) do
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
