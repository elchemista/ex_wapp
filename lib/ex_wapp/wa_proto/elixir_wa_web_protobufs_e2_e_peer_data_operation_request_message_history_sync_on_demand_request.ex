# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncOnDemandRequest do
  @moduledoc false
  defstruct chatJID: nil,
            oldestMsgID: nil,
            oldestMsgFromMe: nil,
            onDemandMsgCount: nil,
            oldestMsgTimestampMS: nil,
            accountLid: nil,
            supportInlineResponse: nil,
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
        |> encode_chatJID(msg)
        |> encode_oldestMsgID(msg)
        |> encode_oldestMsgFromMe(msg)
        |> encode_onDemandMsgCount(msg)
        |> encode_oldestMsgTimestampMS(msg)
        |> encode_accountLid(msg)
        |> encode_supportInlineResponse(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_chatJID(acc, msg) do
        try do
          case msg.chatJID do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.chatJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:chatJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_oldestMsgID(acc, msg) do
        try do
          case msg.oldestMsgID do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.oldestMsgID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:oldestMsgID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_oldestMsgFromMe(acc, msg) do
        try do
          case msg.oldestMsgFromMe do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_bool(msg.oldestMsgFromMe)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:oldestMsgFromMe, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_onDemandMsgCount(acc, msg) do
        try do
          case msg.onDemandMsgCount do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_int32(msg.onDemandMsgCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:onDemandMsgCount, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_oldestMsgTimestampMS(acc, msg) do
        try do
          case msg.oldestMsgTimestampMS do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_int64(msg.oldestMsgTimestampMS)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:oldestMsgTimestampMS, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_accountLid(acc, msg) do
        try do
          case msg.accountLid do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_string(msg.accountLid)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:accountLid, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_supportInlineResponse(acc, msg) do
        try do
          case msg.supportInlineResponse do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_bool(msg.supportInlineResponse)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportInlineResponse, "invalid field value"),
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
          parse_key_value(
            bytes,
            struct(WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncOnDemandRequest)
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
              {[chatJID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[oldestMsgID: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[oldestMsgFromMe: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[onDemandMsgCount: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[oldestMsgTimestampMS: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[accountLid: Protox.Decode.validate_string!(delimited)], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportInlineResponse: value], rest}

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
        WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncOnDemandRequest,
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
        1 => {:chatJID, {:scalar, ""}, :string},
        2 => {:oldestMsgID, {:scalar, ""}, :string},
        3 => {:oldestMsgFromMe, {:scalar, false}, :bool},
        4 => {:onDemandMsgCount, {:scalar, 0}, :int32},
        5 => {:oldestMsgTimestampMS, {:scalar, 0}, :int64},
        6 => {:accountLid, {:scalar, ""}, :string},
        7 => {:supportInlineResponse, {:scalar, false}, :bool}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        accountLid: {6, {:scalar, ""}, :string},
        chatJID: {1, {:scalar, ""}, :string},
        oldestMsgFromMe: {3, {:scalar, false}, :bool},
        oldestMsgID: {2, {:scalar, ""}, :string},
        oldestMsgTimestampMS: {5, {:scalar, 0}, :int64},
        onDemandMsgCount: {4, {:scalar, 0}, :int32},
        supportInlineResponse: {7, {:scalar, false}, :bool}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "chatJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :chatJID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "oldestMsgID",
          kind: {:scalar, ""},
          label: :optional,
          name: :oldestMsgID,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "oldestMsgFromMe",
          kind: {:scalar, false},
          label: :optional,
          name: :oldestMsgFromMe,
          tag: 3,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "onDemandMsgCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :onDemandMsgCount,
          tag: 4,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "oldestMsgTimestampMS",
          kind: {:scalar, 0},
          label: :optional,
          name: :oldestMsgTimestampMS,
          tag: 5,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "accountLid",
          kind: {:scalar, ""},
          label: :optional,
          name: :accountLid,
          tag: 6,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportInlineResponse",
          kind: {:scalar, false},
          label: :optional,
          name: :supportInlineResponse,
          tag: 7,
          type: :bool
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:chatJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :chatJID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("chatJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :chatJID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:oldestMsgID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oldestMsgID",
             kind: {:scalar, ""},
             label: :optional,
             name: :oldestMsgID,
             tag: 2,
             type: :string
           }}
        end

        def field_def("oldestMsgID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oldestMsgID",
             kind: {:scalar, ""},
             label: :optional,
             name: :oldestMsgID,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:oldestMsgFromMe) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oldestMsgFromMe",
             kind: {:scalar, false},
             label: :optional,
             name: :oldestMsgFromMe,
             tag: 3,
             type: :bool
           }}
        end

        def field_def("oldestMsgFromMe") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oldestMsgFromMe",
             kind: {:scalar, false},
             label: :optional,
             name: :oldestMsgFromMe,
             tag: 3,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:onDemandMsgCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "onDemandMsgCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :onDemandMsgCount,
             tag: 4,
             type: :int32
           }}
        end

        def field_def("onDemandMsgCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "onDemandMsgCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :onDemandMsgCount,
             tag: 4,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:oldestMsgTimestampMS) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oldestMsgTimestampMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :oldestMsgTimestampMS,
             tag: 5,
             type: :int64
           }}
        end

        def field_def("oldestMsgTimestampMS") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oldestMsgTimestampMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :oldestMsgTimestampMS,
             tag: 5,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:accountLid) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accountLid",
             kind: {:scalar, ""},
             label: :optional,
             name: :accountLid,
             tag: 6,
             type: :string
           }}
        end

        def field_def("accountLid") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accountLid",
             kind: {:scalar, ""},
             label: :optional,
             name: :accountLid,
             tag: 6,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:supportInlineResponse) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportInlineResponse",
             kind: {:scalar, false},
             label: :optional,
             name: :supportInlineResponse,
             tag: 7,
             type: :bool
           }}
        end

        def field_def("supportInlineResponse") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportInlineResponse",
             kind: {:scalar, false},
             label: :optional,
             name: :supportInlineResponse,
             tag: 7,
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
    def default(:chatJID) do
      {:ok, ""}
    end,
    def default(:oldestMsgID) do
      {:ok, ""}
    end,
    def default(:oldestMsgFromMe) do
      {:ok, false}
    end,
    def default(:onDemandMsgCount) do
      {:ok, 0}
    end,
    def default(:oldestMsgTimestampMS) do
      {:ok, 0}
    end,
    def default(:accountLid) do
      {:ok, ""}
    end,
    def default(:supportInlineResponse) do
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
