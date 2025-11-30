# credo:disable-for-this-file
defmodule WACert.CertChain.NoiseCertificate.Details do
  @moduledoc false
  defstruct serial: nil, issuerSerial: nil, key: nil, notBefore: nil, notAfter: nil, __uf__: []

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
        |> encode_serial(msg)
        |> encode_issuerSerial(msg)
        |> encode_key(msg)
        |> encode_notBefore(msg)
        |> encode_notAfter(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_serial(acc, msg) do
        try do
          case msg.serial do
            nil -> acc
            _ -> [acc, "\b", Protox.Encode.encode_uint32(msg.serial)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:serial, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_issuerSerial(acc, msg) do
        try do
          case msg.issuerSerial do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_uint32(msg.issuerSerial)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:issuerSerial, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_key(acc, msg) do
        try do
          case msg.key do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_bytes(msg.key)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:key, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_notBefore(acc, msg) do
        try do
          case msg.notBefore do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_uint64(msg.notBefore)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:notBefore, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_notAfter(acc, msg) do
        try do
          case msg.notAfter do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_uint64(msg.notAfter)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:notAfter, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WACert.CertChain.NoiseCertificate.Details))
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
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[serial: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[issuerSerial: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[key: delimited], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[notBefore: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[notAfter: value], rest}

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
        WACert.CertChain.NoiseCertificate.Details,
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
        1 => {:serial, {:scalar, 0}, :uint32},
        2 => {:issuerSerial, {:scalar, 0}, :uint32},
        3 => {:key, {:scalar, ""}, :bytes},
        4 => {:notBefore, {:scalar, 0}, :uint64},
        5 => {:notAfter, {:scalar, 0}, :uint64}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        issuerSerial: {2, {:scalar, 0}, :uint32},
        key: {3, {:scalar, ""}, :bytes},
        notAfter: {5, {:scalar, 0}, :uint64},
        notBefore: {4, {:scalar, 0}, :uint64},
        serial: {1, {:scalar, 0}, :uint32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "serial",
          kind: {:scalar, 0},
          label: :optional,
          name: :serial,
          tag: 1,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "issuerSerial",
          kind: {:scalar, 0},
          label: :optional,
          name: :issuerSerial,
          tag: 2,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "key",
          kind: {:scalar, ""},
          label: :optional,
          name: :key,
          tag: 3,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "notBefore",
          kind: {:scalar, 0},
          label: :optional,
          name: :notBefore,
          tag: 4,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "notAfter",
          kind: {:scalar, 0},
          label: :optional,
          name: :notAfter,
          tag: 5,
          type: :uint64
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:serial) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "serial",
             kind: {:scalar, 0},
             label: :optional,
             name: :serial,
             tag: 1,
             type: :uint32
           }}
        end

        def field_def("serial") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "serial",
             kind: {:scalar, 0},
             label: :optional,
             name: :serial,
             tag: 1,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:issuerSerial) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "issuerSerial",
             kind: {:scalar, 0},
             label: :optional,
             name: :issuerSerial,
             tag: 2,
             type: :uint32
           }}
        end

        def field_def("issuerSerial") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "issuerSerial",
             kind: {:scalar, 0},
             label: :optional,
             name: :issuerSerial,
             tag: 2,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:key) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "key",
             kind: {:scalar, ""},
             label: :optional,
             name: :key,
             tag: 3,
             type: :bytes
           }}
        end

        def field_def("key") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "key",
             kind: {:scalar, ""},
             label: :optional,
             name: :key,
             tag: 3,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:notBefore) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "notBefore",
             kind: {:scalar, 0},
             label: :optional,
             name: :notBefore,
             tag: 4,
             type: :uint64
           }}
        end

        def field_def("notBefore") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "notBefore",
             kind: {:scalar, 0},
             label: :optional,
             name: :notBefore,
             tag: 4,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:notAfter) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "notAfter",
             kind: {:scalar, 0},
             label: :optional,
             name: :notAfter,
             tag: 5,
             type: :uint64
           }}
        end

        def field_def("notAfter") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "notAfter",
             kind: {:scalar, 0},
             label: :optional,
             name: :notAfter,
             tag: 5,
             type: :uint64
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
    def default(:serial) do
      {:ok, 0}
    end,
    def default(:issuerSerial) do
      {:ok, 0}
    end,
    def default(:key) do
      {:ok, ""}
    end,
    def default(:notBefore) do
      {:ok, 0}
    end,
    def default(:notAfter) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waCert",
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
