# credo:disable-for-this-file
defmodule WAWebProtobufsServerSync.SyncdPatch do
  @moduledoc false
  defstruct version: nil,
            mutations: [],
            externalMutations: nil,
            snapshotMAC: nil,
            patchMAC: nil,
            keyID: nil,
            exitCode: nil,
            deviceIndex: nil,
            clientDebugData: nil,
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
        |> encode_version(msg)
        |> encode_mutations(msg)
        |> encode_externalMutations(msg)
        |> encode_snapshotMAC(msg)
        |> encode_patchMAC(msg)
        |> encode_keyID(msg)
        |> encode_exitCode(msg)
        |> encode_deviceIndex(msg)
        |> encode_clientDebugData(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_version(acc, msg) do
        try do
          case msg.version do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_message(msg.version)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:version, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mutations(acc, msg) do
        try do
          case msg.mutations do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\x12", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mutations, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_externalMutations(acc, msg) do
        try do
          case msg.externalMutations do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_message(msg.externalMutations)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:externalMutations, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_snapshotMAC(acc, msg) do
        try do
          case msg.snapshotMAC do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_bytes(msg.snapshotMAC)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:snapshotMAC, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_patchMAC(acc, msg) do
        try do
          case msg.patchMAC do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_bytes(msg.patchMAC)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:patchMAC, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_keyID(acc, msg) do
        try do
          case msg.keyID do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_message(msg.keyID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:keyID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_exitCode(acc, msg) do
        try do
          case msg.exitCode do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_message(msg.exitCode)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:exitCode, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_deviceIndex(acc, msg) do
        try do
          case msg.deviceIndex do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_uint32(msg.deviceIndex)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deviceIndex, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_clientDebugData(acc, msg) do
        try do
          case msg.clientDebugData do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_bytes(msg.clientDebugData)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:clientDebugData, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsServerSync.SyncdPatch))
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
                 version:
                   Protox.MergeMessage.merge(
                     msg.version,
                     WAWebProtobufsServerSync.SyncdVersion.decode!(delimited)
                   )
               ], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 mutations:
                   msg.mutations ++ [WAWebProtobufsServerSync.SyncdMutation.decode!(delimited)]
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 externalMutations:
                   Protox.MergeMessage.merge(
                     msg.externalMutations,
                     WAWebProtobufsServerSync.ExternalBlobReference.decode!(delimited)
                   )
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[snapshotMAC: delimited], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[patchMAC: delimited], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 keyID:
                   Protox.MergeMessage.merge(
                     msg.keyID,
                     WAWebProtobufsServerSync.KeyId.decode!(delimited)
                   )
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 exitCode:
                   Protox.MergeMessage.merge(
                     msg.exitCode,
                     WAWebProtobufsServerSync.ExitCode.decode!(delimited)
                   )
               ], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[deviceIndex: value], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[clientDebugData: delimited], rest}

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
        WAWebProtobufsServerSync.SyncdPatch,
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
        1 => {:version, {:scalar, nil}, {:message, WAWebProtobufsServerSync.SyncdVersion}},
        2 => {:mutations, :unpacked, {:message, WAWebProtobufsServerSync.SyncdMutation}},
        3 =>
          {:externalMutations, {:scalar, nil},
           {:message, WAWebProtobufsServerSync.ExternalBlobReference}},
        4 => {:snapshotMAC, {:scalar, ""}, :bytes},
        5 => {:patchMAC, {:scalar, ""}, :bytes},
        6 => {:keyID, {:scalar, nil}, {:message, WAWebProtobufsServerSync.KeyId}},
        7 => {:exitCode, {:scalar, nil}, {:message, WAWebProtobufsServerSync.ExitCode}},
        8 => {:deviceIndex, {:scalar, 0}, :uint32},
        9 => {:clientDebugData, {:scalar, ""}, :bytes}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        clientDebugData: {9, {:scalar, ""}, :bytes},
        deviceIndex: {8, {:scalar, 0}, :uint32},
        exitCode: {7, {:scalar, nil}, {:message, WAWebProtobufsServerSync.ExitCode}},
        externalMutations:
          {3, {:scalar, nil}, {:message, WAWebProtobufsServerSync.ExternalBlobReference}},
        keyID: {6, {:scalar, nil}, {:message, WAWebProtobufsServerSync.KeyId}},
        mutations: {2, :unpacked, {:message, WAWebProtobufsServerSync.SyncdMutation}},
        patchMAC: {5, {:scalar, ""}, :bytes},
        snapshotMAC: {4, {:scalar, ""}, :bytes},
        version: {1, {:scalar, nil}, {:message, WAWebProtobufsServerSync.SyncdVersion}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "version",
          kind: {:scalar, nil},
          label: :optional,
          name: :version,
          tag: 1,
          type: {:message, WAWebProtobufsServerSync.SyncdVersion}
        },
        %{
          __struct__: Protox.Field,
          json_name: "mutations",
          kind: :unpacked,
          label: :repeated,
          name: :mutations,
          tag: 2,
          type: {:message, WAWebProtobufsServerSync.SyncdMutation}
        },
        %{
          __struct__: Protox.Field,
          json_name: "externalMutations",
          kind: {:scalar, nil},
          label: :optional,
          name: :externalMutations,
          tag: 3,
          type: {:message, WAWebProtobufsServerSync.ExternalBlobReference}
        },
        %{
          __struct__: Protox.Field,
          json_name: "snapshotMAC",
          kind: {:scalar, ""},
          label: :optional,
          name: :snapshotMAC,
          tag: 4,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "patchMAC",
          kind: {:scalar, ""},
          label: :optional,
          name: :patchMAC,
          tag: 5,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "keyID",
          kind: {:scalar, nil},
          label: :optional,
          name: :keyID,
          tag: 6,
          type: {:message, WAWebProtobufsServerSync.KeyId}
        },
        %{
          __struct__: Protox.Field,
          json_name: "exitCode",
          kind: {:scalar, nil},
          label: :optional,
          name: :exitCode,
          tag: 7,
          type: {:message, WAWebProtobufsServerSync.ExitCode}
        },
        %{
          __struct__: Protox.Field,
          json_name: "deviceIndex",
          kind: {:scalar, 0},
          label: :optional,
          name: :deviceIndex,
          tag: 8,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "clientDebugData",
          kind: {:scalar, ""},
          label: :optional,
          name: :clientDebugData,
          tag: 9,
          type: :bytes
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:version) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "version",
             kind: {:scalar, nil},
             label: :optional,
             name: :version,
             tag: 1,
             type: {:message, WAWebProtobufsServerSync.SyncdVersion}
           }}
        end

        def field_def("version") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "version",
             kind: {:scalar, nil},
             label: :optional,
             name: :version,
             tag: 1,
             type: {:message, WAWebProtobufsServerSync.SyncdVersion}
           }}
        end

        []
      ),
      (
        def field_def(:mutations) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mutations",
             kind: :unpacked,
             label: :repeated,
             name: :mutations,
             tag: 2,
             type: {:message, WAWebProtobufsServerSync.SyncdMutation}
           }}
        end

        def field_def("mutations") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mutations",
             kind: :unpacked,
             label: :repeated,
             name: :mutations,
             tag: 2,
             type: {:message, WAWebProtobufsServerSync.SyncdMutation}
           }}
        end

        []
      ),
      (
        def field_def(:externalMutations) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "externalMutations",
             kind: {:scalar, nil},
             label: :optional,
             name: :externalMutations,
             tag: 3,
             type: {:message, WAWebProtobufsServerSync.ExternalBlobReference}
           }}
        end

        def field_def("externalMutations") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "externalMutations",
             kind: {:scalar, nil},
             label: :optional,
             name: :externalMutations,
             tag: 3,
             type: {:message, WAWebProtobufsServerSync.ExternalBlobReference}
           }}
        end

        []
      ),
      (
        def field_def(:snapshotMAC) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "snapshotMAC",
             kind: {:scalar, ""},
             label: :optional,
             name: :snapshotMAC,
             tag: 4,
             type: :bytes
           }}
        end

        def field_def("snapshotMAC") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "snapshotMAC",
             kind: {:scalar, ""},
             label: :optional,
             name: :snapshotMAC,
             tag: 4,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:patchMAC) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "patchMAC",
             kind: {:scalar, ""},
             label: :optional,
             name: :patchMAC,
             tag: 5,
             type: :bytes
           }}
        end

        def field_def("patchMAC") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "patchMAC",
             kind: {:scalar, ""},
             label: :optional,
             name: :patchMAC,
             tag: 5,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:keyID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "keyID",
             kind: {:scalar, nil},
             label: :optional,
             name: :keyID,
             tag: 6,
             type: {:message, WAWebProtobufsServerSync.KeyId}
           }}
        end

        def field_def("keyID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "keyID",
             kind: {:scalar, nil},
             label: :optional,
             name: :keyID,
             tag: 6,
             type: {:message, WAWebProtobufsServerSync.KeyId}
           }}
        end

        []
      ),
      (
        def field_def(:exitCode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "exitCode",
             kind: {:scalar, nil},
             label: :optional,
             name: :exitCode,
             tag: 7,
             type: {:message, WAWebProtobufsServerSync.ExitCode}
           }}
        end

        def field_def("exitCode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "exitCode",
             kind: {:scalar, nil},
             label: :optional,
             name: :exitCode,
             tag: 7,
             type: {:message, WAWebProtobufsServerSync.ExitCode}
           }}
        end

        []
      ),
      (
        def field_def(:deviceIndex) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceIndex",
             kind: {:scalar, 0},
             label: :optional,
             name: :deviceIndex,
             tag: 8,
             type: :uint32
           }}
        end

        def field_def("deviceIndex") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceIndex",
             kind: {:scalar, 0},
             label: :optional,
             name: :deviceIndex,
             tag: 8,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:clientDebugData) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "clientDebugData",
             kind: {:scalar, ""},
             label: :optional,
             name: :clientDebugData,
             tag: 9,
             type: :bytes
           }}
        end

        def field_def("clientDebugData") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "clientDebugData",
             kind: {:scalar, ""},
             label: :optional,
             name: :clientDebugData,
             tag: 9,
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
    def default(:version) do
      {:ok, nil}
    end,
    def default(:mutations) do
      {:error, :no_default_value}
    end,
    def default(:externalMutations) do
      {:ok, nil}
    end,
    def default(:snapshotMAC) do
      {:ok, ""}
    end,
    def default(:patchMAC) do
      {:ok, ""}
    end,
    def default(:keyID) do
      {:ok, nil}
    end,
    def default(:exitCode) do
      {:ok, nil}
    end,
    def default(:deviceIndex) do
      {:ok, 0}
    end,
    def default(:clientDebugData) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waServerSync",
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

  @type t :: %__MODULE__{}
end
