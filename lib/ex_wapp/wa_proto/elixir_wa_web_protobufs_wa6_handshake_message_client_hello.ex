# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.HandshakeMessage.ClientHello do
  @moduledoc false
  defstruct ephemeral: nil,
            static: nil,
            payload: nil,
            useExtended: nil,
            extendedCiphertext: nil,
            paddedBytes: nil,
            sendServerHelloPaddedBytes: nil,
            simulateXxkemFs: nil,
            pqMode: nil,
            extendedEphemeral: nil,
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
        |> encode_ephemeral(msg)
        |> encode_static(msg)
        |> encode_payload(msg)
        |> encode_useExtended(msg)
        |> encode_extendedCiphertext(msg)
        |> encode_paddedBytes(msg)
        |> encode_sendServerHelloPaddedBytes(msg)
        |> encode_simulateXxkemFs(msg)
        |> encode_pqMode(msg)
        |> encode_extendedEphemeral(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_ephemeral(acc, msg) do
        try do
          case msg.ephemeral do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_bytes(msg.ephemeral)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeral, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_static(acc, msg) do
        try do
          case msg.static do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_bytes(msg.static)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:static, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_payload(acc, msg) do
        try do
          case msg.payload do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_bytes(msg.payload)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:payload, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_useExtended(acc, msg) do
        try do
          case msg.useExtended do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_bool(msg.useExtended)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:useExtended, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_extendedCiphertext(acc, msg) do
        try do
          case msg.extendedCiphertext do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_bytes(msg.extendedCiphertext)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:extendedCiphertext, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_paddedBytes(acc, msg) do
        try do
          case msg.paddedBytes do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_bytes(msg.paddedBytes)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:paddedBytes, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_sendServerHelloPaddedBytes(acc, msg) do
        try do
          case msg.sendServerHelloPaddedBytes do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_bool(msg.sendServerHelloPaddedBytes)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:sendServerHelloPaddedBytes, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_simulateXxkemFs(acc, msg) do
        try do
          case msg.simulateXxkemFs do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_bool(msg.simulateXxkemFs)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:simulateXxkemFs, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pqMode(acc, msg) do
        try do
          case msg.pqMode do
            nil ->
              acc

            _ ->
              [
                acc,
                "H",
                msg.pqMode
                |> WAWebProtobufsWa6.HandshakeMessage.HandshakePqMode.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pqMode, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_extendedEphemeral(acc, msg) do
        try do
          case msg.extendedEphemeral do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_bytes(msg.extendedEphemeral)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:extendedEphemeral, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsWa6.HandshakeMessage.ClientHello))
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
              {[ephemeral: delimited], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[static: delimited], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[payload: delimited], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[useExtended: value], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[extendedCiphertext: delimited], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[paddedBytes: delimited], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[sendServerHelloPaddedBytes: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[simulateXxkemFs: value], rest}

            {9, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsWa6.HandshakeMessage.HandshakePqMode
                )

              {[pqMode: value], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[extendedEphemeral: delimited], rest}

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
        WAWebProtobufsWa6.HandshakeMessage.ClientHello,
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
        1 => {:ephemeral, {:scalar, ""}, :bytes},
        2 => {:static, {:scalar, ""}, :bytes},
        3 => {:payload, {:scalar, ""}, :bytes},
        4 => {:useExtended, {:scalar, false}, :bool},
        5 => {:extendedCiphertext, {:scalar, ""}, :bytes},
        6 => {:paddedBytes, {:scalar, ""}, :bytes},
        7 => {:sendServerHelloPaddedBytes, {:scalar, false}, :bool},
        8 => {:simulateXxkemFs, {:scalar, false}, :bool},
        9 =>
          {:pqMode, {:scalar, :HANDSHAKE_PQ_MODE_UNKNOWN},
           {:enum, WAWebProtobufsWa6.HandshakeMessage.HandshakePqMode}},
        10 => {:extendedEphemeral, {:scalar, ""}, :bytes}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        ephemeral: {1, {:scalar, ""}, :bytes},
        extendedCiphertext: {5, {:scalar, ""}, :bytes},
        extendedEphemeral: {10, {:scalar, ""}, :bytes},
        paddedBytes: {6, {:scalar, ""}, :bytes},
        payload: {3, {:scalar, ""}, :bytes},
        pqMode:
          {9, {:scalar, :HANDSHAKE_PQ_MODE_UNKNOWN},
           {:enum, WAWebProtobufsWa6.HandshakeMessage.HandshakePqMode}},
        sendServerHelloPaddedBytes: {7, {:scalar, false}, :bool},
        simulateXxkemFs: {8, {:scalar, false}, :bool},
        static: {2, {:scalar, ""}, :bytes},
        useExtended: {4, {:scalar, false}, :bool}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "ephemeral",
          kind: {:scalar, ""},
          label: :optional,
          name: :ephemeral,
          tag: 1,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "static",
          kind: {:scalar, ""},
          label: :optional,
          name: :static,
          tag: 2,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "payload",
          kind: {:scalar, ""},
          label: :optional,
          name: :payload,
          tag: 3,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "useExtended",
          kind: {:scalar, false},
          label: :optional,
          name: :useExtended,
          tag: 4,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "extendedCiphertext",
          kind: {:scalar, ""},
          label: :optional,
          name: :extendedCiphertext,
          tag: 5,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "paddedBytes",
          kind: {:scalar, ""},
          label: :optional,
          name: :paddedBytes,
          tag: 6,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "sendServerHelloPaddedBytes",
          kind: {:scalar, false},
          label: :optional,
          name: :sendServerHelloPaddedBytes,
          tag: 7,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "simulateXxkemFs",
          kind: {:scalar, false},
          label: :optional,
          name: :simulateXxkemFs,
          tag: 8,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "pqMode",
          kind: {:scalar, :HANDSHAKE_PQ_MODE_UNKNOWN},
          label: :optional,
          name: :pqMode,
          tag: 9,
          type: {:enum, WAWebProtobufsWa6.HandshakeMessage.HandshakePqMode}
        },
        %{
          __struct__: Protox.Field,
          json_name: "extendedEphemeral",
          kind: {:scalar, ""},
          label: :optional,
          name: :extendedEphemeral,
          tag: 10,
          type: :bytes
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:ephemeral) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeral",
             kind: {:scalar, ""},
             label: :optional,
             name: :ephemeral,
             tag: 1,
             type: :bytes
           }}
        end

        def field_def("ephemeral") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeral",
             kind: {:scalar, ""},
             label: :optional,
             name: :ephemeral,
             tag: 1,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:static) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "static",
             kind: {:scalar, ""},
             label: :optional,
             name: :static,
             tag: 2,
             type: :bytes
           }}
        end

        def field_def("static") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "static",
             kind: {:scalar, ""},
             label: :optional,
             name: :static,
             tag: 2,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:payload) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "payload",
             kind: {:scalar, ""},
             label: :optional,
             name: :payload,
             tag: 3,
             type: :bytes
           }}
        end

        def field_def("payload") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "payload",
             kind: {:scalar, ""},
             label: :optional,
             name: :payload,
             tag: 3,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:useExtended) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "useExtended",
             kind: {:scalar, false},
             label: :optional,
             name: :useExtended,
             tag: 4,
             type: :bool
           }}
        end

        def field_def("useExtended") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "useExtended",
             kind: {:scalar, false},
             label: :optional,
             name: :useExtended,
             tag: 4,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:extendedCiphertext) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "extendedCiphertext",
             kind: {:scalar, ""},
             label: :optional,
             name: :extendedCiphertext,
             tag: 5,
             type: :bytes
           }}
        end

        def field_def("extendedCiphertext") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "extendedCiphertext",
             kind: {:scalar, ""},
             label: :optional,
             name: :extendedCiphertext,
             tag: 5,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:paddedBytes) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paddedBytes",
             kind: {:scalar, ""},
             label: :optional,
             name: :paddedBytes,
             tag: 6,
             type: :bytes
           }}
        end

        def field_def("paddedBytes") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paddedBytes",
             kind: {:scalar, ""},
             label: :optional,
             name: :paddedBytes,
             tag: 6,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:sendServerHelloPaddedBytes) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sendServerHelloPaddedBytes",
             kind: {:scalar, false},
             label: :optional,
             name: :sendServerHelloPaddedBytes,
             tag: 7,
             type: :bool
           }}
        end

        def field_def("sendServerHelloPaddedBytes") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sendServerHelloPaddedBytes",
             kind: {:scalar, false},
             label: :optional,
             name: :sendServerHelloPaddedBytes,
             tag: 7,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:simulateXxkemFs) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "simulateXxkemFs",
             kind: {:scalar, false},
             label: :optional,
             name: :simulateXxkemFs,
             tag: 8,
             type: :bool
           }}
        end

        def field_def("simulateXxkemFs") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "simulateXxkemFs",
             kind: {:scalar, false},
             label: :optional,
             name: :simulateXxkemFs,
             tag: 8,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:pqMode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pqMode",
             kind: {:scalar, :HANDSHAKE_PQ_MODE_UNKNOWN},
             label: :optional,
             name: :pqMode,
             tag: 9,
             type: {:enum, WAWebProtobufsWa6.HandshakeMessage.HandshakePqMode}
           }}
        end

        def field_def("pqMode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pqMode",
             kind: {:scalar, :HANDSHAKE_PQ_MODE_UNKNOWN},
             label: :optional,
             name: :pqMode,
             tag: 9,
             type: {:enum, WAWebProtobufsWa6.HandshakeMessage.HandshakePqMode}
           }}
        end

        []
      ),
      (
        def field_def(:extendedEphemeral) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "extendedEphemeral",
             kind: {:scalar, ""},
             label: :optional,
             name: :extendedEphemeral,
             tag: 10,
             type: :bytes
           }}
        end

        def field_def("extendedEphemeral") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "extendedEphemeral",
             kind: {:scalar, ""},
             label: :optional,
             name: :extendedEphemeral,
             tag: 10,
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
    def default(:ephemeral) do
      {:ok, ""}
    end,
    def default(:static) do
      {:ok, ""}
    end,
    def default(:payload) do
      {:ok, ""}
    end,
    def default(:useExtended) do
      {:ok, false}
    end,
    def default(:extendedCiphertext) do
      {:ok, ""}
    end,
    def default(:paddedBytes) do
      {:ok, ""}
    end,
    def default(:sendServerHelloPaddedBytes) do
      {:ok, false}
    end,
    def default(:simulateXxkemFs) do
      {:ok, false}
    end,
    def default(:pqMode) do
      {:ok, :HANDSHAKE_PQ_MODE_UNKNOWN}
    end,
    def default(:extendedEphemeral) do
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
