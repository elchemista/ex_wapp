# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ButtonsMessage.Button do
  @moduledoc false
  defstruct buttonID: nil, buttonText: nil, type: nil, nativeFlowInfo: nil, __uf__: []

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
        |> encode_buttonID(msg)
        |> encode_buttonText(msg)
        |> encode_type(msg)
        |> encode_nativeFlowInfo(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_buttonID(acc, msg) do
        try do
          case msg.buttonID do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.buttonID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:buttonID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_buttonText(acc, msg) do
        try do
          case msg.buttonText do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_message(msg.buttonText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:buttonText, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_type(acc, msg) do
        try do
          case msg.type do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x18",
                msg.type
                |> WAWebProtobufsE2E.ButtonsMessage.Button.Type.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:type, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_nativeFlowInfo(acc, msg) do
        try do
          case msg.nativeFlowInfo do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_message(msg.nativeFlowInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:nativeFlowInfo, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.ButtonsMessage.Button))
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
              {[buttonID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 buttonText:
                   Protox.MergeMessage.merge(
                     msg.buttonText,
                     WAWebProtobufsE2E.ButtonsMessage.Button.ButtonText.decode!(delimited)
                   )
               ], rest}

            {3, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.ButtonsMessage.Button.Type)

              {[type: value], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 nativeFlowInfo:
                   Protox.MergeMessage.merge(
                     msg.nativeFlowInfo,
                     WAWebProtobufsE2E.ButtonsMessage.Button.NativeFlowInfo.decode!(delimited)
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
        WAWebProtobufsE2E.ButtonsMessage.Button,
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
        1 => {:buttonID, {:scalar, ""}, :string},
        2 =>
          {:buttonText, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ButtonsMessage.Button.ButtonText}},
        3 => {:type, {:scalar, :UNKNOWN}, {:enum, WAWebProtobufsE2E.ButtonsMessage.Button.Type}},
        4 =>
          {:nativeFlowInfo, {:scalar, nil},
           {:message, WAWebProtobufsE2E.ButtonsMessage.Button.NativeFlowInfo}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        buttonID: {1, {:scalar, ""}, :string},
        buttonText:
          {2, {:scalar, nil}, {:message, WAWebProtobufsE2E.ButtonsMessage.Button.ButtonText}},
        nativeFlowInfo:
          {4, {:scalar, nil}, {:message, WAWebProtobufsE2E.ButtonsMessage.Button.NativeFlowInfo}},
        type: {3, {:scalar, :UNKNOWN}, {:enum, WAWebProtobufsE2E.ButtonsMessage.Button.Type}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "buttonID",
          kind: {:scalar, ""},
          label: :optional,
          name: :buttonID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "buttonText",
          kind: {:scalar, nil},
          label: :optional,
          name: :buttonText,
          tag: 2,
          type: {:message, WAWebProtobufsE2E.ButtonsMessage.Button.ButtonText}
        },
        %{
          __struct__: Protox.Field,
          json_name: "type",
          kind: {:scalar, :UNKNOWN},
          label: :optional,
          name: :type,
          tag: 3,
          type: {:enum, WAWebProtobufsE2E.ButtonsMessage.Button.Type}
        },
        %{
          __struct__: Protox.Field,
          json_name: "nativeFlowInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :nativeFlowInfo,
          tag: 4,
          type: {:message, WAWebProtobufsE2E.ButtonsMessage.Button.NativeFlowInfo}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:buttonID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "buttonID",
             kind: {:scalar, ""},
             label: :optional,
             name: :buttonID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("buttonID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "buttonID",
             kind: {:scalar, ""},
             label: :optional,
             name: :buttonID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:buttonText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "buttonText",
             kind: {:scalar, nil},
             label: :optional,
             name: :buttonText,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.ButtonsMessage.Button.ButtonText}
           }}
        end

        def field_def("buttonText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "buttonText",
             kind: {:scalar, nil},
             label: :optional,
             name: :buttonText,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.ButtonsMessage.Button.ButtonText}
           }}
        end

        []
      ),
      (
        def field_def(:type) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "type",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :type,
             tag: 3,
             type: {:enum, WAWebProtobufsE2E.ButtonsMessage.Button.Type}
           }}
        end

        def field_def("type") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "type",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :type,
             tag: 3,
             type: {:enum, WAWebProtobufsE2E.ButtonsMessage.Button.Type}
           }}
        end

        []
      ),
      (
        def field_def(:nativeFlowInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nativeFlowInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :nativeFlowInfo,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.ButtonsMessage.Button.NativeFlowInfo}
           }}
        end

        def field_def("nativeFlowInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nativeFlowInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :nativeFlowInfo,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.ButtonsMessage.Button.NativeFlowInfo}
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
    def default(:buttonID) do
      {:ok, ""}
    end,
    def default(:buttonText) do
      {:ok, nil}
    end,
    def default(:type) do
      {:ok, :UNKNOWN}
    end,
    def default(:nativeFlowInfo) do
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
