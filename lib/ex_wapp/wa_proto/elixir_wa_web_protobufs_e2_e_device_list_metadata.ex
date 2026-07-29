# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.DeviceListMetadata do
  @moduledoc false
  defstruct senderKeyHash: nil,
            senderTimestamp: nil,
            senderKeyIndexes: [],
            senderAccountType: nil,
            receiverAccountType: nil,
            recipientKeyHash: nil,
            recipientTimestamp: nil,
            recipientKeyIndexes: [],
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
        |> encode_senderKeyHash(msg)
        |> encode_senderTimestamp(msg)
        |> encode_senderKeyIndexes(msg)
        |> encode_senderAccountType(msg)
        |> encode_receiverAccountType(msg)
        |> encode_recipientKeyHash(msg)
        |> encode_recipientTimestamp(msg)
        |> encode_recipientKeyIndexes(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_senderKeyHash(acc, msg) do
        try do
          case msg.senderKeyHash do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_bytes(msg.senderKeyHash)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:senderKeyHash, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_senderTimestamp(acc, msg) do
        try do
          case msg.senderTimestamp do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_uint64(msg.senderTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:senderTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_senderKeyIndexes(acc, msg) do
        try do
          case msg.senderKeyIndexes do
            [] ->
              acc

            values ->
              [
                acc,
                "\x1A",
                (
                  {bytes, len} =
                    Enum.reduce(values, {[], 0}, fn value, {acc, len} ->
                      value_bytes = :binary.list_to_bin([Protox.Encode.encode_uint32(value)])
                      {[acc, value_bytes], len + byte_size(value_bytes)}
                    end)

                  [Protox.Varint.encode(len), bytes]
                )
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:senderKeyIndexes, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_senderAccountType(acc, msg) do
        try do
          case msg.senderAccountType do
            nil ->
              acc

            _ ->
              [
                acc,
                " ",
                msg.senderAccountType
                |> WAAdv.ADVEncryptionType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:senderAccountType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_receiverAccountType(acc, msg) do
        try do
          case msg.receiverAccountType do
            nil ->
              acc

            _ ->
              [
                acc,
                "(",
                msg.receiverAccountType
                |> WAAdv.ADVEncryptionType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:receiverAccountType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_recipientKeyHash(acc, msg) do
        try do
          case msg.recipientKeyHash do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_bytes(msg.recipientKeyHash)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:recipientKeyHash, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_recipientTimestamp(acc, msg) do
        try do
          case msg.recipientTimestamp do
            nil -> acc
            _ -> [acc, "H", Protox.Encode.encode_uint64(msg.recipientTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:recipientTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_recipientKeyIndexes(acc, msg) do
        try do
          case msg.recipientKeyIndexes do
            [] ->
              acc

            values ->
              [
                acc,
                "R",
                (
                  {bytes, len} =
                    Enum.reduce(values, {[], 0}, fn value, {acc, len} ->
                      value_bytes = :binary.list_to_bin([Protox.Encode.encode_uint32(value)])
                      {[acc, value_bytes], len + byte_size(value_bytes)}
                    end)

                  [Protox.Varint.encode(len), bytes]
                )
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:recipientKeyIndexes, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.DeviceListMetadata))
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
              {[senderKeyHash: delimited], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[senderTimestamp: value], rest}

            {3, 2, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 senderKeyIndexes:
                   msg.senderKeyIndexes ++ Protox.Decode.parse_repeated_uint32([], delimited)
               ], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[senderKeyIndexes: msg.senderKeyIndexes ++ [value]], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAAdv.ADVEncryptionType)
              {[senderAccountType: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAAdv.ADVEncryptionType)
              {[receiverAccountType: value], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[recipientKeyHash: delimited], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[recipientTimestamp: value], rest}

            {10, 2, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 recipientKeyIndexes:
                   msg.recipientKeyIndexes ++ Protox.Decode.parse_repeated_uint32([], delimited)
               ], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[recipientKeyIndexes: msg.recipientKeyIndexes ++ [value]], rest}

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
        WAWebProtobufsE2E.DeviceListMetadata,
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
        1 => {:senderKeyHash, {:scalar, ""}, :bytes},
        2 => {:senderTimestamp, {:scalar, 0}, :uint64},
        3 => {:senderKeyIndexes, :packed, :uint32},
        4 => {:senderAccountType, {:scalar, :E2EE}, {:enum, WAAdv.ADVEncryptionType}},
        5 => {:receiverAccountType, {:scalar, :E2EE}, {:enum, WAAdv.ADVEncryptionType}},
        8 => {:recipientKeyHash, {:scalar, ""}, :bytes},
        9 => {:recipientTimestamp, {:scalar, 0}, :uint64},
        10 => {:recipientKeyIndexes, :packed, :uint32}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        receiverAccountType: {5, {:scalar, :E2EE}, {:enum, WAAdv.ADVEncryptionType}},
        recipientKeyHash: {8, {:scalar, ""}, :bytes},
        recipientKeyIndexes: {10, :packed, :uint32},
        recipientTimestamp: {9, {:scalar, 0}, :uint64},
        senderAccountType: {4, {:scalar, :E2EE}, {:enum, WAAdv.ADVEncryptionType}},
        senderKeyHash: {1, {:scalar, ""}, :bytes},
        senderKeyIndexes: {3, :packed, :uint32},
        senderTimestamp: {2, {:scalar, 0}, :uint64}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "senderKeyHash",
          kind: {:scalar, ""},
          label: :optional,
          name: :senderKeyHash,
          tag: 1,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "senderTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :senderTimestamp,
          tag: 2,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "senderKeyIndexes",
          kind: :packed,
          label: :repeated,
          name: :senderKeyIndexes,
          tag: 3,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "senderAccountType",
          kind: {:scalar, :E2EE},
          label: :optional,
          name: :senderAccountType,
          tag: 4,
          type: {:enum, WAAdv.ADVEncryptionType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "receiverAccountType",
          kind: {:scalar, :E2EE},
          label: :optional,
          name: :receiverAccountType,
          tag: 5,
          type: {:enum, WAAdv.ADVEncryptionType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "recipientKeyHash",
          kind: {:scalar, ""},
          label: :optional,
          name: :recipientKeyHash,
          tag: 8,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "recipientTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :recipientTimestamp,
          tag: 9,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "recipientKeyIndexes",
          kind: :packed,
          label: :repeated,
          name: :recipientKeyIndexes,
          tag: 10,
          type: :uint32
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:senderKeyHash) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderKeyHash",
             kind: {:scalar, ""},
             label: :optional,
             name: :senderKeyHash,
             tag: 1,
             type: :bytes
           }}
        end

        def field_def("senderKeyHash") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderKeyHash",
             kind: {:scalar, ""},
             label: :optional,
             name: :senderKeyHash,
             tag: 1,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:senderTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :senderTimestamp,
             tag: 2,
             type: :uint64
           }}
        end

        def field_def("senderTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :senderTimestamp,
             tag: 2,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:senderKeyIndexes) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderKeyIndexes",
             kind: :packed,
             label: :repeated,
             name: :senderKeyIndexes,
             tag: 3,
             type: :uint32
           }}
        end

        def field_def("senderKeyIndexes") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderKeyIndexes",
             kind: :packed,
             label: :repeated,
             name: :senderKeyIndexes,
             tag: 3,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:senderAccountType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderAccountType",
             kind: {:scalar, :E2EE},
             label: :optional,
             name: :senderAccountType,
             tag: 4,
             type: {:enum, WAAdv.ADVEncryptionType}
           }}
        end

        def field_def("senderAccountType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderAccountType",
             kind: {:scalar, :E2EE},
             label: :optional,
             name: :senderAccountType,
             tag: 4,
             type: {:enum, WAAdv.ADVEncryptionType}
           }}
        end

        []
      ),
      (
        def field_def(:receiverAccountType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "receiverAccountType",
             kind: {:scalar, :E2EE},
             label: :optional,
             name: :receiverAccountType,
             tag: 5,
             type: {:enum, WAAdv.ADVEncryptionType}
           }}
        end

        def field_def("receiverAccountType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "receiverAccountType",
             kind: {:scalar, :E2EE},
             label: :optional,
             name: :receiverAccountType,
             tag: 5,
             type: {:enum, WAAdv.ADVEncryptionType}
           }}
        end

        []
      ),
      (
        def field_def(:recipientKeyHash) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recipientKeyHash",
             kind: {:scalar, ""},
             label: :optional,
             name: :recipientKeyHash,
             tag: 8,
             type: :bytes
           }}
        end

        def field_def("recipientKeyHash") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recipientKeyHash",
             kind: {:scalar, ""},
             label: :optional,
             name: :recipientKeyHash,
             tag: 8,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:recipientTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recipientTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :recipientTimestamp,
             tag: 9,
             type: :uint64
           }}
        end

        def field_def("recipientTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recipientTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :recipientTimestamp,
             tag: 9,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:recipientKeyIndexes) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recipientKeyIndexes",
             kind: :packed,
             label: :repeated,
             name: :recipientKeyIndexes,
             tag: 10,
             type: :uint32
           }}
        end

        def field_def("recipientKeyIndexes") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recipientKeyIndexes",
             kind: :packed,
             label: :repeated,
             name: :recipientKeyIndexes,
             tag: 10,
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
    def default(:senderKeyHash) do
      {:ok, ""}
    end,
    def default(:senderTimestamp) do
      {:ok, 0}
    end,
    def default(:senderKeyIndexes) do
      {:error, :no_default_value}
    end,
    def default(:senderAccountType) do
      {:ok, :E2EE}
    end,
    def default(:receiverAccountType) do
      {:ok, :E2EE}
    end,
    def default(:recipientKeyHash) do
      {:ok, ""}
    end,
    def default(:recipientTimestamp) do
      {:ok, 0}
    end,
    def default(:recipientKeyIndexes) do
      {:error, :no_default_value}
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
