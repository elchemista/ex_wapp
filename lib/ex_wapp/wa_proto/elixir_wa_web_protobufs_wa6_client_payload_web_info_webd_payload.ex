# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.WebInfo.WebdPayload do
  @moduledoc false
  defstruct usesParticipantInKey: nil,
            supportsStarredMessages: nil,
            supportsDocumentMessages: nil,
            supportsURLMessages: nil,
            supportsMediaRetry: nil,
            supportsE2EImage: nil,
            supportsE2EVideo: nil,
            supportsE2EAudio: nil,
            supportsE2EDocument: nil,
            documentTypes: nil,
            features: nil,
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
        |> encode_usesParticipantInKey(msg)
        |> encode_supportsStarredMessages(msg)
        |> encode_supportsDocumentMessages(msg)
        |> encode_supportsURLMessages(msg)
        |> encode_supportsMediaRetry(msg)
        |> encode_supportsE2EImage(msg)
        |> encode_supportsE2EVideo(msg)
        |> encode_supportsE2EAudio(msg)
        |> encode_supportsE2EDocument(msg)
        |> encode_documentTypes(msg)
        |> encode_features(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_usesParticipantInKey(acc, msg) do
        try do
          case msg.usesParticipantInKey do
            nil -> acc
            _ -> [acc, "\b", Protox.Encode.encode_bool(msg.usesParticipantInKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:usesParticipantInKey, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportsStarredMessages(acc, msg) do
        try do
          case msg.supportsStarredMessages do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_bool(msg.supportsStarredMessages)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportsStarredMessages, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportsDocumentMessages(acc, msg) do
        try do
          case msg.supportsDocumentMessages do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_bool(msg.supportsDocumentMessages)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportsDocumentMessages, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportsURLMessages(acc, msg) do
        try do
          case msg.supportsURLMessages do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_bool(msg.supportsURLMessages)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportsURLMessages, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportsMediaRetry(acc, msg) do
        try do
          case msg.supportsMediaRetry do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_bool(msg.supportsMediaRetry)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportsMediaRetry, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportsE2EImage(acc, msg) do
        try do
          case msg.supportsE2EImage do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_bool(msg.supportsE2EImage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportsE2EImage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportsE2EVideo(acc, msg) do
        try do
          case msg.supportsE2EVideo do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_bool(msg.supportsE2EVideo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportsE2EVideo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportsE2EAudio(acc, msg) do
        try do
          case msg.supportsE2EAudio do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_bool(msg.supportsE2EAudio)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportsE2EAudio, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportsE2EDocument(acc, msg) do
        try do
          case msg.supportsE2EDocument do
            nil -> acc
            _ -> [acc, "H", Protox.Encode.encode_bool(msg.supportsE2EDocument)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportsE2EDocument, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_documentTypes(acc, msg) do
        try do
          case msg.documentTypes do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_string(msg.documentTypes)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:documentTypes, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_features(acc, msg) do
        try do
          case msg.features do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_bytes(msg.features)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:features, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsWa6.ClientPayload.WebInfo.WebdPayload))
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
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[usesParticipantInKey: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportsStarredMessages: value], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportsDocumentMessages: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportsURLMessages: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportsMediaRetry: value], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportsE2EImage: value], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportsE2EVideo: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportsE2EAudio: value], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportsE2EDocument: value], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[documentTypes: Protox.Decode.validate_string!(delimited)], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[features: delimited], rest}

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
        WAWebProtobufsWa6.ClientPayload.WebInfo.WebdPayload,
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
        1 => {:usesParticipantInKey, {:scalar, false}, :bool},
        2 => {:supportsStarredMessages, {:scalar, false}, :bool},
        3 => {:supportsDocumentMessages, {:scalar, false}, :bool},
        4 => {:supportsURLMessages, {:scalar, false}, :bool},
        5 => {:supportsMediaRetry, {:scalar, false}, :bool},
        6 => {:supportsE2EImage, {:scalar, false}, :bool},
        7 => {:supportsE2EVideo, {:scalar, false}, :bool},
        8 => {:supportsE2EAudio, {:scalar, false}, :bool},
        9 => {:supportsE2EDocument, {:scalar, false}, :bool},
        10 => {:documentTypes, {:scalar, ""}, :string},
        11 => {:features, {:scalar, ""}, :bytes}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        documentTypes: {10, {:scalar, ""}, :string},
        features: {11, {:scalar, ""}, :bytes},
        supportsDocumentMessages: {3, {:scalar, false}, :bool},
        supportsE2EAudio: {8, {:scalar, false}, :bool},
        supportsE2EDocument: {9, {:scalar, false}, :bool},
        supportsE2EImage: {6, {:scalar, false}, :bool},
        supportsE2EVideo: {7, {:scalar, false}, :bool},
        supportsMediaRetry: {5, {:scalar, false}, :bool},
        supportsStarredMessages: {2, {:scalar, false}, :bool},
        supportsURLMessages: {4, {:scalar, false}, :bool},
        usesParticipantInKey: {1, {:scalar, false}, :bool}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "usesParticipantInKey",
          kind: {:scalar, false},
          label: :optional,
          name: :usesParticipantInKey,
          tag: 1,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportsStarredMessages",
          kind: {:scalar, false},
          label: :optional,
          name: :supportsStarredMessages,
          tag: 2,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportsDocumentMessages",
          kind: {:scalar, false},
          label: :optional,
          name: :supportsDocumentMessages,
          tag: 3,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportsURLMessages",
          kind: {:scalar, false},
          label: :optional,
          name: :supportsURLMessages,
          tag: 4,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportsMediaRetry",
          kind: {:scalar, false},
          label: :optional,
          name: :supportsMediaRetry,
          tag: 5,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportsE2EImage",
          kind: {:scalar, false},
          label: :optional,
          name: :supportsE2EImage,
          tag: 6,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportsE2EVideo",
          kind: {:scalar, false},
          label: :optional,
          name: :supportsE2EVideo,
          tag: 7,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportsE2EAudio",
          kind: {:scalar, false},
          label: :optional,
          name: :supportsE2EAudio,
          tag: 8,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportsE2EDocument",
          kind: {:scalar, false},
          label: :optional,
          name: :supportsE2EDocument,
          tag: 9,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "documentTypes",
          kind: {:scalar, ""},
          label: :optional,
          name: :documentTypes,
          tag: 10,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "features",
          kind: {:scalar, ""},
          label: :optional,
          name: :features,
          tag: 11,
          type: :bytes
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:usesParticipantInKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "usesParticipantInKey",
             kind: {:scalar, false},
             label: :optional,
             name: :usesParticipantInKey,
             tag: 1,
             type: :bool
           }}
        end

        def field_def("usesParticipantInKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "usesParticipantInKey",
             kind: {:scalar, false},
             label: :optional,
             name: :usesParticipantInKey,
             tag: 1,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportsStarredMessages) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsStarredMessages",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsStarredMessages,
             tag: 2,
             type: :bool
           }}
        end

        def field_def("supportsStarredMessages") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsStarredMessages",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsStarredMessages,
             tag: 2,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportsDocumentMessages) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsDocumentMessages",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsDocumentMessages,
             tag: 3,
             type: :bool
           }}
        end

        def field_def("supportsDocumentMessages") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsDocumentMessages",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsDocumentMessages,
             tag: 3,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportsURLMessages) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsURLMessages",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsURLMessages,
             tag: 4,
             type: :bool
           }}
        end

        def field_def("supportsURLMessages") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsURLMessages",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsURLMessages,
             tag: 4,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportsMediaRetry) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsMediaRetry",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsMediaRetry,
             tag: 5,
             type: :bool
           }}
        end

        def field_def("supportsMediaRetry") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsMediaRetry",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsMediaRetry,
             tag: 5,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportsE2EImage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsE2EImage",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsE2EImage,
             tag: 6,
             type: :bool
           }}
        end

        def field_def("supportsE2EImage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsE2EImage",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsE2EImage,
             tag: 6,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportsE2EVideo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsE2EVideo",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsE2EVideo,
             tag: 7,
             type: :bool
           }}
        end

        def field_def("supportsE2EVideo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsE2EVideo",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsE2EVideo,
             tag: 7,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportsE2EAudio) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsE2EAudio",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsE2EAudio,
             tag: 8,
             type: :bool
           }}
        end

        def field_def("supportsE2EAudio") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsE2EAudio",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsE2EAudio,
             tag: 8,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportsE2EDocument) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsE2EDocument",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsE2EDocument,
             tag: 9,
             type: :bool
           }}
        end

        def field_def("supportsE2EDocument") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportsE2EDocument",
             kind: {:scalar, false},
             label: :optional,
             name: :supportsE2EDocument,
             tag: 9,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:documentTypes) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "documentTypes",
             kind: {:scalar, ""},
             label: :optional,
             name: :documentTypes,
             tag: 10,
             type: :string
           }}
        end

        def field_def("documentTypes") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "documentTypes",
             kind: {:scalar, ""},
             label: :optional,
             name: :documentTypes,
             tag: 10,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:features) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "features",
             kind: {:scalar, ""},
             label: :optional,
             name: :features,
             tag: 11,
             type: :bytes
           }}
        end

        def field_def("features") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "features",
             kind: {:scalar, ""},
             label: :optional,
             name: :features,
             tag: 11,
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
    def default(:usesParticipantInKey) do
      {:ok, false}
    end,
    def default(:supportsStarredMessages) do
      {:ok, false}
    end,
    def default(:supportsDocumentMessages) do
      {:ok, false}
    end,
    def default(:supportsURLMessages) do
      {:ok, false}
    end,
    def default(:supportsMediaRetry) do
      {:ok, false}
    end,
    def default(:supportsE2EImage) do
      {:ok, false}
    end,
    def default(:supportsE2EVideo) do
      {:ok, false}
    end,
    def default(:supportsE2EAudio) do
      {:ok, false}
    end,
    def default(:supportsE2EDocument) do
      {:ok, false}
    end,
    def default(:documentTypes) do
      {:ok, ""}
    end,
    def default(:features) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waWa6",
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
