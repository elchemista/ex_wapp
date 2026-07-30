# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.DevicePairingRegistrationData do
  @moduledoc false
  defstruct eRegid: nil,
            eKeytype: nil,
            eIdent: nil,
            eSkeyID: nil,
            eSkeyVal: nil,
            eSkeySig: nil,
            buildHash: nil,
            deviceProps: nil,
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
        |> encode_eRegid(msg)
        |> encode_eKeytype(msg)
        |> encode_eIdent(msg)
        |> encode_eSkeyID(msg)
        |> encode_eSkeyVal(msg)
        |> encode_eSkeySig(msg)
        |> encode_buildHash(msg)
        |> encode_deviceProps(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_eRegid(acc, msg) do
        try do
          case msg.eRegid do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_bytes(msg.eRegid)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:eRegid, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_eKeytype(acc, msg) do
        try do
          case msg.eKeytype do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_bytes(msg.eKeytype)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:eKeytype, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_eIdent(acc, msg) do
        try do
          case msg.eIdent do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_bytes(msg.eIdent)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:eIdent, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_eSkeyID(acc, msg) do
        try do
          case msg.eSkeyID do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_bytes(msg.eSkeyID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:eSkeyID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_eSkeyVal(acc, msg) do
        try do
          case msg.eSkeyVal do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_bytes(msg.eSkeyVal)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:eSkeyVal, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_eSkeySig(acc, msg) do
        try do
          case msg.eSkeySig do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_bytes(msg.eSkeySig)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:eSkeySig, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_buildHash(acc, msg) do
        try do
          case msg.buildHash do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_bytes(msg.buildHash)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:buildHash, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_deviceProps(acc, msg) do
        try do
          case msg.deviceProps do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_bytes(msg.deviceProps)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deviceProps, "invalid field value"), __STACKTRACE__
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
            struct(WAWebProtobufsWa6.ClientPayload.DevicePairingRegistrationData)
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
              {[eRegid: delimited], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[eKeytype: delimited], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[eIdent: delimited], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[eSkeyID: delimited], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[eSkeyVal: delimited], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[eSkeySig: delimited], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[buildHash: delimited], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[deviceProps: delimited], rest}

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
        WAWebProtobufsWa6.ClientPayload.DevicePairingRegistrationData,
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
        1 => {:eRegid, {:scalar, ""}, :bytes},
        2 => {:eKeytype, {:scalar, ""}, :bytes},
        3 => {:eIdent, {:scalar, ""}, :bytes},
        4 => {:eSkeyID, {:scalar, ""}, :bytes},
        5 => {:eSkeyVal, {:scalar, ""}, :bytes},
        6 => {:eSkeySig, {:scalar, ""}, :bytes},
        7 => {:buildHash, {:scalar, ""}, :bytes},
        8 => {:deviceProps, {:scalar, ""}, :bytes}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        buildHash: {7, {:scalar, ""}, :bytes},
        deviceProps: {8, {:scalar, ""}, :bytes},
        eIdent: {3, {:scalar, ""}, :bytes},
        eKeytype: {2, {:scalar, ""}, :bytes},
        eRegid: {1, {:scalar, ""}, :bytes},
        eSkeyID: {4, {:scalar, ""}, :bytes},
        eSkeySig: {6, {:scalar, ""}, :bytes},
        eSkeyVal: {5, {:scalar, ""}, :bytes}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "eRegid",
          kind: {:scalar, ""},
          label: :optional,
          name: :eRegid,
          tag: 1,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "eKeytype",
          kind: {:scalar, ""},
          label: :optional,
          name: :eKeytype,
          tag: 2,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "eIdent",
          kind: {:scalar, ""},
          label: :optional,
          name: :eIdent,
          tag: 3,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "eSkeyID",
          kind: {:scalar, ""},
          label: :optional,
          name: :eSkeyID,
          tag: 4,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "eSkeyVal",
          kind: {:scalar, ""},
          label: :optional,
          name: :eSkeyVal,
          tag: 5,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "eSkeySig",
          kind: {:scalar, ""},
          label: :optional,
          name: :eSkeySig,
          tag: 6,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "buildHash",
          kind: {:scalar, ""},
          label: :optional,
          name: :buildHash,
          tag: 7,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "deviceProps",
          kind: {:scalar, ""},
          label: :optional,
          name: :deviceProps,
          tag: 8,
          type: :bytes
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:eRegid) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eRegid",
             kind: {:scalar, ""},
             label: :optional,
             name: :eRegid,
             tag: 1,
             type: :bytes
           }}
        end

        def field_def("eRegid") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eRegid",
             kind: {:scalar, ""},
             label: :optional,
             name: :eRegid,
             tag: 1,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:eKeytype) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eKeytype",
             kind: {:scalar, ""},
             label: :optional,
             name: :eKeytype,
             tag: 2,
             type: :bytes
           }}
        end

        def field_def("eKeytype") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eKeytype",
             kind: {:scalar, ""},
             label: :optional,
             name: :eKeytype,
             tag: 2,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:eIdent) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eIdent",
             kind: {:scalar, ""},
             label: :optional,
             name: :eIdent,
             tag: 3,
             type: :bytes
           }}
        end

        def field_def("eIdent") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eIdent",
             kind: {:scalar, ""},
             label: :optional,
             name: :eIdent,
             tag: 3,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:eSkeyID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eSkeyID",
             kind: {:scalar, ""},
             label: :optional,
             name: :eSkeyID,
             tag: 4,
             type: :bytes
           }}
        end

        def field_def("eSkeyID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eSkeyID",
             kind: {:scalar, ""},
             label: :optional,
             name: :eSkeyID,
             tag: 4,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:eSkeyVal) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eSkeyVal",
             kind: {:scalar, ""},
             label: :optional,
             name: :eSkeyVal,
             tag: 5,
             type: :bytes
           }}
        end

        def field_def("eSkeyVal") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eSkeyVal",
             kind: {:scalar, ""},
             label: :optional,
             name: :eSkeyVal,
             tag: 5,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:eSkeySig) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eSkeySig",
             kind: {:scalar, ""},
             label: :optional,
             name: :eSkeySig,
             tag: 6,
             type: :bytes
           }}
        end

        def field_def("eSkeySig") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eSkeySig",
             kind: {:scalar, ""},
             label: :optional,
             name: :eSkeySig,
             tag: 6,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:buildHash) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "buildHash",
             kind: {:scalar, ""},
             label: :optional,
             name: :buildHash,
             tag: 7,
             type: :bytes
           }}
        end

        def field_def("buildHash") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "buildHash",
             kind: {:scalar, ""},
             label: :optional,
             name: :buildHash,
             tag: 7,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:deviceProps) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceProps",
             kind: {:scalar, ""},
             label: :optional,
             name: :deviceProps,
             tag: 8,
             type: :bytes
           }}
        end

        def field_def("deviceProps") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceProps",
             kind: {:scalar, ""},
             label: :optional,
             name: :deviceProps,
             tag: 8,
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
    def default(:eRegid) do
      {:ok, ""}
    end,
    def default(:eKeytype) do
      {:ok, ""}
    end,
    def default(:eIdent) do
      {:ok, ""}
    end,
    def default(:eSkeyID) do
      {:ok, ""}
    end,
    def default(:eSkeyVal) do
      {:ok, ""}
    end,
    def default(:eSkeySig) do
      {:ok, ""}
    end,
    def default(:buildHash) do
      {:ok, ""}
    end,
    def default(:deviceProps) do
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

  @type t :: %__MODULE__{}
end
