# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.Call do
  @moduledoc false
  defstruct callKey: nil,
            conversionSource: nil,
            conversionData: nil,
            conversionDelaySeconds: nil,
            ctwaSignals: nil,
            ctwaPayload: nil,
            contextInfo: nil,
            nativeFlowCallButtonPayload: nil,
            deeplinkPayload: nil,
            messageContextInfo: nil,
            callEntryPoint: nil,
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
        |> encode_callKey(msg)
        |> encode_conversionSource(msg)
        |> encode_conversionData(msg)
        |> encode_conversionDelaySeconds(msg)
        |> encode_ctwaSignals(msg)
        |> encode_ctwaPayload(msg)
        |> encode_contextInfo(msg)
        |> encode_nativeFlowCallButtonPayload(msg)
        |> encode_deeplinkPayload(msg)
        |> encode_messageContextInfo(msg)
        |> encode_callEntryPoint(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_callKey(acc, msg) do
        try do
          case msg.callKey do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_bytes(msg.callKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callKey, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_conversionSource(acc, msg) do
        try do
          case msg.conversionSource do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.conversionSource)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:conversionSource, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_conversionData(acc, msg) do
        try do
          case msg.conversionData do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_bytes(msg.conversionData)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:conversionData, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_conversionDelaySeconds(acc, msg) do
        try do
          case msg.conversionDelaySeconds do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_uint32(msg.conversionDelaySeconds)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:conversionDelaySeconds, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ctwaSignals(acc, msg) do
        try do
          case msg.ctwaSignals do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.ctwaSignals)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ctwaSignals, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_ctwaPayload(acc, msg) do
        try do
          case msg.ctwaPayload do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_bytes(msg.ctwaPayload)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ctwaPayload, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_contextInfo(acc, msg) do
        try do
          case msg.contextInfo do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_message(msg.contextInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contextInfo, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_nativeFlowCallButtonPayload(acc, msg) do
        try do
          case msg.nativeFlowCallButtonPayload do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_string(msg.nativeFlowCallButtonPayload)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:nativeFlowCallButtonPayload, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_deeplinkPayload(acc, msg) do
        try do
          case msg.deeplinkPayload do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_string(msg.deeplinkPayload)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deeplinkPayload, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messageContextInfo(acc, msg) do
        try do
          case msg.messageContextInfo do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_message(msg.messageContextInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageContextInfo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_callEntryPoint(acc, msg) do
        try do
          case msg.callEntryPoint do
            nil -> acc
            _ -> [acc, "X", Protox.Encode.encode_uint32(msg.callEntryPoint)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callEntryPoint, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.Call))
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
              {[callKey: delimited], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[conversionSource: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[conversionData: delimited], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[conversionDelaySeconds: value], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[ctwaSignals: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[ctwaPayload: delimited], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 contextInfo:
                   Protox.MergeMessage.merge(
                     msg.contextInfo,
                     WAWebProtobufsE2E.ContextInfo.decode!(delimited)
                   )
               ], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[nativeFlowCallButtonPayload: Protox.Decode.validate_string!(delimited)], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[deeplinkPayload: Protox.Decode.validate_string!(delimited)], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 messageContextInfo:
                   Protox.MergeMessage.merge(
                     msg.messageContextInfo,
                     WAWebProtobufsE2E.MessageContextInfo.decode!(delimited)
                   )
               ], rest}

            {11, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[callEntryPoint: value], rest}

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
        WAWebProtobufsE2E.Call,
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
        1 => {:callKey, {:scalar, ""}, :bytes},
        2 => {:conversionSource, {:scalar, ""}, :string},
        3 => {:conversionData, {:scalar, ""}, :bytes},
        4 => {:conversionDelaySeconds, {:scalar, 0}, :uint32},
        5 => {:ctwaSignals, {:scalar, ""}, :string},
        6 => {:ctwaPayload, {:scalar, ""}, :bytes},
        7 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        8 => {:nativeFlowCallButtonPayload, {:scalar, ""}, :string},
        9 => {:deeplinkPayload, {:scalar, ""}, :string},
        10 =>
          {:messageContextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.MessageContextInfo}},
        11 => {:callEntryPoint, {:scalar, 0}, :uint32}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        callEntryPoint: {11, {:scalar, 0}, :uint32},
        callKey: {1, {:scalar, ""}, :bytes},
        contextInfo: {7, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        conversionData: {3, {:scalar, ""}, :bytes},
        conversionDelaySeconds: {4, {:scalar, 0}, :uint32},
        conversionSource: {2, {:scalar, ""}, :string},
        ctwaPayload: {6, {:scalar, ""}, :bytes},
        ctwaSignals: {5, {:scalar, ""}, :string},
        deeplinkPayload: {9, {:scalar, ""}, :string},
        messageContextInfo:
          {10, {:scalar, nil}, {:message, WAWebProtobufsE2E.MessageContextInfo}},
        nativeFlowCallButtonPayload: {8, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "callKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :callKey,
          tag: 1,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "conversionSource",
          kind: {:scalar, ""},
          label: :optional,
          name: :conversionSource,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "conversionData",
          kind: {:scalar, ""},
          label: :optional,
          name: :conversionData,
          tag: 3,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "conversionDelaySeconds",
          kind: {:scalar, 0},
          label: :optional,
          name: :conversionDelaySeconds,
          tag: 4,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "ctwaSignals",
          kind: {:scalar, ""},
          label: :optional,
          name: :ctwaSignals,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "ctwaPayload",
          kind: {:scalar, ""},
          label: :optional,
          name: :ctwaPayload,
          tag: 6,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "contextInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :contextInfo,
          tag: 7,
          type: {:message, WAWebProtobufsE2E.ContextInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "nativeFlowCallButtonPayload",
          kind: {:scalar, ""},
          label: :optional,
          name: :nativeFlowCallButtonPayload,
          tag: 8,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "deeplinkPayload",
          kind: {:scalar, ""},
          label: :optional,
          name: :deeplinkPayload,
          tag: 9,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageContextInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :messageContextInfo,
          tag: 10,
          type: {:message, WAWebProtobufsE2E.MessageContextInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "callEntryPoint",
          kind: {:scalar, 0},
          label: :optional,
          name: :callEntryPoint,
          tag: 11,
          type: :uint32
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:callKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :callKey,
             tag: 1,
             type: :bytes
           }}
        end

        def field_def("callKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :callKey,
             tag: 1,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:conversionSource) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversionSource",
             kind: {:scalar, ""},
             label: :optional,
             name: :conversionSource,
             tag: 2,
             type: :string
           }}
        end

        def field_def("conversionSource") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversionSource",
             kind: {:scalar, ""},
             label: :optional,
             name: :conversionSource,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:conversionData) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversionData",
             kind: {:scalar, ""},
             label: :optional,
             name: :conversionData,
             tag: 3,
             type: :bytes
           }}
        end

        def field_def("conversionData") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversionData",
             kind: {:scalar, ""},
             label: :optional,
             name: :conversionData,
             tag: 3,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:conversionDelaySeconds) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversionDelaySeconds",
             kind: {:scalar, 0},
             label: :optional,
             name: :conversionDelaySeconds,
             tag: 4,
             type: :uint32
           }}
        end

        def field_def("conversionDelaySeconds") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversionDelaySeconds",
             kind: {:scalar, 0},
             label: :optional,
             name: :conversionDelaySeconds,
             tag: 4,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:ctwaSignals) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctwaSignals",
             kind: {:scalar, ""},
             label: :optional,
             name: :ctwaSignals,
             tag: 5,
             type: :string
           }}
        end

        def field_def("ctwaSignals") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctwaSignals",
             kind: {:scalar, ""},
             label: :optional,
             name: :ctwaSignals,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:ctwaPayload) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctwaPayload",
             kind: {:scalar, ""},
             label: :optional,
             name: :ctwaPayload,
             tag: 6,
             type: :bytes
           }}
        end

        def field_def("ctwaPayload") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctwaPayload",
             kind: {:scalar, ""},
             label: :optional,
             name: :ctwaPayload,
             tag: 6,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:contextInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contextInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :contextInfo,
             tag: 7,
             type: {:message, WAWebProtobufsE2E.ContextInfo}
           }}
        end

        def field_def("contextInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contextInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :contextInfo,
             tag: 7,
             type: {:message, WAWebProtobufsE2E.ContextInfo}
           }}
        end

        []
      ),
      (
        def field_def(:nativeFlowCallButtonPayload) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nativeFlowCallButtonPayload",
             kind: {:scalar, ""},
             label: :optional,
             name: :nativeFlowCallButtonPayload,
             tag: 8,
             type: :string
           }}
        end

        def field_def("nativeFlowCallButtonPayload") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nativeFlowCallButtonPayload",
             kind: {:scalar, ""},
             label: :optional,
             name: :nativeFlowCallButtonPayload,
             tag: 8,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:deeplinkPayload) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deeplinkPayload",
             kind: {:scalar, ""},
             label: :optional,
             name: :deeplinkPayload,
             tag: 9,
             type: :string
           }}
        end

        def field_def("deeplinkPayload") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deeplinkPayload",
             kind: {:scalar, ""},
             label: :optional,
             name: :deeplinkPayload,
             tag: 9,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:messageContextInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageContextInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :messageContextInfo,
             tag: 10,
             type: {:message, WAWebProtobufsE2E.MessageContextInfo}
           }}
        end

        def field_def("messageContextInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageContextInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :messageContextInfo,
             tag: 10,
             type: {:message, WAWebProtobufsE2E.MessageContextInfo}
           }}
        end

        []
      ),
      (
        def field_def(:callEntryPoint) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callEntryPoint",
             kind: {:scalar, 0},
             label: :optional,
             name: :callEntryPoint,
             tag: 11,
             type: :uint32
           }}
        end

        def field_def("callEntryPoint") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callEntryPoint",
             kind: {:scalar, 0},
             label: :optional,
             name: :callEntryPoint,
             tag: 11,
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
    def default(:callKey) do
      {:ok, ""}
    end,
    def default(:conversionSource) do
      {:ok, ""}
    end,
    def default(:conversionData) do
      {:ok, ""}
    end,
    def default(:conversionDelaySeconds) do
      {:ok, 0}
    end,
    def default(:ctwaSignals) do
      {:ok, ""}
    end,
    def default(:ctwaPayload) do
      {:ok, ""}
    end,
    def default(:contextInfo) do
      {:ok, nil}
    end,
    def default(:nativeFlowCallButtonPayload) do
      {:ok, ""}
    end,
    def default(:deeplinkPayload) do
      {:ok, ""}
    end,
    def default(:messageContextInfo) do
      {:ok, nil}
    end,
    def default(:callEntryPoint) do
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
