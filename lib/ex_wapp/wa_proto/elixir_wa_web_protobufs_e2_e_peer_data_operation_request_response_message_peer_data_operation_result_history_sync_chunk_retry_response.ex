# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponse do
  @moduledoc false
  defstruct syncType: nil,
            chunkOrder: nil,
            requestID: nil,
            responseCode: nil,
            canRecover: nil,
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
        |> encode_syncType(msg)
        |> encode_chunkOrder(msg)
        |> encode_requestID(msg)
        |> encode_responseCode(msg)
        |> encode_canRecover(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_syncType(acc, msg) do
        try do
          case msg.syncType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.syncType
                |> WAWebProtobufsE2E.HistorySyncType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:syncType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_chunkOrder(acc, msg) do
        try do
          case msg.chunkOrder do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_uint32(msg.chunkOrder)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:chunkOrder, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_requestID(acc, msg) do
        try do
          case msg.requestID do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.requestID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:requestID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_responseCode(acc, msg) do
        try do
          case msg.responseCode do
            nil ->
              acc

            _ ->
              [
                acc,
                " ",
                msg.responseCode
                |> WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponseCode.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:responseCode, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_canRecover(acc, msg) do
        try do
          case msg.canRecover do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_bool(msg.canRecover)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:canRecover, "invalid field value"), __STACKTRACE__
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
              WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponse
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
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.HistorySyncType)
              {[syncType: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[chunkOrder: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[requestID: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponseCode
                )

              {[responseCode: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[canRecover: value], rest}

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
        WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponse,
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
          {:syncType, {:scalar, :INITIAL_BOOTSTRAP}, {:enum, WAWebProtobufsE2E.HistorySyncType}},
        2 => {:chunkOrder, {:scalar, 0}, :uint32},
        3 => {:requestID, {:scalar, ""}, :string},
        4 =>
          {:responseCode, {:scalar, :GENERATION_ERROR},
           {:enum,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponseCode}},
        5 => {:canRecover, {:scalar, false}, :bool}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        canRecover: {5, {:scalar, false}, :bool},
        chunkOrder: {2, {:scalar, 0}, :uint32},
        requestID: {3, {:scalar, ""}, :string},
        responseCode:
          {4, {:scalar, :GENERATION_ERROR},
           {:enum,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponseCode}},
        syncType: {1, {:scalar, :INITIAL_BOOTSTRAP}, {:enum, WAWebProtobufsE2E.HistorySyncType}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "syncType",
          kind: {:scalar, :INITIAL_BOOTSTRAP},
          label: :optional,
          name: :syncType,
          tag: 1,
          type: {:enum, WAWebProtobufsE2E.HistorySyncType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "chunkOrder",
          kind: {:scalar, 0},
          label: :optional,
          name: :chunkOrder,
          tag: 2,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "requestID",
          kind: {:scalar, ""},
          label: :optional,
          name: :requestID,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "responseCode",
          kind: {:scalar, :GENERATION_ERROR},
          label: :optional,
          name: :responseCode,
          tag: 4,
          type:
            {:enum,
             WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponseCode}
        },
        %{
          __struct__: Protox.Field,
          json_name: "canRecover",
          kind: {:scalar, false},
          label: :optional,
          name: :canRecover,
          tag: 5,
          type: :bool
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:syncType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "syncType",
             kind: {:scalar, :INITIAL_BOOTSTRAP},
             label: :optional,
             name: :syncType,
             tag: 1,
             type: {:enum, WAWebProtobufsE2E.HistorySyncType}
           }}
        end

        def field_def("syncType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "syncType",
             kind: {:scalar, :INITIAL_BOOTSTRAP},
             label: :optional,
             name: :syncType,
             tag: 1,
             type: {:enum, WAWebProtobufsE2E.HistorySyncType}
           }}
        end

        []
      ),
      (
        def field_def(:chunkOrder) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chunkOrder",
             kind: {:scalar, 0},
             label: :optional,
             name: :chunkOrder,
             tag: 2,
             type: :uint32
           }}
        end

        def field_def("chunkOrder") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chunkOrder",
             kind: {:scalar, 0},
             label: :optional,
             name: :chunkOrder,
             tag: 2,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:requestID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestID",
             kind: {:scalar, ""},
             label: :optional,
             name: :requestID,
             tag: 3,
             type: :string
           }}
        end

        def field_def("requestID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestID",
             kind: {:scalar, ""},
             label: :optional,
             name: :requestID,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:responseCode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "responseCode",
             kind: {:scalar, :GENERATION_ERROR},
             label: :optional,
             name: :responseCode,
             tag: 4,
             type:
               {:enum,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponseCode}
           }}
        end

        def field_def("responseCode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "responseCode",
             kind: {:scalar, :GENERATION_ERROR},
             label: :optional,
             name: :responseCode,
             tag: 4,
             type:
               {:enum,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponseCode}
           }}
        end

        []
      ),
      (
        def field_def(:canRecover) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "canRecover",
             kind: {:scalar, false},
             label: :optional,
             name: :canRecover,
             tag: 5,
             type: :bool
           }}
        end

        def field_def("canRecover") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "canRecover",
             kind: {:scalar, false},
             label: :optional,
             name: :canRecover,
             tag: 5,
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
    def default(:syncType) do
      {:ok, :INITIAL_BOOTSTRAP}
    end,
    def default(:chunkOrder) do
      {:ok, 0}
    end,
    def default(:requestID) do
      {:ok, ""}
    end,
    def default(:responseCode) do
      {:ok, :GENERATION_ERROR}
    end,
    def default(:canRecover) do
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
