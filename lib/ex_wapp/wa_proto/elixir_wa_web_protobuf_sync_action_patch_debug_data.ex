# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.PatchDebugData do
  @moduledoc false
  defstruct currentLthash: nil,
            newLthash: nil,
            patchVersion: nil,
            collectionName: nil,
            firstFourBytesFromAHashOfSnapshotMACKey: nil,
            newLthashSubtract: nil,
            numberAdd: nil,
            numberRemove: nil,
            numberOverride: nil,
            senderPlatform: nil,
            isSenderPrimary: nil,
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
        |> encode_currentLthash(msg)
        |> encode_newLthash(msg)
        |> encode_patchVersion(msg)
        |> encode_collectionName(msg)
        |> encode_firstFourBytesFromAHashOfSnapshotMACKey(msg)
        |> encode_newLthashSubtract(msg)
        |> encode_numberAdd(msg)
        |> encode_numberRemove(msg)
        |> encode_numberOverride(msg)
        |> encode_senderPlatform(msg)
        |> encode_isSenderPrimary(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_currentLthash(acc, msg) do
        try do
          case msg.currentLthash do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_bytes(msg.currentLthash)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:currentLthash, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_newLthash(acc, msg) do
        try do
          case msg.newLthash do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_bytes(msg.newLthash)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:newLthash, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_patchVersion(acc, msg) do
        try do
          case msg.patchVersion do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_bytes(msg.patchVersion)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:patchVersion, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_collectionName(acc, msg) do
        try do
          case msg.collectionName do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_bytes(msg.collectionName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:collectionName, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_firstFourBytesFromAHashOfSnapshotMACKey(acc, msg) do
        try do
          case msg.firstFourBytesFromAHashOfSnapshotMACKey do
            nil ->
              acc

            _ ->
              [acc, "*", Protox.Encode.encode_bytes(msg.firstFourBytesFromAHashOfSnapshotMACKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :firstFourBytesFromAHashOfSnapshotMACKey,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_newLthashSubtract(acc, msg) do
        try do
          case msg.newLthashSubtract do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_bytes(msg.newLthashSubtract)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:newLthashSubtract, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_numberAdd(acc, msg) do
        try do
          case msg.numberAdd do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_int32(msg.numberAdd)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:numberAdd, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_numberRemove(acc, msg) do
        try do
          case msg.numberRemove do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_int32(msg.numberRemove)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:numberRemove, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_numberOverride(acc, msg) do
        try do
          case msg.numberOverride do
            nil -> acc
            _ -> [acc, "H", Protox.Encode.encode_int32(msg.numberOverride)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:numberOverride, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_senderPlatform(acc, msg) do
        try do
          case msg.senderPlatform do
            nil ->
              acc

            _ ->
              [
                acc,
                "P",
                msg.senderPlatform
                |> WAWebProtobufSyncAction.PatchDebugData.Platform.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:senderPlatform, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isSenderPrimary(acc, msg) do
        try do
          case msg.isSenderPrimary do
            nil -> acc
            _ -> [acc, "X", Protox.Encode.encode_bool(msg.isSenderPrimary)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isSenderPrimary, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufSyncAction.PatchDebugData))
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
              {[currentLthash: delimited], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[newLthash: delimited], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[patchVersion: delimited], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[collectionName: delimited], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[firstFourBytesFromAHashOfSnapshotMACKey: delimited], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[newLthashSubtract: delimited], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[numberAdd: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[numberRemove: value], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[numberOverride: value], rest}

            {10, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufSyncAction.PatchDebugData.Platform)

              {[senderPlatform: value], rest}

            {11, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isSenderPrimary: value], rest}

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
        WAWebProtobufSyncAction.PatchDebugData,
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
        1 => {:currentLthash, {:scalar, ""}, :bytes},
        2 => {:newLthash, {:scalar, ""}, :bytes},
        3 => {:patchVersion, {:scalar, ""}, :bytes},
        4 => {:collectionName, {:scalar, ""}, :bytes},
        5 => {:firstFourBytesFromAHashOfSnapshotMACKey, {:scalar, ""}, :bytes},
        6 => {:newLthashSubtract, {:scalar, ""}, :bytes},
        7 => {:numberAdd, {:scalar, 0}, :int32},
        8 => {:numberRemove, {:scalar, 0}, :int32},
        9 => {:numberOverride, {:scalar, 0}, :int32},
        10 =>
          {:senderPlatform, {:scalar, :ANDROID},
           {:enum, WAWebProtobufSyncAction.PatchDebugData.Platform}},
        11 => {:isSenderPrimary, {:scalar, false}, :bool}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        collectionName: {4, {:scalar, ""}, :bytes},
        currentLthash: {1, {:scalar, ""}, :bytes},
        firstFourBytesFromAHashOfSnapshotMACKey: {5, {:scalar, ""}, :bytes},
        isSenderPrimary: {11, {:scalar, false}, :bool},
        newLthash: {2, {:scalar, ""}, :bytes},
        newLthashSubtract: {6, {:scalar, ""}, :bytes},
        numberAdd: {7, {:scalar, 0}, :int32},
        numberOverride: {9, {:scalar, 0}, :int32},
        numberRemove: {8, {:scalar, 0}, :int32},
        patchVersion: {3, {:scalar, ""}, :bytes},
        senderPlatform:
          {10, {:scalar, :ANDROID}, {:enum, WAWebProtobufSyncAction.PatchDebugData.Platform}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "currentLthash",
          kind: {:scalar, ""},
          label: :optional,
          name: :currentLthash,
          tag: 1,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "newLthash",
          kind: {:scalar, ""},
          label: :optional,
          name: :newLthash,
          tag: 2,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "patchVersion",
          kind: {:scalar, ""},
          label: :optional,
          name: :patchVersion,
          tag: 3,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "collectionName",
          kind: {:scalar, ""},
          label: :optional,
          name: :collectionName,
          tag: 4,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "firstFourBytesFromAHashOfSnapshotMACKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :firstFourBytesFromAHashOfSnapshotMACKey,
          tag: 5,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "newLthashSubtract",
          kind: {:scalar, ""},
          label: :optional,
          name: :newLthashSubtract,
          tag: 6,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "numberAdd",
          kind: {:scalar, 0},
          label: :optional,
          name: :numberAdd,
          tag: 7,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "numberRemove",
          kind: {:scalar, 0},
          label: :optional,
          name: :numberRemove,
          tag: 8,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "numberOverride",
          kind: {:scalar, 0},
          label: :optional,
          name: :numberOverride,
          tag: 9,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "senderPlatform",
          kind: {:scalar, :ANDROID},
          label: :optional,
          name: :senderPlatform,
          tag: 10,
          type: {:enum, WAWebProtobufSyncAction.PatchDebugData.Platform}
        },
        %{
          __struct__: Protox.Field,
          json_name: "isSenderPrimary",
          kind: {:scalar, false},
          label: :optional,
          name: :isSenderPrimary,
          tag: 11,
          type: :bool
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:currentLthash) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "currentLthash",
             kind: {:scalar, ""},
             label: :optional,
             name: :currentLthash,
             tag: 1,
             type: :bytes
           }}
        end

        def field_def("currentLthash") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "currentLthash",
             kind: {:scalar, ""},
             label: :optional,
             name: :currentLthash,
             tag: 1,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:newLthash) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newLthash",
             kind: {:scalar, ""},
             label: :optional,
             name: :newLthash,
             tag: 2,
             type: :bytes
           }}
        end

        def field_def("newLthash") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newLthash",
             kind: {:scalar, ""},
             label: :optional,
             name: :newLthash,
             tag: 2,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:patchVersion) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "patchVersion",
             kind: {:scalar, ""},
             label: :optional,
             name: :patchVersion,
             tag: 3,
             type: :bytes
           }}
        end

        def field_def("patchVersion") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "patchVersion",
             kind: {:scalar, ""},
             label: :optional,
             name: :patchVersion,
             tag: 3,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:collectionName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "collectionName",
             kind: {:scalar, ""},
             label: :optional,
             name: :collectionName,
             tag: 4,
             type: :bytes
           }}
        end

        def field_def("collectionName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "collectionName",
             kind: {:scalar, ""},
             label: :optional,
             name: :collectionName,
             tag: 4,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:firstFourBytesFromAHashOfSnapshotMACKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "firstFourBytesFromAHashOfSnapshotMACKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :firstFourBytesFromAHashOfSnapshotMACKey,
             tag: 5,
             type: :bytes
           }}
        end

        def field_def("firstFourBytesFromAHashOfSnapshotMACKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "firstFourBytesFromAHashOfSnapshotMACKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :firstFourBytesFromAHashOfSnapshotMACKey,
             tag: 5,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:newLthashSubtract) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newLthashSubtract",
             kind: {:scalar, ""},
             label: :optional,
             name: :newLthashSubtract,
             tag: 6,
             type: :bytes
           }}
        end

        def field_def("newLthashSubtract") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newLthashSubtract",
             kind: {:scalar, ""},
             label: :optional,
             name: :newLthashSubtract,
             tag: 6,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:numberAdd) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "numberAdd",
             kind: {:scalar, 0},
             label: :optional,
             name: :numberAdd,
             tag: 7,
             type: :int32
           }}
        end

        def field_def("numberAdd") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "numberAdd",
             kind: {:scalar, 0},
             label: :optional,
             name: :numberAdd,
             tag: 7,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:numberRemove) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "numberRemove",
             kind: {:scalar, 0},
             label: :optional,
             name: :numberRemove,
             tag: 8,
             type: :int32
           }}
        end

        def field_def("numberRemove") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "numberRemove",
             kind: {:scalar, 0},
             label: :optional,
             name: :numberRemove,
             tag: 8,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:numberOverride) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "numberOverride",
             kind: {:scalar, 0},
             label: :optional,
             name: :numberOverride,
             tag: 9,
             type: :int32
           }}
        end

        def field_def("numberOverride") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "numberOverride",
             kind: {:scalar, 0},
             label: :optional,
             name: :numberOverride,
             tag: 9,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:senderPlatform) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderPlatform",
             kind: {:scalar, :ANDROID},
             label: :optional,
             name: :senderPlatform,
             tag: 10,
             type: {:enum, WAWebProtobufSyncAction.PatchDebugData.Platform}
           }}
        end

        def field_def("senderPlatform") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderPlatform",
             kind: {:scalar, :ANDROID},
             label: :optional,
             name: :senderPlatform,
             tag: 10,
             type: {:enum, WAWebProtobufSyncAction.PatchDebugData.Platform}
           }}
        end

        []
      ),
      (
        def field_def(:isSenderPrimary) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSenderPrimary",
             kind: {:scalar, false},
             label: :optional,
             name: :isSenderPrimary,
             tag: 11,
             type: :bool
           }}
        end

        def field_def("isSenderPrimary") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSenderPrimary",
             kind: {:scalar, false},
             label: :optional,
             name: :isSenderPrimary,
             tag: 11,
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
    def default(:currentLthash) do
      {:ok, ""}
    end,
    def default(:newLthash) do
      {:ok, ""}
    end,
    def default(:patchVersion) do
      {:ok, ""}
    end,
    def default(:collectionName) do
      {:ok, ""}
    end,
    def default(:firstFourBytesFromAHashOfSnapshotMACKey) do
      {:ok, ""}
    end,
    def default(:newLthashSubtract) do
      {:ok, ""}
    end,
    def default(:numberAdd) do
      {:ok, 0}
    end,
    def default(:numberRemove) do
      {:ok, 0}
    end,
    def default(:numberOverride) do
      {:ok, 0}
    end,
    def default(:senderPlatform) do
      {:ok, :ANDROID}
    end,
    def default(:isSenderPrimary) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waSyncAction",
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
