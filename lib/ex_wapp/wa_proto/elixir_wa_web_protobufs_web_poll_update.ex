# credo:disable-for-this-file
defmodule WAWebProtobufsWeb.PollUpdate do
  @moduledoc false
  defstruct pollUpdateMessageKey: nil,
            vote: nil,
            senderTimestampMS: nil,
            serverTimestampMS: nil,
            unread: nil,
            metadata: nil,
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
        |> encode_pollUpdateMessageKey(msg)
        |> encode_vote(msg)
        |> encode_senderTimestampMS(msg)
        |> encode_serverTimestampMS(msg)
        |> encode_unread(msg)
        |> encode_metadata(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_pollUpdateMessageKey(acc, msg) do
        try do
          case msg.pollUpdateMessageKey do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_message(msg.pollUpdateMessageKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pollUpdateMessageKey, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_vote(acc, msg) do
        try do
          case msg.vote do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_message(msg.vote)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:vote, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_senderTimestampMS(acc, msg) do
        try do
          case msg.senderTimestampMS do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_int64(msg.senderTimestampMS)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:senderTimestampMS, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_serverTimestampMS(acc, msg) do
        try do
          case msg.serverTimestampMS do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_int64(msg.serverTimestampMS)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:serverTimestampMS, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_unread(acc, msg) do
        try do
          case msg.unread do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_bool(msg.unread)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:unread, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_metadata(acc, msg) do
        try do
          case msg.metadata do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_message(msg.metadata)]
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
          parse_key_value(bytes, struct(WAWebProtobufsWeb.PollUpdate))
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

              {[
                 pollUpdateMessageKey:
                   Protox.MergeMessage.merge(
                     msg.pollUpdateMessageKey,
                     WACommon.MessageKey.decode!(delimited)
                   )
               ], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 vote:
                   Protox.MergeMessage.merge(
                     msg.vote,
                     WAWebProtobufsE2E.PollVoteMessage.decode!(delimited)
                   )
               ], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[senderTimestampMS: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[serverTimestampMS: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[unread: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 metadata:
                   Protox.MergeMessage.merge(
                     msg.metadata,
                     WAWebProtobufsE2E.PollUpdateMessageMetadata.decode!(delimited)
                   )
               ], rest}

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
        WAWebProtobufsWeb.PollUpdate,
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
        1 => {:pollUpdateMessageKey, {:scalar, nil}, {:message, WACommon.MessageKey}},
        2 => {:vote, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollVoteMessage}},
        3 => {:senderTimestampMS, {:scalar, 0}, :int64},
        4 => {:serverTimestampMS, {:scalar, 0}, :int64},
        5 => {:unread, {:scalar, false}, :bool},
        6 => {:metadata, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollUpdateMessageMetadata}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        metadata: {6, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollUpdateMessageMetadata}},
        pollUpdateMessageKey: {1, {:scalar, nil}, {:message, WACommon.MessageKey}},
        senderTimestampMS: {3, {:scalar, 0}, :int64},
        serverTimestampMS: {4, {:scalar, 0}, :int64},
        unread: {5, {:scalar, false}, :bool},
        vote: {2, {:scalar, nil}, {:message, WAWebProtobufsE2E.PollVoteMessage}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "pollUpdateMessageKey",
          kind: {:scalar, nil},
          label: :optional,
          name: :pollUpdateMessageKey,
          tag: 1,
          type: {:message, WACommon.MessageKey}
        },
        %{
          __struct__: Protox.Field,
          json_name: "vote",
          kind: {:scalar, nil},
          label: :optional,
          name: :vote,
          tag: 2,
          type: {:message, WAWebProtobufsE2E.PollVoteMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "senderTimestampMS",
          kind: {:scalar, 0},
          label: :optional,
          name: :senderTimestampMS,
          tag: 3,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "serverTimestampMS",
          kind: {:scalar, 0},
          label: :optional,
          name: :serverTimestampMS,
          tag: 4,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "unread",
          kind: {:scalar, false},
          label: :optional,
          name: :unread,
          tag: 5,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "metadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :metadata,
          tag: 6,
          type: {:message, WAWebProtobufsE2E.PollUpdateMessageMetadata}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:pollUpdateMessageKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollUpdateMessageKey",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollUpdateMessageKey,
             tag: 1,
             type: {:message, WACommon.MessageKey}
           }}
        end

        def field_def("pollUpdateMessageKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pollUpdateMessageKey",
             kind: {:scalar, nil},
             label: :optional,
             name: :pollUpdateMessageKey,
             tag: 1,
             type: {:message, WACommon.MessageKey}
           }}
        end

        []
      ),
      (
        def field_def(:vote) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "vote",
             kind: {:scalar, nil},
             label: :optional,
             name: :vote,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.PollVoteMessage}
           }}
        end

        def field_def("vote") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "vote",
             kind: {:scalar, nil},
             label: :optional,
             name: :vote,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.PollVoteMessage}
           }}
        end

        []
      ),
      (
        def field_def(:senderTimestampMS) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderTimestampMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :senderTimestampMS,
             tag: 3,
             type: :int64
           }}
        end

        def field_def("senderTimestampMS") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderTimestampMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :senderTimestampMS,
             tag: 3,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:serverTimestampMS) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "serverTimestampMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :serverTimestampMS,
             tag: 4,
             type: :int64
           }}
        end

        def field_def("serverTimestampMS") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "serverTimestampMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :serverTimestampMS,
             tag: 4,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:unread) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "unread",
             kind: {:scalar, false},
             label: :optional,
             name: :unread,
             tag: 5,
             type: :bool
           }}
        end

        def field_def("unread") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "unread",
             kind: {:scalar, false},
             label: :optional,
             name: :unread,
             tag: 5,
             type: :bool
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
             kind: {:scalar, nil},
             label: :optional,
             name: :metadata,
             tag: 6,
             type: {:message, WAWebProtobufsE2E.PollUpdateMessageMetadata}
           }}
        end

        def field_def("metadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "metadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :metadata,
             tag: 6,
             type: {:message, WAWebProtobufsE2E.PollUpdateMessageMetadata}
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
    def default(:pollUpdateMessageKey) do
      {:ok, nil}
    end,
    def default(:vote) do
      {:ok, nil}
    end,
    def default(:senderTimestampMS) do
      {:ok, 0}
    end,
    def default(:serverTimestampMS) do
      {:ok, 0}
    end,
    def default(:unread) do
      {:ok, false}
    end,
    def default(:metadata) do
      {:ok, nil}
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
        go_package: "go.mau.fi/whatsmeow/proto/waWeb",
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
